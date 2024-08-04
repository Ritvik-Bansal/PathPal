// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// class GoogleAuthService {
//   final GoogleSignIn googleSignIn = GoogleSignIn(
//     scopes: [
//       'email',
//       'https://www.googleapis.com/auth/userinfo.profile',
//     ],
//   );

//   Future<Map<String, String?>> completeFirebaseSignIn(
//       GoogleSignInAuthentication gAuth) async {
//     try {
//       final credential = GoogleAuthProvider.credential(
//         accessToken: gAuth.accessToken,
//         idToken: gAuth.idToken,
//       );

//       UserCredential userCredential =
//           await FirebaseAuth.instance.signInWithCredential(credential);
//       User? user = userCredential.user;
//       return {
//         'name': user?.displayName,
//         'email': user?.email,
//       };
//     } catch (error) {
//       print('Error during Firebase Sign-In: $error');
//       return {};
//     }
//   }
// }
