import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_solved/components/styles/color.dart';
import 'package:my_solved/components/styles/font.dart';
import 'package:my_solved/features/home/bloc/home_bloc.dart';
import 'package:my_solved/features/setting/bloc/setting_bloc.dart';
import 'package:shared_preferences_repository/shared_preferences_repository.dart';
import 'package:streak_notification_repository/streak_notification_repository.dart';

class SettingScreen extends StatelessWidget {
  final HomeBloc homeBloc;

  const SettingScreen({super.key, required this.homeBloc});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SettingBloc(
        sharedPreferencesRepository: SharedPreferencesRepository(),
        streakNotificationRepository: StreakNotificationRepository(),
      ),
      child: SettingView(
        homeBloc: homeBloc,
      ),
    );
  }
}

class SettingView extends StatefulWidget {
  final HomeBloc homeBloc;

  const SettingView({super.key, required this.homeBloc});

  @override
  State<SettingView> createState() => _SettingViewState();
}

class _SettingViewState extends State<SettingView> {
  @override
  void initState() {
    super.initState();
    context.read<SettingBloc>().add(SettingInit());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text("설정", style: MySolvedTextStyle.title5),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(Icons.close),
          ),
        ],
      ),
      body: BlocBuilder<SettingBloc, SettingState>(
        bloc: BlocProvider.of<SettingBloc>(context),
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "사용자 설정",
                  style: MySolvedTextStyle.caption1
                      .copyWith(color: MySolvedColor.secondaryFont),
                ),
                Divider(),
                SizedBox(
                  height: 8,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("일러스트 배경", style: MySolvedTextStyle.body2),
                    BlocBuilder<HomeBloc, HomeState>(
                      bloc: widget.homeBloc,
                      builder: (context, state) {
                        return Switch(
                          value: state.isOnIllustBackground,
                          onChanged: (isOn) {
                            context.read<SettingBloc>().add(
                                SettingIsOnIllustBackgroundChanged(isOn: isOn));
                            widget.homeBloc.add(
                                HomeIsOnIllustBackgroundChanged(isOn: isOn));
                          },
                          activeColor: MySolvedColor.background,
                          activeTrackColor: MySolvedColor.main,
                          inactiveThumbColor: MySolvedColor.background,
                          inactiveTrackColor:
                              MySolvedColor.disabledButtonBackground,
                          trackOutlineColor: MaterialStateProperty.resolveWith(
                            (states) {
                              if (states.contains(MaterialState.selected)) {
                                return null;
                              }
                              return MySolvedColor.disabledButtonBackground;
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
                SizedBox(height: 24),
                Text(
                  "알림 설정",
                  style: MySolvedTextStyle.caption1
                      .copyWith(color: MySolvedColor.secondaryFont),
                ),
                Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("스트릭 알림", style: MySolvedTextStyle.body2),
                    Switch(
                      value: state.isOnStreakNotification,
                      onChanged: (value) => context.read<SettingBloc>().add(
                          SettingStreakNotificationSwitchChanged(isOn: value)),
                      activeColor: MySolvedColor.background,
                      activeTrackColor: MySolvedColor.main,
                    ),
                  ],
                ),
                SizedBox(
                  height: 8,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("스트릭 알림 시간", style: MySolvedTextStyle.body2),
                    TextButton(
                      onPressed: state.isOnStreakNotification
                          ? () async {
                              await showTimePicker(
                                  context: context,
                                  initialTime: state.streakNotificationTime);
                            }
                          : null,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        foregroundColor: MySolvedColor.font,
                        backgroundColor: MySolvedColor.textFieldBorder,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        "${state.streakNotificationTime.hour}:${state.streakNotificationTime.minute}",
                        style: MySolvedTextStyle.body1,
                      ),
                    )
                  ],
                ),
                SizedBox(
                  height: 8,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("대회 시작 알림 시간", style: MySolvedTextStyle.body2),
                    MenuAnchor(
                      builder: (context, controller, child) {
                        return TextButton(
                          onPressed: () {
                            if (controller.isOpen) {
                              controller.close();
                            } else {
                              controller.open();
                            }
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            foregroundColor: MySolvedColor.font,
                            backgroundColor: MySolvedColor.textFieldBorder,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text("${state.contestNotificationMinute}분 전"),
                        );
                      },
                      menuChildren: List.generate(
                        6,
                        (index) => MenuItemButton(
                          onPressed: () => context.read<SettingBloc>().add(
                              SettingContestNotificationMinuteChanged(
                                  minute: (index + 1) * 10)),
                          child: Text("${(index + 1) * 10}분 전"),
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  "대회 알림 설정 이후에 시간을 변경하면 적용되지 않습니다",
                  style: MySolvedTextStyle.caption1.copyWith(
                    color: MySolvedColor.secondaryFont,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
