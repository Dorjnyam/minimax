import 'package:equatable/equatable.dart';

class TransitStop extends Equatable {
  const TransitStop({required this.name, required this.time});

  final String name;
  final String time;

  @override
  List<Object?> get props => [name, time];
}

class TransitStep extends Equatable {
  const TransitStep({
    required this.title,
    required this.detail,
    required this.minutes,
  });

  final String title;
  final String detail;
  final int minutes;

  @override
  List<Object?> get props => [title, detail, minutes];
}

class TransitRouteOption extends Equatable {
  const TransitRouteOption({
    required this.busNumber,
    required this.routeName,
    required this.headsign,
    required this.fromStop,
    required this.toStop,
    required this.departureTime,
    required this.arrivalTime,
    required this.totalMinutes,
    required this.walkMinutes,
    required this.transferCount,
    required this.stops,
    required this.steps,
  });

  final String busNumber;
  final String routeName;
  final String headsign;
  final String fromStop;
  final String toStop;
  final String departureTime;
  final String arrivalTime;
  final int totalMinutes;
  final int walkMinutes;
  final int transferCount;
  final List<TransitStop> stops;
  final List<TransitStep> steps;

  String get summary {
    final transfer = transferCount == 0 ? 'direct' : '$transferCount transfer';
    return '$totalMinutes min • $transfer • $walkMinutes min walk';
  }

  @override
  List<Object?> get props => [
    busNumber,
    routeName,
    headsign,
    fromStop,
    toStop,
    departureTime,
    arrivalTime,
    totalMinutes,
    walkMinutes,
    transferCount,
    stops,
    steps,
  ];
}
