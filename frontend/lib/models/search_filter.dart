class SearchFilterOption {
  final String value;
  final String label;

  const SearchFilterOption({required this.value, required this.label});

  factory SearchFilterOption.fromJson(Map<String, dynamic> json) =>
      SearchFilterOption(
        value: json['value'] as String? ?? '',
        label: json['label'] as String? ?? '',
      );
}

/// A single AI-generated filter with a currently selected value.
class SearchFilter {
  final String key;
  final String label;

  /// 'dropdown' or 'chips'
  final String type;
  final List<SearchFilterOption> options;
  final String? defaultValue;

  /// Mutable — updated when the user taps a chip or picks a dropdown item.
  String? selectedValue;

  SearchFilter({
    required this.key,
    required this.label,
    required this.type,
    required this.options,
    this.defaultValue,
    this.selectedValue,
  });

  factory SearchFilter.fromJson(Map<String, dynamic> json) {
    final opts = (json['options'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(SearchFilterOption.fromJson)
        .toList();

    final defaultVal = json['defaultValue'] as String?;
    return SearchFilter(
      key: json['key'] as String? ?? '',
      label: json['label'] as String? ?? '',
      type: json['type'] as String? ?? 'chips',
      options: opts,
      defaultValue: defaultVal,
      selectedValue: defaultVal,
    );
  }
}

/// Result returned by the /analyze endpoint.
class AnalyzeResult {
  final Map<String, dynamic> tags;
  final List<SearchFilter> filters;

  const AnalyzeResult({required this.tags, required this.filters});

  factory AnalyzeResult.fromJson(Map<String, dynamic> json) => AnalyzeResult(
        tags: json['tags'] as Map<String, dynamic>? ?? {},
        filters: (json['filters'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(SearchFilter.fromJson)
            .toList(),
      );
}
