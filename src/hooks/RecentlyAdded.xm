
#import <UIKit/UIKit.h>
#import <HBLog.h>
#import "../objc/objc_classes.h"
#import "../interfaces/interfaces.h"

NSIndexPath *indexPathForContextMenuOverride;
NSIndexPath *indexPathForContextActions;

// should i make these global variables thread safe?
BOOL shouldAddAlbumPinContextMenuAction = NO;

%hook MPModelLibraryRequest

- (void)setContentRange:(NSRange)arg1 {
    [[Logger sharedInstance] logStringWithFormat:@"MPModelLibraryRequest: %p - setContentRange: %@", self, arg1];
    [[Logger sharedInstance] logStringWithFormat:@"length: %li", (long)arg1.length];

    arg1.length = 10000;

    %orig;
}

%end

// doesn't work on iPad I suppose
%hook UICollectionViewFlowLayout

// changes the number of columns in UICollectionViews
- (void)setItemSize:(CGSize)arg1 {

    // so the cell size will only be applied to albums in LibraryRecentlyAddedViewController
    id dataSource = [[self collectionView] dataSource];

    if ([dataSource isKindOfClass:objc_getClass("MusicApplication.LibraryRecentlyAddedViewController")]) {

        // APManager *apManager = [APManager sharedInstance];

        MeloManager *meloManager = [MeloManager sharedInstance];
        CGSize size;

        if ([meloManager prefsBoolForKey:@"customNumColumnsEnabled"]) {

            NSInteger numColumns = [[meloManager prefsObjectForKey:@"customNumColumns"] integerValue];
            NSInteger screenWidth = [[UIScreen mainScreen] bounds].size.width;

            float albumWidth = floor((screenWidth - 20 * 2 - [meloManager minimumCellSpacing] * (numColumns - 1)) / numColumns);
            float albumHeight = (albumWidth * 1.5 - albumWidth) > 40 ? floor(albumWidth * 1.5) : albumWidth + 40;

            size = [meloManager prefsBoolForKey:@"hideAlbumTextEnabled"] ? CGSizeMake(albumWidth, albumWidth) : CGSizeMake(albumWidth, albumHeight);
        } else {
            size = [meloManager prefsBoolForKey:@"hideAlbumTextEnabled"] ? CGSizeMake(arg1.width, arg1.width) : arg1;
        }

        %orig(size);
    } else {
        %orig;
    }
}

%end

// %hook UIView

// - (void)layoutSubviews {
//     %orig;
// }

// - (id)tintColor {
//     return [UIColor redColor];
// }

// %end

%hook TitleSectionHeaderView
%property(strong, nonatomic) NSString *sectionIdentifier;
%end

static LibraryRecentlyAddedViewController *currentLRAVC;

%hook LibraryRecentlyAddedViewController
%property(strong, nonatomic) RecentlyAddedManager *recentlyAddedManager;
%property(strong, nonatomic) AlbumActionsViewController *albumActionsVC;

- (id)init {

    RecentlyAddedManager *recentlyAddedManager = [RecentlyAddedManager new];
    [self setRecentlyAddedManager:recentlyAddedManager];
    
    return %orig;
}

- (void)viewWillAppear:(BOOL)arg1 {

    // use this to detect which library view controller it is?
    // need to be able to read the title, which does get set later...able
    // any other way to differentiate them?

    currentLRAVC = self;

    %orig;

    [[Logger sharedInstance] logString:[NSString stringWithFormat:@"LRAVC: %p - viewWillAppear:(%i)", self, arg1]];
}

- (void)viewDidLoad {
    [[Logger sharedInstance] logStringWithFormat:@"LRAVC: %p - viewDidLoad", self];
    %orig;

    if ([[MeloManager sharedInstance] prefsBoolForKey:@"customActionMenuEnabled"]) {
        
        UICollectionView *collectionView = MSHookIvar<UICollectionView *>(self, "_collectionView");
        [[Logger sharedInstance] logStringWithFormat:@"collectionView: %p", collectionView];

        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTapOnAlbum:)];
        tapGesture.numberOfTapsRequired = 1;
        tapGesture.numberOfTouchesRequired = 2;
        
        for (id gesture in [collectionView gestureRecognizers]) {
            // [[Logger sharedInstance] logStringWithFormat:@"gestureRecognizer: %@", gesture];

            [gesture requireGestureRecognizerToFail:tapGesture];
        }
        [collectionView addGestureRecognizer:tapGesture];
    }
}

