import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/part_model.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../utils/media_utils.dart'; // <-- import
import '../screens/media_viewer_screen.dart';

class PartCard extends StatelessWidget {
  final PartModel part;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const PartCard({super.key, required this.part, required this.onTap, required this.onEdit, required this.onDelete});

  Color get _stockColor => part.stock == 0 ? AppColors.danger : part.stock <= 5 ? AppColors.warning : AppColors.success;
  String _fmt(int n) => n.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  @override
  Widget build(BuildContext context) {
    final pv = context.watch<AppProvider>();
    final cartQty = pv.cartQtyFor(part.id);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MediaPreview(part: part),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: Text(part.name, style: AppText.bodyBold, maxLines: 2, overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(5)),
                    child: Text(part.category, style: AppText.caption.copyWith(color: AppColors.primary)),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text('${part.carBrand} ${part.carModel} · ${part.years}',
                  style: AppText.small, maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 6),
              Row(children: [
                _infoChip('SN', part.serialNumber),
                const SizedBox(width: 5),
                _infoChip('MN', part.modelNumber),
              ]),
              const SizedBox(height: 8),
              Row(
                children: [
                  _counter('STOCK', part.stock, _stockColor),
                  const SizedBox(width: 12),
                  _counter('SOLD', part.sold, AppColors.success),
                  const Spacer(),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    const Text('PRICE', style: AppText.caption),
                    Text('${_fmt(part.price)} Ks',
                        style: AppText.smallBold.copyWith(color: AppColors.primary)),
                  ]),
                ],
              ),
              if (part.stock <= 5)
                Container(
                  margin: const EdgeInsets.only(top: 5),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.dangerLight, borderRadius: BorderRadius.circular(5)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.warning_amber_rounded, size: 12, color: AppColors.danger),
                    const SizedBox(width: 3),
                    Text('Low Stock', style: AppText.caption.copyWith(color: AppColors.danger)),
                  ]),
                ),
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.shopping_cart_outlined, size: 14, color: AppColors.textHint),
                const SizedBox(width: 4),
                const Text('Cart', style: AppText.caption),
                const Spacer(),
                _QtyBtn(icon: Icons.remove, onTap: cartQty > 0 ? () => pv.setCartQty(part.id, cartQty - 1) : null),
                const SizedBox(width: 8),
                Text('$cartQty', style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w800,
                    color: cartQty > 0 ? AppColors.primary : AppColors.textHint)),
                const SizedBox(width: 8),
                _QtyBtn(icon: Icons.add, onTap: cartQty >= part.stock ? null : () => pv.setCartQty(part.id, cartQty + 1)),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 14),
                  label: const Text('Edit', style: TextStyle(fontSize: 11)),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 6), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                )),
                const SizedBox(width: 6),
                Expanded(child: OutlinedButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, size: 14),
                  label: const Text('Delete', style: TextStyle(fontSize: 11)),
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, side: const BorderSide(color: AppColors.danger), padding: const EdgeInsets.symmetric(vertical: 6), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                )),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoChip(String label, String value) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(5)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: AppText.caption),
        Text(value, style: AppText.caption.copyWith(color: AppColors.textPrimary, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
      ]),
    ),
  );

  Widget _counter(String label, int value, Color color) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: AppText.caption),
      Text('$value', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color, height: 1.1)),
    ],
  );
}

class _MediaPreview extends StatelessWidget {
  final PartModel part;
  const _MediaPreview({required this.part});

  @override
  Widget build(BuildContext context) {
    final paths = part.mediaPaths;
    final count = paths.length;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        children: [
          SizedBox(
            height: 90, width: double.infinity,
            child: count == 0
                ? Container(
              color: AppColors.primarySurface,
              child: Icon(Icons.settings_outlined, size: 28, color: AppColors.primaryLight.withOpacity(0.4)),
            )
                : isVideoPath(paths.first)
                ? VideoThumbnailWidget(path: paths.first, height: 90)
                : buildMediaImage(paths.first, fit: BoxFit.cover, width: double.infinity, height: 90), // <-- buildMediaImage ပြောင်းလဲခြင်း
          ),
          if (count > 1)
            Positioned(
              top: 6, right: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(10)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.perm_media_outlined, size: 10, color: Colors.white),
                  const SizedBox(width: 3),
                  Text('$count', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                ]),
              ),
            ),
        ],
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _QtyBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 26, height: 26,
      decoration: BoxDecoration(
        color: onTap != null ? AppColors.primarySurface : AppColors.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: onTap != null ? AppColors.primary.withOpacity(0.3) : AppColors.border),
      ),
      child: Icon(icon, size: 14, color: onTap != null ? AppColors.primary : AppColors.textHint),
    ),
  );
}