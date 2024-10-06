import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pathpal/data/airline_data.dart';
import 'package:pathpal/screens/home.dart';
import 'package:pathpal/screens/messages_screen.dart';
import 'package:pathpal/screens/my_stuff_screen.dart';
import 'package:pathpal/screens/notifications.dart';
import 'package:pathpal/screens/profile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pathpal/services/firestore_service.dart';

class Tabs extends StatefulWidget {
  const Tabs({super.key});

  @override
  State<Tabs> createState() => _TabsState();
}

class _TabsState extends State<Tabs> {
  StreamSubscription<DocumentSnapshot>? _userStreamSubscription;
  StreamSubscription<QuerySnapshot>? _notificationsStreamSubscription;
  StreamSubscription<QuerySnapshot>? _messagesStreamSubscription;
  int _selectedIndex = 0;
  String _userName = "Profile";
  late List<Widget> _widgetOptions;
  late FirestoreService _firestoreService;
  late AirlineFetcher _airlineFetcher;
  bool _hasUnreadNotifications = false;
  bool _hasUnreadMessages = false;

  @override
  void initState() {
    super.initState();
    _firestoreService = FirestoreService();
    _airlineFetcher = AirlineFetcher();
    _initUserStream();
    _initNotificationsStream();
    _initMessagesStream();
    _widgetOptions = <Widget>[
      HomeScreen(onProfileTap: () {
        _onItemTapped(4);
      }),
      const MyStuffScreen(),
      NotificationsScreen(
        firestoreService: _firestoreService,
        airlineFetcher: _airlineFetcher,
        onOpen: _markNotificationsAsRead,
      ),
      const MessagesScreen(),
      const ProfileScreen(),
    ];
  }

  void _initUserStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userStreamSubscription = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists) {
          setState(() {
            _userName =
                (snapshot.data() as Map<String, dynamic>)['name'] ?? "Profile";
          });
        }
      });
    }
  }

  void _initMessagesStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _messagesStreamSubscription = FirebaseFirestore.instance
          .collection('chats')
          .where('participants', arrayContains: user.uid)
          .snapshots()
          .listen((snapshot) {
        bool hasUnread = false;
        for (var doc in snapshot.docs) {
          final chatData = doc.data();
          if ((chatData['unreadCount_${user.uid}'] ?? 0) > 0) {
            hasUnread = true;
            break;
          }
        }
        setState(() {
          _hasUnreadMessages = hasUnread;
        });
      });
    }
  }

  void _initNotificationsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _notificationsStreamSubscription = FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .where('read', isEqualTo: false)
          .snapshots()
          .listen((snapshot) {
        setState(() {
          _hasUnreadNotifications = snapshot.docs.isNotEmpty;
        });
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      if (index == 2) {
        _markNotificationsAsRead();
      }
    });
  }

  void _markNotificationsAsRead() {
    _firestoreService
        .markAllNotificationsAsRead(FirebaseAuth.instance.currentUser!.uid);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _selectedIndex == 4
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
        backgroundColor: Theme.of(context).colorScheme.surface,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(
              Icons.home_outlined,
              size: _selectedIndex == 0 ? 28 : 24,
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.flight_outlined,
              size: _selectedIndex == 1 ? 28 : 24,
            ),
            label: 'My Trips',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                Icon(
                  Icons.notifications_outlined,
                  size: _selectedIndex == 2 ? 28 : 24,
                ),
                if (_hasUnreadNotifications)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 12,
                        minHeight: 12,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Alerts',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: _selectedIndex == 3 ? 28 : 24,
                ),
                if (_hasUnreadMessages)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 12,
                        minHeight: 12,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.person_outline,
              size: _selectedIndex == 4 ? 28 : 24,
            ),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.inversePrimary,
        unselectedItemColor:
            Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        onTap: _onItemTapped,
      ),
    );
  }

  @override
  void dispose() {
    _userStreamSubscription?.cancel();
    _notificationsStreamSubscription?.cancel();
    _messagesStreamSubscription?.cancel();
    super.dispose();
  }
}
