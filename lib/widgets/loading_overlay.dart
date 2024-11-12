import 'package:flutter/material.dart';

class LoadingOverlay {
  static OverlayEntry? _overlay;

  static void show(BuildContext context) {
    if (_overlay != null) return;

    _overlay = OverlayEntry(
      builder: (context) => Container(
        color: Colors.black45,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );

    Overlay.of(context).insert(_overlay!);
  }

  static void hide() {
    _overlay?.remove();
    _overlay = null;
  }
}
