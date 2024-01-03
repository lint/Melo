//
//  DelaunayEdgeReorderer.h
//  Delaunay
//
//  Created by Christopher Garrett on 4/14/11.
//  Copyright 2011 ZWorkbench, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface DelaunayEdgeReorderer : NSObject {
    
}

@property (nonatomic, strong) NSMutableArray *edges; 
@property (nonatomic, strong) NSMutableArray *edgeOrientations;

- (id) initWithEdges: (NSArray *) originalEdges criterion: (Class) klass;
- (NSMutableArray *) reorderEdges: (NSArray *) originalEdges criterion: (Class) criterion;


@end
