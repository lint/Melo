//
//  DelaunayOrientation.h
//  Delaunay
//
//  Created by Christopher Garrett on 4/13/11.
//  Copyright 2011 ZWorkbench, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface DelaunayOrientation : NSObject {
    
}


+ (DelaunayOrientation *) left;
+ (DelaunayOrientation *) right;

- (DelaunayOrientation *) opposite;

- (BOOL) isLeft;
- (BOOL) isRight;

@end
