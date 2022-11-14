import 'package:flutter/cupertino.dart';
import 'package:my_solved/view_models/home_view_model.dart';
import 'package:my_solved/views/home_view.dart';
import 'package:provider/provider.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<HomeViewModel>(
      create: (_) => HomeViewModel(),
      child: HomeView(),
    );
  }
}
