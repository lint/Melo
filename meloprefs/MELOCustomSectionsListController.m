#import <Preferences/PSSpecifier.h>
#import "MELOCustomSectionsListController.h"
#import "MELOCustomSectionsListCell.h"
#import <HBLog.h>

@implementation MELOCustomSectionsListController

// default initializer
- (instancetype)init {
	self = [super init];

	if (self) {

		_accentColor = [UIColor systemPinkColor]; //[UIColor colorWithRed:1.0 green:0.216 blue:0.373 alpha:1.0];

		_deleteSectionsButton = [[UIBarButtonItem alloc] initWithTitle:@"Delete All" style:UIBarButtonItemStylePlain target:self action:@selector(deleteAllSections)];
		_deleteSectionsButton.tintColor = [UIColor systemRedColor];
	}

	return self;
}

// get the current specifiers representing cells in the page
- (NSArray *)specifiers {

	if (!_specifiers) {

		// load the static plist file
		NSMutableArray *loadedSpecifiers = [NSMutableArray arrayWithArray:[self loadSpecifiersFromPlistName:@"CustomSections" target:self]];
		
		// load other saved preferences
		NSURL *url = [NSURL fileURLWithPath:@"/var/jb/var/mobile/Library/Preferences/com.lint.melo.prefs.plist"];
		NSDictionary *settings = [NSDictionary dictionaryWithContentsOfURL:url error:nil];
		NSArray *customSectionsInfo = settings[@"customSectionsInfo"];
		NSDictionary *customRecentlyAddedInfo = settings[@"customRecentlyAddedInfo"];

		NSInteger customSectionCellInsertOffset = 2; // just set to 2 since i know it is currently 2 from the number of cells in the plist

		for (PSSpecifier *specifier in loadedSpecifiers) {
			if ([@"customSectionListStartCell" isEqualToString:specifier.properties[@"key"]]) {
				specifier.properties[@"enabled"] = @NO;
				customSectionCellInsertOffset = [loadedSpecifiers indexOfObject:specifier];
				[loadedSpecifiers removeObjectAtIndex:customSectionCellInsertOffset];
				break;
			}
		}

		// check if custom section info is present
		if (!customSectionsInfo) {
			_specifiers = loadedSpecifiers;
			return _specifiers;
		}
		
		// iterate over every saved custom section and insert them into the specifiers list
		for (NSInteger i = 0; i < [customSectionsInfo count]; i++) {
			
			NSDictionary *sectionInfo = customSectionsInfo[i];
			PSSpecifier *customCellSpecifier = [PSSpecifier preferenceSpecifierNamed:sectionInfo[@"identifier"] target:self set:NULL get:NULL detail:Nil cell:-1 edit:Nil];
			NSMutableDictionary *properties = customCellSpecifier.properties;

			properties[@"cellClass"] = [MELOCustomSectionsListCell class];
			properties[@"customSectionIdentifier"] = sectionInfo[@"identifier"];
			properties[@"customSectionTitle"] = sectionInfo[@"title"];
			properties[@"customSectionSubtitle"] = sectionInfo[@"subtitle"];
			properties[@"customSectionType"] = @"MELO_USER_CUSTOM_SECTION";

			// [self insertSpecifier:customCellSpecifier atEndOfGroup:0]; // caused crash when reload specifiers was called 
			[loadedSpecifiers insertObject:customCellSpecifier atIndex:customSectionCellInsertOffset + i];
		}

		// iterate over every specifier
		for (PSSpecifier *specifier in loadedSpecifiers) {

			// replace newlines in group cell footer text
			if ([specifier cellType] == PSGroupCell) {
				NSString *footerText = [specifier propertyForKey:@"footerText"];
				footerText = [footerText stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n"];
				[specifier setProperty:footerText forKey:@"footerText"];
			}

			// set custom recently added title and subtitle
			if (customRecentlyAddedInfo && specifier.properties[@"cellClass"] == [MELOCustomSectionsListCell class]
				&& [@"MELO_RECENTLY_ADDED_SECTION" isEqualToString:specifier.properties[@"customSectionIdentifier"]]) {

				specifier.properties[@"customSectionTitle"] = customRecentlyAddedInfo[@"title"];
				specifier.properties[@"customSectionSubtitle"] = customRecentlyAddedInfo[@"subtitle"];
			}
		}

		_specifiers = loadedSpecifiers;
	}

	return _specifiers;
}

// get the preference value for a given specifier
- (id)readPreferenceValue:(PSSpecifier *)specifier {
	NSURL *url = [NSURL fileURLWithPath:[NSString stringWithFormat:@"/var/jb/var/mobile/Library/Preferences/%@.plist", specifier.properties[@"defaults"]]];
	NSMutableDictionary *settings = [NSMutableDictionary dictionary];
	[settings addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfURL:url error:nil]];

	return (settings[specifier.properties[@"key"]]) ?: specifier.properties[@"default"];
}

