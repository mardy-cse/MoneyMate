import 'package:flutter/foundation.dart';
import '../models/category_suggestion.dart';

/// AI-powered expense categorization service
/// Suggests categories based on expense title using keyword matching and pattern recognition
class AiCategorizationService {
  // Singleton pattern
  static final AiCategorizationService _instance =
      AiCategorizationService._internal();
  factory AiCategorizationService() => _instance;
  AiCategorizationService._internal();

  // Category keywords database (Bangla + English)
  final Map<String, List<String>> _categoryKeywords = {
    'Food': [
      // Bangla keywords
      'খাবার', 'খাদ্য', 'রেস্টুরেন্ট', 'হোটেল', 'বিরিয়ানি', 'চা', 'কফি',
      'নাস্তা', 'দুপুরের খাবার', 'রাতের খাবার', 'ফাস্টফুড', 'পিৎজা',
      'বার্গার', 'চাইনিজ', 'দোকান', 'বেকারি', 'মিষ্টি', 'পান', 'ফল',
      // English keywords
      'food', 'restaurant', 'cafe', 'coffee', 'tea', 'breakfast', 'lunch',
      'dinner', 'meal', 'pizza', 'burger', 'kfc', 'mcdonald', 'dominos',
      'fastfood', 'bakery', 'grocery', 'fruit', 'vegetable', 'rice', 'chicken',
      'fish', 'meat', 'snack', 'sweet', 'chocolate', 'ice cream', 'juice',
      'water', 'drink', 'buffet', 'hotel', 'canteen', 'tiffin', 'biryani',
    ],
    'Transport': [
      // Bangla keywords
      'রিকশা', 'ট্যাক্সি', 'বাস', 'ট্রেন', 'সিএনজি', 'অটো', 'ভাড়া',
      'পেট্রোল', 'জ্বালানি', 'পার্কিং', 'টোল', 'উবার', 'পাঠাও',
      // English keywords
      'rickshaw', 'taxi', 'cab', 'bus', 'train', 'cng', 'auto', 'uber',
      'pathao', 'obhai', 'shohoz', 'fuel', 'petrol', 'gas', 'diesel',
      'parking', 'toll', 'fare', 'transport', 'travel', 'metro', 'bike',
      'scooter', 'car', 'vehicle', 'ride', 'trip', 'commute',
    ],
    'Shopping': [
      // Bangla keywords
      'কেনাকাটা', 'কিনলাম', 'দোকান', 'মার্কেট', 'বাজার', 'কাপড়', 'জুতা',
      'ব্যাগ', 'মোবাইল', 'ইলেকট্রনিক্স', 'আসবাবপত্র',
      // English keywords
      'shopping', 'bought', 'purchase', 'shop', 'store', 'mall', 'market',
      'bazar', 'clothes', 'shirt', 'pant', 'dress', 'shoes', 'bag',
      'mobile', 'phone', 'laptop', 'electronics', 'gadget', 'furniture',
      'amazon', 'daraz', 'evaly', 'pickaboo', 'online', 'order',
    ],
    'Bills': [
      // Bangla keywords
      'বিল', 'বিদ্যুৎ', 'গ্যাস', 'পানি', 'ইন্টারনেট', 'মোবাইল রিচার্জ',
      'ভাড়া', 'বাসা ভাড়া',
      // English keywords
      'bill', 'electricity', 'electric', 'gas', 'water', 'internet',
      'wifi', 'broadband', 'mobile', 'recharge', 'rent', 'house rent',
      'utility', 'cable', 'tv', 'subscription', 'netflix', 'spotify',
      'youtube', 'premium',
    ],
    'Healthcare': [
      // Bangla keywords
      'ডাক্তার', 'হাসপাতাল', 'ক্লিনিক', 'ওষুধ', 'মেডিসিন', 'চিকিৎসা',
      'টেস্ট', 'এক্সরে', 'ফার্মেসি',
      // English keywords
      'doctor', 'hospital', 'clinic', 'medical', 'medicine', 'pharmacy',
      'drug', 'test', 'xray', 'scan', 'checkup', 'health', 'treatment',
      'prescription', 'dental', 'dentist', 'eye', 'optician', 'lab',
    ],
    'Education': [
      // Bangla keywords
      'বই', 'খাতা', 'কলম', 'পেন্সিল', 'স্কুল', 'কলেজ', 'বিশ্ববিদ্যালয়',
      'টিউশন', 'কোর্স', 'ক্লাস', 'পড়াশোনা', 'পরীক্ষা', 'ফি',
      // English keywords
      'book', 'notebook', 'pen', 'pencil', 'school', 'college', 'university',
      'tuition', 'course', 'class', 'study', 'education', 'exam', 'fee',
      'library', 'stationary', 'syllabus', 'tutorial', 'learning', 'training',
      'rokomari', 'online course', 'udemy', 'coursera',
    ],
    'Entertainment': [
      // Bangla keywords
      'সিনেমা', 'মুভি', 'গেম', 'খেলা', 'পার্ক', 'বিনোদন', 'কনসার্ট',
      'থিয়েটার', 'পিকনিক',
      // English keywords
      'movie', 'cinema', 'game', 'gaming', 'play', 'park', 'entertainment',
      'concert', 'show', 'theatre', 'picnic', 'tour', 'tourist', 'zoo',
      'museum', 'sports', 'gym', 'fitness', 'hobby', 'fun', 'party',
      'celebration', 'event', 'ticket', 'steam', 'playstation', 'xbox',
    ],
    'Personal Care': [
      // Bangla keywords
      'সেলুন', 'চুল', 'দাড়ি', 'সৌন্দর্য', 'প্রসাধনী', 'শ্যাম্পু', 'সাবান',
      'ক্রিম', 'পারফিউম',
      // English keywords
      'salon', 'barber', 'haircut', 'shave', 'beauty', 'cosmetic', 'makeup',
      'shampoo', 'soap', 'cream', 'lotion', 'perfume', 'deodorant', 'spa',
      'grooming', 'skincare', 'facial', 'massage', 'parlour',
    ],
    'Gift': [
      // Bangla keywords
      'উপহার', 'গিফট', 'উপঢৌকন', 'দান', 'সাহায্য', 'জন্মদিন', 'বিবাহ',
      // English keywords
      'gift', 'present', 'donation', 'charity', 'help', 'birthday', 'wedding',
      'anniversary', 'celebration', 'reward', 'prize', 'bonus', 'surprise',
    ],
    'Other': [
      // Fallback category
      'অন্যান্য', 'বিবিধ', 'other', 'misc', 'miscellaneous', 'various',
    ],
  };

