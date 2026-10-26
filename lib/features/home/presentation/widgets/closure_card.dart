import 'package:flutter/material.dart';

import '../../data/campus_models.dart';
import '../home_tokens.dart';

class ClosureCard extends StatelessWidget {
  const ClosureCard({super.key, required this.closures});

  static const _maxShown = 3;

  final List<Closure> closures;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 19, 16, 15),
      decoration: BoxDecoration(
        color: HomeColors.closure,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🚧 지금 못 가는 곳 ${closures.length}곳',
            style: HomeText.closureTitle,
          ),
          const SizedBox(height: 7),
          for (final c in closures.take(_maxShown))
            Padding(
              padding: const EdgeInsets.only(left: 18),
              child: Text(c.summary, style: HomeText.closureItem),
            ),
          const SizedBox(height: 9),
          Opacity(
            opacity: 0.8,
            child: Text('길안내가 이곳을 피해서 안내해요', style: HomeText.closureSmall),
          ),
        ],
      ),
    );
  }
}
