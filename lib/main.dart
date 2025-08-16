import 'package:flutter/material.dart';
import 'package:newwicker/provider/buyer_provider.dart';
import 'package:newwicker/provider/cart_provider.dart';
import 'package:newwicker/provider/product_provider.dart';
import 'package:newwicker/views/dashboard_view.dart';
import 'package:provider/provider.dart';

final RouteObserver<ModalRoute> routeObserver = RouteObserver<ModalRoute>();
Future<void> main() async {
  
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(
    
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ProductProvider()..loadProducts(),
        ),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => BuyerProvider()..fetchBuyers()),
      ],
      child: MaterialApp(
        navigatorObservers: [routeObserver],

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
