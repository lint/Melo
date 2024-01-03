//
//  DelaunayPolygon.h
//  Delaunay
//
//  Created by Christopher Garrett on 4/13/11.
//  Copyright 2011 ZWorkbench, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>


typedef enum {
   DelaunayWindingNone = 0,
   DelaunayWindingClockwise,
   DelaunayWindingCounterClockwise
} DelaunayWinding;


@interface DelaunayPolygon : NSObject

@property (strong, nonatomic) NSMutableArray *vertices;

+ (DelaunayPolygon *) polygonWithVertices: (NSMutableArray *) vertices;

- (float) area;
- (DelaunayWinding) winding;
- (float) signedDoubleArea;

- (void)temp; // TODO: necessary addition for some reason to prevent a crash with allemand

@end
