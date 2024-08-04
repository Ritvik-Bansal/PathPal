import 'package:flutter/material.dart';
import 'package:pathpal/screens/home.dart';
import 'package:pathpal/screens/profile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pathpal/widgets/age_phone.dart';

class Tabs extends StatefulWidget {
  const Tabs({super.key});

  @override
  State<Tabs> createState() => _TabsState();
}

class _TabsState extends State<Tabs> {
  int _selectedIndex = 0;
  String _userName = "Profile";

  final List<Widget> _widgetOptions = <Widget>[
    const HomeScreen(),
    const ProfileScreen()
  ];

  @override
  void initState() {
    super.initState();
    _fetchUserName();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowAgePhoneScreen();
    });
  }

  Future<void> _fetchUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (docSnapshot.exists) {
        setState(() {
          _userName = docSnapshot.data()?['name'] ?? "Profile";
        });
      }
    }
  }

  Future<void> _checkAndShowAgePhoneScreen() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      bool needsAgePhone = false;
      if (!docSnapshot.exists) {
        needsAgePhone = true;
      } else {
        final data = docSnapshot.data();
        if (data == null ||
            !data.containsKey('phone_number') ||
            !data.containsKey('age')) {
          needsAgePhone = true;
        }
      }

      if (needsAgePhone) {
        _showAgePhoneScreen();
      }
    }
  }

  void _showAgePhoneScreen() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        child: AgePhone(
          onSubmit: ({String? phone, String? age}) async {
            if (phone != null && age != null) {
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .set({
                  'phone_number': phone,
                  'age': age,
                }, SetOptions(merge: true));
              }
            }
            Navigator.of(context).pop();
          },
          isAuthenticating: false,
        ),
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _selectedIndex == 1
          ? AppBar(
              title: Text(
                _userName.toUpperCase(),
                style: const TextStyle(
                  fontFamily: 'BricolageGrotesque',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: true,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              elevation: 0,
            )
          : null,
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.inversePrimary,
        onTap: _onItemTapped,
      ),
    );
  }
}
