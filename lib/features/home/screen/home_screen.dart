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
    context.read<HomeBloc>().add(InitHome());
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
          return CustomScrollView(
            physics: BouncingScrollPhysics(),
            slivers: [
              SliverList(
                delegate: SliverChildListDelegate([
                  _profileAndBackgroundImage(
                    profileImageURL: state.user!.profileImageUrl ??
                        "https://static.solved.ac/misc/360x360/default_profile.png",
                    isShowIllustBackground: state.isShowIllustBackground,
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
                        if (state.organizations.isNotEmpty)
                          _organizations(organizations: state.organizations),
                        SizedBox(height: 16),
                        _badgeAndClass(
                          badge: state.badge,
                          userClass: state.user!.userClass,
                          classDecoration: state.user!.classDecoration,
                        ),
                        SizedBox(height: 16),
                      ],
                    ),
                  ),
                ]),
              ),
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: MySolvedColor.main,
                      ),
                      child: Text("$index"),
                    ),
                    childCount: 9,
                  ),
                  gridDelegate: SliverQuiltedGridDelegate(
                    crossAxisCount: 3,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    pattern: [
                      QuiltedGridTile(1, 1),
                      QuiltedGridTile(1, 2),
                      QuiltedGridTile(1, 1),
                      QuiltedGridTile(1, 1),
                      QuiltedGridTile(1, 1),
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
}
