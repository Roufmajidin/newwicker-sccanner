import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:newwicker/helpers/image_from_external.dart';
import 'package:newwicker/models/products.dart';
import 'package:newwicker/provider/cart_provider.dart';
import 'package:newwicker/provider/product_provider.dart';
import 'package:provider/provider.dart';
import 'dart:math';

class CartView extends StatefulWidget {
  const CartView({super.key});

  @override
  State<CartView> createState() => _CartViewState();
}

class _CartViewState extends State<CartView> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<CartProvider>(context, listen: false).fetchCart();
    });
  }

  Set<int> expandedItems = {};
  Map<int, bool> checkedItems = {};
  Set<String> checkedArticleCodes = {};
  final companyNameController = TextEditingController();
  final countryController = TextEditingController();
  final packingController = TextEditingController();
  final contactController = TextEditingController();
  Map<int, TextEditingController> remarkControllers = {};
  bool isEditing = false;

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
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final productProv = Provider.of<ProductProvider>(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: Text("Cart"), actions: []),
      body: SingleChildScrollView(
        child: Column(
          children: [
            cartProvider.cartItems.isEmpty
                ? const Center(child: Text('Cart kosong'))
                : SizedBox(
                  height: MediaQuery.of(context).size.height * 0.50,
                  child: ListView.builder(
                    shrinkWrap: true,
                    // padding: EdgeInsets.symmetric(vertical: 50),
                    itemCount: cartProvider.cartItems.length,
                    itemBuilder: (context, index) {
                      final cart = cartProvider.cartItems[index];
                      final isExpanded = expandedItems.contains(cart['id']);
                      final cartId = cart['id'];

                      // Buat controller untuk item ini jika belum ada
                      if (!remarkControllers.containsKey(cart['id'])) {
                        remarkControllers[cart['id']] = TextEditingController(
                          text: cart['remark'] ?? '',
                        );
                      }

                      final remarkController = remarkControllers[cartId]!;
                      final product = productProv.allProducts.firstWhere(
                        (p) => p.articleCode == cart['article_code'],
                        orElse:
                            () => Product(
                              nr: '',
                              photo: '',
                              articleCode: cart['article_code'],
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

                          child: InkWell(
                            onTap: () {
                              setState(() {
                                if (isExpanded) {
                                  expandedItems.remove(cart['id']);
                                } else {
                                  expandedItems.add(cart['id']);
                                }
                              });
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ListTile(
                                  leading: SizedBox(
                                    width: 100,
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Checkbox(
                                          value:
                                              checkedItems[cart['id']] ?? false,
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
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: FutureBuilder<Uint8List?>(
                                            future: ImageHelper.loadWithCache(
                                               cart['article_code'],
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
                                  subtitle: Text(' ${cart['article_code']}'),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () {
                                      cartProvider.removeFromCart(cart['id']);
                                      checkedItems.remove(cart['id']);
                                    },
                                  ),
                                ),
                                if (isExpanded)
                                  AnimatedSize(
                                    duration: const Duration(milliseconds: 200),

                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 20,
                                      ),
                                      child: SizedBox(
                                        height: 40,
                                        child: TextField(
                                          controller:
                                              remarkControllers[cart['id']],
                                          decoration: InputDecoration(
                                            labelText: 'add remark',
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          onSubmitted: (value) {
                                            isEditing = false;
                                            setState(() {
                                              if (isExpanded) {
                                                expandedItems.remove(
                                                  cart['id'],
                                                );
                                              } else {
                                                expandedItems.add(cart['id']);
                                              }
                                            });
                                            print(
                                              'Remark untuk ${cart['article_code']}: $value',
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
          ],
        ),
      ),
      bottomNavigationBar:
          checkedItems.values.any((v) => v)
              ? SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Container(
                  height: 320,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Company Name
                        TextField(
                          controller: companyNameController,

                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 0,
                            ),
                            labelText: "Company Name",
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Country
                        TextField(
                          controller: countryController,

                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 0,
                            ),
                            labelText: "Country",
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.2),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Packing
                        TextField(
                          controller: packingController,

                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 0,
                            ),
                            labelText: "Packing",
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Packing
                        TextField(
                          controller: contactController,

                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 0,
                            ),
                            labelText: "Contact",
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        GestureDetector(
                          onTap:
                              isSaveEnabled
                                  ? () async {
                                    final random = Random();

                                    // Order No random (misal 5 digit)
                                    final int orderNo =
                                        10000 + random.nextInt(90000);
                                    final int buyerId =
                                        10000 + random.nextInt(90000);

                                    // Buyer ID random (misal UUID-like atau angka acak)

                                    final selectedArticleCodes =
                                        cartProvider.cartItems
                                            .where(
                                              (item) =>
                                                  checkedItems[item['id']] ==
                                                  true,
                                            )
                                            .map<String>(
                                              (item) =>
                                                  item['article_code']
                                                      as String,
                                            )
                                            .toList();
                                    // Ambil remark per item
                                    final Map<String, String> remarksMap = {};
                                    for (var cart in cartProvider.cartItems) {
                                      if (checkedItems[cart['id']] == true) {
                                        remarksMap[cart['article_code']] =
                                            remarkControllers[cart['id']]
                                                ?.text ??
                                            '';
                                      }
                                    }
                                    await cartProvider.assign(
                                      selectedArticleCodes,
                                      orderNo: orderNo,
                                      buyerId: buyerId,
                                      companyName: companyNameController.text,
                                      country: countryController.text,
                                      shipmentDate: "",
                                      packing: packingController.text,
                                      contactPerson: contactController.text,
                                      remarks: remarksMap,
                                    );

                                    print(
                                      "✅ Data berhasil disimpan ke DB lokal",
                                    );
                                    print("Order No: $orderNo");
                                    print("Buyer ID: $buyerId");
                                  }
                                  : null, // disabled kalau validasi false,

                          child: Container(
                            width: MediaQuery.of(context).size.width,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color:
                                  isSaveEnabled ? Colors.amber : Colors.white,
                            ),
                            child: const Center(child: Text("Simpan")),
                          ),
                        ),
                      ],
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
