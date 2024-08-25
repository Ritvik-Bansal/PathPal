// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:country_picker/country_picker.dart';
// import 'package:http/http.dart' as http;

// class AgePhone extends StatefulWidget {
//   final Function({String? phone, String? age}) onSubmit;
//   final bool isAuthenticating;
//   const AgePhone({
//     Key? key,
//     required this.onSubmit,
//     required this.isAuthenticating,
//   }) : super(key: key);

//   @override
//   _AgePhoneState createState() => _AgePhoneState();
// }

// class _AgePhoneState extends State<AgePhone> {
//   bool _isMounted = false;
//   final _form = GlobalKey<FormState>();
//   var _enteredPhone = "";
//   var _enteredAge = "";
//   Country? country;

//   @override
//   void initState() {
//     super.initState();
//     _isMounted = true;
//     _initializeCountry();
//   }

//   @override
//   void dispose() {
//     _isMounted = false;
//     super.dispose();
//   }

//   Future<String> fetchCountryCode() async {
//     try {
//       final response = await http.get(Uri.parse('http://ip-api.com/json'));
//       if (response.statusCode == 200) {
//         final body = json.decode(response.body);
//         return body['countryCode'];
//       } else {
//         throw Exception('Failed to load country code');
//       }
//     } catch (e) {
//       print('Error fetching country code: $e');
//       return 'US';
//     }
//   }

//   void _initializeCountry() async {
//     final countryCode = await fetchCountryCode();
//     if (_isMounted) {
//       setState(() {
//         country = CountryParser.parseCountryCode(countryCode);
//       });
//     }
//   }

//   void _safeSetState(VoidCallback fn) {
//     if (_isMounted) {
//       setState(fn);
//     }
//   }

//   void _trySubmit() {
//     final isValid = _form.currentState!.validate();
//     if (!isValid) return;

//     _form.currentState!.save();
//     widget.onSubmit(
//       phone: _enteredPhone,
//       age: _enteredAge,
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SingleChildScrollView(
//       child: Dialog(
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(20),
//         ),
//         child: Form(
//           key: _form,
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Image.asset('assets/icon/icon_removed_bg.png'),
//               Text(
//                 'Additional Information',
//                 style: TextStyle(
//                   fontSize: 30,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               SizedBox(height: 10),
//               Text(
//                 'In order to use PathPal, you must provide some additional information.',
//                 textAlign: TextAlign.left,
//                 style: TextStyle(
//                   fontSize: 16,
//                   color: Colors.grey.shade600,
//                 ),
//               ),
//               SizedBox(height: 15),
//               if (country != null)
//                 TextFormField(
//                   keyboardType: TextInputType.number,
//                   decoration: InputDecoration(
//                     hintText: 'Enter phone number',
//                     contentPadding: EdgeInsets.symmetric(vertical: 20),
//                     prefixIcon: GestureDetector(
//                       behavior: HitTestBehavior.opaque,
//                       onTap: () {
//                         showCountryPicker(
//                           context: context,
//                           onSelect: (Country country) {
//                             _safeSetState(() {
//                               this.country = country;
//                             });
//                           },
//                           favorite: ['US', 'IN'],
//                           countryListTheme: CountryListThemeData(
//                             bottomSheetHeight:
//                                 MediaQuery.sizeOf(context).height / 2,
//                             borderRadius:
//                                 BorderRadius.vertical(top: Radius.circular(20)),
//                             inputDecoration: InputDecoration(
//                               labelText: 'Search',
//                               hintText: 'Start typing to search',
//                               prefixIcon: const Icon(Icons.search),
//                               border: OutlineInputBorder(
//                                 borderSide: BorderSide(
//                                   color:
//                                       const Color(0xFF8C98A8).withOpacity(0.2),
//                                 ),
//                               ),
//                             ),
//                           ),
//                         );
//                       },
//                       child: Container(
//                         height: 56,
//                         width: 70,
//                         alignment: Alignment.center,
//                         child: Text(
//                           '${country!.flagEmoji} +${country!.phoneCode}',
//                           style: TextStyle(
//                             fontSize: 16,
//                             color: Theme.of(context).colorScheme.onSurface,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                   validator: (value) {
//                     if (value!.isEmpty) {
//                       return 'Please enter a phone number';
//                     } else if (!RegExp(
//                             r'^\s*(?:\+?(\d{1,3}))?[-. (]*(\d{3})[-. )]*(\d{3})[-. ]*(\d{4})(?: *x(\d+))?\s*$')
//                         .hasMatch(value)) {
//                       return 'Please enter a valid phone number';
//                     }
//                     return null;
//                   },
//                   onSaved: (value) {
//                     _enteredPhone = "+${country!.phoneCode} ${value!}";
//                   },
//                 ),
//               SizedBox(height: 10),
//               TextFormField(
//                 decoration: const InputDecoration(label: Text('Age')),
//                 keyboardType: TextInputType.number,
//                 validator: (value) {
//                   if (value!.isEmpty || num.tryParse(value) == null) {
//                     return 'Please enter an age';
//                   } else if (num.parse(value) > 120) {
//                     return 'Please enter a valid age';
//                   }
//                   return null;
//                 },
//                 onSaved: (value) {
//                   _enteredAge = value!;
//                 },
//               ),
//               const SizedBox(height: 15),
//               if (widget.isAuthenticating)
//                 const CircularProgressIndicator()
//               else
//                 ElevatedButton(
//                   onPressed: _trySubmit,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor:
//                         Theme.of(context).colorScheme.primaryContainer,
//                   ),
//                   child: Text('Submit'),
//                 ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
