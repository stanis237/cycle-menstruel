import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();

  bool _isLoading = true;
  bool _isSaving = false;
  String _username = "";
  String _email = "";
  
  int _cycleLength = 28;
  int _periodLength = 5;
  bool _isIrregular = false;
  String _objective = 'track';
  bool _privacyEnabled = true;

  TimeOfDay _pillTime = const TimeOfDay(hour: 20, minute: 0);
  bool _pillReminderEnabled = false;
  bool _cycleRemindersEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() {
      _isLoading = true;
    });

    final profile = await _apiService.getProfile();
    
    if (profile != null) {
      final pDetails = profile['profile'] ?? {};
      setState(() {
        _username = profile['username'] ?? "";
        _email = profile['email'] ?? "";
        _cycleLength = pDetails['average_cycle_length'] ?? 28;
        _periodLength = pDetails['average_period_length'] ?? 5;
        _isIrregular = pDetails['is_irregular_declared'] ?? false;
        _objective = pDetails['objective'] ?? 'track';
        _privacyEnabled = pDetails['privacy_enabled'] ?? true;
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveProfile() async {
    setState(() {
      _isSaving = true;
    });

    if (_pillReminderEnabled) {
      await NotificationService().schedulePillReminder(1, _pillTime.hour, _pillTime.minute);
    } else {
      await NotificationService().cancelAll();
    }

    final success = await _apiService.updateProfile({
      'profile': {
        'average_cycle_length': _cycleLength,
        'average_period_length': _periodLength,
        'is_irregular_declared': _isIrregular,
        'objective': _objective,
        'privacy_enabled': _privacyEnabled,
      }
    });

    setState(() {
      _isSaving = false;
    });

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profil mis à jour avec succès.")),
      );
      // Wait a short moment to let the user see the snackbar then redirect
      Future.delayed(const Duration(seconds: 1), () {
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
          (route) => false,
        );
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur lors de la mise à jour.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7FC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF4A148C)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          "Paramètres du Profil",
          style: TextStyle(color: Color(0xFF4A148C), fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF8E24AA)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // User Identity Details
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: const Color(0xFFF3E5F5),
                            child: Text(
                              _username.isNotEmpty ? _username[0].toUpperCase() : "U",
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF8E24AA)),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _username,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4A148C)),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _email,
                                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Cycle Parameters
                  _buildSectionCard(
                    title: "Paramètres de calcul",
                    icon: Icons.settings_suggest_rounded,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Durée moyenne du cycle :"),
                            Text(
                              "$_cycleLength jours",
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4A148C)),
                            ),
                          ],
                        ),
                        Slider(
                          value: _cycleLength.toDouble(),
                          min: 20,
                          max: 45,
                          divisions: 25,
                          activeColor: const Color(0xFF8E24AA),
                          onChanged: (val) {
                            setState(() {
                              _cycleLength = val.toInt();
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Durée moyenne des règles :"),
                            Text(
                              "$_periodLength jours",
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE91E63)),
                            ),
                          ],
                        ),
                        Slider(
                          value: _periodLength.toDouble(),
                          min: 3,
                          max: 10,
                          divisions: 7,
                          activeColor: const Color(0xFFE91E63),
                          onChanged: (val) {
                            setState(() {
                              _periodLength = val.toInt();
                            });
                          },
                        ),
                        const Divider(),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text("Cycles irréguliers"),
                          subtitle: const Text("Applique une marge d'incertitude aux prédictions"),
                          value: _isIrregular,
                          activeColor: const Color(0xFF8E24AA),
                          onChanged: (val) {
                            setState(() {
                              _isIrregular = val;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Objective Selection
                  _buildSectionCard(
                    title: "Objectif de l'application",
                    icon: Icons.track_changes_rounded,
                    child: DropdownButtonFormField<String>(
                      value: _objective,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'track', child: Text("Suivi de cycle classique")),
                        DropdownMenuItem(value: 'pregnancy', child: Text("Désir de grossesse (fertilité)")),
                        DropdownMenuItem(value: 'contraception', child: Text("Contraception naturelle")),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _objective = val;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Privacy Switch
                  _buildSectionCard(
                    title: "Confidentialité & Sécurité",
                    icon: Icons.security_rounded,
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text("Chiffrement local activé"),
                      subtitle: const Text("Sécurise l'affichage de vos données sensibles"),
                      value: _privacyEnabled,
                      activeThumbColor: const Color(0xFF8E24AA),
                      onChanged: (val) {
                        setState(() {
                          _privacyEnabled = val;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Notifications & Reminders
                  _buildSectionCard(
                    title: "Rappels & Notifications",
                    icon: Icons.notifications_active_rounded,
                    child: Column(
                      children: [
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text("Rappel de pilule"),
                          subtitle: const Text("Recevoir une notification quotidienne"),
                          value: _pillReminderEnabled,
                          activeColor: const Color(0xFF8E24AA),
                          onChanged: (val) {
                            setState(() {
                              _pillReminderEnabled = val;
                            });
                          },
                        ),
                        if (_pillReminderEnabled)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text("Heure du rappel"),
                            subtitle: Text(_pillTime.format(context)),
                            trailing: const Icon(Icons.access_time_rounded, color: Color(0xFF8E24AA)),
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: _pillTime,
                              );
                              if (picked != null) {
                                setState(() => _pillTime = picked);
                              }
                            },
                          ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text("Rappels de cycle"),
                          subtitle: const Text("Prévisions de règles et d'ovulation"),
                          value: _cycleRemindersEnabled,
                          activeColor: const Color(0xFF8E24AA),
                          onChanged: (val) {
                            setState(() {
                              _cycleRemindersEnabled = val;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Save Profile Button
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A148C),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text("Enregistrer les modifications", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  const SizedBox(height: 16),

                  // Log out button
                  TextButton.icon(
                    icon: const Icon(Icons.logout_rounded, color: Colors.red),
                    label: const Text("Se déconnecter", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    onPressed: () async {
                      await _authService.logout();
                      if (!context.mounted) return;
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required Widget child}) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF8E24AA), size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF4A148C)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}
