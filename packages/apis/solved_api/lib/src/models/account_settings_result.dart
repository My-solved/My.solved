/// The viewer's resolved settings, from the official v4 API.
final class AccountSettingsResult {
  const AccountSettingsResult({required this.settings});

  final AccountSettings settings;
}

/// Exact wire values: `show`, `warn`, `hide`.
enum AccountSettingIconScheme {
  show('show'),
  warn('warn'),
  hide('hide');

  const AccountSettingIconScheme(this.value);

  final String value;
}

/// Exact wire values: `default`, `legacy`.
enum AccountSettingIconTheme {
  defaultValue('default'),
  legacy('legacy');

  const AccountSettingIconTheme(this.value);

  final String value;
}

/// Exact wire values: `relative`, `absolute`.
enum AccountSettingIconWarnMode {
  relative('relative'),
  absolute('absolute');

  const AccountSettingIconWarnMode(this.value);

  final String value;
}

/// Exact wire values: `id`, `level`, `solved`, `average_try`, `random`.
enum AccountSettingProblemSort {
  id('id'),
  level('level'),
  solved('solved'),
  averageTry('average_try'),
  random('random');

  const AccountSettingProblemSort(this.value);

  final String value;
}

/// Exact wire values: `asc`, `desc`.
enum AccountSettingSortDirection {
  asc('asc'),
  desc('desc');

  const AccountSettingSortDirection(this.value);

  final String value;
}

/// Exact wire values: `show`, `solved-only`, `hide`.
enum AccountSettingSolvedOnlyVisibility {
  show('show'),
  solvedOnly('solved-only'),
  hide('hide');

  const AccountSettingSolvedOnlyVisibility(this.value);

  final String value;
}

/// Exact wire values: `show`, `hide`.
enum AccountSettingVisibility {
  show('show'),
  hide('hide');

  const AccountSettingVisibility(this.value);

  final String value;
}

/// Exact wire values: `dots`, `gradient`, `none`.
enum AccountSettingSourceLevelDisplay {
  dots('dots'),
  gradient('gradient'),
  none('none');

  const AccountSettingSourceLevelDisplay(this.value);

  final String value;
}

/// Exact wire values: `show`, `partial-if-ascending`, `partial`, `hide`.
enum AccountSettingSourceLevelPartlySolved {
  show('show'),
  partialIfAscending('partial-if-ascending'),
  partial('partial'),
  hide('hide');

  const AccountSettingSourceLevelPartlySolved(this.value);

  final String value;
}

/// Exact wire values: `show`, `partly-solved`, `all-solved`, `hide`.
enum AccountSettingSourceOrderType {
  show('show'),
  partlySolved('partly-solved'),
  allSolved('all-solved'),
  hide('hide');

  const AccountSettingSourceOrderType(this.value);

  final String value;
}

/// Exact wire values: `default`, `name`, `size`, `p25`, `p50`, `p75`.
enum AccountSettingSourceSort {
  defaultValue('default'),
  name('name'),
  size('size'),
  p25('p25'),
  p50('p50'),
  p75('p75');

  const AccountSettingSourceSort(this.value);

  final String value;
}

/// Exact wire values: `identifier`, `ko`, `en`, `ja`.
enum AccountSettingTagDisplayLanguage {
  identifier('identifier'),
  ko('ko'),
  en('en'),
  ja('ja');

  const AccountSettingTagDisplayLanguage(this.value);

  final String value;
}

/// Exact wire values: `system`, `light`, `dark`.
enum AccountSettingTheme {
  system('system'),
  light('light'),
  dark('dark');

  const AccountSettingTheme(this.value);

  final String value;
}

/// Every setting with defaults applied.
///
/// Documented integer bounds are enforced. No relation between settings is
/// inferred.
final class AccountSettings {
  const AccountSettings({
    required this.theme,
    required this.iconTheme,
    required this.iconSchemeSolved,
    required this.iconSchemeUnsolved,
    required this.iconSchemeHover,
    required this.iconWarnMode,
    required this.iconWarnRelative,
    required this.iconWarnAbsolute,
    required this.alwaysShowUnrated,
    required this.alwaysShowUnratable,
    required this.showSolvedUserCount,
    required this.showVotedUserCount,
    required this.showTagButton,
    required this.tagDisplayLanguage,
    required this.problemSort,
    required this.problemSortDirection,
    required this.showOriginalTitle,
    required this.showOriginalContest,
    required this.sourceLevelAllSolved,
    required this.sourceLevelPartlySolved,
    required this.sourceLevelUnsolved,
    required this.sourceLevelHover,
    required this.sourceLevelDisplay,
    required this.sourceSort,
    required this.sourceSortDirection,
    required this.sourceOrderType,
    required this.sourceOrderHover,
  });

  final AccountSettingTheme theme;
  final AccountSettingIconTheme iconTheme;
  final AccountSettingIconScheme iconSchemeSolved;
  final AccountSettingIconScheme iconSchemeUnsolved;
  final AccountSettingIconScheme iconSchemeHover;
  final AccountSettingIconWarnMode iconWarnMode;

  /// Integer from -30 through 30.
  final int iconWarnRelative;

  /// Integer from 0 through 30.
  final int iconWarnAbsolute;
  final bool alwaysShowUnrated;
  final bool alwaysShowUnratable;
  final AccountSettingSolvedOnlyVisibility showSolvedUserCount;
  final AccountSettingSolvedOnlyVisibility showVotedUserCount;
  final AccountSettingSolvedOnlyVisibility showTagButton;
  final AccountSettingTagDisplayLanguage tagDisplayLanguage;
  final AccountSettingProblemSort problemSort;
  final AccountSettingSortDirection problemSortDirection;
  final bool showOriginalTitle;
  final bool showOriginalContest;
  final AccountSettingVisibility sourceLevelAllSolved;
  final AccountSettingSourceLevelPartlySolved sourceLevelPartlySolved;
  final AccountSettingVisibility sourceLevelUnsolved;
  final AccountSettingVisibility sourceLevelHover;
  final AccountSettingSourceLevelDisplay sourceLevelDisplay;
  final AccountSettingSourceSort sourceSort;
  final AccountSettingSortDirection sourceSortDirection;
  final AccountSettingSourceOrderType sourceOrderType;
  final AccountSettingVisibility sourceOrderHover;
}
