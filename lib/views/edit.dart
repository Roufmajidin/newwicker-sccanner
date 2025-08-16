import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:newwicker/helpers/image_from_external.dart';
import 'package:newwicker/views/databases/stactic_db.dart';
import 'package:newwicker/views/sales_view.dart';
import 'package:provider/provider.dart';

import 'package:newwicker/helpers/cart_i.dart'
    show ImageHelper; // asumsi ada ImageHelper.loadWithCache
import 'package:newwicker/models/products.dart';
import 'package:newwicker/provider/cart_provider.dart';
import 'package:newwicker/provider/product_provider.dart';
import 'package:newwicker/views/dashboard_view.dart';
import 'package:newwicker/views/qr_view.dart';

class EditCart extends StatefulWidget {
  final int buyerId;
  const EditCart({super.key, required this.buyerId});

  @override
  State<EditCart> createState() => _EditCartState();
}

class _EditCartState extends State<EditCart> {
  final companyNameController = TextEditingController();
  final countryController = TextEditingController();
  final packingController = TextEditingController();
  final contactController = TextEditingController();
  Map<int, TextEditingController> remarkControllers = {};
  Set<int> expandedItems = {};
  Map<int, bool> checkedItems = {};
  Set<String> checkedArticleCodes = {};

  @override
  void initState() {
    super.initState();
    // hanya panggil fetch, jangan isi controller di sini
    Future.microtask(() {
      Provider.of<CartProvider>(
        context,
        listen: false,
      ).fetchCartByBuyer(widget.buyerId);
    });
  }

  bool _isInitialized = false; // ✅ flag agar tidak setText berulang

  @override
  void dispose() {
    companyNameController.dispose();
    countryController.dispose();
    packingController.dispose();
    contactController.dispose();
    remarkControllers.forEach((key, controller) => controller.dispose());

    super.dispose();
  }

