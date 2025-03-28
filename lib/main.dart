import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

// screens imported
import 'welcome_screen.dart';
import 'dashboard.dart';
import 'home.dart';
import 'admin/adminDashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  User? _user;

  @override
  void initState() {
    super.initState();
    // Listen to authentication state changes
    FirebaseAuth.instance.authStateChanges().listen((user) {
      setState(() {
        _user = user;
      });

      // Update Firestore if the user is logged out
      if (user == null) {
        FirebaseFirestore.instance
            .collection('IDS')
            .doc(user!.uid)
            .update({'isActive': false});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_user != null) {
      // User is logged in, check their status
      return FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('IDS').doc(_user!.uid).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('User  data not found.'));
          }

          // Check the user's status
          String userStatus = snapshot.data!['status'] ?? '';
          if (userStatus == 'person') {
            return DashboardPage(); // Navigate to DashboardPage for regular users
          } else if (userStatus == 'Secretary') {
            return AdminDashboardPage(); // Navigate to AdminDashboardPage for Secretary users
          } else {
            return Center(child: Text('Unexpected user status'));
          }
        },
      );
    } else {
      return WelcomeScreen(); // User is not logged in
    }
  }
}