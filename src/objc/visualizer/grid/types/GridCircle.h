
#import <UIKit/UIKit.h>

@interface GridCircle : NSObject

    // CGPoint normCenter;
    // CGPoint center;
    // CGFloat radius;
    // CGFloat z;
    // CGFloat strength;
    // NSString *identifier;
    // BOOL isContained;
    // BOOL isIntersected;
    // NSInteger groupIndex;

@property(assign, nonatomic) CGPoint viewNormalizedCenter;
@property(assign, nonatomic) CGPoint center;
@property(assign, nonatomic) CGFloat radius;
@property(assign, nonatomic) CGFloat strength;
@property(assign, nonatomic) NSString *identifier;
- (instancetype)initWithWithIdentifier:(NSString *)ident normalizedCenter:(CGPoint)center radius:(CGFloat)radius strength:(CGFloat)strength;

@end