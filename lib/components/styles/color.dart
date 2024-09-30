import 'package:flutter/material.dart';

class MySolvedColor {
  static const Color main = Color(0xFF11CE3C);

  static const Color warning = Colors.red;

  static const Color font = Color(0xFF000000);
  static const Color secondaryFont = Color(0xFF767676);

  static const Color background = Color(0xFFFFFFFF);
  static const Color secondaryBackground = Color(0xFFF9F9F9);

  static const Color primaryButtonForeground = Color(0xFFFFFFFF);
  static const Color secondaryButtonBackground = Color(0xFFD9D9D9);
  static const Color disabledButtonForeground = Color(0xFF767676);
  static const Color disabledButtonBackground = Color(0xFFD9D9D9);

  static const Color textFieldBorder = Color(0xFFD9D9D9);

  static const Color divider = Color(0xFFD6D6D6);

  static const Color bottomNavigationBarUnselected = Color(0xFFC4C4C4);

  static Map<String, List<Color>> get streakTheme => {
        'default': [
          Color(0xDCDDDFFF),
          Color(0xffa1e4ac),
          Color(0xff78cb94),
          Color(0xff4eb17c),
          Color(0xff007950),
        ],
        'color_red': [
          Color(0xDCDDDFFF),
          Color(0xffFBB4B4),
          Color(0xffEA8686),
          Color(0xffDA5858),
          Color(0xffC92A2A),
        ],
        'color_wine': [
          Color(0xDCDDDFFF),
          Color(0xffF4B0C8),
          Color(0xffDA7F9F),
          Color(0xffC04F76),
          Color(0xffA61E4D),
        ],
        'color_purple': [
          Color(0xDCDDDFFF),
          Color(0xffE2ADF1),
          Color(0xffC383D5),
          Color(0xffA558B8),
          Color(0xff862E9C),
        ],
        'color_violet': [
          Color(0xDCDDDFFF),
          Color(0xffBFADF8),
          Color(0xff9F88E7),
          Color(0xff7F62D5),
          Color(0xff5F3DC4),
        ],
        'color_indigo': [
          Color(0xDCDDDFFF),
          Color(0xffACBBFA),
          Color(0xff8597E9),
          Color(0xff5D73D8),
          Color(0xff364FC7),
        ],
        'color_blue': [
          Color(0xDCDDDFFF),
          Color(0xff97CAF5),
          Color(0xff6DA8DC),
          Color(0xff4286C4),
          Color(0xff1864AB),
        ],
        'color_cyan': [
          Color(0xDCDDDFFF),
          Color(0xff8FD9E5),
          Color(0xff63B7C5),
          Color(0xff3794A5),
          Color(0xff0B7285),
        ],
        'color_teal': [
          Color(0xDCDDDFFF),
          Color(0xff8EE1CA),
          Color(0xff61C0A5),
          Color(0xff35A080),
          Color(0xff087F5B),
        ],
        'color_green': [
          Color(0xDCDDDFFF),
          Color(0xffA6E4B1),
          Color(0xff7DC68B),
          Color(0xff54A864),
          Color(0xff2B8A3E),
        ],
        'color_lime': [
          Color(0xDCDDDFFF),
          Color(0xffC7E996),
          Color(0xffA3CD68),
          Color(0xff80B03B),
          Color(0xff5C940D),
        ],
        'color_yellow': [
          Color(0xDCDDDFFF),
          Color(0xffF9DF8C),
          Color(0xffF3BC5D),
          Color(0xffEC9A2F),
          Color(0xffE67700),
        ],
        'color_orange': [
          Color(0xDCDDDFFF),
          Color(0xffFBC694),
          Color(0xffF09C68),
          Color(0xffE4723B),
          Color(0xffD9480F),
        ],
        'tier_bronze': [
          Color(0xDCDDDFFF),
          Color(0xffDDBEA0),
          Color(0xffCD9B6B),
          Color(0xffBD7935),
          Color(0xffAD5600),
        ],
        'tier_silver': [
          Color(0xDCDDDFFF),
          Color(0xffB6C1CB),
          Color(0xff90A0B0),
          Color(0xff698095),
          Color(0xff435F7A),
        ],
        'tier_gold': [
          Color(0xDCDDDFFF),
          Color(0xffF3D6A0),
          Color(0xffF1C26B),
          Color(0xffEEAE35),
          Color(0xffD38200),
        ],
        'tier_platinum': [
          Color(0xDCDDDFFF),
          Color(0xffACF0DA),
          Color(0xff80EBC8),
          Color(0xff52DBA9),
          Color(0xff23C188),
        ],
        'tier_diamond': [
          Color(0xDCDDDFFF),
          Color(0xff9EDFFA),
          Color(0xff69D1FB),
          Color(0xff35C1ED),
          Color(0xff00A5D8),
        ],
        'tier_ruby': [
          Color(0xDCDDDFFF),
          Color(0xffFA9FC2),
          Color(0xffFC6AA2),
          Color(0xffFD3582),
          Color(0xffDB0059),
        ],
        'tier_master': [
          Color(0xDCDDDFFF),
          Color(0xff7DF7FF),
          Color(0xff95CAFF),
          Color(0xffC38DEE),
          Color(0xffFD7DAB),
        ],
        'special_hanbyeol': [
          Color(0xDCDDDFFF),
          Color(0xffFFD459),
          Color(0xffFFAA69),
          Color(0xffFF7C79),
          Color(0xffFF5F84),
        ],
        'color_solvedac': [
          Color(0xDCDDDFFF),
          Color(0xffA7E9B4),
          Color(0xff77E08B),
          Color(0xff46CC5C),
          Color(0xff15AF2F),
        ],
        'color_baekjoon': [
          Color(0xDCDDDFFF),
          Color(0xff8CD2EA),
          Color(0xff5FB4DE),
          Color(0xff3197D3),
          Color(0xff0479C7),
        ],
      };

  static Map<int, Color> get tier => {
        0: Color(0xff2d2d2d),
        1: Color(0xff9d4900),
        2: Color(0xffa54f00),
        3: Color(0xffad5600),
        4: Color(0xffb55d0a),
        5: Color(0xffc67739),
        6: Color(0xff38546e),
        7: Color(0xff3d5a74),
        8: Color(0xff435f7a),
        9: Color(0xff496580),
        10: Color(0xff4e6a86),
        11: Color(0xffd28500),
        12: Color(0xffdf8f00),
        13: Color(0xffec9a00),
        14: Color(0xfff9a518),
        15: Color(0xffffb028),
        16: Color(0xff00c78b),
        17: Color(0xff00d497),
        18: Color(0xff27e2a4),
        19: Color(0xff3ef0b1),
        20: Color(0xff51fdbd),
        21: Color(0xff009ee5),
        22: Color(0xff00a9f0),
        23: Color(0xff00b4fc),
        24: Color(0xff2bbfff),
        25: Color(0xff41caff),
        26: Color(0xffe0004c),
        27: Color(0xffea0053),
        28: Color(0xfff5005a),
        29: Color(0xffff0062),
        30: Color(0xffff3071),
      };
}
