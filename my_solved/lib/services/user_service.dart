import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum UserState { unknown, loggedIn, loading }

class UserService extends ChangeNotifier {
  static final UserService _instance = UserService._privateConstructor();
  UserState state = UserState.loading;

  String name = '';
  int streakTheme = 0;
  bool isIllustration = true;
  bool showTierIcon = true;
  bool showTags = true;
  int searchDefaultOpt = 0;
  bool searchDefaultSort = true;

  bool _disposed = false;

  UserService._privateConstructor() {
    Future<String> initName = initUserName();
    initName.then((name) {
      this.name = name;
      if (name.isNotEmpty) {
        state = UserState.loggedIn;
      } else {
        state = UserState.unknown;
      }
      notifyListeners();
    });

    Future<int> initStreak = initStreakTheme();
    initStreak.then((theme) {
      streakTheme = theme;
      notifyListeners();
    });

    Future<bool> initIllust = initIllustration();
    initIllust.then((isOn) {
      isIllustration = isOn;
      notifyListeners();
    });

    Future<bool> initTier = initTierIcon();
    initTier.then((isOn) {
      showTierIcon = isOn;
      notifyListeners();
    });
  }

  factory UserService() {
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

  void setUserName(String name) async {
    this.name = name;
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('username', name);
    notifyListeners();
  }

  Future<String> initUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('username') ?? '';
  }

  void logout() async {
    state = UserState.unknown;
    name = '';
    streakTheme = 0;
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('username');
    notifyListeners();
  }

  Future<int> initStreakTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('streak') ?? 0;
  }

  void setStreakTheme(int theme) async {
    streakTheme = theme;
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('streak', theme);
    notifyListeners();
  }

  Future<bool> initIllustration() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isIllust') ?? true;
  }

  void setIllustration(bool isOn) async {
    isIllustration = isOn;
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isIllust', isOn);
    notifyListeners();
  }

  Future<bool> initTierIcon() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('showTierIcon') ?? true;
  }

  void setTierIcon(bool isOn) async {
    showTierIcon = isOn;
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('showTierIcon', isOn);
    notifyListeners();
  }

  Future<bool> initTags() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('showTags') ?? true;
  }

  void setTags(bool isOn) async {
    showTags = isOn;
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('showTags', isOn);
    notifyListeners();
  }

  Future<int> initSearchDefaultOpt() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('searchDefaultOpt') ?? 0;
  }

  void setSearchDefaultOpt(int opt) async {
    searchDefaultOpt = opt;
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('searchDefaultOpt', opt);
    notifyListeners();
  }

  Future<bool> initSearchDefaultSort() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('searchDefaultSort') ?? true;
  }

  void setSearchDefaultSort(bool isAsc) async {
    searchDefaultSort = isAsc;
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('searchDefaultSort', isAsc);
    notifyListeners();
  }
}
