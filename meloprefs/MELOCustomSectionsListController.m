#import <Preferences/PSSpecifier.h>
#import "MELOCustomSectionsListController.h"
#import "MELOCustomSectionsListCell.h"
#import <HBLog.h>

@implementation MELOCustomSectionsListController

- (instancetype)init {
	self = [super init];

	if (self) {

		_accentColor = [UIColor systemPinkColor]; //[UIColor colorWithRed:1.0 green:0.216 blue:0.373 alpha:1.0];

		_deleteSectionsButton = [[UIBarButtonItem alloc] initWithTitle:@"Delete All" style:UIBarButtonItemStylePlain target:self action:@selector(deleteAllSections)];
		_deleteSectionsButton.tintColor = [UIColor systemRedColor];

		_needsSave = NO;
		_autosaveTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(autosaveTimerFired:) userInfo:nil repeats:YES];
	}

	return self;
}

- (NSArray *)specifiers {
	HBLogDebug(@"%@", @"getting specifiers array");

	if (!_specifiers) {
		_specifiers = [self loadSpecifiersFromPlistName:@"CustomSections" target:self];

		NSURL *url = [NSURL fileURLWithPath:@"/var/jb/var/mobile/Library/Preferences/com.lint.melo.prefs.plist"];
		NSDictionary *settings = [NSDictionary dictionaryWithContentsOfURL:url error:nil];

		for (NSDictionary *sectionInfo in settings[@"customSectionsInfoForPrefs"]) {

			HBLogDebug(@"\tloaded section: %@, %@", sectionInfo[@"title"], sectionInfo[@"identifier"]);

			PSSpecifier *customCellSpecifier = [PSSpecifier preferenceSpecifierNamed:sectionInfo[@"identifier"] target:self set:NULL get:NULL detail:Nil cell:-1 edit:Nil];
			NSMutableDictionary *properties = customCellSpecifier.properties;

			properties[@"cellClass"] = [MELOCustomSectionsListCell class];
			properties[@"customSectionIdentifier"] = sectionInfo[@"identifier"];
			properties[@"customSectionTitle"] = sectionInfo[@"title"];
			properties[@"customSectionSubtitle"] = sectionInfo[@"subtitle"];

			[self insertSpecifier:customCellSpecifier atEndOfGroup:0];
		}

		for (PSSpecifier *specifier in _specifiers) {
			if ([specifier cellType] == PSGroupCell) {
				NSString *footerText = [specifier propertyForKey:@"footerText"];
				footerText = [footerText stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n"];
				[specifier setProperty:footerText forKey:@"footerText"];
			}
		}
	}

	return _specifiers;
}

- (id)readPreferenceValue:(PSSpecifier *)specifier {
	NSURL *url = [NSURL fileURLWithPath:[NSString stringWithFormat:@"/var/jb/var/mobile/Library/Preferences/%@.plist", specifier.properties[@"defaults"]]];
	NSMutableDictionary *settings = [NSMutableDictionary dictionary];
	[settings addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfURL:url error:nil]];

	return (settings[specifier.properties[@"key"]]) ?: specifier.properties[@"default"];
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

- (void)viewWillAppear:(BOOL)arg1 {
	[super viewWillAppear:arg1];
	self.navigationItem.rightBarButtonItem.tintColor = _accentColor;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)arg1 editingStyleForRowAtIndexPath:(NSIndexPath *)arg2 {
	return [self isCustomListCellAtIndexPath:arg2] ? UITableViewCellEditingStyleDelete : UITableViewCellEditingStyleNone;
}

- (UITableViewCell *)tableView:(UITableView *)arg1 cellForRowAtIndexPath:(NSIndexPath *)arg2 {
	HBLogDebug(@"MELOCustomSectionsListController tableView: cellForRowAtIndexPath: %ld, %ld", arg2.section, arg2.row);

	PSTableCell *cell =  (PSTableCell *)[super tableView:arg1 cellForRowAtIndexPath:arg2];
	[cell setCellEnabled:YES];

	if (cell.specifier.cellType == PSButtonCell) {
		cell.textLabel.textColor = _accentColor;
		cell.textLabel.highlightedTextColor = _accentColor;
	}

	return cell;
}

- (NSIndexPath *)tableView:(UITableView *)arg1 targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)destinationIndexPath {
	return destinationIndexPath.section == sourceIndexPath.section ? destinationIndexPath : sourceIndexPath;
	//return [self isCustomListCellAtIndexPath:destinationIndexPath] ? destinationIndexPath : sourceIndexPath;
}