- (void)setTitle:(NSString *)title {
    [[Logger sharedInstance] logStringWithFormat:@"LRAVC %p - setTitle:(%@)", self, title];

    %orig;

    NSBundle *bundle = [NSBundle bundleWithPath:[NSString stringWithFormat:@"%@%@", [[NSBundle mainBundle] bundlePath], @"/Frameworks/MusicApplication.framework"]];

    NSString *localizedRecentlyAddedTitle = NSLocalizedStringFromTableInBundle(@"RECENTLY_ADDED_VIEW_TITLE", @"Music", bundle, nil);
    NSString *localizedDownloadedMusicTitle = NSLocalizedStringFromTableInBundle(@"RECENTLY_DOWNLOADED_VIEW_TITLE", @"Music", bundle, nil);

    if ([title isEqualToString:localizedRecentlyAddedTitle]) {
        [[self recentlyAddedManager] setIsDownloadedMusic:NO];
    } else if ([title isEqualToString:localizedDownloadedMusicTitle]) {
        [[self recentlyAddedManager] setIsDownloadedMusic:YES];
    }

    // [[self recentlyAddedManager] loadData];
}

/* methods that deal with displaying sections */

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)arg1 {
    [[Logger sharedInstance] logString:[NSString stringWithFormat:@"LRAVC: %p - numberOfSectionsInCollectionView:(%p)", self, arg1]];

    // get the recently added manager
    RecentlyAddedManager *recentlyAddedManager = [self recentlyAddedManager];
    
    // check if the manager is not ready to inject fake data
    if (![recentlyAddedManager isReadyForUse]) {
        return %orig;
    }
    
    return [recentlyAddedManager numberOfSections];
}

- (NSInteger)collectionView:(UICollectionView *)arg1 numberOfItemsInSection:(NSInteger)arg2 {
    [[Logger sharedInstance] logString:[NSString stringWithFormat:@"LRAVC: %p - collectionView:(%p) numberOfItemsInSection:(%li)", self, arg1, arg2]];

    // get the recently added manager
    RecentlyAddedManager *recentlyAddedManager = [self recentlyAddedManager];
    
    // check if the manager is not ready to inject fake data
    if (![recentlyAddedManager isReadyForUse]) {
        return %orig;
    }

    return [recentlyAddedManager numberOfAlbumsInSection:arg2];
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)arg1 viewForSupplementaryElementOfKind:(id)arg2 atIndexPath:(NSIndexPath *)arg3 {
    [[Logger sharedInstance] logString:[NSString stringWithFormat:@"LRAVC: %p - collectionView:(%p) viewForSupplementaryElementOfKind:(%@) atIndexPath:<%ld-%ld>", self, arg1, arg2, arg3.section, arg3.item]];
    
    // get the recently added manager
    RecentlyAddedManager *recentlyAddedManager = [self recentlyAddedManager];

    // check if the manager is not ready to inject fake data
    if (![recentlyAddedManager isReadyForUse]) {
        return %orig;
    }

    Section *section = [recentlyAddedManager sectionAtIndex:arg3.section];

    UICollectionReusableView *orig = %orig;
    TitleSectionHeaderView *titleHeaderView = (TitleSectionHeaderView *)orig;

    if (section.title) {
        [titleHeaderView setTitle:section.title];
    }

    if (section.subtitle) {
        [titleHeaderView setSubtitle:section.subtitle];
    }

    return orig;
}

// - (void)collectionView:(UICollectionView *)arg1 didEndDisplayingSupplementaryView:(UICollectionReusableView *)arg2 forElementOfKind:(id)arg3 atIndexPath:(NSIndexPath *)arg4 {
- (void)collectionView:(id)arg1 didEndDisplayingSupplementaryView:(id)arg2 forElementOfKind:(id)arg3 atIndexPath:(id)arg4 {
    [[Logger sharedInstance] logString:[NSString stringWithFormat:@"LRAVC: %p - collectionView:(%p) didEndDisplayingSupplementaryView:(%@) forElementOfKind:(%@) atIndexPath:<%@>", self, arg1, arg2, arg3, arg4]];

    // get the recently added manager
    RecentlyAddedManager *recentlyAddedManager = [self recentlyAddedManager];

    // check if the manager is not ready to inject fake data
    if (![recentlyAddedManager isReadyForUse]) {
        %orig;
        return;
    }

    %orig;
}

/* methods that deal with displaying albums */

- (id)collectionView:(UICollectionView *)arg1 cellForItemAtIndexPath:(NSIndexPath *)arg2 {
    [[Logger sharedInstance] logString:[NSString stringWithFormat:@"LRAVC: %p - collectionView:(%p) cellForItemAtIndexPath:<%ld-%ld>", self, arg1, arg2.section, arg2.item]];

    // in old code, this sets the custom "identifier" property on the AlbumCell returned by %orig(injected)

    // check if recently added manager is ready to inject data
    RecentlyAddedManager *recentlyAddedManager = [self recentlyAddedManager];
    if (![recentlyAddedManager isReadyForUse]) {
        return %orig;
    }

    NSIndexPath *realIndexPath = [recentlyAddedManager translateIndexPath:arg2];
    [[Logger sharedInstance] logString:[NSString stringWithFormat:@"realIndexPath:<%ld-%ld>", realIndexPath.section, realIndexPath.item]];

    // use the injected data
    id orig = %orig(arg1, [recentlyAddedManager translateIndexPath:arg2]);
    
    // // add a double tap gesture recognizer to every album cell
    // if (![orig gestureRecognizers] || [[orig gestureRecognizers] count] == 0) {
    //     UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTapOnAlbum:)];
    //     tapGesture.numberOfTapsRequired = 2;
        
    //     [orig addGestureRecognizer:tapGesture];
    // }

    if ([[MeloManager sharedInstance] prefsBoolForKey:@"hideAlbumTextEnabled"]) {
        UIView *textStackView = MSHookIvar<UIView *>(orig, "textStackView");
        [textStackView setHidden:YES];
        // HBLogDebug(@"\ttextStackView:%@", textStackView);
        // [MSHookIvar<UIView *>(orig, "textStackView") setHidden:YES];
    }

    return orig;
}

