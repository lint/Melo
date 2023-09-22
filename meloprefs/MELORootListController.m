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
		_killMusicButton = [[UIBarButtonItem alloc] initWithTitle:@"Kill Music" style: UIBarButtonItemStylePlain target:self action: @selector(killMusic)];
		// _killMusicButton.tintColor = self.accentColor;

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

// kills the music app
- (void)killMusic {

	NSTask *t = [[NSTask alloc] init];
    [t setLaunchPath:ROOT_PATH_NS(@"/usr/bin/killall")];
    [t setArguments:[NSArray arrayWithObjects:@"-9", @"Music", nil]];
    [t launch];
}

// set a key to clear any saved data on next app launch
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
