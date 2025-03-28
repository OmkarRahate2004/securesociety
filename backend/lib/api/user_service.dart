import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? getCurrentUser () {
    return _auth.currentUser ;
  }

  // Additional user-related methods can be added here
}