import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:horizontal_data_table/horizontal_data_table.dart';
import 'package:newwicker/helpers/image_from_external.dart';
import 'package:newwicker/provider/cart_provider.dart';
import 'package:newwicker/views/dashboard_view.dart';
import 'package:newwicker/views/databases/stactic_db.dart';
import 'package:newwicker/views/edit.dart';
import 'package:provider/provider.dart';

class SalesView extends StatefulWidget {
  const SalesView({super.key});

  @override
  State<SalesView> createState() => _SalesViewState();
}

class _SalesViewState extends State<SalesView> {
  Future<List<Map<String, dynamic>>> _getBuyers() async {
    final db = await DBHelper.instance.database;
    final buyers = await db.query('buyer', orderBy: 'id ASC');
    return buyers;
  }

  Future<List<Map<String, dynamic>>> _getCartsForBuyer(int buyerId) async {
    final db = await DBHelper.instance.database;
    final carts = await db.query(
      'cart',
      where: 'buyer_id = ? AND status IS NOT NULL',
      whereArgs: [buyerId],
      orderBy: 'id ASC',
    );
    return carts;
  }

  Future<void> _printAllDataAsJson() async {
    final buyers = await _getBuyers();
    final result = [];

    for (var buyer in buyers) {
      final carts = await _getCartsForBuyer(buyer['id']);
      result.add({'buyer': buyer, 'carts': carts});
    }
    print(result);
  }

  Future<void> _deleteAllData() async {
    final db = await DBHelper.instance.database;
    final batch = db.batch();
    batch.delete('cart');
    batch.delete('buyer');
    await batch.commit(noResult: true);

    print("Semua data buyer dan cart berhasil dihapus!");
  }

  // Print JSON ke console
  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);

    final screenWidth = MediaQuery.of(context).size.width;
    final leftWidth = 100.0; // left column width
    final rightWidth = screenWidth - leftWidth; // sisa untuk kolom kanan

    return Scaffold(
      appBar: AppBar(
        title: const Text("Draft Sales"),

        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () {
                FocusScope.of(context).unfocus();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => DashboardView()),
                  (route) => false,
                );
              },

              child: Icon(Icons.home_filled),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _getBuyers(),
        builder: (context, buyerSnapshot) {
          if (buyerSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final buyers = buyerSnapshot.data ?? [];
          if (buyers.isEmpty) return const Center(child: Text("No buyers"));

          return ListView.builder(
             itemCount: buyers.length,
  itemBuilder: (context, index) {
    final buyer = buyers[index];
    return FutureBuilder<List<Map<String, dynamic>>>(
              future: _getCartsForBuyer(buyer['id']),
              builder: (context, cartSnapshot) {
                final carts = cartSnapshot.data ?? [];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Label
                        Padding(
                          padding: const EdgeInsets.only(left: 16.0),

                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text("Company"),
                              Text("Country"),
                              Text("Packing"),
                              Text("Contact person"),
                            ],
                          ),
                        ),

                        SizedBox(width: 16),

                        // Nilai buyer → pakai Expanded supaya ellipsis berfungsi
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ": ${buyer['company_name'] ?? '-'}",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                ": ${buyer['country'] ?? '-'}",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                ": ${buyer['packing'] ?? '-'}",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                ": ${buyer['contact_person'] ?? '-'}",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),

                        SizedBox(width: 16),

                        // Tombol delete & edit
                        Padding(
                          padding: const EdgeInsets.only(right: 16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: InkWell(
                                  onTap: () async {
                                    await cartProvider.deletebuyerwt(
                                      buyer['id'],
                                    );
                                    setState(() {});
                                  },
                                  child: Icon(Icons.delete),
                                ),
                              ),
                              SizedBox(height: 8),
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: InkWell(
                                  onTap: () {
                                    FocusScope.of(context).unfocus();
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) =>
                                                EditCart(buyerId: buyer['id']),
                                      ),
                                    );
                                  },
                                  child: Icon(Icons.edit),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // ===== Horizontal Table per Buyer =====
                    SizedBox(
                      height:
                          carts.isEmpty
                              ? 50.0
                              : (carts.length * 80.0).clamp(120.0, 400.0),
                      child:
                          carts.isEmpty
                              ? const Center(child: Text("No orders"))
                              : Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: HorizontalDataTable(
                                  leftHandSideColumnWidth: leftWidth,
                                  rightHandSideColumnWidth: 570,

                                  isFixedHeader: true,
                                  headerWidgets: _buildHeader(),
                                  leftSideItemBuilder:
                                      (context, index) =>
                                          _buildLeftColumn(carts[index]),
                                  rightSideItemBuilder:
                                      (context, index) =>
                                          _buildRightColumn(carts[index]),
                                  itemCount: carts.length,
                                  rowSeparatorWidget: const Divider(
                                    color: Colors.black38,
                                    height: 0.7,
                                    thickness: 0.0,
                                  ),
                                ),
                              ),
                    ),
                    const SizedBox(height: 24),
                  ],
                );
              },
              );}
          );
        },
      ),
    );
  }

  // ===== Horizontal Table =====
  List<Widget> _buildHeader() {
    return [
      _headerCell("Image", 100),
      _headerCell("Article Nr", 100),
      _headerCell("Remark", 100),
      _headerCell("Date", 120),
    ];
  }

  // ===== Right Column per cart =====
  Widget _buildRightColumn(Map<String, dynamic> cart) {
    return Row(
      children: [
        _cell(cart['article_code'] ?? '-', 100),
        _cell(cart['remark'] ?? '-', 100),
        _cell(cart['created_at'] ?? '-', 120),
      ],
    );
  }

  Widget _headerCell(String label, double width) {
    return Container(
      width: width,
      height: 40,
      color: Colors.blueAccent,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildLeftColumn(Map<String, dynamic> cart) {
    final articleCode = cart['article_code']?.toString() ?? '';

    return _cellWidget(
      ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 80,
          height: 80,
          child: FutureBuilder<Uint8List?>(
            future: ImageHelper.loadWithCache(articleCode),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Container(height: 220, color: Colors.grey.shade200);
              }
              if (snapshot.hasData && snapshot.data != null) {
                return Image.memory(
                  snapshot.data!,
                  width: double.infinity,
                  height: double.infinity,
                  gaplessPlayback: true,
                );
              } else {
                return const Icon(Icons.image_not_supported, size: 50);
              }
            },
          ),
        ),
      ),
      120,
    );
  }

  // Ubah _cell supaya bisa menerima widget
  Widget _cellWidget(Widget child, double width) {
    return Container(
      width: width,
      height: 80,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: child,
    );
  }

  Widget _cell(String text, double width) {
    return Container(
      width: width,
      height: 80,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Text(text),
    );
  }
}
