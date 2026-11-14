import 'package:flutter/material.dart';

/// Defines Pakistani worker categories, cities, and payment methods.
class PakistanConstants {
  // ── Worker Categories ──────────────────────────────────────────────────
  static const List<Map<String, dynamic>> categories = [
    {
      'id': 'electrician',
      'name': 'Electrician',
      'urdu': 'بجلی والا',
      'icon': Icons.electrical_services,
    },
    {
      'id': 'plumber',
      'name': 'Plumber',
      'urdu': 'نلکے والا',
      'icon': Icons.plumbing,
    },
    {
      'id': 'ac_technician',
      'name': 'AC Technician',
      'urdu': 'اے سی ٹیکنیشن',
      'icon': Icons.ac_unit,
    },
    {
      'id': 'solar_installer',
      'name': 'Solar Installer',
      'urdu': 'سولر انسٹالر',
      'icon': Icons.solar_power,
    },
    {
      'id': 'generator_ups',
      'name': 'UPS & Generator',
      'urdu': 'یو پی ایس اور جنریٹر',
      'icon': Icons.power,
    },
    {
      'id': 'mechanic',
      'name': 'Mechanic',
      'urdu': 'مستری',
      'icon': Icons.car_repair,
    },
    {
      'id': 'painter',
      'name': 'Painter',
      'urdu': 'پینٹر',
      'icon': Icons.format_paint,
    },
    {
      'id': 'carpenter',
      'name': 'Carpenter',
      'urdu': 'بڑھئی',
      'icon': Icons.handyman,
    },
    {
      'id': 'tutor',
      'name': 'Home Tutor',
      'urdu': 'ٹیوٹر',
      'icon': Icons.menu_book,
    },
    {
      'id': 'driver',
      'name': 'Driver',
      'urdu': 'ڈرائیور',
      'icon': Icons.directions_car,
    },
    {
      'id': 'cleaner',
      'name': 'House Cleaner',
      'urdu': 'صفائی والا',
      'icon': Icons.cleaning_services,
    },
    {
      'id': 'mason',
      'name': 'Mason / Builder',
      'urdu': 'راج مستری',
      'icon': Icons.construction,
    },
  ];

  // ── Common skills per category (worker setup, job posting, job filters) ─
  static const Map<String, List<String>> skillSuggestions = {
    'electrician': ['House wiring', 'DB / breaker boards', 'Fans & lights', 'UPS installation', 'Fault finding'],
    'plumber': ['Leak repair', 'Pipe fitting', 'Water tank', 'Geyser installation', 'Bathroom fittings'],
    'ac_technician': ['AC installation', 'AC service', 'Gas refill', 'Inverter AC repair'],
    'solar_installer': ['Solar panels', 'Inverter setup', 'Net metering', 'Battery banks'],
    'generator_ups': ['Generator repair', 'UPS repair', 'Battery replacement'],
    'mechanic': ['Car repair', 'Motorbike repair', 'Engine tuning'],
    'painter': ['Wall paint', 'Distemper', 'Wood polish', 'Waterproofing'],
    'carpenter': ['Furniture repair', 'Doors & windows', 'Kitchen cabinets', 'Wood polish'],
    'tutor': ['Mathematics', 'Science', 'English', 'Quran'],
    'driver': ['City driving', 'Long route', 'Pick & drop'],
    'cleaner': ['Deep cleaning', 'Sofa cleaning', 'Water tank cleaning'],
    'mason': ['Brick work', 'Plaster', 'Tile fixing', 'Renovation'],
  };

  /// Category map by id (null for unknown/legacy ids).
  static Map<String, dynamic>? categoryById(String id) {
    for (final c in categories) {
      if (c['id'] == id) return c;
    }
    return null;
  }

  // ── Pakistani Cities & Coordinates ─────────────────────────────────────
  static const List<Map<String, dynamic>> cities = [
    {'name': 'All Cities', 'lat': 33.6844, 'lng': 73.0479},
    {'name': 'Islamabad', 'lat': 33.6844, 'lng': 73.0479},
    {'name': 'Rawalpindi', 'lat': 33.5973, 'lng': 73.0479},
    {'name': 'Lahore', 'lat': 31.5204, 'lng': 74.3587},
    {'name': 'Karachi', 'lat': 24.8607, 'lng': 67.0011},
    {'name': 'Peshawar', 'lat': 34.0151, 'lng': 71.5249},
    {'name': 'Quetta', 'lat': 30.1798, 'lng': 66.9750},
    {'name': 'Multan', 'lat': 30.1575, 'lng': 71.5249},
    {'name': 'Faisalabad', 'lat': 31.4504, 'lng': 73.1350},
    {'name': 'Sialkot', 'lat': 32.4927, 'lng': 74.5310},
    {'name': 'Gujranwala', 'lat': 32.1617, 'lng': 74.1883},
  ];

  static List<String> get majorCities => cities
      .where((c) => c['name'] != 'All Cities')
      .map((c) => c['name'] as String)
      .toList();

  // ── Payment Methods ────────────────────────────────────────────────────
  static const List<Map<String, dynamic>> paymentMethods = [
    {
      'id': 'jazzcash',
      'name': 'JazzCash Mobile Account',
      'shortName': 'JazzCash',
      'icon': Icons.phone_android,
      'color': 0xFFE2001A,
      'requiresPhone': true,
      'accountHint': '+92 300 1234567',
    },
    {
      'id': 'easypaisa',
      'name': 'EasyPaisa Wallet',
      'shortName': 'EasyPaisa',
      'icon': Icons.account_balance_wallet,
      'color': 0xFF00A950,
      'requiresPhone': true,
      'accountHint': '+92 345 1234567',
    },
    {
      'id': 'raast_qr',
      'name': 'Raast / IBFT Instant QR',
      'shortName': 'Raast QR',
      'icon': Icons.qr_code_scanner_rounded,
      'color': 0xFF006622,
      'requiresPhone': false,
      'details':
          'Raast ID: 0300-1234567\nBank: Meezan Bank Ltd\nTitle: Skill Bridge Escrow PK\nIBAN: PK29MEZN00012345678901',
    },
    {
      'id': 'card',
      'name': 'Debit / Credit Card',
      'shortName': 'Card',
      'icon': Icons.credit_card,
      'color': 0xFF4A154B,
      'requiresPhone': false,
    },
    {
      'id': 'cod',
      'name': 'Cash on Completion',
      'shortName': 'Cash',
      'icon': Icons.payments_outlined,
      'color': 0xFF333333,
      'requiresPhone': false,
    },
  ];
}