  @override
  @override
  Widget build(BuildContext context) {
    final productProv = Provider.of<ProductProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("Edit Cart"),
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
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          if (cartProvider.state == CartState.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (cartProvider.state == CartState.error) {
            return Center(child: Text("Error: ${cartProvider.errorMessage}"));
          }

          if (cartProvider.buyerWithCarts.isEmpty) {
            return const Center(child: Text("Cart kosong"));
          }

          final buyer =
              cartProvider.buyerWithCarts.first['buyer']
                  as Map<String, dynamic>;

          // ✅ hanya setText sekali saja setelah data pertama kali ada
          if (!_isInitialized) {
            companyNameController.text = buyer['company_name'] ?? "";
            countryController.text = buyer['country'] ?? "";
            packingController.text = buyer['packing'] ?? "";
            contactController.text = buyer['contact_person'] ?? "";
            _isInitialized = true;
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: companyNameController,
                decoration: InputDecoration(
                  isDense: true,

                  labelText: 'Company Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: countryController,
                decoration: InputDecoration(
                  isDense: true,

                  labelText: 'Country',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: packingController,
                decoration: InputDecoration(
                  isDense: true,

                  labelText: 'Packing',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: contactController,
                decoration: InputDecoration(
                  labelText: 'Contact Person',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),

              // dua
              SizedBox(
                height: 400,
                child: ListView.builder(
                  padding: EdgeInsets.only(
                    bottom:
                        kToolbarHeight +
                        16, // agar tidak tertutup bottomNavigationBar
                  ),
                  itemCount: cartProvider.buyerWithCarts.first['carts'].length,
                  itemBuilder: (context, index) {
                    final carts =
                        cartProvider.buyerWithCarts.first['carts']
                            as List<Map<String, dynamic>>;

                    final cart = carts[index];
                    final cartId =
                        cart['id'] ?? cart['article_code']?.hashCode ?? index;
                    final isExpanded = expandedItems.contains(cartId);

                    // Controller
                    final remarkController = remarkControllers.putIfAbsent(
                      cartId,
                      () => TextEditingController(text: cart['remark'] ?? ""),
                    );

                    final articleCode = cart['article_code']?.toString() ?? '';
                    final product = productProv.allProducts.firstWhere(
                      (p) => p.articleCode == articleCode,
                      orElse:
                          () => Product(
                            nr: '',
                            photo: '',
                            articleCode: articleCode,
                            name: 'Produk tidak ditemukan',
                            categories: '',
                            subCategories: '',
                            itemDimension: Dimension(w: 0, d: 0, h: 0),
                            packingDimension: Dimension(w: 0, d: 0, h: 0),
                            sizeOfSet: SizeOfSet(
                              set2: '',
                              set3: '',
                              set4: '',
                              set5: '',
                            ),
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

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 10,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListTile(
                              onTap: () {
                                setState(() {
                                  if (isExpanded) {
                                    expandedItems.remove(cartId);
                                  } else {
                                    expandedItems.add(cartId);
                                  }
                                });
                              },
                              onLongPress: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('ubah Data ? $cartId'),
                                  ),
                                );
                                FocusScope.of(context).unfocus();
                                Navigator.push(
                                  context,

                                  MaterialPageRoute(
                                    builder:
                                        (_) => QRViewExample(
                                          cartId: cartId,
                                        ), // kosong
                                  ),
                                );
                              },
                              leading: SizedBox(
                                width: 100,
                                child: Row(
                                  children: [
                                    Checkbox(
                                      value: checkedItems[cart['id']] ?? false,
                                      onChanged: (value) {
                                        setState(() {
                                          checkedItems[cart['id']] =
                                              value ?? false;

                                          if (value ?? false) {
                                            checkedArticleCodes.add(
                                              cart['article_code'],
                                            );
                                          } else {
                                            checkedArticleCodes.remove(
                                              cart['article_code'],
                                            );
                                          }
                                        });
                                      },
                                    ),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: FutureBuilder<Uint8List?>(
                                        future: ImageHelper.loadWithCache(
                                          articleCode,
                                        ),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return const SizedBox(
                                              width: 40,
                                              height: 40,
                                              child: Center(
                                                child: SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                      ),
                                                ),
                                              ),
                                            );
                                          }
                                          if (snapshot.hasData &&
                                              snapshot.data != null) {
                                            return Image.memory(
                                              snapshot.data!,
                                              width: 40,
                                              height: 40,
                                              fit: BoxFit.cover,
                                            );
                                          } else {
                                            return const Icon(
                                              Icons.broken_image,
                                              size: 40,
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              title: Text(product.name),
                              subtitle: Text(articleCode),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () async {
                                  await cartProvider.removeFromCartBuyer(
                                    cartId,
                                    widget.buyerId,
                                  );
                                  checkedItems.remove(cartId);
                                  carts.removeAt(index);
                                },
                              ),
                            ),
                            if (isExpanded)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: TextField(
                                  controller: remarkControllers[cart['id']],
                                  decoration: InputDecoration(
                                    labelText: 'Add remark',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          FocusScope.of(context).unfocus();
          Navigator.push(
            context,

            MaterialPageRoute(
              builder:
                  (_) => QRViewExample(
                    buyerId: widget.buyerId,
                    status: "addnewitemtobuyercart",
                  ), // kosong
            ),
          );
        },
        child: Icon(Icons.add),
      ),
      bottomNavigationBar:
          checkedItems.values.any((v) => v)
              ? SizedBox(
                height: 100,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: GestureDetector(
                    onTap:
                        isSaveEnabled
                            ? () async {
                              final cartProvider = Provider.of<CartProvider>(
                                context,
                                listen: false,
                              );
                              final carts =
                                  cartProvider.buyerWithCarts.first['carts']
                                      as List<Map<String, dynamic>>;
                              final buyerInfo =
                                  cartProvider.buyerWithCarts.first['buyer'];
                              // final cart = carts[index];

                              final selectedArticleCodes =
                                  carts
                                      .where(
                                        (c) => checkedItems[c['id']] == true,
                                      )
                                      .map<String>(
                                        (c) => c['article_code'].toString(),
                                      )
                                      .toList();

                              // Ambil remark per item
                              final Map<String, String> remarksMap = {};
                              for (var cart in carts) {
                                if (checkedItems[cart['id']] == true) {
                                  remarksMap[cart['article_code']] =
                                      remarkControllers[cart['id']]?.text ?? '';
                                }
                              }
                              print("remark : $remarksMap");
                              print("ceklis : $selectedArticleCodes");
                              await cartProvider.assignTo(
                                selectedArticleCodes,
                                orderNo: buyerInfo['order_no'],
                                buyerId: buyerInfo['id'],
                                companyName: companyNameController.text,
                                country: countryController.text,
                                shipmentDate: '',
                                packing: packingController.text,
                                contactPerson: contactController.text,
                                remarks: remarksMap,
                              );

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Data berhasil diupdate'),
                                ),
                              );
                              FocusScope.of(context).unfocus();

                              Navigator.push(
                                context,

                                MaterialPageRoute(
                                  builder: (_) => SalesView(), // kosong
                                ),
                              );
                            }
                            : null,
                    child: Container(
                      width: double.infinity,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSaveEnabled ? Colors.amber : Colors.grey,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Simpan'),
                    ),
                  ),
                ),
              )
              : const SizedBox(),
    );
  }

  bool get isSaveEnabled {
    // Cek minimal 1 item dicentang
    final hasChecked = checkedItems.values.any((v) => v);

    // Cek semua field wajib terisi
    final fieldsFilled =
        companyNameController.text.isNotEmpty &&
        countryController.text.isNotEmpty &&
        packingController.text.isNotEmpty &&
        contactController.text.isNotEmpty;

    return hasChecked && fieldsFilled;
  }
}
