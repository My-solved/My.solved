import 'package:flutter/cupertino.dart';

class ContestFilterScreen extends StatelessWidget {
  const ContestFilterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ContestFilterView();
  }
}

class ContestFilterView extends StatefulWidget {
  const ContestFilterView({super.key});

  @override
  State<ContestFilterView> createState() => _ContestFilterViewState();
}

class _ContestFilterViewState extends State<ContestFilterView> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text("Contest Filter"),
    );
  }
}
