import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:country_picker/country_picker.dart';
import 'package:http/http.dart' as http;

class AuthForm extends StatefulWidget {
  final bool isLogin;
  final Function(String, String, {String? name, String? phone, String? age})
      onSubmit;
  final bool isAuthenticating;
  final VoidCallback onToggleAuthMode;
  final VoidCallback onForgotPassword;

  const AuthForm({
    Key? key,
    required this.isLogin,
    required this.onSubmit,
    required this.isAuthenticating,
    required this.onToggleAuthMode,
    required this.onForgotPassword,
  }) : super(key: key);

  @override
  _AuthFormState createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  bool _isMounted = false;
  final _form = GlobalKey<FormState>();
  var _enteredEmail = "";
  var _enteredPassword = "";
  var _enteredName = "";
  var _enteredPhone = "";
  var _enteredAge = "";
  var _passwordVisible = false;
  Country? country;

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    _initializeCountry();
  }

  @override
  void dispose() {
    _isMounted = false;
    super.dispose();
  }

  Future<String> fetchCountryCode() async {
    try {
      final response = await http.get(Uri.parse('http://ip-api.com/json'));
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        return body['countryCode'];
      } else {
        throw Exception('Failed to load country code');
      }
    } catch (e) {
      print('Error fetching country code: $e');
      return 'US'; // Default to US if there's an error
    }
  }

  void _initializeCountry() async {
    final countryCode = await fetchCountryCode();
    if (_isMounted) {
      setState(() {
        country = CountryParser.parseCountryCode(countryCode);
      });
    }
  }

  void _safeSetState(VoidCallback fn) {
    if (_isMounted) {
      setState(fn);
    }
  }

  void _trySubmit() {
    final isValid = _form.currentState!.validate();
    if (!isValid) return;

    _form.currentState!.save();
    widget.onSubmit(
      _enteredEmail,
      _enteredPassword,
      name: _enteredName,
      phone: _enteredPhone,
      age: _enteredAge,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      color: Theme.of(context).colorScheme.surface,
      margin: const EdgeInsets.all(10),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: const InputDecoration(label: Text('Email Address')),
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                textCapitalization: TextCapitalization.none,
                validator: (value) {
                  if (value == null ||
                      value.trim().isEmpty ||
                      !value.contains('@')) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
                onSaved: (newValue) {
                  _enteredEmail = newValue!;
                },
              ),
              TextFormField(
                decoration: InputDecoration(
                  label: Text('Password'),
                  suffixIcon: IconButton(
                    onPressed: () {
                      _safeSetState(() {
                        _passwordVisible = !_passwordVisible;
                      });
                    },
                    icon: Icon(
                      _passwordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                  ),
                ),
                obscureText: !_passwordVisible,
                validator: (value) {
                  if (value == null || value.trim().length < 6) {
                    return "Password must be at least 6 characters long";
                  }
                  return null;
                },
                onSaved: (newValue) {
                  _enteredPassword = newValue!;
                },
              ),
              if (!widget.isLogin)
                TextFormField(
                  decoration: const InputDecoration(label: Text('Full Name')),
                  enableSuggestions: true,
                  validator: (value) {
                    if (value == null ||
                        !value.trim().contains(' ') ||
                        value.isEmpty) {
                      return 'Please enter a full name';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _enteredName = value!;
                  },
                ),
              if (!widget.isLogin && country != null)
                TextFormField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.only(top: 15),
                    hintText: 'Enter phone number',
                    prefixIcon: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        showCountryPicker(
                          context: context,
                          onSelect: (Country country) {
                            _safeSetState(() {
                              this.country = country;
                            });
                          },
                          favorite: ['US', 'IN'],
                          countryListTheme: CountryListThemeData(
                            bottomSheetHeight:
                                MediaQuery.sizeOf(context).height / 2,
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(20)),
                            inputDecoration: InputDecoration(
                              labelText: 'Search',
                              hintText: 'Start typing to search',
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color:
                                      const Color(0xFF8C98A8).withOpacity(0.2),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      child: Container(
                        height: 56,
                        width: 100,
                        alignment: Alignment.center,
                        child: Text(
                          '${country!.flagEmoji} +${country!.phoneCode}',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Please enter a phone number';
                    } else if (!RegExp(
                            r'^\s*(?:\+?(\d{1,3}))?[-. (]*(\d{3})[-. )]*(\d{3})[-. ]*(\d{4})(?: *x(\d+))?\s*$')
                        .hasMatch(value)) {
                      return 'Please enter a valid phone number';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _enteredPhone = "+${country!.phoneCode} ${value!}";
                  },
                ),
              if (!widget.isLogin)
                TextFormField(
                  decoration: const InputDecoration(label: Text('Age')),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value!.isEmpty || num.tryParse(value) == null) {
                      return 'Please enter an age';
                    } else if (num.parse(value) > 120) {
                      return 'Please enter a valid age';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _enteredAge = value!;
                  },
                ),
              const SizedBox(height: 20),
              if (widget.isAuthenticating)
                const CircularProgressIndicator()
              else
                ElevatedButton(
                  onPressed: _trySubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                  ),
                  child: Text(widget.isLogin ? "LOGIN" : "SIGN UP"),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(widget.isLogin ? "New User?" : "Have an account?"),
                  TextButton(
                    onPressed: widget.onToggleAuthMode,
                    child: Text(widget.isLogin ? "Sign up" : "Login"),
                  ),
                ],
              ),
              if (widget.isLogin)
                TextButton(
                  onPressed: widget.onForgotPassword,
                  child: Text("Forgot Password?"),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
