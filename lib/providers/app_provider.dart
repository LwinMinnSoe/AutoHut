import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // <-- Supabase ထည့်သွင်းခြင်း
import '../models/part_model.dart';
import '../models/sale_model.dart';

class CartItem {
  final PartModel part;
  final int quantity;
  const CartItem({required this.part, required this.quantity});
}

class AppProvider extends ChangeNotifier {
  final _db = FirebaseFirestore.instance;
  final _supabase = Supabase.instance.client; // <-- Firebase Storage အစား Supabase သုံးခြင်း

  List<PartModel> _parts = [];
  List<SaleModel> _sales = [];
  List<String> _categories = ['Engine','Brakes','Electrical','Suspension','Body','Transmission','Cooling'];
  List<String> _brands = ['Toyota','Honda','Mitsubishi','Suzuki','Hyundai','Nissan','Mazda','Ford'];
  final Map<String, int> _cart = {};

  bool _loaded = false;
  bool _uploading = false;
  String? _error;

  StreamSubscription? _partsSub;
  StreamSubscription? _salesSub;
  StreamSubscription? _configSub;

  List<PartModel> get parts => _parts;
  List<SaleModel> get sales => _sales;
  List<String> get categories => _categories;
  List<String> get brands => _brands;
  Map<String, int> get cart => _cart;
  bool get loaded => _loaded;
  bool get uploading => _uploading;
  String? get error => _error;

  int cartQtyFor(String partId) => _cart[partId] ?? 0;

  List<CartItem> get cartItems => _cart.entries
      .map((e) {
    try {
      final p = _parts.firstWhere((p) => p.id == e.key);
      return CartItem(part: p, quantity: e.value);
    } catch (_) { return null; }
  })
      .whereType<CartItem>()
      .toList();

  int get cartCount => _cart.values.fold(0, (a, b) => a + b);
  int get cartTotal => cartItems.fold(0, (a, b) => a + b.part.price * b.quantity);

  int get totalStock => _parts.fold(0, (a, b) => a + b.stock);
  int get totalSold  => _parts.fold(0, (a, b) => a + b.sold);
  int get lowStockCount => _parts.where((p) => p.stock <= 5).length;
  int get totalRevenue  => _sales.fold(0, (a, b) => a + b.total);

  int get thisMonthRevenue {
    final now = DateTime.now();
    return _sales.where((s) => s.date.year == now.year && s.date.month == now.month)
        .fold(0, (a, b) => a + b.total);
  }
  int get lastMonthRevenue {
    final last = DateTime(DateTime.now().year, DateTime.now().month - 1);
    return _sales.where((s) => s.date.year == last.year && s.date.month == last.month)
        .fold(0, (a, b) => a + b.total);
  }
  int get avgOrderValue  => _sales.isEmpty ? 0 : totalRevenue ~/ _sales.length;
  int get totalOrderCount => _sales.length;
  int get totalItemsSold  => _sales.fold(0, (a, s) => a + s.items.fold(0, (b, it) => b + it.qty));

