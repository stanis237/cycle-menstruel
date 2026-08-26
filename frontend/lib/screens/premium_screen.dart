import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const Icon(Icons.stars_rounded, size: 80, color: Color(0xFFFFD700)),
            const SizedBox(height: 16),
            const Text(
              "Cyclia Premium",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF4A148C)),
            ),
            const SizedBox(height: 8),
            const Text(
              "Débloquez la pleine puissance de votre santé",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            _buildFeatureRow(Icons.people_rounded, "Mode Partenaire (Bientôt)", "Partagez votre cycle avec votre conjoint en toute sécurité."),
            _buildFeatureRow(Icons.cloud_sync_rounded, "Synchronisation Cloud Illimitée", "Retrouvez vos données sur tous vos appareils."),
            _buildFeatureRow(Icons.health_and_safety_rounded, "Analyses Médicales Poussées", "Détection avancée des anomalies et rapports détaillés."),
            _buildFeatureRow(Icons.block, "Zéro Publicité", "Une expérience pure et sans interruption pour toujours."),
            const SizedBox(height: 40),
            _buildSubscriptionOption(
              context,
              "Mensuel",
              "4,99 € / mois",
              "7 jours d'essai gratuit",
              false,
            ),
            const SizedBox(height: 16),
            _buildSubscriptionOption(
              context,
              "Annuel",
              "29,99 € / an",
              "Économisez 50% - Le plus populaire",
              true,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () async {
                await NotificationService().showPromotion(
                  "Bienvenue dans Cyclia Pro ! 🌟",
                  "Votre abonnement a été activé. Découvrez vos nouvelles analyses dès maintenant."
                );
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Abonnement activé avec succès !")),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A148C),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text("Passer à Cyclia Pro", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 20),
            const Text(
              "Annulez à tout moment. Conditions générales applicables.",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFFF3E5F5), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: const Color(0xFF8E24AA)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionOption(BuildContext context, String title, String price, String badge, bool isSelected) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: isSelected ? const Color(0xFF8E24AA) : Colors.grey.shade300, width: 2),
        borderRadius: BorderRadius.circular(20),
        color: isSelected ? const Color(0xFFF3E5F5).withValues(alpha: 0.3) : Colors.white,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(price, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF4A148C))),
              const SizedBox(height: 4),
              Text(badge, style: TextStyle(fontSize: 12, color: isSelected ? const Color(0xFF8E24AA) : Colors.green, fontWeight: FontWeight.bold)),
            ],
          ),
          Icon(isSelected ? Icons.check_circle : Icons.circle_outlined, color: const Color(0xFF8E24AA)),
        ],
      ),
    );
  }
}
