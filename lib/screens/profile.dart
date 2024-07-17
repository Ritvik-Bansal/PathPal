import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pathpal/screens/personal_info.dart';
import 'package:pathpal/widgets/buildSettingItem.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context)
          .colorScheme
          .primaryContainer, // Light blue background
      child: Column(
        children: [
          const SizedBox(height: 20),
          const CircleAvatar(
            radius: 80,
            backgroundColor: Colors.grey,
            child: Icon(Icons.person, size: 80, color: Colors.white),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              padding: EdgeInsets.all(10),
              margin: const EdgeInsets.only(top: 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                //add border color blue??? maybe not needed
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Account Settings',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      const BuildSettingItem(
                        Icons.edit,
                        'PERSONAL INFORMATION',
                        nextScreen: PersonalInfoScreen(),
                      ),
                      const BuildSettingItem(
                        Icons.calendar_today,
                        'TRIP CALENDAR',
                        nextScreen: PersonalInfoScreen(),
                      ),
                      const BuildSettingItem(
                        Icons.settings,
                        'SETTINGS',
                        nextScreen: PersonalInfoScreen(),
                      ),
                      const BuildSettingItem(
                        Icons.notifications,
                        'NOTIFICATIONS',
                        nextScreen: PersonalInfoScreen(),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Help and Support',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      const BuildSettingItem(
                        Icons.security,
                        'PRIVACY POLICY',
                        nextScreen: PersonalInfoScreen(),
                      ),
                      const BuildSettingItem(
                        Icons.description,
                        'TERMS AND CONDITIONS',
                        nextScreen: PersonalInfoScreen(),
                      ),
                      const BuildSettingItem(
                        Icons.help,
                        'HELP',
                        nextScreen: PersonalInfoScreen(),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(200, 50),
                          ),
                          onPressed: () {
                            FirebaseAuth.instance.signOut();
                          },
                          child: const Text('LOG OUT',
                              style: TextStyle(fontSize: 18)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
