import 'package:uuid/uuid.dart';

class SaleItem {
  final String partId;
  final String name;
  final String serialNumber;
  final String modelNumber;
  final String carBrand;
  final String carModel;
  final String category;
  final int qty;
  final int unitPrice;
  final int subtotal;

  const SaleItem({
    required this.partId,
    required this.name,
    required this.serialNumber,
    required this.modelNumber,
    required this.carBrand,
    required this.carModel,
    required this.category,
    required this.qty,
    required this.unitPrice,
    required this.subtotal,
  });

  Map<String, dynamic> toJson() => {
        'partId': partId, 'name': name, 'serialNumber': serialNumber,
        'modelNumber': modelNumber, 'carBrand': carBrand, 'carModel': carModel,
        'category': category, 'qty': qty, 'unitPrice': unitPrice, 'subtotal': subtotal,
      };

  factory SaleItem.fromJson(Map<String, dynamic> j) => SaleItem(
        partId: j['partId'] as String, name: j['name'] as String,
        serialNumber: j['serialNumber'] as String, modelNumber: j['modelNumber'] as String,
        carBrand: j['carBrand'] as String, carModel: j['carModel'] as String,
        category: j['category'] as String, qty: j['qty'] as int,
        unitPrice: j['unitPrice'] as int, subtotal: j['subtotal'] as int,
      );
}

class SaleModel {
  final String id;
  final String invoiceNo;
  final DateTime date;
  final List<SaleItem> items;
  final int total;

  SaleModel({
    String? id,
    required this.invoiceNo,
    DateTime? date,
    required this.items,
    required this.total,
  })  : id = id ?? const Uuid().v4(),
        date = date ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'invoiceNo': invoiceNo,
        'date': date.toIso8601String(),
        'items': items.map((e) => e.toJson()).toList(),
        'total': total,
      };

  factory SaleModel.fromJson(Map<String, dynamic> j) => SaleModel(
        id: j['id'] as String,
        invoiceNo: j['invoiceNo'] as String,
        date: DateTime.parse(j['date'] as String),
        items: (j['items'] as List)
            .map((e) => SaleItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        total: j['total'] as int,
      );
}
