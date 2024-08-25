import 'package:flutter/material.dart';
import 'package:pathpal/screens/forgot_password_screen.dart';
import 'package:pathpal/widgets/forgot_password_button.dart';

class ForgetPasswordBottomSheet extends StatelessWidget {
  const ForgetPasswordBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Forgot your password?",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Select the option below to reset your password",
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 30),
          Forgetpasswordbtn(
            icon: Icons.mail_outline_rounded,
            titleText: 'E-mail',
            descText: 'Reset Password via E-mail',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ForgetPasswordMailScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }
}
