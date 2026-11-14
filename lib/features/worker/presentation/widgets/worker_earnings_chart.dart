import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skill_bridge/config/theme/app_text_styles.dart';
import 'package:skill_bridge/core/enums/contract_status.dart';
import 'package:skill_bridge/features/contracts/presentation/providers/contract_providers.dart';
import 'package:skill_bridge/core/utils/formatters.dart';
import 'package:skill_bridge/features/worker/presentation/screens/worker_home_screen.dart';

// ── Dark Design Tokens ────────────────────────────────────────────────────────
const _card = Color(0xFF131A27);
const _surface2 = Color(0xFF192233);
const _textPrimary = Color(0xFFF5F6FA);
const _textSecondary = Color(0xFF929BAA);
const _border = Color(0xFF252F40);
const _accent = Color(0xFF4778E8);
const _success = Color(0xFF22C58B);

/// Minimal Premium Earnings Widget — 4-week line chart.
class WorkerEarningsChart extends ConsumerStatefulWidget {
  final int totalCompleted;

  const WorkerEarningsChart({super.key, required this.totalCompleted});

  @override
  ConsumerState<WorkerEarningsChart> createState() =>
      _WorkerEarningsChartState();
}

class _WorkerEarningsChartState extends ConsumerState<WorkerEarningsChart> {
  String _period = 'This Month';
  final _periods = ['This Month', 'Last Month', 'All Time'];

