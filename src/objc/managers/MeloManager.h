
#import <UIKit/UIKit.h>

// forward declarations
@class RecentlyAddedManager, LibraryRecentlyAddedViewController;

// overall tweak manager class
@interface MeloManager : NSObject
@property(strong, nonatomic) NSDictionary *prefs;
@property(strong, nonatomic) NSMutableDictionary *defaultPrefs;
@property(strong, nonatomic) NSUserDefaults *defaults;
@property(strong, nonatomic) NSMutableArray *recentlyAddedManagers;
@property(strong, atomic) NSIndexPath *indexPathForContextMenuOverride;
@property(strong, atomic) NSIndexPath *indexPathForContextActions;
@property(assign, atomic) BOOL shouldAddCustomContextActions;
@property(strong, nonatomic) LibraryRecentlyAddedViewController *currentLRAVC;
@property(assign, nonatomic) CGFloat collectionViewCellSpacing;
@property(assign, nonatomic) CGFloat otherPagesCollectionViewCellSpacing;
@property(assign, nonatomic) CGSize collectionViewItemSize;
@property(assign, nonatomic) CGSize otherPagesCollectionViewItemSize;
@property(assign, nonatomic) CGFloat albumCellTextSpacing;
@property(assign, nonatomic) BOOL shouldPreventLRAVCInit;
@property(assign, nonatomic) BOOL shouldCrash;

+ (void)load;
+ (instancetype)sharedInstance;
- (instancetype)init;
- (void)finishInitialization:(NSNotification *)arg1;

- (void)loadPrefs;
- (BOOL)prefsBoolForKey:(NSString *)arg1;
- (NSInteger)prefsIntForKey:(NSString *)arg1;
- (CGFloat)prefsFloatForKey:(NSString *)arg1;
- (id)prefsObjectForKey:(NSString *)arg1;

- (void)checkClearPins;
- (void)addRecentlyAddedManager:(RecentlyAddedManager *)arg1;
- (void)updateCollectionViewLayoutValues;
- (NSDictionary *)albumCellDisplayDictForDataSource:(id)dataSource;

+ (NSString *)localizedRecentlyAddedTitle;
+ (NSString *)localizedDownloadedMusicTitle;

- (void)handlePrefsChanged:(NSString *)arg1;
// - (void)customSectionsInfo;
- (NSArray *)customSectionsInfo;
@end