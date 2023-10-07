
#import "AlbumActionsViewController.h"
#import "../managers/managers.h"
#import "../../interfaces/interfaces.h"
#import "../reflection/reflection.h"
#import "../utilities/utilities.h"
#import "MeloModernSlider.h"

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
        [Logger logStringWithFormat:@"%@", section];
        NSString *sectionTitle = [section displayTitle];
        [Logger logStringWithFormat:@"sectionTitle: %@", sectionTitle];
        // NSString *title = [NSString stringWithFormat:@"Move to '%@'", sectionTitle]; // this broke for some reason... it started filling it with garbage? even tho the string was fine? idk
        NSString *title = [@"Move to: " stringByAppendingString:sectionTitle ?: @"<no title>"];
        NSString *ident = section.identifier;

        [Logger logStringWithFormat:@"title string: %@", title];
        [Logger logStringWithFormat:@"%@", section.title];

        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button addTarget:self action:@selector(handleButtonPress:) forControlEvents:UIControlEventTouchUpInside];
        [button setTitle:title forState:UIControlStateNormal];
        button.backgroundColor = [UIColor systemPinkColor];
        button.frame = CGRectMake(20, currButtonYOrigin, buttonWidth, buttonHeight);
        button.layer.cornerRadius = 10;
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
        button.backgroundColor = [UIColor systemPinkColor];
        button.frame = CGRectMake(20, currButtonYOrigin, buttonWidth, buttonHeight);
        button.layer.cornerRadius = 10;
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
        button.backgroundColor = [UIColor systemPinkColor];
        button.frame = CGRectMake(20, currButtonYOrigin, buttonWidth, buttonHeight);
        button.layer.cornerRadius = 10;
        currButtonYOrigin += buttonOffset;
        [view addSubview:button];

        [_buttonMap setObject:button forKey:ident];
    }

    // add wiggle mode action if possible
    if ([[MeloManager sharedInstance] prefsBoolForKey:@"showWiggleModeActionEnabled"]) {
        // TODO: should i check prefs here? not that it really matters

        NSString *title = @"Wiggle Mode";
        NSString *ident = @"MELO_ACTION_WIGGLE";

        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button addTarget:self action:@selector(handleButtonPress:) forControlEvents:UIControlEventTouchUpInside];
        [button setTitle:title forState:UIControlStateNormal];
        button.backgroundColor = [UIColor systemPinkColor];
        button.frame = CGRectMake(20, currButtonYOrigin, buttonWidth, buttonHeight);
        button.layer.cornerRadius = 10;
        currButtonYOrigin += buttonOffset;
        [view addSubview:button];

        [_buttonMap setObject:button forKey:ident];   
    }

    MeloModernSlider *testSlider = [[MeloModernSlider alloc] initWithFrame:CGRectMake((screenWidth - (buttonWidth * .80)) / 2, currButtonYOrigin, buttonWidth * .80, buttonHeight)];
    [testSlider setImagesForMinImage:@"speaker.fill" maxImage:@"speaker.wave.3.fill"];
    currButtonYOrigin += buttonOffset;
    [_buttonMap setObject:testSlider forKey:@"TEST_SLIDER"];
    [view addSubview:testSlider];
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
        [_libraryRecentlyAddedViewController handleActionShiftAlbumAtIndexPath:self.albumAdjustedIndexPath movingLeft:YES];
    } else if ([ident isEqualToString:@"MELO_ACTION_SHIFT_RIGHT"]) {
        [_libraryRecentlyAddedViewController handleActionShiftAlbumAtIndexPath:self.albumAdjustedIndexPath movingLeft:NO];
    } else if ([ident isEqualToString:@"MELO_ACTION_WIGGLE"]) {
        [_libraryRecentlyAddedViewController toggleWiggleMode];
    } else {
        NSInteger sectionIndex = [_recentlyAddedManager sectionIndexForIdentifier:ident];
        [_libraryRecentlyAddedViewController handleActionMoveAlbumAtIndexPath:self.albumAdjustedIndexPath toSection:sectionIndex];
    }
}

@end