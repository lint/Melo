
#import <UIKit/UIKit.h>

// forward declaration
@class VisualizerManager;

@interface LibraryMenuManager : NSObject
@property(strong, nonatomic) VisualizerManager *visualizerManager;
@property(strong, nonatomic) NSMutableArray *addedPages;
@property(strong, nonatomic) NSMutableArray *test; // TODO: instant crash if i remove this line.. allemand bug i believe

+ (void)load;
+ (instancetype)sharedInstance;

- (void)setupCustomPages;
- (NSInteger)numberOfAddedPages;
- (NSMutableDictionary *)pageInfoForIdentifier:(NSString *)ident;
- (void)addNewPageWithIdent:(NSString* )ident title:(NSString *)title imageName:(NSString *)imageName viewController:(UIViewController *)viewController;

@end