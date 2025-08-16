import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:newwicker/helpers/image_from_external.dart';
import 'package:newwicker/views/cart_view.dart';
import 'package:newwicker/views/databases/stactic_db.dart';
import 'package:newwicker/views/details.dart';
import 'package:newwicker/views/qr_view.dart';
import 'package:newwicker/views/sales_view.dart';
import 'package:provider/provider.dart';
import '../provider/product_provider.dart';
import '../models/products.dart';
import 'package:permission_handler/permission_handler.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  int _selectedIndex = 0;

  void _onTabSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _openScanner() {
    Navigator.push(
      context,
      // MaterialPageRoute(
      //   builder: (_) => ScannerView(product: null), // kosong
      // ),
      MaterialPageRoute(
        builder: (_) => QRViewExample(), // kosong
      ),
    );
  }

  Future<bool> requestStoragePermission() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      status = await Permission.storage.request();
    }
    return status.isGranted;
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    requestStoragePermission();
  }

  @override
  Widget build(BuildContext context) {
    final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

    final productProvider = context.watch<ProductProvider>();
    final products =
        productProvider.foundProduct != null
            ? [productProvider.foundProduct!]
            : productProvider.allProducts;

    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              child: Image.asset(
                'assets/images/newwicker.png',
                width: double.infinity,
                height: double.infinity,
                gaplessPlayback: true,
              ),
            ),
            Builder(
              builder:
                  (drawerContext) => InkWell(
                    onTap: () async {
                      FocusScope.of(drawerContext).unfocus();

                      // Tutup Drawer dulu
                      Navigator.pop(drawerContext);

                      // Navigasi ke halaman baru menggunakan context utama Scaffold
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SalesView()),
                      );
                    },
                    child: ListTile(
                      leading: Icon(Icons.book),
                      title: Text("Draft Sales"),
                    ),
                  ),
            ),
          ],
        ),
      ),
      backgroundColor: const Color.fromARGB(255, 230, 230, 230),
      floatingActionButton: FloatingActionButton(
        onPressed: _openScanner,
        backgroundColor: Colors.black,
        child: const Icon(Icons.qr_code_scanner, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        padding: const EdgeInsets.all(2),
        shape: const CircularNotchedRectangle(),
        notchMargin: 6.0,
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onTabSelected,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(
              icon: Icon(Icons.list_alt),
              label: 'Produk',
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () {
                      _scaffoldKey.currentState?.openDrawer();
                    },
                    child: const Icon(Icons.menu),
                  ),
                  Row(
                    children: [
                      // Icon(Icons.search),
                      const SizedBox(width: 12),
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => CartView()),
                          );
                        },
                        child: const Icon(Icons.shopping_cart_outlined),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // GREETING
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('NewWicker ,', style: TextStyle(fontSize: 20)),
                  Text(
                    'Welcome to Catalogue',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 24),
                ],
              ),
            ),

            // CATEGORY ICONS (lazy horizontal)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                height: 60,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 4,
                  itemBuilder: (context, index) {
                    final icons = [
                      Icons.chair_alt,
                      Icons.lightbulb_outline,
                      Icons.bed_outlined,
                      Icons.kitchen,
                    ];
                    return _buildCategoryIcon(icons[index]);
                  },
                ),
              ),
            ),

            const SizedBox(height: 24),

            // POPULAR TEXT
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: const [
                  Text(
                    'Popular',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // PRODUCT GRID - wrapped with Expanded (scrollable lazy!)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return _buildProductCard(product, context);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryIcon(IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: CircleAvatar(
        radius: 28,
        backgroundColor: Colors.white,
        child: Icon(icon),
      ),
    );
  }

  Widget _buildProductCard(Product product, context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailView(product: product),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child:
                  product.photo.isNotEmpty
                      ? FutureBuilder<Uint8List?>(
                        future: ImageHelper.loadWithCache(product.articleCode),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Container(
                              color: Colors.grey.shade200,
                              width: double.infinity,
                              height: double.infinity,
                            );
                          }
                          if (snapshot.hasData && snapshot.data != null) {
                            return Image.memory(
                              snapshot.data!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              gaplessPlayback: true, // biar gak flicker
                            );
                          } else {
                            return const Icon(Icons.broken_image, size: 50);
                          }
                        },
                      )
                      : const FlutterLogo(),
            ),
            const SizedBox(height: 8),
            Text(
              product.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('\$${product.cbm.toStringAsFixed(2)}'),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.star, size: 14, color: Colors.amber),
                    SizedBox(width: 4),
                    Text('4.5'),
                  ],
                ),
                InkWell(
                  onTap: () async {
                    final db = await DBHelper.instance.database;

                    await db.insert('cart', {
                      'article_code': product.articleCode,
                      'created_at': DateTime.now().toIso8601String(),
                      'buyer_id': 1,
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Item berhasil ditambahkan ke keranjang'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Icon(Icons.shopping_cart_outlined),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
