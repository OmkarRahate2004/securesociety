import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RequestPage extends StatefulWidget {
  @override
  _RequestPageState createState() => _RequestPageState();
}

class _RequestPageState extends State<RequestPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  String? _requestType;
  String? _apartmentNo;
  DateTime? _startDateTime;
  DateTime? _endDateTime;

  @override
  void initState() {
    super.initState();
    _getApartmentNo();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Submit a Request'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Request Type'),
                value: _requestType,
                items: <String>[
                  'Complaint',
                  'Access to Gym',
                  'Access to Pool',
                  'Access to Hall',
                  'Other'
                ].map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _requestType = newValue;
                    // Reset date/time pickers when request type changes
                    _startDateTime = null;
                    _endDateTime = null;
                  });
                },
                validator: (value) => value == null ? 'Please select a request type' : null,
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: 'Title'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16.0),
              TextFormField(
                controller: _bodyController,
                decoration: InputDecoration(labelText: 'Request Details'),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter request details';
                  }
                  return null;
                },
              ),
              if (_requestType != null && _requestType!.startsWith('Access')) ...[
                SizedBox(height: 16.0),
                Text('Select Access Time:'),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => _selectStartDateTime(context),
                        child: Text(_startDateTime == null
                            ? 'Start Date & Time'
                            : 'Start: ${_startDateTime!.toLocal()}'.split(' ')[0]),
                      ),
                    ),
                    SizedBox(width: 8.0),
                    Expanded(
                      child: TextButton(
                        onPressed: () => _selectEndDateTime(context),
                        child: Text(_endDateTime == null
                            ? 'End Date & Time'
                            : 'End: ${_endDateTime!.toLocal()}'.split(' ')[0]),
                      ),
                    ),
                  ],
                ),
              ],
              SizedBox(height: 16.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _submitRequest();
                      }
                    },
                    child: Text('Send'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Clear the form
                      _titleController.clear();
                      _bodyController.clear();
                      setState(() {
                        _requestType = null;
                        _startDateTime = null;
                        _endDateTime = null;
                      });
                    },
                    child: Text('Cancel'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectStartDateTime(BuildContext context) async {
    DateTime? picked = await showDateTimePicker(context);
    if (picked != null && picked != _startDateTime) {
      setState(() {
        _startDateTime = picked;
      });
    }
  }

  Future<void> _selectEndDateTime(BuildContext context) async {
    DateTime? picked = await showDateTimePicker(context);
    if (picked != null && picked != _endDateTime) {
      setState(() {
        _endDateTime = picked;
      });
    }
  }

  Future<DateTime?> showDateTimePicker(BuildContext context) async {
    DateTime now = DateTime.now();
    return await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
    ).then((date) {
      if (date != null) {
        return showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(now),
        ).then((time) {
          if (time != null) {
            return DateTime(date.year, date.month, date.day, time.hour, time.minute);
          }
          return null;
        });
      }
      return null;
    });
  }

  Future<void> _submitRequest() async {
    User? user = FirebaseAuth.instance.currentUser ;

    if (user != null && _apartmentNo != null) {
      String userId = user.uid;

      // Create a request object
      Map<String, dynamic> requestData = {
        'userId': userId,
        'apartmentNo': _apartmentNo,
        'template': _requestType,
        'title': _titleController.text,
        'body': _bodyController.text,
        'timestamp': FieldValue.serverTimestamp(),
      };

      if (_requestType != null && _requestType!.startsWith('Access')) {
        requestData['startDateTime'] = _startDateTime;
        requestData['endDateTime'] = _endDateTime;
      }

      // Save the request to Firestore
      await FirebaseFirestore.instance.collection('SS').add(requestData);

      // Clear the form
      _titleController.clear();
      _bodyController.clear();
      setState(() {
        _requestType = null;
        _startDateTime = null;
        _endDateTime = null;
      });

      // Show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request submitted successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No user is logged in or apartment number not found.')),
      );
    }
  }
}