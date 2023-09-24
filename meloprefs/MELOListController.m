
#import "MELOListController.h"
#import <Preferences/PSSpecifier.h>
#import <Preferences/PSSliderTableCell.h>
#import <Preferences/PSSwitchTableCell.h>
#import <Preferences/PreferencesAppController.h>
#import <rootless.h>

// TODO: one day actually use this as a super class for other custom list controllers once you stop using allemand

@implementation MELOListController

- (instancetype)init {
	
	if ((self = [super init])) {
		_accentColor = [UIColor systemPinkColor]; //[UIColor colorWithRed:1.0 green:0.216 blue:0.373 alpha:1.0];
	}

	return self;
}

- (id)readPreferenceValue:(PSSpecifier *)specifier {
	NSURL *url = [NSURL fileURLWithPath:[NSString stringWithFormat:@"/var/jb/var/mobile/Library/Preferences/%@.plist", specifier.properties[@"defaults"]]];
	NSMutableDictionary *settings = [NSMutableDictionary dictionary];
	[settings addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfURL:url error:nil]];

	id plistValue = (settings[specifier.properties[@"key"]]) ?: specifier.properties[@"default"];

	// [self changeEnabled:plistValue && [plistValue boolValue] forCellDependentOnKey:[specifier propertyForKey:@"key"]];

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

	// [self changeEnabled:value && [value boolValue] forCellDependentOnKey:[specifier propertyForKey:@"key"]];
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

	// [self reloadSpecifiers];

	self.view.tintColor = _accentColor;
	// [[[UIApplication sharedApplication] delegate] appWindow].tintColor = _accentColor;
	[self.navigationController.navigationBar setPrefersLargeTitles:NO];
	// _table.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
}

- (void)viewWillDisappear:(BOOL)animated {
	// [[[UIApplication sharedApplication] delegate] appWindow].tintColor = nil;
	[super viewWillDisappear:animated];
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

// - (void)updateDependentSpecifiers {

// 	for (PSSpecifier *specifier in _specifiers) {

// 		PSSpecifier *parentSpecifier = [self specifierForKey:specifier.properties[@"parentKey"]];

// 		if (parentSpecifier) {
			
// 		}
// 	}
// }

@end