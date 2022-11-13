import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../views/main_tab_view.dart';
import '../view_models/main_tab_view_model.dart';

class MainTabPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<MainTabViewModel>(
      create: (_) => MainTabViewModel(),
      child: MainTabView(),
    );
  }
}
