import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class IncomeScreen extends StatelessWidget {
  const IncomeScreen({super.key});

  String _fmt(int n) => n.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  @override
  Widget build(BuildContext context) {
    final pv = context.watch<AppProvider>();
    final monthly = pv.monthlyIncome;
    final maxVal = monthly.values.fold(0, (a, b) => a > b ? a : b);
    final topItems = pv.topSellingItems;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Hero summary
            Container(
              width: double.infinity,
              color: AppColors.primary,
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Revenue', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text('${_fmt(pv.totalRevenue)} Ks',
                      style: const TextStyle(color: AppColors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _heroStat('This Month', '${_fmt(pv.thisMonthRevenue)} Ks', Icons.calendar_today_outlined),
                      const SizedBox(width: 10),
                      _heroStat('Last Month', '${_fmt(pv.lastMonthRevenue)} Ks', Icons.calendar_month_outlined),
                      const SizedBox(width: 10),
                      _heroStat('Avg. Order', '${_fmt(pv.avgOrderValue)} Ks', Icons.show_chart_outlined),
                    ],
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Quick stats row
                  Row(
                    children: [
                      _quickStat('Orders', '${pv.totalOrderCount}', Icons.receipt_outlined, AppColors.primary),
                      const SizedBox(width: 10),
                      _quickStat('Items Sold', '${pv.totalItemsSold}', Icons.sell_outlined, AppColors.success),
                      const SizedBox(width: 10),
                      _quickStat('Low Stock', '${pv.lowStockCount}', Icons.warning_amber_outlined, AppColors.danger),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Monthly Bar Chart
                  const Text('Monthly Revenue', style: AppText.h3),
                  const SizedBox(height: 4),
                  Text('Last 6 months', style: AppText.small),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 16, 14, 10),
                      child: Column(
                        children: [
                          SizedBox(
                            height: 148,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: monthly.entries.map((e) {
                                final ratio = maxVal > 0 ? e.value / maxVal : 0.0;
                                final isMax = e.value == maxVal && maxVal > 0;
                                return Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 3),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        if (e.value > 0)
                                          Text(
                                            '${(e.value / 1000).round()}K',
                                            style: TextStyle(
                                              fontSize: 9, fontWeight: FontWeight.w700,
                                              color: isMax ? AppColors.primary : AppColors.textHint,
                                            ),
                                          ),
                                        const SizedBox(height: 2),
                                        AnimatedContainer(
                                          duration: const Duration(milliseconds: 600),
                                          curve: Curves.easeOut,
                                          height: 100 * ratio,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.bottomCenter,
                                              end: Alignment.topCenter,
                                              colors: isMax
                                                  ? [AppColors.primary, AppColors.primaryLight]
                                                  : [AppColors.primarySurface, AppColors.primarySurface.withOpacity(0.5)],
                                            ),
                                            borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(e.key, style: AppText.caption.copyWith(fontSize: 9)),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Top Selling Items
                  const Text('Top Selling Items', style: AppText.h3),
                  const SizedBox(height: 10),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: topItems.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(16),
                              child: Text('No sales data yet', style: AppText.small),
                            )
                          : Column(
                              children: topItems.asMap().entries.map((e) {
                                final i = e.key;
                                final item = e.value;
                                return Column(
                                  children: [
                                    ListTile(
                                      dense: true,
                                      leading: Container(
                                        width: 28, height: 28,
                                        decoration: BoxDecoration(
                                          color: i == 0 ? AppColors.primary : AppColors.primarySurface,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text('${i + 1}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: i == 0 ? AppColors.white : AppColors.primary)),
                                        ),
                                      ),
                                      title: Text(item['name'] as String, style: AppText.bodyBold),
                                      subtitle: Text('${item['qty']} pcs sold', style: AppText.small),
                                      trailing: Text('${_fmt(item['revenue'] as int)} Ks', style: AppText.bodyBold.copyWith(color: AppColors.success)),
                                    ),
                                    if (i < topItems.length - 1) const Divider(height: 1, indent: 56),
                                  ],
                                );
                              }).toList(),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Transaction Stats
                  const Text('Transaction Stats', style: AppText.h3),
                  const SizedBox(height: 10),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        children: [
                          _statRow('Total Orders', '${pv.totalOrderCount} orders'),
                          const Divider(height: 1, indent: 16, endIndent: 16),
                          _statRow('Average Order Value', '${_fmt(pv.avgOrderValue)} Ks'),
                          const Divider(height: 1, indent: 16, endIndent: 16),
                          _statRow('Total Items Sold', '${pv.totalItemsSold} pcs'),
                          const Divider(height: 1, indent: 16, endIndent: 16),
                          _statRow('Total Parts in Inventory', '${pv.parts.length} items'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroStat(String label, String value, IconData icon) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: AppColors.white.withOpacity(0.7)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: AppColors.white, fontSize: 12, fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(label, style: TextStyle(color: AppColors.white.withOpacity(0.65), fontSize: 9, fontWeight: FontWeight.w600)),
        ],
      ),
    ),
  );

  Widget _quickStat(String label, String value, IconData icon, Color color) => Expanded(
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
            Text(label, style: AppText.caption),
          ],
        ),
      ),
    ),
  );

  Widget _statRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(
      children: [
        Text(label, style: AppText.body.copyWith(color: AppColors.textSecondary)),
        const Spacer(),
        Text(value, style: AppText.bodyBold),
      ],
    ),
  );
}
