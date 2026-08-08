/// Mapping of Roman Urdu slang, Urdu keywords, and common trade terms to official SkillBridge Categories.
class PakistaniTradeSynonyms {
  static const Map<String, List<String>> categorySynonyms = {
    'Electrician': [
      'bijli',
      'wire',
      'wiring',
      'switch',
      'board',
      'breaker',
      'light',
      'fan',
      'ups',
      'inverter',
      'short circuit',
      'electrician',
      'bijli wala',
    ],
    'Plumber': [
      'null',
      'nalka',
      'pipe',
      'leak',
      'leakage',
      'water',
      'motor',
      'tanki',
      'sewerage',
      'drain',
      'plumber',
      'nalke wala',
    ],
    'AC Technician': [
      'ac',
      'air conditioner',
      'cooling',
      'gas',
      'compressor',
      'split',
      'service',
      'chiller',
      'ac technician',
      'ac wala',
    ],
    'Carpenter': [
      'wood',
      'lakri',
      'khati',
      'door',
      'table',
      'chair',
      'cabinet',
      'furniture',
      'lock',
      'carpenter',
      'lakri wala',
    ],
    'Painter': [
      'rang',
      'paint',
      'painter',
      'whitewash',
      'wall',
      'putty',
      'distemper',
      'enamel',
      'rang wala',
    ],
    'Mason (Mistri)': [
      'mistri',
      'mason',
      'cement',
      'brick',
      'wall',
      'floor',
      'plaster',
      'construction',
      'marwa',
      'raj mistri',
    ],
    'Home Appliance Repair': [
      'fridge',
      'refrigerator',
      'washing machine',
      'oven',
      'microwave',
      'appliance',
      'iron',
      'repair',
    ],
    'Cleaner': [
      'safai',
      'cleaner',
      'cleaning',
      'wash',
      'broom',
      'mop',
      'home clean',
      'safai wala',
    ],
    'Driver': [
      'driver',
      'car',
      'gaari',
      'driving',
      'chaufuer',
      'vehicle',
      'driver wala',
    ],
    'Welder': [
      'weld',
      'welder',
      'steel',
      'iron gate',
      'grill',
      'metal',
      'welding',
    ],
    'Solar Installer': [
      'solar',
      'panel',
      'inverter',
      'battery',
      'plate',
      'solar installer',
    ],
    'Pest Control': [
      'pest',
      'cockroach',
      'termite',
      'dimak',
      'spray',
      'insect',
      'pest control',
    ],
  };

  /// Returns the matching official trade category for a given Roman Urdu / English text or keyword.
  /// Returns null if no strong keyword match is found.
  static String? matchCategory(String query) {
    if (query.trim().isEmpty) return null;
    final lower = query.toLowerCase();

    for (final entry in categorySynonyms.entries) {
      final category = entry.key;
      final keywords = entry.value;

      for (final kw in keywords) {
        if (lower.contains(kw) || kw.contains(lower)) {
          return category;
        }
      }
    }
    return null;
  }

  /// Suggests a fair Pakistani market PKR budget range (min, max) for a trade category.
  static ({int minPkr, int maxPkr}) suggestBudgetRange(String category) {
    switch (category) {
      case 'Electrician':
        return (minPkr: 1500, maxPkr: 4000);
      case 'Plumber':
        return (minPkr: 1200, maxPkr: 3500);
      case 'AC Technician':
        return (minPkr: 2500, maxPkr: 6000);
      case 'Carpenter':
        return (minPkr: 2000, maxPkr: 7000);
      case 'Painter':
        return (minPkr: 5000, maxPkr: 25000);
      case 'Mason (Mistri)':
        return (minPkr: 3000, maxPkr: 10000);
      case 'Solar Installer':
        return (minPkr: 8000, maxPkr: 35000);
      default:
        return (minPkr: 1500, maxPkr: 5000);
    }
  }
}
