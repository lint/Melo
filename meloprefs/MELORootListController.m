#import "MELORootListController.h"
#import <Preferences/PSSpecifier.h>
#import <Preferences/PSSliderTableCell.h>
#import <Preferences/PSSwitchTableCell.h>
#import <Preferences/PreferencesAppController.h>
#import <rootless.h>
#import <NSTask.h>

@implementation MELORootListController

- (instancetype)init {
	self = [super init];

	if (self) {
		_accentColor = [UIColor systemPinkColor]; //[UIColor colorWithRed:1.0 green:0.216 blue:0.373 alpha:1.0];

		_killMusicButton = [[UIBarButtonItem alloc] initWithTitle:@"Kill Music" style: UIBarButtonItemStylePlain target:self action: @selector(killMusic)];
		_killMusicButton.tintColor = _accentColor;

		self.navigationItem.rightBarButtonItem = _killMusicButton;
	}

	return self;
}

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
	}

	return _specifiers;
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
	// CFStringRef notificationName = (__bridge CFStringRef)specifier.properties[@"PostNotification"];

	// if (notificationName) {
	// 	CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), notificationName, NULL, NULL, YES);
	// }

	// [self changeEnabled:value && [value boolValue] forCellDependentOnKey:[specifier propertyForKey:@"key"]];
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

- (void)killMusic {

	NSTask *t = [[NSTask alloc] init];
    [t setLaunchPath:ROOT_PATH_NS(@"/usr/bin/killall")];
    [t setArguments:[NSArray arrayWithObjects:@"-9", @"Music", nil]];
    [t launch];
}

- (void)clearPins {

	
	// UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Warning" message:@"Your pins will be cleared when you restart the music app. Do you want to continue?" preferredStyle:UIAlertControllerStyleAlert];

	// UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
	// UIAlertAction *continueAction = [UIAlertAction actionWithTitle:@"Continue" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * action) {
	
		NSString *path = @"/var/jb/var/mobile/Library/Preferences/com.lint.melo.prefs.plist";
		NSURL *url = [NSURL fileURLWithPath:path isDirectory:NO];
		NSMutableDictionary *settings = [[NSMutableDictionary alloc] initWithContentsOfFile:path];
		NSString *ident = [[NSProcessInfo processInfo] globallyUniqueString];

		[settings setObject:ident forKey:@"MELO_CLEAR_PINS_KEY"];
		[settings writeToURL:url error:nil];
	
	// }];

	// [alert addAction:cancelAction];
	// [alert addAction:continueAction];
	// [self presentViewController:alert animated:YES completion:nil];
}

@end
