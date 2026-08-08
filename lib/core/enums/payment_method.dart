enum PaymentMethod {
  jazzcash('jazzcash'),
  easypaisa('easypaisa'),
  cod('cod');

  final String value;
  const PaymentMethod(this.value);

  static PaymentMethod fromString(String val) {
    return PaymentMethod.values.firstWhere(
      (e) => e.value == val.toLowerCase(),
      orElse: () => PaymentMethod.cod,
    );
  }
}
