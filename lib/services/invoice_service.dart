import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';
import '../utils/currency_formatter.dart';

class KhataStatementEntry {
  final DateTime date;
  final String description;
  final String reference;
  final double debit;
  final double credit;
  final double runningBalance;

  const KhataStatementEntry({
    required this.date,
    required this.description,
    required this.reference,
    required this.debit,
    required this.credit,
    required this.runningBalance,
  });
}

class InvoiceService {
  static const String companyName = 'BAINADA BROTHERS (OPC) PRIVATE LIMITED';
  static const String companyTradeName = 'BAINADA BROTHERS (OPC) PRIVATE LIMITED';
  static const String companyTagline = 'Wholesale Grocery & Kirana Super-Stockist';
  static const String companyAddress =
      'Nanag Ram Watika Road, Shree Ram Ki Nangal, Jaipur, Rajasthan - 302022';
  static const String companyGstin = '08AANCB2205J1ZQ';
  static const String companyDirector = 'Ajay Meena';
  static const String companyPhone = '+91 98290 99999';
  static const String companyEmail = 'orders@bainada.com';
  static const String stateCode = '08 (Rajasthan)';

  /// Sanitize text for PDF font compatibility (removes Hindi/unsupported glyphs)
  static String sanitizeForPdf(String? input, {String fallback = ''}) {
    if (input == null || input.trim().isEmpty) return fallback;
    final buffer = StringBuffer();
    for (final rune in input.runes) {
      if (rune >= 32 && rune <= 126) {
        buffer.writeCharCode(rune);
      } else if (rune == 10 || rune == 13) {
        buffer.writeCharCode(rune);
      } else if (rune == 0x20B9) {
        buffer.write('Rs. ');
      }
    }
    final clean = buffer.toString().trim();
    return clean.isNotEmpty ? clean : fallback;
  }

  /// Safe currency formatter for PDF documents (avoiding raw unicode ₹ font crashes)
  static String formatPdfCurrency(double? amount) {
    if (amount == null || !amount.isFinite) return 'Rs. 0.00';
    final isNegative = amount < 0;
    final absVal = amount.abs();
    final formatted = absVal.toStringAsFixed(2);
    return isNegative ? '-Rs. $formatted' : 'Rs. $formatted';
  }

  /// Safe Regular Font Loader
  static Future<pw.Font> _loadFontRegular() async {
    try {
      return await PdfGoogleFonts.robotoRegular();
    } catch (_) {
      try {
        return await PdfGoogleFonts.openSansRegular();
      } catch (_) {
        return pw.Font.helvetica();
      }
    }
  }

  /// Safe Bold Font Loader
  static Future<pw.Font> _loadFontBold() async {
    try {
      return await PdfGoogleFonts.robotoBold();
    } catch (_) {
      try {
        return await PdfGoogleFonts.openSansBold();
      } catch (_) {
        return pw.Font.helveticaBold();
      }
    }
  }

  /// Convert number into Indian currency words
  static String numberToWords(int number) {
    if (number == 0) return 'Zero Rupees Only';

    final List<String> units = [
      '', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine', 'Ten',
      'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen', 'Seventeen', 'Eighteen', 'Nineteen'
    ];
    final List<String> tens = [
      '', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'
    ];

    String convertBelowThousand(int n) {
      if (n == 0) return '';
      if (n < 20) return units[n];
      if (n < 100) return '${tens[n ~/ 10]} ${units[n % 10]}'.trim();
      return '${units[n ~/ 100]} Hundred ${convertBelowThousand(n % 100)}'.trim();
    }

    int crore = number ~/ 10000000;
    int lakh = (number % 10000000) ~/ 100000;
    int thousand = (number % 100000) ~/ 1000;
    int remainder = number % 1000;

    String result = '';
    if (crore > 0) result += '${convertBelowThousand(crore)} Crore ';
    if (lakh > 0) result += '${convertBelowThousand(lakh)} Lakh ';
    if (thousand > 0) result += '${convertBelowThousand(thousand)} Thousand ';
    if (remainder > 0) result += convertBelowThousand(remainder);

    return 'Rupees ${result.trim()} Only';
  }

