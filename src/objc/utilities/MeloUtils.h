
#import <UIKit/UIKit.h>

@interface MeloUtils : NSObject
+ (NSDictionary *)colorToDict:(UIColor *)color;
+ (UIColor *)dictToColor:(NSDictionary *)dict;
+ (CGFloat)ceilToThird:(CGFloat)arg1;
+ (BOOL)appLanaguageIsLeftToRight;
@end