  @override
  Widget build(BuildContext context) {
    final contractsAsync = ref.watch(userContractsStreamProvider);

    return contractsAsync.when(
      loading: () => _buildShell(
        child: const SizedBox(
          height: 140,
          child: Center(
            child: CircularProgressIndicator(color: _accent, strokeWidth: 2),
          ),
        ),
        totalEarnings: null,
        weeklyValues: null,
      ),
      error: (_, __) => _buildShell(
        child: const SizedBox(
          height: 100,
          child: Center(
            child: Text(
              'Could not load earnings',
              style: TextStyle(color: _textSecondary, fontSize: 13),
            ),
          ),
        ),
        totalEarnings: null,
        weeklyValues: null,
      ),
      data: (contracts) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        // Determine period date range
        DateTime periodStart;
        DateTime periodEnd;
        if (_period == 'Last Month') {
          final firstOfThisMonth = DateTime(now.year, now.month, 1);
          periodStart = DateTime(now.year, now.month - 1, 1);
          periodEnd = firstOfThisMonth.subtract(const Duration(days: 1));
        } else if (_period == 'All Time') {
          periodStart = DateTime(2020);
          periodEnd = today.add(const Duration(days: 1));
        } else {
          // This Month
          periodStart = DateTime(now.year, now.month, 1);
          periodEnd = today.add(const Duration(days: 1));
        }

        return _buildForRange(contracts, periodStart, periodEnd);
      },
    );
  }

  Widget _buildForRange(
    List<dynamic> contracts,
    DateTime start,
    DateTime end,
  ) {
    final completed = contracts.where((c) {
      final at = c.completedAt;
      return c.status == ContractStatus.completed &&
          at != null &&
          !at.isBefore(start) &&
          at.isBefore(end);
    }).toList();

    final totalEarnings = completed.fold<double>(
      0,
      (sum, c) => sum + (c.workerEarnings as double),
    );

    // Build 4-week buckets
    final weeklyValues = List.generate(4, (week) {
      final weekStart = start.add(Duration(days: week * 7));
      final weekEnd = weekStart.add(const Duration(days: 7));
      return completed
          .where((c) {
            final at = c.completedAt as DateTime;
            return !at.isBefore(weekStart) && at.isBefore(weekEnd);
          })
          .fold<double>(0, (sum, c) => sum + (c.workerEarnings as double));
    });

    // Previous period comparison
    final periodDuration = end.difference(start);
    final prevStart = start.subtract(periodDuration);
    final prevEarnings = contracts
        .where((c) {
          final at = c.completedAt;
          return c.status == ContractStatus.completed &&
              at != null &&
              !at.isBefore(prevStart) &&
              at.isBefore(start);
        })
        .fold<double>(0, (sum, c) => sum + (c.workerEarnings as double));

    double? growthPct;
    if (prevEarnings > 0) {
      growthPct = ((totalEarnings - prevEarnings) / prevEarnings) * 100;
    }

    return _buildShell(
      totalEarnings: totalEarnings,
      growthPct: growthPct,
      weeklyValues: weeklyValues,
      child: const SizedBox.shrink(),
    );
  }

  Widget _buildShell({
    required Widget child,
    double? totalEarnings,
    double? growthPct,
    List<double>? weeklyValues,
  }) {
    final hasData =
        totalEarnings != null && weeklyValues != null && totalEarnings > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with flexible layout
          Row(
            children: [
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.bar_chart_rounded,
                      color: _accent,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Your Earnings',
                        style: AppTextStyles.bodyStrong.copyWith(
                          color: _textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Period selector dropdown
              _PeriodDropdown(
                value: _period,
                options: _periods,
                onChanged: (val) => setState(() => _period = val),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Total earnings + growth badge
          if (totalEarnings != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    Formatters.formatPkr(totalEarnings),
                    style: const TextStyle(
                      color: _textPrimary,
                      fontFamily: 'JetBrainsMono',
                      fontWeight: FontWeight.w800,
                      fontSize: 24,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (growthPct != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: (growthPct >= 0
                              ? _success
                              : const Color(0xFFEF5350))
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          growthPct >= 0
                              ? Icons.arrow_upward_rounded
                              : Icons.arrow_downward_rounded,
                          color: growthPct >= 0
                              ? _success
                              : const Color(0xFFEF5350),
                          size: 11,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${growthPct.abs().toStringAsFixed(0)}%',
                          style: TextStyle(
                            color: growthPct >= 0
                                ? _success
                                : const Color(0xFFEF5350),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'JetBrainsMono',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 14),
          ],

          // Chart area or loading/empty
          if (hasData) ...[
            _LineChartWidget(values: weeklyValues!),
          ] else if (weeklyValues != null && totalEarnings == 0) ...[
            _buildEmptyChartPlaceholder(),
          ] else ...[
            child,
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyChartPlaceholder() {
    return SizedBox(
      height: 110,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.show_chart_rounded,
                color: _textSecondary, size: 28),
            const SizedBox(height: 6),
            Text(
              'No earnings recorded yet',
              style: AppTextStyles.labelCaption.copyWith(
                color: _textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Period Dropdown ───────────────────────────────────────────────────────────
class _PeriodDropdown extends StatelessWidget {
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  const _PeriodDropdown({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      initialValue: value,
      onSelected: onChanged,
      color: const Color(0xFF131A27),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: _border),
      ),
      itemBuilder: (context) => options
          .map((opt) => PopupMenuItem(
                value: opt,
                child: Text(
                  opt,
                  style: AppTextStyles.bodyPrimary.copyWith(
                    color: _textPrimary,
                    fontSize: 13,
                  ),
                ),
              ))
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: _surface2,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: AppTextStyles.labelCaption.copyWith(
                color: _textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 3),
            const Icon(Icons.keyboard_arrow_down_rounded,
                color: _textSecondary, size: 16),
          ],
        ),
      ),
    );
  }
}

// ── Line Chart Widget ─────────────────────────────────────────────────────────
class _LineChartWidget extends StatelessWidget {
  final List<double> values;

  const _LineChartWidget({required this.values});

  @override
  Widget build(BuildContext context) {
    final maxVal = values.isEmpty ? 1.0 : values.reduce(math.max);
    final effectiveMax = maxVal == 0 ? 1.0 : maxVal;

    return Column(
      children: [
        // Chart + Y-axis labels
        SizedBox(
          height: 125,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Y-axis labels
              SizedBox(
                width: 32,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _yLabel(effectiveMax),
                      style: const TextStyle(
                          color: _textSecondary,
                          fontSize: 9,
                          fontFamily: 'JetBrainsMono'),
                    ),
                    Text(
                      _yLabel(effectiveMax * 0.67),
                      style: const TextStyle(
                          color: _textSecondary,
                          fontSize: 9,
                          fontFamily: 'JetBrainsMono'),
                    ),
                    Text(
                      _yLabel(effectiveMax * 0.33),
                      style: const TextStyle(
                          color: _textSecondary,
                          fontSize: 9,
                          fontFamily: 'JetBrainsMono'),
                    ),
                    const Text(
                      '0',
                      style: TextStyle(
                          color: _textSecondary,
                          fontSize: 9,
                          fontFamily: 'JetBrainsMono'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Canvas chart
              Expanded(
                child: CustomPaint(
                  painter: PremiumLineChartPainter(values: values),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // X-axis labels
        Padding(
          padding: const EdgeInsets.only(left: 40),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              values.length,
              (i) => Expanded(
                child: Center(
                  child: Text(
                    'Week ${i + 1}',
                    style: const TextStyle(
                      color: _textSecondary,
                      fontSize: 9,
                      fontFamily: 'JetBrainsMono',
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _yLabel(double val) {
    if (val >= 1000) {
      return '${(val / 1000).toStringAsFixed(0)}k';
    }
    return val.toStringAsFixed(0);
  }
}
