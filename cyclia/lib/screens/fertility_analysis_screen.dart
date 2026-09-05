import 'package:flutter/material.dart';
import '../services/api_service.dart';

class FertilityAnalysisScreen extends StatefulWidget {
  const FertilityAnalysisScreen({super.key});

  @override
  State<FertilityAnalysisScreen> createState() => _FertilityAnalysisScreenState();
}

class _FertilityAnalysisScreenState extends State<FertilityAnalysisScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  double _confidenceScore = 0.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final entries = await _apiService.getDailyEntries();
    if (entries != null) {
      // Logic to calculate confidence based on data completion
      int loggedDays = entries.length;
      int tempLogged = entries.where((e) => e['temperature'] != null).length;
      int mucusLogged = entries.where((e) => e['cervical_mucus'] != null && e['cervical_mucus'] != 'none').length;
      
      setState(() {
        _confidenceScore = (tempLogged + mucusLogged) / (loggedDays * 2).clamp(1, 100);
        if (_confidenceScore > 1.0) _confidenceScore = 1.0;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7FC),
      appBar: AppBar(
        title: const Text("Analyse de Protection", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4A148C))),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildConfidenceCard(),
                  const SizedBox(height: 24),
                  _buildBiologicalShieldStatus(),
                  const SizedBox(height: 24),
                  const Text("Facteurs de Risque", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4A148C))),
                  const SizedBox(height: 16),
                  _buildRiskTile("Oubli de saisie", "Il manque 3 jours de température.", Icons.warning_amber_rounded, Colors.orange),
                  _buildRiskTile("Stress détecté", "Le mode Blocus est actif, l'ovulation peut être décalée.", Icons.psychology_rounded, Colors.blue),
                  const SizedBox(height: 32),
                  _buildEducationSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildConfidenceCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
      ),
      child: Column(
        children: [
          const Text("FIABILITÉ DE L'ALGORITHME", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2, color: Colors.grey)),
          const SizedBox(height: 16),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  value: _confidenceScore,
                  strokeWidth: 12,
                  backgroundColor: Colors.grey.shade100,
                  color: _confidenceScore > 0.8 ? Colors.green : Colors.orange,
                ),
              ),
              Text(
                "${(_confidenceScore * 100).toInt()}%",
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _confidenceScore > 0.8 
                ? "Vos données sont excellentes. Les prédictions de zone sûre sont très précises."
                : "Ajoutez plus de données (température/mucus) pour sécuriser vos prédictions.",
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildBiologicalShieldStatus() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF4A148C), Color(0xFF8E24AA)]),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Row(
        children: [
          Icon(Icons.shield_rounded, color: Color(0xFFFFD700), size: 30),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Bouclier Biologique", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                Text("L'ovulation n'est pas encore confirmée. Protection recommandée.", style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskTile(String title, String desc, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(desc, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEducationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Comprendre ma sécurité", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4A148C))),
        const SizedBox(height: 16),
        _buildInfoCard("La règle des 3 jours", "L'ovulation est confirmée après 3 jours consécutifs de température haute.", Icons.thermostat),
        const SizedBox(height: 12),
        _buildInfoCard("Le Mucus Cervical", "Si vous voyez de la glaire type 'blanc d'œuf', vous êtes extrêmement fertile.", Icons.opacity),
      ],
    );
  }

  Widget _buildInfoCard(String title, String desc, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFF3E5F5), borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF8E24AA), size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text("$title: $desc", style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }
}
