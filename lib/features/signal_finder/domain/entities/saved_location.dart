import 'dart:convert';
import 'package:uuid/uuid.dart';

import 'signal_rank.dart';

class SavedLocation {
  final String id;
  final String name;
  final String description;
  final DateTime timestamp;
  final double score;
  final SignalRank rank;

  SavedLocation({
    String? id,
    required this.name,
    this.description = '',
    DateTime? timestamp,
    required this.score,
    required this.rank,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'score': score,
      'rank': rank.toString().split('.').last,
    };
  }

  factory SavedLocation.fromMap(Map<String, dynamic> map) {
    return SavedLocation(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
      score: (map['score'] ?? 0.0).toDouble(),
      rank: SignalRank.values.firstWhere(
        (e) => e.toString().split('.').last == map['rank'],
        orElse: () => SignalRank.deadZone,
      ),
    );
  }

  String toJson() => json.encode(toMap());

  factory SavedLocation.fromJson(String source) => SavedLocation.fromMap(json.decode(source));
}
