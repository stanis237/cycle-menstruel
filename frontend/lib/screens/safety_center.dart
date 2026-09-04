import 'package:flutter/material.dart';

class SafetyCenter extends StatelessWidget {
  const SafetyCenter({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7FC),
      appBar: AppBar(
        title: const Text("Centre de Sécurité", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4A148C))),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEmergencyHeader(),
            const SizedBox(height: 32),
            const Text("Guides de Protection", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4A148C))),
            const SizedBox(height: 16),
            _buildGuideCard(
              "Oubli de pilule ?",
              "Agissez dans les 12h. Si le délai est dépassé, utilisez une protection supplémentaire pendant 7 jours.",
              Icons.medication_outlined,
              Colors.orange,
            ),
            const SizedBox(height: 16),
            _buildGuideCard(
              "Accident de parcours ?",
              "La contraception d'urgence (pilule du lendemain) est plus efficace dans les 24h. Ne tardez pas.",
              Icons.warning_amber_rounded,
              Colors.red,
            ),
            const SizedBox(height: 32),
            const Text("Fiabilité des méthodes", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4A148C))),
            const SizedBox(height: 16),
            _buildMethodRow("Préservatif", "98%", Colors.blue),
            _buildMethodRow("Pilule", "99.7%", Colors.green),
            _buildMethodRow("Symptothermie", "97% (si rigoureux)", Colors.purple),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFB71C1C), Color(0xFFE53935)]),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.red.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_rounded, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Text("AIDE D'URGENCE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
            ],
          ),
          SizedBox(height: 16),
          Text(
            "En cas de doute sur un rapport, consultez immédiatement un pharmacien ou un médecin.",
            style: TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideCard(String title, String desc, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(desc, style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodRow(String name, String rate, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(name, style: const TextStyle(fontWeight: FontWeight.w500))),
          Expanded(
            flex: 7,
            child: Stack(
              children: [
                Container(height: 8, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4))),
                FractionallySizedBox(
                  widthFactor: 0.95, // Simulation
                  child: Container(height: 8, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(rate, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 12)),
        ],
      ),
    );
  }
}
