
#import "LibraryMenuManager.h"
#import "../ui/ui.h"
#import "../visualizer/visualizer.h"
#import "MeloManager.h"

static LibraryMenuManager *sharedLibraryMenuManager;
static void createSharedLibraryMenuManager(void *p) {
    sharedLibraryMenuManager = [LibraryMenuManager new];
}

@implementation LibraryMenuManager 

// initialize the shared instance without obtaining a reference
+ (void)load {
    [self sharedInstance];
}

// create a singleton instance
+ (instancetype)sharedInstance {

    static dispatch_once_t onceToken;
    dispatch_once_f(&onceToken, nil, &createSharedLibraryMenuManager);

	return sharedLibraryMenuManager;
}

// default initializer
- (instancetype)init {

    if ((self = [super init])) {
        _addedPages = [NSMutableArray array];

        // _test = [NSMutableArray array];

        // needs to be done on the main thread due to creating new view controllers
        [self performSelectorOnMainThread:@selector(setupCustomPages) withObject:nil waitUntilDone:NO];
    }

    return self;
}

// add custom pages to the added pages array
- (void)setupCustomPages {

    MeloManager *meloManager = [MeloManager sharedInstance];

    if ([meloManager prefsBoolForKey:@"recentlyViewedPagesEnabled"]) {
        [self addNewPageWithIdent:@"MELO_PAGE_RECENTLY_VIEWED" title:@"Show Last Viewed Album" imageName:@"clock.arrow.circlepath" viewController:[RecentlyViewedPageViewController new]];
    }

    if ([meloManager prefsBoolForKey:@"visualizerPageEnabled"]) {
        [self addNewPageWithIdent:@"MELO_PAGE_VISUALIZER" title:@"Visualizer" imageName:@"waveform" viewController:[VisualizerPageViewController new]];
    }
}

// return the number of pages added to the library menu
- (NSInteger)numberOfAddedPages {
    return [_addedPages count];
}

// create a new dictionary with the given values to add to the added pages array
- (void)addNewPageWithIdent:(NSString *)ident title:(NSString *)title imageName:(NSString *)imageName viewController:(UIViewController *)viewController {

    // do not add a page with no identifier
    if (!ident) {
        return;
    }

    NSMutableDictionary *info = [NSMutableDictionary dictionary];
    info[@"identifier"] = ident;
    info[@"title"] = title ?: @"";
    
    if (imageName) {
        info[@"imageName"] = imageName;
    }

    if (viewController) {
        info[@"viewController"] = viewController;
    }

    [_addedPages addObject:info];
}

// returns the page info in the added pages array that matches the given identifier
- (NSMutableDictionary *)pageInfoForIdentifier:(NSString *)ident {

    if (!ident) {
        return nil;
    }

    for (NSMutableDictionary *pageInfo in _addedPages) {
        if ([pageInfo[@"identifier"] isEqualToString:ident]) {
            return pageInfo;
        }
    }

    return nil;
}

@end