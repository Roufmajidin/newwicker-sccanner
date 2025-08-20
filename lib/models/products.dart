import 'package:intl/intl.dart';

class Product {
  final String nr;
  final String photo;
  final String articleCode;
  final String name;
  final String categories;
  final String subCategories;
  final Dimension itemDimension;
  final Dimension packingDimension;
  final SizeOfSet sizeOfSet;
  final String composition;
  final String finishing;
  final double qty;
  final double cbm;
  final double totalCbm;
  final Remarks remarks;
  final double fobJakartaInUsd;
  final double valueInUsd;

  Product({
    required this.nr,
    required this.photo,
    required this.articleCode,
    required this.name,
    required this.categories,
    required this.subCategories,
    required this.itemDimension,
    required this.packingDimension,
    required this.sizeOfSet,
    required this.composition,
    required this.finishing,
    required this.qty,
    required this.cbm,
    required this.totalCbm,
    required this.remarks,
    required this.fobJakartaInUsd,
    required this.valueInUsd,
  });
  factory Product.empty() {
    return Product(
      nr: '',
      photo: '',
      articleCode: '',
      name: '',
      categories: '',
      subCategories: '',
      itemDimension: Dimension(w: 0, d: 0, h: 0),
      packingDimension: Dimension(w: 0, d: 0, h: 0),
      sizeOfSet: SizeOfSet(set2: '', set3: '', set4: '', set5: ''),
      composition: '',
      finishing: '',
      qty: 0,
      cbm: 0,
      totalCbm: 0,
      remarks: Remarks.empty(),
      fobJakartaInUsd: 0,
      valueInUsd: 0,
    );
  }

  /// Format angka desimal dengan 2 angka di belakang koma
  String get cbmFormatted => cbm.toStringAsFixed(2);

  String get totalCbmFormatted => totalCbm.toStringAsFixed(2);

  /// Format dimensi jadi "W x D x H cm"
  String get itemDimensionFormatted =>
      '${_formatNumber(itemDimension.w)} x ${_formatNumber(itemDimension.d)} x ${_formatNumber(itemDimension.h)} cm';

  String get packingDimensionFormatted =>
      '${_formatNumber(packingDimension.w)} x ${_formatNumber(packingDimension.d)} x ${_formatNumber(packingDimension.h)} cm';

  /// Format USD ke Rupiah
  String get fobJakartaInUsdFormatted =>
      _formatCurrency(fobJakartaInUsd, 'USD');

  String get valueInUsdFormatted => _formatCurrency(valueInUsd, 'USD');

  String get fobJakartaInIdrFormatted =>
      _formatCurrency(fobJakartaInUsd * 16000, 'IDR');

  String get valueInIdrFormatted => _formatCurrency(valueInUsd * 16000, 'IDR');

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      nr: json['nr']?.toString() ?? json['nr.']?.toString() ?? '',
      photo: json['photo']?.toString() ?? '',
      articleCode: json['article_code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      categories: json['categories']?.toString() ?? '',
      subCategories: json['sub_categories']?.toString() ?? '',
      itemDimension: Dimension.fromJson(json['item_dimension'] ?? {}),
      packingDimension: Dimension.fromJson(json['packing_dimension'] ?? {}),
      sizeOfSet: SizeOfSet(
        set2: json['size_of_set_set_2']?.toString() ?? '',
        set3: json['size_of_set_set_3']?.toString() ?? '',
        set4: json['size_of_set_set_4']?.toString() ?? '',
        set5: json['size_of_set_set_5']?.toString() ?? '',
      ),
      composition: json['composition']?.toString() ?? '',
      finishing: json['finishing']?.toString() ?? '',
      qty: _parseNum(json['qty']).toDouble(),
      cbm: _parseNum(json['cbm']).toDouble(),
      totalCbm: _parseNum(json['total_cbm']).toDouble(),
      remarks:
          json['remarks'] is Map<String, dynamic>
              ? Remarks.fromJson(json['remarks'])
              : Remarks.empty(),
      fobJakartaInUsd: _parseNum(json['fob_jakarta_in_usd']).toDouble(),
      valueInUsd: _parseNum(json['value_in_usd']).toDouble(),
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'nr': nr,
      'photo': photo,
      'article_code': articleCode,
      'name': name,
      'categories': categories,
      'sub_categories': subCategories,
      'item_dimension': itemDimension,
      'packing_dimension': packingDimension,
      'size_of_set': sizeOfSet,
      'composition': composition,
      'finishing': finishing,
      'qty': qty,
      'cbm': cbm,
      'total_cbm': totalCbm,
      'remarks': remarks,
      'fob_jakarta_in_usd': fobJakartaInUsd,
      'value_in_usd': valueInUsd,
    };
  }

  Map<String, dynamic> toJson() => {
    'nr': nr,
    'photo': photo,
    'article_code': articleCode,
    'name': name,
    'categories': categories,
    'sub_categories': subCategories,
    'item_dimension': itemDimension.toJson(),
    'packing_dimension': packingDimension.toJson(),
    'size_of_set_set_2': sizeOfSet.set2,
    'size_of_set_set_3': sizeOfSet.set3,
    'size_of_set_set_4': sizeOfSet.set4,
    'size_of_set_set_5': sizeOfSet.set5,
    'composition': composition,
    'finishing': finishing,
    'qty': qty,
    'cbm': cbm,
    'total_cbm': totalCbm,
    'remarks': remarks.toJson(),
    'fob_jakarta_in_usd': fobJakartaInUsd,
    'value_in_usd': valueInUsd,
  };
}

