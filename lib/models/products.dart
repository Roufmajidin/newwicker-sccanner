class Product {
  final String nr;
  final String photo;
  final String articleCode;
  final String name;
  final String categories;
  final Dimension itemDimension;
  final Dimension packingDimension;
  final SizeOfSet sizeOfSet;
  final String composition;
  final String finishing;
  final double cbm;
  final Remarks remarks;

  Product({
    required this.nr,
    required this.photo,
    required this.articleCode,
    required this.name,
    required this.categories,
    required this.itemDimension,
    required this.packingDimension,
    required this.sizeOfSet,
    required this.composition,
    required this.finishing,
    required this.cbm,
    required this.remarks,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      nr: json['nr'],
      photo: json['photo'],
      articleCode: json['article_code'],
      name: json['name'],
      categories: json['categories'],
      itemDimension: Dimension.fromJson(json['item_dimension']),
      packingDimension: Dimension.fromJson(json['packing_dimension']),
      sizeOfSet: SizeOfSet.fromJson(json['size_of_set']),
      composition: json['composition'],
      finishing: json['finishing'],
      cbm: (json['cbm'] as num).toDouble(),
      remarks: Remarks.fromJson(json['remarks']),
    );
  }

  Map<String, dynamic> toJson() => {
        'nr': nr,
        'photo': photo,
        'article_code': articleCode,
        'name': name,
        'categories': categories,
        'item_dimension': itemDimension.toJson(),
        'packing_dimension': packingDimension.toJson(),
        'size_of_set': sizeOfSet.toJson(),
        'composition': composition,
        'finishing': finishing,
        'cbm': cbm,
        'remarks': remarks.toJson(),
      };
}

class Dimension {
  final int w;
  final int d;
  final int h;

  Dimension({required this.w, required this.d, required this.h});

  factory Dimension.fromJson(Map<String, dynamic> json) {
    return Dimension(
      w: json['w'],
      d: json['d'],
      h: json['h'],
    );
  }

  Map<String, dynamic> toJson() => {
        'w': w,
        'd': d,
        'h': h,
      };
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

  factory SizeOfSet.fromJson(Map<String, dynamic> json) {
    return SizeOfSet(
      set2: json['set2'] ?? '',
      set3: json['set3'] ?? '',
      set4: json['set4'] ?? '',
      set5: json['set5'] ?? '',
    );
  }

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
      rangka: RemarkDetail.fromJson(json['rangka']),
      anyam: RemarkDetail.fromJson(json['anyam']),
    );
  }

  Map<String, dynamic> toJson() => {
        'rangka': rangka.toJson(),
        'anyam': anyam.toJson(),
      };
}

class RemarkDetail {
  final int harga;
  final String sub;

  RemarkDetail({required this.harga, required this.sub});

  factory RemarkDetail.fromJson(Map<String, dynamic> json) {
    return RemarkDetail(
      harga: json['harga'],
      sub: json['sub'],
    );
  }

  Map<String, dynamic> toJson() => {
        'harga': harga,
        'sub': sub,
      };
}
