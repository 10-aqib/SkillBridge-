/// B6. Commission Engine (10% Flat Rate) (FYP Spec 2.1.7)
/// 
/// Calculates platform fee (10% flat rate) and worker net payout (90%),
/// ensuring consistent financial accounting across jobs and contracts.
class CommissionBreakdown {
  final double grossAmount;
  final double platformFee;
  final double workerPayout;
  final double commissionRate;

  const CommissionBreakdown({
    required this.grossAmount,
    required this.platformFee,
    required this.workerPayout,
    required this.commissionRate,
  });

  Map<String, dynamic> toMap() {
    return {
      'grossAmount': grossAmount,
      'platformFee': platformFee,
      'workerPayout': workerPayout,
      'commissionRate': commissionRate,
    };
  }
}

class CommissionService {
  /// Flat 10% commission rate as per FYP Proposal section 2.1.7
  static const double flatRate = 0.10; // 10%

  /// Calculates platform commission fee: totalAmount * 0.10
  static double calculatePlatformFee(double totalAmount) {
    return (totalAmount * flatRate).roundToDouble();
  }

  /// Calculates worker net payout: totalAmount * 0.90
  static double calculateWorkerPayout(double totalAmount) {
    return (totalAmount * (1.0 - flatRate)).roundToDouble();
  }

  /// Calculates complete commission breakdown
  static CommissionBreakdown calculateBreakdown(double totalAmount) {
    final fee = calculatePlatformFee(totalAmount);
    final payout = totalAmount - fee;
    return CommissionBreakdown(
      grossAmount: totalAmount,
      platformFee: fee,
      workerPayout: payout,
      commissionRate: flatRate,
    );
  }
}
