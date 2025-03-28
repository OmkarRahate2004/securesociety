import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'adminDashboard.dart';
import 'adminSettingsPage.dart';

class AdminMessagesPage extends StatefulWidget {
  @override
  _AdminMessagesPage createState() => _AdminMessagesPage();
}

class _AdminMessagesPage extends State<AdminMessagesPage> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _locationController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  String _eventStatus = 'Upcoming'; // Default status
  String _selectedFilter = 'All'; // For filtering events
  int _currentIndex = 1; // For bottom navigation (1 for Messages)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Events'),
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
                // Stay on AdminMessagesPage
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEventDialog,
        child: Icon(Icons.add),
        backgroundColor: Colors.amberAccent,
      ),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        _buildEventFilterDropdown(),
        Expanded(child: _buildEventList()),
      ],
    );
  }

  Widget _buildEventForm() {
    return Column(
      children: [
        TextField(
          controller: _titleController,
          decoration: InputDecoration(hintText: 'Event Title'),
        ),
        TextField(
          controller: _bodyController,
          decoration: InputDecoration(hintText: 'Event Body'),
        ),
        TextField(
          controller: _locationController,
          decoration: InputDecoration(hintText: 'Event Location'),
        ),
        SizedBox(height: 10),
        ElevatedButton(
          onPressed: () => _selectDateTime(true),
          child: Text('Select Start Date & Time'),
        ),
        SizedBox(height: 10),
        ElevatedButton(
          onPressed: () => _selectDateTime(false),
          child: Text('Select End Date & Time'),
        ),
        SizedBox(height: 20),
        _buildSelectedDateTimeDisplay(),
        SizedBox(height: 10),
        DropdownButton<String>(
          value: _eventStatus,
          items: <String>['Upcoming', 'Ongoing', 'Completed']
              .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _eventStatus = newValue!;
            });
          },
        ),
        SizedBox(height: 10),
        ElevatedButton(
          onPressed: _addEvent,
          child: Text('Add Event'),
        ),
      ],
    );
  }

  Widget _buildSelectedDateTimeDisplay() {
    String startDateTime = _startDate != null
        ? 'From: ${DateFormat('yyyy-MM-dd – kk:mm').format(_startDate!)}'
        : 'From: Not selected';
    String endDateTime = _endDate != null
        ? 'To: ${DateFormat('yyyy-MM-dd – kk:mm').format(_endDate!)}'
        : 'To: Not selected';

    return Center(
      child: Column(
        children: [
          Text(startDateTime, style: TextStyle(fontSize: 16)),
          SizedBox(height: 5),
          Text(endDateTime, style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildEventFilterDropdown() {
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

  Future<void> _addEvent() async {
    if (_titleController.text.isEmpty || _bodyController.text.isEmpty || _locationController.text.isEmpty || _startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please fill all fields')));
      return;
    }

    await FirebaseFirestore.instance.collection('ep').add({
      'title': _titleController.text.trim(),
      'body': _bodyController.text.trim(),
      'location': _locationController.text.trim(),
      'startDate': Timestamp.fromDate(_startDate!),
      'endDate': Timestamp.fromDate(_endDate!),
      'status': _eventStatus,
    });

    // Clear the fields after adding the event
    _titleController.clear();
    _bodyController.clear();
    _locationController.clear();
    _startDate = null;
    _endDate = null;
    setState(() {});
  }

  Future<void> _selectDateTime(bool isStart) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      TimeOfDay? timePicked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (timePicked != null) {
        DateTime selectedDateTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          timePicked.hour,
          timePicked.minute,
        );

        if (isStart) {
          setState(() {
            _startDate = selectedDateTime;
          });
        } else {
          setState(() {
            _endDate = selectedDateTime;
          });
        }
      }
    }
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

  void _showAddEventDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Event'),
          content: _buildEventForm(), // Call the form method here
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}