class Dimension {
  final double w;
  final double d;
  final double h;

  Dimension({required this.w, required this.d, required this.h});

  factory Dimension.fromJson(Map<String, dynamic> json) {
    return Dimension(
      w: _parseNum(json['w']).toDouble(),
      d: _parseNum(json['d']).toDouble(),
      h: _parseNum(json['h']).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {'w': w, 'd': d, 'h': h};
  String formatted({String unit = "cm"}) {
    return "${w.toStringAsFixed(0)} x ${d.toStringAsFixed(0)} x ${h.toStringAsFixed(0)} $unit";
  }
}


class SizeOfSet {
  final String set2;
  final String set3;
  final String set4;
  final String set5;

  SizeOfSet({
    required this.set2,
    required this.set3,
    required this.set4,
    required this.set5,
  });

  Map<String, dynamic> toJson() => {
    'set2': set2,
    'set3': set3,
    'set4': set4,
    'set5': set5,
  };
}

class Remarks {
  final RemarkDetail rangka;
  final RemarkDetail anyam;

  Remarks({required this.rangka, required this.anyam});

  factory Remarks.fromJson(Map<String, dynamic> json) {
    return Remarks(
      rangka: RemarkDetail.fromJson(json['rangka'] ?? {}),
      anyam: RemarkDetail.fromJson(json['anyam'] ?? {}),
    );
  }

  factory Remarks.empty() {
    return Remarks(
      rangka: RemarkDetail(harga: 0, sub: ''),
      anyam: RemarkDetail(harga: 0, sub: ''),
    );
  }

  Map<String, dynamic> toJson() => {
    'rangka': rangka.toJson(),
    'anyam': anyam.toJson(),
  };
}

class RemarkDetail {
  final double harga;
  final String sub;

  RemarkDetail({required this.harga, required this.sub});

  factory RemarkDetail.fromJson(Map<String, dynamic> json) {
    return RemarkDetail(
      harga: _parseNum(json['harga']).toDouble(),
      sub: json['sub']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'harga': harga, 'sub': sub};
}

/// Helper parsing angka, string angka, atau pecahan
num _parseNum(dynamic value) {
  if (value == null) return 0;

  if (value is num) return value;

  if (value is String) {
    final parsed = num.tryParse(value);
    if (parsed != null) return parsed;

    // Format pecahan "a/b"
    if (value.contains('/')) {
      final parts = value.split('/');
      if (parts.length == 2) {
        final num1 = num.tryParse(parts[0].trim()) ?? 0;
        final num2 = num.tryParse(parts[1].trim()) ?? 1;
        if (num2 != 0) {
          return num1 / num2;
        }
      }
    }
  }

  return 0;
}

/// Helper format angka
String _formatNumber(double value) {
  return value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(2);
}

/// Helper format currency
String _formatCurrency(double value, String currency) {
  final format = NumberFormat.currency(
    locale: 'en_US',
    symbol: currency == 'USD' ? '\$' : 'Rp ',
    decimalDigits: 2,
  );
  return format.format(value);
}
