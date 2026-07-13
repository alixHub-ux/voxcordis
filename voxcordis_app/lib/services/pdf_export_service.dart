import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/analysis_result.dart';

class PdfExportService {
  static Future<void> export(AnalysisResult result) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Row(children: [
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('Voxcordis',
                    style: pw.TextStyle(
                        fontSize: 24,
                        color: const PdfColor.fromInt(0xFF6B3FA0),
                        fontWeight: pw.FontWeight.bold)),
                pw.Text("Rapport d'analyse vocale",
                    style: const pw.TextStyle(
                        fontSize: 14, color: PdfColors.grey600)),
              ]),
            ]),
          ),
          pw.SizedBox(height: 24),
          pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Date : ${DateFormat('dd/MM/yyyy à HH:mm').format(result.date)}',
                    style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600)),
                if (result.modelVersion != null)
                  pw.Text('Modèle v${result.modelVersion}',
                      style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600)),
              ]),
          pw.SizedBox(height: 20),
          pw.Divider(),
          pw.SizedBox(height: 20),

          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: _bgColor(result.riskLevel),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
              border: pw.Border.all(color: _riskColor(result.riskLevel), width: 1.5),
            ),
            child: pw.Column(children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: pw.BoxDecoration(
                  color: _riskColor(result.riskLevel),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(20)),
                ),
                child: pw.Text(result.riskLabel,
                    style: pw.TextStyle(
                        fontSize: 14,
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 12),
              pw.Text(result.userMessage,
                  style: const pw.TextStyle(
                      fontSize: 15, color: PdfColors.black, height: 1.5)),
            ]),
          ),
          pw.SizedBox(height: 28),

          pw.Header(level: 1, text: 'Ce que vous devez faire'),
          pw.SizedBox(height: 8),
          pw.Text(result.recommendation,
              style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey800, height: 1.6)),
          pw.SizedBox(height: 32),

          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFFFFF3E0),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              border: pw.Border.all(color: const PdfColor.fromInt(0xFFFFB74D), width: 1),
            ),
            child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('\u26A0\uFE0F', style: const pw.TextStyle(fontSize: 16, color: PdfColors.orange)),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: pw.Text(
                  'Voxcordis est un outil de dépistage uniquement. Ce rapport ne constitue pas un diagnostic médical. Veuillez consulter un professionnel de la santé qualifié.',
                  style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700, height: 1.5),
                ),
              ),
            ]),
          ),
        ],
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'voxcordis_analyse_${DateFormat('yyyyMMdd_HHmmss').format(result.date)}.pdf',
    );
  }

  static PdfColor _riskColor(RiskLevel level) {
    switch (level) {
      case RiskLevel.low:
        return const PdfColor.fromInt(0xFF4CAF50);
      case RiskLevel.moderate:
        return const PdfColor.fromInt(0xFFFF9800);
      case RiskLevel.high:
        return const PdfColor.fromInt(0xFFF44336);
    }
  }

  static PdfColor _bgColor(RiskLevel level) {
    switch (level) {
      case RiskLevel.low:
        return const PdfColor.fromInt(0xFFE8F5E9);
      case RiskLevel.moderate:
        return const PdfColor.fromInt(0xFFFFF3E0);
      case RiskLevel.high:
        return const PdfColor.fromInt(0xFFFFEBEE);
    }
  }
}
