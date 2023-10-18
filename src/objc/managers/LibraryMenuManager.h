
#import <UIKit/UIKit.h>

@interface LibraryMenuManager : NSObject
@property(strong, nonatomic) NSMutableArray *addedPages;

+ (void)load;
+ (instancetype)sharedInstance;

- (NSInteger)numberOfAddedPages;
- (NSMutableDictionary *)pageInfoForIdentifier:(NSString *)ident;
- (void)addNewPageWithIdent:(NSString* )ident title:(NSString *)title imageName:(NSString *)imageName viewController:(UIViewController *)viewController;

@end