- (id)collectionView:(UICollectionView *)arg1 contextMenuConfigurationForItemAtIndexPath:(NSIndexPath *)arg2 point:(CGPoint)arg3 {
    [[Logger sharedInstance] logString:[NSString stringWithFormat:@"LRAVC: %p - collectionView:(%p) contextMenuConfigurationForItemAtIndexPath:<%ld-%ld> point:(do later if needed)", self, arg1, arg2.section, arg2.item]];

    // in old code, this does some additional overrides and setting of global variables to ensure the context menu option is added properly
    
    // check if recently added manager is ready to inject data
    RecentlyAddedManager *recentlyAddedManager = [self recentlyAddedManager];
    if (![recentlyAddedManager isReadyForUse]) {
        return %orig;
    }

    shouldAddAlbumPinContextMenuAction = YES;

    NSIndexPath *realIndexPath = [recentlyAddedManager translateIndexPath:arg2];
    indexPathForContextActions = arg2;
    indexPathForContextMenuOverride = arg2;

    id orig = %orig(arg1, realIndexPath, arg3);
    indexPathForContextMenuOverride = nil;

    //HBLogDebug(@"\tmenu previewProvider: %@", [orig previewProvider]);

    return orig;

    // // use injected data
    // return %orig(arg1, [recentlyAddedManager translateIndexPath:arg2], arg3);
}

- (void)collectionView:(UICollectionView *)arg1 willEndContextMenuInteractionWithConfiguration:(id)arg2 animator:(id)arg3 {
    [[Logger sharedInstance] logString:[NSString stringWithFormat:@"LRAVC: %p - collectionView:(%p) willEndContextMenuInteractionWithConfiguration: (%p) animator:(%p)", self, arg1, arg2, arg3]];

    %orig;

    shouldAddAlbumPinContextMenuAction = NO;
    //indexPathForContextMenuOverride = nil;
}

- (void)collectionView:(UICollectionView *)arg1 willDisplayCell:(id)arg2 forItemAtIndexPath:(NSIndexPath *)arg3 {
    [[Logger sharedInstance] logString:[NSString stringWithFormat:@"LRAVC: %p - collectionView:(%p) willDisplayCell:(%p) forItemAtIndexPath:<%ld-%ld>", self, arg1, arg2, arg3.section, arg3.item]];

    // in old code, contained some checks for if the requested item is out of bounds for some reason
    // i remember this fixing some crash, due to the system using the default index paths to request but not being able to properly translate them?
    // not really sure, but i bet it'll come up again..
    
    // check if recently added manager is ready to inject data
    RecentlyAddedManager *recentlyAddedManager = [self recentlyAddedManager];
    if (![recentlyAddedManager isReadyForUse]) {
        %orig;
        return;
    }
    NSIndexPath *adjustedIndexPath = [recentlyAddedManager translateIndexPath:arg3];

    [[Logger sharedInstance] logString:[NSString stringWithFormat:@"adjustedIndexPath:<%ld-%ld>", adjustedIndexPath.section, adjustedIndexPath.item]];

    // use injected data
    %orig(arg1, arg2, [recentlyAddedManager translateIndexPath:arg3]);

    // [[Logger sharedInstance] logString:@"finished willDisplayCell"];



    // out of bounds check that i used in the old code
    // if (arg3.item >= [self collectionView:MSHookIvar<UICollectionView *>(self, "_collectionView") numberOfItemsInSection:arg3.section]) {
    //     // HBLogDebug(@"\tadjusted indexPath is out of bounds for pinnedSection: %ld? something probably went wrong", arg3.section);
    //     [[Logger sharedInstance] logString:@"failed index path bounds check? just don't call method??"];
    // } else {
    //     %orig(arg1, arg2, [recentlyAddedManager translateIndexPath:arg3]);
    // }


}

- (void)collectionView:(UICollectionView *)arg1 didEndDisplayingCell:(id)arg2 forItemAtIndexPath:(NSIndexPath *)arg3 {
    [[Logger sharedInstance] logString:[NSString stringWithFormat:@"LRAVC: %p - collectionView:(%p) didEndDisplayingCell:(%p) forItemAtIndexPath:<%ld-%ld>", self, arg1, arg2, arg3.section, arg3.item]];
    
    // in old code, this did not ever inject a different index path, it just called %orig, so maybe do that again here as well..
    
    // check if recently added manager is ready to inject data
    RecentlyAddedManager *recentlyAddedManager = [self recentlyAddedManager];
    if (![recentlyAddedManager isReadyForUse]) {
        %orig;
        return;
    }

    // use injected data
    // %orig(arg1, arg2, [recentlyAddedManager translateIndexPath:arg3]);
    %orig;
}

