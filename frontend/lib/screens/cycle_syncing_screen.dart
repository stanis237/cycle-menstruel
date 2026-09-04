import 'package:flutter/material.dart';

class CycleSyncingScreen extends StatelessWidget {
  final String phase;
  const CycleSyncingScreen({super.key, required this.phase});

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> data = _getSyncingData(phase);
    final Color phaseColor = data['color'];

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7FC),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            backgroundColor: phaseColor,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                "Cycle Syncing : ${data['title']}",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [phaseColor, phaseColor.withValues(alpha: 0.7)],
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Opacity(
                      opacity: 0.1,
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 150,
                        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                      ),
                    ),
                    Icon(data['icon'], size: 80, color: Colors.white.withValues(alpha: 0.5)),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildIntroCard(data),
                  const SizedBox(height: 32),
                  _buildSectionTitle("🏋️ Sport & Fitness"),
                  const SizedBox(height: 16),
                  _buildInfoCard(
                    title: data['sport_title'],
                    desc: data['sport_desc'],
                    color: Colors.orange,
                    icon: Icons.fitness_center,
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle("🥗 Nutrition & Énergie"),
                  const SizedBox(height: 16),
                  _buildInfoCard(
                    title: data['food_title'],
                    desc: data['food_desc'],
                    color: Colors.green,
                    icon: Icons.restaurant,
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle("🧠 État d'esprit"),
                  const SizedBox(height: 16),
                  _buildInfoCard(
                    title: data['mind_title'],
                    desc: data['mind_desc'],
                    color: Colors.blue,
                    icon: Icons.psychology,
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF4A148C)),
    );
  }

  Widget _buildIntroCard(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          Text(
            data['intro'],
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({required String title, required String desc, required Color color, required IconData icon}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
                const SizedBox(height: 8),
                Text(desc, style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getSyncingData(String phase) {
    if (phase.contains("Règles")) {
      return {
        "title": "Phase Menstruelle",
        "color": const Color(0xFFE91E63),
        "icon": Icons.water_drop,
        "intro": "C'est un moment de renouveau. Vos niveaux d'hormones sont au plus bas. Écoutez votre corps.",
        "sport_title": "Mouvement doux",
        "sport_desc": "Privilégiez le yoga réparateur, la marche lente ou le stretching. Évitez les entraînements intensifs (HIIT).",
        "food_title": "Aliments réconfortants",
        "food_desc": "Focus sur le fer (épinards, viande rouge) et le magnésium (chocolat noir). Buvez beaucoup de tisanes chaudes.",
        "mind_title": "Introspection",
        "mind_desc": "C'est la période idéale pour tenir un journal, méditer et poser vos intentions pour le mois à venir.",
      };
    } else if (phase.contains("fertile")) {
      return {
        "title": "Phase Ovulatoire",
        "color": const Color(0xFF2196F3),
        "icon": Icons.wb_sunny,
        "intro": "Votre énergie et votre confiance sont à leur apogée. Vous êtes au sommet de votre forme !",
        "sport_title": "Haute Intensité",
        "sport_desc": "C'est le moment pour le HIIT, la course rapide ou les cours collectifs dynamiques. Vous avez une force maximale.",
        "food_title": "Aliments légers & frais",
        "food_desc": "Votre métabolisme est efficace. Privilégiez les légumes crus, les fruits et les aliments riches en antioxydants.",
        "mind_title": "Communication",
        "mind_desc": "Vous êtes naturellement plus sociable. Idéal pour les présentations, les rendez-vous ou les sorties entre amis.",
      };
    } else if (phase.contains("folliculaire")) {
      return {
        "title": "Phase Folliculaire",
        "color": const Color(0xFF9C27B0),
        "icon": Icons.eco,
        "intro": "La phase de préparation. Votre énergie remonte progressivement avec la hausse des oestrogènes.",
        "sport_title": "Cardio & Nouveauté",
        "sport_desc": "Essayez de nouveaux sports. La course, la danse ou le vélo sont parfaits pour accompagner cette hausse d'énergie.",
        "food_title": "Énergie & Fermenté",
        "food_desc": "Aliments fermentés (kefir, choucroute) pour la flore et glucides complexes pour l'énergie durable.",
        "mind_title": "Planification",
        "mind_desc": "Votre esprit est clair et créatif. Planifiez vos projets du mois et lancez de nouvelles idées.",
      };
    } else {
      return {
        "title": "Phase Lutéale",
        "color": const Color(0xFFFF9800),
        "icon": Icons.nights_stay,
        "intro": "Votre corps se prépare à un nouveau cycle. Votre température augmente et votre énergie diminue doucement.",
        "sport_title": "Renforcement Modéré",
        "sport_desc": "Pilates, musculation légère ou natation. Écoutez votre fatigue qui peut arriver plus vite.",
        "food_title": "Glucides & Fibres",
        "food_desc": "Augmentez les fibres pour éviter les ballonnements. Focus sur le riz complet, les patates douces et les graines.",
        "mind_title": "Organisation",
        "mind_desc": "Un bon moment pour les tâches administratives, le rangement et la finalisation des projets en cours.",
      };
    }
  }
}
