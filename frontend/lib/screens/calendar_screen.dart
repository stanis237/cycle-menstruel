import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import 'symptoms_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final ApiService _apiService = ApiService();
  
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  Map<String, dynamic>? _predictionData;
  bool _isLoading = true;
  Map<String, dynamic>? _selectedDayEntry;
  bool _isLoadingEntry = false;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadPredictions();
    _loadSelectedDayEntry();
  }

  Future<void> _loadPredictions() async {
    setState(() {
      _isLoading = true;
    });
    final data = await _apiService.getPredictions();
    setState(() {
      _predictionData = data;
      _isLoading = false;
    });
  }

  Future<void> _loadSelectedDayEntry() async {
    if (_selectedDay == null) return;
    setState(() {
      _isLoadingEntry = true;
    });
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDay!);
    final entry = await _apiService.getDailyEntry(dateStr);
    setState(() {
      _selectedDayEntry = entry;
      _isLoadingEntry = false;
    });
  }

  // Helper methods to identify day types
  bool _isPeriodDay(DateTime day) {
    if (_predictionData == null) return false;
    
    // Check current cycle rules
    if (_predictionData!['current_cycle'] != null) {
      final current = _predictionData!['current_cycle'];
      final start = DateTime.parse(current['start_date']);
      final length = current['average_period_length'] ?? 5;
      final end = start.add(Duration(days: length - 1));
      
      if (day.isAfter(start.subtract(const Duration(seconds: 1))) && 
          day.isBefore(end.add(const Duration(days: 1)))) {
        return true;
      }
    }
    
    // Check predicted rules
    final predictions = _predictionData!['predictions'] as List? ?? [];
    for (var pred in predictions) {
      final start = DateTime.parse(pred['predicted_start']);
      final end = DateTime.parse(pred['predicted_end']);
      if (day.isAfter(start.subtract(const Duration(seconds: 1))) && 
          day.isBefore(end.add(const Duration(days: 1)))) {
        return true;
      }
    }
    
    return false;
  }

  bool _isFertileDay(DateTime day) {
    if (_predictionData == null) return false;
    
    // Check current cycle fertile window
    if (_predictionData!['current_cycle'] != null) {
      final current = _predictionData!['current_cycle'];
      if (current['fertile_window_start'] != null && current['fertile_window_end'] != null) {
        final start = DateTime.parse(current['fertile_window_start']);
        final end = DateTime.parse(current['fertile_window_end']);
        if (day.isAfter(start.subtract(const Duration(seconds: 1))) && 
            day.isBefore(end.add(const Duration(days: 1)))) {
          return true;
        }
      }
    }
    
    // Check predicted fertile windows
    final predictions = _predictionData!['predictions'] as List? ?? [];
    for (var pred in predictions) {
      final start = DateTime.parse(pred['predicted_fertile_start']);
      final end = DateTime.parse(pred['predicted_fertile_end']);
      if (day.isAfter(start.subtract(const Duration(seconds: 1))) && 
          day.isBefore(end.add(const Duration(days: 1)))) {
        return true;
      }
    }
    
    return false;
  }

  bool _isOvulationDay(DateTime day) {
    if (_predictionData == null) return false;
    
    // Check current ovulation
    if (_predictionData!['current_cycle'] != null) {
      final current = _predictionData!['current_cycle'];
      if (current['ovulation_date'] != null) {
        final ov = DateTime.parse(current['ovulation_date']);
        if (isSameDay(day, ov)) return true;
      }
    }
    
    // Check predicted ovulation
    final predictions = _predictionData!['predictions'] as List? ?? [];
    for (var pred in predictions) {
      final ov = DateTime.parse(pred['predicted_ovulation']);
      if (isSameDay(day, ov)) return true;
    }
    
    return false;
  }

  Future<void> _startCycleAtSelectedDay() async {
    if (_selectedDay == null) return;
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDay!);
    
    setState(() {
      _isLoading = true;
    });
    
    final result = await _apiService.startCycle(dateStr);
    
    if (!mounted) return;
    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nouveau cycle démarré avec succès.")),
      );
      await _loadPredictions();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Impossible de démarrer le cycle.")),
      );
      setState(() {
        _isLoading = false;
      });
    }
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
          "Calendrier du Cycle",
          style: TextStyle(color: Color(0xFF4A148C), fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF8E24AA)))
          : Column(
              children: [
                // Calendar Container
                Card(
                  margin: const EdgeInsets.all(16),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                    child: TableCalendar(
                      locale: 'fr_FR',
                      firstDay: DateTime.now().subtract(const Duration(days: 365)),
                      lastDay: DateTime.now().add(const Duration(days: 365)),
                      focusedDay: _focusedDay,
                      calendarFormat: _calendarFormat,
                      selectedDayPredicate: (day) {
                        return isSameDay(_selectedDay, day);
                      },
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });
                        _loadSelectedDayEntry();
                      },
                      onFormatChanged: (format) {
                        if (_calendarFormat != format) {
                          setState(() {
                            _calendarFormat = format;
                          });
                        }
                      },
                      onPageChanged: (focusedDay) {
                        _focusedDay = focusedDay;
                      },
                      
                      // Beautiful Custom Styles for Cells
                      calendarBuilders: CalendarBuilders(
                        defaultBuilder: (context, day, focusedDay) {
                          return _buildCustomCell(day, Colors.black87);
                        },
                        outsideBuilder: (context, day, focusedDay) {
                          return _buildCustomCell(day, Colors.grey.shade400);
                        },
                        todayBuilder: (context, day, focusedDay) {
                          return Container(
                            margin: const EdgeInsets.all(4),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFF8E24AA), width: 2),
                              shape: BoxShape.circle,
                            ),
                            child: _buildCustomCell(day, const Color(0xFF8E24AA), showMarkerBg: false),
                          );
                        },
                        selectedBuilder: (context, day, focusedDay) {
                          return Container(
                            margin: const EdgeInsets.all(4),
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: Color(0xFF4A148C),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              "${day.day}",
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),

                // Legend
                _buildLegend(),

                const SizedBox(height: 10),

                // Selected Day Details panel
                Expanded(
                  child: _buildSelectedDayPanel(),
                ),
              ],
            ),
    );
  }

  Widget _buildCustomCell(DateTime day, Color textColor, {bool showMarkerBg = true}) {
    Color? cellBg;
    IconData? overlayIcon;
    Color overlayColor = Colors.transparent;

    if (showMarkerBg) {
      if (_isOvulationDay(day)) {
        cellBg = const Color(0xFFE3F2FD); // Light blue
        overlayIcon = Icons.star_rounded;
        overlayColor = const Color(0xFF2196F3);
      } else if (_isPeriodDay(day)) {
        cellBg = const Color(0xFFFCE4EC); // Light pink
        overlayColor = const Color(0xFFE91E63);
      } else if (_isFertileDay(day)) {
        cellBg = const Color(0xFFE1F5FE); // Light sky blue
        overlayColor = const Color(0xFF03A9F4);
      }
    }

    return Container(
      margin: const EdgeInsets.all(3),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: cellBg,
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            "${day.day}",
            style: TextStyle(
              color: textColor,
              fontWeight: cellBg != null ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (overlayColor != Colors.transparent && !_isOvulationDay(day))
            Positioned(
              bottom: 4,
              child: Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: overlayColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          if (overlayIcon != null)
            Positioned(
              top: 2,
              right: 2,
              child: Icon(overlayIcon, size: 10, color: overlayColor),
            )
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildLegendItem("Règles", const Color(0xFFE91E63)),
          _buildLegendItem("Fertile", const Color(0xFF03A9F4)),
          _buildLegendItem("Ovulation", const Color(0xFF2196F3), isStar: true),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, {bool isStar = false}) {
    return Row(
      children: [
        isStar
            ? Icon(Icons.star_rounded, size: 16, color: color)
            : Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.2), shape: BoxShape.circle),
                child: Center(
                  child: Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                ),
              ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildSelectedDayPanel() {
    if (_selectedDay == null) return const SizedBox.shrink();
    
    final formattedDate = DateFormat('EEEE dd MMMM yyyy', 'fr_FR').format(_selectedDay!);
    final isToday = isSameDay(_selectedDay, DateTime.now());
    final isBeforeOrToday = _selectedDay!.isBefore(DateTime.now()) || isToday;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  formattedDate,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF4A148C)),
                ),
              ),
              if (isBeforeOrToday)
                TextButton.icon(
                  onPressed: () async {
                    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDay!);
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SymptomsScreen(initialDate: dateStr),
                      ),
                    );
                    _loadSelectedDayEntry();
                  },
                  icon: const Icon(Icons.edit_note, size: 20),
                  label: Text(_selectedDayEntry != null ? "Modifier" : "Saisir"),
                ),
            ],
          ),
          const SizedBox(height: 15),

          // Symptoms overview or status
          Expanded(
            child: _isLoadingEntry
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_selectedDayEntry != null) ...[
                          _buildDetailRow("Flux menstruel", _getIntensityText(_selectedDayEntry!['flow_intensity'])),
                          _buildDetailRow("Douleurs", _getIntensityText(_selectedDayEntry!['pain_intensity'])),
                          _buildDetailRow("Humeur", _selectedDayEntry!['mood'] ?? "Non spécifiée"),
                          _buildDetailRow("Énergie", _selectedDayEntry!['energy_level'] != null ? "${_selectedDayEntry!['energy_level']}/5" : "Non spécifié"),
                          if (_selectedDayEntry!['notes'] != null && _selectedDayEntry!['notes'].toString().isNotEmpty) ...[
                            const SizedBox(height: 10),
                            const Text("Notes :", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            Text(
                              "\"${_selectedDayEntry!['notes']}\"",
                              style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.black87),
                            ),
                          ],
                        ] else ...[
                          Text(
                            "Aucun symptôme renseigné pour ce jour.",
                            style: TextStyle(color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                          ),
                        ],
                        
                        const Divider(height: 30),

                        // Action to Start Cycle here (if applicable, within 90 days)
                        if (isBeforeOrToday && !_isPeriodDay(_selectedDay!)) ...[
                          ElevatedButton.icon(
                            onPressed: _startCycleAtSelectedDay,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFCE4EC),
                              foregroundColor: const Color(0xFFC2185B),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            icon: const Icon(Icons.water_drop_outlined, size: 20),
                            label: const Text(
                              "Mes règles ont commencé ce jour",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF4A148C))),
        ],
      ),
    );
  }

  String _getIntensityText(int? level) {
    if (level == null || level == 0) return "Aucun";
    if (level == 1) return "Léger";
    if (level == 2) return "Moyen";
    if (level == 3) return "Abondant/Intense";
    return "Aucun";
  }
}
