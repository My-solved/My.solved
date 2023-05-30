import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ContestService extends ChangeNotifier {
  static final ContestService _instance = ContestService._privateConstructor();

  ContestService._privateConstructor() {
    init();
  }

  bool _disposed = false;

  Map showVenues = {
    'AtCoder': false,
    'BOJ Open': false,
    'Codeforces': false,
    'Programmers': false,
    'Others': false,
  };

  factory ContestService() {
    return _instance;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }

  Future<void> init() async {
    await _initializeContest();
  }

  Future<void> _initializeContest() async {
    initContestShow();
  }

  Future<void> initContestShow() async {
    final prefs = await SharedPreferences.getInstance();
    for (var venue in showVenues.keys) {
      final show = prefs.getBool('show$venue') ?? true;
      showVenues[venue] = show;
    }
    notifyListeners();
  }

  Future<void> toggleContestShow(String venue) async {
    final prefs = await SharedPreferences.getInstance();
    final show = prefs.getBool('show$venue') ?? false;
    showVenues[venue] = !show;
    prefs.setBool('show$venue', !show);
    notifyListeners();
  }
}
