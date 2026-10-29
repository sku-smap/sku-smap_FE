import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../data/search_assets.dart';
import '../search_tokens.dart';

class PickerHeader extends StatelessWidget {
  const PickerHeader({
    super.key,
    required this.controller,
    required this.hint,
    required this.onBack,
    required this.onVoice,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final String hint;
  final VoidCallback onBack;
  final VoidCallback onVoice;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: SearchLayout.headerHeight + 1,
      padding: const EdgeInsets.fromLTRB(6, 10, 12, 10),
      decoration: const BoxDecoration(
        color: SearchColors.surface,
        border: Border(bottom: BorderSide(color: SearchColors.headerLine)),
      ),
      child: Row(
        children: [
          _IconButton(
            icon: SearchAssets.back,
            size: 22,
            label: '닫기',
            onTap: onBack,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Container(
              height: SearchLayout.fieldHeight,
              padding: const EdgeInsets.only(left: 16),
              decoration: BoxDecoration(
                color: SearchColors.field,
                borderRadius: BorderRadius.circular(SearchLayout.fieldRadius),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      autofocus: true,
                      style: SearchText.input,
                      cursorColor: SearchColors.blue,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => onSubmit(),
                      decoration: InputDecoration.collapsed(
                        hintText: hint,
                        hintStyle: SearchText.inputHint,
                      ),
                    ),
                  ),
                  _IconButton(
                    icon: SearchAssets.mic,
                    size: 20,
                    label: '음성으로 검색',
                    onTap: onVoice,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({
    required this.icon,
    required this.size,
    required this.label,
    required this.onTap,
  });

  final String icon;
  final double size;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox.square(
          dimension: SearchLayout.iconButton,
          child: Center(
            child: SvgPicture.asset(icon, width: size, height: size),
          ),
        ),
      ),
    );
  }
}
