import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'requestPage.dart';
import 'settingsPage.dart';

class DashboardPage extends StatefulWidget {
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;

  // List of pages for the bottom navigation
  final List<Widget> _pages = [
    HomeScreen(),
    RequestPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
      ),
      body: _pages[_selectedIndex], // Display the selected page
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.request_page),
            label: 'Request',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber,
        unselectedItemColor: Colors.black,
        onTap: _onItemTapped,
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index; // Update the selected index
    });
  }
}

// HomeScreen widget to display user information and events
class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedFilter = 'All'; // Default filter

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Events'),
        backgroundColor: Colors.amberAccent,
      ),
      body: Column(
        children: [
          _buildFilterDropdown(),
          Expanded(child: _buildEventList()),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: DropdownButton<String>(
        value: _selectedFilter,
        items: <String>['All', 'Upcoming', 'Ongoing', 'Completed']
            .map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: (String? newValue) {
          setState(() {
            _selectedFilter = newValue!;
          });
        },
      ),
    );
  }

  Widget _buildEventList() {
    return FutureBuilder<QuerySnapshot>(
      future: _fetchEvents(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No events available'));
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            return _buildEventCard(doc);
          },
        );
      },
    );
  }

  Widget _buildEventCard(QueryDocumentSnapshot doc) {
    DateTime startDate = (doc['startDate'] as Timestamp).toDate();
    DateTime endDate = (doc['endDate'] as Timestamp).toDate();
    Color backgroundColor;

    // Determine the background color based on the event status
    if (endDate.isBefore(DateTime.now())) {
      backgroundColor = Colors.red; // Completed
    } else if (startDate.isBefore(DateTime.now()) && endDate.isAfter(DateTime.now())) {
      backgroundColor = Colors.blue; // Ongoing
    } else {
      backgroundColor = Colors.green; // Upcoming
    }

    // Check if the event is within 30 days from the system date
    if (endDate.difference(DateTime.now()).inDays >= 30) {
      return Container(); // Don't show the event
    }

    return Card(
      color: backgroundColor,
      margin: EdgeInsets.all(10),
      child: ListTile(
 title: Text(doc['title'], style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${doc['body']}\nLocation: ${doc['location']}'),
        onTap: () => _showEventDetails(doc),
      ),
    );
  }

  Future<QuerySnapshot> _fetchEvents() async {
    CollectionReference collection = FirebaseFirestore.instance.collection('ep');
    Query query = collection;

    // Filter by status based on the selected filter
    if (_selectedFilter == 'Upcoming') {
      query = query.where('endDate', isGreaterThan: DateTime.now());
    } else if (_selectedFilter == 'Ongoing') {
      query = query.where('startDate', isLessThanOrEqualTo: DateTime.now())
                   .where('endDate', isGreaterThan: DateTime.now());
    } else if (_selectedFilter == 'Completed') {
      query = query.where('endDate', isLessThan: DateTime.now());
    }

    return await query.get();
  }

  void _showEventDetails(QueryDocumentSnapshot doc) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(doc['title']),
          content: Text('${doc['body']}\nLocation: ${doc['location']}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }
}