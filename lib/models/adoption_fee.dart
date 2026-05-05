class AdoptionFee {
  final double total;
  final Map<String, double> breakdown;
  final String? notes;

  const AdoptionFee({
    required this.total,
    this.breakdown = const {},
    this.notes,
  });

  factory AdoptionFee.fromMap(Map<String, dynamic> map) {
    return AdoptionFee(
      total: (map['total'] as num?)?.toDouble() ?? 0.0,
      breakdown: (map['breakdown'] as Map<String, dynamic>?)
              ?.map((k, v) => MapEntry(k, (v as num).toDouble())) ??
          {},
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'total': total,
        'breakdown': breakdown,
        'notes': notes,
      };

  AdoptionFee copyWith({
    double? total,
    Map<String, double>? breakdown,
    String? notes,
  }) =>
      AdoptionFee(
        total: total ?? this.total,
        breakdown: breakdown ?? this.breakdown,
        notes: notes ?? this.notes,
      );

  double get breakdownSum =>
      breakdown.values.fold(0.0, (a, b) => a + b);
}
