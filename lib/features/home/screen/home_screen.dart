import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:my_solved/components/styles/color.dart';
import 'package:my_solved/components/styles/font.dart';
import 'package:my_solved/features/home/bloc/home_bloc.dart';
import 'package:solved_api/solved_api.dart' as solved_api;

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.scaffoldKey});

  final GlobalKey<ScaffoldState> scaffoldKey;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MySolvedColor.secondaryBackground,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: MySolvedColor.secondaryBackground,
        actions: [
          IconButton(
            onPressed: () => scaffoldKey.currentState?.openEndDrawer(),
            icon: Icon(Icons.menu),
          ),
        ],
      ),
      body: HomeView(),
    );
  }
}

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  void initState() {
    super.initState();
    context.read<HomeBloc>().add(HomeInit());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HomeBloc, HomeState>(
      bloc: BlocProvider.of<HomeBloc>(context),
      listener: (context, state) {
        if (state.status.isFailure) {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text("네트워크 오류가 발생했어요"),
                content: Text("잠시 후 다시 시도해주세요"),
                actions: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text("확인"),
                  ),
                ],
              );
            },
          );
        }
      },
      builder: (context, state) {
        if (state.status.isSuccess && state.user != null) {
          final gridItem = [
            GridItem(
              title: "문제 해결",
              value: state.user!.solvedCount.toString(),
              unit: "개",
            ),
            GridItem(
              title: "문제 기여",
              value: state.user!.voteCount.toString(),
              unit: "개",
            ),
            GridItem(
              title: "라이벌",
              value: state.user!.reverseRivalCount.toString(),
              unit: "명",
            ),
            GridItem(
              title: "스트릭(최대)",
              value: state.user!.maxStreak.toString(),
              unit: "일",
              foregroundColor: MySolvedColor.background,
              backgroundColor: MySolvedColor.main,
            ),
            GridItem(
              title: "레이팅",
              value: state.user!.rank.toString(),
              unit: "#",
              isPrefixUnit: true,
              backgroundColor: MySolvedColor.disabledButtonBackground,
            ),
            GridItem(
              title: "뱃지",
              value: state.badges.length.toString(),
              unit: "개",
            ),
          ];
          return CustomScrollView(
            physics: BouncingScrollPhysics(),
            slivers: [
              SliverList(
                delegate: SliverChildListDelegate([
                  _profileAndBackgroundImage(
                    profileImageURL: state.user!.profileImageUrl ??
                        "https://static.solved.ac/misc/360x360/default_profile.png",
                    isShowIllustBackground: state.isOnIllustBackground,
                    background: state.background,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        SizedBox(height: 16),
                        _handleAndBio(
                          handle: state.handle,
                          bio: state.user!.bio,
                        ),
                        SizedBox(height: 16),
                        _tier(
                            tier: state.user!.tier, rating: state.user!.rating),
                        SizedBox(height: 16),
                        if (state.organizations.isNotEmpty)
                          _organizations(organizations: state.organizations),
                        SizedBox(height: 16),
                        _badgeAndClass(
                          badge: state.badge,
                          userClass: state.user!.userClass,
                          classDecoration: state.user!.classDecoration,
                        ),
                      ],
                    ),
                  ),
                ]),
              ),
              SliverPadding(
                padding: EdgeInsets.all(16),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return _gridItem(item: gridItem[index]);
                    },
                    childCount: gridItem.length,
                  ),
                  gridDelegate: SliverQuiltedGridDelegate(
                    crossAxisCount: 3,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    pattern: [
                      QuiltedGridTile(1, 1),
                      QuiltedGridTile(1, 1),
                      QuiltedGridTile(1, 1),
                      QuiltedGridTile(1, 1),
                      QuiltedGridTile(1, 2),
                      QuiltedGridTile(1, 2),
                      QuiltedGridTile(1, 1),
                    ],
                  ),
                ),
              ),
            ],
          );
        } else {
          return Center(
            child: CircularProgressIndicator(
              color: MySolvedColor.main,
            ),
          );
        }
      },
    );
  }

  Widget _profileAndBackgroundImage({
    required String profileImageURL,
    required bool isShowIllustBackground,
    required solved_api.Background? background,
  }) {
    final backgroundImageUrl = background?.backgroundImageUrl ??
        "https://static.solved.ac/profile_bg/abstract_001/abstract_001_light.png";
    final illustBackgroundImageUrl = background?.fallbackBackgroundImageUrl;
    final url = isShowIllustBackground && illustBackgroundImageUrl != null
        ? illustBackgroundImageUrl
        : backgroundImageUrl;
    return Stack(
      alignment: Alignment.bottomLeft,
      children: [
        Column(
          children: [
            Container(
              width: double.infinity,
              height: 160,
              color: MySolvedColor.background,
              child: ExtendedImage.network(url),
            ),
            SizedBox(height: 50),
          ],
        ),
        Row(
          children: [
            SizedBox(width: 16),
            SizedBox(
              width: 80,
              height: 80,
              child: ClipOval(
                child: ExtendedImage.network(profileImageURL),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _handleAndBio({required String handle, required String? bio}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: MySolvedColor.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            handle,
            style: MySolvedTextStyle.title3,
          ),
          if (bio != null)
            Column(
              children: [
                SizedBox(height: 4),
                Text(
                  bio,
                  style: MySolvedTextStyle.body2.copyWith(
                    color: MySolvedColor.secondaryFont,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _organizations(
      {required List<solved_api.Organization> organizations}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: MySolvedColor.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Wrap(
        children: List.generate(
          organizations.length,
          (index) => Text(
            index != organizations.length - 1
                ? "${organizations[index].name}, "
                : organizations[index].name,
            style: MySolvedTextStyle.body2.copyWith(
              color: MySolvedColor.secondaryFont,
            ),
          ),
        ),
      ),
    );
  }

  Widget _tier({required int tier, required int rating}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: MySolvedColor.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: rating < 3000
          ? Row(
              children: [
                Text(
                  _tierText(tier),
                  style: MySolvedTextStyle.title5.copyWith(
                    color: _ratingColor(rating),
                  ),
                ),
                SizedBox(width: 4),
                Text(
                  rating.toString(),
                  style: MySolvedTextStyle.body1.copyWith(
                    color: _ratingColor(rating),
                  ),
                ),
              ],
            )
          : ShaderMask(
              shaderCallback: (rect) {
                return LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF7cf9ff),
                    Color(0xFFb491ff),
                    Color(0xFFff7ca8)
                  ],
                ).createShader(Rect.fromLTRB(0, 0, rect.width, rect.height));
              },
              blendMode: BlendMode.srcATop,
              child: Row(
                children: [
                  Text(
                    "Master",
                    style: MySolvedTextStyle.title5,
                  ),
                  Text(
                    rating.toString(),
                    style: MySolvedTextStyle.body1,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _badgeAndClass({
    required solved_api.Badge? badge,
    required int userClass,
    required String? classDecoration,
  }) {
    String classText = userClass.toString();
    if (classDecoration == "silver") classText += "s";
    if (classDecoration == "gold") classText += "g";
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: MySolvedColor.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          if (badge != null)
            ExtendedImage.network(
              width: 40,
              height: 40,
              badge.badgeImageUrl,
            ),
          SvgPicture.asset(
            width: 40,
            height: 40,
            "assets/images/classes/c$classText.svg",
          ),
        ],
      ),
    );
  }

  Widget _gridItem({required GridItem item}) {
    return Container(
      padding: EdgeInsets.only(top: 20, left: 16, right: 16, bottom: 20),
      decoration: BoxDecoration(
        color: item.backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.title,
            style: MySolvedTextStyle.body2.copyWith(
              color: item.foregroundColor,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (item.isPrefixUnit)
                Column(
                  children: [
                    Text(
                      item.unit,
                      style: MySolvedTextStyle.body1.copyWith(
                        color: item.foregroundColor,
                      ),
                    ),
                    SizedBox(height: 4),
                  ],
                ),
              if (item.isPrefixUnit) SizedBox(width: 2),
              Text(
                item.value,
                style: MySolvedTextStyle.title1.copyWith(
                  fontSize: 24,
                  color: item.foregroundColor,
                ),
              ),
              if (!item.isPrefixUnit) SizedBox(width: 2),
              if (!item.isPrefixUnit)
                Column(
                  children: [
                    Text(
                      item.unit,
                      style: MySolvedTextStyle.body1.copyWith(
                        color: item.foregroundColor,
                      ),
                    ),
                    SizedBox(height: 4),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _ratingColor(int rating) {
    if (rating < 30) {
      return Color(0xFF2D2D2D);
    } else if (rating < 200) {
      // bronze
      return Color(0xffad5600);
    } else if (rating < 800) {
      // silver
      return Color(0xFF425E79);
    } else if (rating < 1600) {
      // gold
      return Color(0xffec9a00);
    } else if (rating < 2200) {
      // platinum
      return Color(0xff00c78b);
    } else if (rating < 2700) {
      // diamond
      return Color(0xff00b4fc);
    } else if (rating < 3000) {
      // ruby
      return Color(0xffff0062);
    } else {
      // master
      return Color(0xffb300e0);
    }
  }

  String _tierText(int tier) {
    if (tier == 1) {
      return 'Bronze V';
    } else if (tier == 2) {
      return 'Bronze IV';
    } else if (tier == 3) {
      return 'Bronze III';
    } else if (tier == 4) {
      return 'Bronze II';
    } else if (tier == 5) {
      return 'Bronze I';
    } else if (tier == 6) {
      return 'Silver V';
    } else if (tier == 7) {
      return 'Silver IV';
    } else if (tier == 8) {
      return 'Silver III';
    } else if (tier == 9) {
      return 'Silver II';
    } else if (tier == 10) {
      return 'Silver I';
    } else if (tier == 11) {
      return 'Gold V';
    } else if (tier == 12) {
      return 'Gold IV';
    } else if (tier == 13) {
      return 'Gold III';
    } else if (tier == 14) {
      return 'Gold II';
    } else if (tier == 15) {
      return 'Gold I';
    } else if (tier == 16) {
      return 'Platinum V';
    } else if (tier == 17) {
      return 'Platinum IV';
    } else if (tier == 18) {
      return 'Platinum III';
    } else if (tier == 19) {
      return 'Platinum II';
    } else if (tier == 20) {
      return 'Platinum I';
    } else if (tier == 21) {
      return 'Diamond V';
    } else if (tier == 22) {
      return 'Diamond IV';
    } else if (tier == 23) {
      return 'Diamond III';
    } else if (tier == 24) {
      return 'Diamond II';
    } else if (tier == 25) {
      return 'Diamond I';
    } else if (tier == 26) {
      return 'Ruby V';
    } else if (tier == 27) {
      return 'Ruby IV';
    } else if (tier == 28) {
      return 'Ruby III';
    } else if (tier == 29) {
      return 'Ruby II';
    } else if (tier == 30) {
      return 'Ruby I';
    } else if (tier == 31) {
      return 'Master';
    } else {
      return 'Unrated';
    }
  }
}

class GridItem {
  String title;
  String value;
  String unit;
  bool isPrefixUnit;
  Color foregroundColor;
  Color backgroundColor;

  GridItem({
    required this.title,
    required this.value,
    required this.unit,
    this.isPrefixUnit = false,
    this.foregroundColor = MySolvedColor.font,
    this.backgroundColor = MySolvedColor.background,
  });
}
