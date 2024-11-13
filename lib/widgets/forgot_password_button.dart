import 'package:flutter/material.dart';

class Forgetpasswordbtn extends StatelessWidget {
  const Forgetpasswordbtn({
    super.key,
    required this.icon,
    required this.descText,
    required this.titleText,
    required this.onTap,
    this.iconSize = 60,
    this.fontSize = 16,
  });

  final IconData icon;
  final String titleText;
  final String descText;
  final void Function() onTap;
  final double iconSize;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: const Color.fromARGB(104, 180, 221, 255),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: iconSize,
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titleText,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    descText,
                    style: TextStyle(
                      fontSize: fontSize,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
