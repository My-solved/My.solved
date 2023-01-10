import 'package:flutter/material.dart';
import 'package:my_solved/models/User.dart';
import 'package:my_solved/models/user/Top_100.dart';
import 'package:my_solved/providers/user/show_api.dart';
import 'package:my_solved/providers/user/top_100_api.dart';

import '../models/user/Badges.dart';
import '../models/user/TagRatings.dart';
import '../providers/user/available_badges_api.dart';
import '../providers/user/tag_ratings_api.dart';

class ProfileDetailViewModel with ChangeNotifier {
  String handle = '';
  Future<User>? future;
  Future<Top_100>? futureTop;
  Future<Badges>? futureBadges;
  Future<List<TagRatings>>? futureTagRatings;

  ProfileDetailViewModel(this.handle) {
    future = userShow(handle);
    futureTop = top_100(handle);
    futureBadges = availableBadges(handle);
    futureTagRatings = tagRatings(handle);
    notifyListeners();
  }
}
