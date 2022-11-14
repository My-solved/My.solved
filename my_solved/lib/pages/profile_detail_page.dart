import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_solved/view_models/profile_detail_view_model.dart';
import 'package:my_solved/views/profile_detail_view.dart';

class ProfileDetailPage extends StatelessWidget {
  late String handle;

  ProfileDetailPage(this.handle);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ProfileDetailViewModel>(
      create: (_) => ProfileDetailViewModel(handle),
      child: ProfileDetailView(),
    );
  }
}