// save the preference value for a given specifier
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

// save custom sections information to the preferences file
- (void)saveData {
	NSURL *url = [NSURL fileURLWithPath:@"/var/jb/var/mobile/Library/Preferences/com.lint.melo.prefs.plist"];
	NSMutableDictionary *settings = [NSMutableDictionary dictionary];
	[settings addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfURL:url error:nil]];

	settings[@"customSectionsInfo"] = [self serializeCustomSections];
	settings[@"customRecentlyAddedInfo"] = [self serializeCustomRecentlyAddedInfo];
	// settings[@"customSectionsInfo"] = [self serializeValidCustomSections];
	[settings writeToURL:url error:nil];

	CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.lint.melo.prefs/prefschanged"), NULL, NULL, YES);
}

// called when the main view is about to be presented on screen
- (void)viewWillAppear:(BOOL)arg1 {
	[super viewWillAppear:arg1];
	self.navigationItem.rightBarButtonItem.tintColor = _accentColor;

	UITableView *table = [self table];
	if (table) {
		table.allowsSelectionDuringEditing = YES;
	}
}

// called after the main view was presented on screen
- (void)viewDidAppear:(BOOL)arg1 {
	[super viewWillAppear:arg1];
	self.navigationItem.rightBarButtonItem.tintColor = _accentColor;

	// UITableView *table = [self table];
	// if (table) {
	// 	table.allowsSelectionDuringEditing = YES;
	// }
}

// UITableViewDataSource method - returns a cell instance for a given index path
- (UITableViewCell *)tableView:(UITableView *)arg1 cellForRowAtIndexPath:(NSIndexPath *)arg2 {

	PSTableCell *cell = (PSTableCell *)[super tableView:arg1 cellForRowAtIndexPath:arg2];
	// PSSpecifier *specifier = [cell specifier];
	
	[cell setCellEnabled:YES];

	// set colors for the cell
	if (cell.specifier.cellType == PSButtonCell) {
		cell.textLabel.textColor = _accentColor;
		cell.textLabel.highlightedTextColor = _accentColor;
	}

	return cell;
}

// UITableViewDataSource method - move a cell from one index path to another 
- (void)tableView:(UITableView *)arg1 moveRowAtIndexPath:(NSIndexPath *)arg2 toIndexPath:(NSIndexPath *)arg3 {

	// get the index in the specifiers array
	NSInteger sourceIndex = [self indexForIndexPath:arg2];
	NSInteger destIndex = [self indexForIndexPath:arg3];

	// move the specifier to the given index
	PSSpecifier *specifier = [self specifierAtIndex:sourceIndex];
	[_specifiers removeObject:specifier];
	[_specifiers insertObject:specifier atIndex:destIndex];

	// save the changes
	[self saveData];
}

// UITableViewDataSource method - determine if a cell is allowed to be moved
- (BOOL)tableView:(UITableView *)arg1 canMoveRowAtIndexPath:(NSIndexPath *)arg2 {

	// only allow a cell to be moved if it is a custom section cell
	return [self isCustomSectionCellAtIndexPath:arg2];
}

