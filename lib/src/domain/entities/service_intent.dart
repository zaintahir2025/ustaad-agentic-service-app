/// Domain Entity representing the parsed customer service intent.
class ServiceIntent {
  const ServiceIntent({
    required this.role,
    required this.description,
    required this.urgency,
    required this.location,
    required this.timeLabel,
    required this.language,
    required this.confidence,
    this.userBudget,
  });

  final String role;
  final String description;
  final String urgency;
  final String location;
  final String timeLabel;
  final String language;
  final double confidence;
  final int? userBudget;

  ServiceIntent copyWith({
    String? role,
    String? description,
    String? urgency,
    String? location,
    String? timeLabel,
    String? language,
    double? confidence,
    int? userBudget,
  }) {
    return ServiceIntent(
      role: role ?? this.role,
      description: description ?? this.description,
      urgency: urgency ?? this.urgency,
      location: location ?? this.location,
      timeLabel: timeLabel ?? this.timeLabel,
      language: language ?? this.language,
      confidence: confidence ?? this.confidence,
      userBudget: userBudget ?? this.userBudget,
    );
  }
}
