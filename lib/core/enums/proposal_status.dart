enum ProposalStatus {
  pending('pending'),
  accepted('accepted'),
  rejected('rejected'),
  withdrawn('withdrawn');

  final String value;
  const ProposalStatus(this.value);

  static ProposalStatus fromString(String val) {
    return ProposalStatus.values.firstWhere(
      (e) => e.value == val.toLowerCase(),
      orElse: () => ProposalStatus.pending,
    );
  }
}
