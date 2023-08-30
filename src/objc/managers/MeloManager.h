
#import <UIKit/UIKit.h>

// forward declarations
@class RecentlyAddedManager;

// overall tweak manager class
@interface MeloManager : NSObject
@property(strong, nonatomic) NSDictionary *prefs;
@property(strong, nonatomic) NSDictionary *defaultPrefs;
@property(strong, nonatomic) NSUserDefaults *defaults;
@property(strong, nonatomic) NSMutableArray *recentlyAddedManagers;

+ (void)load;
+ (instancetype)sharedInstance;
- (instancetype)init;

- (void)loadPrefs;
- (BOOL)prefsBoolForKey:(NSString *)arg1;
- (id)prefsObjectForKey:(NSString *)arg1;

- (CGFloat)minimumCellSpacing;
- (void)checkClearPins;
- (void)dataChangeOccurred:(RecentlyAddedManager *)sender;
- (void)addRecentlyAddedManager:(RecentlyAddedManager *)arg1;

@end