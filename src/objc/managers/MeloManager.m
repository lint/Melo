
#import "MeloManager.h"
#import "RecentlyAddedManager.h"
#import "../utilities/utilities.h"

static MeloManager *sharedMeloManager;

@implementation MeloManager

// - (int)test {
//     int (^block)(void) = ^{return 100;};
//     return block();
// }

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

    // need hacky sharedInstance while using Allemand
    @synchronized([NSNull null]) {
        if (!sharedMeloManager) {
            sharedMeloManager = [MeloManager new];
        }
        return sharedMeloManager;    
    }
}

// default initializer
- (instancetype)init {

    if ((self = [super init])) {

        [Logger logString:@"MeloManager - init"];

        [self loadPrefs];
        _defaults = [[NSUserDefaults alloc] initWithSuiteName:@"com.lint.melo.data"];
        _recentlyAddedManagers = [NSMutableArray array];
        self.shouldAddCustomContextActions = NO;

        [Logger logStringWithFormat:@"defaults: %@", _defaults];

        [self checkClearPins];
    }

    return self;
}

// returns a boolean stored in preferences with the given key
- (BOOL)prefsBoolForKey:(NSString *)arg1 {
    return [[self prefsObjectForKey:arg1] boolValue];
}

// returns an object stored in preferences with the given key
- (id)prefsObjectForKey:(NSString *)arg1 {
    return _prefs[arg1] ?: _defaultPrefs[arg1];
}

// load the saved preferences from file
- (void)loadPrefs {
    _prefs = [[NSDictionary alloc] initWithContentsOfFile:@"/var/jb/var/mobile/Library/Preferences/com.lint.melo.prefs.plist"];

    [[Logger sharedInstance] logStringWithFormat:@"MeloManager - loadPrefs, prefs result: %@", _prefs];

    NSDictionary *defaultPrefs = @{
        @"enabled": @YES,
        @"customNumColumnsEnabled": @YES,
        @"customNumColumns": @4,
        @"customAlbumCellCornerRadiusEnabled": @NO,
        @"customAlbumCellCornerRadius": @0,
        @"hideAlbumTextEnabled": @YES,
        @"removeAlbumLimitEnabled": @YES,
        @"customActionMenuEnabled":@YES,
        @"loggingEnabled": @NO,
        @"contextActionsLocationValue": @1, 
        @"allActionsInSubmenuEnabled": @NO,
        @"showMoveActionsEnabled": @YES,
        @"showShiftActionsEnabled": @YES,
        @"downloadedPinningEnabled": @NO,
        @"syncLibraryPinsEnabled":@NO,
        @"customSectionsEnabled": @NO,
        @"customTintColorEnabled": @NO,
        @"customAlbumCellSpacingEnabled": @NO,
        @"customAlbumCellSpacing": @5,
        @"renameRecentlyAddedSectionEnabled": @NO,
        @"collapsibleSectionsEnabled": @YES,
        @"showWiggleModeActionEnabled": @YES,
        @"preserveCollapsedStateEnabled": @YES,
        @"wiggleModeHooksEnabled": @YES,
        @"themingHooksEnabled": @YES,
        @"pinningHooksEnabled": @YES,
        @"layoutHooksEnabled": @YES,
        @"mainLayoutAffectsOtherAlbumPagesEnabled": @YES,
        @"hideTextAffectsOtherAlbumPagesEnabled": @NO,
        @"customAlbumCellFontSizeEnabled": @NO,
        @"customAlbumCellFontSize": @12
        // @"customTintColor": [self colorToDict:[UIColor systemPinkColor]]
        };
    _defaultPrefs = [NSMutableDictionary dictionaryWithDictionary:defaultPrefs];
    // [_defaultPrefs setObject:[self colorToDict:[UIColor systemPinkColor]] forKey:@"customTintColor"];
}

