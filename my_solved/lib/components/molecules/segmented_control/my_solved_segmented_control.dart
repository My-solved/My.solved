import 'package:flutter/material.dart';
import 'package:my_solved/components/styles/color.dart';
import 'package:my_solved/components/styles/font.dart';

class MySolvedSegmentedControl extends StatefulWidget {
  final List<String> screenTitles;
  final int defaultIndex;
  final Function(int index) onSelected;

  const MySolvedSegmentedControl({
    required this.screenTitles,
    required this.defaultIndex,
    required this.onSelected,
    super.key,
  });

  @override
  State<MySolvedSegmentedControl> createState() =>
      _MySolvedSegmentedControlState();
}

class _MySolvedSegmentedControlState extends State<MySolvedSegmentedControl> {
  late int current;

  @override
  void initState() {
    super.initState();
    current = widget.defaultIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        widget.screenTitles.length,
        (index) {
          return Row(
            children: [
              GestureDetector(
                onTap: () {
                  current = index;
                  widget.onSelected(index);
                },
                child: Container(
                  padding: EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: current == index
                            ? MySolvedColor.font
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Text(
                    widget.screenTitles[index],
                    style: current == index
                        ? MySolvedTextStyle.title5
                        : MySolvedTextStyle.body1.copyWith(
                            color: MySolvedColor.secondaryFont,
                          ),
                  ),
                ),
              ),
              SizedBox(width: 12),
            ],
          );
        },
      ),
    );
  }
}
