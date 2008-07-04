/*  This code is based on Apple's "GeekGameBoard" sample code, version 1.0.
    http://developer.apple.com/samplecode/GeekGameBoard/
    Copyright © 2007 Apple Inc. Copyright © 2008 Jens Alfke. All Rights Reserved.

    Redistribution and use in source and binary forms, with or without modification, are permitted
    provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, this list of conditions
      and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice, this list of
      conditions and the following disclaimer in the documentation and/or other materials provided
      with the distribution.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
    IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND 
    FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRI-
    BUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
    (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR 
    PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
    CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF 
    THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
#import <Cocoa/Cocoa.h>
@class GGBLayer, Bit, Card, Grid, Game;
@protocol BitHolder;


/** NSView that hosts a game. */
@interface BoardView : NSView
{
    @private
    Game *_game;                                // Current Game
    GGBLayer *_gameboard;                       // Game's main layer
    NSSize _oldSize;
    
    // Used during mouse-down tracking:
    NSPoint _dragStartPos;                      // Starting position of mouseDown
    Bit *_dragBit;                              // Bit being dragged
    id<BitHolder> _oldHolder;                   // Bit's original holder
    CALayer *_oldSuperlayer;                    // Bit's original superlayer
    int _oldLayerIndex;                         // Bit's original index in _oldSuperlayer.layers
    CGPoint _oldPos;                            // Bit's original x/y position
    CGPoint _dragOffset;                        // Offset of mouse position from _dragBit's origin
    BOOL _dragMoved;                            // Has the mouse moved more than 3 pixels since mouseDown?
    id<BitHolder> _dropTarget;                  // Current BitHolder the cursor is over
    
    // Used while handling incoming drags:
    CALayer *_viewDropTarget;                   // Current drop target during an incoming drag-n-drop
    NSDragOperation _viewDropOp;                // Current drag operation
}

@property (retain) Game *game;
@property (readonly) CALayer *gameboard;

- (void) startGameNamed: (NSString*)gameClassName;

- (void) createGameBoard;

- (void) reverseBoard;

- (IBAction) enterFullScreen: (id)sender;

- (CGRect) gameBoardFrame;

@end
