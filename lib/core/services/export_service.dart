import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../models/transaction.dart';

class ExportService {
  Future<void> exportTransactionsToPdf(List<TransactionModel> transactions) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Header(level: 0, text: 'BudgetBoss Transaction Report'),
          pw.TableHelper.fromTextArray(
            headers: ['Date', 'Title', 'Category', 'Type', 'Amount'],
            data: transactions.map((tx) {
              return [
                tx.date.toString().substring(0, 10),
                tx.title,
                tx.category,
                tx.type.toString().split('.').last,
                tx.amount.toStringAsFixed(2),
              ];
            }).toList(),
          ),
          pw.Padding(padding: const pw.EdgeInsets.all(10)),
          pw.Paragraph(text: 'Total Balance: ${transactions.fold(0.0, (sum, item) => item.type == TransactionType.income ? sum + item.amount : sum - item.amount).toStringAsFixed(2)}'),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }
}
