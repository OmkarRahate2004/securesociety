import 'package:flutter/material.dart';
import 'Login.dart'; // Make sure to import your Login screen

class WelcomeScreen extends StatefulWidget {
  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<String> _images = [
    'assets/lgo.png',
    // 'assets/image2.png',
    // 'assets/image3.png',
  ];

  void _nextPage() {
    if (_currentPage < _images.length - 1) {
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    } else {
      // Navigate to the login page if on the last image
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page!.round();
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _images.length,
              itemBuilder: (context, index) {
                return Image.asset(
                  _images[index],
                  fit: BoxFit.cover,
                );
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _build3DButton("Previous", _previousPage, Colors.black),
              _build3DButton(
                _currentPage == _images.length - 1 ? "Go to Login" : "Next",
                _nextPage,
                Colors.black,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _build3DButton(String text, VoidCallback onPressed, Color color) {
    return Material(
      elevation: 8, // Adjust elevation for 3D effect
      borderRadius: BorderRadius.circular(8), // Rounded corners
      child: Container(
        decoration: BoxDecoration(
          color: color, // Button color
          borderRadius: BorderRadius.circular(8), // Match the Material border radius
        ),
        child: TextButton(
          onPressed: onPressed,
          child: Text(
            text,
            style: TextStyle(color: Colors.white), // Text color
          ),
        ),
      ),
    );
  }
}