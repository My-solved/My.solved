import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_solved/view_models/profile_view_model.dart';
import 'package:my_solved/views/profile_view.dart';

class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ProfileViewModel>(
      create: (_) => ProfileViewModel(),
      child: ProfileView(),
    );
  }
}
