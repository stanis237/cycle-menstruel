import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'api_service.dart';

class ExportService {
  final ApiService _apiService = ApiService();

  Future<void> exportDataToCsv() async {
    final entries = await _apiService.getDailyEntries();
    if (entries == null || entries.isEmpty) {
      throw Exception("Aucune donnée à exporter");
    }

    // Create CSV header
    String csvData = "Date,Flux,Douleur,Humeur,Energie,Temperature,Contraception,Details Sex\n";

    // Add rows
    for (var e in entries) {
      csvData += "${e['date']},"
          "${e['flow_intensity'] ?? 0},"
          "${e['pain_intensity'] ?? 0},"
          "${e['mood'] ?? ''},"
          "${e['energy_level'] ?? ''},"
          "${e['temperature'] ?? ''},"
          "${e['used_contraception'] == true ? 'Oui' : 'Non'},"
          "${e['sex_details'] ?? ''}\n";
    }

    // Save to temporary file
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/cyclia_export.csv');
    await file.writeAsString(csvData);

    // Share file
    await Share.shareXFiles([XFile(file.path)], text: 'Mon historique de santé Cyclia');
  }
}
