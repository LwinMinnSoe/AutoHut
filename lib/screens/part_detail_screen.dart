import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/part_model.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../utils/media_utils.dart'; // <-- import
import 'add_edit_part_screen.dart';
import 'media_viewer_screen.dart';

class PartDetailScreen extends StatefulWidget {
  final PartModel part;
  const PartDetailScreen({super.key, required this.part});
  @override
  State<PartDetailScreen> createState() => _PartDetailScreenState();
}

class _PartDetailScreenState extends State<PartDetailScreen> {
  late PageController _pageCtrl;
  int _mediaIndex = 0;

  @override
  void initState() { super.initState(); _pageCtrl = PageController(); }
  @override
  void dispose() { _pageCtrl.dispose(); super.dispose(); }

  String _fmt(int n) => n.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  Color _stockColor(int stock) => stock == 0 ? AppColors.danger : stock <= 5 ? AppColors.warning : AppColors.success;

  @override
  Widget build(BuildContext context) {
    final pv = context.watch<AppProvider>();
    final p = pv.parts.firstWhere((x) => x.id == widget.part.id, orElse: () => widget.part);
    final cartQty = pv.cartQtyFor(p.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(p.name, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddEditPartScreen(part: p)))),
          IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _confirmDelete(context, pv, p)),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MediaGallery(
              mediaPaths: p.mediaPaths,
              currentIndex: _mediaIndex,
              pageCtrl: _pageCtrl,
              onPageChanged: (i) => setState(() => _mediaIndex = i),
              onTap: (i) => Navigator.push(context, MaterialPageRoute(builder: (_) => MediaViewerScreen(mediaPaths: p.mediaPaths, initialIndex: i))),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: Text(p.name, style: AppText.h1)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(8)),
                      child: Text(p.category, style: AppText.smallBold.copyWith(color: AppColors.primary)),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  Text('${p.carBrand} ${p.carModel} · ${p.years}', style: AppText.small),
                  const SizedBox(height: 16),
                  _infoGrid([
                    ('Serial No.', p.serialNumber),
                    ('Model No.', p.modelNumber),
                    ('Car Brand', p.carBrand),
                    ('Car Model', p.carModel),
                    ('Compatible Years', p.years),
                    ('Price', '${_fmt(p.price)} Ks'),
                  ]),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(child: _statBox('CURRENT STOCK', '${p.stock}', _stockColor(p.stock))),
                    const SizedBox(width: 10),
                    Expanded(child: _statBox('TOTAL SOLD', '${p.sold}', AppColors.success)),
                  ]),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(children: [
                        const Icon(Icons.shopping_cart_outlined, color: AppColors.primary),
                        const SizedBox(width: 8),
                        const Text('Add to Cart', style: AppText.bodyBold),
                        const Spacer(),
                        _QtyControl(qty: cartQty, maxQty: p.stock, onChanged: (q) => pv.setCartQty(p.id, q)),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(child: OutlinedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddEditPartScreen(part: p))), icon: const Icon(Icons.edit_outlined, size: 16), label: const Text('Edit Part'))),
                    const SizedBox(width: 10),
                    Expanded(child: OutlinedButton.icon(onPressed: () => _confirmDelete(context, pv, p), icon: const Icon(Icons.delete_outline, size: 16), label: const Text('Delete'), style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, side: const BorderSide(color: AppColors.danger)))),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoGrid(List<(String, String)> items) => GridView.count(
    shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 2, childAspectRatio: 2.8, crossAxisSpacing: 8, mainAxisSpacing: 8,
    children: items.map((e) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(e.$1, style: AppText.caption),
        const SizedBox(height: 1),
        Text(e.$2, style: AppText.bodyBold, maxLines: 1, overflow: TextOverflow.ellipsis),
      ]),
    )).toList(),
  );

  Widget _statBox(String label, String value, Color color) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.3))),
    child: Column(children: [
      Text(label, style: AppText.caption.copyWith(color: color)),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: color, height: 1.1)),
    ]),
  );

  void _confirmDelete(BuildContext context, AppProvider pv, PartModel p) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Part?'), content: Text('Remove "${p.name}" permanently?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger), onPressed: () { pv.deletePart(p.id); Navigator.pop(context); Navigator.pop(context); }, child: const Text('Delete')),
        ],
      ),
    );
  }
}

