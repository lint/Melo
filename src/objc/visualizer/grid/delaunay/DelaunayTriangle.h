
#import <UIKit/UIKit.h>

@class DelaunaySite;

@interface DelaunayTriangle : NSObject
@property(strong, nonatomic) DelaunaySite *site1;
@property(strong, nonatomic) DelaunaySite *site2;
@property(strong, nonatomic) DelaunaySite *site3;
- (instancetype)initWithSite1:(DelaunaySite *)site1 site2:(DelaunaySite *)site2 site3:(DelaunaySite *)site3;
- (CGPoint)calculateCircumcenter;
- (NSArray *)sites;
- (BOOL)isAdjacentToTriangle:(DelaunayTriangle *)triangle;
@end