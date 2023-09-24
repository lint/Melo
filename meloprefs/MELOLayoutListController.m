#import "MELOLayoutListController.h"
#import <Preferences/PSSpecifier.h>
#import <Preferences/PSSliderTableCell.h>
#import <Preferences/PSSwitchTableCell.h>

@implementation MELOLayoutListController

- (instancetype)init {
	self = [super init];

	if (self) {
		_accentColor = [UIColor systemPinkColor];
	}

	return self;
}

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [self loadSpecifiersFromPlistName:@"Page_Layout" target:self];
	}

	return _specifiers;
}

- (id)readPreferenceValue:(PSSpecifier *)specifier {
	NSURL *url = [NSURL fileURLWithPath:[NSString stringWithFormat:@"/var/jb/var/mobile/Library/Preferences/%@.plist", specifier.properties[@"defaults"]]];
	NSMutableDictionary *settings = [NSMutableDictionary dictionary];
	[settings addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfURL:url error:nil]];

	id plistValue = (settings[specifier.properties[@"key"]]) ?: specifier.properties[@"default"];
	return plistValue;
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier {
	NSURL *url = [NSURL fileURLWithPath:[NSString stringWithFormat:@"/var/jb/var/mobile/Library/Preferences/%@.plist", specifier.properties[@"defaults"]]];
	NSMutableDictionary *settings = [NSMutableDictionary dictionary];
	[settings addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfURL:url error:nil]];

	[settings setObject:value forKey:specifier.properties[@"key"]];
	[settings writeToURL:url error:nil];

	CFStringRef notificationName = (__bridge CFStringRef)specifier.properties[@"PostNotification"];

	if (notificationName) {
		CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), notificationName, NULL, NULL, YES);
	}
}

- (PSSpecifier *)specifierForKey:(NSString *)arg1 {
	for (PSSpecifier *specifier in _specifiers) {
		if ([arg1 isEqualToString:specifier.properties[@"key"]]) {
			return specifier;
		}
	}

	return nil;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

	self.view.tintColor = _accentColor;
	[self.navigationController.navigationBar setPrefersLargeTitles:NO];
}

- (UITableViewCell *)tableView:(UITableView *)arg1 cellForRowAtIndexPath:(NSIndexPath *)arg2 {
	PSTableCell *cell = (PSTableCell *)[super tableView:arg1 cellForRowAtIndexPath:arg2];

	if (cell.specifier.cellType == PSButtonCell) {
		cell.textLabel.textColor = _accentColor;
		cell.textLabel.highlightedTextColor = _accentColor;
	}

	if ([cell isKindOfClass:[PSSwitchTableCell class]]) {
		PSSwitchTableCell *switchOrig = (PSSwitchTableCell *)cell;
		UISwitch *switchView = (UISwitch *)[switchOrig control];
		[switchView setOnTintColor:_accentColor];
	}

	return cell;
}

@end
