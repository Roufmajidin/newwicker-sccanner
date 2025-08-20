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
  bool _isLoading = true; // state untuk loading
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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
    // requestStoragePermission();
    _initAsync();
  }

  void _initAsync() async {
    await requestStoragePermission();

    final productProvider = context.read<ProductProvider>();

    // Load semua produk dari JSON
    if (productProvider.allProducts.isEmpty) {
      await productProvider.loadProducts();
    }

    final carts =
        productProvider.allProducts
            .map((p) => {'article_code': p.articleCode, 'photo': p.photo})
            .toList();

    // Preload gambar di background
    ImageHelper.preloadImages(carts).then((_) {
      if (mounted) {
        setState(() {
          _isLoading = false; // semua gambar sudah di-cache
        });
      }
    });

    if (mounted) {
      setState(() {
        _isLoading = true; // sementara preload berjalan
      });
    }
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
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(onPressed: (){
                       _scaffoldKey.currentState?.openDrawer();
                    }, icon: Icon(Icons.menu)),
                    Row(
                      children: [
                        const SizedBox(width: 12),
                       IconButton(onPressed: (){
                         Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => CartView()),
                            );
                       }, icon: Icon(Icons.shopping_bag_outlined))
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // GREETING
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('NewWicker ,', style: TextStyle(fontSize: 20)),
                    Text(
                      'Welcome to Catalogue',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // CATEGORY ICONS
            SliverToBoxAdapter(
              child: SizedBox(
                height: 60,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
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

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // POPULAR TEXT
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: const Text(
                  'Popular',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // PRODUCT GRID (SliverGrid)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount:
                      (MediaQuery.of(context).size.width / 200).floor(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.8,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final product = products[index];
                  return _buildProductCard(product, context);
                }, childCount: products.length),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
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

  Widget _buildProductCard(Product product, BuildContext context) {
    final articleCode = product.articleCode;
    final cachedImage =
        ImageHelper.cachedImages[articleCode]; // ambil dari cache
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
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child:
                  product.photo.isNotEmpty
                      ? (ImageHelper.cachedImages.containsKey(
                            product.articleCode,
                          )
                          ? Image.memory(
                            ImageHelper.cachedImages[product.articleCode]!,
                            fit: BoxFit.cover,
                            cacheWidth: 200,
                            cacheHeight: 200,
                          )
                          : Container(
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: Text("Sedang membuat cache..."),
                            ),
                          ))
                      : const FlutterLogo(),
            ),
            const SizedBox(height: 8),
            Text(
              product.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('\$${product.valueInUsd.toStringAsFixed(2)}'),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.star, size: 14, color: Colors.amber),
                    const SizedBox(width: 4),
                     Text('${product.articleCode}'),
                  ],
                ),
               IconButton(onPressed: ()async{
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
               }, icon: Icon(Icons.add_shopping_cart_rounded))
              ],
            ),
          ],
        ),
      ),
    );
  }
}