- (BOOL)collectionView:(UICollectionView *)arg1 shouldSelectItemAtIndexPath:(NSIndexPath *)arg2 { 
    [[Logger sharedInstance] logString:[NSString stringWithFormat:@"LRAVC: %p - collectionView:(%p) shouldSelectItemAtIndexPath:<%ld-%ld>", self, arg1, arg2.section, arg2.item]];

    // check if recently added manager is ready to inject data
    RecentlyAddedManager *recentlyAddedManager = [self recentlyAddedManager];
    if (![recentlyAddedManager isReadyForUse]) {
        return %orig;
    }

    [[Logger sharedInstance] logStringWithFormat:@"realIndexPath: %@", [recentlyAddedManager translateIndexPath:arg2]];

    // use injected data
    // BOOL orig = %orig(arg1, [recentlyAddedManager translateIndexPath:arg2]);
    BOOL orig = %orig;
    [[Logger sharedInstance] logStringWithFormat:@"result: %i", orig];
    return orig;
    // return YES;

    // this method does not translate the paths because if it does, for some reason calling %orig with the real path causes issues with selecting an album
    // my guess for what happens:
    // let's say all of the albums are in the recently added section and none in the pinned section
    // call %orig with the real index path
    // this index path will get passed to [UICollectionView cellForItemAtIndexPath:]
    // now the the translated / real index path has section 0, but the cellForItemAtIndexPath is going off the faked positions of the albums?
    // so it doesn't return anything and then %orig returns NO for shouldSelectItemAtIndexPath
    // thus, if we just pass the adjusted index path to %orig, that will get passed to the UICollectionView method, which will succeed
    // and then it all works out
    // my old code DOES translate the index path tho... so not sure what's different
}

- (void)collectionView:(UICollectionView *)arg1 didSelectItemAtIndexPath:(NSIndexPath *)arg2 { 
    [[Logger sharedInstance] logString:[NSString stringWithFormat:@"LRAVC: %p - collectionView:(%p) didSelectItemAtIndexPath:<%ld-%ld>", self, arg1, arg2.section, arg2.item]];
  
    // check if recently added manager is ready to inject data
    RecentlyAddedManager *recentlyAddedManager = [self recentlyAddedManager];
    if (![recentlyAddedManager isReadyForUse]) {
        %orig;
        return;
    }

    [[Logger sharedInstance] logStringWithFormat:@"realIndexPath: %@", [recentlyAddedManager translateIndexPath:arg2]];

    // use injected data
    %orig(arg1, [recentlyAddedManager translateIndexPath:arg2]);
}

- (BOOL)collectionView:(UICollectionView *)arg1 shouldHighlightItemAtIndexPath:(NSIndexPath *)arg2 {
    [[Logger sharedInstance] logString:[NSString stringWithFormat:@"LRAVC: %p - collectionView:(%p) shouldHighlightItemAtIndexPath:<%ld-%ld>", self, arg1, arg2.section, arg2.item]];
    
    // check if recently added manager is ready to inject data
    RecentlyAddedManager *recentlyAddedManager = [self recentlyAddedManager];
    if (![recentlyAddedManager isReadyForUse]) {
        return %orig;
    }

    // use injected data
    return %orig(arg1, [recentlyAddedManager translateIndexPath:arg2]);
}

// -(id)_collectionView:(id)arg1 indexPathForSectionIndexTitle:(id)arg2 atIndex:(NSInteger)arg3 {
// }

// -(id)_sectionIndexTitlesForCollectionView:(id)arg1 {
// }

// -(id)_collectionView:(id)arg1 canEditItemAtIndexPath:(id)arg2 {
// }

%new
- (void)checkAlbumOrder {
    [[Logger sharedInstance] logString:[NSString stringWithFormat:@"LRAVC: %p - checkAlbumOrder", self]];

    RecentlyAddedManager *recentlyAddedManager = [self recentlyAddedManager];
    MPModelResponse *response = MSHookIvar<MPModelResponse *>(self, "_modelResponse");
    NSMutableArray *realAlbumOrder = [NSMutableArray array];

    if (response) {

        NSInteger realIndex = 0;

        for (id item in [[response results] allItems]) {

            NSString *identifier = [@([[item identifiers] persistentID]) stringValue];
            NSDictionary *info;

            if ([item album]) {
                MPModelAlbum *album = [item album];
                info = @{@"identifier" : identifier, 
                    @"artist" : [[album artist] name] ?: @"TEMP_ARTIST_NAME", 
                    @"title" : [album title] ?: @"TEMP_ALBUM_TITLE",
                    @"realIndex": @(realIndex++)};
            } else if ([item playlist]) {
                MPModelPlaylist *playlist = [item playlist];
                info = @{@"identifier" : identifier, 
                    @"artist" : [[playlist curator] name] ?: @"TEMP_ARTIST_NAME",
                    @"title" : [playlist name] ?: @"TEMP_PLAYLIST_NAME",
                    @"realIndex": @(realIndex++)};
            } else {
                [[Logger sharedInstance] logString:@"could not get either album or playlist from library response"];
            }

            Album *album = [[Album alloc] initWithDictionary:info];

            [realAlbumOrder addObject:album];
            [[Logger sharedInstance] logString:[NSString stringWithFormat:@"id: %@, artist: %@, title: %@", info[@"identifier"], info[@"artist"], info[@"title"]]];
        }

        [recentlyAddedManager processRealAlbumOrder:realAlbumOrder];
    }
}

