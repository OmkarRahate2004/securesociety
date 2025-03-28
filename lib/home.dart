import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'Login.dart';

class HomeScreen extends StatelessWidget {
  Future<void> logoutUser (BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Options Screen')),
      body: Center(
        child: TextButton(
          onPressed: () => logoutUser (context),
          child: Text("LOGOUT →"),
        ),
      ),
    );
  }
}