//
//  NSArray+Delaunay.h
//  Delaunay
//
//  Created by Christopher Garrett on 4/13/11.
//  Copyright 2011 ZWorkbench, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface NSArray (Delaunay)

- (NSArray *) delaunayLinesForEdges;
- (NSMutableArray *) reverse;
- (CGPoint) pointAtIndex: (NSInteger) index;

@end
