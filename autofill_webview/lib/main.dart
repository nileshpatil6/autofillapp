import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/mapping_provider.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized(); // Important for plugins like flutter_secure_storage
  runApp(
    ChangeNotifierProvider(
      create: (_) => MappingProvider(),
      child: MaterialApp(
        title: 'Autofill WebView', // Added a title
        theme: ThemeData( // Added a basic theme
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: HomeScreen(),
        debugShowCheckedModeBanner: false, // Commonly disabled for dev
      ),
    ),
  );
}