// UITableViewDelegate method - always returning the index path allows button cells to be pressed while in editing mode
- (NSIndexPath *)tableView:(UITableView *)arg1 willSelectRowAtIndexPath:(NSIndexPath *)arg2 {
	return arg2;
}

// UITableViewDelegate method - "Asks the delegate to return a new index path to retarget a proposed move of a row."
- (NSIndexPath *)tableView:(UITableView *)arg1 targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)destinationIndexPath {
	
	// PSSpecifier *targetSpecifier = [self specifierAtIndexPath:destinationIndexPath];

	// only allow cells to move within their section
	if (destinationIndexPath.section != sourceIndexPath.section) {
		return sourceIndexPath;
	} 

	return destinationIndexPath;
}

// UITableViewDelegate method - "Asks the delegate for the editing style of a row at a particular location in a table view."
- (UITableViewCellEditingStyle)tableView:(UITableView *)arg1 editingStyleForRowAtIndexPath:(NSIndexPath *)arg2 {

	// only allow editing of custom section cells
	if ([self isCustomSectionCellAtIndexPath:arg2]) {
		return UITableViewCellEditingStyleDelete;
	}

	return UITableViewCellEditingStyleNone;
}

// UITableViewDelegate method - "Asks the delegate whether the background of the specified row should be indented while the table view is in editing mode"
- (BOOL)tableView:(UITableView *)arg1 shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)arg2 {
	return [self isCustomSectionCellAtIndexPath:arg2];
}

// UITableViewDataSource method - "Asks the data source to commit the insertion or deletion of a specified row"
- (void)tableView:(UITableView *)arg1 commitEditingStyle:(UITableViewCellEditingStyle)arg2 forRowAtIndexPath:(NSIndexPath *)arg3 {
	// [super tableView:arg1 commitEditingStyle:arg2 forRowAtIndexPath:arg3];

	if (arg2 == UITableViewCellEditingStyleDelete) {

		PSSpecifier *specifier = [self specifierAtIndexPath:arg3];
		[self removeSpecifier:specifier animated:YES];

	// currently unused
	} else if (arg2 == UITableViewCellEditingStyleInsert) {
		[self addNewCustomSectionCell];
	}

	// save data whenever a row is added or deleted
	[self saveData];
}

// called when the edit / done button is tapped
- (void)editDoneTapped {
	[super editDoneTapped];

	self.navigationItem.rightBarButtonItem.tintColor = _accentColor;

	//[UIView animateWithDuration:1.0 animations:^{
		if ([self editable]) {
			self.navigationItem.leftBarButtonItem = _deleteSectionsButton;
			self.navigationItem.title = nil;
		} else {
			self.navigationItem.leftBarButtonItem = nil;
			self.navigationItem.title = self.title;
		}
	//} completion:nil];

	//TODO: put an editing check before saving to file?
	[self saveData];
}

// TODO: does this actually do anything? when i hit enter in editing mode nothing happens
- (void)_returnKeyPressed:(NSNotification *)arg1 {
	[self.view endEditing:YES];
	[super _returnKeyPressed:arg1];
}

// returns if a given cell is a custom section cell
- (BOOL)isCustomSectionCellAtIndexPath:(NSIndexPath *)arg1 {
	PSSpecifier *specifier = [self specifierAtIndex:[self indexForIndexPath:arg1]];
	return [self isCustomSectionCellSpecifier:specifier];
}

// returns if a given specifier is for a custom section cell
- (BOOL)isCustomSectionCellSpecifier:(PSSpecifier *)specifier {
	return specifier.properties[@"cellClass"] == [MELOCustomSectionsListCell class] 
		&& [@"MELO_USER_CUSTOM_SECTION" isEqualToString:specifier.properties[@"customSectionType"]];
}

