import 'package:flutter/cupertino.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum UserState { unknown, loggedIn, loading }

class UserService extends ChangeNotifier {
  static final UserService _instance = UserService._privateConstructor();
  UserState state = UserState.loading;

  String name = '';
  bool isIllustration = true;

  bool showTier = true;
  bool showTags = true;

  int searchDefaultOpt = 0;
  bool searchDefaultSort = true;

  bool isOnStreakAlarm = true;
  int streakAlarmHour = 0;
  int streakAlarmMinute = 0;

  bool isOnContestAlarm = true;
  int contestAlarmHour = 0;
  int contestAlarmMinute = 0;

  String currentTimeZone = '';
  bool solvedToday = false;

  int tagChartType = 0;
  int currentHomeTab = 0;
  int currentUserTab = 0;

  int userCount = 0;

  bool _disposed = false;

  UserService._privateConstructor() {
    Future<String> valUserName = initUserName();
    valUserName.then((name) {
      this.name = name;
      if (name.isNotEmpty) {
        state = UserState.loggedIn;
      } else {
        state = UserState.unknown;
      }
      notifyListeners();
    });

    Future<bool> valIllustration = initIllustration();
    valIllustration.then((isOn) {
      isIllustration = isOn;
    });

    Future<bool> valTier = initTier();
    valTier.then((isOn) {
      showTier = isOn;
    });

    Future<bool> valTags = initTags();
    valTags.then((isOn) {
      showTags = isOn;
    });

    Future<bool> valStreakAlarm = initStreakAlarm();
    valStreakAlarm.then((isOn) {
      isOnStreakAlarm = isOn;
    });

    Future<DateTime> valStreakAlarmTime = initStreakAlarmTime();
    valStreakAlarmTime.then((time) {
      streakAlarmHour = time.hour;
      streakAlarmMinute = time.minute;
    });

    Future<int> valSearchDefaultOpt = initSearchDefaultOpt();
    valSearchDefaultOpt.then((opt) {
      searchDefaultOpt = opt;
    });

    Future<bool> valSearchDefaultSort = initSearchDefaultSort();
    valSearchDefaultSort.then((isAsc) {
      searchDefaultSort = isAsc;
    });

    Future<bool> valContestAlarm = initContestAlarm();
    valContestAlarm.then((isOn) {
      isOnContestAlarm = isOn;
    });

    Future<DateTime> valContestAlarmTime = initContestAlarmTime();
    valContestAlarmTime.then((time) {
      contestAlarmHour = time.hour;
      contestAlarmMinute = time.minute;
    });

    Future<String> valTimeZone = FlutterNativeTimezone.getLocalTimezone();
    valTimeZone.then((zone) {
      currentTimeZone = zone;
    });

    Future<bool> valSolvedToday = initSolvedToday();
    valSolvedToday.then((isSolved) {
      solvedToday = isSolved;
    });

    Future<int> valTagChartType = initTagChartType();
    valTagChartType.then((type) {
      tagChartType = type;
    });

    Future<int> valHomeTab = initCurrentHomeTab();
    valHomeTab.then((tab) {
      currentHomeTab = tab;
    });

    Future<int> valUserTab = initCurrentUserTab();
    valUserTab.then((tab) {
      currentUserTab = tab;
    });

    Future<int> valUserCount = initUserCount();
    valUserCount.then((count) {
      userCount = count;
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

  void logout() async {
    state = UserState.unknown;
    name = '';
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('username');
    notifyListeners();
  }

  Future<String> initUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('username') ?? '';
  }

  void setUserName(String name) async {
    this.name = name;
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('username', name);
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

  Future<bool> initTier() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('showTier') ?? true;
  }

  void setTier(bool isOn) async {
    showTier = isOn;
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('showTier', isOn);
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

  Future<bool> initStreakAlarm() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isOnStreakAlarm') ?? true;
  }

  void setStreakAlarm(bool isOn) async {
    isOnStreakAlarm = isOn;
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isOnStreakAlarm', isOn);
    notifyListeners();
  }

  Future<DateTime> initStreakAlarmTime() async {
    final prefs = await SharedPreferences.getInstance();
    return DateTime(0, 0, 0, prefs.getInt('streakAlarmHour') ?? 0,
        prefs.getInt('streakAlarmMinute') ?? 0);
  }

  void setStreakAlarmTime(int hour, int minute) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('streakAlarmHour', hour);
    prefs.setInt('streakAlarmMinute', minute);
    notifyListeners();
  }

  Future<bool> initContestAlarm() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isOnContestAlarm') ?? true;
  }

  void setContestAlarm(bool isOn) async {
    isOnContestAlarm = isOn;
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isOnContestAlarm', isOn);
    notifyListeners();
  }

  Future<DateTime> initContestAlarmTime() async {
    final prefs = await SharedPreferences.getInstance();
    return DateTime(0, 0, 0, prefs.getInt('contestAlarmHour') ?? 0,
        prefs.getInt('contestAlarmMinute') ?? 0);
  }

  void setContestAlarmTime(int hour, int minute) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('contestAlarmHour', hour);
    prefs.setInt('contestAlarmMinute', minute);
    notifyListeners();
  }

  Future<bool> initSolvedToday() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('solvedToday') ?? true;
  }

  void setSolvedToday(bool solved) async {
    solvedToday = solved;
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('solvedToday', solved);
    notifyListeners();
  }

  Future<int> initTagChartType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('tagChartType') ?? 0;
  }

  void setTagChartType(int type) async {
    tagChartType = type;
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('tagChartType', type);
    notifyListeners();
  }

  Future<int> initCurrentHomeTab() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('currentHomeTab') ?? 0;
  }

  void setCurrentHomeTab(int tab) async {
    currentHomeTab = tab;
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('currentHomeTab', tab);
    notifyListeners();
  }

  Future<int> initCurrentUserTab() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('currentUserTab') ?? 0;
  }

  void setCurrentUserTab(int tab) async {
    currentUserTab = tab;
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('currentUserTab', tab);
    notifyListeners();
  }

  Future<int> initUserCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('userCount') ?? 0;
  }

  void setUserCount(int count) async {
    userCount = count;
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('userCount', count);
    notifyListeners();
  }
}
