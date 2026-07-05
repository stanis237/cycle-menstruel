import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'calendar_screen.dart';
import 'symptoms_screen.dart';
import 'profile_screen.dart';

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
      _isLoading = false;
    });
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
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      todayStr,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // Central Status Ring
                    _buildCycleStatusRing(),

                    const SizedBox(height: 30),

                    // Bottom Navigation Grid
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionCard(
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
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: _buildActionCard(
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
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Symptoms Summary or CTA
                    _buildTodaySymptomSummary(),

                    const SizedBox(height: 20),

                    // Next cycle details
                    _buildNextCycleCard(),
                    
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: const Color(0xFF8E24AA),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 1) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CalendarScreen()),
            );
          } else if (index == 2) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ).then((_) => _loadDashboardData());
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "Accueil"),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: "Calendrier"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profil"),
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

    return Center(
      child: Container(
        width: 250,
        height: 250,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: phaseColor.withValues(alpha: 0.15),
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
              width: 210,
              height: 210,
              child: CircularProgressIndicator(
                value: percentage,
                strokeWidth: 12,
                backgroundColor: phaseColor.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(phaseColor),
              ),
            ),
            // Central Content
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  phaseIcon,
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(height: 8),
                Text(
                  "JOUR",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade400,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  "$currentDay",
                  style: TextStyle(
                    fontSize: 54,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF4A148C),
                    height: 1.1,
                  ),
                ),
                Text(
                  phase,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: phaseColor,
                  ),
                ),
                const SizedBox(height: 8),
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
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A148C),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
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
      return Card(
        color: const Color(0xFFFFF3F5),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Icon(Icons.favorite_border_rounded, color: Color(0xFFE91E63)),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Suivi quotidien",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF880E4F)),
                    ),
                    Text(
                      "Vous n'avez pas encore noté vos symptômes aujourd'hui.",
                      style: TextStyle(fontSize: 12, color: Colors.pink.shade900.withValues(alpha: 0.7)),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SymptomsScreen()),
                  );
                  _loadDashboardData();
                },
                child: const Text("Noter"),
              ),
            ],
          ),
        ),
      );
    }

    final entry = _todayEntry!;
    List<String> logged = [];
    if (entry['flow_intensity'] != null && entry['flow_intensity'] > 0) {
      logged.add("Flux: ${_getIntensityText(entry['flow_intensity'])}");
    }
    if (entry['pain_intensity'] != null && entry['pain_intensity'] > 0) {
      logged.add("Douleur: ${_getIntensityText(entry['pain_intensity'])}");
    }
    if (entry['mood'] != null && entry['mood'].toString().isNotEmpty) {
      logged.add("Humeur: ${entry['mood']}");
    }
    if (entry['energy_level'] != null) {
      logged.add("Énergie: ${entry['energy_level']}/5");
    }

    return Card(
      color: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.favorite_rounded, color: Color(0xFFE91E63), size: 18),
                    SizedBox(width: 8),
                    Text(
                      "Symptômes du jour",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF4A148C)),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SymptomsScreen()),
                    );
                    _loadDashboardData();
                  },
                  child: const Text("Modifier"),
                ),
              ],
            ),
            const SizedBox(height: 8),
            logged.isEmpty
                ? const Text("Rien de particulier noté aujourd'hui.", style: TextStyle(fontSize: 13, color: Colors.black54))
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: logged.map((tag) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFCE4EC),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(fontSize: 11, color: Color(0xFFC2185B), fontWeight: FontWeight.w600),
                      ),
                    )).toList(),
                  ),
            if (entry['notes'] != null && entry['notes'].toString().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                "Note : \"${entry['notes']}\"",
                style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.black87),
              ),
            ],
          ],
        ),
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
    final startStr = _formatDateStr(nextPrediction['predicted_start']);
    final fertileStartStr = _formatDateStr(nextPrediction['predicted_fertile_start']);
    final fertileEndStr = _formatDateStr(nextPrediction['predicted_fertile_end']);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE8EAF6), Color(0xFFE1BEE7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Prochaines prévisions",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A237E),
            ),
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
                      "Fenêtre de fertilité estimée",
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
}
