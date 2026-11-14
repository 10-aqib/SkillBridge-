import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:skill_bridge/core/extensions/context_extensions.dart';

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

/// List timestamp: time today, "Yesterday", weekday this week, else a date.
String chatListTime(BuildContext context, DateTime at, {DateTime? now}) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  final today = _day(now ?? DateTime.now());
  final day = _day(at);
  final diff = today.difference(day).inDays;
  if (diff <= 0) return DateFormat.jm(locale).format(at);
  if (diff == 1) return context.l10n.chatYesterday;
  if (diff < 7) return DateFormat.E(locale).format(at);
  return DateFormat.yMd(locale).format(at);
}

/// Date separator inside a conversation: Today, Yesterday, or the date.
String chatDayLabel(BuildContext context, DateTime at, {DateTime? now}) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  final diff = _day(now ?? DateTime.now()).difference(_day(at)).inDays;
  if (diff <= 0) return context.l10n.chatToday;
  if (diff == 1) return context.l10n.chatYesterday;
  return DateFormat.yMMMMd(locale).format(at);
}

bool chatSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

String chatMessageTime(BuildContext context, DateTime at) =>
    DateFormat.jm(Localizations.localeOf(context).toLanguageTag()).format(at);
