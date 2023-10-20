
#import "MeloManager.h"
#import "RecentlyAddedManager.h"
#import "../utilities/utilities.h"
#import "../../interfaces/interfaces.h"
#import <substrate.h>

static MeloManager *sharedMeloManager;
static void createSharedMeloManager(void *p) {
    sharedMeloManager = [MeloManager new];
}

@implementation MeloManager

// loads the object if you don't need to use it right away
+ (void)load {
    [self sharedInstance];
}

// create a singleton instance
+ (instancetype)sharedInstance {
	// static MeloManager* sharedInstance = nil;
	// static dispatch_once_t onceToken;
	// dispatch_once(&onceToken, ^{
	// 	sharedInstance = [MeloManager new];
	// });
    // return sharedInstance;

    static dispatch_once_t onceToken;
    dispatch_once_f(&onceToken, nil, &createSharedMeloManager);

	return sharedMeloManager;
}

// default initializer
- (instancetype)init {

    if ((self = [super init])) {

        [Logger logString:@"MeloManager - init"];

        [self loadPrefs];
        _shouldCrash = NO;

        _shouldPreventLRAVCInit = YES;

        _defaults = [[NSUserDefaults alloc] initWithSuiteName:@"com.lint.melo.data"];
        [Logger logStringWithFormat:@"defaults: %@", _defaults];

        _recentlyAddedManagers = [NSMutableArray array];
        self.shouldAddCustomContextActions = NO;

        _albumCellTextSpacing = 5;
        
        [self checkClearPins];

        // add an observer for when the application finished launching to perform UI calculations
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(finishInitialization:) name:UIApplicationDidFinishLaunchingNotification object:nil];
    }

    return self;
}

// callback for when the app has launched and UI components can be used
- (void)finishInitialization:(NSNotification *)arg1 {

    [self updateCollectionViewLayoutValues];
    _defaultPrefs[@"customTintColor"] =  [MeloUtils colorToDict:[UIColor systemPinkColor]];
}

// returns a boolean stored in preferences with the given key
- (BOOL)prefsBoolForKey:(NSString *)arg1 {
    return [[self prefsObjectForKey:arg1] boolValue];
}

// returns an integer stored in preferences with the given key
- (NSInteger)prefsIntForKey:(NSString *)arg1 {
    return [[self prefsObjectForKey:arg1] integerValue];
}

// returns a float stored in preferences with the given key
- (CGFloat)prefsFloatForKey:(NSString *)arg1 {
    return [[self prefsObjectForKey:arg1] floatValue];
}

// returns an object stored in preferences with the given key
- (id)prefsObjectForKey:(NSString *)arg1 {
    return _prefs[arg1] ?: _defaultPrefs[arg1];
}

