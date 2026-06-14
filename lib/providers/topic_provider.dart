import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/kidio_models.dart';
import '../repositories/topic_repository.dart';
import '../local/cache_service.dart';

class TopicProvider extends ChangeNotifier {
  final TopicRepository repository;
  final CacheService cacheService;

  List<Topic> _topics = [];
  List<Topic> _filteredTopics = [];
  int _currentPage = 1;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  bool _isOffline = false;
  String? _errorMessage;
  String? _searchQuery;

  TopicProvider(this.repository, {CacheService? cacheService}) 
      : cacheService = cacheService ?? CacheService() {
    _initConnectivity();
  }

  void _initConnectivity() {
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      _isOffline = result == ConnectivityResult.none;
      notifyListeners();
    });
  }

  // Getters
  List<Topic> get topics => _searchQuery == null || _searchQuery!.isEmpty ? _topics : _filteredTopics;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => (_searchQuery == null || _searchQuery!.isEmpty) && _hasMore;
  bool get isOffline => _isOffline;
  String? get errorMessage => _errorMessage;
  String? get searchQuery => _searchQuery;

  void search(String? query) {
    _searchQuery = query;
    if (query == null || query.isEmpty) {
      _filteredTopics = [];
    } else {
      _filteredTopics = _topics
          .where((t) => t.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
    notifyListeners();
  }

  Future<void> loadFirstPage() async {
    _isLoading = true;
    _errorMessage = null;
    _currentPage = 1;
    notifyListeners();

    try {
      final result = await repository.fetchTopics(
        pageNumber: _currentPage,
      );
      _topics = result.items;
      _hasMore = _topics.length < result.totalCount;
      _isOffline = false;
      
      await cacheService.saveTopicsPage(_currentPage, result);
      
      // Update filtered list if searching
      if (_searchQuery != null && _searchQuery!.isNotEmpty) {
        search(_searchQuery);
      }
    } catch (e) {
      final cachedItems = cacheService.getTopicsPage(_currentPage);
      if (cachedItems != null) {
        _topics = cachedItems;
        _hasMore = _topics.length < cacheService.getTotalCountForPage(_currentPage);
        _isOffline = true;
        _errorMessage = null;
      } else {
        _errorMessage = e.toString();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore || _isOffline) return;

    _isLoadingMore = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      final result = await repository.fetchTopics(
        pageNumber: nextPage,
        q: _searchQuery,
      );

      if (result.items.isNotEmpty) {
        _topics.addAll(result.items);
        _currentPage = nextPage;
        _hasMore = _topics.length < result.totalCount;
        if (_searchQuery == null || _searchQuery!.isEmpty) {
          await cacheService.saveTopicsPage(_currentPage, result);
        }
      } else {
        _hasMore = false;
      }
    } catch (e) {
      _errorMessage = "Failed to load more: ${e.toString()}";
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => loadFirstPage();
}