%new
- (void)handleMoveToSectionAction:(NSInteger)sectionIndex {
    [[Logger sharedInstance] logStringWithFormat:@"LRAVC: %p - handleMoveToSectionAction:(%ld)", self, sectionIndex];

    // ideally, if moving the album back into the recently added section, it will move it to the album's proper place
    // for now tho, i'll just move it to the first spot, then it will move back whenever the app is refreshed since the recently added section is not saved

    RecentlyAddedManager *recentlyAddedManager = [self recentlyAddedManager];

    NSIndexPath *sourceAdjustedIndexPath = indexPathForContextActions;
    NSIndexPath *destAdjustedIndexPath = [NSIndexPath indexPathForItem:0 inSection:sectionIndex];

    [[Logger sharedInstance] logStringWithFormat:@"indexPathForContextActions: %@", indexPathForContextActions];

    // commented out so that the block does not cause a crash while patching with allemand
    // // perform the move operation
    // [self moveAlbumCellFromAdjustedIndexPath:sourceAdjustedIndexPath toAdjustedIndexPath:destAdjustedIndexPath dataUpdateBlock:^(){
    //     [recentlyAddedManager moveAlbumAtAdjustedIndexPath:destAdjustedIndexPath toAdjustedIndexPath:destAdjustedIndexPath];
    // }];        

    [recentlyAddedManager moveAlbumAtAdjustedIndexPath:sourceAdjustedIndexPath toAdjustedIndexPath:destAdjustedIndexPath];
    [self moveAlbumCellFromAdjustedIndexPath:sourceAdjustedIndexPath toAdjustedIndexPath:destAdjustedIndexPath dataUpdateBlock:nil]; 
}

%new 
- (void)handleShiftAction:(BOOL)isMovingLeft {
    [[Logger sharedInstance] logStringWithFormat:@"LRAVC: %p - handleShiftAction:isMovingLeft:(%i)", self, isMovingLeft];

    RecentlyAddedManager *recentlyAddedManager = [self recentlyAddedManager];

    NSIndexPath *sourceAdjustedIndexPath = indexPathForContextActions;
    NSIndexPath *destAdjustedIndexPath;
    
    // the destination is one to the left or right of the current item
    if (isMovingLeft) {
        destAdjustedIndexPath = [NSIndexPath indexPathForItem:indexPathForContextActions.item - 1 inSection:indexPathForContextActions.section];
    } else {
        destAdjustedIndexPath = [NSIndexPath indexPathForItem:indexPathForContextActions.item + 1 inSection:indexPathForContextActions.section];
    }

    // commented out so that the block does not cause a crash while patching with allemand
    // // perform the shift operation
    // [self moveAlbumCellFromAdjustedIndexPath:sourceAdjustedIndexPath toAdjustedIndexPath:destAdjustedIndexPath dataUpdateBlock:^(){
    //     [recentlyAddedManager moveAlbumAtAdjustedIndexPath:sourceAdjustedIndexPath toAdjustedIndexPath:destAdjustedIndexPath];
    // }];

    [recentlyAddedManager moveAlbumAtAdjustedIndexPath:sourceAdjustedIndexPath toAdjustedIndexPath:destAdjustedIndexPath];
    [self moveAlbumCellFromAdjustedIndexPath:sourceAdjustedIndexPath toAdjustedIndexPath:destAdjustedIndexPath dataUpdateBlock:nil]; 
}

%new 
- (void)moveAlbumCellFromAdjustedIndexPath:(NSIndexPath *)sourceIndexPath toAdjustedIndexPath:(NSIndexPath *)destIndexPath dataUpdateBlock:(void (^)())dataUpdateBlock {
    [[Logger sharedInstance] logStringWithFormat:@"LRAVC: %p - moveAlbumCellFromAdjustedIndexPath:%@ toAdjustedIndexPath:%@", self, sourceIndexPath, destIndexPath];

    // RecentlyAddedManager *recentlyAddedManager = [self recentlyAddedManager];
    UICollectionView *collectionView = MSHookIvar<UICollectionView *>(self, "_collectionView");

    // old code first uncollapsed the destination section if it was collapsed

    // execute the data update
    // dataUpdateBlock();

    // old code then made source section always "visible" and preserved the state in a variable

    // move the cell
    [collectionView moveItemAtIndexPath:sourceIndexPath toIndexPath:destIndexPath];

    // old code would then restore the source section's visible state 
    // and would also hide the source section if it became empty and that option was enabled

}