class _MediaGallery extends StatelessWidget {
  final List<String> mediaPaths;
  final int currentIndex;
  final PageController pageCtrl;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onTap;

  const _MediaGallery({required this.mediaPaths, required this.currentIndex, required this.pageCtrl, required this.onPageChanged, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (mediaPaths.isEmpty) return _placeholder();
    return Column(
      children: [
        SizedBox(
          height: 260,
          child: PageView.builder(
            controller: pageCtrl, itemCount: mediaPaths.length, onPageChanged: onPageChanged,
            itemBuilder: (_, i) {
              final path = mediaPaths[i];
              return GestureDetector(
                onTap: () => onTap(i),
                child: Stack(
                  children: [
                    SizedBox.expand(child: isVideoPath(path) ? VideoThumbnailWidget(path: path, height: 260) : buildMediaImage(path, fit: BoxFit.cover)), // <-- buildMediaImage သုံးခြင်း
                    Positioned(
                      bottom: 8, right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                        child: const Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.fullscreen, color: Colors.white, size: 14),
                          SizedBox(width: 3),
                          Text('Tap to view', style: TextStyle(color: Colors.white, fontSize: 10)),
                        ]),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        if (mediaPaths.length > 1) ...[
          SizedBox(
            height: 56,
            child: ListView.builder(
              scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12), itemCount: mediaPaths.length,
              itemBuilder: (_, i) {
                final isActive = currentIndex == i; final path = mediaPaths[i];
                return GestureDetector(
                  onTap: () => pageCtrl.animateToPage(i, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200), margin: const EdgeInsets.only(right: 8), width: 56,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: isActive ? AppColors.primary : AppColors.border, width: isActive ? 2.5 : 1)),
                    child: ClipRRect(borderRadius: BorderRadius.circular(6.5), child: isVideoPath(path) ? Container(color: AppColors.textPrimary, child: const Icon(Icons.play_circle_outline, color: Colors.white, size: 22)) : buildMediaImage(path, fit: BoxFit.cover)), // <-- buildMediaImage သုံးခြင်း
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(mediaPaths.length, (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 220), margin: const EdgeInsets.symmetric(horizontal: 3), width: currentIndex == i ? 18 : 6, height: 6,
              decoration: BoxDecoration(color: currentIndex == i ? AppColors.primary : AppColors.border, borderRadius: BorderRadius.circular(3)),
            )),
          ),
          const SizedBox(height: 4),
        ],
      ],
    );
  }

  Widget _placeholder() => Container(
    height: 200, color: AppColors.primarySurface,
    child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.image_outlined, size: 48, color: AppColors.primaryLight.withOpacity(0.4)),
      const SizedBox(height: 8),
      Text('No photos', style: AppText.small.copyWith(color: AppColors.textHint)),
    ])),
  );
}

class _QtyControl extends StatelessWidget {
  final int qty, maxQty;
  final ValueChanged<int> onChanged;
  const _QtyControl({required this.qty, required this.maxQty, required this.onChanged});

  @override
  Widget build(BuildContext context) => Row(children: [
    _btn(Icons.remove, qty > 0 ? () => onChanged(qty - 1) : null),
    Padding(padding: const EdgeInsets.symmetric(horizontal: 14), child: Text('$qty', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: qty > 0 ? AppColors.primary : AppColors.textHint))),
    _btn(Icons.add, qty < maxQty ? () => onChanged(qty + 1) : null),
  ]);

  Widget _btn(IconData icon, VoidCallback? onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 32, height: 32,
      decoration: BoxDecoration(color: onTap != null ? AppColors.primarySurface : AppColors.background, borderRadius: BorderRadius.circular(8), border: Border.all(color: onTap != null ? AppColors.primary.withOpacity(0.4) : AppColors.border)),
      child: Icon(icon, size: 16, color: onTap != null ? AppColors.primary : AppColors.textHint),
    ),
  );
}