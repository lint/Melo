
#import "AnimationManager.h"
#import "../utilities/utilities.h"
#import "../../interfaces/interfaces.h"
#import "WiggleModeManager.h"

// this is used to handle completion code for animations, unfortunately required since blocks don't work when patching with Allemand
@implementation AnimationManager 

// delegate method called whenever an animation is about to begin
- (void)handleAnimationWillStart:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {

}

// delegate method called whenever an animation has completed
- (void)handleAnimationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {

    NSDictionary *ctx = (__bridge_transfer NSDictionary *)context;

    // completion code for when wiggle mode is enabled and the "end wiggle mode" button / view pops up
    if ([@"MELO_ANIMATION_END_WIGGLE_VIEW_POP_UP" isEqualToString:animationID]) {

        UIView *view = ctx[@"view"];
        if (view) {
            view.userInteractionEnabled = YES;
        }

    // completion code to hide the album text (artist and album name) when starting a drag in wiggle mode
    } else if ([@"MELO_ANIMATION_HIDE_ALBUM_TEXT_ON_DRAG" isEqualToString:animationID]) {

        UIView *cell = ctx[@"cell"];
        if (cell) {
            cell.hidden = YES;
        }
    
    // completion code to reset album cells after a drag is complete
    } else if ([@"MELO_ANIMATION_END_DRAG" isEqualToString:animationID]) {

        WiggleModeManager *wiggleManager = ctx[@"wiggleManager"];
        AlbumCell *cell = ctx[@"cell"];
        UIView *artworkView = ctx[@"artworkView"];
        UIView *textStackView = ctx[@"textStackView"];
        UIView *customTextView = [cell respondsToSelector:@selector(customTextView)] ? [cell customTextView] : nil;

        cell.hidden = NO;
        //cell.alpha = 1; // old code
        artworkView.alpha = 1;
        textStackView.alpha = 0;

        if (customTextView) {
            customTextView.alpha = 0;
        }

        wiggleManager.draggingView = nil;
        wiggleManager.draggingIndexPath = nil;
        wiggleManager.endWiggleModeView.userInteractionEnabled = YES;

        NSDictionary *ctxCopy = [NSDictionary dictionaryWithDictionary:ctx];

        [UIView beginAnimations:@"MELO_ANIMATION_END_DRAG_COMPLETE_SHOW_ALBUM_TEXT" context:(__bridge_retained void *)ctxCopy];
        [UIView setAnimationDuration:0.2];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:@selector(handleAnimationDidStop:finished:context:)];
            
            textStackView.alpha = 1;

            if (customTextView) {
                customTextView.alpha = 1;
            }
        [UIView commitAnimations];

        //[collectionView.collectionViewLayout invalidateLayout]; //do I need this? // old code

    // completion code for the animation which shows the album text after the main end drag animation is complete
    } else if ([@"MELO_ANIMATION_END_DRAG_COMPLETE_SHOW_ALBUM_TEXT" isEqualToString:animationID]) {

        UIView *draggingView = ctx[@"draggingView"];
        if (draggingView) {
            [draggingView removeFromSuperview];
        }
    
    // completion code for the animation that hides the end wiggle mode button / view 
    } else if ([@"MELO_ANIMATION_END_WIGGLE_VIEW_DISMISS" isEqualToString:animationID]) {

        UIView *endWiggleModeView = ctx[@"endWiggleModeView"];
        if (endWiggleModeView) {
            endWiggleModeView.hidden = YES;
            [endWiggleModeView superview].userInteractionEnabled = NO;
        }

    // completion code for the first part of the empty insertion flash
    } else if ([@"MELO_ANIMATION_EMPTY_INSERTION_FLASH_PART_1" isEqualToString:animationID]) {

        UIView *view = ctx[@"view"];
        UIColor *origColor = [MeloUtils dictToColor:ctx[@"origColor"]];
        NSNumber *interval = ctx[@"interval"];

        if (view && origColor) {
            NSDictionary *ctxCopy = [NSDictionary dictionaryWithDictionary:ctx];

            [UIView beginAnimations:@"MELO_ANIMATION_EMPTY_INSERTION_FLASH_PART_2" context:(__bridge_retained void *)ctxCopy];
            [UIView setAnimationDuration:[interval doubleValue]];
            [UIView setAnimationDelegate:self];
            [UIView setAnimationDidStopSelector:@selector(handleAnimationDidStop:finished:context:)];
                view.backgroundColor = origColor;
            [UIView commitAnimations];
        }

    // completion code for the second part of the empty insertion flash
    } else if ([@"MELO_ANIMATION_EMPTY_INSERTION_FLASH_PART_2" isEqualToString:animationID]) {

        UIView *view = ctx[@"view"];
        UIColor *highlightColor = [MeloUtils dictToColor:ctx[@"highlightColor"]];
        NSNumber *interval = ctx[@"interval"];

        if (view && highlightColor) {
            NSDictionary *ctxCopy = [NSDictionary dictionaryWithDictionary:ctx];

            [UIView beginAnimations:@"MELO_ANIMATION_EMPTY_INSERTION_FLASH_PART_3" context:(__bridge_retained void *)ctxCopy];
            [UIView setAnimationDuration:[interval doubleValue]];
            [UIView setAnimationDelegate:self];
            [UIView setAnimationDidStopSelector:@selector(handleAnimationDidStop:finished:context:)];
                view.backgroundColor = highlightColor;
            [UIView commitAnimations];
        }

    // completion code for the third part of the empty insertion flash
    } else if ([@"MELO_ANIMATION_EMPTY_INSERTION_FLASH_PART_3" isEqualToString:animationID]) {

        UIView *view = ctx[@"view"];
        UIColor *origColor = [MeloUtils dictToColor:ctx[@"origColor"]];
        NSNumber *interval = ctx[@"interval"];

        if (view && origColor) {
            [UIView beginAnimations:nil context:nil];
            [UIView setAnimationDuration:[interval doubleValue] * 1.5];
                view.backgroundColor = origColor;
            [UIView commitAnimations];
        }

    // completeion code for setting time text on the music player when a music scrub has ended
    } else if ([@"MELO_ANIMATION_MUSIC_PLAYER_SCRUB_STOPPED" isEqualToString:animationID]) {
        
        UILabel *elapsedTimeLabel = ctx[@"elapsedTimeLabel"];
        UILabel *remainingTimeLabel = ctx[@"remainingTimeLabel"];

        elapsedTimeLabel.textColor = [UIColor whiteColorWithAlpha:0.18];
        remainingTimeLabel.textColor = [UIColor whiteColorWithAlpha:0.18];

        elapsedTimeLabel.alpha = 1;
        remainingTimeLabel.alpha = 1;
    
    // completeion code for growing / shrinking the volume slider on scrub start / end
    } else if ([@"MELO_ANIMATION_VOLUME_SLIDER_TOUCH" isEqualToString:animationID]) {
        
        VolumeSlider *volumeSlider = ctx[@"volumeSlider"];
        BOOL shouldApplyLargeOriginalSliderWidth = [ctx[@"shouldApplyLargeOriginalSliderWidth"] boolValue];

        [volumeSlider setShouldApplyLargeSliderWidth:shouldApplyLargeOriginalSliderWidth];

    } else {
        [Logger logString:@"AnimationManager handleAnimationDidStop could not match animationID"];
    }
    
}

@end