- (BOOL)tableView:(UITableView *)arg1 canMoveRowAtIndexPath:(NSIndexPath *)arg2 {
	HBLogDebug(@"canMoveRowAtIndexPath: %@ result: %i", arg2, [self isCustomListCellAtIndexPath:arg2]);

	return [self isCustomListCellAtIndexPath:arg2];
}

- (void)tableView:(UITableView *)arg1 moveRowAtIndexPath:(NSIndexPath *)arg2 toIndexPath:(NSIndexPath *)arg3 {
	HBLogDebug(@"moveRowAtIndexPath: %@ toIndexPath: %@", arg2, arg3);

	NSInteger indx1 = [self indexForIndexPath:arg2];
	NSInteger indx2 = [self indexForIndexPath:arg3];

	PSSpecifier *specifier = [self specifierAtIndex:indx1];
	[_specifiers removeObject:specifier];
	[_specifiers insertObject:specifier atIndex:indx2];

	[self saveData];
}

- (void)tableView:(UITableView *)arg1 commitEditingStyle:(UITableViewCellEditingStyle)arg2 forRowAtIndexPath:(NSIndexPath *)arg3 {
	HBLogDebug(@"\tcommitEditingStyle: %ld forRowAtIndexPath:%@", arg2, arg3);

	[super tableView:arg1 commitEditingStyle:arg2 forRowAtIndexPath:arg3];
	[self saveData];
}

- (void)editDoneTapped {
	HBLogDebug(@"%@", @"MELOCustomSectionsListController editDoneTapped");

	[super editDoneTapped];

	self.navigationItem.rightBarButtonItem.tintColor = _accentColor;

	HBLogDebug(@"isEditing: %i", [self editable]);

	//[UIView animateWithDuration:1.0 animations:^{
		if ([self editable]) {
			self.navigationItem.leftBarButtonItem = _deleteSectionsButton;
			self.navigationItem.title = nil;
		} else {
			self.navigationItem.leftBarButtonItem = nil;
			self.navigationItem.title = self.title;
		}
	//} completion:nil];

	//put an editing check before saving to file?
	[self saveData];
}

- (void)_returnKeyPressed:(NSNotification *)arg1 {
	[self.view endEditing:YES];
	[super _returnKeyPressed:arg1];
}

- (BOOL)isCustomListCellAtIndexPath:(NSIndexPath *)arg1 {
	PSSpecifier *specifier = [self specifierAtIndex:[self indexForIndexPath:arg1]];
	return specifier.properties[@"cellClass"] == [MELOCustomSectionsListCell class];
}

- (void)addNewCustomSectionCell {
	HBLogDebug(@"%@", @"Adding new custom section cell");

	PSSpecifier *newCustomCellSpecifier = [PSSpecifier preferenceSpecifierNamed:@"placeholder" target:self set:NULL get:NULL detail:Nil cell:PSTitleValueCell edit:Nil];
	NSMutableDictionary *properties = newCustomCellSpecifier.properties;

	properties[@"cellClass"] = [MELOCustomSectionsListCell class];
	properties[@"customSectionIdentifier"] = [[NSProcessInfo processInfo] globallyUniqueString];
	properties[@"customSectionTitle"] = @"";
	properties[@"customSectionSubtitle"] = @"";

	[self insertSpecifier:newCustomCellSpecifier atEndOfGroup:0 animated:YES];
	[self saveData];
}


