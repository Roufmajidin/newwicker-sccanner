import 'package:flutter/material.dart';
import 'package:newwicker/provider/product_provider.dart';
import 'package:newwicker/views/dashboard_view.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProductProvider()..loadProducts()),
      ],
      child:  MaterialApp(
         theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.amber,
          primary: Colors.black,
          secondary: Colors.amber,
          background: const Color(0xfff9f9f9),
        ),
         ),
        debugShowCheckedModeBanner: false,
        home: DashboardView(),
      ),
    ),
  );  
}
