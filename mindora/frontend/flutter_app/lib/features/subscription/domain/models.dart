import 'package:equatable/equatable.dart';

class Plan extends Equatable {
  const Plan({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    required this.tier,
    required this.amountMinor,
    required this.currency,
    required this.billingCycle,
    required this.features,
    required this.isActive,
    required this.sortOrder,
  });

  final String id;
  final String code;
  final String name;
  final String? description;
  final String tier;
  final int amountMinor;
  final String currency;
  final String billingCycle;
  final Map<String, dynamic> features;
  final bool isActive;
  final int sortOrder;

  /// Human-friendly amount, e.g. "2 500 FCFA"
  String get displayAmount {
    final whole = amountMinor / 100.0;
    final formatted = whole == whole.roundToDouble()
        ? whole.toStringAsFixed(0)
        : whole.toStringAsFixed(2);
    // Simple thousands separator with a narrow no-break space.
    final withSep = formatted.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]} ',
    );
    return '$withSep $currency';
  }

  String get cycleLabel => switch (billingCycle) {
        'monthly' => 'per month',
        'quarterly' => 'per quarter',
        'yearly' => 'per year',
        _ => '',
      };

  factory Plan.fromJson(Map<String, dynamic> j) => Plan(
        id: j['id'] as String,
        code: j['code'] as String,
        name: j['name'] as String,
        description: j['description'] as String?,
        tier: j['tier'] as String,
        amountMinor: j['amount_minor'] as int,
        currency: j['currency'] as String,
        billingCycle: j['billing_cycle'] as String,
        features: (j['features'] as Map?)?.cast<String, dynamic>() ?? {},
        isActive: j['is_active'] as bool? ?? true,
        sortOrder: j['sort_order'] as int? ?? 0,
      );

  @override
  List<Object?> get props => [id, code];
}

class Subscription extends Equatable {
  const Subscription({
    required this.id,
    required this.userId,
    required this.planId,
    required this.status,
    this.currentPeriodStart,
    this.currentPeriodEnd,
    this.cancelledAt,
    required this.provider,
    this.providerReference,
    required this.createdAt,
    this.plan,
  });

  final String id;
  final String userId;
  final String planId;
  final String status;
  final DateTime? currentPeriodStart;
  final DateTime? currentPeriodEnd;
  final DateTime? cancelledAt;
  final String provider;
  final String? providerReference;
  final DateTime createdAt;
  final Plan? plan;

  bool get isActive => status == 'active';

  int get daysRemaining {
    if (currentPeriodEnd == null) return 0;
    final diff = currentPeriodEnd!.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  factory Subscription.fromJson(Map<String, dynamic> j) => Subscription(
        id: j['id'] as String,
        userId: j['user_id'] as String,
        planId: j['plan_id'] as String,
        status: j['status'] as String,
        currentPeriodStart: j['current_period_start'] != null
            ? DateTime.parse(j['current_period_start'] as String)
            : null,
        currentPeriodEnd: j['current_period_end'] != null
            ? DateTime.parse(j['current_period_end'] as String)
            : null,
        cancelledAt: j['cancelled_at'] != null
            ? DateTime.parse(j['cancelled_at'] as String)
            : null,
        provider: j['provider'] as String,
        providerReference: j['provider_reference'] as String?,
        createdAt: DateTime.parse(j['created_at'] as String),
        plan: j['plan'] != null
            ? Plan.fromJson(j['plan'] as Map<String, dynamic>)
            : null,
      );

  @override
  List<Object?> get props => [id, status, currentPeriodEnd];
}

class Payment extends Equatable {
  const Payment({
    required this.id,
    required this.userId,
    this.subscriptionId,
    this.planId,
    required this.status,
    required this.amountMinor,
    required this.currency,
    required this.reference,
    this.providerReference,
    required this.provider,
    this.redirectUrl,
    this.failureReason,
    this.paidAt,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String? subscriptionId;
  final String? planId;
  final String status;
  final int amountMinor;
  final String currency;
  final String reference;
  final String? providerReference;
  final String provider;
  final String? redirectUrl;
  final String? failureReason;
  final DateTime? paidAt;
  final DateTime createdAt;

  factory Payment.fromJson(Map<String, dynamic> j) => Payment(
        id: j['id'] as String,
        userId: j['user_id'] as String,
        subscriptionId: j['subscription_id'] as String?,
        planId: j['plan_id'] as String?,
        status: j['status'] as String,
        amountMinor: j['amount_minor'] as int,
        currency: j['currency'] as String,
        reference: j['reference'] as String,
        providerReference: j['provider_reference'] as String?,
        provider: j['provider'] as String,
        redirectUrl: j['redirect_url'] as String?,
        failureReason: j['failure_reason'] as String?,
        paidAt: j['paid_at'] != null
            ? DateTime.parse(j['paid_at'] as String)
            : null,
        createdAt: DateTime.parse(j['created_at'] as String),
      );

  @override
  List<Object?> get props => [id, status];
}

class CheckoutSession extends Equatable {
  const CheckoutSession({
    required this.payment,
    required this.checkoutUrl,
    required this.provider,
  });

  final Payment payment;
  final String checkoutUrl;
  final String provider;

  factory CheckoutSession.fromJson(Map<String, dynamic> j) => CheckoutSession(
        payment: Payment.fromJson(j['payment'] as Map<String, dynamic>),
        checkoutUrl: j['checkout_url'] as String,
        provider: j['provider'] as String,
      );

  @override
  List<Object?> get props => [payment.id, checkoutUrl];
}
