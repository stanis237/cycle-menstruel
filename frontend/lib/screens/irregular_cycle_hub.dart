import 'package:flutter/material.dart';
import 'doctor_consultation_screen.dart';

class IrregularCycleHub extends StatelessWidget {
  final double variationDays;
  const IrregularCycleHub({super.key, required this.variationDays});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7FC),
      appBar: AppBar(
        title: const Text("Mon Cycle Irrégulier", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4A148C))),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusHeader(),
            const SizedBox(height: 24),
            _buildInsightCard(
              "Pourquoi est-ce irrégulier ?",
              "Les cycles varient naturellement. Le stress, l'alimentation, le sommeil ou des conditions comme le SOPK peuvent influencer la durée.",
              Icons.help_outline_rounded,
              Colors.blue,
            ),
            const SizedBox(height: 24),
            const Text("Conseils d'experte", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4A148C))),
            const SizedBox(height: 16),
            _buildTipTile("Suivez votre glaire cervicale", "En cycle irrégulier, vos pertes sont le meilleur indicateur de fertilité.", Icons.water_drop_outlined),
            _buildTipTile("Prenez votre température", "Une hausse de 0.3°C confirme que l'ovulation a eu lieu.", Icons.thermostat_rounded),
            _buildTipTile("Réduisez le cortisol", "Le stress bloque l'ovulation. Essayez 5 min de cohérence cardiaque par jour.", Icons.self_improvement_rounded),
            const SizedBox(height: 32),
            _buildSelfObservationChecklist(),
            const SizedBox(height: 32),
            _buildDoctorCard(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSelfObservationChecklist() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF8E24AA).withValues(alpha: 0.2), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("✅ Check-list d'Autonomie", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF4A148C))),
          const SizedBox(height: 16),
          _buildCheckItem("Vérifier ma glaire chaque matin"),
          _buildCheckItem("Prendre ma température avant de me lever"),
          _buildCheckItem("Noter chaque sensation d'humidité"),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          const Text(
            "RAPPEL SÉCURITÉ : En cas d'irrégularité, si vous n'avez pas de données physiques claires, considérez chaque jour comme potentiellement fertile.",
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFC2185B)),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: Color(0xFF8E24AA), size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildStatusHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A237E),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.blue.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("ANALYSE CYCLIA", style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
          const SizedBox(height: 12),
          Text(
            "Variation détectée : ${variationDays.toStringAsFixed(1)} jours",
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "Vos prédictions sont désormais basées sur des plages de dates pour garantir votre sérénité.",
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(String title, String desc, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 10),
          Text(desc, style: TextStyle(color: Colors.grey.shade700, fontSize: 14, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildTipTile(String title, String desc, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFFF3E5F5), shape: BoxShape.circle),
            child: Icon(icon, color: const Color(0xFF8E24AA), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 2),
                Text(desc, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3F5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.pink.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("🚨 Quand consulter ?", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFC2185B))),
          const SizedBox(height: 12),
          _buildBulletPoint("Cycles de moins de 21 jours ou plus de 45 jours."),
          _buildBulletPoint("Absence de règles pendant plus de 3 mois."),
          _buildBulletPoint("Douleurs invalidantes ne passant pas avec du repos."),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const DoctorConsultationScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC2185B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Ouvrir le Rapport Médical"),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("• ", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFC2185B))),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: Colors.black87))),
        ],
      ),
    );
  }
}
