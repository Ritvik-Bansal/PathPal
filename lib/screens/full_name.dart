import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pathpal/screens/tabs.dart';

class FullNameScreen extends StatefulWidget {
  final User user;

  const FullNameScreen({Key? key, required this.user}) : super(key: key);

  @override
  _FullNameScreenState createState() => _FullNameScreenState();
}

class _FullNameScreenState extends State<FullNameScreen> {
  final _formKey = GlobalKey<FormState>();
  String _fullName = '';

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      try {
        await widget.user.updateDisplayName(_fullName);
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.user.uid)
            .update({'name': _fullName});
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const Tabs()),
        );
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update name: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(title: Text('Addiitonal Information')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 120),
              Image.asset('assets/icon/icon_removed_bg.png'),
              TextFormField(
                decoration: InputDecoration(labelText: 'Full Name'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your full name';
                  }
                  if (!value.contains(' ')) {
                    return 'Please enter your first and last name';
                  }
                  return null;
                },
                onSaved: (value) => _fullName = value!,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submit,
                child: Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
