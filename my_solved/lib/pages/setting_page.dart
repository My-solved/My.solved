import 'package:flutter/cupertino.dart';
import 'package:my_solved/view_models/setting_view_model.dart';
import 'package:my_solved/views/setting_view.dart';
import 'package:provider/provider.dart';

class SettingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SettingViewModel>(
      create: (_) => SettingViewModel(),
      child: SettingView(),
    );
  }
}
