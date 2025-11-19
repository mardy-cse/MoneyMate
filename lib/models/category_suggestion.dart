/// Category suggestion with confidence score
/// Used by AI categorization to suggest expense categories
class CategorySuggestion {
  final String category;
  final double confidence; // 0.0 to 1.0

  CategorySuggestion(this.category, this.confidence);

  /// Get confidence as percentage
  int get confidencePercentage => (confidence * 100).round();

  /// Get confidence level description
  String get confidenceLevel {
    if (confidence >= 0.8) return 'High';
    if (confidence >= 0.5) return 'Medium';
    return 'Low';
  }

  @override
  String toString() => '$category ($confidencePercentage%)';
}