%new
- (void)handleDoubleTapOnAlbum:(UITapGestureRecognizer *)sender {
    [[Logger sharedInstance] logStringWithFormat:@"LRAVC: %p - handleDoubleTapOnAlbum:(%@)", self, sender];

    if (sender.state == UIGestureRecognizerStateRecognized) {
        // handling code

        [[Logger sharedInstance] logString:@"state recognized"];

        RecentlyAddedManager *recentlyAddedManager = [self recentlyAddedManager];
        UICollectionView *collectionView = MSHookIvar<UICollectionView *>(self, "_collectionView");

        CGPoint point = [sender locationInView:collectionView];
        NSIndexPath *indexPath = [collectionView indexPathForItemAtPoint:point];

        [[Logger sharedInstance] logStringWithFormat:@"indexPath: %@", indexPath];

        Album *album = [recentlyAddedManager albumAtAdjustedIndexPath:indexPath];
        [[Logger sharedInstance] logStringWithFormat:@"album: %@", album];

        // ActionsPresentationController *presController = [ActionsPresentationController new];

        AlbumActionsViewController *albumActionsVC = [AlbumActionsViewController new];
        albumActionsVC.libraryRecentlyAddedViewController = self;
        albumActionsVC.recentlyAddedManager = recentlyAddedManager;
        albumActionsVC.albumAdjustedIndexPath = indexPath;
        indexPathForContextActions = indexPath;

        albumActionsVC.modalPresentationStyle = UIModalPresentationPopover;
        albumActionsVC.preferredContentSize = CGSizeMake(280, 230);
        albumActionsVC.popoverPresentationController.delegate = self;

        // albumActionsVC.popoverPresentationController.sourceView = self.view;
        // albumActionsVC.popoverPresentationController.sourceRect = CGRectMake(384, -120, 280, 230);
        [self setAlbumActionsVC:albumActionsVC];

        [self presentViewController:albumActionsVC animated:YES completion:nil];
        // [self pushViewController:albumActionsVC animated:YES];
    }
}

%new
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return [[MeloManager sharedInstance] minimumCellSpacing];
}

%new
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return [[MeloManager sharedInstance] minimumCellSpacing];
}

%end

%hook UICollectionView

- (void)setContentSize:(CGRect)arg1 {
    //HBLogWarn(@"UICollectionView: %p setContentSize: %@", self, NSStringFromCGRect(arg1));
    %orig;
}

- (void)moveItemAtIndexPath:(NSIndexPath *)arg1 toIndexPath:(NSIndexPath *)arg2 {
    // HBLogWarn(@"UICollectionView moveItemAtIndexPath: <%ld,%ld> toIndexPath: <%ld,%ld>", arg1.section, arg1.item, arg2.section, arg2.item);
    %orig;
}

- (void)reloadData {
    //%orig; //having it first seems to fix the didEndDisplayingCell crash bug, but then isReadyForUse is not YES in time for when the number of sections is checked

    id dataSource = [self dataSource];

    %orig;

    if (dataSource && [dataSource isKindOfClass:objc_getClass("MusicApplication.LibraryRecentlyAddedViewController")]) {
        [dataSource checkAlbumOrder];
    }

    //%orig;
}

// prevents crashing when opening a context menu in a section other than 0
- (void)reloadItemsAtIndexPaths:(NSArray *)arg1 {

    if (indexPathForContextMenuOverride) {
        [[Logger sharedInstance] logString:[NSString stringWithFormat:@"UICollectionView: %p - inject index path during reload", self]];
        arg1 = @[indexPathForContextMenuOverride];
    }

    %orig;
}

// allows the context menu to pop up with the correct album without crashing
// fairly certain this is just used to find the initial location of the selected cell when called in use of the context menu, but whatever the reason, it's necessary
- (UICollectionViewCell *)cellForItemAtIndexPath:(NSIndexPath *)arg1 {
    [[Logger sharedInstance] logStringWithFormat:@"UICollectionView: %p cellForItemAtIndexPath: %@", self, arg1];

    if (indexPathForContextMenuOverride) {
        [[Logger sharedInstance] logStringWithFormat:@"\toverriding index path to: %@", indexPathForContextMenuOverride];
        return %orig(indexPathForContextMenuOverride);
    } else {
        return %orig;
    }
}

- (void)performBatchUpdates:(id)arg1 completion:(id)arg2 {
    HBLogDebug(@"UICollectionView: %p performBatchUpdates", self);
    %orig;
}

%end

// adding custom actions to the context menu
%hook UIMenu

