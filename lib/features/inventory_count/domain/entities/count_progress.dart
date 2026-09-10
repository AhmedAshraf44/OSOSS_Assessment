import 'package:equatable/equatable.dart';

class CountProgress extends Equatable {
  const CountProgress({required this.counted, required this.total});

  final int counted;
  final int total;

  static const zero = CountProgress(counted: 0, total: 0);

  @override
  List<Object?> get props => [counted, total];
}
