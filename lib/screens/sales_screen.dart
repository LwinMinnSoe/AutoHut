import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/sale_model.dart';
import '../theme/app_theme.dart';
import 'invoice_screen.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});
  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  String _period = '1M';
  String? _expandedId;

  static const _periods = [
    ('1M', '1 Month'), ('3M', '3 Months'),
    ('6M', '6 Months'), ('1Y', '1 Year'), ('All', 'All Time'),
  ];

  String _fmt(int n) => n.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  @override
  Widget build(BuildContext context) {
    final pv = context.watch<AppProvider>();
    final sales = pv.filteredSales(_period);
    final periodTotal = sales.fold(0, (a, b) => a + b.total);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Blue header with period filter
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Period label
                const Text('Period', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                const SizedBox(height: 6),
                // Custom period chips - NO ChoiceChip
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _periods.map((p) => _periodBtn(p.$1, p.$2)).toList(),
                  ),
                ),
                const SizedBox(height: 12),
                // Stats
                Row(
                  children: [
                    _headerStat('Transactions', '${sales.length}'),
                    const SizedBox(width: 20),
                    _headerStat('Total Revenue', '${_fmt(periodTotal)} Ks'),
                  ],
                ),
              ],
            ),
          ),

          // ── Sales list
          Expanded(
            child: sales.isEmpty
                ? _empty()
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: sales.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _saleRow(context, sales[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _periodBtn(String period, String label) {
    final isSelected = _period == period;
    return GestureDetector(
      onTap: () => setState(() { _period = period; _expandedId = null; }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 7),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent : AppColors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.white.withOpacity(0.35),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              const Icon(Icons.check_rounded, size: 12, color: AppColors.white),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: AppColors.white,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerStat(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: TextStyle(color: AppColors.white.withOpacity(0.7), fontSize: 10, fontWeight: FontWeight.w600)),
      Text(value, style: const TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.w800)),
    ],
  );

  Widget _saleRow(BuildContext context, SaleModel sale) {
    final isExpanded = _expandedId == sale.id;
    return Card(
      child: Column(
        children: [
          // Row header
          InkWell(
            onTap: () => setState(() => _expandedId = isExpanded ? null : sale.id),
            borderRadius: isExpanded
                ? const BorderRadius.vertical(top: Radius.circular(12))
                : BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.receipt_long_outlined, size: 18, color: AppColors.primary),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Text(sale.invoiceNo, style: AppText.bodyBold.copyWith(color: AppColors.primary)),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(6)),
                            child: Text('${sale.items.length} items', style: AppText.caption.copyWith(color: AppColors.primary)),
                          ),
                        ]),
                        const SizedBox(height: 2),
                        Text(DateFormat('dd MMM yyyy  HH:mm').format(sale.date), style: AppText.small),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${_fmt(sale.total)} Ks', style: AppText.bodyBold.copyWith(color: AppColors.success)),
                      const SizedBox(height: 5),
                      GestureDetector(
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => InvoiceScreen(sale: sale))),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.print_outlined, size: 11, color: AppColors.textSecondary),
                            const SizedBox(width: 3),
                            Text('Invoice', style: AppText.caption.copyWith(color: AppColors.textSecondary)),
                          ]),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 6),
                  Icon(isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: AppColors.textHint, size: 20),
                ],
              ),
            ),
          ),
          // Expanded detail
          if (isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(children: [
                ...sale.items.asMap().entries.map((e) {
                  final idx = e.key;
                  final item = e.value;
                  return Padding(
                    padding: EdgeInsets.only(bottom: idx < sale.items.length - 1 ? 10 : 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 22, height: 22,
                          decoration: BoxDecoration(color: AppColors.primarySurface, shape: BoxShape.circle),
                          child: Center(child: Text('${idx + 1}', style: AppText.caption.copyWith(color: AppColors.primary))),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.name, style: AppText.bodyBold),
                            Text('${item.carBrand} ${item.carModel}  ·  SN: ${item.serialNumber}', style: AppText.small),
                            Text('MN: ${item.modelNumber}  ·  ${item.category}', style: AppText.small),
                          ],
                        )),
                        const SizedBox(width: 8),
                        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          Text('${_fmt(item.unitPrice)} × ${item.qty}', style: AppText.small),
                          Text('${_fmt(item.subtotal)} Ks',
                              style: AppText.smallBold.copyWith(color: AppColors.success)),
                        ]),
                      ],
                    ),
                  );
                }),
                const Divider(height: 16),
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  const Text('Order Total:', style: AppText.bodyBold),
                  const SizedBox(width: 8),
                  Text('${_fmt(sale.total)} Ks',
                      style: AppText.bodyBold.copyWith(color: AppColors.primary, fontSize: 15)),
                ]),
              ]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _empty() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.receipt_long_outlined, size: 56, color: AppColors.border),
        const SizedBox(height: 12),
        const Text('No sales in this period', style: AppText.h3),
        const SizedBox(height: 4),
        const Text('Try selecting a wider date range', style: AppText.small),
      ],
    ),
  );
}
