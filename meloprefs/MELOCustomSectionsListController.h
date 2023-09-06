
#import <Preferences/PSListController.h>
#import <UIKit/UIKit.h>

@interface PSListController ()
- (void)_returnKeyPressed:(id)arg1;
@end

@interface PSEditableListController : PSListController
- (void)editDoneTapped;
- (BOOL)performDeletionActionForSpecifier:(PSSpecifier *)arg1;
- (BOOL)editable;
@end

@interface MELOCustomSectionsListController : PSEditableListController
@property(strong, nonatomic) UIBarButtonItem *deleteSectionsButton;
@property(strong, nonatomic) UIColor *accentColor;

- (BOOL)isCustomSectionCellSpecifier:(PSSpecifier *)specifier;
- (BOOL)isCustomSectionCellAtIndexPath:(NSIndexPath *)arg1;
- (void)addNewCustomSectionCell;
- (void)deleteAllSections;
- (NSArray *)serializeCustomSections;
- (NSDictionary *)serializeCustomRecentlyAddedInfo;
- (void)saveData;
- (NSInteger)numberOfCustomSections;
- (PSSpecifier *)customRecentlyAddedInfoSpecifier;
@end
