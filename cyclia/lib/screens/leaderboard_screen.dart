import 'package:flutter/material.dart';
import '../services/api_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _users = [];

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    final data = await _apiService.getLeaderboard();
    setState(() {
      _users = data ?? [];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7FC),
      appBar: AppBar(
        title: const Text("Communauté Cyclia", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4A148C))),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildHeroCard(),
                const SizedBox(height: 20),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    children: [
                      Text("Classement Sécurité", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF4A148C))),
                      Spacer(),
                      Icon(Icons.info_outline, size: 14, color: Colors.grey),
                      SizedBox(width: 4),
                      Text("Anonyme", style: TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _users.length,
                    itemBuilder: (context, index) {
                      final user = _users[index];
                      return _buildUserTile(user, index + 1);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF4A148C), Color(0xFF8E24AA)]),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: Colors.purple.withValues(alpha: 0.2), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: const Row(
        children: [
          Icon(Icons.emoji_events_rounded, color: Color(0xFFFFD700), size: 50),
          SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Inspirons-nous !", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                SizedBox(height: 4),
                Text(
                  "Rejoignez les milliers de femmes qui maîtrisent leur cycle avec Cyclia.",
                  style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTile(Map<String, dynamic> user, int rank) {
    final bool isMe = user['is_me'] ?? false;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFFF3E5F5) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isMe ? Border.all(color: const Color(0xFF8E24AA), width: 1) : null,
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            alignment: Alignment.center,
            child: Text(
              "$rank",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: rank <= 3 ? const Color(0xFF8E24AA) : Colors.grey,
              ),
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            backgroundColor: Colors.grey.shade100,
            child: Text(_getEmojiForRank(rank), style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['username'],
                  style: TextStyle(fontWeight: FontWeight.bold, color: isMe ? const Color(0xFF4A148C) : Colors.black87),
                ),
                Text("${user['badges']} badges débloqués", style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("${user['score']}%", style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF4A148C))),
              const Text("Sécurité", style: TextStyle(fontSize: 8, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  String _getEmojiForRank(int rank) {
    if (rank == 1) return "🥇";
    if (rank == 2) return "🥈";
    if (rank == 3) return "🥉";
    return "👤";
  }
}
