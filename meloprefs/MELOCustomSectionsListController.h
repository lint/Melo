
#import <Preferences/PSListController.h>
#import <UIKit/UIKit.h>

@interface PSListController ()
- (void)_returnKeyPressed:(id)arg1;
//- (NSInteger)tableView:(UITableView *)arg1 numberOfItemsInSection:(NSInteger)arg2;
@end

@interface PSEditableListController : PSListController
- (void)editDoneTapped;
- (BOOL)performDeletionActionForSpecifier:(PSSpecifier *)arg1;
- (BOOL)editable;
@end

@interface MELOCustomSectionsListController : PSEditableListController
@property(strong, nonatomic) UIBarButtonItem *deleteSectionsButton;
@property(strong, nonatomic) UIColor *accentColor;
@property(strong, nonatomic) NSTimer *autosaveTimer;
@property(assign, nonatomic) BOOL needsSave;

- (BOOL)isCustomListCellAtIndexPath:(NSIndexPath *)arg1;
- (void)addNewCustomSectionCell;
- (void)deleteAllSections;
- (NSArray *)getCurrentCustomSectionsInfo;
- (NSArray *)getValidCurrentCustomSectionsInfo;
- (void)setNeedsSave;
- (void)autosaveTimerFired:(NSTimer *)arg1;
- (void)saveData;
- (void)logSpecifiers;
@end
