import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import 'dashboard_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();

  DateTime? _birthDate;
  DateTime? _lastPeriodDate;
  int _cycleLength = 28;
  int _periodLength = 5;
  bool _isIrregular = false;
  String _objective = 'track';
  bool _isLoading = false;

  Future<void> _selectBirthDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1960),
      lastDate: DateTime.now(),
      locale: const Locale('fr', 'FR'),
    );
    if (picked != null && picked != _birthDate) {
      setState(() {
        _birthDate = picked;
      });
    }
  }

  Future<void> _selectLastPeriodDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now(),
      locale: const Locale('fr', 'FR'),
    );
    if (picked != null && picked != _lastPeriodDate) {
      setState(() {
        _lastPeriodDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (_lastPeriodDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez renseigner la date de vos dernières règles.")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final formattedBirthDate = _birthDate != null ? DateFormat('yyyy-MM-dd').format(_birthDate!) : null;
    final formattedLastPeriodDate = DateFormat('yyyy-MM-dd').format(_lastPeriodDate!);

    // 1. Update Profile info
    final profileSuccess = await _apiService.updateProfile({
      'profile': {
        'birth_date': formattedBirthDate,
        'average_cycle_length': _cycleLength,
        'average_period_length': _periodLength,
        'is_irregular_declared': _isIrregular,
        'objective': _objective,
      }
    });

    if (profileSuccess) {
      // 2. Start initial cycle
      final cycleSuccess = await _apiService.startCycle(formattedLastPeriodDate);
      
      if (cycleSuccess != null) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
        return;
      }
    }

    setState(() {
      _isLoading = false;
    });
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Une erreur s'est produite lors de la configuration. Veuillez réessayer.")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF3E5F5), // Light purple
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    "Bienvenue sur Cyclia",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A148C),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Configurons votre profil pour personnaliser vos prédictions de cycle.",
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.black54,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

                  // Card 1: Objective
                  _buildSectionCard(
                    title: "Quel est votre objectif principal ?",
                    icon: Icons.track_changes_rounded,
                    child: Column(
                      children: [
                        _buildObjectiveTile('track', 'Suivi de cycle', 'Comprendre mon corps et anticiper mes règles'),
                        const SizedBox(height: 10),
                        _buildObjectiveTile('pregnancy', 'Désir de grossesse', 'Optimiser mes chances de conception naturelle'),
                        const SizedBox(height: 10),
                        _buildObjectiveTile('contraception', 'Contraception naturelle', 'Suivre ma fertilité avec la méthode symptothermique'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Card 2: Dates
                  _buildSectionCard(
                    title: "Informations importantes",
                    icon: Icons.calendar_month_rounded,
                    child: Column(
                      children: [
                        // Birth Date
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text("Votre date de naissance (Optionnel)"),
                          subtitle: Text(
                            _birthDate == null 
                                ? "Non renseignée" 
                                : DateFormat('dd MMMM yyyy', 'fr_FR').format(_birthDate!),
                          ),
                          trailing: const Icon(Icons.cake_outlined, color: Color(0xFF8E24AA)),
                          onTap: () => _selectBirthDate(context),
                        ),
                        const Divider(),
                        // Last Period Date
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text("Premier jour de vos dernières règles"),
                          subtitle: Text(
                            _lastPeriodDate == null 
                                ? "Sélectionner la date" 
                                : DateFormat('dd MMMM yyyy', 'fr_FR').format(_lastPeriodDate!),
                            style: TextStyle(
                              color: _lastPeriodDate == null ? Colors.red : Colors.black87,
                            ),
                          ),
                          trailing: const Icon(Icons.bloodtype_outlined, color: Color(0xFFE91E63)),
                          onTap: () => _selectLastPeriodDate(context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Card 3: Cycle details
                  _buildSectionCard(
                    title: "Durée de vos cycles",
                    icon: Icons.timelapse_rounded,
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
                          inactiveColor: const Color(0xFFE0E0E0),
                          onChanged: (val) {
                            setState(() {
                              _cycleLength = val.toInt();
                            });
                          },
                        ),
                        const SizedBox(height: 15),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Durée des règles :"),
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
                          inactiveColor: const Color(0xFFE0E0E0),
                          onChanged: (val) {
                            setState(() {
                              _periodLength = val.toInt();
                            });
                          },
                        ),
                        const Divider(height: 32),
                        SwitchListTile(
                          title: const Text("Mes cycles sont irréguliers"),
                          subtitle: const Text("Cochez si la durée de vos cycles varie souvent de plus de 7 jours."),
                          value: _isIrregular,
                          activeThumbColor: const Color(0xFF8E24AA),
                          contentPadding: EdgeInsets.zero,
                          onChanged: (val) {
                            setState(() {
                              _isIrregular = val;
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Submit Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A148C),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            "Commencer",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required Widget child}) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF4A148C)),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF4A148C)),
                ),
              ],
            ),
            const SizedBox(height: 15),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildObjectiveTile(String value, String title, String subtitle) {
    final isSelected = _objective == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _objective = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF3E5F5) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF8E24AA) : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: const Color(0xFF8E24AA),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? const Color(0xFF4A148C) : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