  // Common expense patterns for better detection
  final Map<String, RegExp> _patterns = {
    'Food': RegExp(
      r'(খাবার|খাদ্য|রেস্টুরেন্ট|food|restaurant|cafe|lunch|dinner|breakfast)',
      caseSensitive: false,
    ),
    'Transport': RegExp(
      r'(রিকশা|ভাড়া|rickshaw|taxi|uber|pathao|transport|fuel|petrol)',
      caseSensitive: false,
    ),
    'Shopping': RegExp(
      r'(কিনলাম|কেনা|shopping|bought|purchase|order|mall)',
      caseSensitive: false,
    ),
    'Bills': RegExp(
      r'(বিল|bill|rent|electricity|gas|internet|recharge)',
      caseSensitive: false,
    ),
    'Healthcare': RegExp(
      r'(ডাক্তার|ওষুধ|doctor|hospital|medicine|medical|health)',
      caseSensitive: false,
    ),
    'Education': RegExp(
      r'(বই|টিউশন|book|tuition|course|school|college|university)',
      caseSensitive: false,
    ),
    'Entertainment': RegExp(
      r'(সিনেমা|গেম|movie|game|entertainment|concert|ticket)',
      caseSensitive: false,
    ),
  };

  /// Suggest category based on expense title
  /// Returns the most likely category or 'Other' if uncertain
  String suggestCategory(String title) {
    if (title.trim().isEmpty) {
      return 'Other';
    }

    final normalizedTitle = title.toLowerCase().trim();
    final scores = <String, int>{};

    // Calculate scores for each category
    for (final category in _categoryKeywords.keys) {
      int score = 0;

      // Check keyword matches
      final keywords = _categoryKeywords[category]!;
      for (final keyword in keywords) {
        if (normalizedTitle.contains(keyword.toLowerCase())) {
          // Exact word match gets higher score
          if (normalizedTitle == keyword.toLowerCase()) {
            score += 10;
          } else if (normalizedTitle
              .split(' ')
              .contains(keyword.toLowerCase())) {
            score += 5;
          } else {
            score += 2;
          }
        }
      }

      // Check pattern matches
      if (_patterns.containsKey(category)) {
        if (_patterns[category]!.hasMatch(normalizedTitle)) {
          score += 3;
        }
      }

      if (score > 0) {
        scores[category] = score;
      }
    }

    // Return category with highest score
    if (scores.isEmpty) {
      return 'Other';
    }

    final sortedCategories = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedCategories.first.key;
  }

