
#import "MeloUtils.h"

@implementation MeloUtils

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

// rounds a float up to the nearest 1/3 - used to round font heights to their appropriate display heights
+ (CGFloat)ceilToThird:(CGFloat)arg1 {

    // TODO: calling this method just crashes the app... allemand issue? since it's a class method with CGFloat which does something? idk

    NSInteger isNegMultiplier = arg1 < 0 ? -1 : 1;
    CGFloat absArg = fabs(arg1);
    CGFloat intPart = floor(absArg);
    CGFloat decPart = absArg - intPart;
    CGFloat roundedPart;

    // round the decimal to the nearest third
    if (fabs(decPart) < 0.0001) {
        roundedPart = 0;
    } else if (decPart <= 1./3) {
        roundedPart = 1./3;
    } else if (decPart <= 2./3) {
        roundedPart = 2./3;
    } else {
        roundedPart = 1;
    }

    return (intPart + roundedPart) * isNegMultiplier;
}

// returns true if the current language is set to left to right, false if right to left
+ (BOOL)appLanaguageIsLeftToRight {

    // TODO:
    // apparently there is some discourse on how to actually get the right language...
    // https://stackoverflow.com/questions/3910244/getting-current-device-language-in-ios/10497352#10497352

    // this one gets the language used in the app
    // NSString *language = [[[NSBundle mainBundle] preferredLocalizations] objectAtIndex:0];

    // this one gets the device language
    NSString *language = [[NSLocale preferredLanguages] firstObject];

    // which is actually used to determine UI element layout? i assume the device language
    NSInteger direction = [NSLocale characterDirectionForLanguage:language];

    // any result other than right to left is treated as left to right
    return direction != NSLocaleLanguageDirectionRightToLeft;
}

@end