// not the best method to inject custom actions into, but the one i could find that works for the moment
- (UIMenu *)menuByReplacingChildren:(NSArray<UIMenuElement *> *)arg1 {
    [[Logger sharedInstance] logString:[NSString stringWithFormat:@"UIMenu: %@ - menuByReplacingChildren:(%@)", self, arg1]];

    if ([[MeloManager sharedInstance] prefsBoolForKey:@"customActionMenuEnabled"]) {
        return %orig;
    }

    [[Logger sharedInstance] logString:@"children:"];
    for (id child in arg1) {
        [[Logger sharedInstance] logStringWithFormat:@"\tchild identifier: %@, child: %@", [child identifier], child];
    }

    // without the identifer check, when adding actions to the bottom of the list it worked perfectly, but adding to the top would create 3 duplicate actions. why? who could know..
    if (shouldAddAlbumPinContextMenuAction) {

        [[Logger sharedInstance] logStringWithFormat:@"shouldAddAlbumPinContextMenuAction: %i, indexPathForContextActions: %@", shouldAddAlbumPinContextMenuAction, indexPathForContextActions];

        // detect if the menu already has the injected context actions
        BOOL containsInjectedActions = NO;

        // iterate over every child menu element
        for (id child in arg1) {

            // check if the child is an action and if so check its identifier prefix
            if ([child respondsToSelector:@selector(identifier)] && [[child identifier] hasPrefix:@"MELO_ACTION"]) {
                containsInjectedActions = YES;
                break;
            }

            // if child is a submenu, check if every one of its children is an action and if so has the right prefix
            if ([child isKindOfClass:[UIMenu class]]) {
                for (id subchild in [child children]) {
                    if ([subchild respondsToSelector:@selector(identifier)] && [[subchild identifier] hasPrefix:@"MELO_ACTION"]) {
                        containsInjectedActions = YES;
                        break;
                    }
                }
            }
        }

        // no injected actions were added yet, do so now
        if (!containsInjectedActions) {
            [[Logger sharedInstance] logString:@"no previously injected actions detected"];

            if (!currentLRAVC) {
                [[Logger sharedInstance] logString:@"no current LibraryRecentlyAddedViewController, this shouldn't happen..."];
                return %orig;
            }

            [[Logger sharedInstance] logString:@"here1"];

            RecentlyAddedManager *recentlyAddedManager = [currentLRAVC recentlyAddedManager];
            NSMutableArray *newActions = [NSMutableArray array];
            // Album *targetAlbum = [recentlyAddedManager albumAtAdjustedIndexPath:indexPathForContextActions];

            /* add the move to section action */

            // old code converts section index from 'visible' to 'data' when hiding empty sections was a thing

            // place all move actions into a submenu
            BOOL displayMoveActionsInline = YES; // old code had this as a setting, default to yes for now 
            NSMutableArray *subMenuActions = [NSMutableArray array];

            [[Logger sharedInstance] logString:@"here2"];
            [[Logger sharedInstance] logStringWithFormat:@"%@", recentlyAddedManager];

            // iterate over every section
            for (NSInteger i = 0; i < [recentlyAddedManager numberOfSections]; i++) {

                [[Logger sharedInstance] logStringWithFormat:@"%ld", i];
                
                // don't have move action to current section
                if (i == indexPathForContextActions.section) {
                    continue;
                }

                Section *section = [recentlyAddedManager sectionAtIndex:i];
                NSString *title = [NSString stringWithFormat:@"Move to '%@'", section.title];
                NSString *ident = [NSString stringWithFormat:@"MELO_ACTION_MOVE_TO_%@", section.identifier];

                [[Logger sharedInstance] logStringWithFormat:@"section: %@", section];

                // create the action
                UIAction *subMenuAction = [UIAction actionWithTitle:title image:[UIImage systemImageNamed:@"arrow.swap"] identifier:ident handler:^(UIAction *action) {
                    [currentLRAVC handleMoveToSectionAction:i];
                }];

                [subMenuActions addObject:subMenuAction];

                [[Logger sharedInstance] logString:@"added to submenuactions array"];
            }

            [[Logger sharedInstance] logString:@"here3"];

            // only create the submenu if there is more than one action
            if ([subMenuActions count] > 1) {
                UIMenu *subMenu = [UIMenu menuWithTitle:@"Move to Section" image:[UIImage systemImageNamed:@"arrow.swap"] identifier:@"MELO_ACTION_MOVE_TO_SECTION_MENU"
                    options:displayMoveActionsInline ? UIMenuOptionsDisplayInline : 0 children:subMenuActions];

                [newActions addObject:subMenu];
            } else if ([subMenuActions count] == 1) {
                [newActions addObject:subMenuActions[0]];
            }

            [[Logger sharedInstance] logString:@"here4"];

            // add shift left action if possible
            if ([recentlyAddedManager canShiftAlbumAtAdjustedIndexPath:indexPathForContextActions movingLeft:YES]) {
                UIAction *shiftLeftAction = [UIAction actionWithTitle:@"Shift Left" image:[UIImage systemImageNamed:@"arrow.left"] identifier:@"MELO_ACTION_SHIFT_LEFT" handler:^(UIAction *action) {
                    [currentLRAVC handleShiftAction:YES];
                }];

                [newActions addObject:shiftLeftAction];
            }

            [[Logger sharedInstance] logString:@"here5"];

            // add shift right action if possible
            if ([recentlyAddedManager canShiftAlbumAtAdjustedIndexPath:indexPathForContextActions movingLeft:NO]) {
                UIAction *shiftRightAction = [UIAction actionWithTitle:@"Shift Right" image:[UIImage systemImageNamed:@"arrow.right"] identifier:@"RIGHT" handler:^(UIAction *action) {
                    [currentLRAVC handleShiftAction:NO];
                }];

                [newActions addObject:shiftRightAction];
            }

            [[Logger sharedInstance] logString:@"here6"];

            // placing all custom actions into a submenu
            //if ([meloManager prefsBoolForKey:@"allActionsInSubmenuEnabled"]) {
                // UIMenu *subMenu = [UIMenu menuWithTitle:@"Melo Actions" image:[UIImage systemImageNamed:@"pin"] identifier:@"MELO_ACTION_SUBMENU"
                //     options:[meloManager prefsBoolForKey:@"allActionsInSubmenuEnabled"] ? 0 : UIMenuOptionsDisplayInline children:newActions];

                // newActions = [NSMutableArray arrayWithObjects:subMenu, nil];
            //}

            // placing custom actions at top or bottom
            BOOL placeMenuAtTop = YES; // old code has this done by preferences ([[apManager prefsObjectForKey:@"contextActionsLocationValue"] integerValue] == 0)

            if (placeMenuAtTop) {
                arg1 = [newActions arrayByAddingObjectsFromArray:arg1];
            } else {
                arg1 = [arg1 arrayByAddingObjectsFromArray:newActions];
            }
        }
    }

	id orig =  %orig;
    [[Logger sharedInstance] logStringWithFormat:@"UIMenu result: %@", orig];
    return orig;
}

