import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:newwicker/provider/product_provider.dart';
import 'package:newwicker/views/details.dart';
import 'package:provider/provider.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'package:newwicker/models/products.dart';

class QRViewExample extends StatefulWidget {
  final int? cartId;
  final int? buyerId;
  final String? status;

  const QRViewExample({super.key, this.cartId, this.buyerId, this.status});

  @override
  State<StatefulWidget> createState() => _QRViewExampleState();
}

class _QRViewExampleState extends State<QRViewExample> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  final FocusNode _articleFocusNode = FocusNode();

  String? scannedData;
  bool _isScanning = false;
  Timer? _timeoutTimer;
  bool _isTyping = false; // untuk atur flex kamera
  @override
  void initState() {
    super.initState();
    _startTimeout();
  }

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller?.pauseCamera();
    } else if (Platform.isIOS) {
      controller?.resumeCamera();
    }
  }

  void _startTimeout() {
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(const Duration(seconds: 20), () {
      if (mounted && !_isScanning) {
        controller?.pauseCamera();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Waktu habis, silakan refresh scanner')),
        );
      }
    });
  }

  void _refreshCamera() {
    setState(() {
      scannedData = null;
      _isScanning = false; // reset supaya bisa scan lagi
    });
    _startTimeout();
    controller?.resumeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Expanded(
            flex: _isTyping ? 1 : 2,
            child: Stack(
              children: [
                QRView(
                  key: qrKey,
                  onQRViewCreated: _onQRViewCreated,
                  overlay: QrScannerOverlayShape(
                    borderColor: Colors.red,
                    borderRadius: 10,
                    borderLength: 30,
                    borderWidth: 10,
                    cutOutSize: 300,
                  ),
                ),
                Positioned(
                  top: 20,
                  right: 20,
                  child: ElevatedButton(
                    onPressed: _refreshCamera,
                    child: const Icon(Icons.refresh),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: _isTyping ? 2 : 1,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                // mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 12),
                  TypeAheadField<Product>(
                    suggestionsCallback: (pattern) {
                      final provider = Provider.of<ProductProvider>(
                        context,
                        listen: false,
                      );
                      return provider.allProducts
                          .where(
                            (product) =>
                                product.articleCode.toLowerCase().contains(
                                  pattern.toLowerCase(),
                                ) ||
                                product.name.toLowerCase().contains(
                                  pattern.toLowerCase(),
                                ),
                          )
                          .take(5)
                          .toList();
                    },
                    builder: (context, textController, _articleFocusNode) {
                      return SizedBox(
                        height: 40,
                        child: TextField(
                          controller: textController,
                          focusNode: _articleFocusNode,
                          onTap: () => setState(() => _isTyping = true),
                          onEditingComplete: () {
                            setState(() => _isTyping = false);
                          },
                          onTapUpOutside: (event) {
                            setState(() => _isTyping = false);
                          },
                          onAppPrivateCommand: (action, data) {
                            setState(() => _isTyping = false);
                          },

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
                        title: Text(suggestion.articleCode),
                        subtitle: Text(suggestion.name),
                      );
                    },
                    onSelected: (Product suggestion) async {
                      final provider = Provider.of<ProductProvider>(
                        context,
                        listen: false,
                      );

                      provider.foundProduct = suggestion;
                      setState(() {
                        FocusScope.of(context).unfocus();
                        _isTyping = false;
                        _closeKeyboard();
                      });

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => ProductDetailView(
                                product: suggestion,
                                id: widget.cartId,
                                buyerId: widget.buyerId,
                                status: widget.status,
                              ),
                        ),
                      ).then((_) {
                        _closeKeyboard();

                        setState(() {
                          _isTyping = false;
                        });
                        _refreshCamera();
                      });
                    },
                    emptyBuilder:
                        (context) => const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('Tidak ada produk ditemukan.'),
                        ),
                    loadingBuilder:
                        (context) => const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                  ),

                  Text(
                    scannedData != null
                        ? 'Hasil Scan: $scannedData'
                        : 'Scan kode QR',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) async {
      if (_isScanning) return;
      _isScanning = true;
      _timeoutTimer?.cancel();

      final code = scanData.code;
      // SnackBar(content: Text(code.toString()));
      print('code $code');
      setState(() => scannedData = code);

      await controller.pauseCamera();

      final provider = context.read<ProductProvider>();
      final product = provider.findProductByNr(code!.trim().toUpperCase());
      // print('halow : ${product.name}');
      if (!mounted) return;

      if (product != null ) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => ProductDetailView(
                  product: product,
                  buyerId: widget.buyerId,
                  status: widget.status,
                ),
          ),
        ).then((_) {
          _isScanning = false; // reset di sini
          _refreshCamera();
        });
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Produk tidak ditemukan')));
        _refreshCamera();
      }
    });
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    controller?.dispose();
    FocusScope.of(context).unfocus();
    _articleFocusNode.dispose();

    super.dispose();
  }

  void _closeKeyboard() {
    _articleFocusNode.unfocus();
    FocusScope.of(context).unfocus();
    setState(() {
      _isTyping = false;
    });
  }
}