  /// Get top 3 category suggestions with confidence scores
  /// Returns list of suggestions sorted by confidence
  List<CategorySuggestion> getSuggestions(String title) {
    if (title.trim().isEmpty) {
      return [CategorySuggestion('Other', 1.0)];
    }

    final normalizedTitle = title.toLowerCase().trim();
    final scores = <String, int>{};

    // Calculate scores for each category (excluding 'Other')
    for (final category in _categoryKeywords.keys) {
      if (category == 'Other') continue;

      int score = 0;
      final keywords = _categoryKeywords[category]!;

      for (final keyword in keywords) {
        if (normalizedTitle.contains(keyword.toLowerCase())) {
          if (normalizedTitle == keyword.toLowerCase()) {
            score += 10;
          } else if (normalizedTitle
              .split(' ')
              .contains(keyword.toLowerCase())) {
            score += 5;
          } else {
            score += 2;
          }
        }
      }

      if (_patterns.containsKey(category)) {
        if (_patterns[category]!.hasMatch(normalizedTitle)) {
          score += 3;
        }
      }

      if (score > 0) {
        scores[category] = score;
      }
    }

    if (scores.isEmpty) {
      return [CategorySuggestion('Other', 1.0)];
    }

    // Sort by score
    final sortedScores = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Calculate confidence scores (normalize to 0-1 range)
    final maxScore = sortedScores.first.value.toDouble();
    final suggestions = sortedScores.take(3).map((entry) {
      final confidence = entry.value / maxScore;
      return CategorySuggestion(entry.key, confidence);
    }).toList();

    return suggestions;
  }

  /// Add custom keyword to a category
  /// Useful for learning user preferences
  void addCustomKeyword(String category, String keyword) {
    if (_categoryKeywords.containsKey(category)) {
      if (!_categoryKeywords[category]!.contains(keyword.toLowerCase())) {
        _categoryKeywords[category]!.add(keyword.toLowerCase());
        debugPrint('Added custom keyword: $keyword -> $category');
      }
    }
  }

  /// Learn from user corrections
  /// When user changes suggested category, learn that pattern
  void learnFromCorrection(String title, String correctCategory) {
    final words = title.toLowerCase().split(' ');
    for (final word in words) {
      if (word.length > 2) {
        // Only meaningful words
        addCustomKeyword(correctCategory, word);
      }
    }
  }

  /// Get all available categories
  List<String> getAvailableCategories() {
    return _categoryKeywords.keys.toList();
  }

  /// Check if a category exists
  bool categoryExists(String category) {
    return _categoryKeywords.containsKey(category);
  }
}
