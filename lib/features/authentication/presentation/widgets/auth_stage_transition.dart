import 'package:algolens/core/theme/app_motion.dart';
import 'package:flutter/material.dart';

class AuthStageTransition extends StatelessWidget {
  const AuthStageTransition({super.key, required this.stage, required this.child});

  final Object stage;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: AppMotion.duration(context, AppMotion.page),
    switchInCurve: AppMotion.curve,
    switchOutCurve: Curves.easeIn,
    layoutBuilder: (current, previous) => ClipRect(
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          for (final outgoing in previous)
            if (outgoing.key != current?.key)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: IgnorePointer(child: ExcludeSemantics(child: outgoing)),
              ),
          ?current,
        ],
      ),
    ),
    child: KeyedSubtree(key: ValueKey(stage), child: child),
  );
}
