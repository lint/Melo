
#import "ColorUtils.h"

@implementation ColorUtils

// converts a color object to a dictionary
+ (NSDictionary *)colorToDict:(UIColor *)color {
	const CGFloat *components = CGColorGetComponents(color.CGColor);
	
    NSMutableDictionary *colorDict = [NSMutableDictionary dictionary];
	colorDict[@"red"] = [NSNumber numberWithFloat:components[0]];
	colorDict[@"green"] = [NSNumber numberWithFloat:components[1]];
	colorDict[@"blue"] = [NSNumber numberWithFloat:components[2]];
	colorDict[@"alpha"] = [NSNumber numberWithFloat:components[3]];

	return colorDict;
}

// converts a dictionary to a color object
+ (UIColor *)dictToColor:(NSDictionary *)dict {

    // [[Logger sharedInstance] logStringWithFormat:@"dictToColor: %@", dict];
    // for (id key in dict) {
    //     [[Logger sharedInstance] logStringWithFormat:@"key: '%@'", key];
    // }
    // [[Logger sharedInstance] logStringWithFormat:@"red from dict: %@", dict[@"red"]];
    // [[Logger sharedInstance] logStringWithFormat:@"red from dict2: %@", [dict valueForKey:@"red"]];
    // [[Logger sharedInstance] logStringWithFormat:@"green from dict: %@", dict[@"green"]];
    // [[Logger sharedInstance] logStringWithFormat:@"blue from dict: %@", dict[@"blue"]];
    // [[Logger sharedInstance] logStringWithFormat:@"alpha from dict: %@", dict[@"alpha"]];

    CGFloat red = dict[@"red"] ? [dict[@"red"] floatValue] : 0;
    CGFloat green = dict[@"green"] ? [dict[@"green"] floatValue] : 0;
    CGFloat blue = dict[@"blue"] ? [dict[@"blue"] floatValue] : 0;
    CGFloat alpha = dict[@"alpha"] ? [dict[@"alpha"] floatValue] : 1;

    // [[Logger sharedInstance] logStringWithFormat:@"red: %f", red];
    // [[Logger sharedInstance] logStringWithFormat:@"green: %f", green];
    // [[Logger sharedInstance] logStringWithFormat:@"blue: %f", blue];
    // [[Logger sharedInstance] logStringWithFormat:@"alpha: %f", alpha];

    return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
}
@end