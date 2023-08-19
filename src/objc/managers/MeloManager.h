
#import <UIKit/UIKit.h>

// overall tweak manager class
@interface MeloManager : NSObject
@property(strong, nonatomic) NSDictionary *prefs;
@property(strong, nonatomic) NSDictionary *defaultPrefs;

+ (void)load;
+ (instancetype)sharedInstance;
- (instancetype)init;

- (void)loadPrefs;
- (BOOL)prefsBoolForKey:(NSString *)arg1;
- (id)prefsObjectForKey:(NSString *)arg1;

@end