import 'package:flutter/material.dart';
import '../services/api_service.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _cycles = [];
  Map<String, dynamic>? _analysis;
  Map<String, dynamic>? _currentCycle;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final cycles = await _apiService.getCycles();
    final predictions = await _apiService.getPredictions();
    
    setState(() {
      _cycles = cycles ?? [];
      if (predictions != null) {
        _analysis = predictions['analysis'];
        _currentCycle = predictions['current_cycle'];
      }
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7FC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF4A148C)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          "Analyses & Santé",
          style: TextStyle(color: Color(0xFF4A148C), fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF8E24AA)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Génération de votre rapport PDF en cours...")),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF8E24AA)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRegularityCard(),
                  const SizedBox(height: 20),
                  _buildSummaryStats(),
                  const SizedBox(height: 20),
                  _buildExportCTA(),
                  const SizedBox(height: 24),
                  const Text(
                    "Historique des cycles",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4A148C)),
                  ),
                  const SizedBox(height: 12),
                  _buildCycleHistoryGraph(),
                  const SizedBox(height: 24),
                  const Text(
                    "Fréquence des symptômes",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4A148C)),
                  ),
                  const SizedBox(height: 12),
                  _buildSymptomStats(),
                  const SizedBox(height: 24),
                  const Text(
                    "Équilibre des humeurs",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4A148C)),
                  ),
                  const SizedBox(height: 12),
                  _buildMoodDistribution(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildRegularityCard() {
    final status = _analysis?['regularity_status'] ?? "Analyse en cours...";
    final variation = _analysis?['variation_days'] ?? 0;
    final bool isIrregular = status == "Irrégulier";

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isIrregular 
              ? [const Color(0xFFFFF3E0), const Color(0xFFFFE0B2)]
              : [const Color(0xFFF3E5F5), const Color(0xFFE1BEE7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Statut : $status",
                style: TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold, 
                  color: isIrregular ? Colors.orange.shade900 : const Color(0xFF4A148C)
                ),
              ),
              Icon(
                isIrregular ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
                color: isIrregular ? Colors.orange : const Color(0xFF8E24AA),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isIrregular
                ? "Vos cycles présentent une variation de $variation jours. Les prédictions sont affichées sous forme de plages de dates pour plus de précision."
                : "Vos cycles sont réguliers (variation de $variation jours). Vos prédictions sont très fiables.",
            style: TextStyle(
              fontSize: 14, 
              color: isIrregular ? Colors.orange.shade800 : Colors.purple.shade900,
              height: 1.4
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStats() {
    final avgCycle = _currentCycle?['average_cycle_length'] ?? 28;
    final avgPeriod = _currentCycle?['average_period_length'] ?? 5;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            "Cycle Moyen",
            "$avgCycle jours",
            Icons.sync,
            Colors.purple,
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _buildStatCard(
            "Règles Moyennes",
            "$avgPeriod jours",
            Icons.water_drop,
            Colors.pink,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF4A148C)),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildCycleHistoryGraph() {
    // Simulated data for visualization
    final data = [27, 29, 28, 30, 26, 28];
    
    return Container(
      height: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: data.map((d) {
                final heightFactor = (d - 20) / 15; // Normalize for graph
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 20,
                      height: 120 * heightFactor,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3E5F5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        width: 20,
                        height: 30, // Period length simulation
                        decoration: BoxDecoration(
                          color: const Color(0xFFE91E63),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text("${d}j", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.square, color: Color(0xFFE91E63), size: 10),
              SizedBox(width: 4),
              Text("Règles", style: TextStyle(fontSize: 10)),
              SizedBox(width: 15),
              Icon(Icons.square, color: Color(0xFFF3E5F5), size: 10),
              SizedBox(width: 4),
              Text("Cycle", style: TextStyle(fontSize: 10)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSymptomStats() {
    final symptoms = [
      {"name": "Crampes", "percent": 0.8, "color": Colors.red},
      {"name": "Maux de tête", "percent": 0.4, "color": Colors.orange},
      {"name": "Fatigue", "percent": 0.6, "color": Colors.blue},
      {"name": "Ballonnements", "percent": 0.3, "color": Colors.green},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: symptoms.map((s) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(s['name'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    Text("${((s['percent'] as double) * 100).toInt()}%", style: const TextStyle(fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: s['percent'] as double,
                  backgroundColor: Colors.grey.shade100,
                  color: s['color'] as Color,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildExportCTA() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EAF6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.indigo.shade100),
      ),
      child: Row(
        children: [
          const Icon(Icons.assignment_turned_in_rounded, color: Colors.indigo, size: 30),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Rapport médical gratuit",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1A237E)),
                ),
                Text(
                  "Exportez vos 3 derniers mois de données.",
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
               ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Préparation du document PDF...")),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Exporter"),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodDistribution() {
    final moods = [
      {"name": "Calme", "emoji": "😊", "percent": 0.4},
      {"name": "Heureuse", "emoji": "😄", "percent": 0.3},
      {"name": "Irritable", "emoji": "😠", "percent": 0.15},
      {"name": "Triste", "emoji": "😢", "percent": 0.15},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: moods.map((m) {
          return Column(
            children: [
              Text(m['emoji'] as String, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 8),
              Text(
                "${((m['percent'] as double) * 100).toInt()}%",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Text(m['name'] as String, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
            ],
          );
        }).toList(),
      ),
    );
  }
}
