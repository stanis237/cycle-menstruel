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
  final _weightController = TextEditingController();
  final _sleepController = TextEditingController();

  late String _dateStr;
  int _flowIntensity = 0; // 0 to 3
  int _painIntensity = 0; // 0 to 3
  String _selectedMood = "";
  double _energyLevel = 3.0;
  String _lhTest = "negative";
  bool _isLoading = false;

  // New fields inspired by Flo
  List<String> _physicalSymptoms = [];
  String _dischargeType = "none";
  bool _hadSex = false;
  String _sexDetails = "protected";
  int _stressLevel = 3;
  bool _alcohol = false;
  String _exercise = "none";
  String _skin = "clear";
  String _hair = "normal";
  int _waterIntake = 0;
  bool _pillTaken = false;
  bool _usedContraception = false;
  String _contraceptionMethod = "condom";

  final List<Map<String, dynamic>> _physicalList = [
    {"name": "Crampes", "icon": Icons.bolt, "value": "cramps"},
    {"name": "Ballonnements", "icon": Icons.cloud_outlined, "value": "bloating"},
    {"name": "Seins sensibles", "icon": Icons.favorite_outline, "value": "breast_tenderness"},
    {"name": "Acné", "icon": Icons.face_retouching_natural, "value": "acne"},
    {"name": "Maux de tête", "icon": Icons.psychology_outlined, "value": "headache"},
    {"name": "Mal de dos", "icon": Icons.accessibility_new, "value": "back_pain"},
  ];

  final List<Map<String, String>> _dischargeList = [
    {"name": "Aucune", "value": "none"},
    {"name": "Crémeuse", "value": "creamy"},
    {"name": "Blanc d'œuf", "value": "egg_white"},
    {"name": "Liquide", "value": "watery"},
    {"name": "Collante", "value": "sticky"},
  ];

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
        _dischargeType = data['cervical_mucus'] ?? "none";
        _hadSex = data['had_sex'] ?? false;
        _sexDetails = data['sex_details'] ?? "protected";
        _stressLevel = data['stress_level'] ?? 3;
        _alcohol = data['alcohol_consumption'] ?? false;
        _exercise = data['exercise_intensity'] ?? "none";
        _skin = data['skin_condition'] ?? "clear";
        _hair = data['hair_condition'] ?? "normal";
        _waterIntake = data['water_intake'] ?? 0;
        _pillTaken = data['pill_taken'] ?? false;
        _usedContraception = data['used_contraception'] ?? false;
        _contraceptionMethod = data['contraception_method'] ?? "condom";
        
        if (data['weight'] != null) _weightController.text = data['weight'].toString();
        if (data['sleep_hours'] != null) _sleepController.text = data['sleep_hours'].toString();

        if (data['physical_symptoms'] != null && data['physical_symptoms'].toString().isNotEmpty) {
          _physicalSymptoms = data['physical_symptoms'].toString().split(',');
        }
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
      'cervical_mucus': _dischargeType,
      'physical_symptoms': _physicalSymptoms.join(','),
      'had_sex': _hadSex,
      'sex_details': _sexDetails,
      'weight': double.tryParse(_weightController.text),
      'sleep_hours': double.tryParse(_sleepController.text),
      'stress_level': _stressLevel,
      'water_intake': _waterIntake,
      'alcohol_consumption': _alcohol,
      'pill_taken': _pillTaken,
      'used_contraception': _usedContraception,
      'contraception_method': _contraceptionMethod,
      'exercise_intensity': _exercise,
      'skin_condition': _skin,
      'hair_condition': _hair,
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
                  // IMPORTANT: Fertility Signs First (Safety Priority)
                  _buildSectionCard(
                    title: "SIGNES DE FERTILITÉ (Priorité Sécurité)",
                    icon: Icons.security_rounded,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Pertes vaginales / Mucus :", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _dischargeList.map((d) {
                            final isSelected = _dischargeType == d['value'];
                            return ChoiceChip(
                              label: Text(d['name']!),
                              selected: isSelected,
                              selectedColor: const Color(0xFFE1F5FE),
                              onSelected: (selected) => setState(() => _dischargeType = d['value']!),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        const Text("Température basale (°C) :", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _tempController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            hintText: "Ex: 36.6",
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

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

                  // Physical Symptoms Grid
                  _buildSectionCard(
                    title: "Symptômes physiques",
                    icon: Icons.accessibility_new_rounded,
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _physicalList.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.3,
                      ),
                      itemBuilder: (context, index) {
                        final s = _physicalList[index];
                        final isSelected = _physicalSymptoms.contains(s['value']);
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _physicalSymptoms.remove(s['value']);
                              } else {
                                _physicalSymptoms.add(s['value']!);
                              }
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFFCE4EC) : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? const Color(0xFFE91E63) : Colors.grey.shade300,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(s['icon'] as IconData, size: 20, color: isSelected ? const Color(0xFFC2185B) : Colors.grey),
                                const SizedBox(height: 4),
                                Text(
                                  s['name']!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? const Color(0xFF880E4F) : Colors.black87,
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

                  // Cervical Mucus
                  _buildSectionCard(
                    title: "Pertes vaginales",
                    icon: Icons.opacity_rounded,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _dischargeList.map((d) {
                        final isSelected = _dischargeType == d['value'];
                        return ChoiceChip(
                          label: Text(d['name']!),
                          selected: isSelected,
                          selectedColor: const Color(0xFFE1F5FE),
                          labelStyle: TextStyle(
                            color: isSelected ? const Color(0xFF0277BD) : Colors.black87,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (selected) {
                            if (selected) setState(() => _dischargeType = d['value']!);
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Lifestyle / Sex
                  _buildSectionCard(
                    title: "Journal de Protection",
                    icon: Icons.shield_rounded,
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text("Pilule prise aujourd'hui", style: TextStyle(fontSize: 14)),
                          value: _pillTaken,
                          activeThumbColor: const Color(0xFFFF9800),
                          onChanged: (val) => setState(() => _pillTaken = val),
                          contentPadding: EdgeInsets.zero,
                          secondary: const Icon(Icons.medication_rounded, color: Color(0xFFFF9800)),
                        ),
                        const Divider(),
                        SwitchListTile(
                          title: const Text("Autre protection utilisée", style: TextStyle(fontSize: 14)),
                          subtitle: const Text("Préservatif, diaphragme, etc.", style: TextStyle(fontSize: 11)),
                          value: _usedContraception,
                          activeThumbColor: const Color(0xFF4CAF50),
                          onChanged: (val) => setState(() => _usedContraception = val),
                          contentPadding: EdgeInsets.zero,
                          secondary: const Icon(Icons.security_rounded, color: Color(0xFF4CAF50)),
                        ),
                        if (_usedContraception)
                          DropdownButtonFormField<String>(
                            initialValue: _contraceptionMethod,
                            decoration: const InputDecoration(labelText: "Méthode"),
                            items: const [
                              DropdownMenuItem(value: "condom", child: Text("Préservatif")),
                              DropdownMenuItem(value: "withdrawal", child: Text("Retrait")),
                              DropdownMenuItem(value: "emergency", child: Text("Contraception d'urgence")),
                              DropdownMenuItem(value: "other", child: Text("Autre")),
                            ],
                            onChanged: (val) => setState(() => _contraceptionMethod = val!),
                          ),
                        const Divider(),
                        SwitchListTile(
                          title: const Text("Rapport sexuel", style: TextStyle(fontSize: 14)),
                          value: _hadSex,
                          activeThumbColor: const Color(0xFFE91E63),
                          onChanged: (val) => setState(() => _hadSex = val),
                          contentPadding: EdgeInsets.zero,
                          secondary: const Icon(Icons.favorite_rounded, color: Color(0xFFE91E63)),
                        ),
                        if (_hadSex)
                          Padding(
                            padding: const EdgeInsets.only(left: 48.0),
                            child: Row(
                              children: [
                                ChoiceChip(
                                  label: const Text("Protégé"),
                                  selected: _sexDetails == "protected",
                                  onSelected: (val) => setState(() => _sexDetails = "protected"),
                                ),
                                const SizedBox(width: 8),
                                ChoiceChip(
                                  label: const Text("Non protégé"),
                                  selected: _sexDetails == "unprotected",
                                  onSelected: (val) => setState(() => _sexDetails = "unprotected"),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Health Metrics
                  _buildSectionCard(
                    title: "Paramètres de santé",
                    icon: Icons.monitor_weight_rounded,
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _weightController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: "Poids (kg)", border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _sleepController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: "Sommeil (h)", border: OutlineInputBorder()),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Skin & Hair
                  _buildSectionCard(
                    title: "Peau & Cheveux",
                    icon: Icons.face_rounded,
                    child: Column(
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: _skin,
                          decoration: const InputDecoration(labelText: "État de la peau"),
                          items: const [
                            DropdownMenuItem(value: "clear", child: Text("Saine")),
                            DropdownMenuItem(value: "oily", child: Text("Grasse")),
                            DropdownMenuItem(value: "dry", child: Text("Sèche")),
                            DropdownMenuItem(value: "spots", child: Text("Imperfections")),
                          ],
                          onChanged: (val) => setState(() => _skin = val!),
                        ),
                        DropdownButtonFormField<String>(
                          initialValue: _hair,
                          decoration: const InputDecoration(labelText: "État des cheveux"),
                          items: const [
                            DropdownMenuItem(value: "normal", child: Text("Normaux")),
                            DropdownMenuItem(value: "oily", child: Text("Gras")),
                            DropdownMenuItem(value: "dry", child: Text("Secs")),
                            DropdownMenuItem(value: "hair_loss", child: Text("Chute de cheveux")),
                          ],
                          onChanged: (val) => setState(() => _hair = val!),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Stress & Lifestyle
                  _buildSectionCard(
                    title: "Stress & Lifestyle",
                    icon: Icons.psychology_rounded,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Niveau de stress:"),
                            Text("$_stressLevel/5", style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Slider(
                          value: _stressLevel.toDouble(),
                          min: 1, max: 5, divisions: 4,
                          onChanged: (val) => setState(() => _stressLevel = val.toInt()),
                        ),
                        DropdownButtonFormField<String>(
                          initialValue: _exercise,
                          decoration: const InputDecoration(labelText: "Activité physique"),
                          items: const [
                            DropdownMenuItem(value: "none", child: Text("Aucune")),
                            DropdownMenuItem(value: "light", child: Text("Légère")),
                            DropdownMenuItem(value: "moderate", child: Text("Modérée")),
                            DropdownMenuItem(value: "intense", child: Text("Intense")),
                          ],
                          onChanged: (val) => setState(() => _exercise = val!),
                        ),
                        SwitchListTile(
                          title: const Text("Consommation d'alcool"),
                          value: _alcohol,
                          onChanged: (val) => setState(() => _alcohol = val),
                        ),
                      ],
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
