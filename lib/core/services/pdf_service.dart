import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:poultry_accounting/domain/entities/payment.dart';
import 'package:poultry_accounting/domain/entities/customer.dart';
import 'package:poultry_accounting/domain/entities/invoice.dart';
import 'package:poultry_accounting/domain/repositories/report_repository.dart';
import 'package:printing/printing.dart';

/// A service to generate PDF documents for the application.
class PdfService {
  
  /// Generates a PDF for a payment receipt or payment voucher.
  Future<Uint8List> generatePaymentReceiptPdf({
    required Payment payment,
    String? companyName,
    String? companyPhone,
    String? companyAddress,
  }) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.cairoRegular();
    final fontBold = await PdfGoogleFonts.cairoBold();

    final theme = pw.ThemeData.withFont(
      base: font,
      bold: fontBold,
    );

    final dateFormat = intl.DateFormat('yyyy/MM/dd HH:mm');
    final currencyFormat = intl.NumberFormat.currency(symbol: '₪', decimalDigits: 2);

    pdf.addPage(
      pw.Page(
        theme: theme,
        pageFormat: PdfPageFormat.a5.landscape,
        textDirection: pw.TextDirection.rtl,
        build: (context) => pw.Container(
          padding: const pw.EdgeInsets.all(20),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.black, width: 2),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildReceiptHeader(companyName, companyPhone, companyAddress, payment, dateFormat),
              pw.SizedBox(height: 20),
              _buildReceiptBody(payment, currencyFormat),
              pw.Spacer(),
              _buildReceiptSignatures(),
            ],
          ),
        ),
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildReceiptHeader(String? name, String? phone, String? address, Payment payment, intl.DateFormat dateFormat) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(name ?? 'اسم المنشأة', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            if (phone != null) pw.Text('هاتف: $phone', style: const pw.TextStyle(fontSize: 10)),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              payment.type == 'receipt' ? 'سند قبض' : 'سند صرف',
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: payment.type == 'receipt' ? PdfColors.green : PdfColors.red),
            ),
            pw.Text('رقم السند: ${payment.paymentNumber}', style: const pw.TextStyle(fontSize: 12)),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text('التاريخ: ${dateFormat.format(payment.paymentDate)}', style: const pw.TextStyle(fontSize: 10)),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildReceiptBody(Payment payment, intl.NumberFormat currency) {
    final partyName = payment.customer?.name ?? payment.supplier?.name ?? 'جهة غير معروفة';
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          children: [
            pw.Text(payment.type == 'receipt' ? 'وصلنا من السيد/ة: ' : 'صرفنا للسيد/ة: ', style: pw.TextStyle(fontSize: 14)),
            pw.Text(partyName, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Row(
          children: [
            pw.Text('مبلغ وقدره: ', style: pw.TextStyle(fontSize: 14)),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              child: pw.Text(currency.format(payment.amount), style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Row(
          children: [
            pw.Text('وذلك عن: ', style: pw.TextStyle(fontSize: 14)),
            pw.Text(payment.notes ?? 'تسديد حساب', style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Row(
          children: [
            pw.Text('طريقة الدفع: ', style: pw.TextStyle(fontSize: 14)),
            pw.Text(payment.methodDisplayName, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            if (payment.referenceNumber != null) ...[
              pw.SizedBox(width: 20),
              pw.Text('رقم المرجع: ', style: pw.TextStyle(fontSize: 14)),
              pw.Text(payment.referenceNumber!, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            ],
          ],
        ),
      ],
    );
  }

  pw.Widget _buildReceiptSignatures() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          children: [
            pw.Text('توقيع المستلم', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 30),
            pw.Text('_________________'),
          ],
        ),
        pw.Column(
          children: [
            pw.Text('توقيع المحاسب', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 30),
            pw.Text('_________________'),
          ],
        ),
      ],
    );
  }

  /// Generates a PDF for a specific Sales Invoice.
  Future<Uint8List> generateInvoicePdf({
    required Invoice invoice,
    required Customer customer,
    String? companyName,
    String? companyPhone,
    String? companyAddress,
  }) async {
    final pdf = pw.Document();

    // Load Arabic Font (Cairo)
    final font = await PdfGoogleFonts.cairoRegular();
    final fontBold = await PdfGoogleFonts.cairoBold();

    final theme = pw.ThemeData.withFont(
      base: font,
      bold: fontBold,
    );
    
    // Date Formatter
    final dateFormat = intl.DateFormat('yyyy/MM/dd HH:mm');
    final currencyFormat = intl.NumberFormat.currency(symbol: '₪', decimalDigits: 2);

    pdf.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl, // RT support for Arabic
        build: (context) => [
          _buildHeader(companyName, companyPhone, companyAddress, invoice, dateFormat),
          pw.SizedBox(height: 20),
          _buildCustomerInfo(customer),
          pw.SizedBox(height: 20),
          _buildInvoiceTable(invoice.items, currencyFormat),
          pw.SizedBox(height: 20),
          _buildTotals(invoice, currencyFormat),
          pw.Divider(),
          _buildFooter(),
        ],
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildHeader(
    String? name, 
    String? phone, 
    String? address, 
    Invoice invoice, 
    intl.DateFormat dateFormat,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(name ?? 'اسم المنشأة', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            if (phone != null) pw.Text('هاتف: $phone'),
            if (address != null) pw.Text('العنوان: $address'),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text('فاتورة مبيعات', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue)),
            pw.Text('رقم الفاتورة: #${invoice.id}'),
            pw.Text('التاريخ: ${dateFormat.format(invoice.invoiceDate)}'),
          ],
        ),
      ],
    );
  }

  Future<Uint8List> generateStatementPdf({
    required Customer customer,
    required List<CustomerStatementEntry> entries,
    DateTime? fromDate,
    DateTime? toDate,
    String? companyName,
    String? companyPhone,
    String? companyAddress,
  }) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.cairoRegular();
    final fontBold = await PdfGoogleFonts.cairoBold();

    final theme = pw.ThemeData.withFont(
      base: font,
      bold: fontBold,
    );

    final dateFormat = intl.DateFormat('yyyy/MM/dd');
    final currencyFormat = intl.NumberFormat.currency(symbol: '₪', decimalDigits: 2);

    pdf.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        build: (context) => [
          _buildStatementHeader(companyName, companyPhone, companyAddress, customer, fromDate, toDate),
          pw.SizedBox(height: 20),
          _buildStatementTable(entries, currencyFormat, dateFormat),
          pw.SizedBox(height: 20),
          _buildStatementSummary(entries, currencyFormat),
          pw.Divider(),
          _buildFooter(),
        ],
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildStatementHeader(
    String? name,
    String? phone,
    String? address,
    Customer customer,
    DateTime? from,
    DateTime? to,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(name ?? 'اسم المنشأة', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                if (phone != null) pw.Text('هاتف: $phone'),
              ],
            ),
            pw.Text('كشف حساب عميل', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.green)),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Text('العميل: ${customer.name}', style: pw.TextStyle(fontSize: 16)),
        if (from != null || to != null)
          pw.Text(
            'الفترة: ${from != null ? intl.DateFormat('yyyy/MM/dd').format(from) : '...'} - ${to != null ? intl.DateFormat('yyyy/MM/dd').format(to) : '...'}',
          ),
      ],
    );
  }

  pw.Widget _buildStatementTable(List<CustomerStatementEntry> entries, intl.NumberFormat currency, intl.DateFormat dateFormat) {
    return pw.TableHelper.fromTextArray(
      headers: ['التاريخ', 'البيان', 'المرجع', 'مدين (له)', 'دائن (عليه)', 'الرصيد'],
      data: entries.map((e) => [
        dateFormat.format(e.date),
        e.description,
        e.reference,
        e.debit > 0 ? currency.format(e.debit) : '-',
        e.credit > 0 ? currency.format(e.credit) : '-',
        currency.format(e.balance),
      ]).toList(),
      border: pw.TableBorder.all(color: PdfColors.grey300),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.green),
      cellAlignment: pw.Alignment.center,
    );
  }

  pw.Widget _buildStatementSummary(List<CustomerStatementEntry> entries, intl.NumberFormat currency) {
    final lastBalance = entries.isNotEmpty ? entries.last.balance : 0.0;
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Container(
          width: 250,
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('الرصيد النهائي المستحق:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
              pw.Text(currency.format(lastBalance), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14, color: lastBalance > 0 ? PdfColors.red : PdfColors.green)),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildCustomerInfo(Customer customer) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Row(
        children: [
          pw.Text('السيد / السادة: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text(customer.name, style: const pw.TextStyle(fontSize: 16)),
          pw.Spacer(),
          if (customer.phone != null) pw.Text('جوال: ${customer.phone}'),
        ],
      ),
    );
  }

  pw.Widget _buildInvoiceTable(List<InvoiceItem> items, intl.NumberFormat currency) {
    return pw.TableHelper.fromTextArray(
      headers: ['م', 'الصنف', 'الكمية', 'السعر الإفرادي', 'الإجمالي'],
      data: items.asMap().entries.map((entry) {
        final index = entry.key + 1;
        final item = entry.value;
        return [
          index.toString(),
          item.productName,
          item.quantity.toStringAsFixed(2),
          currency.format(item.unitPrice),
          currency.format(item.total),
        ];
      }).toList(),
      border: pw.TableBorder.all(color: PdfColors.grey300),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey),
      cellAlignment: pw.Alignment.center,
      cellAlignments: {
        1: pw.Alignment.centerRight, // Product name alignment
      },
    );
  }

  pw.Widget _buildTotals(Invoice invoice, intl.NumberFormat currency) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Container(
          width: 200,
          child: pw.Column(
            children: [
              _buildTotalRow('المبيعات', currency.format(invoice.subtotal)),
              if (invoice.discount > 0)
                _buildTotalRow('الخصم', currency.format(invoice.discount), color: PdfColors.red),
              pw.Divider(),
              _buildTotalRow('الصافي المطلوب', currency.format(invoice.total), isBold: true, fontSize: 16),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildTotalRow(String label, String value, {PdfColor? color, bool isBold = false, double fontSize = 12}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontWeight: isBold ? pw.FontWeight.bold : null, fontSize: fontSize)),
          pw.Text(value, style: pw.TextStyle(color: color, fontWeight: isBold ? pw.FontWeight.bold : null, fontSize: fontSize)),
        ],
      ),
    );
  }

  pw.Widget _buildFooter() {
    return pw.Column(
      children: [
        pw.SizedBox(height: 20),
        pw.Text('شكراً لتعاملكم معنا', style: const pw.TextStyle(fontSize: 14)),
        pw.Text('حررت هذه الفاتورة إلكترونياً ولا تحتاج إلى توقيع', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
      ],
    );
  }
}

final pdfServiceProvider = Provider<PdfService>((ref) {
  return PdfService();
});