// load the saved preferences from file
- (void)loadPrefs {
    _prefs = [[NSDictionary alloc] initWithContentsOfFile:@"/var/jb/var/mobile/Library/Preferences/com.lint.melo.prefs.plist"];

    [[Logger sharedInstance] logStringWithFormat:@"MeloManager - loadPrefs, prefs result: %@", _prefs];

    _defaultPrefs =  [NSMutableDictionary dictionaryWithDictionary:@{
        @"enabled": @YES,
        @"customNumColumnsEnabled": @YES,
        @"customNumColumns": @4,
        @"customAlbumCellCornerRadiusEnabled": @NO,
        @"customAlbumCellCornerRadius": @0,
        @"hideAlbumTextEnabled": @NO,
        @"removeAlbumLimitEnabled": @YES,
        @"customActionMenuEnabled":@YES,
        @"loggingEnabled": @NO,
        @"contextActionsLocationValue": @1, 
        @"allActionsInSubmenuEnabled": @NO,
        @"showMoveActionsEnabled": @YES,
        @"showShiftActionsEnabled": @YES,
        @"downloadedPinningEnabled": @YES,
        @"syncLibraryPinsEnabled":@YES,
        @"customSectionsEnabled": @NO,
        @"customTintColorEnabled": @NO,
        @"customAlbumCellSpacingEnabled": @NO,
        @"customAlbumCellSpacing": @5,
        @"renameRecentlyAddedSectionEnabled": @NO,
        @"collapsibleSectionsEnabled": @YES,
        @"showWiggleModeActionEnabled": @YES,
        @"preserveCollapsedStateEnabled": @YES,
        @"themingHooksEnabled": @YES,
        @"pinningHooksEnabled": @YES,
        @"layoutHooksEnabled": @YES,
        @"mainLayoutAffectsOtherAlbumPagesEnabled": @YES,
        @"textLayoutAffectsOtherAlbumPagesEnabled": @NO,
        @"customAlbumCellFontSizeEnabled": @NO,
        @"customAlbumCellFontSize": @12,
        @"wiggleModeShakeAnimationsEnabled": @YES,
        @"backportHooksEnabled": @YES,
        @"newMusicPlayerEnabled": @NO,
        @"smallerPlaylistsViewCellsEnabled": @NO,
        @"customPlaylistCellHeightEnabled": @NO,
        @"customPlaylistCellHeight": @50,
        @"libraryHooksEnabled": @YES,
        @"recentlyViewedPagesEnabled": @NO,
        @"recentlyViewedPagesLimitEnabled": @YES,
        @"recentlyViewedPagesLimit": @5,
        @"visualizerPageEnabled": @NO
    }];
}

// update prefs when a change from settings was detected
- (void)handlePrefsChanged:(NSString *)arg1 {
    [Logger logString:@"MeloManager - prefs change detected!!"];
    
    _prefs = [[NSDictionary alloc] initWithContentsOfFile:@"/var/jb/var/mobile/Library/Preferences/com.lint.melo.prefs.plist"];
    NSString *notifName = @"MELO_NOTIFICATION_PREFS_UPDATED";

    // pinning preferences were updated
    if ([arg1 isEqualToString:@"com.lint.melo.prefs/pinning.updated"]) {
        notifName = [notifName stringByAppendingString:@"_PINNING"];

    // layout preferences were updated
    } else if ([arg1 isEqualToString:@"com.lint.melo.prefs/layout.updated"]) {
        notifName = [notifName stringByAppendingString:@"_LAYOUT"];

        [self updateCollectionViewLayoutValues];

    // theming preferences were updated
    } else if ([arg1 isEqualToString:@"com.lint.melo.prefs/theming.updated"]) {
        notifName = [notifName stringByAppendingString:@"_THEMING"];

    // backport preferences were updated
    } else if ([arg1 isEqualToString:@"com.lint.melo.prefs/backport.updated"]) {
        notifName = [notifName stringByAppendingString:@"_BACKPORT"];

    }

    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:notifName object:self]];
}


