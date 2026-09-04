import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'calendar_screen.dart';
import 'symptoms_screen.dart';
import 'profile_screen.dart';
import 'discover_screen.dart';
import 'stats_screen.dart';
import 'chat_screen.dart';
import 'premium_screen.dart';
import 'cycle_syncing_screen.dart';
import 'irregular_cycle_hub.dart';
import 'safety_center.dart';
import '../services/notification_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();

  Map<String, dynamic>? _data;
  Map<String, dynamic>? _todayEntry;
  bool _isLoading = true;
  String _username = "";
  int _waterGlasses = 0;
  bool _pillTaken = false;
  bool _blocusMode = false;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    final username = await _authService.getUsername() ?? "Utilisatrice";
    final data = await _apiService.getPredictions();
    
    // Fetch today's symptoms log
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final todayEntry = await _apiService.getDailyEntry(todayStr);

    setState(() {
      _username = username;
      _data = data;
      _todayEntry = todayEntry;
      if (todayEntry != null) {
        _waterGlasses = todayEntry['water_intake'] ?? 0;
        _pillTaken = todayEntry['pill_taken'] ?? false;
      } else {
        _waterGlasses = 0;
        _pillTaken = false;
      }
      _isLoading = false;
    });

    _scheduleCycleNotifications();
  }

  Future<void> _updateQuickStats() async {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    
    // We merge with existing entry if available
    Map<String, dynamic> entryData = Map.from(_todayEntry ?? {});
    entryData['date'] = todayStr;
    entryData['water_intake'] = _waterGlasses;
    entryData['pill_taken'] = _pillTaken;

    final success = await _apiService.saveDailyEntry(entryData);
    if (success) {
      // Reload today's entry to stay in sync
      final updatedEntry = await _apiService.getDailyEntry(todayStr);
      setState(() {
        _todayEntry = updatedEntry;
      });
    }
  }

  void _scheduleCycleNotifications() {
    if (_data == null || _data!['predictions'] == null) return;
    final List predictions = _data!['predictions'];
    if (predictions.isEmpty) return;

    final firstPred = predictions[0];
    final startStr = firstPred['predicted_start'];
    final ovStr = firstPred['predicted_ovulation'];

    if (startStr != null) {
      NotificationService().schedulePeriodReminder(DateTime.parse(startStr));
    }
    if (ovStr != null) {
      NotificationService().scheduleOvulationReminder(DateTime.parse(ovStr));
    }
  }

  Color _getPhaseColor(String phase) {
    if (phase.contains("Règles")) return const Color(0xFFE91E63); // Pink/Red
    if (phase.contains("fertile")) return const Color(0xFF2196F3); // Blue
    if (phase.contains("folliculaire")) return const Color(0xFF9C27B0); // Purple
    return const Color(0xFFFF9800); // Orange (Luteal)
  }

  String _getPhaseIcon(String phase) {
    if (phase.contains("Règles")) return "🩸";
    if (phase.contains("fertile")) return "✨";
    if (phase.contains("folliculaire")) return "🌱";
    return "🌙";
  }

  @override
  Widget build(BuildContext context) {
    final todayStr = DateFormat('dd MMMM yyyy', 'fr_FR').format(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7FC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Bonjour, $_username",
          style: const TextStyle(
            color: Color(0xFF4A148C),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Color(0xFF8E24AA)),
            onPressed: () async {
              await _authService.logout();
              if (!context.mounted) return;
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF8E24AA)))
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              color: const Color(0xFF8E24AA),
              child: Stack(
                children: [
                  // Subtle Background Logo
                  Positioned(
                    right: -50,
                    top: 100,
                    child: Opacity(
                      opacity: 0.03,
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 250,
                        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                  SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildDateNavigator(),
                    const SizedBox(height: 20),

                    // Blocus Mode Toggle (Trend)
                    _buildBlocusToggle(),
                    const SizedBox(height: 15),

                    // Central Status Ring
                    _buildCycleStatusRing(),
                    
                    if (_data != null && (_data!['current_cycle']?['is_irregular'] ?? false))
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  "Cycle irrégulier : Fiez-vous à vos signes physiques (glaire/température) pour plus de sécurité.",
                                  style: TextStyle(fontSize: 11, color: Color(0xFFE65100), fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    
                    const SizedBox(height: 20),
                    
                    // Premium Banner
                    _buildPremiumCTA(),

                    const SizedBox(height: 25),

                    // Quick Tools Scroller (Compact)
                    _buildQuickTools(),

                    const SizedBox(height: 20),
                    
                    // NEW: Safety Verification & Period Prep
                    _buildSecurityAndPrepSection(),

                    const SizedBox(height: 20),

                    // Summary
                    _buildTodaySymptomSummary(),
                    const SizedBox(height: 24),
                    
                    // Actions Grid
                    const Padding(
                      padding: EdgeInsets.only(left: 4, bottom: 12),
                      child: Text(
                        "Outils & Suivi",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF4A148C)),
                      ),
                    ),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                      childAspectRatio: 1.4,
                      children: [
                        _buildActionCard(
                          title: "Calendrier",
                          subtitle: "Suivi & prédictions",
                          icon: Icons.calendar_month_rounded,
                          color: const Color(0xFF8E24AA),
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const CalendarScreen()),
                            );
                            _loadDashboardData();
                          },
                        ),
                        _buildActionCard(
                          title: "Symptômes",
                          subtitle: _todayEntry != null ? "Saisie enregistrée" : "Noter aujourd'hui",
                          icon: Icons.add_circle_outline_rounded,
                          color: const Color(0xFFE91E63),
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const SymptomsScreen()),
                            );
                            _loadDashboardData();
                          },
                        ),
                        _buildActionCard(
                          title: "Analyses",
                          subtitle: "Tendances du cycle",
                          icon: Icons.bar_chart_rounded,
                          color: const Color(0xFFFF9800),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const StatsScreen()),
                            );
                          },
                        ),
                        _buildActionCard(
                          title: "Sécurité",
                          subtitle: "Guides & Urgence",
                          icon: Icons.shield_rounded,
                          color: const Color(0xFFC2185B),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const SafetyCenter()),
                            );
                          },
                        ),
                        _buildActionCard(
                          title: "Profil",
                          subtitle: "Vos paramètres",
                          icon: Icons.person_rounded,
                          color: const Color(0xFF2196F3),
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const ProfileScreen()),
                            );
                            _loadDashboardData();
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Phase Insights (Flo inspired)
                    _buildPhaseInsights(),

                    const SizedBox(height: 24),

                    // Next cycle details
                    _buildNextCycleCard(),

                    const SizedBox(height: 24),

                    // Daily Health Insights
                    _buildDailyTips(),
                    
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: const Color(0xFF8E24AA),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == 1) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DiscoverScreen()),
            );
          } else if (index == 2) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CalendarScreen()),
            );
          } else if (index == 3) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ).then((_) => _loadDashboardData());
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "Accueil"),
          BottomNavigationBarItem(icon: Icon(Icons.explore_rounded), label: "Découvrir"),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: "Calendrier"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profil"),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ChatScreen()),
          );
        },
        backgroundColor: const Color(0xFF4A148C),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.chat_bubble_outline_rounded),
        label: const Text("Assistant Santé"),
      ),
    );
  }

  Widget _buildDateNavigator() {
    final dateDisplay = DateFormat('EEEE dd MMMM', 'fr_FR').format(_selectedDate);
    final isToday = DateFormat('yyyy-MM-dd').format(_selectedDate) == 
                    DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left, color: Color(0xFF8E24AA)),
          onPressed: () {
            setState(() {
              _selectedDate = _selectedDate.subtract(const Duration(days: 1));
            });
          },
        ),
        Column(
          children: [
            Text(
              isToday ? "AUJOURD'HUI" : "DATE",
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF8E24AA), letterSpacing: 1),
            ),
            Text(
              dateDisplay,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right, color: Color(0xFF8E24AA)),
          onPressed: () {
            setState(() {
              _selectedDate = _selectedDate.add(const Duration(days: 1));
            });
          },
        ),
      ],
    );
  }

  Widget _buildBlocusToggle() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _blocusMode ? const Color(0xFF1A237E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _blocusMode ? Colors.transparent : Colors.grey.shade300),
        boxShadow: _blocusMode ? [BoxShadow(color: Colors.blue.withValues(alpha: 0.3), blurRadius: 8)] : null,
      ),
      child: Row(
        children: [
          Icon(Icons.menu_book_rounded, color: _blocusMode ? Colors.white : Colors.blueGrey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Mode Blocus & Stress",
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    fontSize: 13, 
                    color: _blocusMode ? Colors.white : Colors.black87
                  ),
                ),
                Text(
                  "Ajuste les prédictions et conseils",
                  style: TextStyle(
                    fontSize: 11, 
                    color: _blocusMode ? Colors.white70 : Colors.grey
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _blocusMode,
            activeColor: Colors.amber,
            onChanged: (val) {
              setState(() {
                _blocusMode = val;
              });
              if (val) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Mode Blocus activé : Vos conseils sont personnalisés.")),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickTools() {
    return SizedBox(
      height: 120,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildToolCard("Hydratation", "${_waterGlasses}/8", Icons.local_drink, Colors.blue, _buildSmallWaterTracker()),
          const SizedBox(width: 15),
          _buildToolCard("Pilule", _pillTaken ? "Prise" : "20:00", Icons.medication, Colors.orange, _buildSmallPillTracker()),
          const SizedBox(width: 15),
          _buildToolCard("Exercice", "À faire", Icons.fitness_center, Colors.green, const Text("Yoga léger", style: TextStyle(fontSize: 10))),
        ],
      ),
    );
  }

  Widget _buildToolCard(String title, String value, IconData icon, Color color, Widget content) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 16),
              Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const Spacer(),
          // Note: We'll use the existing small trackers but wrapped
          SizedBox(height: 40, child: content),
        ],
      ),
    );
  }

  Widget _buildPremiumCTA() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF8E24AA), Color(0xFFE91E63)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.pink.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Le saviez-vous ?",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  "L'exercice léger peut réduire vos douleurs de 30%.",
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DiscoverScreen())),
            child: const Text("LIRE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildCycleStatusRing() {
    if (_data == null || _data!['current_cycle'] == null) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              const Text(
                "Aucun cycle en cours",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4A148C)),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  final success = await _apiService.startCycle(DateFormat('yyyy-MM-dd').format(DateTime.now()));
                  if (success != null) _loadDashboardData();
                },
                child: const Text("Démarrer un cycle aujourd'hui"),
              )
            ],
          ),
        ),
      );
    }

    final currentCycle = _data!['current_cycle'];
    final int currentDay = currentCycle['current_day'] ?? 1;
    final int avgCycleLength = currentCycle['average_cycle_length'] ?? 28;
    final String phase = currentCycle['current_phase'] ?? "Phase folliculaire";
    final phaseColor = _getPhaseColor(phase);
    final phaseIcon = _getPhaseIcon(phase);

    // Blocus logic
    String blocusNotice = "";
    if (_blocusMode) {
      blocusNotice = "Attention : Le stress peut retarder votre cycle.";
    }

    // Calculate percentage representation
    double percentage = currentDay / avgCycleLength;
    if (percentage > 1.0) percentage = 1.0;
    if (percentage < 0.0) percentage = 0.0;

    // Days until next period
    final int daysRemaining = avgCycleLength - currentDay;
    String daysText = "";
    if (daysRemaining > 0) {
      daysText = "Règles dans $daysRemaining jours";
    } else if (daysRemaining == 0) {
      daysText = "Règles prévues aujourd'hui";
    } else {
      daysText = "Retard de ${daysRemaining.abs()} jours";
    }

    // Probability of pregnancy (Flo inspired)
    String probText = "Basse";
    Color probColor = Colors.green;
    String riskTitle = "ZONE SÛRE";
    
    if (phase.toLowerCase().contains("fertile") || phase.toLowerCase().contains("ovulation")) {
      probText = "Élevée";
      probColor = Colors.red;
      riskTitle = "RISQUE ÉLEVÉ";
    } else if (currentDay > (avgCycleLength / 2) - 8 && currentDay < (avgCycleLength / 2)) {
      probText = "Moyenne";
      probColor = Colors.orange;
      riskTitle = "VIGILANCE";
    }

    return Center(
      child: Container(
        width: 270,
        height: 270,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: probColor.withValues(alpha: 0.15),
              blurRadius: 30,
              spreadRadius: 5,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer Ring representation
            SizedBox(
              width: 230,
              height: 230,
              child: CircularProgressIndicator(
                value: percentage,
                strokeWidth: 14,
                backgroundColor: probColor.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(probColor),
              ),
            ),
            // Central Content
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(color: probColor, borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    riskTitle,
                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  phaseIcon,
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(height: 4),
                Text(
                  "JOUR",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade400,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  "$currentDay",
                  style: TextStyle(
                    fontSize: 58,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF4A148C),
                    height: 1.0,
                  ),
                ),
                Text(
                  phase.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: phaseColor,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: phaseColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    daysText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: phaseColor,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Chances de grossesse : ",
                      style: TextStyle(fontSize: 10, color: Colors.black54),
                    ),
                    Text(
                      probText,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: probColor),
                    ),
                  ],
                ),
                if (_blocusMode) ...[
                  const SizedBox(height: 8),
                  Text(
                    blocusNotice,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 9, color: Colors.redAccent, fontWeight: FontWeight.bold),
                  ),
                ]
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A148C),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaySymptomSummary() {
    if (_todayEntry == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3F5),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: const Icon(Icons.favorite_rounded, color: Color(0xFFE91E63)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Comment vous sentez-vous ?",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF880E4F)),
                  ),
                  Text(
                    "Notez vos symptômes pour des prévisions plus précises.",
                    style: TextStyle(fontSize: 12, color: Colors.pink.shade900.withValues(alpha: 0.7)),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SymptomsScreen()),
                );
                _loadDashboardData();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE91E63),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: const Text("Noter"),
            ),
          ],
        ),
      );
    }

    final entry = _todayEntry!;
    List<Map<String, dynamic>> logged = [];
    if (entry['flow_intensity'] != null && entry['flow_intensity'] > 0) {
      logged.add({"label": _getIntensityText(entry['flow_intensity']), "icon": Icons.water_drop, "color": Colors.red});
    }
    if (entry['mood'] != null && entry['mood'].toString().isNotEmpty) {
      logged.add({"label": entry['mood'], "icon": Icons.mood, "color": Colors.orange});
    }
    if (entry['cervical_mucus'] != null && entry['cervical_mucus'] != "none") {
      logged.add({"label": "Pertes: ${entry['cervical_mucus']}", "icon": Icons.opacity, "color": Colors.blue});
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Résumé du jour",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF4A148C)),
              ),
              GestureDetector(
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SymptomsScreen()),
                  );
                  _loadDashboardData();
                },
                child: const Text("Modifier", style: TextStyle(color: Color(0xFF8E24AA), fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          logged.isEmpty
              ? const Text("Rien de particulier noté.", style: TextStyle(fontSize: 13, color: Colors.black54))
              : Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: logged.map((item) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: (item['color'] as Color).withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(item['icon'] as IconData, size: 14, color: item['color'] as Color),
                        const SizedBox(width: 6),
                        Text(
                          item['label'] as String,
                          style: TextStyle(fontSize: 12, color: item['color'] as Color, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  )).toList(),
                ),
        ],
      ),
    );
  }

  String _getIntensityText(int level) {
    if (level == 1) return "Léger";
    if (level == 2) return "Moyen";
    if (level == 3) return "Abondant/Intense";
    return "Aucun";
  }

  Widget _buildNextCycleCard() {
    if (_data == null || _data!['predictions'] == null || (_data!['predictions'] as List).isEmpty) {
      return const SizedBox.shrink();
    }

    final nextPrediction = (_data!['predictions'] as List)[0];
    final bool isIrregular = _data!['current_cycle']?['is_irregular'] ?? false;
    
    String startStr;
    if (isIrregular && nextPrediction['earliest_predicted_start'] != null) {
      final s1 = _formatDateStr(nextPrediction['earliest_predicted_start']);
      final s2 = _formatDateStr(nextPrediction['latest_predicted_start']);
      startStr = "Entre le $s1 et le $s2";
    } else {
      startStr = _formatDateStr(nextPrediction['predicted_start']);
    }

    final fertileStartStr = _formatDateStr(nextPrediction['predicted_fertile_start']);
    final fertileEndStr = _formatDateStr(nextPrediction['predicted_fertile_end']);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isIrregular 
              ? [const Color(0xFFFFF3E0), const Color(0xFFFFE0B2)]
              : [const Color(0xFFE8EAF6), const Color(0xFFE1BEE7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Prochaines prévisions",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A237E),
                ),
              ),
              if (isIrregular)
                GestureDetector(
                  onTap: () {
                    final variation = _data!['analysis']?['variation_days'] ?? 0.0;
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => IrregularCycleHub(variationDays: variation.toDouble())),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(8)),
                    child: const Text("IRRÉGULIER >", style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.water_drop, color: Color(0xFFE91E63), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Prochaines règles estimées",
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    Text(
                      startStr,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.star_rounded, color: Color(0xFF2196F3), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Fenêtre de fertilité",
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    Text(
                      "du $fertileStartStr au $fertileEndStr",
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDateStr(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy', 'fr_FR').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  Widget _buildSmallWaterTracker() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.local_drink_rounded, color: Color(0xFF2196F3), size: 20),
              Text(
                "$_waterGlasses/8",
                style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0D47A1)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text("Eau", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: List.generate(8, (index) {
              final bool filled = index < _waterGlasses;
              return GestureDetector(
                onTap: () {
                  setState(() => _waterGlasses = index + 1);
                  _updateQuickStats();
                },
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: filled ? const Color(0xFF2196F3) : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF2196F3).withValues(alpha: 0.3)),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallPillTracker() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                _pillTaken ? Icons.check_circle : Icons.medication_rounded,
                color: _pillTaken ? Colors.green : Colors.orange,
                size: 20,
              ),
              Transform.scale(
                scale: 0.7,
                child: Switch(
                  value: _pillTaken,
                  activeColor: Colors.green,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onChanged: (val) {
                    setState(() => _pillTaken = val);
                    _updateQuickStats();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text("Pilule", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          Text(
            _pillTaken ? "Prise" : "À prendre",
            style: TextStyle(fontSize: 11, color: _pillTaken ? Colors.green.shade700 : Colors.orange.shade900),
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseInsights() {
    if (_data == null || _data!['current_cycle'] == null) return const SizedBox.shrink();
    
    final phase = _data!['current_cycle']['current_phase'] ?? "Phase folliculaire";
    String title = "";
    String content = "";
    Color color = Colors.purple;

    if (phase.contains("Règles")) {
      title = _blocusMode ? "Blocus & Règles" : "Prenez soin de vous";
      content = _blocusMode 
        ? "Mix difficile ! Buvez des tisanes au gingembre et faites des micro-pauses de 5 min toutes les heures."
        : "Votre niveau d'oestrogène est au plus bas. Priorisez le repos et les aliments riches en fer.";
      color = const Color(0xFFE91E63);
    } else if (phase.contains("fertile")) {
      title = "Énergie maximale";
      content = "C'est le moment où vous vous sentez le plus sociable et dynamique. Profitez-en pour vos projets !";
      color = const Color(0xFF2196F3);
    } else if (phase.contains("folliculaire")) {
      title = "Nouveau départ";
      content = "Votre corps se prépare. Idéal pour commencer de nouvelles routines sportives.";
      color = const Color(0xFF9C27B0);
    } else {
      title = "Ralentissement";
      content = "La progestérone augmente. Vous pourriez vous sentir plus introspective ou fatiguée.";
      color = const Color(0xFFFF9800);
    }

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => CycleSyncingScreen(phase: phase)),
        );
      },
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.1), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: Icon(Icons.auto_awesome_rounded, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: color, letterSpacing: 0.5),
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, size: 14, color: color.withValues(alpha: 0.5)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade800, height: 1.5, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  "Voir conseils sport & nutrition",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color.withValues(alpha: 0.7)),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDailyTips() {
    final tips = [
      {
        "title": "Bien-être",
        "desc": "La magnésium peut aider à réduire les crampes musculaires.",
        "icon": Icons.lightbulb_outline,
        "color": Colors.orange
      },
      {
        "title": "Sommeil",
        "desc": "Essayez de dormir 8h pour réguler vos hormones.",
        "icon": Icons.nightlight_round,
        "color": Colors.indigo
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            "Conseils du jour",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4A148C)),
          ),
        ),
        SizedBox(
          height: 130,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: tips.length,
            itemBuilder: (context, index) {
              final tip = tips[index];
              return Container(
                width: 260,
                margin: const EdgeInsets.only(right: 15),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (tip['color'] as Color).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(tip['icon'] as IconData, color: tip['color'] as Color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            tip['title'] as String,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tip['desc'] as String,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityAndPrepSection() {
    final bool isNearPeriod = (_data != null && _data!['current_cycle'] != null) && 
        (_data!['current_cycle']['average_cycle_length'] - _data!['current_cycle']['current_day'] <= 3);

    return Column(
      children: [
        // Card 1: Safety Verification
        _buildActionBanner(
          title: "Vérifier ma sécurité",
          subtitle: "Rapport sans risque ou protection ?",
          icon: Icons.verified_user_rounded,
          color: const Color(0xFF1B5E20),
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SafetyCenter()));
          },
        ),
        
        if (isNearPeriod) ...[
          const SizedBox(height: 16),
          // Card 2: Period Prep Kit (Visible only when period is near)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3F5),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.pink.shade100),
            ),
            child: Row(
              children: [
                const Icon(Icons.shopping_bag_rounded, color: Color(0xFFE91E63), size: 24),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Kit Préparation Règles 🩸", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF880E4F))),
                      Text("Anticipez vos douleurs habituelles.", style: TextStyle(fontSize: 12, color: Colors.black54)),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Conseil : Prévoyez magnésium et bouillotte dès demain.")),
                    );
                  },
                  child: const Text("VOIR", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionBanner({required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color)),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: color.withValues(alpha: 0.7))),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color),
          ],
        ),
      ),
    );
  }
}