%end

%hook ArtworkPrefetchingController

// ios 14+ needs real index paths injected here as the adjusted index paths seem to be passed during [UICollectionView layoutSubviews]
// this fixes a crash caused by scrolling down (to the point where the injected pinned section title leaves the screen)
- (void)collectionView:(UICollectionView *)arg1 prefetchItemsAtIndexPaths:(id)arg2 {
    [[Logger sharedInstance] logString:[NSString stringWithFormat:@"ArtworkPrefetchingController: %p - collectionView:(%p) prefetchItemsAtIndexPaths:(%@)", self, arg1, arg2]];

    // check if this instance is for the current LibraryRecentlyAddedViewController
    if (currentLRAVC && [currentLRAVC recentlyAddedManager] && [[currentLRAVC recentlyAddedManager] isReadyForUse] && arg1 == MSHookIvar<UICollectionView *>(currentLRAVC, "_collectionView")) {

        // translate all adjusted index paths to their real index path
        NSMutableArray *realIndexPaths = [NSMutableArray array];
        for (NSIndexPath *indexPath in arg2) {
            [realIndexPaths addObject:[[currentLRAVC recentlyAddedManager] translateIndexPath:indexPath]];
        }

        arg2 = realIndexPaths;
    }

    %orig;
}

%end

%hook AlbumCell

- (void)layoutSubviews {
    %orig;

    MeloManager *meloManager = [MeloManager sharedInstance];

    id dataSource = [[self _collectionView] dataSource];
    // BOOL shouldChangeCornerRadius = [dataSource isKindOfClass:objc_getClass("MusicApplication.LibraryRecentlyAddedViewController")] || ([apManager prefsBoolForKey:@"affectAlbumsPagesEnabled"] && ([dataSource isKindOfClass:objc_getClass("MusicApplication.AlbumsViewController")] || [dataSource isKindOfClass:objc_getClass("MusicApplication.ArtistViewController")]));
    BOOL shouldChangeCornerRadius = [dataSource isKindOfClass:objc_getClass("MusicApplication.LibraryRecentlyAddedViewController")];
    shouldChangeCornerRadius = shouldChangeCornerRadius && [meloManager prefsBoolForKey:@"customAlbumCellCornerRadiusEnabled"];

    if (shouldChangeCornerRadius) {

        CGFloat radius = [[meloManager prefsObjectForKey:@"customAlbumCellCornerRadius"] floatValue] / 100 * [self frame].size.width;

        UIView *artworkView = MSHookIvar<UIView *>(MSHookIvar<id>(self, "artworkComponent"), "imageView");

        [artworkView setClipsToBounds:YES];
        [[artworkView layer] setCornerRadius:radius];
        //[[self layer] setContinuousCorners:YES];
    }
}

%end

%ctor {

    MeloManager *meloManager = [MeloManager sharedInstance];

    if ([meloManager prefsBoolForKey:@"enabled"]) {
        %init(LibraryRecentlyAddedViewController = objc_getClass("MusicApplication.LibraryRecentlyAddedViewController"), 
            TitleSectionHeaderView = objc_getClass("MusicApplication.TitleSectionHeaderView"),
            ArtworkPrefetchingController = objc_getClass("MusicApplication.ArtworkPrefetchingController"),
            AlbumCell = objc_getClass("MusicApplication.AlbumCell"));
    }
}