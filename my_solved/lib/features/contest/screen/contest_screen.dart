import 'package:flutter/material.dart';

class ContestScreen extends StatelessWidget {
  const ContestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ContestView();
  }
}

class ContestView extends StatefulWidget {
  const ContestView({super.key});

  @override
  State<ContestView> createState() => _ContestViewState();
}

class _ContestViewState extends State<ContestView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text("Contest View"),
      ),
    );
  }
}