// updates the values for all properties related to collection view sizing and spacing
- (void)updateCollectionViewLayoutValues {
    
    NSInteger customNumColumns = [self prefsIntForKey:@"customNumColumns"];
    NSInteger numLibraryColumns = [self prefsBoolForKey:@"customNumColumnsEnabled"] ? customNumColumns : 2;
    NSInteger numOtherColumns = [self prefsBoolForKey:@"customNumColumnsEnabled"] && [self prefsBoolForKey:@"mainLayoutAffectsOtherAlbumPagesEnabled"] ? customNumColumns : 2;
    NSInteger screenWidth = [[UIScreen mainScreen] bounds].size.width; // can't be done in %ctor
    UIFont *customTextFont = [UIFont systemFontOfSize:[self prefsIntForKey:@"customAlbumCellFontSize"]];

    // the spacing between album cells
    if ([self prefsBoolForKey:@"customAlbumCellSpacingEnabled"]) {
        _collectionViewCellSpacing = [self prefsFloatForKey:@"customAlbumCellSpacing"];
    } else {
        _collectionViewCellSpacing = [self prefsBoolForKey:@"customNumColumnsEnabled"] ? (10 - customNumColumns) / 10 * 2.5 + 5 : 20;
    }
    
    // spacing between album cells for other album pages
    if ([self prefsBoolForKey:@"mainLayoutAffectsOtherAlbumPagesEnabled"]) {
        _otherPagesCollectionViewCellSpacing = _collectionViewCellSpacing;
    } else {
        _otherPagesCollectionViewCellSpacing = 20;
    }

    //size of each album in a collection view to change the number of displayed columns

    float albumWidth = floor((screenWidth - 20 * 2 - _collectionViewCellSpacing * (numLibraryColumns - 1)) / numLibraryColumns);

    if ([self prefsBoolForKey:@"hideAlbumTextEnabled"]) {
        _collectionViewItemSize = CGSizeMake(albumWidth, albumWidth);
    } else {
        float albumHeight;
        
        if ([self prefsBoolForKey:@"customAlbumCellFontSizeEnabled"]) {
            CGFloat textAndSpacingHeight = _albumCellTextSpacing * 3 + [customTextFont lineHeight] * 2;
            albumHeight = albumWidth + textAndSpacingHeight;
        } else {
            albumHeight = (albumWidth * 1.5 - albumWidth) > 40 ? floor(albumWidth * 1.5) : albumWidth + 40;
        }

        _collectionViewItemSize = CGSizeMake(albumWidth, albumHeight);
    }

    // size of each album in a collection view to change the number of displayed columns for other albums pages

    albumWidth = floor((screenWidth - 20 * 2 - _otherPagesCollectionViewCellSpacing * (numOtherColumns - 1)) / numOtherColumns);

    if ([self prefsBoolForKey:@"hideAlbumTextEnabled"] && [self prefsBoolForKey:@"textLayoutAffectsOtherAlbumPagesEnabled"]) {
        _otherPagesCollectionViewItemSize = CGSizeMake(albumWidth, albumWidth);
    } else {
        float albumHeight;

        if ([self prefsBoolForKey:@"customAlbumCellFontSizeEnabled"] && [self prefsBoolForKey:@"textLayoutAffectsOtherAlbumPagesEnabled"]) {
            CGFloat textAndSpacingHeight = _albumCellTextSpacing * 3 + [customTextFont lineHeight] * 2;
            albumHeight = albumWidth + textAndSpacingHeight;
        } else {
            albumHeight = (albumWidth * 1.5 - albumWidth) > 40 ? floor(albumWidth * 1.5) : albumWidth + 40;
        }

        _otherPagesCollectionViewItemSize = CGSizeMake(albumWidth, albumHeight);
    }
}

// check preferences for if the pinned albums should be cleared
- (void)checkClearPins {

    [[Logger sharedInstance] logString:@"MeloManager checkClearPins"];

    NSString *clearPinsKey = @"MELO_CLEAR_PINS_KEY";
    NSString *savedID = [_defaults objectForKey:clearPinsKey];
    NSString *prefsID = [self prefsObjectForKey:clearPinsKey];

    [[Logger sharedInstance] logStringWithFormat:@"savedClearPinsID: %@, preferencesClearPinsID: %@", savedID, prefsID];

    // check if the preference clear pins key has changed
    // TODO: this is probably redudant (like it could be compressed)
    BOOL shouldClearPins = ((prefsID && !savedID) || (prefsID && savedID && ![prefsID isEqualToString:savedID]));
    if (!shouldClearPins) {
        return;
    }

    [[Logger sharedInstance] logString:@"new clear pins id detected, will remove saved data"];

    // clear the saved data
    [_defaults setObject:nil forKey:@"MELO_DATA_DOWNLOADED"];
    [_defaults setObject:nil forKey:@"MELO_DATA_LIBRARY"];
    [_defaults setObject:nil forKey:@"MELO_DATA_DOWNLOADED_CUSTOM_SECTIONS"];
    [_defaults setObject:nil forKey:@"MELO_DATA_LIBRARY_CUSTOM_SECTIONS"];

    // save the clear pins id from preferences 
    [_defaults setObject:prefsID forKey:clearPinsKey];
}

