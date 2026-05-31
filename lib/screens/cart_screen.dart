import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/sale_model.dart';
import '../theme/app_theme.dart';
import 'invoice_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  String _fmt(int n) => n.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  @override
  Widget build(BuildContext context) {
    final pv = context.watch<AppProvider>();
    final items = pv.cartItems;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.shopping_cart_outlined, size: 20),
            const SizedBox(width: 8),
            const Text('Shopping Cart'),
            if (pv.cartCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(10)),
                child: Text('${pv.cartCount}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.white)),
              ),
            ],
          ],
        ),
        actions: [
          if (items.isNotEmpty)
            TextButton.icon(
              onPressed: () => _confirmClear(context, pv),
              icon: const Icon(Icons.delete_sweep_outlined, size: 18, color: AppColors.white),
              label: const Text('Clear', style: TextStyle(color: AppColors.white, fontSize: 12)),
            ),
        ],
      ),
      body: items.isEmpty ? _emptyCart() : Column(
        children: [
          // ── Cart Items List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(14),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final ci = items[i];
                final qty = ci.quantity;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        // Photo placeholder
                        Container(
                          width: 52, height: 52,
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.settings_outlined, color: AppColors.primaryLight, size: 24),
                        ),
                        const SizedBox(width: 12),
                        // Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(ci.part.name, style: AppText.bodyBold, maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 2),
                              Text('${ci.part.carBrand} ${ci.part.carModel}', style: AppText.small),
                              const SizedBox(height: 2),
                              Text('${_fmt(ci.part.price)} Ks / pc', style: AppText.small.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        // Qty controls
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                _qtyBtn(Icons.remove, qty > 0 ? () => pv.setCartQty(ci.part.id, qty - 1) : null),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  child: Text('$qty', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primary)),
                                ),
                                _qtyBtn(Icons.add, qty < ci.part.stock ? () => pv.setCartQty(ci.part.id, qty + 1) : null),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text('${_fmt(ci.part.price * qty)} Ks',
                                style: AppText.bodyBold.copyWith(color: AppColors.success)),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // ── Order Summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              boxShadow: [BoxShadow(color: Color(0x15000000), blurRadius: 12, offset: Offset(0, -4))],
            ),
            child: Column(
              children: [
                Row(children: [
                  const Text('Total Items', style: AppText.small),
                  const Spacer(),
                  Text('${pv.cartCount} pcs', style: AppText.bodyBold),
                ]),
                const Divider(height: 16),
                Row(children: [
                  const Text('TOTAL', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                  const Spacer(),
                  Text('${_fmt(pv.cartTotal)} Ks',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primary)),
                ]),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Continue Shopping'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () => _confirmOrder(context, pv),
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text('Confirm Order'),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyCart() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.shopping_cart_outlined, size: 64, color: AppColors.border),
        const SizedBox(height: 14),
        const Text('Cart is empty', style: AppText.h2),
        const SizedBox(height: 6),
        const Text('Add parts from Inventory', style: AppText.small),
      ],
    ),
  );

  Widget _qtyBtn(IconData icon, VoidCallback? onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 30, height: 30,
      decoration: BoxDecoration(
        color: onTap != null ? AppColors.primarySurface : AppColors.background,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: onTap != null ? AppColors.primary.withOpacity(0.35) : AppColors.border),
      ),
      child: Icon(icon, size: 15, color: onTap != null ? AppColors.primary : AppColors.textHint),
    ),
  );

  void _confirmClear(BuildContext context, AppProvider pv) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear Cart?'),
        content: const Text('Remove all items from cart?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () { pv.clearCart(); Navigator.pop(context); },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _confirmOrder(BuildContext context, AppProvider pv) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Order?'),
        content: Text('Total: ${_fmt(pv.cartTotal)} Ks\n${pv.cartCount} items'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final sale = pv.confirmOrder();
              Navigator.pop(context);
              if (sale != null) _showSuccess(context, sale);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showSuccess(BuildContext context, SaleModel sale) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: AppColors.success, size: 48),
        title: const Text('Order Confirmed!', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(sale.invoiceNo, style: AppText.bodyBold.copyWith(color: AppColors.primary)),
            const SizedBox(height: 4),
            Text('${_fmt(sale.total)} Ks', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.success)),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          OutlinedButton(onPressed: () { Navigator.pop(context); Navigator.pop(context); }, child: const Text('Close')),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => InvoiceScreen(sale: sale)));
            },
            icon: const Icon(Icons.print_outlined, size: 16),
            label: const Text('Print Invoice'),
          ),
        ],
      ),
    );
  }
}
