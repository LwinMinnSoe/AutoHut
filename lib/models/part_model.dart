import 'package:uuid/uuid.dart';

class PartModel {
  final String id;
  final String name;
  final String serialNumber;
  final String modelNumber;
  final String years;
  final String category;
  final String carBrand;
  final String carModel;
  final int stock;
  final int sold;
  final int price;
  final List<String> mediaPaths;   // up to 4 photos/videos
  final DateTime createdAt;

  PartModel({
    String? id,
    required this.name,
    required this.serialNumber,
    required this.modelNumber,
    required this.years,
    required this.category,
    required this.carBrand,
    required this.carModel,
    required this.stock,
    this.sold = 0,
    required this.price,
    List<String>? mediaPaths,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        mediaPaths = mediaPaths ?? [],
        createdAt = createdAt ?? DateTime.now();

  // Convenience — first photo or null
  String? get primaryPhoto => mediaPaths.isNotEmpty ? mediaPaths.first : null;

  PartModel copyWith({
    String? name, String? serialNumber, String? modelNumber,
    String? years, String? category, String? carBrand, String? carModel,
    int? stock, int? sold, int? price, List<String>? mediaPaths,
  }) => PartModel(
    id: id,
    name: name ?? this.name,
    serialNumber: serialNumber ?? this.serialNumber,
    modelNumber: modelNumber ?? this.modelNumber,
    years: years ?? this.years,
    category: category ?? this.category,
    carBrand: carBrand ?? this.carBrand,
    carModel: carModel ?? this.carModel,
    stock: stock ?? this.stock,
    sold: sold ?? this.sold,
    price: price ?? this.price,
    mediaPaths: mediaPaths ?? List.from(this.mediaPaths),
    createdAt: createdAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'serialNumber': serialNumber,
    'modelNumber': modelNumber, 'years': years, 'category': category,
    'carBrand': carBrand, 'carModel': carModel, 'stock': stock,
    'sold': sold, 'price': price,
    'mediaPaths': mediaPaths,
    'createdAt': createdAt.toIso8601String(),
  };

  factory PartModel.fromJson(Map<String, dynamic> j) => PartModel(
    id: j['id'] as String,
    name: j['name'] as String,
    serialNumber: j['serialNumber'] as String,
    modelNumber: j['modelNumber'] as String,
    years: j['years'] as String,
    category: j['category'] as String,
    carBrand: j['carBrand'] as String,
    carModel: j['carModel'] as String,
    stock: j['stock'] as int,
    sold: (j['sold'] as int?) ?? 0,
    price: j['price'] as int,
    mediaPaths: j['mediaPaths'] != null
        ? List<String>.from(j['mediaPaths'] as List)
        : (j['photoPath'] != null ? [j['photoPath'] as String] : []),
    createdAt: DateTime.parse(j['createdAt'] as String),
  );
}
