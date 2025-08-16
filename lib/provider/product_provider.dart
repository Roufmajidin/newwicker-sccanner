import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../models/products.dart';

class ProductProvider extends ChangeNotifier {
  List<Product> _products = [];
  Product? _foundProduct;
  bool _isLoading = false;
  Product? get foundProduct => _foundProduct;
  List<Product> get allProducts => _products;
  bool get isLoading => _isLoading;
  Future<void> loadProducts() async {
    final String response = await rootBundle.loadString('assets/data.json');
    final List<dynamic> data = json.decode(response);
    _products = data.map((item) => Product.fromJson(item)).toList();
    notifyListeners();
  }

  set foundProduct(Product? prod) {
    _foundProduct = prod;
    notifyListeners();
  }

  // Fungsi load JSON

  void clearScan() {
    _foundProduct = null;
    notifyListeners();
  }

  Product findProductByNr(String nrCode) {
    final product = _products.firstWhere(
      (p) => p.articleCode == nrCode,
      orElse:
          () => Product(
            nr: nrCode,
            photo: '',
            articleCode: '',
            name: 'Tidak ditemukan',
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
            remarks: Remarks(
              rangka: RemarkDetail(harga: 0, sub: ''),
              anyam: RemarkDetail(harga: 0, sub: ''),
            ),
            fobJakartaInUsd: 0,
            valueInUsd: 0,
          ),
    );
    // _allProducts = product;
    _foundProduct = product;
    loadProducts();
    notifyListeners();
    return product;
  }
  // update 
  
}
