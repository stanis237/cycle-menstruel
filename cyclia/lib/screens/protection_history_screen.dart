import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class ProtectionHistoryScreen extends StatefulWidget {
  const ProtectionHistoryScreen({super.key});

  @override
  State<ProtectionHistoryScreen> createState() => _ProtectionHistoryScreenState();
}

class _ProtectionHistoryScreenState extends State<ProtectionHistoryScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _entries = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final entries = await _apiService.getDailyEntries();
    if (entries != null) {
      // Filter entries that have sex or contraception info and sort by date descending
      final filtered = entries.where((e) => 
        e['had_sex'] == true || 
        e['pill_taken'] == true || 
        e['used_contraception'] == true
      ).toList();
      filtered.sort((a, b) => b['date'].compareTo(a['date']));
      setState(() {
        _entries = filtered;
      });
    }
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7FC),
      appBar: AppBar(
        title: const Text("Journal de Protection", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4A148C))),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _entries.length,
                  itemBuilder: (context, index) {
                    final entry = _entries[index];
                    return _buildHistoryCard(entry);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shield_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 20),
          Text("Aucune donnée enregistrée", style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
          const SizedBox(height: 8),
          Text("Notez vos rapports et prises de pilule.", style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> entry) {
    final date = DateTime.parse(entry['date']);
    final formattedDate = DateFormat('EEEE dd MMMM', 'fr_FR').format(date);
    
    final bool hadSex = entry['had_sex'] ?? false;
    final bool protected = entry['sex_details'] == 'protected';
    final bool pillTaken = entry['pill_taken'] ?? false;
    final bool otherProt = entry['used_contraception'] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(formattedDate, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4A148C), fontSize: 15)),
          const SizedBox(height: 16),
          if (pillTaken)
            _buildStatusRow(Icons.check_circle, "Pilule contraceptive prise", Colors.orange),
          if (hadSex)
            _buildStatusRow(
              protected ? Icons.favorite : Icons.favorite_border,
              "Rapport sexuel ${protected ? 'protégé' : 'non protégé'}",
              protected ? Colors.green : Colors.red,
            ),
          if (otherProt)
            _buildStatusRow(Icons.shield, "Protection : ${entry['contraception_method'] ?? 'Autre'}", Colors.blue),
        ],
      ),
    );
  }

  Widget _buildStatusRow(IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