// adds a new custom section to the end of the list (handler for button)
- (void)addNewCustomSectionCell {
	PSSpecifier *newCustomCellSpecifier = [PSSpecifier preferenceSpecifierNamed:@"placeholder" target:self set:NULL get:NULL detail:Nil cell:PSTitleValueCell edit:Nil];
	NSMutableDictionary *properties = newCustomCellSpecifier.properties;

	// set properties of the specifier
	properties[@"cellClass"] = [MELOCustomSectionsListCell class];
	properties[@"customSectionIdentifier"] = [[NSProcessInfo processInfo] globallyUniqueString];
	properties[@"customSectionTitle"] = @"";
	properties[@"customSectionSubtitle"] = @"";
	properties[@"customSectionType"] = @"MELO_USER_CUSTOM_SECTION";

	// [self insertSpecifier:newCustomCellSpecifier atEndOfGroup:0 animated:YES];
	NSInteger insertIndex = [self numberOfCustomSections] + 1;
	[self insertSpecifier:newCustomCellSpecifier atIndex:insertIndex animated:YES];
	[self saveData];
}

// permanently removes all custom sections (handler for button)
- (void)deleteAllSections {

	// UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Warning" message:@"All custom sections and their pins will be deleted. Do you want to continue?" preferredStyle:UIAlertControllerStyleAlert];

	// UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
	// UIAlertAction *continueAction = [UIAlertAction actionWithTitle:@"Continue" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * action) {

		NSMutableArray *specifiersToDelete = [NSMutableArray array];

		// find custom cell specifiers
		for (PSSpecifier *specifier in _specifiers) {
			if ([self isCustomSectionCellSpecifier:specifier]) {
				[specifiersToDelete addObject:specifier];
			}
		}

		// remove all matched specifiers
		for (PSSpecifier *specifier in specifiersToDelete) {
			[self removeSpecifier:specifier animated:YES];
		}

		[self saveData];
	// }];

	// [alert addAction:cancelAction];
	// [alert addAction:continueAction];
	// [self presentViewController:alert animated:YES completion:nil];
}

// returns an array of dictionaries representing each custom section
- (NSArray *)serializeCustomSections {

	NSMutableArray *sectionsInfo = [NSMutableArray array];

	// iterate over every specifier
	for (NSInteger i = 0; i < [_specifiers count]; i++) {
		PSSpecifier *specifier = [self specifierAtIndex:i];
		NSMutableDictionary *properties = specifier.properties;

		// check if the specifier is for a custom section
		if ([self isCustomSectionCellSpecifier:specifier]) {

			// extract necessary values (and trim them)
			NSString *title = [properties[@"customSectionTitle"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
			NSString *subtitle = [properties[@"customSectionSubtitle"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
			NSString *identifier = properties[@"customSectionIdentifier"];

			NSDictionary *info = @{@"identifier" : identifier, @"title" : title, @"subtitle" : subtitle};
			[sectionsInfo addObject:info];
		}
	}

	return sectionsInfo;
}

// returns a dictionary representing the renamed recently added section
- (NSDictionary *)serializeCustomRecentlyAddedInfo {

	PSSpecifier *specifier = [self customRecentlyAddedInfoSpecifier];

	NSString *title = [specifier.properties[@"customSectionTitle"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	NSString *subtitle = [specifier.properties[@"customSectionSubtitle"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	NSString *identifier = specifier.properties[@"customSectionIdentifier"];

	return @{@"identifier" : identifier, @"title" : title, @"subtitle" : subtitle};
}

// returns the number of custom section cells
- (NSInteger)numberOfCustomSections {

	NSInteger count = 0;

	for (PSSpecifier *specifier in _specifiers) {

		if ([self isCustomSectionCellSpecifier:specifier]) {
			count++;
		}
	}

	return count;
}

// returns the specifier associated with the custom recently added title and subtitle
- (PSSpecifier *)customRecentlyAddedInfoSpecifier {
	
	for (PSSpecifier *specifier in _specifiers) {
		if (specifier.properties[@"cellClass"] == [MELOCustomSectionsListCell class]
			&& [@"MELO_RECENTLY_ADDED_SECTION" isEqualToString:specifier.properties[@"customSectionIdentifier"]]) {
			return specifier;
		}
	}
	
	return nil;
}

@end
