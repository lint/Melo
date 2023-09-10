
#import <UIKit/UIKit.h>

@interface ColorUtils : NSObject
+ (NSDictionary *)colorToDict:(UIColor *)color;
+ (UIColor *)dictToColor:(NSDictionary *)dict;
@end