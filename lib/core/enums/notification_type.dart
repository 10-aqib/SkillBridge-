enum NotificationType {
  jobPosted('job_posted'),
  proposalReceived('proposal_received'),
  proposalAccepted('proposal_accepted'),
  contractCreated('contract_created'),
  reviewReceived('review_received'),
  chatMessage('chat_message'),
  workerVerified('worker_verified'),
  disputeUpdate('dispute_update'),
  adminBroadcast('admin_broadcast');

  final String value;
  const NotificationType(this.value);

  static NotificationType fromString(String val) {
    return NotificationType.values.firstWhere(
      (e) => e.value == val.toLowerCase(),
      orElse: () => NotificationType.adminBroadcast,
    );
  }
}
