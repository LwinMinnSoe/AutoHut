import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/sale_model.dart';
import '../theme/app_theme.dart';

class InvoiceScreen extends StatelessWidget {
  final SaleModel sale;
  const InvoiceScreen({super.key, required this.sale});

  String _fmt(int n) => n.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(sale.invoiceNo),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined),
            tooltip: 'Print / Save PDF',
            onPressed: () => _printInvoice(context),
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share',
            onPressed: () => _printInvoice(context),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFE5E5E5),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 560),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(4),
              boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 16, offset: Offset(0, 4))],
            ),
            child: Column(
              children: [
                // ── Invoice Header
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.border)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Brand
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.asset(
                                    'assets/images/logo.png',
                                    width: 36, height: 36,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('AutoHut', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.primary, letterSpacing: 1)),
                                    Text('Quality Parts, Every Time.', style: TextStyle(fontSize: 9, color: AppColors.accent, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            const Text('Yangon, Myanmar', style: AppText.small),
                            const Text('Tel: +95 9 xxx xxx xxx', style: AppText.small),
                          ],
                        ),
                      ),
                      // Invoice info
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('INVOICE', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textPrimary, letterSpacing: 2)),
                          const SizedBox(height: 4),
                          Text(sale.invoiceNo, style: AppText.bodyBold.copyWith(color: AppColors.primary)),
                          const SizedBox(height: 4),
                          Text(DateFormat('dd MMM yyyy').format(sale.date), style: AppText.small),
                          Text(DateFormat('HH:mm').format(sale.date), style: AppText.small),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Items Table Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  decoration: const BoxDecoration(color: AppColors.primarySurface),
                  child: const Row(
                    children: [
                      SizedBox(width: 22, child: Text('#', style: AppText.label)),
                      SizedBox(width: 10),
                      Expanded(flex: 3, child: Text('ITEM', style: AppText.label)),
                      Expanded(flex: 2, child: Text('DETAILS', style: AppText.label)),
                      SizedBox(width: 30, child: Text('QTY', style: AppText.label, textAlign: TextAlign.center)),
                      SizedBox(width: 10),
                      SizedBox(width: 80, child: Text('UNIT', style: AppText.label, textAlign: TextAlign.right)),
                      SizedBox(width: 10),
                      SizedBox(width: 80, child: Text('TOTAL', style: AppText.label, textAlign: TextAlign.right)),
                    ],
                  ),
                ),

                // ── Items
                ...sale.items.asMap().entries.map((e) {
                  final i = e.key;
                  final item = e.value;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: i.isOdd ? AppColors.background : AppColors.white,
                      border: const Border(bottom: BorderSide(color: AppColors.divider)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 22,
                          child: Container(
                            width: 20, height: 20,
                            decoration: BoxDecoration(color: AppColors.primarySurface, shape: BoxShape.circle),
                            child: Center(child: Text('${i + 1}', style: AppText.caption.copyWith(color: AppColors.primary))),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.name, style: AppText.bodyBold),
                              Text('${item.carBrand} ${item.carModel}', style: AppText.small),
                              Text(item.category, style: AppText.small.copyWith(color: AppColors.primary)),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('SN: ${item.serialNumber}', style: AppText.small),
                              Text('MN: ${item.modelNumber}', style: AppText.small),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 30,
                          child: Text('${item.qty}', style: AppText.bodyBold, textAlign: TextAlign.center),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 80,
                          child: Text('${_fmt(item.unitPrice)}', style: AppText.body.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.right),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 80,
                          child: Text('${_fmt(item.subtotal)} Ks', style: AppText.bodyBold, textAlign: TextAlign.right),
                        ),
                      ],
                    ),
                  );
                }),

                // ── Total
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SizedBox(
                        width: 200,
                        child: Column(
                          children: [
                            _totalRow('Subtotal', '${_fmt(sale.total)} Ks'),
                            _totalRow('Tax / Discount', '—'),
                            const Divider(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('TOTAL', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.white)),
                                  Text('${_fmt(sale.total)} Ks', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.white)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Signatures
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                  child: Row(
                    children: ['Customer Signature', 'Seller Signature'].map((label) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            Container(height: 40, decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border)))),
                            const SizedBox(height: 6),
                            Text(label, style: AppText.caption),
                          ],
                        ),
                      ),
                    )).toList(),
                  ),
                ),

                // ── Footer
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                  child: Column(
                    children: [
                      const Divider(),
                      const SizedBox(height: 8),
                      const Text('Thank you for your business!', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                      const SizedBox(height: 3),
                      const Text('AutoHut · Quality Parts, Every Time. · Yangon, Myanmar', style: AppText.small),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _printInvoice(context),
        icon: const Icon(Icons.print_outlined),
        label: const Text('Print / Save PDF', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _totalRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppText.small),
        Text(value, style: AppText.smallBold),
      ],
    ),
  );

  Future<void> _printInvoice(BuildContext context) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                    pw.Text('AutoHut', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF2B5BA8))),
                    pw.Text('Quality Parts, Every Time.', style: const pw.TextStyle(fontSize: 10, color: PdfColor.fromInt(0xFFE8823A))),
                    pw.SizedBox(height: 8),
                    pw.Text('Yangon, Myanmar', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text('Tel: +95 9 xxx xxx xxx', style: const pw.TextStyle(fontSize: 10)),
                  ]),
                  pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                    pw.Text('INVOICE', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 4),
                    pw.Text(sale.invoiceNo, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF2B5BA8))),
                    pw.Text(DateFormat('dd MMM yyyy HH:mm').format(sale.date), style: const pw.TextStyle(fontSize: 10)),
                  ]),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Divider(color: const PdfColor.fromInt(0xFF2B5BA8), thickness: 2),
              pw.SizedBox(height: 16),

              // Table
              pw.Table(
                border: pw.TableBorder.all(color: const PdfColor.fromInt(0xFFD5E0F0), width: 0.5),
                columnWidths: {
                  0: const pw.FlexColumnWidth(0.4),
                  1: const pw.FlexColumnWidth(2.5),
                  2: const pw.FlexColumnWidth(2),
                  3: const pw.FlexColumnWidth(0.6),
                  4: const pw.FlexColumnWidth(1.2),
                  5: const pw.FlexColumnWidth(1.2),
                },
                children: [
                  // Header row
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFEEF3FC)),
                    children: ['#', 'Item', 'Details', 'Qty', 'Unit Price', 'Total'].map((h) =>
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(h, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)))
                    ).toList(),
                  ),
                  // Data rows
                  ...sale.items.asMap().entries.map((e) => pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${e.key + 1}', style: const pw.TextStyle(fontSize: 9))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                        pw.Text(e.value.name, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                        pw.Text('${e.value.carBrand} ${e.value.carModel}', style: const pw.TextStyle(fontSize: 8)),
                      ])),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                        pw.Text('SN: ${e.value.serialNumber}', style: const pw.TextStyle(fontSize: 8)),
                        pw.Text('MN: ${e.value.modelNumber}', style: const pw.TextStyle(fontSize: 8)),
                      ])),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${e.value.qty}', style: const pw.TextStyle(fontSize: 9), textAlign: pw.TextAlign.center)),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${_fmt(e.value.unitPrice)} Ks', style: const pw.TextStyle(fontSize: 9), textAlign: pw.TextAlign.right)),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${_fmt(e.value.subtotal)} Ks', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9), textAlign: pw.TextAlign.right)),
                    ],
                  )),
                ],
              ),
              pw.SizedBox(height: 16),

              // Total
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Container(
                  width: 200,
                  padding: const pw.EdgeInsets.all(12),
                  decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF2B5BA8)),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('TOTAL', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 12)),
                      pw.Text('${_fmt(sale.total)} Ks', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 12)),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(height: 40),

              // Footer
              pw.Divider(),
              pw.Center(child: pw.Text('Thank you for your business! · AutoHut · Yangon, Myanmar', style: const pw.TextStyle(fontSize: 9))),
            ],
          );
        },
      ),
    );
    await Printing.layoutPdf(onLayout: (_) => pdf.save());
  }
}
