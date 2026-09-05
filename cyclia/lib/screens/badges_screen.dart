import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'premium_screen.dart';

class BadgesScreen extends StatefulWidget {
  const BadgesScreen({super.key});

  @override
  State<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends State<BadgesScreen> {
  final ApiService _apiService = ApiService();
  bool _isPremium = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkPremiumStatus();
  }

  Future<void> _checkPremiumStatus() async {
    final profile = await _apiService.getProfile();
    if (profile != null && profile['profile'] != null) {
      setState(() {
        _isPremium = profile['profile']['is_premium'] ?? false;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7FC),
      appBar: AppBar(
        title: const Text("Mes Trophées", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4A148C))),
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
                  const Text("Badges Classiques", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4A148C))),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.9,
                    children: [
                      _buildBadgeCard("Bronze", "1 mois serein", Icons.shield_rounded, Colors.orange.shade300, true, false),
                      _buildBadgeCard("Argent", "3 mois sereins", Icons.shield_rounded, Colors.blueGrey.shade300, true, false),
                      _buildBadgeCard("Or", "6 mois sereins", Icons.shield_rounded, const Color(0xFFFFD700), false, false),
                      _buildBadgeCard("Série 🔥", "21j de pilule", Icons.local_fire_department_rounded, Colors.deepOrange, true, false),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("👑 Badges Élite", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF8E24AA))),
                      if (!_isPremium)
                        GestureDetector(
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PremiumScreen())),
                          child: const Text("DEVENIR PRO >", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF8E24AA))),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.9,
                    children: [
                      _buildBadgeCard("Diamant", "1 an de protection", Icons.diamond_rounded, Colors.blue.shade300, false, true),
                      _buildBadgeCard("Zen Master", "Stress maîtrisé", Icons.self_improvement_rounded, Colors.teal.shade300, false, true),
                      _buildBadgeCard("Bio Expert", "Cycles parfaits", Icons.auto_awesome_rounded, Colors.purple.shade300, false, true),
                      _buildBadgeCard("Ambassadeur", "Invitations réussies", Icons.people_rounded, Colors.pink.shade300, false, true),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildBadgeCard(String title, String desc, IconData icon, Color color, bool isUnlocked, bool isElite) {
    bool canSee = !isElite || _isPremium;
    
    return GestureDetector(
      onTap: () {
        if (isElite && !_isPremium) {
          _showPremiumLockDialog();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
          border: isUnlocked ? Border.all(color: color.withValues(alpha: 0.3), width: 2) : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Opacity(
                  opacity: (isUnlocked && canSee) ? 1.0 : 0.2,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: Icon(icon, color: color, size: 32),
                  ),
                ),
                if (isElite && !_isPremium)
                  const Icon(Icons.lock_rounded, size: 16, color: Color(0xFF8E24AA)),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: (isUnlocked && canSee) ? Colors.black87 : Colors.grey,
              ),
            ),
            Text(
              desc,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 9, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  void _showPremiumLockDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.stars_rounded, color: Color(0xFFFFD700)),
            SizedBox(width: 10),
            Text("Contenu Élite"),
          ],
        ),
        content: const Text("Les badges Élite sont réservés aux membres Cyclia Premium. Relevez des défis de santé avancés !"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Plus tard")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PremiumScreen()));
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8E24AA), foregroundColor: Colors.white),
            child: const Text("Voir Cyclia Pro"),
          ),
        ],
      ),
    );
  }
}
