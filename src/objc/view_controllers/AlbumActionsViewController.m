
#import "AlbumActionsViewController.h"
#import "../managers/managers.h"
#import "../../interfaces/interfaces.h"
#import "../reflection/reflection.h"
#import "../utilities/utilities.h"

@implementation AlbumActionsViewController

- (instancetype)init{
    
    if ((self = [super init])) {
        
        _buttonMap = [NSMutableDictionary dictionary];

    }

    return self;
}

- (void)viewDidLoad {

    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenRect.size.width;
    CGFloat screenHeight = screenRect.size.height;
    
    // self.preferredContentSize = CGSizeMake(screenWidth, screenHeight / 2);
    // [self setPreferredContentSize:CGSizeMake(screenWidth, screenHeight / 2)];


    [super viewDidLoad];

    [[Logger sharedInstance] logString:@"AlbumActionsViewController - viewDidLoad"];
    
    UIView *view = [self view];

    // CGRect backgroundFrame = CGRectMake(view.frame.origin.x, view.frame.size.height / 2, view.frame.size.width, view.frame.size.height / 2);
    
    // view.frame = backgroundFrame;
    view.backgroundColor = [UIColor blackColor];
    // [view addSubview:background];

    RecentlyAddedManager *recentlyAddedManager = [self recentlyAddedManager];


    CGFloat buttonHeight = 50;
    CGFloat buttonWidth = screenWidth - 40;
    CGFloat buttonOffset = 70;
    CGFloat currButtonYOrigin = 20;
    
    // Album *targetAlbum = [recentlyAddedManager albumAtAdjustedIndexPath:_albumAdjustedIndexPath];

    /* add the move to section action */

    // iterate over every section
    for (NSInteger i = 0; i < [recentlyAddedManager numberOfSections]; i++) {

        [[Logger sharedInstance] logStringWithFormat:@"i: %ld", i];
        
        // don't have move action to current section
        if (i == _albumAdjustedIndexPath.section) {
            continue;
        }

        Section *section = [recentlyAddedManager sectionAtIndex:i];
        NSString *title = [NSString stringWithFormat:@"Move to '%@'", section.title];
        NSString *ident = section.identifier;

        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button addTarget:self action:@selector(handleButtonPress:) forControlEvents:UIControlEventTouchUpInside];
        [button setTitle:title forState:UIControlStateNormal];
        button.backgroundColor = [UIColor redColor];
        button.frame = CGRectMake(20, currButtonYOrigin, buttonWidth, buttonHeight);
        currButtonYOrigin += buttonOffset;
        [view addSubview:button];

        [_buttonMap setObject:button forKey:ident];
    }

    // add shift left action if possible
    if ([recentlyAddedManager canShiftAlbumAtAdjustedIndexPath:_albumAdjustedIndexPath movingLeft:YES]) {
        NSString *title = @"Shift Left";
        NSString *ident = @"MELO_ACTION_SHIFT_LEFT";

        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button addTarget:self action:@selector(handleButtonPress:) forControlEvents:UIControlEventTouchUpInside];
        [button setTitle:title forState:UIControlStateNormal];
        button.backgroundColor = [UIColor redColor];
        button.frame = CGRectMake(20, currButtonYOrigin, buttonWidth, buttonHeight);
        currButtonYOrigin += buttonOffset;
        [view addSubview:button];

        [_buttonMap setObject:button forKey:ident];
    }

    // add shift right action if possible
    if ([recentlyAddedManager canShiftAlbumAtAdjustedIndexPath:_albumAdjustedIndexPath movingLeft:NO]) {
        NSString *title = @"Shift Right";
        NSString *ident = @"MELO_ACTION_SHIFT_RIGHT";

        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button addTarget:self action:@selector(handleButtonPress:) forControlEvents:UIControlEventTouchUpInside];
        [button setTitle:title forState:UIControlStateNormal];
        button.backgroundColor = [UIColor redColor];
        button.frame = CGRectMake(20, currButtonYOrigin, buttonWidth, buttonHeight);
        currButtonYOrigin += buttonOffset;
        [view addSubview:button];

        [_buttonMap setObject:button forKey:ident];
    }
}

- (void)handleButtonPress:(UIButton *)sender {

    [self dismissViewControllerAnimated:YES completion:nil];

    NSString *ident = [_buttonMap objectForKey:sender];

    for (NSString *key in _buttonMap) {
        id button = _buttonMap[key];
        if (button == sender) {
            ident = key;
            break;
        }
    }

    if (!ident) {
        [[Logger sharedInstance] logString:@"could not locate button for ident..."];
        return;
    }

    if ([ident isEqualToString:@"MELO_ACTION_SHIFT_LEFT"]) {
        [_libraryRecentlyAddedViewController handleShiftAction:YES];
    } else if ([ident isEqualToString:@"MELO_ACTION_SHIFT_RIGHT"]) {
        [_libraryRecentlyAddedViewController handleShiftAction:NO];
    } else {
        NSInteger sectionIndex = [_recentlyAddedManager sectionIndexForIdentifier:ident];
        [_libraryRecentlyAddedViewController handleMoveToSectionAction:sectionIndex];
    }
}

@end