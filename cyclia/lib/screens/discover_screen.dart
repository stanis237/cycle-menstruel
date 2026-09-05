import 'package:flutter/material.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  String _selectedCategory = "Tout";

  final List<Map<String, String>> _categories = [
    {"name": "Tout", "icon": "🌟"},
    {"name": "Nutrition", "icon": "🥗"},
    {"name": "Sommeil", "icon": "😴"},
    {"name": "Fitness", "icon": "🏋️"},
    {"name": "Bien-être", "icon": "🧘"},
  ];

  final List<Map<String, String>> _allArticles = [
    {
      "title": "5 aliments pour réduire les crampes",
      "duration": "3 min",
      "category": "Nutrition",
      "image": "https://images.unsplash.com/photo-1490645935967-10de6ba17061?q=80&w=200&auto=format&fit=crop"
    },
    {
      "title": "Comprendre sa phase lutéale",
      "duration": "5 min",
      "category": "Bien-être",
      "image": "https://images.unsplash.com/photo-1518310383802-640c2de311b2?q=80&w=200&auto=format&fit=crop"
    },
    {
      "title": "Pourquoi on dort mal avant les règles ?",
      "duration": "4 min",
      "category": "Sommeil",
      "image": "https://images.unsplash.com/photo-1541781774459-bb2af2f05b55?q=80&w=200&auto=format&fit=crop"
    },
    {
      "title": "Le sport idéal selon votre cycle",
      "duration": "6 min",
      "category": "Fitness",
      "image": "https://images.unsplash.com/photo-1517836357463-d25dfeac3438?q=80&w=200&auto=format&fit=crop"
    },
    {
      "title": "L'hydratation et le cycle hormonal",
      "duration": "2 min",
      "category": "Nutrition",
      "image": "https://images.unsplash.com/photo-1548839140-29a749e1cf4d?q=80&w=200&auto=format&fit=crop"
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filteredArticles = _selectedCategory == "Tout"
        ? _allArticles
        : _allArticles.where((a) => a['category'] == _selectedCategory).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7FC),
      appBar: AppBar(
        title: const Text(
          "Découvrir",
          style: TextStyle(color: Color(0xFF4A148C), fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
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
            const SizedBox(height: 32),
            const Text(
              "Catégories",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4A148C)),
            ),
            const SizedBox(height: 16),
            _buildInteractiveCategories(),
            const SizedBox(height: 32),
            _buildShopSection(),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedCategory == "Tout" ? "Articles populaires" : "Articles : $_selectedCategory",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4A148C)),
                ),
                if (_selectedCategory != "Tout")
                  TextButton(
                    onPressed: () => setState(() => _selectedCategory = "Tout"),
                    child: const Text("Voir tout"),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _buildArticleList(filteredArticles),
            const SizedBox(height: 40),
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
        borderRadius: BorderRadius.circular(28),
        image: const DecorationImage(
          image: NetworkImage('https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?q=80&w=1000&auto=format&fit=crop'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Color(0xFF8E24AA), borderRadius: BorderRadius.circular(8)),
              child: Text(
                "SANTÉ MENTALE",
                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2),
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Comment le cycle influence votre humeur",
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractiveCategories() {
    return SizedBox(
      height: 45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategory == cat['name'];
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilterChip(
              label: Text("${cat['icon']} ${cat['name']}"),
              selected: isSelected,
              onSelected: (bool selected) {
                setState(() {
                  _selectedCategory = cat['name']!;
                });
              },
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFFF3E5F5),
              checkmarkColor: const Color(0xFF8E24AA),
              labelStyle: TextStyle(
                color: isSelected ? const Color(0xFF4A148C) : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: isSelected ? const Color(0xFF8E24AA) : Colors.grey.shade200),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildArticleList(List<Map<String, String>> articles) {
    if (articles.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text("Aucun article trouvé dans cette catégorie.", style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return Column(
      children: articles.map((art) {
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.grey.shade100),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(art['image']!, width: 70, height: 70, fit: BoxFit.cover),
            ),
            title: Text(
              art['title']!,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF4A148C)),
            ),
            subtitle: Row(
              children: [
                Text(
                  art['category']!,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF8E24AA), fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.access_time, size: 12, color: Colors.grey),
                const SizedBox(width: 4),
                Text(art['duration']!, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
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
        const SizedBox(height: 16),
        SizedBox(
          height: 140,
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
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(p['icon'] as IconData, color: const Color(0xFFE91E63), size: 28),
                    const SizedBox(height: 8),
                    Text(p['name'] as String, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    const SizedBox(height: 4),
                    Text(p['price'] as String, style: const TextStyle(fontSize: 13, color: Color(0xFF4A148C), fontWeight: FontWeight.w900)),
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
