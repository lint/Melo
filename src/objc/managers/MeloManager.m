
#import "MeloManager.h"
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
    _defaultPrefs = @{@"enabled": @YES,
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
        @"showShiftActionsEnabled": @YES
        };
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

    // save the clear pins id from preferences 
    [_defaults setObject:prefsID forKey:clearPinsKey];
}

@end