import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:newwicker/provider/product_provider.dart';
import 'package:newwicker/views/scanner.dart';
import 'package:provider/provider.dart';
import '../models/products.dart';

class ProductDetailView extends StatefulWidget {
  final Product? product; // null artinya mode scan

  const ProductDetailView({super.key, this.product});

  @override
  State<ProductDetailView> createState() => _ProductDetailViewState();
}

class _ProductDetailViewState extends State<ProductDetailView>
    with WidgetsBindingObserver {
  late final MobileScannerController _controller;
  String? _scanMessage;
  bool _cameraActive = true;
  bool _isInitializing = false;
  Key _scannerKey = UniqueKey();
  final TextEditingController _articleNrController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _controller = MobileScannerController(
      autoStart: widget.product == null, // autoStart hanya di mode scan
      formats: [BarcodeFormat.qrCode],
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      detectionTimeoutMs: 500,
    );
  }

  late ProductProvider _productProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Simpan reference saat context masih aman
    _productProvider = context.read<ProductProvider>();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();

    // Gunakan provider yang sudah disimpan sebelumnya
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _productProvider.clearScan();
    });

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_cameraActive) {
      _controller.start();
      _cameraActive = true;
    } else if ((state == AppLifecycleState.inactive ||
            state == AppLifecycleState.paused) &&
        _cameraActive) {
      _controller.stop();
      _cameraActive = false;
    }
  }

  void _onBarcodeDetect(BarcodeCapture capture) {
    final String? code = capture.barcodes.first.rawValue;
    if (code != null) {
      final provider = context.read<ProductProvider>();
      provider.findProductByNr(code);
      _controller.stop();
      _cameraActive = false;

      // Navigasi ke halaman detail dengan produk ditemukan
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetailView(product: provider.foundProduct),
        ),
      );
    }
  }

  Future<void> _resetScanner() async {
    context.read<ProductProvider>().clearScan();
    setState(() {
      _scanMessage = null;
      _scannerKey = UniqueKey(); // reset kamera widget
    });
    await Future.delayed(const Duration(milliseconds: 300));
    await _startCamera();
  }

  Future<void> _startCamera() async {
    if (_cameraActive || _isInitializing) return;
    _isInitializing = true;

    try {
      await _controller.start();
      _cameraActive = true;
    } catch (e) {
      debugPrint('Start camera error: $e');
    } finally {
      _isInitializing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return Scaffold(
      backgroundColor: const Color(0xfff9f9f9),

      appBar: AppBar(
        leading: const BackButton(),
        title: Text(product != null ? 'Detail Produk' : 'Scan QR'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body:
          product == null
              ? Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Container(
                      width: 300,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TypeAheadField<Product>(
                            suggestionsCallback: (pattern) {
                              final provider = Provider.of<ProductProvider>(
                                context,
                                listen: false,
                              );
                              return provider.allProducts
                                  .where(
                                    (product) =>
                                        product.nr.toLowerCase().contains(
                                          pattern.toLowerCase(),
                                        ) ||
                                        product.name.toLowerCase().contains(
                                          pattern.toLowerCase(),
                                        ),
                                  )
                                  .take(5)
                                  .toList();
                            },
                            builder: (context, controller, focusNode) {
                              return SizedBox(
                                height: 40,
                                child: TextField(
                                  controller: controller,
                                  focusNode: focusNode,
                                  decoration: InputDecoration(
                                    labelText: 'Article NR',
                                    prefixIcon: const Icon(Icons.search),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              );
                            },
                            itemBuilder: (context, Product suggestion) {
                              return ListTile(
                                title: Text(suggestion.nr),
                                subtitle: Text(suggestion.name),
                              );
                            },
                            onSelected: (Product suggestion) async {
                              final provider = Provider.of<ProductProvider>(
                                context,
                                listen: false,
                              );
                              provider.foundProduct = suggestion;
                              _articleNrController.text = suggestion.nr;
                              // _showProductBottomSheet(context, suggestion);
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => ProductDetailView(
                                        product: suggestion,
                                      ),
                                )
                              );
                            },
                            emptyBuilder:
                                (context) => const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text('Tidak ada produk ditemukan.'),
                                ),
                            loadingBuilder:
                                (context) => const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            "Scan QR Code",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            "Letak QR Code dalam kotak",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Stack(
                              alignment: Alignment.center,

                              children: [
                                SizedBox(
                                  width: 280,
                                  height: 280,
                                  child: Image.asset(
                                    fit: BoxFit.cover,
                                    'assets/images/qr.png',
                                    // width: 220,
                                    // height: 220,
                                  ),
                                ),
                                SizedBox(
                                  width: 200,
                                  height: 200,
                                  child: MobileScanner(
                                    key: _scannerKey,
                                    controller: _controller,
                                    onDetect: _onBarcodeDetect,
                                    errorBuilder: (context, error) {
                                      return Center(
                                        child: Text(
                                          'Error kamera: ${error.errorCode.name}',
                                          style: const TextStyle(
                                            color: Colors.red,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Image.asset(
                        'assets/images/${product.photo}',
                        height: 220,
                        errorBuilder:
                            (_, __, ___) =>
                                const Icon(Icons.image_not_supported),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.categories,
                      style: const TextStyle(color: Colors.orangeAccent),
                    ),
                    Text(
                      'Rp ${product.remarks.rangka.harga + product.remarks.anyam.harga}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    _buildDetailRow('Composition', product.composition),
                    _buildDetailRow('Finishing', product.finishing),
                    _buildDetailRow('CBM', product.cbm.toString()),
                    const SizedBox(height: 12),
                    const Text(
                      'Item Dimensions',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    _buildDetailRow(
                      'W x D x H',
                      '${product.itemDimension.w} x ${product.itemDimension.d} x ${product.itemDimension.h} cm',
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Packing Dimensions',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    _buildDetailRow(
                      'W x D x H',
                      '${product.packingDimension.w} x ${product.packingDimension.d} x ${product.packingDimension.h} cm',
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Set Sizes',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if (product.sizeOfSet.set2.isNotEmpty)
                          _buildTag(product.sizeOfSet.set2),
                        if (product.sizeOfSet.set3.isNotEmpty)
                          _buildTag(product.sizeOfSet.set3),
                        if (product.sizeOfSet.set4.isNotEmpty)
                          _buildTag(product.sizeOfSet.set4),
                        if (product.sizeOfSet.set5.isNotEmpty)
                          _buildTag(product.sizeOfSet.set5),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Pricing Details',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    _buildDetailRow(
                      'Rangka',
                      'Rp ${product.remarks.rangka.harga} (${product.remarks.rangka.sub})',
                    ),
                    _buildDetailRow(
                      'Anyam',
                      'Rp ${product.remarks.anyam.harga} (${product.remarks.anyam.sub})',
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                      ),
                      onPressed: () {},
                      child: const Text("Buy Now"),
                    ),
                  ],
                ),
              ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => ScannerView()));
        },
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text("Scan Ulang"),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Table(
      border: TableBorder.all(
        color: Colors.grey.withOpacity(0.6),
      ), // opsional, untuk garis tabel
      columnWidths: const {
        0: FlexColumnWidth(1), // Label
        1: FlexColumnWidth(1), // Value
      },
      children: [
        TableRow(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.blue.shade100,
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.blue.shade50,
              child: Text(value),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(text),
    );
  }

  void _showProductBottomSheet(BuildContext context, Product product) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              product.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // tutup bottom sheet
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProductDetailView(product: product),
                  ),
                );
              },
              child: const Text("Lihat Detail"),
            ),
          ],
        );
      },
    );
  }
}