- (void)deleteAllSections {
	HBLogDebug(@"%@", @"deleting sections...");

	// UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Warning" message:@"All custom sections and their pins will be deleted. Do you want to continue?" preferredStyle:UIAlertControllerStyleAlert];

	// UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
	// UIAlertAction *continueAction = [UIAlertAction actionWithTitle:@"Continue" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * action) {

		NSMutableArray *specifiersToDelete = [NSMutableArray array];

		for (PSSpecifier *specifier in _specifiers) {
			if (specifier.properties[@"cellClass"] == [MELOCustomSectionsListCell class]) {
				[specifiersToDelete addObject:specifier];
			}
		}

		for (PSSpecifier *specifier in specifiersToDelete) {
			[self removeSpecifier:specifier animated:YES];
		}

		[self saveData];
	// }];

	// [alert addAction:cancelAction];
	// [alert addAction:continueAction];
	// [self presentViewController:alert animated:YES completion:nil];
}

- (NSArray *)getCurrentCustomSectionsInfo {
	HBLogDebug(@"%@", @"getCurrentCustomSectionsInfo");

	NSMutableArray *sectionsInfo = [NSMutableArray array];

	for (NSInteger i = 0; i < [_specifiers count]; i++) {

		NSMutableDictionary *properties = [self specifierAtIndex:i].properties;

		if (properties[@"cellClass"] == [MELOCustomSectionsListCell class]) {

			NSString *title = [properties[@"customSectionTitle"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
			NSString *subtitle = [properties[@"customSectionSubtitle"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

			NSDictionary *info = @{@"identifier" : properties[@"customSectionIdentifier"], @"title" : title, @"subtitle" : subtitle};
			//HBLogDebug(@"added title: %@", properties[@"customSectionTitle"]);

			[sectionsInfo addObject:info];
		}
	}

	for (NSDictionary *info in sectionsInfo) {
		HBLogDebug(@"\tsection: %@, %@",info[@"title"], info[@"identifier"]);
	}

	return sectionsInfo;
}

- (NSArray *)getValidCurrentCustomSectionsInfo {
	HBLogDebug(@"%@", @"getValidCurrentCustomSectionsInfo");

	NSMutableArray *sectionsInfo = [NSMutableArray arrayWithArray:[self getCurrentCustomSectionsInfo]]; //since I know it returns a mutable array, do I need to do this?
	NSMutableArray *sectionsToRemove = [NSMutableArray array];

	for (NSInteger i = 0; i < [sectionsInfo count]; i++) {

		NSString *title = sectionsInfo[i][@"title"];

		if (!title || [title isEqualToString:@""]) {
			[sectionsToRemove addObject:sectionsInfo[i]];
		}
	}

	[sectionsInfo removeObjectsInArray:sectionsToRemove];
	return sectionsInfo;
}

- (void)logSpecifiers {

	for (NSInteger i = 0; i < [_specifiers count]; i++) {
		PSSpecifier *spec = [self specifierAtIndex:i];
		HBLogDebug(@"\tspecifier name: %@", [spec properties][@"customSectionTitle"]);
	}
}

- (void)setNeedsSave {
	HBLogDebug(@"%@", @"setting needs save");
	_needsSave = YES;
}

- (void)autosaveTimerFired:(NSTimer *)arg1 {
	HBLogDebug(@"%@", @"AutosaveTimerFired");

	if (_needsSave) {
		HBLogDebug(@"%@", @"Needs save");
		[self saveData];
		_needsSave = NO;
	}
}

- (void)saveData {
	HBLogDebug(@"%@", @"saving custom section info");

	NSURL *url = [NSURL fileURLWithPath:@"/var/jb/var/mobile/Library/Preferences/com.lint.melo.prefs.plist"];
	NSMutableDictionary *settings = [NSMutableDictionary dictionary];
	[settings addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfURL:url error:nil]];

	settings[@"customSectionsInfoForPrefs"] = [self getCurrentCustomSectionsInfo];
	settings[@"customSectionsInfo"] = [self getValidCurrentCustomSectionsInfo];
	[settings writeToURL:url error:nil];

	CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.lint.melo.prefs/prefschanged"), NULL, NULL, YES);
}

@end
