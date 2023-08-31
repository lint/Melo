
#import "MELOColorPickerCell.h"

@implementation MELOColorPickerCell

// initializer 
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier specifier:(PSSpecifier *)specifier {
	self = [super initWithStyle:style reuseIdentifier:reuseIdentifier specifier:specifier];
	
    if (self) {
		self.accessoryView = self.control;
		// self.detailTextLabel.text = [specifier.properties objectForKey:@"subtitle"];
		// self.detailTextLabel.numberOfLines = 2;
		// [self setCellEnabled:[[[NSUserDefaults standardUserDefaults] objectForKey:@"textStyle" inDomain:domain] integerValue] == 2];

        [self loadSelectedColor];
	}
	
    return self;
}

// - (void)setCellEnabled:(BOOL)cellEnabled {
// 	[super setCellEnabled:cellEnabled];
// 	self.control.backgroundColor = cellEnabled ? [self currentColor] : [UIColor secondaryLabelColor];
// 	// self.control.hidden = !cellEnabled;
// }

// - (BOOL)cellEnabled {
// 	// return [[[NSUserDefaults standardUserDefaults] objectForKey:@"textStyle" inDomain:domain] integerValue] == 2;
//     return YES;
// }

- (void)refreshCellContentsWithSpecifier:(PSSpecifier *)specifier {
	[super refreshCellContentsWithSpecifier:specifier];
	self.control.backgroundColor = [self cellEnabled] ? [self currentColor] : [UIColor systemPinkColor];
}

// returns a custom button
- (UIButton *)newControl {

	UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
	button.frame = CGRectMake(0, 0, 30, 30);
	button.backgroundColor = _currentColor;
	button.layer.masksToBounds = NO;
	button.layer.cornerRadius = button.frame.size.width / 2;

	[button addTarget:self action:@selector(handleColorButtonPressed) forControlEvents:UIControlEventTouchUpInside];

	return button;
}

// called when the color picker button is selected
- (void)handleColorButtonPressed {

	UIColorPickerViewController *colorPickerController = [[UIColorPickerViewController alloc] init];
	colorPickerController.delegate = self;
	colorPickerController.supportsAlpha = YES;
	colorPickerController.modalPresentationStyle = UIModalPresentationPageSheet;
	colorPickerController.modalInPresentation = YES;
	colorPickerController.selectedColor = _currentColor;

	[[self _viewControllerForAncestor] presentViewController:colorPickerController animated:YES completion:nil]; 
}

- (UIColor *)loadSelectedColor {
    
    // read the preferences file
    NSString *path = @"/var/jb/var/mobile/Library/Preferences/com.lint.melo.prefs.plist";
    NSMutableDictionary *settings = [[NSMutableDictionary alloc] initWithContentsOfFile:path];

    // get the current color
    NSDictionary *colorDict = [settings objectForKey:@"customTintColor"];
    UIColor *color = colorDict ? [self dictToColor:colorDict] : [UIColor systemPinkColor];

    _currentColor = color;
    return color;
}

// saves the currently selected color to preferences
- (void)saveSelectedColor:(UIColor *)color {

    // read the preferences file
    NSString *path = @"/var/jb/var/mobile/Library/Preferences/com.lint.melo.prefs.plist";
    NSURL *url = [NSURL fileURLWithPath:path isDirectory:NO];
    NSMutableDictionary *settings = [[NSMutableDictionary alloc] initWithContentsOfFile:path];

    // create the dictionary representation
    NSDictionary *colorDict = [self colorToDict:color];

    // save to preferences
    [settings setObject:colorDict forKey:@"customTintColor"];
	[settings writeToURL:url error:nil];
}

// delegate method called when a new color is selected
- (void)colorPickerViewControllerDidSelectColor:(UIColorPickerViewController *)viewController {
	// [[NSUserDefaults standardUserDefaults] setObject:[self dictionaryForColor:viewController.selectedColor] forKey:[self.specifier.properties[@"key"] stringByAppendingString:@"Dict"] inDomain:domain];
	// [[NSUserDefaults standardUserDefaults] synchronize];
	// CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), (CFStringRef)@"com.mtac.amp/statusbar.changed", nil, nil, true);

    UIColor *color = viewController.selectedColor;
    _currentColor = color;

	self.control.backgroundColor = _currentColor;
    [self saveSelectedColor:_currentColor];
}

// converts a color object to a dictionary
- (NSDictionary *)colorToDict:(UIColor *)color {
	const CGFloat *components = CGColorGetComponents(color.CGColor);
	
    NSMutableDictionary *colorDict = [NSMutableDictionary new];
	[colorDict setObject:[NSNumber numberWithFloat:components[0]] forKey:@"red"];
	[colorDict setObject:[NSNumber numberWithFloat:components[1]] forKey:@"green"];
	[colorDict setObject:[NSNumber numberWithFloat:components[2]] forKey:@"blue"];
    [colorDict setObject:[NSNumber numberWithFloat:components[3]] forKey:@"alpha"];

	return colorDict;
}

// converts a dictionary to a color object
- (UIColor *)dictToColor:(NSDictionary *)dict {

    CGFloat red = dict[@"red"] ? [dict[@"red"] floatValue] : 0;
    CGFloat green = dict[@"green"] ? [dict[@"green"] floatValue] : 0;
    CGFloat blue = dict[@"blue"] ? [dict[@"blue"] floatValue] : 0;
    CGFloat alpha = dict[@"alpha"] ? [dict[@"alpha"] floatValue] : 1;

    return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
}

@end