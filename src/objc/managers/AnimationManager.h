
#import <UIKit/UIKit.h>

@interface AnimationManager : NSObject

- (void)handleAnimationWillStart:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context;
- (void)handleAnimationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context;

@end