import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bottom navigation index (0 home, 1 quran, 2 azkar, 3 qiyam, 4 calendar)
final tabIndexProvider = StateProvider<int>((ref) => 0);

/// Selected azkar category (0 morning, 1 evening, 2 sleep, 3 after prayer)
final azkarCategoryProvider = StateProvider<int>((ref) => 0);
