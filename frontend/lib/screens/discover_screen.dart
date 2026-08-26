import 'package:flutter/material.dart';

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7FC),
      appBar: AppBar(
        title: const Text(
          "Découvrir",
          style: TextStyle(color: Color(0xFF4A148C), fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Pour vous aujourd'hui",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF4A148C)),
            ),
            const SizedBox(height: 16),
            _buildFeaturedArticle(),
            const SizedBox(height: 24),
            const Text(
              "Catégories",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4A148C)),
            ),
            const SizedBox(height: 12),
            _buildCategories(),
            const SizedBox(height: 24),
            _buildShopSection(),
            const SizedBox(height: 24),
            const Text(
              "Articles populaires",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4A148C)),
            ),
            const SizedBox(height: 12),
            _buildArticleList(),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedArticle() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        image: const DecorationImage(
          image: NetworkImage('https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?q=80&w=1000&auto=format&fit=crop'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "SANTÉ MENTALE",
              style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
            SizedBox(height: 4),
            Text(
              "Comment le cycle influence votre humeur",
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategories() {
    final categories = [
      {"name": "Nutrition", "icon": Icons.restaurant, "color": Colors.orange},
      {"name": "Sommeil", "icon": Icons.bedtime, "color": Colors.indigo},
      {"name": "Fitness", "icon": Icons.fitness_center, "color": Colors.green},
      {"name": "Bien-être", "icon": Icons.spa, "color": Colors.teal},
    ];

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          return Container(
            width: 80,
            margin: const EdgeInsets.only(right: 12),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (cat['color'] as Color).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(cat['icon'] as IconData, color: cat['color'] as Color),
                ),
                const SizedBox(height: 8),
                Text(
                  cat['name'] as String,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildArticleList() {
    final articles = [
      {
        "title": "5 aliments pour réduire les crampes",
        "duration": "3 min",
        "image": "https://images.unsplash.com/photo-1490645935967-10de6ba17061?q=80&w=200&auto=format&fit=crop"
      },
      {
        "title": "Comprendre sa phase lutéale",
        "duration": "5 min",
        "image": "https://images.unsplash.com/photo-1518310383802-640c2de311b2?q=80&w=200&auto=format&fit=crop"
      },
    ];

    return Column(
      children: articles.map((art) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(art['image']!, width: 60, height: 60, fit: BoxFit.cover),
            ),
            title: Text(
              art['title']!,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Text(
              "Lecture : ${art['duration']}",
              style: const TextStyle(fontSize: 12),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
        );
      }).toList(),
    );
  }

  Widget _buildShopSection() {
    final products = [
      {"name": "Test Ovulation x10", "price": "19,90 €", "icon": Icons.science_outlined},
      {"name": "Magnésium Bio", "price": "14,50 €", "icon": Icons.health_and_safety_outlined},
      {"name": "Tisane Cycle Zen", "price": "9,00 €", "icon": Icons.emoji_food_beverage_outlined},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Boutique Cyclia",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4A148C)),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            itemBuilder: (context, index) {
              final p = products[index];
              return Container(
                width: 140,
                margin: const EdgeInsets.only(right: 15),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(p['icon'] as IconData, color: const Color(0xFFE91E63), size: 30),
                    const SizedBox(height: 12),
                    Text(p['name'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    const SizedBox(height: 4),
                    Text(p['price'] as String, style: const TextStyle(fontSize: 14, color: Color(0xFF4A148C), fontWeight: FontWeight.w900)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
