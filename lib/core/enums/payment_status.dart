enum PaymentStatus {
  unpaid('unpaid'),
  escrow('escrow'),
  released('released'),
  refunded('refunded'),
  failed('failed');

  final String value;
  const PaymentStatus(this.value);

  static PaymentStatus fromString(String val) {
    return PaymentStatus.values.firstWhere(
      (e) => e.value == val.toLowerCase(),
      orElse: () => PaymentStatus.unpaid,
    );
  }
}
