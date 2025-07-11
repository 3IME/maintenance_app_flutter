// lib/services/pdf_generator.dart
import 'dart:typed_data';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/reservation.dart';
import '../models/collaborateur.dart'; // Assurez-vous que le chemin est correct

class PdfGenerator {
  static Future<Uint8List> generateReservationsPdf(
    List<Reservation> reservations,
    Box<Collaborateur> collaborateursBox,
  ) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR');

    // Trier les réservations par date pour un rendu logique
    reservations.sort((a, b) => a.startTime.compareTo(b.startTime));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (context) => _buildHeader('Planning des Réservations'),
        footer: _buildFooter,
        build: (context) => [
          _buildReservationTable(reservations, collaborateursBox, dateFormat),
          if (reservations.isEmpty)
            pw.Center(
              child: pw.Padding(
                padding: const pw.EdgeInsets.all(30),
                child: pw.Text('Aucune réservation à afficher.',
                    textAlign: pw.TextAlign.center),
              ),
            ),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader(String title) {
    return pw.Container(
      alignment: pw.Alignment.center,
      margin: const pw.EdgeInsets.only(bottom: 20.0),
      child: pw.Text(
        title,
        style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 10.0),
      child: pw.Text('Page ${context.pageNumber} / ${context.pagesCount}',
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
    );
  }

  static pw.Widget _buildReservationTable(
    List<Reservation> reservations,
    Box<Collaborateur> collaborateursBox,
    DateFormat dateFormat,
  ) {
    return pw.TableHelper.fromTextArray(
      headers: ['Date & Heure', 'Sujet', 'Collaborateurs'],
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      cellPadding: const pw.EdgeInsets.all(8),
      data: reservations.map((reservation) {
        // Récupérer les noms des collaborateurs
        final collaboratorNames = reservation.resourceIds
            .map((key) => collaborateursBox.get(key)?.nomComplet ?? 'N/A')
            .join(', ');

        return [
          dateFormat.format(reservation.startTime),
          reservation.subject,
          collaboratorNames.isNotEmpty ? collaboratorNames : 'Aucun',
        ];
      }).toList(),
    );
  }
}
