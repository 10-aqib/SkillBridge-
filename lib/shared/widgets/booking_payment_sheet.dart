import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skill_bridge/config/theme/app_dimensions.dart';
import 'package:skill_bridge/config/theme/app_text_styles.dart';
import 'package:skill_bridge/core/constants/pakistan_constants.dart';
import 'package:skill_bridge/core/extensions/context_extensions.dart';
import 'package:skill_bridge/core/utils/formatters.dart';
import 'package:skill_bridge/features/auth/presentation/providers/auth_providers.dart';
import 'package:skill_bridge/features/contracts/presentation/providers/contract_providers.dart';
import 'package:skill_bridge/shared/widgets/app_button.dart';
import 'package:skill_bridge/shared/widgets/app_card.dart';
import 'package:skill_bridge/shared/widgets/app_text_field.dart';

class BookingPaymentSheet extends ConsumerStatefulWidget {
  final String workerId;
  final String workerName;
  final String categoryName;
  final double hourlyRatePkr;

  const BookingPaymentSheet({
    super.key,
    required this.workerId,
    required this.workerName,
    required this.categoryName,
    required this.hourlyRatePkr,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String workerId,
    required String workerName,
    required String categoryName,
    required double hourlyRatePkr,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BookingPaymentSheet(
        workerId: workerId,
        workerName: workerName,
        categoryName: categoryName,
        hourlyRatePkr: hourlyRatePkr,
      ),
    );
  }

  @override
  ConsumerState<BookingPaymentSheet> createState() => _BookingPaymentSheetState();
}

class _BookingPaymentSheetState extends ConsumerState<BookingPaymentSheet> {
  String _selectedCity = 'Lahore';
  final _addressController = TextEditingController(text: 'DHA Phase 5, Sector C');
  final _phoneController = TextEditingController(text: '+92 300 ');
  int _hours = 2;
  String _selectedPaymentMethod = 'jazzcash';
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _selectedTimeSlot = 'Morning (10:00 AM - 01:00 PM)';

  final List<String> _timeSlots = [
    'Morning (10:00 AM - 01:00 PM)',
    'Afternoon (02:00 PM - 05:00 PM)',
    'Evening (06:00 PM - 09:00 PM)',
  ];

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  double get _platformFee => 150.0;
  double get _totalAmount => (widget.hourlyRatePkr * _hours) + _platformFee;

  bool _isSubmitting = false;

  Future<void> _confirmBooking() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Please log in to hire workers.'),
              backgroundColor: context.colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      final ds = ref.read(contractRemoteDataSourceProvider);
      await ds.createDirectContract(
        clientId: currentUser.uid,
        clientName: currentUser.displayName,
        clientPhotoUrl: currentUser.photoUrl,
        workerId: widget.workerId,
        workerName: widget.workerName,
        workerPhotoUrl: null,
        categoryName: widget.categoryName,
        hourlyRatePkr: widget.hourlyRatePkr,
        hours: _hours,
        totalAmount: _totalAmount,
        address: _addressController.text.trim(),
        city: _selectedCity,
        date: _selectedDate,
        timeSlot: _selectedTimeSlot,
        phone: _phoneController.text.trim(),
        paymentMethod: _selectedPaymentMethod,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Booking request sent to ${widget.workerName}! Pending approval. Total: ${Formatters.formatPkr(_totalAmount)}',
            ),
            backgroundColor: context.colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to confirm booking: $e'),
            backgroundColor: context.colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String _getPaymentName() {
    final method = PakistanConstants.paymentMethods.firstWhere(
      (m) => m['id'] == _selectedPaymentMethod,
      orElse: () => {'shortName': 'Cash'},
    );
    return method['shortName'] as String;
  }

  @override
  Widget build(BuildContext context) {
    final cities = PakistanConstants.cities.where((c) => c['name'] != 'All Cities').toList();
    final paymentMethods = PakistanConstants.paymentMethods;

    return Container(
      padding: EdgeInsets.only(
        left: AppDimensions.space20,
        right: AppDimensions.space20,
        top: AppDimensions.space20,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppDimensions.space20,
      ),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXl),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.colorScheme.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.space16),

              // Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Book Service',
                          style: AppTextStyles.headlineMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${widget.workerName} • ${widget.categoryName}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: context.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppDimensions.space8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.space12,
                      vertical: AppDimensions.space6,
                    ),
                    decoration: BoxDecoration(
                      color: context.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                    ),
                    child: Text(
                      '${Formatters.formatPkr(widget.hourlyRatePkr)}/hr',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: context.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: AppDimensions.space32),

              // ── Step 1: Location & City ────────────────────────────────────
              Text(
                '1. Service Address (Pakistan)',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppDimensions.space12),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedCity,
                      decoration: const InputDecoration(
                        labelText: 'City',
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      items: cities.map((city) {
                        return DropdownMenuItem(
                          value: city['name'] as String,
                          child: Text(city['name'] as String),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedCity = val);
                      },
                    ),
                  ),
                  const SizedBox(width: AppDimensions.space12),
                  Expanded(
                    flex: 3,
                    child: AppTextField(
                      controller: _addressController,
                      labelText: 'Street / Area',
                      hintText: 'e.g., F-7/4 or DHA Phase 5',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.space20),

              // ── Step 2: Date & Time ────────────────────────────────────────
              Text(
                '2. Preferred Date & Time',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppDimensions.space12),
              Row(
                children: [
                  Expanded(
                    child: AppCard(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 30)),
                        );
                        if (date != null) setState(() => _selectedDate = date);
                      },
                      padding: const EdgeInsets.all(AppDimensions.space12),
                      color: context.colorScheme.surfaceContainerHighest,
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, size: 18, color: context.colorScheme.primary),
                          const SizedBox(width: AppDimensions.space8),
                          Text(
                            '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                            style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.space8),
              DropdownButtonFormField<String>(
                initialValue: _selectedTimeSlot,
                decoration: const InputDecoration(
                  labelText: 'Time Slot',
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                items: _timeSlots.map((slot) {
                  return DropdownMenuItem(value: slot, child: Text(slot));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedTimeSlot = val);
                },
              ),
              const SizedBox(height: AppDimensions.space20),

              // ── Step 3: Estimated Duration ────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '3. Estimated Duration',
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '$_hours ${_hours == 1 ? 'hour' : 'hours'}',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: context.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Slider(
                value: _hours.toDouble(),
                min: 1,
                max: 8,
                divisions: 7,
                label: '$_hours hrs',
                onChanged: (val) => setState(() => _hours = val.toInt()),
              ),
              const SizedBox(height: AppDimensions.space16),

              // ── Step 4: Payment Method ─────────────────────────────────────
              Text(
                '4. Select Payment Method (Pakistan)',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppDimensions.space12),
              Column(
                children: paymentMethods.map((method) {
                  final id = method['id'] as String;
                  final isSelected = _selectedPaymentMethod == id;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppDimensions.space8),
                    child: AppCard(
                      onTap: () => setState(() => _selectedPaymentMethod = id),
                      padding: const EdgeInsets.all(AppDimensions.space12),
                      color: isSelected
                          ? context.colorScheme.primaryContainer.withValues(alpha: 0.4)
                          : context.colorScheme.surfaceContainer,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                method['icon'] as IconData,
                                color: isSelected
                                    ? context.colorScheme.primary
                                    : context.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: AppDimensions.space12),
                              Expanded(
                                child: Text(
                                  method['name'] as String,
                                  style: AppTextStyles.bodyLarge.copyWith(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check_circle,
                                  color: context.colorScheme.primary,
                                ),
                            ],
                          ),
                          if (isSelected && (method['requiresPhone'] == true)) ...[
                            const SizedBox(height: AppDimensions.space12),
                            AppTextField(
                              controller: _phoneController,
                              labelText: '${method['shortName']} Phone Number',
                              hintText: method['accountHint'] as String?,
                              keyboardType: TextInputType.phone,
                            ),
                          ],
                          if (isSelected && method['details'] != null) ...[
                            const SizedBox(height: AppDimensions.space8),
                            Container(
                              padding: const EdgeInsets.all(AppDimensions.space12),
                              decoration: BoxDecoration(
                                color: context.colorScheme.surface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: method['id'] == 'raast_qr'
                                      ? const Color(0xFF006622)
                                      : context.colorScheme.outlineVariant,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (method['id'] == 'raast_qr') ...[
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.qr_code_2_rounded,
                                          size: 32,
                                          color: Color(0xFF006622),
                                        ),
                                        const SizedBox(width: AppDimensions.space8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '100% Escrow Protected • محفوظ ادائیگی',
                                                style: AppTextStyles.labelSmall.copyWith(
                                                  color: const Color(0xFF006622),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                'Scan with any banking app in Pakistan',
                                                style: AppTextStyles.bodySmall.copyWith(
                                                  color: context.colorScheme.onSurfaceVariant,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: AppDimensions.space8),
                                  ],
                                  Text(
                                    method['details'] as String,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      fontFamily: 'monospace',
                                      color: context.colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppDimensions.space20),

              // ── Summary & PKR Calculation ──────────────────────────────────
              AppCard(
                padding: const EdgeInsets.all(AppDimensions.space16),
                color: context.colorScheme.surfaceContainerHighest,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Service Cost ($_hours hrs)',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodyMedium,
                          ),
                        ),
                        Text(
                          Formatters.formatPkr(widget.hourlyRatePkr * _hours),
                          style: AppTextStyles.bodyMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.space8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Skill Bridge PK Platform Fee',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodyMedium,
                          ),
                        ),
                        Text(
                          Formatters.formatPkr(_platformFee),
                          style: AppTextStyles.bodyMedium,
                        ),
                      ],
                    ),
                    const Divider(height: AppDimensions.space16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Payable (PKR)',
                          style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          Formatters.formatPkr(_totalAmount),
                          style: AppTextStyles.titleMedium.copyWith(
                            color: context.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.space24),

              // ── Confirm CTA ────────────────────────────────────────────────
              AppButton(
                text: 'Request Booking • ${Formatters.formatPkr(_totalAmount)}',
                onPressed: _confirmBooking,
                isLoading: _isSubmitting,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
