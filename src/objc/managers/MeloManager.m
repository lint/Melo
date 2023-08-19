
#import "MeloManager.h"

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
    _defaultPrefs = @{@"enabled": @YES};
}

@end