// returns the spacing between album cells 
- (CGFloat)collectionViewCellSpacing {
    NSInteger numColumns = [[self prefsObjectForKey:@"customNumColumns"] integerValue];

    if ([self prefsBoolForKey:@"customAlbumCellSpacingEnabled"]) {
        return [[self prefsObjectForKey:@"customAlbumCellSpacing"] floatValue];
    } else {
        return [self prefsBoolForKey:@"customNumColumnsEnabled"] ? (10 - numColumns) / 10 * 2.5 + 5 : 20;
    }
}

// returns the spacing between album cells for other album pages
- (CGFloat)otherPagesCollectionViewCellSpacing {

    if ([self prefsBoolForKey:@"mainLayoutAffectsOtherAlbumPagesEnabled"]) {
        return [self collectionViewCellSpacing];
    } else {
        return 20;
    }
}

// returns the size of each album in a collection view to change the number of displayed columns
- (CGSize)collectionViewItemSize {
    NSInteger numColumns = [self prefsBoolForKey:@"customNumColumnsEnabled"] ? [[self prefsObjectForKey:@"customNumColumns"] integerValue] : 2;
    NSInteger screenWidth = [[UIScreen mainScreen] bounds].size.width;

    float albumWidth = floor((screenWidth - 20 * 2 - [self collectionViewCellSpacing] * (numColumns - 1)) / numColumns);
    float albumHeight = (albumWidth * 1.5 - albumWidth) > 40 ? floor(albumWidth * 1.5) : albumWidth + 40;

    if ([self prefsBoolForKey:@"hideAlbumTextEnabled"]) {
        return CGSizeMake(albumWidth, albumWidth);
    } else {
        float albumHeight = (albumWidth * 1.5 - albumWidth) > 40 ? floor(albumWidth * 1.5) : albumWidth + 40;
        return CGSizeMake(albumWidth, albumHeight);
    }
}

// returns the size of each album in a collection view to change the number of displayed columns for other albums pages
- (CGSize)otherPagesCollectionViewItemSize {
    NSInteger numColumns;
    NSInteger screenWidth = [[UIScreen mainScreen] bounds].size.width;

    if ([self prefsBoolForKey:@"customNumColumnsEnabled"] && [self prefsBoolForKey:@"mainLayoutAffectsOtherAlbumPagesEnabled"]) {
        numColumns = [[self prefsObjectForKey:@"customNumColumns"] integerValue];
    } else {
        numColumns = 2;
    }

    float albumWidth = floor((screenWidth - 20 * 2 - [self otherPagesCollectionViewCellSpacing] * (numColumns - 1)) / numColumns);

    if ([self prefsBoolForKey:@"hideAlbumTextEnabled"] && [self prefsBoolForKey:@"hideTextAffectsOtherAlbumPagesEnabled"]) {
        return CGSizeMake(albumWidth, albumWidth);
    } else {
        float albumHeight = (albumWidth * 1.5 - albumWidth) > 40 ? floor(albumWidth * 1.5) : albumWidth + 40;
        return CGSizeMake(albumWidth, albumHeight);
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

// inform other recently added managers if one of them made a change to the album order
- (void)dataChangeOccurred:(RecentlyAddedManager *)sender {
    for (RecentlyAddedManager *recentlyAddedManager in _recentlyAddedManagers) {

        // do not notify the sending manager of the change or to any managers of different types (for full library vs downloaded music) when syncing is disabled enabled
        if (recentlyAddedManager != sender && ([self prefsBoolForKey:@"syncLibraryPinsEnabled"] || recentlyAddedManager.isDownloadedMusic == sender.isDownloadedMusic)) {
            recentlyAddedManager.unhandledDataChangeOccurred = YES;
        }
    }
}

// add a recently added manager to the array
- (void)addRecentlyAddedManager:(RecentlyAddedManager *)arg1 {
    if (![_recentlyAddedManagers containsObject:arg1]) {
        [_recentlyAddedManagers addObject:arg1];
    }
}

@end