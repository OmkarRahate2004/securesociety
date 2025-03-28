import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// pages
import 'Login.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final List<Map<String, String>> _familyMembers = [];
  String? _apartmentNo;

  @override
  void initState() {
    super.initState();
    _getApartmentNo();
    _loadFamilyMembers(); // Load existing family members on init
  }

  Future<void> _getApartmentNo() async {
    User? user = FirebaseAuth.instance.currentUser ;

    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('IDS').doc(user.uid).get();
      if (userDoc.exists) {
        setState(() {
          _apartmentNo = userDoc['apartmentNo']; // Assuming 'apartmentNo' is the field name
        });
      }
    }
  }

  Future<void> _loadFamilyMembers() async {
    String userId = FirebaseAuth.instance.currentUser !.uid;

    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('fm').doc(userId).collection('members').get();
    for (var doc in snapshot.docs) {
      _familyMembers.add({
        'id': doc.id, // Store the document ID for deletion
        'name': doc['name'],
        'phone': doc['phone'] ?? '',
      });
    }
    setState(() {}); // Refresh the UI
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _logout,
            child: Text('Logout'),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _sendPasswordResetEmail,
            child: Text('Change Password'),
          ),
          SizedBox(height: 20),
          Text(
            'Add Family Member',
            style: TextStyle(fontSize: 20),
          ),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(labelText: 'Name'),
          ),
          TextField(
            controller: _phoneController,
            decoration: InputDecoration(labelText: 'Phone Number (optional)'),
            keyboardType: TextInputType.phone,
          ),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: _addFamilyMember,
            child: Text('Add Member'),
          ),
          SizedBox(height: 20),
          Text(
            'Family Members:',
            style: TextStyle(fontSize: 20),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _familyMembers.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_familyMembers[index]['name']!),
                  subtitle: Text(_familyMembers[index]['phone'] ?? 'No phone number'),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () => _confirmDeleteFamilyMember(index),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
  }

  Future<void> _sendPasswordResetEmail() async {
    User? user = FirebaseAuth.instance.currentUser ;
    if (user != null) {
      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email!);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Password reset email sent!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No user is logged in.')),
      );
    }
  }

  Future<void> _addFamilyMember() async {
    if (_nameController.text.isNotEmpty) {
      String userId = FirebaseAuth.instance.currentUser !.uid;

      // Create a family member object
      Map<String, String> familyMember = {
        'name': _nameController.text,
        'phone': _phoneController.text,
        'apartmentNo': _apartmentNo ?? '', // Include apartment number
      };

      // Save to Firestore under user's UID
      DocumentReference memberRef = await FirebaseFirestore.instance.collection('fm').doc(userId).collection('members').add(familyMember);

      setState(() {
        _familyMembers.add({
          'id': memberRef.id, // Store the document ID for future reference
          'name': _nameController.text,
          'phone': _phoneController.text,
        });
        _nameController.clear();
        _phoneController.clear();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a name.')),
      );
    }
  }

  Future<void> _confirmDeleteFamilyMember(int index) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete this family member?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await _removeFamilyMember(index);
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _removeFamilyMember(int index) async {
    String userId = FirebaseAuth.instance.currentUser !.uid;
    String memberId = _familyMembers[index]['id']!;

    // Remove from Firestore
    await FirebaseFirestore.instance.collection('fm').doc(userId).collection('members').doc(memberId).delete();

    setState(() {
      _familyMembers.removeAt(index);
    });
  }
}