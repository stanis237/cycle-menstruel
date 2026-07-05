import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class SymptomsScreen extends StatefulWidget {
  final String? initialDate; // YYYY-MM-DD
  const SymptomsScreen({super.key, this.initialDate});

  @override
  State<SymptomsScreen> createState() => _SymptomsScreenState();
}

class _SymptomsScreenState extends State<SymptomsScreen> {
  final ApiService _apiService = ApiService();
  final _notesController = TextEditingController();
  final _tempController = TextEditingController();

  late String _dateStr;
  int _flowIntensity = 0; // 0 to 3
  int _painIntensity = 0; // 0 to 3
  String _selectedMood = "";
  double _energyLevel = 3.0; // 1 to 5
  String _lhTest = "negative";
  bool _isLoading = false;

  final List<Map<String, String>> _moods = [
    {"name": "Calme", "emoji": "😊", "value": "calm"},
    {"name": "Heureuse", "emoji": "😄", "value": "happy"},
    {"name": "Fatiguée", "emoji": "😴", "value": "tired"},
    {"name": "Triste", "emoji": "😢", "value": "sad"},
    {"name": "Irritable", "emoji": "😠", "value": "irritable"},
    {"name": "Anxieuse", "emoji": "😰", "value": "anxious"},
  ];

  @override
  void initState() {
    super.initState();
    _dateStr = widget.initialDate ?? DateFormat('yyyy-MM-dd').format(DateTime.now());
    _loadExistingData();
  }

  Future<void> _loadExistingData() async {
    setState(() {
      _isLoading = true;
    });

    final data = await _apiService.getDailyEntry(_dateStr);
    
    if (data != null) {
      setState(() {
        _flowIntensity = data['flow_intensity'] ?? 0;
        _painIntensity = data['pain_intensity'] ?? 0;
        _selectedMood = data['mood'] ?? "";
        _energyLevel = (data['energy_level'] ?? 3).toDouble();
        _notesController.text = data['notes'] ?? "";
        if (data['temperature'] != null) {
          _tempController.text = data['temperature'].toString();
        }
        _lhTest = data['lh_test'] ?? "negative";
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _save() async {
    setState(() {
      _isLoading = true;
    });

    double? temperature;
    if (_tempController.text.trim().isNotEmpty) {
      temperature = double.tryParse(_tempController.text.trim());
    }

    final entryData = {
      'date': _dateStr,
      'flow_intensity': _flowIntensity,
      'pain_intensity': _painIntensity,
      'mood': _selectedMood,
      'energy_level': _energyLevel.toInt(),
      'notes': _notesController.text.trim(),
      'temperature': temperature,
      'lh_test': _lhTest,
    };

    final success = await _apiService.saveDailyEntry(entryData);

    setState(() {
      _isLoading = false;
    });

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Symptômes enregistrés avec succès.")),
      );
      Navigator.of(context).pop(true); // Return success to parent view to reload dashboard
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Une erreur s'est produite lors de l'enregistrement.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Human readable date
    final dateObj = DateTime.parse(_dateStr);
    final formattedDate = DateFormat('dd MMMM yyyy', 'fr_FR').format(dateObj);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7FC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Color(0xFF4A148C)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          "Symptômes du $formattedDate",
          style: const TextStyle(color: Color(0xFF4A148C), fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF8E24AA)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Flow Intensity
                  _buildSectionCard(
                    title: "Flux menstruel",
                    icon: Icons.water_drop_rounded,
                    child: _buildIntensitySelector(
                      currentValue: _flowIntensity,
                      color: const Color(0xFFE91E63),
                      labels: ["Aucun", "Léger", "Moyen", "Abondant"],
                      onSelected: (val) {
                        setState(() {
                          _flowIntensity = val;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Pain Intensity
                  _buildSectionCard(
                    title: "Douleurs & Crampes",
                    icon: Icons.healing_rounded,
                    child: _buildIntensitySelector(
                      currentValue: _painIntensity,
                      color: const Color(0xFF9C27B0),
                      labels: ["Aucune", "Légère", "Moyenne", "Intense"],
                      onSelected: (val) {
                        setState(() {
                          _painIntensity = val;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Mood Grid
                  _buildSectionCard(
                    title: "Humeur",
                    icon: Icons.mood_rounded,
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _moods.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.2,
                      ),
                      itemBuilder: (context, index) {
                        final m = _moods[index];
                        final isSelected = _selectedMood == m['value'];
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedMood = isSelected ? "" : m['value']!;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFF3E5F5) : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF8E24AA) : Colors.grey.shade300,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(m['emoji']!, style: const TextStyle(fontSize: 24)),
                                const SizedBox(height: 4),
                                Text(
                                  m['name']!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? const Color(0xFF4A148C) : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Energy Level
                  _buildSectionCard(
                    title: "Niveau d'énergie",
                    icon: Icons.bolt_rounded,
                    child: Column(
                      children: [
                        Slider(
                          value: _energyLevel,
                          min: 1,
                          max: 5,
                          divisions: 4,
                          activeColor: const Color(0xFFFF9800),
                          inactiveColor: Colors.grey.shade200,
                          onChanged: (val) {
                            setState(() {
                              _energyLevel = val;
                            });
                          },
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Très bas (1)", style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                            Text("Neutre (3)", style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                            Text("Très élevé (5)", style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Basal Body Temp (Fertility)
                  _buildSectionCard(
                    title: "Température basale (°C)",
                    icon: Icons.thermostat_rounded,
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _tempController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              hintText: "Ex: 36.6",
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        // LH Test result
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Test d'ovulation (LH)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            Row(
                              children: [
                                ChoiceChip(
                                  label: const Text("-"),
                                  selected: _lhTest == "negative",
                                  onSelected: (selected) {
                                    if (selected) setState(() => _lhTest = "negative");
                                  },
                                ),
                                const SizedBox(width: 8),
                                ChoiceChip(
                                  label: const Text("+"),
                                  selected: _lhTest == "positive",
                                  onSelected: (selected) {
                                    if (selected) setState(() => _lhTest = "positive");
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Notes
                  _buildSectionCard(
                    title: "Notes personnelles",
                    icon: Icons.note_alt_rounded,
                    child: TextField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: "Ajoutez des notes sur votre état physique ou mental...",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Save Button
                  ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A148C),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text("Enregistrer les données", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required Widget child}) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF8E24AA), size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF4A148C)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildIntensitySelector({
    required int currentValue,
    required Color color,
    required List<String> labels,
    required ValueChanged<int> onSelected,
  }) {
    return Row(
      children: List.generate(4, (index) {
        final isSelected = currentValue == index;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: index == 0 ? 0 : 4,
              right: index == 3 ? 0 : 4,
            ),
            child: GestureDetector(
              onTap: () => onSelected(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? color : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? color : Colors.grey.shade300,
                    width: 1,
                  ),
                ),
                child: Text(
                  labels[index],
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
