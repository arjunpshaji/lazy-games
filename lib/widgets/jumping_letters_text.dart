import 'package:flutter/material.dart';

/// A widget that animates the letters of a string with a jumping animation,
/// letter by letter, in a repeating staggered sequence.
class JumpingLettersText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final double jumpHeight;
  final Duration letterJumpDuration;
  final Duration delayBetweenLetters;
  final Duration cyclePauseDuration;

  const JumpingLettersText({
    super.key,
    required this.text,
    required this.style,
    this.jumpHeight = 12.0,
    this.letterJumpDuration = const Duration(milliseconds: 350),
    this.delayBetweenLetters = const Duration(milliseconds: 90),
    this.cyclePauseDuration = const Duration(milliseconds: 1200),
  });

  @override
  State<JumpingLettersText> createState() => _JumpingLettersTextState();
}

class _JumpingLettersTextState extends State<JumpingLettersText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    final lettersCount = widget.text.length;
    final delayMs = widget.delayBetweenLetters.inMilliseconds;
    final jumpMs = widget.letterJumpDuration.inMilliseconds;
    final pauseMs = widget.cyclePauseDuration.inMilliseconds;

    // Total duration of a single animation cycle is:
    // (delay for each letter except the last) + (jump duration of the last letter) + (pause duration)
    final totalDurationMs =
        (lettersCount - 1) * delayMs + jumpMs + pauseMs;

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: totalDurationMs),
    );

    _animations = List.generate(lettersCount, (index) {
      final startMs = index * delayMs;
      final endMs = startMs + jumpMs;

      final startFraction = startMs / totalDurationMs;
      final endFraction = endMs / totalDurationMs;

      // Use a custom TweenSequence to rise and fall smoothly
      return TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween<double>(begin: 0.0, end: -widget.jumpHeight)
              .chain(CurveTween(curve: Curves.easeOutQuad)),
          weight: 50.0,
        ),
        TweenSequenceItem(
          tween: Tween<double>(begin: -widget.jumpHeight, end: 0.0)
              .chain(CurveTween(curve: Curves.easeInQuad)),
          weight: 50.0,
        ),
      ]).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            startFraction,
            endFraction,
            curve: Curves.linear,
          ),
        ),
      );
    });

    _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant JumpingLettersText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text ||
        oldWidget.jumpHeight != widget.jumpHeight ||
        oldWidget.letterJumpDuration != widget.letterJumpDuration ||
        oldWidget.delayBetweenLetters != widget.delayBetweenLetters ||
        oldWidget.cyclePauseDuration != widget.cyclePauseDuration) {
      _controller.dispose();
      _initAnimations();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.text.length, (index) {
        final char = widget.text[index];
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _animations[index].value),
              child: child,
            );
          },
          child: Text(
            char,
            style: widget.style,
          ),
        );
      }),
    );
  }
}
