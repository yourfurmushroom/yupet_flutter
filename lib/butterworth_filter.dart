import 'dart:math';

class ButterworthFilter {
  final double fs; // 取樣頻率
  final double fc; // 截止頻率
  final int order;

  late List<double> a;
  late List<double> b;
  late List<double> z;

  ButterworthFilter({required this.fs, required this.fc, this.order = 2}) {
    _computeCoefficients();
    z = List.filled(order + 1, 0.0);
  }

  void _computeCoefficients() {
    double wc = 2 * pi * fc / fs;
    double c = 1 / tan(wc / 2);
    double c2 = c * c;

    double norm = 1 / (1 + sqrt(2) * c + c2);

    b = [
      norm,
      2 * norm,
      norm,
    ];

    a = [
      1.0,
      -2 * (c2 - 1) * norm, // 修正 a[1]，標準公式
      -(1 - sqrt(2) * c + c2) * norm, // 修正 a[2]，標準公式
    ];
  }

  double filter(double input) {
    double output = b[0] * input + z[0];

    for (int i = 0; i < order; i++) {
      z[i] = b[i + 1] * input + z[i + 1] - a[i + 1] * output;
    }

    z[order] = b[order] * input - a[order] * output; // 修正 z[order] 更新邏輯
    return output;
  }
}