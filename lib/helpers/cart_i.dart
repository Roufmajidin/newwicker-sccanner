import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:newwicker/helpers/image_h.dart';

class CartImage extends StatelessWidget {
  final String articleCode;
  final double width;
  final double height;

  const CartImage({
    super.key,
    required this.articleCode,
    this.width = 50,
    this.height = 50,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: ImageHelper.loadImage('assets/images/$articleCode.webp'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: width,
            height: height,
            color: Colors.grey.shade200,
          );
        }
        if (snapshot.hasData && snapshot.data != null) {
          return Image.memory(
            snapshot.data!,
            width: width,
            height: height,
            fit: BoxFit.cover,
          );
        }
        return Icon(Icons.broken_image, size: width * 0.8);
      },
    );
  }
}