// add a recently added manager to the array
- (void)addRecentlyAddedManager:(RecentlyAddedManager *)arg1 {
    if (![_recentlyAddedManagers containsObject:arg1]) {
        [_recentlyAddedManagers addObject:arg1];
    }

    if ([_recentlyAddedManagers count] >= 2) {
        // [NSException raise:@"TEST EXCEPTION" format:@"test exception complete: %@", @"yay"];
        _shouldCrash = YES;
    }
}

// returns a dictionary representing display settings for an album cell of a given datasource
- (NSDictionary *)albumCellDisplayDictForDataSource:(id)dataSource {

    BOOL hideAlbumTextEnabled = [self prefsBoolForKey:@"hideAlbumTextEnabled"];
    BOOL customCornerRadiusEnabled = [self prefsBoolForKey:@"customAlbumCellCornerRadiusEnabled"];
    BOOL changeFontSizeEnabled = [self prefsBoolForKey:@"customAlbumCellFontSizeEnabled"];
    BOOL applyTextLayoutToOtherPagesEnabled = [self prefsBoolForKey:@"textLayoutAffectsOtherAlbumPagesEnabled"];
    BOOL applyMainLayoutToOtherPagesEnabled = [self prefsBoolForKey:@"mainLayoutAffectsOtherAlbumPagesEnabled"];
    BOOL dataSourceIsLRAVC = [dataSource isKindOfClass:objc_getClass("MusicApplication.LibraryRecentlyAddedViewController")];
    BOOL dataSourceIsOtherVC = [dataSource isKindOfClass:objc_getClass("MusicApplication.AlbumsViewController")] || 
        [dataSource isKindOfClass:objc_getClass("MusicApplication.AlbumsViewController")] || 
        [dataSource isKindOfClass:objc_getClass("MusicApplication.JSGridViewController")];

    BOOL shouldApplyCornerRadius = customCornerRadiusEnabled && (dataSourceIsLRAVC || (dataSourceIsOtherVC && applyMainLayoutToOtherPagesEnabled));
    BOOL shouldHideText = hideAlbumTextEnabled && (dataSourceIsLRAVC || (dataSourceIsOtherVC && applyTextLayoutToOtherPagesEnabled));
    BOOL shouldChangeFontSize = changeFontSizeEnabled && (dataSourceIsLRAVC || (dataSourceIsOtherVC && applyTextLayoutToOtherPagesEnabled));

    NSMutableDictionary *display = [NSMutableDictionary dictionary];
    display[@"shouldApplyCornerRadius"] = @(shouldApplyCornerRadius);
    display[@"shouldHideText"] = @(shouldHideText);
    display[@"shouldChangeFontSize"] = @(shouldChangeFontSize);

    return display;
}

+ (NSString *)localizedRecentlyAddedTitle {
    NSBundle *bundle = [NSBundle bundleWithPath:[NSString stringWithFormat:@"%@%@", [[NSBundle mainBundle] bundlePath], @"/Frameworks/MusicApplication.framework"]];
    return NSLocalizedStringFromTableInBundle(@"RECENTLY_ADDED_VIEW_TITLE", @"Music", bundle, nil);
}

+ (NSString *)localizedDownloadedMusicTitle {
    NSBundle *bundle = [NSBundle bundleWithPath:[NSString stringWithFormat:@"%@%@", [[NSBundle mainBundle] bundlePath], @"/Frameworks/MusicApplication.framework"]];
    return NSLocalizedStringFromTableInBundle(@"RECENTLY_DOWNLOADED_VIEW_TITLE", @"Music", bundle, nil);
}

- (NSArray *)customSectionsInfo {
    // [Logger logStringWithFormat:@"MELOMANAGER: %@", _prefs[@"customSectionsInfo"]];

    if (!_prefs[@"customSectionsInfo"]) {
        return nil;
    }

    return [NSArray arrayWithArray:_prefs[@"customSectionsInfo"]];
}

@end
