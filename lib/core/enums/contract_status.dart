enum ContractStatus {
  pending('pending'),
  active('active'),
  completed('completed'),
  disputed('disputed'),
  cancelled('cancelled'),
  rejected('rejected');

  final String value;
  const ContractStatus(this.value);

  static ContractStatus fromString(String val) {
    return ContractStatus.values.firstWhere(
      (e) => e.value == val.toLowerCase(),
      orElse: () => ContractStatus.active,
    );
  }
}
