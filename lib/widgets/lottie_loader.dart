import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LottieLoader extends StatelessWidget {
  final double size;

  const LottieLoader({super.key, this.size = 60});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: Lottie.asset('assets/lottie/loader.json', fit: BoxFit.contain),
      ),
    );
  }
}
