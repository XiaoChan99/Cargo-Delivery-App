import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  static bool _initialized = false;
  
  static Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "YOUR_API_KEY",
          appId: "1:504667552703:android:18afcba538a7648c91bf0a",
          messagingSenderId: "YOUR_SENDER_ID",
          projectId: "cargo-delivery-app-b0f42",
          // Add these for web if needed:
          // authDomain: "your-project.firebaseapp.com",
          // storageBucket: "your-project.appspot.com",
        ),
      );
      _initialized = true;
      print("Firebase initialized successfully");
    } catch (e) {
      print("Firebase initialization error: $e");
      throw Exception("Failed to initialize Firebase: $e");
    }
  }
  
  static FirebaseFirestore get firestore => FirebaseFirestore.instance;
  static FirebaseAuth get auth => FirebaseAuth.instance;
}