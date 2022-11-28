import 'package:flutter/cupertino.dart';
import 'package:my_solved/view_models/login_view_model.dart';
import 'package:my_solved/views/login_view.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<LoginViewModel>(
      create: (_) => LoginViewModel(),
      child: LoginView(),
    );
  }
}
