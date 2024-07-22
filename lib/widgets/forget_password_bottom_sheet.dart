import 'package:flutter/material.dart';
import 'package:pathpal/screens/forgetPasswordMail.dart';
import 'package:pathpal/widgets/forgetPasswordBtn.dart';

class ForgetPasswordBottomSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Forgot your password?",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          Text(
            "Select the option below to reset your password",
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          SizedBox(height: 30),
          Forgetpasswordbtn(
            icon: Icons.mail_outline_rounded,
            titleText: 'E-mail',
            descText: 'Reset Password via E-mail',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ForgetPasswordMailScreen(),
                ),
              );
            },
          ),
          SizedBox(height: 50),
        ],
      ),
    );
  }
}
