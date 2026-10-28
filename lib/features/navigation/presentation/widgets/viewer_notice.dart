import 'package:flutter/material.dart';

import '../navigation_tokens.dart';

// Pill on the dark photo background; tappable when it offers a retry
class ViewerNotice extends StatelessWidget {
  const ViewerNotice({super.key, required this.text, this.onTap});

  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      liveRegion: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: NavColors.loading,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: NavText.loading,
          ),
        ),
      ),
    );
  }
}
