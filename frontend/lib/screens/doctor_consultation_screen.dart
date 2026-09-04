import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class DoctorConsultationScreen extends StatefulWidget {
  const DoctorConsultationScreen({super.key});

  @override
  State<DoctorConsultationScreen> createState() => _DoctorConsultationScreenState();
}

class _DoctorConsultationScreenState extends State<DoctorConsultationScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  Map<String, dynamic>? _data;
  List<dynamic> _cycles = [];

  @override
  void initState() {
    super.initState();
    _loadMedicalData();
  }

  Future<void> _loadMedicalData() async {
    final results = await Future.wait([
      _apiService.getPredictions(),
      _apiService.getCycles(),
    ]);

    setState(() {
      _data = results[0] as Map<String, dynamic>?;
      _cycles = results[1] as List<dynamic>? ?? [];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Professional clean background
      appBar: AppBar(
        title: const Text("Rapport de Consultation", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Génération du PDF médical...")),
              );
            },
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMedicalHeader(),
                  const SizedBox(height: 32),
                  _buildSectionTitle("Historique des Cycles (6 mois)"),
                  _buildCycleTable(),
                  const SizedBox(height: 32),
                  _buildSectionTitle("Analyse de la Régularité"),
                  _buildRegularitySummary(),
                  const SizedBox(height: 32),
                  _buildSectionTitle("Symptômes Prédominants"),
                  _buildSymptomSummary(),
                  const SizedBox(height: 40),
                  _buildFooter(),
                ],
              ),
            ),
    );
  }

  Widget _buildMedicalHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.medical_services_rounded, color: Colors.blue, size: 30),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Données de Santé", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text("Généré par Cyclia Health", style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
        Text(
          DateFormat('dd/MM/yyyy').format(DateTime.now()),
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildCycleTable() {
    if (_cycles.isEmpty) return const Text("Aucune donnée enregistrée.");

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Table(
        border: TableBorder.symmetric(inside: BorderSide(color: Colors.grey.shade100)),
        children: [
          const TableRow(
            decoration: BoxDecoration(color: Color(0xFFF5F7FA)),
            children: [
              _Cell("Début", isHeader: true),
              _Cell("Durée", isHeader: true),
              _Cell("Flux", isHeader: true),
            ],
          ),
          ..._cycles.take(6).map((c) {
            final start = DateTime.parse(c['start_date']);
            return TableRow(
              children: [
                _Cell(DateFormat('dd MMM yyyy').format(start)),
                _Cell("${c['duration'] ?? '--'} j"),
                _Cell(c['flow_avg'] ?? "Normal"),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRegularitySummary() {
    final analysis = _data?['analysis'];
    final bool isIrregular = analysis?['regularity_status'] == "Irrégulier";
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isIrregular ? Colors.orange.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isIrregular ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
                color: isIrregular ? Colors.orange : Colors.green,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                "Statut : ${analysis?['regularity_status'] ?? 'Stable'}",
                style: TextStyle(fontWeight: FontWeight.bold, color: isIrregular ? Colors.orange.shade900 : Colors.green.shade900),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Variation moyenne : ${analysis?['variation_days'] ?? 0} jours.",
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildSymptomSummary() {
    return Column(
      children: [
        _buildMedicalSymptomRow("Douleurs (Dysménorrhée)", "Fréquentes (80%)", Colors.red),
        _buildMedicalSymptomRow("Humeur (SPM)", "Irritabilité légère", Colors.orange),
        _buildMedicalSymptomRow("Ménorragie", "Flux modéré", Colors.blue),
      ],
    );
  }

  Widget _buildMedicalSymptomRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
      child: const Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: Colors.grey),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              "Ce document est une aide à la consultation et ne remplace pas un diagnostic médical.",
              style: TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final String text;
  final bool isHeader;
  const _Cell(this.text, {this.isHeader = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          fontSize: isHeader ? 12 : 14,
          color: isHeader ? Colors.grey.shade700 : Colors.black87,
        ),
      ),
    );
  }
}
