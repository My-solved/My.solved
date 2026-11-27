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

/// One field of a partial update: a value, or an explicit JSON `null`.
///
/// Leave the field itself `null` to omit it from the request.
final class NullablePatch<T extends Object> {
  const NullablePatch.value(T this.value) : isNull = false;

  /// Sends JSON `null`. The server's meaning of `null` is not documented.
  const NullablePatch.toNull()
      : value = null,
        isNull = true;

  final T? value;
  final bool isNull;
}

/// A partial change to the viewer's settings.
///
/// Fields left `null` are omitted. No field is required, so an empty patch
/// sends `{}`.
final class AccountSettingsPatch {
  const AccountSettingsPatch({
    this.theme,
    this.iconTheme,
    this.iconSchemeSolved,
    this.iconSchemeUnsolved,
    this.iconSchemeHover,
    this.iconWarnMode,
    this.iconWarnRelative,
    this.iconWarnAbsolute,
    this.alwaysShowUnrated,
    this.alwaysShowUnratable,
    this.showSolvedUserCount,
    this.showVotedUserCount,
    this.showTagButton,
    this.tagDisplayLanguage,
    this.problemSort,
    this.problemSortDirection,
    this.showOriginalTitle,
    this.showOriginalContest,
    this.sourceLevelAllSolved,
    this.sourceLevelPartlySolved,
    this.sourceLevelUnsolved,
    this.sourceLevelHover,
    this.sourceLevelDisplay,
    this.sourceSort,
    this.sourceSortDirection,
    this.sourceOrderType,
    this.sourceOrderHover,
  });

  final NullablePatch<AccountSettingTheme>? theme;
  final NullablePatch<AccountSettingIconTheme>? iconTheme;
  final NullablePatch<AccountSettingIconScheme>? iconSchemeSolved;
  final NullablePatch<AccountSettingIconScheme>? iconSchemeUnsolved;
  final NullablePatch<AccountSettingIconScheme>? iconSchemeHover;
  final NullablePatch<AccountSettingIconWarnMode>? iconWarnMode;

  /// Integer from -30 through 30 when set.
  final NullablePatch<int>? iconWarnRelative;

  /// Integer from 0 through 30 when set.
  final NullablePatch<int>? iconWarnAbsolute;
  final NullablePatch<bool>? alwaysShowUnrated;
  final NullablePatch<bool>? alwaysShowUnratable;
  final NullablePatch<AccountSettingSolvedOnlyVisibility>? showSolvedUserCount;
  final NullablePatch<AccountSettingSolvedOnlyVisibility>? showVotedUserCount;
  final NullablePatch<AccountSettingSolvedOnlyVisibility>? showTagButton;
  final NullablePatch<AccountSettingTagDisplayLanguage>? tagDisplayLanguage;
  final NullablePatch<AccountSettingProblemSort>? problemSort;
  final NullablePatch<AccountSettingSortDirection>? problemSortDirection;
  final NullablePatch<bool>? showOriginalTitle;
  final NullablePatch<bool>? showOriginalContest;
  final NullablePatch<AccountSettingVisibility>? sourceLevelAllSolved;
  final NullablePatch<AccountSettingSourceLevelPartlySolved>?
      sourceLevelPartlySolved;
  final NullablePatch<AccountSettingVisibility>? sourceLevelUnsolved;
  final NullablePatch<AccountSettingVisibility>? sourceLevelHover;
  final NullablePatch<AccountSettingSourceLevelDisplay>? sourceLevelDisplay;
  final NullablePatch<AccountSettingSourceSort>? sourceSort;
  final NullablePatch<AccountSettingSortDirection>? sourceSortDirection;
  final NullablePatch<AccountSettingSourceOrderType>? sourceOrderType;
  final NullablePatch<AccountSettingVisibility>? sourceOrderHover;
}