  /// Generate full A4 GST Tax Invoice Document
  static Future<Uint8List> generateInvoicePdf(OrderModel order) async {
    final pdf = pw.Document();

    final fontRegular = await PdfGoogleFonts.openSansRegular();
    final fontBold = await PdfGoogleFonts.openSansBold();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header Section
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        companyName.toUpperCase(),
                        style: pw.TextStyle(font: fontBold, fontSize: 18, color: PdfColors.green900),
                      ),
                      pw.Text(companyTagline, style: pw.TextStyle(font: fontRegular, fontSize: 9, color: PdfColors.grey700)),
                      pw.SizedBox(height: 4),
                      pw.Text(companyAddress, style: pw.TextStyle(font: fontRegular, fontSize: 8)),
                      pw.Text('Phone: $companyPhone | Email: $companyEmail', style: pw.TextStyle(font: fontRegular, fontSize: 8)),
                      pw.Text('GSTIN: $companyGstin | State Code: $stateCode', style: pw.TextStyle(font: fontBold, fontSize: 8)),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.green900, width: 1.5),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                    ),
                    child: pw.Column(
                      children: [
                        pw.Text('TAX INVOICE', style: pw.TextStyle(font: fontBold, fontSize: 12, color: PdfColors.green900)),
                        pw.Text('B2B Wholesale', style: pw.TextStyle(font: fontRegular, fontSize: 8, color: PdfColors.grey700)),
                      ],
                    ),
                  ),
                ],
              ),
              pw.Divider(thickness: 1, color: PdfColors.grey400),

              // Invoice Details & Merchant Bill To Section
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Bill To Box
                  pw.Expanded(
                    flex: 5,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey300),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('BILL TO (BUYER):', style: pw.TextStyle(font: fontBold, fontSize: 8, color: PdfColors.grey800)),
                          pw.SizedBox(height: 2),
                          pw.Text(order.merchantName, style: pw.TextStyle(font: fontBold, fontSize: 10)),
                          pw.Text('Address: ${order.merchantAddress}', style: pw.TextStyle(font: fontRegular, fontSize: 8)),
                          pw.Text('Contact: ${order.merchantPhone}', style: pw.TextStyle(font: fontRegular, fontSize: 8)),
                          pw.Text(
                            'GSTIN / UIN: ${order.merchantGstin != null && order.merchantGstin!.isNotEmpty ? order.merchantGstin : "Unregistered (URP)"}',
                            style: pw.TextStyle(font: fontBold, fontSize: 8),
                          ),
                          pw.Text('Place of Supply: Rajasthan (08)', style: pw.TextStyle(font: fontRegular, fontSize: 8)),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 10),

                  // Invoice Meta Box
                  pw.Expanded(
                    flex: 5,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey300),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('Invoice No:', style: pw.TextStyle(font: fontBold, fontSize: 8)),
                              pw.Text(order.invoiceNumber, style: pw.TextStyle(font: fontBold, fontSize: 9, color: PdfColors.green900)),
                            ],
                          ),
                          pw.SizedBox(height: 2),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('Invoice Date:', style: pw.TextStyle(font: fontRegular, fontSize: 8)),
                              pw.Text(CurrencyFormatter.formatDate(order.createdAt), style: pw.TextStyle(font: fontRegular, fontSize: 8)),
                            ],
                          ),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('Payment Mode:', style: pw.TextStyle(font: fontRegular, fontSize: 8)),
                              pw.Text(order.paymentType.displayName, style: pw.TextStyle(font: fontBold, fontSize: 8)),
                            ],
                          ),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('Payment Status:', style: pw.TextStyle(font: fontRegular, fontSize: 8)),
                              pw.Text(
                                order.isPaid ? 'PAID' : 'PENDING / CREDIT',
                                style: pw.TextStyle(
                                  font: fontBold,
                                  fontSize: 8,
                                  color: order.isPaid ? PdfColors.green800 : PdfColors.red800,
                                ),
                              ),
                            ],
                          ),
                          if (order.salesmanName != null) ...[
                            pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text('Sales Officer:', style: pw.TextStyle(font: fontRegular, fontSize: 8)),
                                pw.Text(order.salesmanName!, style: pw.TextStyle(font: fontRegular, fontSize: 8)),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 12),

              // Itemized Table
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                columnWidths: {
                  0: const pw.FixedColumnWidth(22), // S.No
                  1: const pw.FlexColumnWidth(4.5), // Description
                  2: const pw.FlexColumnWidth(1.5), // HSN
                  3: const pw.FlexColumnWidth(1.2), // Qty
                  4: const pw.FlexColumnWidth(1.4), // Unit
                  5: const pw.FlexColumnWidth(1.8), // Rate
                  6: const pw.FlexColumnWidth(2.0), // Taxable
                  7: const pw.FlexColumnWidth(1.3), // GST %
                  8: const pw.FlexColumnWidth(2.2), // Total
                },
                children: [
                  // Table Header
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.green800),
                    children: [
                      _buildTableHeaderCell('#', fontBold),
                      _buildTableHeaderCell('Item Description', fontBold),
                      _buildTableHeaderCell('HSN', fontBold),
                      _buildTableHeaderCell('Qty', fontBold),
                      _buildTableHeaderCell('Unit', fontBold),
                      _buildTableHeaderCell('Rate', fontBold),
                      _buildTableHeaderCell('Taxable', fontBold),
                      _buildTableHeaderCell('GST', fontBold),
                      _buildTableHeaderCell('Amount', fontBold),
                    ],
                  ),
                  // Table Data Rows
                  ...order.items.asMap().entries.map((entry) {
                    final index = entry.key + 1;
                    final item = entry.value;
                    return pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: index.isEven ? PdfColors.grey100 : PdfColors.white,
                      ),
                      children: [
                        _buildTableCell('$index', fontRegular, align: pw.TextAlign.center),
                        _buildTableCell(item.productName, fontRegular),
                        _buildTableCell(item.hsnCode, fontRegular, align: pw.TextAlign.center),
                        _buildTableCell('${item.quantity}', fontRegular, align: pw.TextAlign.center),
                        _buildTableCell(item.unit, fontRegular, align: pw.TextAlign.center),
                        _buildTableCell(item.unitPrice.toStringAsFixed(2), fontRegular, align: pw.TextAlign.right),
                        _buildTableCell(item.taxableTotal.toStringAsFixed(2), fontRegular, align: pw.TextAlign.right),
                        _buildTableCell('${item.gstRate.toStringAsFixed(0)}%', fontRegular, align: pw.TextAlign.center),
                        _buildTableCell(item.totalItemPrice.toStringAsFixed(2), fontBold, align: pw.TextAlign.right),
                      ],
                    );
                  }),
                ],
              ),
              pw.SizedBox(height: 10),

              // Tax Summary & Calculation Box
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Amount in Words & Notes
                  pw.Expanded(
                    flex: 6,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Amount in Words:', style: pw.TextStyle(font: fontBold, fontSize: 8)),
                        pw.Text(
                          numberToWords(order.grandTotal.toInt()),
                          style: pw.TextStyle(font: fontBold, fontSize: 9, color: PdfColors.green900),
                        ),
                        pw.SizedBox(height: 6),
                        if (order.notes != null && order.notes!.isNotEmpty) ...[
                          pw.Text('Remarks: ${order.notes}', style: pw.TextStyle(font: fontRegular, fontSize: 8)),
                          pw.SizedBox(height: 4),
                        ],
                        pw.Container(
                          padding: const pw.EdgeInsets.all(6),
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: PdfColors.grey300),
                            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('Terms & Conditions:', style: pw.TextStyle(font: fontBold, fontSize: 7)),
                              pw.Text('1. Goods once sold will not be taken back or exchanged.', style: pw.TextStyle(font: fontRegular, fontSize: 6.5)),
                              pw.Text('2. All disputes subject to Jaipur Jurisdiction only.', style: pw.TextStyle(font: fontRegular, fontSize: 6.5)),
                              pw.Text('3. Interest @ 18% p.a. will be charged if bill is not paid within credit period.', style: pw.TextStyle(font: fontRegular, fontSize: 6.5)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 14),

                  // Totals Box
                  pw.Expanded(
                    flex: 4,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey100,
                        border: pw.Border.all(color: PdfColors.grey400),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                      ),
                      child: pw.Column(
                        children: [
                          _buildCalculationRow('Taxable Amount:', 'Rs. ${order.taxableAmount.toStringAsFixed(2)}', fontRegular),
                          _buildCalculationRow('CGST (Central):', 'Rs. ${order.cgst.toStringAsFixed(2)}', fontRegular),
                          _buildCalculationRow('SGST (State):', 'Rs. ${order.sgst.toStringAsFixed(2)}', fontRegular),
                          if (order.igst > 0)
                            _buildCalculationRow('IGST (Inter-State):', 'Rs. ${order.igst.toStringAsFixed(2)}', fontRegular),
                          pw.Divider(thickness: 0.5),
                          _buildCalculationRow('Total GST Tax:', 'Rs. ${order.totalGst.toStringAsFixed(2)}', fontRegular),
                          pw.Divider(thickness: 1, color: PdfColors.grey600),
                          _buildCalculationRow(
                            'Grand Total:',
                            'Rs. ${order.grandTotal.toStringAsFixed(2)}',
                            fontBold,
                            fontSize: 11,
                            textColor: PdfColors.green900,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              pw.Spacer(),

              // Signatures Footer
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.SizedBox(height: 20),
                      pw.Text('_________________________', style: pw.TextStyle(font: fontRegular, fontSize: 8)),
                      pw.Text("Receiver's Signature & Stamp", style: pw.TextStyle(font: fontRegular, fontSize: 8)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('For Bainada Brothers Wholesale', style: pw.TextStyle(font: fontBold, fontSize: 8)),
                      pw.SizedBox(height: 24),
                      pw.Text('Authorized Signatory', style: pw.TextStyle(font: fontRegular, fontSize: 8)),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildTableHeaderCell(String text, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.white),
      ),
    );
  }

  static pw.Widget _buildTableCell(
    String text,
    pw.Font font, {
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(font: font, fontSize: 8),
      ),
    );
  }

  static pw.Widget _buildCalculationRow(
    String title,
    String value,
    pw.Font font, {
    double fontSize = 8,
    PdfColor textColor = PdfColors.black,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(title, style: pw.TextStyle(font: font, fontSize: fontSize)),
          pw.Text(value, style: pw.TextStyle(font: font, fontSize: fontSize, color: textColor)),
        ],
      ),
    );
  }

  /// Print or Share GST Invoice Modal
  static Future<void> printOrPreview(BuildContext context, OrderModel order) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => generateInvoicePdf(order),
      name: 'Invoice_${order.invoiceNumber}',
    );
  }

  // ==========================================
  // KHATA ACCOUNT STATEMENT PDF GENERATOR
  // ==========================================
  static Future<Uint8List> generateKhataStatementPdf({
    required UserModel merchant,
    required DateTime startDate,
    required DateTime endDate,
    required List<OrderModel> orders,
  }) async {
    final pdf = pw.Document();
    final fontRegular = await _loadFontRegular();
    final fontBold = await _loadFontBold();

    final dateFormat = DateFormat('dd/MM/yyyy');
    final periodFormat = DateFormat('dd MMM yyyy');

    final merchantShop = sanitizeForPdf(merchant.shopName, fallback: sanitizeForPdf(merchant.name, fallback: 'Kirana Store'));
    final merchantProprietor = sanitizeForPdf(merchant.name, fallback: 'Merchant Owner');
    final merchantAddr = sanitizeForPdf(merchant.address, fallback: '—');
    final merchantPhone = sanitizeForPdf(merchant.phone, fallback: 'N/A');
    final merchantGstin = sanitizeForPdf(merchant.gstin, fallback: 'Unregistered');
    final creditLimit = merchant.creditLimit.isFinite ? merchant.creditLimit : 0.0;

    // Filter merchant orders safely
    final merchantOrders = orders.where((o) {
      final matchesUid = o.merchantId == merchant.uid;
      final matchesName = o.merchantName.toLowerCase().trim() == (merchant.shopName ?? merchant.name).toLowerCase().trim();
      return (matchesUid || matchesName) && o.status != OrderStatus.cancelled;
    }).toList();

    // Sort chronologically
    merchantOrders.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    // Calculate opening balance before startDate
    double openingBalance = 0.0;
    for (final o in merchantOrders) {
      if (o.createdAt.isBefore(startDate)) {
        openingBalance += o.grandTotal;
        if (o.isPaid) {
          openingBalance -= o.grandTotal;
        }
      }
    }

    // Build statement entries in range
    final List<KhataStatementEntry> entries = [];
    double currentBalance = openingBalance;

    // Filter in range
    final inRangeOrders = merchantOrders.where((o) {
      final orderDate = o.createdAt;
      return orderDate.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
          orderDate.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();

    if (inRangeOrders.isNotEmpty) {
      for (final order in inRangeOrders) {
        currentBalance += order.grandTotal;
        final orderItemsSummary = order.items.isNotEmpty
            ? order.items.map((i) => sanitizeForPdf(i.productName, fallback: 'Item')).take(2).join(", ")
            : 'Wholesale Grocery Supplies';

        entries.add(KhataStatementEntry(
          date: order.createdAt,
          description: 'Wholesale Order - $orderItemsSummary',
          reference: sanitizeForPdf(order.invoiceNumber, fallback: order.id),
          debit: order.grandTotal,
          credit: 0.0,
          runningBalance: currentBalance,
        ));

        if (order.isPaid) {
          currentBalance -= order.grandTotal;
          entries.add(KhataStatementEntry(
            date: order.createdAt.add(const Duration(hours: 1)),
            description: 'Payment Received (${order.paymentType.displayName})',
            reference: 'REC-${sanitizeForPdf(order.invoiceNumber, fallback: order.id)}',
            debit: 0.0,
            credit: order.grandTotal,
            runningBalance: currentBalance,
          ));
        }
      }
    }

    final double totalDebits = entries.fold(0.0, (sum, e) => sum + e.debit);
    final double totalCredits = entries.fold(0.0, (sum, e) => sum + e.credit);
    final double closingBalance = currentBalance;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        header: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header Section
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        companyName.toUpperCase(),
                        style: pw.TextStyle(font: fontBold, fontSize: 16, color: PdfColors.green900),
                      ),
                      pw.Text(companyTagline, style: pw.TextStyle(font: fontRegular, fontSize: 8.5, color: PdfColors.grey700)),
                      pw.SizedBox(height: 3),
                      pw.Text(companyAddress, style: pw.TextStyle(font: fontRegular, fontSize: 7.5)),
                      pw.Text('Phone: $companyPhone | Email: $companyEmail', style: pw.TextStyle(font: fontRegular, fontSize: 7.5)),
                      pw.Text('GSTIN: $companyGstin | State Code: $stateCode', style: pw.TextStyle(font: fontBold, fontSize: 7.5)),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.green900, width: 1.5),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                      color: PdfColors.green50,
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text('KHATA STATEMENT', style: pw.TextStyle(font: fontBold, fontSize: 11, color: PdfColors.green900)),
                        pw.Text('Account Ledger', style: pw.TextStyle(font: fontRegular, fontSize: 8, color: PdfColors.grey800)),
                      ],
                    ),
                  ),
                ],
              ),
              pw.Divider(thickness: 1, color: PdfColors.grey400),
              pw.SizedBox(height: 4),
            ],
          );
        },
        build: (pw.Context context) {
          return [
            // Merchant Info & Statement Metadata Box
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400, width: 0.8),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                color: PdfColors.grey100,
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Left: Merchant Details
                  pw.Expanded(
                    flex: 6,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('MERCHANT ACCOUNT DETAILS:', style: pw.TextStyle(font: fontBold, fontSize: 8, color: PdfColors.green900)),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          merchantShop,
                          style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.black),
                        ),
                        pw.Text('Proprietor: $merchantProprietor', style: pw.TextStyle(font: fontRegular, fontSize: 8)),
                        pw.Text('Address: $merchantAddr', style: pw.TextStyle(font: fontRegular, fontSize: 8)),
                        pw.Text('Phone: $merchantPhone', style: pw.TextStyle(font: fontRegular, fontSize: 8)),
                        pw.Text('GSTIN: $merchantGstin', style: pw.TextStyle(font: fontBold, fontSize: 8)),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 12),
                  // Right: Statement Period & Account Stats
                  pw.Expanded(
                    flex: 5,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('STATEMENT SUMMARY:', style: pw.TextStyle(font: fontBold, fontSize: 8, color: PdfColors.green900)),
                        pw.SizedBox(height: 3),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Period:', style: pw.TextStyle(font: fontRegular, fontSize: 8)),
                            pw.Text('${periodFormat.format(startDate)} - ${periodFormat.format(endDate)}', style: pw.TextStyle(font: fontBold, fontSize: 8)),
                          ],
                        ),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Credit Limit:', style: pw.TextStyle(font: fontRegular, fontSize: 8)),
                            pw.Text(formatPdfCurrency(creditLimit), style: pw.TextStyle(font: fontBold, fontSize: 8)),
                          ],
                        ),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Opening Balance:', style: pw.TextStyle(font: fontRegular, fontSize: 8)),
                            pw.Text(formatPdfCurrency(openingBalance), style: pw.TextStyle(font: fontBold, fontSize: 8)),
                          ],
                        ),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Generated On:', style: pw.TextStyle(font: fontRegular, fontSize: 7.5, color: PdfColors.grey700)),
                            pw.Text(DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now()), style: pw.TextStyle(font: fontRegular, fontSize: 7.5)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            // Ledger Transactions Table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: const {
                0: pw.FlexColumnWidth(1.4), // Date
                1: pw.FlexColumnWidth(3.8), // Description & Ref
                2: pw.FlexColumnWidth(1.6), // Debit (Rs)
                3: pw.FlexColumnWidth(1.6), // Credit (Rs)
                4: pw.FlexColumnWidth(1.8), // Balance (Rs)
              },
              children: [
                // Table Header
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.green900),
                  children: [
                    _buildTableHeaderCell('Date', fontBold),
                    _buildTableHeaderCell('Description / Reference', fontBold),
                    _buildTableHeaderCell('Debit (Rs.)', fontBold),
                    _buildTableHeaderCell('Credit (Rs.)', fontBold),
                    _buildTableHeaderCell('Net Balance (Rs.)', fontBold),
                  ],
                ),
                // Opening Balance Row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    _buildTableCell(dateFormat.format(startDate), fontRegular, align: pw.TextAlign.center),
                    _buildTableCell('OPENING BALANCE B/F', fontBold),
                    _buildTableCell('-', fontRegular, align: pw.TextAlign.right),
                    _buildTableCell('-', fontRegular, align: pw.TextAlign.right),
                    _buildTableCell(formatPdfCurrency(openingBalance), fontBold, align: pw.TextAlign.right),
                  ],
                ),
                // If no transactions in range
                if (entries.isEmpty)
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.white),
                    children: [
                      _buildTableCell('-', fontRegular, align: pw.TextAlign.center),
                      _buildTableCell('No transactions recorded for this merchant in the selected period.', fontRegular),
                      _buildTableCell('-', fontRegular, align: pw.TextAlign.right),
                      _buildTableCell('-', fontRegular, align: pw.TextAlign.right),
                      _buildTableCell(formatPdfCurrency(openingBalance), fontBold, align: pw.TextAlign.right),
                    ],
                  )
                else
                  // Transactions
                  ...entries.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final item = entry.value;
                    final isEven = idx % 2 == 0;

                    return pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: isEven ? PdfColors.white : PdfColors.grey50,
                      ),
                      children: [
                        _buildTableCell(dateFormat.format(item.date), fontRegular, align: pw.TextAlign.center),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(item.description, style: pw.TextStyle(font: fontRegular, fontSize: 8)),
                              pw.Text('Ref: ${item.reference}', style: pw.TextStyle(font: fontRegular, fontSize: 7, color: PdfColors.grey700)),
                            ],
                          ),
                        ),
                        _buildTableCell(
                          item.debit > 0 ? formatPdfCurrency(item.debit) : '-',
                          fontRegular,
                          align: pw.TextAlign.right,
                        ),
                        _buildTableCell(
                          item.credit > 0 ? formatPdfCurrency(item.credit) : '-',
                          fontRegular,
                          align: pw.TextAlign.right,
                        ),
                        _buildTableCell(
                          formatPdfCurrency(item.runningBalance),
                          fontBold,
                          align: pw.TextAlign.right,
                        ),
                      ],
                    );
                  }),
              ],
            ),
            pw.SizedBox(height: 12),

            // Summary Footer Box & Reconciliation
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Left: Bank Account / Payment Settlement Info
                pw.Expanded(
                  flex: 5,
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300, width: 0.8),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('PAYMENT SETTLEMENT DETAILS:', style: pw.TextStyle(font: fontBold, fontSize: 7.5, color: PdfColors.green900)),
                        pw.SizedBox(height: 2),
                        pw.Text('Bank: State Bank of India, Mandi Branch', style: pw.TextStyle(font: fontRegular, fontSize: 7)),
                        pw.Text('A/C Name: Bainada Brothers Wholesale', style: pw.TextStyle(font: fontRegular, fontSize: 7)),
                        pw.Text('A/C No: 39820011002233 | IFSC: SBIN0001234', style: pw.TextStyle(font: fontBold, fontSize: 7)),
                        pw.Text('UPI ID: bainada.brothers@sbi', style: pw.TextStyle(font: fontRegular, fontSize: 7)),
                        pw.SizedBox(height: 4),
                        pw.Text('* Please quote Shop Name / Invoice number in payment remarks.', style: pw.TextStyle(font: fontRegular, fontSize: 6.5, color: PdfColors.grey600)),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 12),
                // Right: Financial Summary Totals
                pw.Expanded(
                  flex: 5,
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.green900, width: 1.2),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                      color: PdfColors.green50,
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _buildCalculationRow('Total Invoiced (Debits):', formatPdfCurrency(totalDebits), fontBold, fontSize: 8),
                        _buildCalculationRow('Total Paid (Credits):', formatPdfCurrency(totalCredits), fontBold, fontSize: 8, textColor: PdfColors.green900),
                        pw.Divider(thickness: 0.8, color: PdfColors.green900),
                        _buildCalculationRow('NET CLOSING DUE:', formatPdfCurrency(closingBalance), fontBold, fontSize: 10, textColor: closingBalance > 0 ? PdfColors.red900 : PdfColors.green900),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 10),

            // Amount in words
            pw.Container(
              padding: const pw.EdgeInsets.all(6),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
              ),
              child: pw.Row(
                children: [
                  pw.Text('Closing Due in Words: ', style: pw.TextStyle(font: fontBold, fontSize: 7.5)),
                  pw.Expanded(
                    child: pw.Text(
                      numberToWords(closingBalance.clamp(0.0, 999999999.0).toInt()),
                      style: pw.TextStyle(font: fontRegular, fontSize: 7.5, color: PdfColors.grey900),
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 18),

            // Signatures
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Container(width: 140, height: 1, color: PdfColors.grey400),
                    pw.SizedBox(height: 3),
                    pw.Text("Merchant / Kirana Signature", style: pw.TextStyle(font: fontRegular, fontSize: 7.5)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text('For BAINADA BROTHERS WHOLESALE', style: pw.TextStyle(font: fontBold, fontSize: 8, color: PdfColors.green900)),
                    pw.SizedBox(height: 24),
                    pw.Container(width: 150, height: 1, color: PdfColors.grey400),
                    pw.SizedBox(height: 3),
                    pw.Text('Authorized Signatory / Account Manager', style: pw.TextStyle(font: fontRegular, fontSize: 7.5)),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  /// Print or Preview Khata Statement Modal
  static Future<void> printOrPreviewKhataStatement(
    BuildContext context,
    UserModel merchant,
    DateTime startDate,
    DateTime endDate,
    List<OrderModel> orders,
  ) async {
    final cleanShopName = sanitizeForPdf(merchant.shopName ?? merchant.name, fallback: 'Merchant').replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => generateKhataStatementPdf(
        merchant: merchant,
        startDate: startDate,
        endDate: endDate,
        orders: orders,
      ),
      name: 'Khata_Statement_${cleanShopName}_${DateFormat('yyyyMMdd').format(startDate)}_${DateFormat('yyyyMMdd').format(endDate)}',
    );
  }

  /// Download Khata Statement PDF direct file
  static Future<void> downloadKhataStatementPdf(
    BuildContext context,
    UserModel merchant,
    DateTime startDate,
    DateTime endDate,
    List<OrderModel> orders,
  ) async {
    final cleanShopName = sanitizeForPdf(merchant.shopName ?? merchant.name, fallback: 'Merchant').replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    final pdfBytes = await generateKhataStatementPdf(
      merchant: merchant,
      startDate: startDate,
      endDate: endDate,
      orders: orders,
    );
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'Khata_Statement_$cleanShopName.pdf',
    );
  }
}
