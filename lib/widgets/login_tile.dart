import 'package:flutter/material.dart';

class LoginTile extends StatelessWidget {
  final String imagePath;
  final Function()? onTap;
  final String title;
  const LoginTile(
      {super.key,
      required this.imagePath,
      required this.onTap,
      required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: Row(
            children: [
              Expanded(
                child: Divider(
                  thickness: 1.0,
                  color: Colors.grey.shade300,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Text(
                  "Other sign-in options",
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 14,
                  ),
                ),
              ),
              Expanded(
                child: Divider(
                  thickness: 2.0,
                  color: Colors.grey.shade300,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 10),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(40),
              color: Colors.white,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  imagePath,
                  height: 24,
                  width: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
