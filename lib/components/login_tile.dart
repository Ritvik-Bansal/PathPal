import 'package:flutter/material.dart';

class LoginTile extends StatelessWidget {
  final String imagePath;
  final Function()? onTap;
  const LoginTile({
    super.key,
    required this.imagePath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.blue.shade400,
          ),
          borderRadius: BorderRadius.circular(90),
          color: Colors.blue[100],
        ),
        child: Image.asset(
          imagePath,
          height: 40,
          width: 40,
        ),
      ),
    );
  }
}
