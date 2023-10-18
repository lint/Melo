
#import "RecentlyViewedPageManager.h"
#import "../../interfaces/interfaces.h"
#import "MeloManager.h"

static RecentlyViewedPageManager *sharedRecentlyViewedPageManager;
static void createSharedRecentlyViewedPageManager(void *p) {
    sharedRecentlyViewedPageManager = [RecentlyViewedPageManager new];
}

@implementation RecentlyViewedPageManager 

// initialize the shared instance without obtaining a reference
+ (void)load {
    [self sharedInstance];
}

// create a singleton instance
+ (instancetype)sharedInstance {

    static dispatch_once_t onceToken;
    dispatch_once_f(&onceToken, nil, &createSharedRecentlyViewedPageManager);

	return sharedRecentlyViewedPageManager;
}

// default initializer
- (instancetype)init {

    if ((self = [super init])) {

        MeloManager *meloManager = [MeloManager sharedInstance];

        _albumQueue = [NSMutableArray array];
        _navMap = [NSMutableDictionary dictionary];

        [self updateQueueConfigFromPrefs];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleLibraryPrefsUpdate:) name:@"MELO_NOTIFICATION_PREFS_UPDATED_LIBRARY" object:meloManager];
    }

    return self;
}

- (void)updateQueueConfigFromPrefs {
    MeloManager *meloManager = [MeloManager sharedInstance];

    _shouldLimitQueues = [meloManager prefsBoolForKey:@"recentlyViewedPagesLimitEnabled"];
    NSInteger newLimit = [meloManager prefsIntForKey:@"recentlyViewedPagesLimit"];
    _queueSizeLimit = newLimit;

    if ([_albumQueue count] > newLimit) {

        for (NSInteger i = 0; i < [_albumQueue count] - newLimit; i++) {
            [_albumQueue removeLastObject];
        }
    }
}

- (void)handleLibraryPrefsUpdate:(NSNotification *)arg1 {

    [self updateQueueConfigFromPrefs];
}

- (void)addAlbumPageToQueue:(id)arg1 {

    if (_shouldLimitQueues && [_albumQueue count] >= _queueSizeLimit) {
        [_albumQueue removeLastObject];
    }

    [_albumQueue insertObject:arg1 atIndex:0];
}

- (void)addNavControllerToMap:(UINavigationController *)arg1 {

    if (!arg1) {
        return;
    }

    NSMutableDictionary *data = _navMap[arg1.identifier];

    if (!data) {
        data = [NSMutableDictionary dictionary];
        data[@"parent"] = arg1;
        _navMap[arg1.identifier] = data;
    }   

    data[@"controllers"] = [NSArray arrayWithArray:[arg1 viewControllers]];
}

- (NSArray *)viewControllersForMappedNavController:(UINavigationController *)arg1 {
    
    if (!arg1) {
        return nil;
    }

    NSMutableDictionary *data = _navMap[arg1.identifier];

    if (data) {
        return data[@"controllers"];
    }

    return nil;
}

@end