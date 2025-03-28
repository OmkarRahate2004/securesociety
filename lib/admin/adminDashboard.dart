import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'adminMessagesPage.dart';
import 'adminSettingsPage.dart';

class AdminDashboardPage extends StatefulWidget {
  @override
  _AdminDashboardPageState createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  // Separate state for each section
  String _allSelectedType = 'All';
  DateTime? _allStartDate;
  DateTime? _allEndDate;

  String _pendingSelectedType = 'All';
  DateTime? _pendingStartDate;
  DateTime? _pendingEndDate;

  String _completedSelectedType = 'All';
  DateTime? _completedStartDate;
  DateTime? _completedEndDate;

  String _discardedSelectedType = 'All';
  DateTime? _discardedStartDate;
  DateTime? _discardedEndDate;

  List<String> _visibleSections = ['All', 'Pending', 'Completed', 'Discarded'];
  int _currentIndex = 0; // For bottom navigation

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard'),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert),
            onSelected: (String value) {
              _toggleSectionVisibility(value);
            },
            itemBuilder: (BuildContext context) {
              return {'All', 'Pending', 'Completed', 'Discarded'}.map((String choice) {
                return PopupMenuItem<String>(
                  value: choice,
                  child: Text(_visibleSections.contains(choice) ? 'Hide $choice' : 'Show $choice'),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            switch (index) {
              case 0:
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => AdminDashboardPage()),
                );
                break;
              case 1:
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => AdminMessagesPage()),
                );
                break;
              case 2:
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => AdminSettingsPage()),
                );
                break;
            }
          });
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Messages'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return SingleChildScrollView(
          child: Column(
            children: [
              if (_visibleSections.contains('All'))
                _buildSection('All Complaints/Requests', _allSelectedType, _allStartDate, _allEndDate, (type, startDate, endDate) {
                  setState(() {
                    _allSelectedType = type;
                    _allStartDate = startDate;
                    _allEndDate = endDate;
                  });
                }, Colors.blue[50]!),
              if (_visibleSections.contains('Pending'))
                _buildSection('Pending Complaints/Requests', _pendingSelectedType, _pendingStartDate, _pendingEndDate, (type, startDate, endDate) {
                  setState(() {
                    _pendingSelectedType = type;
                    _pendingStartDate = startDate;
                    _pendingEndDate = endDate;
                  });
                }, Colors.red[50]!),
              if (_visibleSections.contains('Completed'))
                _buildSection('Completed Complaints/Requests', _completedSelectedType, _completedStartDate, _completedEndDate, (type, startDate, endDate) {
                  setState(() {
                    _completedSelectedType = type;
                    _completedStartDate = startDate;
                    _completedEndDate = endDate;
                  });
                }, Colors.green[50]!),
              if (_visibleSections.contains('Discarded'))
                _buildSection('Discarded Complaints/Requests', _discardedSelectedType, _discardedStartDate, _discardedEndDate, (type, startDate, endDate) {
                  setState(() {
                    _discardedSelectedType = type;
                    _discardedStartDate = startDate;
                    _discardedEndDate = endDate;
                  });
                }, Colors.grey[300]!),
            ],
          ),
        );
      case 1:
        return AdminMessagesPage(); // Navigate to AdminMessagesPage
      case 2:
        return AdminSettingsPage(); // Navigate to SettingsPage
      default:
        return Container();
    }
  }

  void _toggleSectionVisibility(String section) {
    setState(() {
      if (_visibleSections.contains(section)) {
        _visibleSections.remove(section);
      } else {
        _visibleSections.add(section);
      }
    });
  }

  Widget _buildSection(String title, String selectedType, DateTime? startDate, DateTime? endDate, Function(String, DateTime?, DateTime?) onUpdate, Color backgroundColor) {
    return Card(
      margin: EdgeInsets.all(10),
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Row(
              children: [
                DropdownButton<String>(
                  value: selectedType,
                  items: <String>['All', 'Complaints', 'Requests']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    onUpdate(newValue!, startDate, endDate);
                  },
                ),
                SizedBox(width: 20),
                ElevatedButton(
                  onPressed: () => _selectDateRange(selectedType, startDate, endDate, onUpdate),
                  child: Text('Select Date Range'),
                ),
                Spacer(),
              ],
            ),
            SizedBox(height: 10),
            // Display selected date range
            if (startDate != null && endDate != null)
              Text('Selected Date Range: ${DateFormat('yyyy-MM-dd').format(startDate)} to ${DateFormat('yyyy-MM-dd').format(endDate)}'),
            SizedBox(height: 10),
            FutureBuilder<QuerySnapshot>(
              future: _fetchData(title, selectedType, startDate, endDate),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                }
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Text('No data available');
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var doc = snapshot.data!.docs[index];
                    return ListTile(
                      title: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(text: 'Apartment No: ', style: TextStyle(fontWeight: FontWeight.bold)),
                            TextSpan(text: '${doc['apartmentNo']}\n', style: TextStyle(fontWeight: FontWeight.bold)),
                            TextSpan(text: doc['title']),
                          ],
                        ),
                      ),
                      subtitle: Text(doc['body']),
                      onTap: () => _showDetails(doc),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<QuerySnapshot> _fetchData(String section, String selectedType, DateTime? startDate, DateTime? endDate) async {
    CollectionReference collection = FirebaseFirestore.instance.collection('SS');
    Query query = collection;

    // Filter by type
    if (selectedType == 'Complaints') {
      query = query.where('template', isEqualTo: 'Complaint');
    } else if (selectedType == 'Requests') {
      query = query.where('template', isEqualTo: 'Request');
    }

    // Filter by date range
    if (startDate != null && endDate != null) {
      query = query.where('timestamp', isGreaterThanOrEqualTo: startDate)
                   .where('timestamp', isLessThanOrEqualTo: endDate);
    }

    // Filter by status based on the section
    if (section == 'Pending Complaints/Requests') {
      query = query.where('status', isEqualTo: 'Pending');
    } else if (section == 'Completed Complaints/Requests') {
      query = query.where('status', isEqualTo: 'Completed');
    } else if (section == 'Discarded Complaints/Requests') {
      query = query.where('status', isEqualTo: 'Discarded');
    }

    return await query.get();
  }

  Future<void> _selectDateRange(String selectedType, DateTime? startDate, DateTime? endDate, Function(String, DateTime?, DateTime?) onUpdate) async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(Duration(days: 30)),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      onUpdate(selectedType, picked.start, picked.end);
    }
  }

  void _showDetails(QueryDocumentSnapshot doc) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(doc['title']),
          content: Text(doc['body']),
          actions: [
            DropdownButton<String>(
              items: <String>['Pending', 'Completed', 'Discarded']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                _updateStatus(doc.id, newValue!);
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateStatus(String docId, String status) async {
    CollectionReference collection = FirebaseFirestore.instance.collection('SS');
    await collection.doc(docId).update({'status': status});
    setState(() {});
  }
}