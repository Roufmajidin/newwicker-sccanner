// cart_provider.dart
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:newwicker/helpers/image_from_external.dart';
import 'package:newwicker/views/databases/stactic_db.dart';

enum CartState {
  initial, // awal, belum ada apa-apa
  loading, // sedang fetch
  success, // data berhasil
  error, // ada error
}

class CartProvider extends ChangeNotifier {
  final DBHelper _dbHelper = DBHelper.instance;
  List<Map<String, dynamic>> _items = [];

  List<Map<String, dynamic>> get items => _items;
  List<Map<String, dynamic>> _cartItems = [];
  List<Map<String, dynamic>> get cartItems => _cartItems;

  // Data buyer + cart
  List<Map<String, dynamic>> _buyerWithCarts = [];
  List<Map<String, dynamic>> get buyerWithCarts => _buyerWithCarts;
  // cache
  final Map<String, Uint8List?> _imageCache = {}; // cache gambar
  final Map<String, dynamic> _cartDetails = {}; // cache detail cart

  Uint8List? getImage(String articleCode) => _imageCache[articleCode];
  dynamic getCartDetail(String articleCode) => _cartDetails[articleCode];
  CartState _state = CartState.initial;
  CartState get state => _state;
  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  Future<Uint8List?> loadImage(String articleCode) async {
    // ini memanggil helper kamu
    return await ImageHelper.loadWithCache(articleCode);
  }

  Future<void> fetchCart() async {
    final data = await DBHelper.instance.getDarftCart();
    _cartItems = data;
    notifyListeners();
  }

  Future<void> init() async {
    final db = await _dbHelper.database;
    _items = await db.query('cart');
    notifyListeners();
  }

  Future<void> addToCart(String articleCode, int buyerId) async {
    await _dbHelper.insertCart({
      'article_code': articleCode,
      'created_at': DateTime.now().toIso8601String(),
      'buyer_id': buyerId,
    });
    await init(); // refresh list setelah insert
  }

  Future<void> removeFromCart(int id) async {
    final db = DBHelper.instance;
    await db.deleteCart(id);
    await fetchCart();
    notifyListeners();
  }

  Future<void> removeFromCartBuyer(int id, int buyerId) async {
    final db = DBHelper.instance;
    await db.deleteCart(id);
    await fetchCartByBuyer(buyerId);
    notifyListeners();
  }

  Future<void> deletebuyerwt(int id) async {
    final db = DBHelper.instance;
    await db.deleteBuyerWithCart(id);
    await fetchCart();
  }

  Future<void> assign(
    List<String> articleCodes, {
    required int orderNo,
    required String companyName,
    String? country,
    String? shipmentDate,
    String? packing,
    String? contactPerson,
    String? createdAt,
    Map<String, String>? remarks, // <article_code, remark>
    int? buyerId,
  }) async {
    await _dbHelper.assignCartToBuyer(
      articleCodes,
      orderNo: orderNo,
      companyName: companyName,
      country: country,
      shipmentDate: shipmentDate,
      packing: packing,
      contactPerson: contactPerson,
      createdAt: createdAt,
      remarks: remarks,
      buyerId: buyerId,
    );

    // Refresh cart dan buyerWithCarts
    if (buyerId != null && buyerId != 1) {
      await fetchCartByBuyer(buyerId);
    } else {
      // Jika buyer baru, ambil id terakhir
      final db = await _dbHelper.database;
      final lastBuyer = await db.query('buyer', orderBy: 'id DESC', limit: 1);
      if (lastBuyer.isNotEmpty) {
        await fetchCartByBuyer(lastBuyer.first['id'] as int);
      }
    }

    await fetchCart(); // refresh draft cart
  }

  Future<void> assignTo(
    List<String> articleCodes, {
    required int orderNo,
    required String companyName,
    String? country,
    String? shipmentDate,
    String? packing,
    String? contactPerson,
    String? createdAt,
    Map<String, String>? remarks, // <article_code, remark>
    int? buyerId,
  }) async {
    await _dbHelper.assignOrUpdateCartBuyer(
      articleCodes,
      orderNo: orderNo,
      companyName: companyName,
      country: country,
      shipmentDate: shipmentDate,
      packing: packing,
      contactPerson: contactPerson,
      createdAt: createdAt,
      remarks: remarks,
      buyerId: buyerId,
    );

    // Refresh cart dan buyerWithCarts
    if (buyerId != null && buyerId != 1) {
      await fetchCartByBuyer(buyerId);
    } else {
      // Jika buyer baru, ambil id terakhir
      final db = await _dbHelper.database;
      final lastBuyer = await db.query('buyer', orderBy: 'id DESC', limit: 1);
      if (lastBuyer.isNotEmpty) {
        await fetchCartByBuyer(lastBuyer.first['id'] as int);
      }
    }

    await fetchCart(); // refresh draft cart
  }

  Future<void> fetchCartByBuyer(int buyerId) async {
    try {
      _state = CartState.loading;
      notifyListeners();

      final db = await _dbHelper.database;

      // 1️⃣ Ambil buyer
      final buyers = await db.query(
        'buyer',
        where: 'id = ?',
        whereArgs: [buyerId],
      );

      if (buyers.isEmpty) {
        _buyerWithCarts = [];
        _state = CartState.success; // sukses tapi kosong
        notifyListeners();
        return;
      }

      final buyer = buyers.first;

      // 2️⃣ Ambil cart untuk buyer ini
      final carts = await db.query(
        'cart',
        where: 'buyer_id = ?',
        whereArgs: [buyerId],
        orderBy: 'id ASC',
      );

      // 3️⃣ Simpan buyer + cart ke list
      _buyerWithCarts = [
        {'buyer': buyer, 'carts': carts},
      ];

      _state = CartState.success;
      notifyListeners();

      print('buyer : $_buyerWithCarts');
    } catch (e) {
      _state = CartState.error;
      _errorMessage = e.toString();
      notifyListeners();
      print("❌ Error fetchCartByBuyer: $e");
    }
  }

  Future<void> addCartItem({
    required int? buyerId,
    required String articleCode,
    String? createdAt,
  }) async {
    final db = await _dbHelper.database;

    final id = await db.insert('cart', {
      'article_code': articleCode,
      'buyer_id': buyerId,
      'created_at': createdAt ?? DateTime.now().toIso8601String(),
    });
    fetchCartByBuyer(buyerId!);
    notifyListeners();
  }

  // ya allah error
}
