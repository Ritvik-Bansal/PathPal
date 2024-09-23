import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:country_picker/country_picker.dart';
import 'package:pathpal/screens/learn_more.dart';
import 'package:pathpal/screens/privacy_policy_screen.dart';
import 'package:pathpal/screens/terms_conditions_screen.dart';
import 'package:pathpal/services/google_auth_flow.dart';
import 'package:pathpal/widgets/login_tile.dart';

class AuthForm extends StatefulWidget {
  final bool isLogin;
  final Function(String, String, {String? name}) onSubmit;
  final bool isAuthenticating;
  final VoidCallback onToggleAuthMode;
  final VoidCallback onForgotPassword;
  final Function() onResendVerificationEmail;

  const AuthForm({
    super.key,
    required this.isLogin,
    required this.onSubmit,
    required this.isAuthenticating,
    required this.onToggleAuthMode,
    required this.onForgotPassword,
    required this.onResendVerificationEmail,
  });

  @override
  _AuthFormState createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  bool _isMounted = false;
  final _form = GlobalKey<FormState>();
  var _enteredEmail = "";
  var _enteredPassword = "";
  var _enteredConfirmPassword = "";
  var _enteredName = "";
  var _passwordVisible = false;
  Country? country;
  final GoogleAuthFlow _googleAuthFlow = GoogleAuthFlow();

  @override
  void initState() {
    super.initState();
    _isMounted = true;
  }

  @override
  void dispose() {
    _isMounted = false;
    super.dispose();
  }

  void _safeSetState(VoidCallback fn) {
    if (_isMounted) {
      setState(fn);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    _safeSetState(() {});

    try {
      final user = await _googleAuthFlow.startAuthFlow(context);
      if (user != null) {
        print('Successfully signed in with Google: ${user.displayName}');
      }
    } finally {
      _safeSetState(() {});
    }
  }

  void _trySubmit() {
    final isValid = _form.currentState!.validate();
    if (!isValid) return;

    if (!widget.isLogin && _enteredPassword != _enteredConfirmPassword) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    _form.currentState!.save();
    widget.onSubmit(
      _enteredEmail,
      _enteredPassword,
      name: _enteredName,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      margin: const EdgeInsets.only(bottom: 0, right: 10, left: 10, top: 10),
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
                  label: const Text('Password'),
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
                onChanged: (value) {
                  _enteredPassword = value;
                },
              ),
              if (widget.isLogin)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: widget.onForgotPassword,
                    child: const Text("Forgot Password?"),
                  ),
                ),
              if (!widget.isLogin)
                TextFormField(
                  decoration: InputDecoration(
                    label: const Text('Confirm Password'),
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
                    if (value != _enteredPassword) {
                      return "Passwords do not match";
                    }
                    return null;
                  },
                  onSaved: (newValue) {
                    _enteredConfirmPassword = newValue!;
                  },
                  onChanged: (value) {
                    _enteredConfirmPassword = value;
                  },
                ),
              if (!widget.isLogin)
                TextFormField(
                  decoration: const InputDecoration(label: Text('Full Name')),
                  enableSuggestions: false,
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
              if (!widget.isLogin)
                Column(
                  children: [
                    SizedBox(height: 30),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface),
                          children: [
                            const TextSpan(
                              text: 'I have read and accepted PathPal\'s ',
                            ),
                            TextSpan(
                              text: 'Terms of Service',
                              style: const TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const TermsAndConditionsScreen()),
                                  );
                                },
                            ),
                            const TextSpan(text: ' and '),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: const TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const PrivacyPolicyScreen()),
                                  );
                                },
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              if (widget.isAuthenticating)
                CircularProgressIndicator(
                  backgroundColor: Theme.of(context).colorScheme.surface,
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _trySubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                    ),
                    child: Text(widget.isLogin ? "LOGIN" : "SIGN UP"),
                  ),
                ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(widget.isLogin ? "New User?" : "Have an account?"),
                  if (widget.isLogin) ...[
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const LearnMoreScreen()),
                        );
                      },
                      child: Text("Learn more"),
                    ),
                    Text("or"),
                  ],
                  TextButton(
                    onPressed: widget.onToggleAuthMode,
                    child: Text(widget.isLogin ? "Sign up" : "Login"),
                  ),
                ],
              ),
              if (widget.isLogin) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.3),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Or login with',
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.3),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                LoginTile(
                  imagePath: 'assets/images/google_logo.png',
                  onTap: _handleGoogleSignIn,
                  title: 'Sign in with Google',
                ),
                const SizedBox(height: 20),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