  Map<String, int> get monthlyIncome {
    final result = <String, int>{};
    for (int i = 5; i >= 0; i--) {
      final d = DateTime(DateTime.now().year, DateTime.now().month - i);
      final k = '${_mon(d.month)} ${d.year.toString().substring(2)}';
      result[k] = _sales.where((s) => s.date.year == d.year && s.date.month == d.month)
          .fold(0, (a, b) => a + b.total);
    }
    return result;
  }
  String _mon(int m) => ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][m-1];

  List<Map<String, dynamic>> get topSellingItems {
    final map = <String, Map<String, dynamic>>{};
    for (final s in _sales) {
      for (final it in s.items) {
        map.putIfAbsent(it.name, () => {'name': it.name, 'qty': 0, 'revenue': 0});
        map[it.name]!['qty'] = (map[it.name]!['qty'] as int) + it.qty;
        map[it.name]!['revenue'] = (map[it.name]!['revenue'] as int) + it.subtotal;
      }
    }
    return (map.values.toList()..sort((a,b) => (b['revenue'] as int).compareTo(a['revenue'] as int))).take(5).toList();
  }

  List<SaleModel> filteredSales(String period) {
    if (period == 'All') return _sales;
    final days = {'1M':30,'3M':90,'6M':180,'1Y':365}[period] ?? 30;
    final cut = DateTime.now().subtract(Duration(days: days));
    return _sales.where((s) => s.date.isAfter(cut)).toList();
  }

  AppProvider() { _init(); }

  void _init() {
    _listenParts();
    _listenSales();
    _listenConfig();
  }

  void _listenParts() {
    _partsSub = _db.collection('parts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snap) {
      _parts = snap.docs.map((d) => PartModel.fromJson({...d.data(), 'id': d.id})).toList();
      if (!_loaded) {
        _loaded = true;
        if (_parts.isEmpty) _seedSampleData();
      }
      notifyListeners();
    }, onError: (e) {
      _error = e.toString();
      _loaded = true;
      notifyListeners();
    });
  }

  void _listenSales() {
    _salesSub = _db.collection('sales')
        .orderBy('date', descending: true)
        .snapshots()
        .listen((snap) {
      _sales = snap.docs.map((d) => SaleModel.fromJson({...d.data(), 'id': d.id})).toList();
      notifyListeners();
    });
  }

  void _listenConfig() {
    _configSub = _db.doc('config/settings').snapshots().listen((snap) {
      if (snap.exists && snap.data() != null) {
        final data = snap.data()!;
        if (data['categories'] != null) _categories = List<String>.from(data['categories']);
        if (data['brands'] != null)     _brands     = List<String>.from(data['brands']);
        notifyListeners();
      } else {
        _db.doc('config/settings').set({'categories': _categories, 'brands': _brands});
      }
    });
  }

  @override
  void dispose() {
    _partsSub?.cancel();
    _salesSub?.cancel();
    _configSub?.cancel();
    super.dispose();
  }

  Future<void> addPart(PartModel part) async {
    _parts.insert(0, part); notifyListeners();
    await _db.collection('parts').doc(part.id).set(part.toJson());
  }

  Future<void> updatePart(PartModel updated) async {
    final i = _parts.indexWhere((p) => p.id == updated.id);
    if (i != -1) { _parts[i] = updated; notifyListeners(); }
    await _db.collection('parts').doc(updated.id).set(updated.toJson());
  }

  Future<void> deletePart(String id) async {
    try {
      // 1. ဖျက်မည့် ပစ္စည်းကို ID ဖြင့် အရင်ရှာပြီး ၎င်းတွင်ရှိသော ပုံလမ်းကြောင်း (URLs) များကို ယူမယ်
      final partToDelete = _parts.firstWhere((p) => p.id == id);

      // 2. ပုံလမ်းကြောင်းများ ရှိပါက Supabase Storage ထဲကနေ လိုက်ဖျက်မယ်
      if (partToDelete.mediaPaths.isNotEmpty) {
        final List<String> fileNames = partToDelete.mediaPaths.map((url) {
          // Public URL ကြီးထဲကနေ နောက်ဆုံးက ဖိုင်နာမည် သီးသန့်ကို ဖြတ်ထုတ်ယူခြင်း ဖြစ်ပါတယ်
          return url.split('/').last;
        }).toList();

        // Supabase Bucket ထဲမှ ဖိုင်များကို အစုလိုက် (Bulk) ဖျက်ချခြင်း
        await _supabase.storage.from('AutoHut').remove(fileNames);
        debugPrint('✅ Deleted storage files from Supabase: $fileNames');
      }
    } catch (e) {
      // Storage မှာ ဖိုင်မရှိတော့ရင်လည်း database ဆက်ဖျက်နိုင်အောင် error ကို ခေတ္တဖမ်းထားခြင်း
      debugPrint('⚠️ Storage delete warning or item not found: $e');
    }

    // 3. Local State နှင့် Firebase Firestore Database ထဲမှ ဖျက်ခြင်း (မူလကုဒ်ဟောင်း)
    _parts.removeWhere((p) => p.id == id);
    _cart.remove(id);
    notifyListeners();
    await _db.collection('parts').doc(id).delete();
  }

  void setCartQty(String partId, int qty) {
    if (qty <= 0) _cart.remove(partId); else _cart[partId] = qty;
    notifyListeners();
  }

  void clearCart() { _cart.clear(); notifyListeners(); }

  SaleModel? confirmOrder() {
    if (_cart.isEmpty) return null;
    final ci = cartItems;
    final items = ci.map((c) => SaleItem(
      partId: c.part.id, name: c.part.name,
      serialNumber: c.part.serialNumber, modelNumber: c.part.modelNumber,
      carBrand: c.part.carBrand, carModel: c.part.carModel,
      category: c.part.category, qty: c.quantity,
      unitPrice: c.part.price, subtotal: c.part.price * c.quantity,
    )).toList();

    final sale = SaleModel(
      invoiceNo: 'INV-${(_sales.length + 1).toString().padLeft(5, '0')}',
      items: items, total: cartTotal,
    );

    _sales.insert(0, sale);
    for (final c in ci) {
      final i = _parts.indexWhere((p) => p.id == c.part.id);
      if (i != -1) _parts[i] = _parts[i].copyWith(
        stock: _parts[i].stock - c.quantity,
        sold:  _parts[i].sold  + c.quantity,
      );
    }
    _cart.clear();
    notifyListeners();

    _commitOrder(sale, items);
    return sale;
  }

  Future<void> _commitOrder(SaleModel sale, List<SaleItem> items) async {
    try {
      final batch = _db.batch();
      batch.set(_db.collection('sales').doc(sale.id), sale.toJson());
      for (final it in items) {
        batch.update(_db.collection('parts').doc(it.partId), {
          'stock': FieldValue.increment(-it.qty),
          'sold':  FieldValue.increment(it.qty),
        });
      }
      await batch.commit();
    } catch (e) { debugPrint('Firestore order commit error: $e'); }
  }

  Future<void> addCategory(String cat) async {
    if (_categories.contains(cat)) return;
    _categories.add(cat); notifyListeners();
    await _db.doc('config/settings').update({'categories': FieldValue.arrayUnion([cat])});
  }

  Future<void> addBrand(String brand) async {
    if (_brands.contains(brand)) return;
    _brands.add(brand); notifyListeners();
    await _db.doc('config/settings').update({'brands': FieldValue.arrayUnion([brand])});
  }

  // ── Supabase Storage သို့ ပြောင်းလဲထားသော Upload Function ────────────────
  Future<List<String>> uploadMedia(List<String> paths) async {
    _uploading = true; notifyListeners();
    final result = <String>[];
    for (final path in paths) {
      if (path.startsWith('http')) { result.add(path); continue; }
      try {
        final file = File(path);
        if (!await file.exists()) continue;

        final bytes = await file.readAsBytes();
        final name = '${DateTime.now().millisecondsSinceEpoch}_${path.split(RegExp(r'[/\\]')).last}';

        // ── နာမည်ကို 'parts' အစား 'AutoHut' သို့ ပြောင်းလဲလိုက်ပါတယ် ──
        await _supabase.storage.from('AutoHut').uploadBinary(
            name,
            bytes,
            fileOptions: FileOptions(
                contentType: ['.mp4', '.mov', '.avi'].any(name.toLowerCase().endsWith) ? 'video/mp4' : 'image/jpeg'
            )
        );

        // ── နာမည်ကို 'parts' အစား 'AutoHut' သို့ ပြောင်းလဲလိုက်ပါတယ် ──
        final publicUrl = _supabase.storage.from('AutoHut').getPublicUrl(name);
        result.add(publicUrl);
      } catch (e) {
        debugPrint('❌ Supabase Upload Error: $e');
        _uploading = false; notifyListeners();
        rethrow;
      }
    }
    _uploading = false; notifyListeners();
    return result;
  }

  Future<void> _seedSampleData() async {
    final now = DateTime.now();
    final sample = [
      PartModel(name:'Brake Pad Set', serialNumber:'BP-2024-001', modelNumber:'TRW-GDB1234', years:'2018-2023', category:'Brakes', carBrand:'Toyota', carModel:'Camry', stock:22, sold:0, price:45000, createdAt:now.subtract(const Duration(days:90))),
      PartModel(name:'Oil Filter', serialNumber:'OF-2024-002', modelNumber:'MANN-W7015', years:'2015-2022', category:'Engine', carBrand:'Honda', carModel:'Civic', stock:55, sold:0, price:8500, createdAt:now.subtract(const Duration(days:80))),
    ];
    final batch = _db.batch();
    for (final p in sample) batch.set(_db.collection('parts').doc(p.id), p.toJson());
    batch.set(_db.doc('config/settings'), {'categories': _categories, 'brands': _brands});
    await batch.commit();
  }

  Future<void> deleteCategory(String category) async {
    _categories.remove(category); notifyListeners();
    await _db.doc('config/settings').update({'categories': FieldValue.arrayRemove([category])});
  }

  Future<void> deleteBrand(String brand) async {
    _brands.remove(brand); notifyListeners();
    await _db.doc('config/settings').update({'brands': FieldValue.arrayRemove([brand])});
  }
}