import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import 'inventory_screen.dart';
import 'sales_screen.dart';
import 'income_screen.dart';
import 'cart_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _tab = 0;

  static const _titles = ['Inventory', 'Sales History', 'Income'];

  final _screens = const [
    InventoryScreen(),
    SalesScreen(),
    IncomeScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final pv = context.watch<AppProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/logo.png',
                width: 36,
                height: 36,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 9),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('AutoHut', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.white, letterSpacing: 1.2)),
                Text(_titles[_tab], style: TextStyle(fontSize: 10, color: AppColors.white.withOpacity(0.75), fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                decoration: BoxDecoration(
                  color: pv.cartCount > 0 ? AppColors.accent : AppColors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.white.withOpacity(0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.shopping_cart_outlined, size: 17, color: AppColors.white),
                    const SizedBox(width: 5),
                    const Text('Cart', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.white)),
                    if (pv.cartCount > 0) ...[
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(8)),
                        child: Text('${pv.cartCount}',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.accent)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(index: _tab, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2),
            label: 'Inventory',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'Sales',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Income',
          ),
        ],
      ),
    );
  }
}
