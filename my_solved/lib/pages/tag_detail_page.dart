import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/tag_detail_view_model.dart';
import '../views/tag_detail_view.dart';

class TagDetailPage extends StatelessWidget {
  late String tagName;

  TagDetailPage(this.tagName);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<TagDetailViewModel>(
      create: (_) => TagDetailViewModel(tagName),
      child: TagDetailView(),
    );
  }
}
