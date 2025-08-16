import 'package:flutter/material.dart';
import 'package:newwicker/models/buyer_model.dart';
import 'package:newwicker/views/databases/stactic_db.dart';

class BuyerProvider with ChangeNotifier {
  List<Buyer> _buyers = [];
  List<Buyer> get buyers => _buyers;

  Future<void> fetchBuyers() async {
    final db = await DBHelper.instance.database;
    final data = await db.query('buyer', orderBy: 'id DESC');
    _buyers = data.map((e) => Buyer.fromMap(e)).toList();
    notifyListeners();
  }
}
