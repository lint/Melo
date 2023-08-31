
#import "MeloManager.h"
#import "RecentlyAddedManager.h"
#import "../utilities/utilities.h"

static MeloManager *sharedMeloManager;

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

        [self loadPrefs];
        _defaults = [[NSUserDefaults alloc] initWithSuiteName:@"com.lint.melo.data"];
        _recentlyAddedManagers = [NSMutableArray array];

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
        @"customTintColorEnabled": @NO//,
        // @"customTintColor": [self colorToDict:[UIColor systemPinkColor]]
        };
    _defaultPrefs = [NSMutableDictionary dictionaryWithDictionary:defaultPrefs];
    // [_defaultPrefs setObject:[self colorToDict:[UIColor systemPinkColor]] forKey:@"customTintColor"];
}

- (CGFloat)minimumCellSpacing {
    NSInteger numColumns = [[self prefsObjectForKey:@"customNumColumns"] integerValue];
    return [self prefsBoolForKey:@"customNumColumnsEnabled"] ? (10 - numColumns) / 10 * 2.5 + 5 : 20;
}

- (void)checkClearPins {

    [[Logger sharedInstance] logString:@"MeloManager checkClearPins"];

    NSString *clearPinsKey = @"MELO_CLEAR_PINS_KEY";
    NSString *savedID = [_defaults objectForKey:clearPinsKey];
    NSString *prefsID = [self prefsObjectForKey:clearPinsKey];

    [[Logger sharedInstance] logStringWithFormat:@"savedClearPinsID: %@, preferencesClearPinsID: %@", savedID, prefsID];

    // check if the preference clear pins key has changed
    BOOL shouldClearPins = ((prefsID && !savedID) || (prefsID && savedID && ![prefsID isEqualToString:savedID]));
    if (!shouldClearPins) {
        return;
    }

    [[Logger sharedInstance] logString:@"new clear pins id detected, will remove saved data"];

    // clear the saved data
    [_defaults setObject:nil forKey:@"MELO_DATA_DOWNLOADED"];
    [_defaults setObject:nil forKey:@"MELO_DATA_LIBRARY"];

    // TODO: remember to add custom sections here

    // save the clear pins id from preferences 
    [_defaults setObject:prefsID forKey:clearPinsKey];
}

// inform other recently added managers if one of them made a change to the album order
- (void)dataChangeOccurred:(RecentlyAddedManager *)sender {
    for (RecentlyAddedManager *recentlyAddedManager in _recentlyAddedManagers) {

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

// converts a color object to a dictionary
- (NSDictionary *)colorToDict:(UIColor *)color {
	const CGFloat *components = CGColorGetComponents(color.CGColor);
	
    NSMutableDictionary *colorDict = [NSMutableDictionary new];
	[colorDict setObject:[NSNumber numberWithFloat:components[0]] forKey:@"red"];
	[colorDict setObject:[NSNumber numberWithFloat:components[1]] forKey:@"green"];
	[colorDict setObject:[NSNumber numberWithFloat:components[2]] forKey:@"blue"];
    [colorDict setObject:[NSNumber numberWithFloat:components[3]] forKey:@"alpha"];

	return colorDict;
}

// converts a dictionary to a color object
- (UIColor *)dictToColor:(NSDictionary *)dict {

    CGFloat red = dict[@"red"] ? [dict[@"red"] floatValue] : 0;
    CGFloat green = dict[@"green"] ? [dict[@"green"] floatValue] : 0;
    CGFloat blue = dict[@"blue"] ? [dict[@"blue"] floatValue] : 0;
    CGFloat alpha = dict[@"alpha"] ? [dict[@"alpha"] floatValue] : 1;

    return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
}

@end