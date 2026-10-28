import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../search_tokens.dart';

class SearchToast extends StatelessWidget {
  const SearchToast({super.key, required this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final text = message;
    final top = math.max(
      SearchLayout.toastInset,
      MediaQuery.paddingOf(context).top,
    );
    return Positioned(
      top: top,
      left: SearchLayout.toastInset,
      right: SearchLayout.toastInset,
      child: IgnorePointer(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: text == null
              ? const SizedBox.shrink()
              : Center(
                  key: ValueKey(text),
                  child: Semantics(
                    liveRegion: true,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: SearchColors.toast,
                        borderRadius: BorderRadius.circular(
                          SearchLayout.toastRadius,
                        ),
                        boxShadow: SearchShadows.toast,
                      ),
                      child: Text(
                        text,
                        textAlign: TextAlign.center,
                        style: SearchText.toast,
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
