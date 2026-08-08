import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skill_bridge/config/theme/app_colors.dart';
import 'package:skill_bridge/shared/widgets/app_button.dart';
import 'package:skill_bridge/shared/widgets/app_card.dart';
import 'package:skill_bridge/config/theme/app_text_styles.dart';

class EasyPaisaCheckoutScreen extends ConsumerStatefulWidget {
  final String jobId;
  final double amount;
  final String workerName;

  const EasyPaisaCheckoutScreen({
    super.key,
    required this.jobId,
    required this.amount,
    required this.workerName,
  });

  @override
  ConsumerState<EasyPaisaCheckoutScreen> createState() =>
      _EasyPaisaCheckoutScreenState();
}

class _EasyPaisaCheckoutScreenState
    extends ConsumerState<EasyPaisaCheckoutScreen> {
  final _phoneController = TextEditingController();
  final _pinController = TextEditingController();
  bool _isLoading = false;
  bool _isSuccess = false;

  void _processPayment() async {
    if (_phoneController.text.length < 11 || _pinController.text.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid mobile number and 5-digit PIN.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Mock API call to EasyPaisa taking 2 seconds
    await Future.delayed(const Duration(seconds: 2));

    // Wait 1 more second to show success animation before popping
    setState(() {
      _isLoading = false;
      _isSuccess = true;
    });

    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      context.pop(true); // Return true indicating success
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const easyPaisaGreen = Color(0xFF00B74F);

    if (_isSuccess) {
      return Scaffold(
        backgroundColor: easyPaisaGreen,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline,
                  color: Colors.white, size: 100),
              const SizedBox(height: 24),
              Text(
                'Payment Successful!',
                style: AppTextStyles.headlineLg.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                'Rs. ${widget.amount.toInt()} paid to ${widget.workerName}',
                style: AppTextStyles.bodyStrong.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: easyPaisaGreen,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('EasyPaisa Checkout',
            style: AppTextStyles.heading3.copyWith(color: Colors.white)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              // EasyPaisa Logo Mock
              Container(
                height: 80,
                decoration: BoxDecoration(
                  color: easyPaisaGreen,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    'easypaisa',
                    style: AppTextStyles.headlineLg.copyWith(
                      color: Colors.white,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              AppCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Payment Details',
                        style: AppTextStyles.heading3
                            .copyWith(color: AppColors.primary)),
                    const Divider(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Paying To:', style: AppTextStyles.bodyMedium),
                        Text(widget.workerName,
                            style: AppTextStyles.bodyStrong),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Amount:', style: AppTextStyles.bodyMedium),
                        Text('Rs. ${widget.amount.toInt()}',
                            style: AppTextStyles.heading3
                                .copyWith(color: easyPaisaGreen)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Text('Mobile Account Number',
                  style: AppTextStyles.bodyStrong),
              const SizedBox(height: 8),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: '03XX XXXXXXX',
                  prefixIcon: const Icon(Icons.phone_android, color: easyPaisaGreen),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: easyPaisaGreen, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('5-Digit PIN', style: AppTextStyles.bodyStrong),
              const SizedBox(height: 8),
              TextField(
                controller: _pinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 5,
                decoration: InputDecoration(
                  hintText: '• • • • •',
                  prefixIcon: const Icon(Icons.lock_outline, color: easyPaisaGreen),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: easyPaisaGreen, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _processPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: easyPaisaGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'PAY RS. ${widget.amount.toInt()}',
                          style: AppTextStyles.heading3
                              .copyWith(color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
