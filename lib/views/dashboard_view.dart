import 'package:flutter/material.dart';
import 'package:newwicker/views/details.dart';
import 'package:newwicker/views/scanner.dart';
import 'package:provider/provider.dart';
import '../provider/product_provider.dart';
import '../models/products.dart';

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
      MaterialPageRoute(
        builder: (_) => ProductDetailView(product: null), // kosong
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final products =
        productProvider.foundProduct != null
            ? [productProvider.foundProduct!]
            : productProvider.allProducts;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 230, 230, 230),
      floatingActionButton: FloatingActionButton(
        onPressed: _openScanner,
        backgroundColor: Colors.black,
        child: const Icon(Icons.qr_code_scanner, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        padding: EdgeInsets.all(2),
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
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// HEADER
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Icon(Icons.menu),
                    Row(
                      children: [
                        Icon(Icons.search),
                        SizedBox(width: 12),
                        Icon(Icons.shopping_cart_outlined),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              /// GREETING
              ///
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('NewWicker ,', style: TextStyle(fontSize: 20)),
                    const Text(
                      'Wellcome to Catalogue',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),

              /// CATEGORIES
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),

                child: SizedBox(
                  height: 60,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildCategoryIcon(Icons.chair_alt),
                      _buildCategoryIcon(Icons.lightbulb_outline),
                      _buildCategoryIcon(Icons.bed_outlined),
                      _buildCategoryIcon(Icons.kitchen),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              /// POPULAR SECTION
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),

                child: Column(
                  children: [
                    const Text(
                      'Popular',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),

                child: GridView.builder(
                  // shrinkWra  p: true,
                  padding: const EdgeInsets.all(12),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.8,
                      ),
                  itemCount: products.length,
                  physics: NeverScrollableScrollPhysics(), // biar scroll luar yang menangani

                  itemBuilder: (context, index) {
                    final product = products[index];
                    return _buildProductCard(product, context);
                  },
                ),
              ),
            ],
          ),
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
          color: Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child:
                  product.photo.isNotEmpty
                      ? Image.asset('assets/images/${product.photo}')
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
              children: const [
                Row(
                  children: [
                    Icon(Icons.star, size: 14, color: Colors.amber),
                    SizedBox(width: 4),
                    Text('4.5'),
                  ],
                ),
                Icon(Icons.add_box_outlined),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
