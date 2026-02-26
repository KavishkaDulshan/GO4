import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';
import '../models/history_item.dart';
import '../models/search_result.dart';

enum SearchStatus { idle, processing, success, error }

class SearchState {
  final SearchStatus status;
  final SearchResult? result;
  final String? errorMessage;
  final String? capturedImagePath;
  final String? capturedAudioPath;

  const SearchState({
    this.status = SearchStatus.idle,
    this.result,
    this.errorMessage,
    this.capturedImagePath,
    this.capturedAudioPath,
  });

  SearchState copyWith({
    SearchStatus? status,
    SearchResult? result,
    String? errorMessage,
    String? capturedImagePath,
    String? capturedAudioPath,
  }) =>
      SearchState(
        status: status ?? this.status,
        result: result ?? this.result,
        errorMessage: errorMessage ?? this.errorMessage,
        capturedImagePath: capturedImagePath ?? this.capturedImagePath,
        capturedAudioPath: capturedAudioPath ?? this.capturedAudioPath,
      );
}

class SearchNotifier extends StateNotifier<SearchState> {
  SearchNotifier() : super(const SearchState());

  void captureImage(String path) =>
      state = state.copyWith(capturedImagePath: path);

  void captureAudio(String path) =>
      state = state.copyWith(capturedAudioPath: path);

  void clearAudio() => state = SearchState(
        capturedImagePath: state.capturedImagePath,
      );

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
        status: SearchStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  void reset() => state = const SearchState();

  /// Load a [HistoryItem] into state so the results screen can display it.
  void loadHistory(HistoryItem item) {
    final result = SearchResult(
      searchId: item.searchId,
      tags: item.tags,
      results: item.results,
    );
    state = SearchState(status: SearchStatus.success, result: result);
  }
}

final searchProvider =
    StateNotifierProvider<SearchNotifier, SearchState>((_) => SearchNotifier());
