import 'dart:math';

import 'package:flutter/widgets.dart';

class Word {
  String value;
  Offset pos;
  Color color;
  double size;

  Word(String value, Random random) {
    this.value = value;
    pos = Offset(random.nextDouble(), random.nextDouble());
    color = HSVColor.fromAHSV(1.0, random.nextDouble() * 255.0, 1.0, 1.0).toColor();
    size = random.nextInt(20) + 14.0;
  }
}
