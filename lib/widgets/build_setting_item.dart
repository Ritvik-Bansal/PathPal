import 'package:flutter/material.dart';

class BuildSettingItem extends StatelessWidget {
  const BuildSettingItem(this.icon, this.title,
      {super.key, required this.nextScreen});
  final IconData icon;
  final String title;
  final Widget nextScreen;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              return nextScreen;
            },
          ),
        );
      },
    );
  }
}
