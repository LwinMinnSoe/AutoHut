import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../models/part_model.dart';
import 'add_edit_part_screen.dart';
import 'part_detail_screen.dart';
import '../widgets/stat_card.dart';
import '../widgets/part_card.dart';

// ─── Filter type ──────────────────────────────────────────────────────────
enum _StatFilter { all, inStock, sold, lowStock }

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});
  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _searchCtrl = TextEditingController();
  String _searchField = 'all';
  String _selectedCategory = 'All';
  String _query = '';

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  List<PartModel> _filtered(List<PartModel> parts) {
    final q = _query.toLowerCase();
    return parts.where((p) {
      final catMatch = _selectedCategory == 'All' || p.category == _selectedCategory;
      if (q.isEmpty) return catMatch;
      final fieldMatch = switch (_searchField) {
        'name'   => p.name.toLowerCase().contains(q),
        'serial' => p.serialNumber.toLowerCase().contains(q),
        'model'  => p.modelNumber.toLowerCase().contains(q),
        'year'   => p.years.contains(q),
        _        => [p.name, p.serialNumber, p.modelNumber, p.years, p.carBrand, p.carModel]
            .any((v) => v.toLowerCase().contains(q)),
      };
      return catMatch && fieldMatch;
    }).toList();
  }

  IconData _catIcon(String cat) => switch (cat) {
    'Engine' => Icons.settings,
    'Brakes' => Icons.album_outlined,
    'Electrical' => Icons.bolt,
    'Suspension' => Icons.tune,
    'Body' => Icons.directions_car_outlined,
    'Transmission' => Icons.swap_horiz,
    'Cooling' => Icons.ac_unit,
    _ => Icons.label_outline,
  };

  // ── Tap stat card → show filtered sheet ──────────────────────────────
  void _showStatSheet(BuildContext ctx, AppProvider pv, _StatFilter filter) {
    late List<PartModel> list;
    late String title;
    late String subtitle;
    late IconData icon;
    late Color color;

    switch (filter) {
      case _StatFilter.all:
        list = List.from(pv.parts)..sort((a, b) => a.name.compareTo(b.name));
        title = 'All Parts';
        subtitle = '${list.length} items';
        icon = Icons.category_outlined;
        color = AppColors.primaryLight;
        break;
      case _StatFilter.inStock:
        list = pv.parts.where((p) => p.stock > 0).toList()
          ..sort((a, b) => b.stock.compareTo(a.stock));
        title = 'In Stock';
        subtitle = '${pv.totalStock} units total';
        icon = Icons.inventory_outlined;
        color = AppColors.primaryLight;
        break;
      case _StatFilter.sold:
        list = List.from(pv.parts)..sort((a, b) => b.sold.compareTo(a.sold));
        title = 'Sold Overview';
        subtitle = '${pv.totalSold} units sold';
        icon = Icons.check_circle_outline;
        color = AppColors.success;
        break;
      case _StatFilter.lowStock:
        list = pv.parts.where((p) => p.stock <= 5).toList()
          ..sort((a, b) => a.stock.compareTo(b.stock));
        title = 'Low Stock Alert';
        subtitle = '${list.length} items need restocking';
        icon = Icons.warning_amber_rounded;
        color = AppColors.danger;
        break;
    }

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilteredPartsSheet(
        title: title,
        subtitle: subtitle,
        icon: icon,
        color: color,
        parts: list,
        filter: filter,
        onPartTap: (part) {
          Navigator.pop(ctx);
          Navigator.push(ctx, MaterialPageRoute(
            builder: (_) => PartDetailScreen(part: part),
          ));
        },
      ),
    );
  }

  void _showCategoryPicker(BuildContext context, AppProvider pv) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        final allCats = ['All', ...pv.categories];
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 36, height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
            ),
            const Padding(
              padding: EdgeInsets.only(left: 16, bottom: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Select Category', style: AppText.h3),
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: allCats.length,
                itemBuilder: (_, i) {
                  final cat = allCats[i];
                  final count = cat == 'All'
                      ? pv.parts.length
                      : pv.parts.where((p) => p.category == cat).length;
                  final isSelected = _selectedCategory == cat;
                  return ListTile(
                    selected: isSelected,
                    selectedTileColor: AppColors.primarySurface,
                    leading: Container(
                      width: 34, height: 34,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(_catIcon(cat), size: 17,
                          color: isSelected ? AppColors.white : AppColors.textSecondary),
                    ),
                    title: Text(cat,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? AppColors.primary : AppColors.textPrimary,
                          fontSize: 14,
                        )),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('$count',
                          style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w700,
                            color: isSelected ? AppColors.white : AppColors.primary,
                          )),
                    ),
                    onTap: () {
                      setState(() => _selectedCategory = cat);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final pv = context.watch<AppProvider>();
    final parts = _filtered(pv.parts);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Stats bar
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
            child: Row(
              children: [
                StatCard(
                  label: 'Parts', value: '${pv.parts.length}',
                  icon: Icons.category_outlined,
                  onTap: () => _showStatSheet(context, pv, _StatFilter.all),
                ),
                const SizedBox(width: 8),
                StatCard(
                  label: 'In Stock', value: '${pv.totalStock}',
                  icon: Icons.inventory_outlined,
                  onTap: () => _showStatSheet(context, pv, _StatFilter.inStock),
                ),
                const SizedBox(width: 8),
                StatCard(
                  label: 'Sold', value: '${pv.totalSold}',
                  icon: Icons.check_circle_outline,
                  onTap: () => _showStatSheet(context, pv, _StatFilter.sold),
                ),
                const SizedBox(width: 8),
                StatCard(
                  label: 'Low Stock', value: '${pv.lowStockCount}',
                  icon: Icons.warning_amber_rounded,
                  isAlert: pv.lowStockCount > 0,
                  onTap: () => _showStatSheet(context, pv, _StatFilter.lowStock),
                ),
              ],
            ),
          ),

          // ── Search bar
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (v) => setState(() => _query = v),
                        decoration: const InputDecoration(
                          hintText: 'Search parts...',
                          prefixIcon: Icon(Icons.search, color: AppColors.textHint, size: 20),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                        ),
                        style: AppText.body,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const AddEditPartScreen())),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Part'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const Text('Search by:', style: AppText.caption),
                      const SizedBox(width: 8),
                      ...[
                        ('all', 'All Fields'), ('name', 'Name'),
                        ('serial', 'Serial No.'), ('model', 'Model No.'), ('year', 'Year'),
                      ].map((e) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: _searchChip(e.$1, e.$2),
                      )),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // ── Category picker button
          InkWell(
            onTap: () => _showCategoryPicker(context, pv),
            child: Container(
              color: AppColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              child: Row(
                children: [
                  Icon(_catIcon(_selectedCategory), size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    _selectedCategory == 'All' ? 'All Categories' : _selectedCategory,
                    style: AppText.bodyBold.copyWith(color: AppColors.primary),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(10)),
                    child: Text('${parts.length} parts',
                        style: AppText.caption.copyWith(color: AppColors.primary)),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.keyboard_arrow_down_rounded,
                      color: AppColors.primary, size: 22),
                ],
              ),
            ),
          ),

          const Divider(height: 1),

          // ── Parts grid
          Expanded(
            child: parts.isEmpty
                ? _empty()
                : GridView.builder(
                    padding: const EdgeInsets.all(10),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 300,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      mainAxisExtent: 390,
                    ),
                    itemCount: parts.length,
                    itemBuilder: (_, i) => PartCard(
                      part: parts[i],
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => PartDetailScreen(part: parts[i]))),
                      onEdit: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => AddEditPartScreen(part: parts[i]))),
                      onDelete: () => _confirmDelete(context, pv, parts[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _searchChip(String field, String label) {
    final isSelected = _searchField == field;
    return GestureDetector(
      onTap: () => setState(() => _searchField = field),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(label,
          style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600,
            color: isSelected ? AppColors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _empty() => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.inventory_2_outlined, size: 56, color: AppColors.border),
      const SizedBox(height: 12),
      Text('No parts found', style: AppText.h3.copyWith(color: AppColors.textHint)),
      const SizedBox(height: 4),
      const Text('Add a new part or adjust your filter', style: AppText.small),
    ]),
  );

  void _confirmDelete(BuildContext context, AppProvider pv, PartModel part) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Part?'),
        content: Text('Remove "${part.name}" permanently?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () { pv.deletePart(part.id); Navigator.pop(context); },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Filtered Parts Bottom Sheet
// ════════════════════════════════════════════════════════════════════════════
class _FilteredPartsSheet extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<PartModel> parts;
  final _StatFilter filter;
  final ValueChanged<PartModel> onPartTap;

  const _FilteredPartsSheet({
    required this.title, required this.subtitle,
    required this.icon, required this.color,
    required this.parts, required this.filter,
    required this.onPartTap,
  });

  String _fmt(int n) => n.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  Color _stockColor(int stock) =>
      stock == 0 ? AppColors.danger : stock <= 5 ? AppColors.warning : AppColors.success;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      snap: true,
      snapSizes: const [0.5, 0.75, 0.95],
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // ── Handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
            ),

            // ── Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color.withOpacity(0.25)),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: AppText.h2),
                        Text(subtitle, style: AppText.small.copyWith(color: color, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  // Close button
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 20),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.background,
                      shape: const CircleBorder(),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // ── List
            Expanded(
              child: parts.isEmpty
                  ? Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(icon, size: 48, color: AppColors.border),
                        const SizedBox(height: 12),
                        Text('No parts found', style: AppText.h3.copyWith(color: AppColors.textHint)),
                      ]),
                    )
                  : ListView.separated(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      itemCount: parts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (_, i) => _PartListTile(
                        part: parts[i],
                        filter: filter,
                        onTap: () => onPartTap(parts[i]),
                        stockColor: _stockColor(parts[i].stock),
                        fmt: _fmt,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Horizontal Part List Tile ─────────────────────────────────────────────
class _PartListTile extends StatelessWidget {
  final PartModel part;
  final _StatFilter filter;
  final VoidCallback onTap;
  final Color stockColor;
  final String Function(int) fmt;

  const _PartListTile({
    required this.part, required this.filter, required this.onTap,
    required this.stockColor, required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: filter == _StatFilter.lowStock && part.stock == 0
                  ? AppColors.danger.withOpacity(0.4)
                  : filter == _StatFilter.lowStock
                      ? AppColors.warning.withOpacity(0.4)
                      : AppColors.border,
              width: filter == _StatFilter.lowStock ? 1.5 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                // ── Photo
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 60, height: 60,
                    child: part.mediaPaths.isNotEmpty
                        ? Image.file(File(part.mediaPaths.first), fit: BoxFit.cover)
                        : Container(
                            color: AppColors.primarySurface,
                            child: Icon(Icons.settings_outlined,
                                size: 24, color: AppColors.primaryLight.withOpacity(0.5)),
                          ),
                  ),
                ),
                const SizedBox(width: 12),

                // ── Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name + category
                      Row(
                        children: [
                          Expanded(
                            child: Text(part.name,
                                style: AppText.bodyBold,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primarySurface,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(part.category,
                                style: AppText.caption.copyWith(color: AppColors.primary)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      // Brand + model
                      Text('${part.carBrand} ${part.carModel} · ${part.years}',
                          style: AppText.small,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      // Stock / Sold / Price row
                      Row(
                        children: [
                          _badge('STOCK', '${part.stock}', stockColor),
                          const SizedBox(width: 8),
                          _badge('SOLD', '${part.sold}', AppColors.success),
                          const Spacer(),
                          Text('${fmt(part.price)} Ks',
                              style: AppText.smallBold.copyWith(
                                  color: AppColors.primary, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Arrow
                const SizedBox(width: 6),
                Icon(Icons.chevron_right_rounded,
                    color: AppColors.textHint, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _badge(String label, String value, Color color) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(label, style: AppText.caption.copyWith(fontSize: 8)),
      const SizedBox(width: 3),
      Text(value, style: TextStyle(
          fontSize: 13, fontWeight: FontWeight.w800, color: color, height: 1)),
    ],
  );
}
