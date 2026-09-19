class SubscriptionPlanEntity {
  const SubscriptionPlanEntity({
    required this.code, required this.name, required this.amountMinorUnits,
    required this.currency, required this.interval,
  });
  final String code;
  final String name;
  final int amountMinorUnits;
  final String currency;
  final String interval;

  /// Placeholder pricing (see backend config) — a zero amount displays
  /// as "Price coming soon" rather than a misleading "0 XAF".
  String get displayPrice =>
      amountMinorUnits <= 0 ? 'Price coming soon' : '${(amountMinorUnits / 100).toStringAsFixed(2)} $currency';

  factory SubscriptionPlanEntity.fromJson(Map<String, dynamic> json) => SubscriptionPlanEntity(
        code: json['code'] as String,
        name: json['name'] as String,
        amountMinorUnits: json['amount_minor_units'] as int,
        currency: json['currency'] as String,
        interval: json['interval'] as String,
      );
}

class CreditTransactionEntity {
  const CreditTransactionEntity({required this.delta, required this.reason, required this.createdAt});
  final int delta;
  final String reason;
  final DateTime createdAt;

  factory CreditTransactionEntity.fromJson(Map<String, dynamic> json) => CreditTransactionEntity(
        delta: json['delta'] as int,
        reason: json['reason'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
