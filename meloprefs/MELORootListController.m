#import <Foundation/Foundation.h>
#import "MELORootListController.h"

@implementation MELORootListController

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
	}

	return _specifiers;
}

@end
