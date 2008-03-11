//
//  BoardUIView.h
//  GeekGameBoard
//
//  Created by Jens Alfke on 3/7/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
@class GGBLayer, Bit, Card, Grid, Game;
@protocol BitHolder;


/** NSView that hosts a game. */
@interface BoardUIView : UIView
{
    @private
    Game *_game;                                // Current Game
    GGBLayer *_gameboard;                       // Game's main layer
    
    // Used during mouse-down tracking:
    CGPoint _dragStartPos;                      // Starting position of mouseDown
    Bit *_dragBit;                              // Bit being dragged
    id<BitHolder> _oldHolder;                   // Bit's original holder
    CALayer *_oldSuperlayer;                    // Bit's original superlayer
    int _oldLayerIndex;                         // Bit's original index in _oldSuperlayer.layers
    CGPoint _oldPos;                            // Bit's original x/y position
    CGPoint _dragOffset;                        // Offset of mouse position from _dragBit's origin
    BOOL _dragMoved;                            // Has the mouse moved more than 3 pixels since mouseDown?
    id<BitHolder> _dropTarget;                  // Current BitHolder the cursor is over
    
    // Used while handling incoming drags:
    GGBLayer *_viewDropTarget;                   // Current drop target during an incoming drag-n-drop
}

- (void) startGameNamed: (NSString*)gameClassName;

@property (readonly) Game *game;
@property (readonly) GGBLayer *gameboard;

- (CGRect) gameBoardFrame;

@end
