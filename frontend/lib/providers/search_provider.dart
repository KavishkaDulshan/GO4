import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';
import '../models/history_item.dart';
import '../models/search_filter.dart';
import '../models/search_result.dart';

enum SearchStatus { idle, analyzing, analyzed, processing, success, error }

class SearchState {
  final SearchStatus status;
  final SearchResult? result;
  final String? errorMessage;
  final String? capturedImagePath;
  final String? capturedAudioPath;

  /// Optional plain-text query entered via the keyboard search sheet.
  final String? capturedText;

  /// Tags returned by the analyze step (used to build the final search query).
  final Map<String, dynamic>? analyzedTags;

  /// AI-generated filters populated after the analyze step.
  final List<SearchFilter>? pendingFilters;

  const SearchState({
    this.status = SearchStatus.idle,
    this.result,
    this.errorMessage,
    this.capturedImagePath,
    this.capturedAudioPath,
    this.capturedText,
    this.analyzedTags,
    this.pendingFilters,
  });

  SearchState copyWith({
    SearchStatus? status,
    SearchResult? result,
    String? errorMessage,
    String? capturedImagePath,
    String? capturedAudioPath,
    String? capturedText,
    Map<String, dynamic>? analyzedTags,
    List<SearchFilter>? pendingFilters,
  }) =>
      SearchState(
        status:            status            ?? this.status,
        result:            result            ?? this.result,
        errorMessage:      errorMessage      ?? this.errorMessage,
        capturedImagePath: capturedImagePath ?? this.capturedImagePath,
        capturedAudioPath: capturedAudioPath ?? this.capturedAudioPath,
        capturedText:      capturedText      ?? this.capturedText,
        analyzedTags:      analyzedTags      ?? this.analyzedTags,
        pendingFilters:    pendingFilters    ?? this.pendingFilters,
      );

  /// True when the user has at least one input ready.
  bool get hasInput =>
      capturedImagePath != null || capturedAudioPath != null ||
      (capturedText != null && capturedText!.isNotEmpty);
}

class SearchNotifier extends StateNotifier<SearchState> {
  SearchNotifier() : super(const SearchState());

  void captureImage(String path) =>
      state = state.copyWith(capturedImagePath: path);

  void captureAudio(String path) =>
      state = state.copyWith(capturedAudioPath: path);

  void captureText(String text) =>
      state = state.copyWith(capturedText: text);

  void clearAudio() => state = SearchState(
        capturedImagePath: state.capturedImagePath,
        capturedText:      state.capturedText,
      );

  void clearImage() => state = SearchState(
        capturedAudioPath: state.capturedAudioPath,
        capturedText:      state.capturedText,
      );

  void clearText() => state = SearchState(
        capturedImagePath: state.capturedImagePath,
        capturedAudioPath: state.capturedAudioPath,
      );

  // ── Step 1: Analyze inputs → tags + smart filters ─────────────────────────

  Future<void> analyzeInputs() async {
    state = state.copyWith(status: SearchStatus.analyzing);
    try {
      final analyzeResult = await ApiClient.instance.analyzeSearch(
        imagePath: state.capturedImagePath,
        audioPath: state.capturedAudioPath,
        query:     state.capturedText,
      );

      state = state.copyWith(
        status:         SearchStatus.analyzed,
        analyzedTags:   analyzeResult.tags,
        pendingFilters: analyzeResult.filters,
      );
    } catch (e) {
      state = state.copyWith(
        status:       SearchStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  // ── Step 2: Submit with selected filters → product results ────────────────

  Future<void> submitWithFilters(List<SearchFilter> filters) async {
    state = state.copyWith(status: SearchStatus.processing);
    try {
      // Build enriched query: base Gemini query + all selected filter values.
      final base = (state.analyzedTags?['searchQuery'] as String? ?? '').trim();
      final extras = filters
          .expand((f) => f.selectedValues)
          .where((v) => v.isNotEmpty)
          .toList();

      final enrichedQuery = extras.isEmpty ? base : '$base ${extras.join(' ')}';

      // Do NOT re-send image or audio — that would trigger Gemini re-analysis
      // and overwrite the filter-enriched query.
      final result = await ApiClient.instance.search(
        query: enrichedQuery.isEmpty ? null : enrichedQuery,
      );
      state = state.copyWith(status: SearchStatus.success, result: result);
    } catch (e) {
      state = state.copyWith(
        status:       SearchStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  // ── Legacy direct search ──────────────────────────────────────────────────

  Future<void> submitSearch() async {
    state = state.copyWith(status: SearchStatus.processing);
    try {
      final result = await ApiClient.instance.search(
        imagePath: state.capturedImagePath,
        audioPath: state.capturedAudioPath,
      );
      state = state.copyWith(status: SearchStatus.success, result: result);
    } catch (e) {
      state = state.copyWith(
        status:       SearchStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  void reset() => state = const SearchState();

  /// Load a [HistoryItem] into state so the results screen can display it.
  void loadHistory(HistoryItem item) {
    final result = SearchResult(
      searchId: item.searchId,
      tags:     item.tags,
      results:  item.results,
    );
    state = SearchState(status: SearchStatus.success, result: result);
  }
}

final searchProvider =
    StateNotifierProvider<SearchNotifier, SearchState>((_) => SearchNotifier());
