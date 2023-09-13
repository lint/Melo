
#import <UIKit/UIKit.h>
#import "hooks.h"
#import "../objc/objc_classes.h"
#import "../interfaces/interfaces.h"

%group LayoutGroup

// doesn't work on iPad I suppose
// %hook UICollectionViewFlowLayout

// // changes the number of columns in UICollectionViews
// - (void)setItemSize:(CGSize)arg1 {

//     MeloManager *meloManager = [MeloManager sharedInstance];

//     // needed to check if the album layout is for certain classes
//     id dataSource = [[self collectionView] dataSource];

//     // TODO: you can def condense this / just make it better, plus comments ofc

//     if ([dataSource isKindOfClass:objc_getClass("MusicApplication.LibraryRecentlyAddedViewController")]) {

//         CGSize size;

//         if ([meloManager prefsBoolForKey:@"customNumColumnsEnabled"]) {

//             NSInteger numColumns = [[meloManager prefsObjectForKey:@"customNumColumns"] integerValue];
//             NSInteger screenWidth = [[UIScreen mainScreen] bounds].size.width;

//             float albumWidth = floor((screenWidth - 20 * 2 - [meloManager collectionViewCellSpacing] * (numColumns - 1)) / numColumns);
//             float albumHeight = (albumWidth * 1.5 - albumWidth) > 40 ? floor(albumWidth * 1.5) : albumWidth + 40;

//             size = [meloManager prefsBoolForKey:@"hideAlbumTextEnabled"] ? CGSizeMake(albumWidth, albumWidth) : CGSizeMake(albumWidth, albumHeight);
//         } else {
//             size = [meloManager prefsBoolForKey:@"hideAlbumTextEnabled"] ? CGSizeMake(arg1.width, arg1.width) : arg1;
//         }

//         %orig(size);
//     } else if ([meloManager prefsBoolForKey:@"affectAlbumPagesEnabled"] && 
//         ([dataSource isKindOfClass:objc_getClass("MusicApplication.AlbumsViewController")] || 
//         [dataSource isKindOfClass:objc_getClass("MusicApplication.ArtistViewController")])) {

//         CGSize size;

//         if ([meloManager prefsBoolForKey:@"customNumColumnsEnabled"]) {

//             NSInteger numColumns = [[meloManager prefsObjectForKey:@"customNumColumns"] integerValue];
//             NSInteger screenWidth = [[UIScreen mainScreen] bounds].size.width;

//             float albumWidth = floor((screenWidth - 20 * 2 - [meloManager collectionViewCellSpacing] * (numColumns - 1)) / numColumns);
//             float albumHeight = (albumWidth * 1.5 - albumWidth) > 40 ? floor(albumWidth * 1.5) : albumWidth + 40;

//             size = [meloManager prefsBoolForKey:@"hideAlbumTextEnabled"] ? CGSizeMake(albumWidth, albumWidth) : CGSizeMake(albumWidth, albumHeight); 
//         } else {
//             size = [meloManager prefsBoolForKey:@"hideAlbumTextEnabled"] ? CGSizeMake(arg1.width, arg1.width) : arg1;
//         }

//         %orig(size);

//     } else {
//         %orig;
//     }
// }

// %end


%hook AlbumsViewController

- (id)collectionView:(UICollectionView *)arg1 cellForItemAtIndexPath:(NSIndexPath *)arg2 {

    id orig = %orig;

    if ([[MeloManager sharedInstance] prefsBoolForKey:@"hideAlbumTextEnabled"]) {
        UIView *textStackView = MSHookIvar<UIView *>(orig, "textStackView");
        [textStackView setHidden:YES];
    }

    return orig;
}

%new
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return [[MeloManager sharedInstance] collectionViewCellSpacing];
}

%new
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return [[MeloManager sharedInstance] collectionViewCellSpacing];
}

%new
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return [[MeloManager sharedInstance] collectionViewItemSize];
}

%end


%hook ArtistViewController

- (id)collectionView:(UICollectionView *)arg1 cellForItemAtIndexPath:(NSIndexPath *)arg2 {

    id orig = %orig;

    if ([[MeloManager sharedInstance] prefsBoolForKey:@"hideAlbumTextEnabled"]) {
        UIView *textStackView = MSHookIvar<UIView *>(orig, "textStackView");
        [textStackView setHidden:YES];
    }

    return orig;
}

%new
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return [[MeloManager sharedInstance] collectionViewCellSpacing];
}

%new
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return [[MeloManager sharedInstance] collectionViewCellSpacing];
}

%new
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return [[MeloManager sharedInstance] collectionViewItemSize];
}

%end


%hook LibraryRecentlyAddedViewController 

- (id)collectionView:(UICollectionView *)arg1 cellForItemAtIndexPath:(NSIndexPath *)arg2 {

    id orig = %orig;

    if ([[MeloManager sharedInstance] prefsBoolForKey:@"hideAlbumTextEnabled"]) {
        UIView *textStackView = MSHookIvar<UIView *>(orig, "textStackView");
        [textStackView setHidden:YES];
    }

    return orig;
}

%new
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return [[MeloManager sharedInstance] collectionViewCellSpacing];
}

%new
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return [[MeloManager sharedInstance] collectionViewCellSpacing];
}

%new
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return [[MeloManager sharedInstance] collectionViewItemSize];
}

%end


%hook AlbumCell

- (void)layoutSubviews {
    %orig;

    MeloManager *meloManager = [MeloManager sharedInstance];
    id dataSource = [[self _collectionView] dataSource];
    
    BOOL shouldChangeCornerRadius = [meloManager prefsBoolForKey:@"customAlbumCellCornerRadiusEnabled"] && 
    ([dataSource isKindOfClass:objc_getClass("MusicApplication.LibraryRecentlyAddedViewController")] || 
    ([meloManager prefsBoolForKey:@"affectAlbumPagesEnabled"] && 
    ([dataSource isKindOfClass:objc_getClass("MusicApplication.AlbumsViewController")] ||
    [dataSource isKindOfClass:objc_getClass("MusicApplication.ArtistViewController")])));

    if (shouldChangeCornerRadius) {

        CGFloat radius = [[meloManager prefsObjectForKey:@"customAlbumCellCornerRadius"] floatValue] / 100 * [self frame].size.width;

        UIView *artworkView = MSHookIvar<UIView *>(MSHookIvar<id>(self, "artworkComponent"), "imageView");

        [artworkView setClipsToBounds:YES];
        [[artworkView layer] setCornerRadius:radius];
        //[[self layer] setContinuousCorners:YES];
    }

    if ([dataSource isKindOfClass:objc_getClass("MusicApplication.LibraryRecentlyAddedViewController")]) {
        WiggleModeManager *wiggleManager = [dataSource wiggleModeManager];
        // if (wiggleManager) {
            [wiggleManager inWiggleMode] ? [self addShakeAnimation] : [self removeShakeAnimation];
        // }
    }
}

%end


%end

// layout hooks constructor
extern "C" void InitLayout() {

    MeloManager *meloManager = [MeloManager sharedInstance];

    if ([meloManager prefsBoolForKey:@"layoutHooksEnabled"]) {
        %init(LayoutGroup,
            AlbumsViewController = objc_getClass("MusicApplication.AlbumsViewController"),
            ArtistViewController = objc_getClass("MusicApplication.ArtistViewController"),
            LibraryRecentlyAddedViewController = objc_getClass("MusicApplication.LibraryRecentlyAddedViewController"),
            AlbumCell = objc_getClass("MusicApplication.AlbumCell")
        );
    }
}