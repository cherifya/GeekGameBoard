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
#import "BoardView.h"
#import "Bit.h"
#import "BitHolder.h"
#import "Game.h"
#import "QuartzUtils.h"
#import "GGBUtils.h"


@interface BoardView ()
- (void) _findDropTarget: (NSPoint)pos;
@end


@implementation BoardView


@synthesize game=_game, gameboard=_gameboard;


- (void) dealloc
{
    [_game release];
    [super dealloc];
}


- (void) startGameNamed: (NSString*)gameClassName
{
    if( _gameboard ) {
        [_gameboard removeFromSuperlayer];
        _gameboard = nil;
    }
    _gameboard = [[CALayer alloc] init];
    _gameboard.frame = [self gameBoardFrame];
    _gameboard.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;
    [self.layer addSublayer: _gameboard];
    [_gameboard release];
    
    Class gameClass = NSClassFromString(gameClassName);
    setObj(&_game, [[gameClass alloc] initWithBoard: _gameboard]);
}


- (CGRect) gameBoardFrame
{
    return self.layer.bounds;
}


- (void)resetCursorRects
{
    [super resetCursorRects];
    [self addCursorRect: self.bounds cursor: [NSCursor openHandCursor]];
}


- (IBAction) enterFullScreen: (id)sender
{
    if( self.isInFullScreenMode ) {
        [self exitFullScreenModeWithOptions: nil];
    } else {
        [self enterFullScreenMode: self.window.screen 
                      withOptions: nil];
    }
}


#pragma mark -
#pragma mark KEY EVENTS:


- (void) keyDown: (NSEvent*)ev
{
    if( self.isInFullScreenMode ) {
        if( [ev.charactersIgnoringModifiers hasPrefix: @"\033"] )       // Esc key
            [self enterFullScreen: self];
    }
}


#pragma mark -
#pragma mark HIT-TESTING:


/** Converts a point from window coords, to this view's root layer's coords. */
- (CGPoint) _convertPointFromWindowToLayer: (NSPoint)locationInWindow
{
    NSPoint where = [self convertPoint: locationInWindow fromView: nil];    // convert to view coords
    return NSPointToCGPoint( [self convertPointToBase: where] );            // then to layer coords
}


// Hit-testing callbacks (to identify which layers caller is interested in):
typedef BOOL (*LayerMatchCallback)(CALayer*);

static BOOL layerIsBit( CALayer* layer )        {return [layer isKindOfClass: [Bit class]];}
static BOOL layerIsBitHolder( CALayer* layer )  {return [layer conformsToProtocol: @protocol(BitHolder)];}
static BOOL layerIsDropTarget( CALayer* layer ) {return [layer respondsToSelector: @selector(draggingEntered:)];}


/** Locates the layer at a given point in window coords.
    If the leaf layer doesn't pass the layer-match callback, the nearest ancestor that does is returned.
    If outOffset is provided, the point's position relative to the layer is stored into it. */
- (CALayer*) hitTestPoint: (NSPoint)locationInWindow
         forLayerMatching: (LayerMatchCallback)match
                   offset: (CGPoint*)outOffset
{
    CGPoint where = [self _convertPointFromWindowToLayer: locationInWindow ];
    CALayer *layer = [_gameboard hitTest: where];
    while( layer ) {
        if( match(layer) ) {
            CGPoint bitPos = [self.layer convertPoint: layer.position 
                              fromLayer: layer.superlayer];
            if( outOffset )
                *outOffset = CGPointMake( bitPos.x-where.x, bitPos.y-where.y);
            return layer;
        } else
            layer = layer.superlayer;
    }
    return nil;
}


#pragma mark -
#pragma mark MOUSE CLICKS & DRAGS:


- (void) mouseDown: (NSEvent*)ev
{
    BOOL placing = NO;
    _dragStartPos = ev.locationInWindow;
    _dragBit = (Bit*) [self hitTestPoint: _dragStartPos
                        forLayerMatching: layerIsBit 
                                  offset: &_dragOffset];
    
    if( ! _dragBit ) {
        // If no bit was clicked, see if it's a BitHolder the game will let the user add a Bit to:
        id<BitHolder> holder = (id<BitHolder>) [self hitTestPoint: _dragStartPos
                                                 forLayerMatching: layerIsBitHolder
                                                           offset: NULL];
        if( holder ) {
            _dragBit = [_game bitToPlaceInHolder: holder];
            if( _dragBit ) {
                _dragOffset.x = _dragOffset.y = 0;
                if( _dragBit.superlayer==nil )
                    _dragBit.position = [self _convertPointFromWindowToLayer: _dragStartPos];
                placing = YES;
            }
        }
    }
    
    if( ! _dragBit ) {
        Beep();
        return;
    }
    
    // Clicked on a Bit:
    _dragMoved = NO;
    _dropTarget = nil;
    _oldHolder = _dragBit.holder;
    // Ask holder's and game's permission before dragging:
    if( _oldHolder ) {
        _dragBit = [_oldHolder canDragBit: _dragBit];
        if( _dragBit && ! [_game canBit: _dragBit moveFrom: _oldHolder] ) {
            [_oldHolder cancelDragBit: _dragBit];
            _dragBit = nil;
        }
        if( ! _dragBit ) {
            _oldHolder = nil;
            NSBeep();
            return;
        }
    }
    
    // Start dragging:
    _oldSuperlayer = _dragBit.superlayer;
    _oldLayerIndex = [_oldSuperlayer.sublayers indexOfObjectIdenticalTo: _dragBit];
    _oldPos = _dragBit.position;
    ChangeSuperlayer(_dragBit, self.layer, self.layer.sublayers.count);
    _dragBit.pickedUp = YES;
    [[NSCursor closedHandCursor] push];
    
    if( placing ) {
        if( _oldSuperlayer )
            _dragBit.position = [self _convertPointFromWindowToLayer: _dragStartPos];
        _dragMoved = YES;
        [self _findDropTarget: _dragStartPos];
    }
}


- (void) mouseDragged: (NSEvent*)ev
{
    if( _dragBit ) {
        // Get the mouse position, and see if we've moved 3 pixels since the mouseDown:
        NSPoint pos = ev.locationInWindow;
        if( fabs(pos.x-_dragStartPos.x)>=3 || fabs(pos.y-_dragStartPos.y)>=3 )
            _dragMoved = YES;
        
        // Move the _dragBit (without animation -- it's unnecessary and slows down responsiveness):
        CGPoint where = [self _convertPointFromWindowToLayer: pos];
        where.x += _dragOffset.x;
        where.y += _dragOffset.y;
        
        CGPoint newPos = [_dragBit.superlayer convertPoint: where fromLayer: self.layer];

        [CATransaction flush];
        [CATransaction begin];
        [CATransaction setValue:(id)kCFBooleanTrue
                         forKey:kCATransactionDisableActions];
        _dragBit.position = newPos;
        [CATransaction commit];

        // Find what it's over:
        [self _findDropTarget: pos];
    }
}


- (void) _findDropTarget: (NSPoint)locationInWindow
{
    locationInWindow.x += _dragOffset.x;
    locationInWindow.y += _dragOffset.y;
    id<BitHolder> target = (id<BitHolder>) [self hitTestPoint: locationInWindow
                                             forLayerMatching: layerIsBitHolder
                                                       offset: NULL];
    if( target == _oldHolder )
        target = nil;
    if( target != _dropTarget ) {
        [_dropTarget willNotDropBit: _dragBit];
        _dropTarget.highlighted = NO;
        _dropTarget = nil;
    }
    if( target ) {
        CGPoint targetPos = [(CALayer*)target convertPoint: _dragBit.position
                                                 fromLayer: _dragBit.superlayer];
        if( [target canDropBit: _dragBit atPoint: targetPos]
           && [_game canBit: _dragBit moveFrom: _oldHolder to: target] ) {
            _dropTarget = target;
            _dropTarget.highlighted = YES;
        }
    }
}


- (void) mouseUp: (NSEvent*)ev
{
    if( _dragBit ) {
        if( _dragMoved ) {
            // Update the drag tracking to the final mouse position:
            [self mouseDragged: ev];
            _dropTarget.highlighted = NO;
            _dragBit.pickedUp = NO;

            // Is the move legal?
            if( _dropTarget && [_dropTarget dropBit: _dragBit
                                            atPoint: [(CALayer*)_dropTarget convertPoint: _dragBit.position 
                                                                            fromLayer: _dragBit.superlayer]] ) {
                // Yes, notify the interested parties:
                [_oldHolder draggedBit: _dragBit to: _dropTarget];
                [_game bit: _dragBit movedFrom: _oldHolder to: _dropTarget];
            } else {
                // Nope, cancel:
                [_dropTarget willNotDropBit: _dragBit];
                if( _oldSuperlayer ) {
                    ChangeSuperlayer(_dragBit, _oldSuperlayer, _oldLayerIndex);
                    _dragBit.position = _oldPos;
                    [_oldHolder cancelDragBit: _dragBit];
                } else {
                    [_dragBit removeFromSuperlayer];
                }
            }
        } else {
            // Just a click, without a drag:
            _dropTarget.highlighted = NO;
            _dragBit.pickedUp = NO;
            ChangeSuperlayer(_dragBit, _oldSuperlayer, _oldLayerIndex);
            [_oldHolder cancelDragBit: _dragBit];
            if( ! [_game clickedBit: _dragBit] )
                NSBeep();
        }

        _dropTarget = nil;
        _dragBit = nil;
        [NSCursor pop];
    }
}


#pragma mark -
#pragma mark INCOMING DRAGS:


// subroutine to call the target
static int tell( id target, SEL selector, id arg, int defaultValue )
{
    if( target && [target respondsToSelector: selector] )
        return (ssize_t) [target performSelector: selector withObject: arg];
    else
        return defaultValue;
}


- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
    _viewDropTarget = [self hitTestPoint: [sender draggingLocation]
                        forLayerMatching: layerIsDropTarget
                                  offset: NULL];
    _viewDropOp = _viewDropTarget ?[_viewDropTarget draggingEntered: sender] :NSDragOperationNone;
    return _viewDropOp;
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender
{
    CALayer *target = [self hitTestPoint: [sender draggingLocation]
                        forLayerMatching: layerIsDropTarget 
                                  offset: NULL];
    if( target == _viewDropTarget ) {
        if( _viewDropTarget )
            _viewDropOp = tell(_viewDropTarget,@selector(draggingUpdated:),sender,_viewDropOp);
    } else {
        tell(_viewDropTarget,@selector(draggingExited:),sender,0);
        _viewDropTarget = target;
        if( _viewDropTarget )
            _viewDropOp = [_viewDropTarget draggingEntered: sender];
        else
            _viewDropOp = NSDragOperationNone;
    }
    return _viewDropOp;
}

- (BOOL)wantsPeriodicDraggingUpdates
{
    return (_viewDropTarget!=nil);
}

- (void)draggingExited:(id <NSDraggingInfo>)sender
{
    tell(_viewDropTarget,@selector(draggingExited:),sender,0);
    _viewDropTarget = nil;
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
    return tell(_viewDropTarget,@selector(prepareForDragOperation:),sender,YES);
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
    return [_viewDropTarget performDragOperation: sender];
}

- (void)concludeDragOperation:(id <NSDraggingInfo>)sender
{
    tell(_viewDropTarget,@selector(concludeDragOperation:),sender,0);
}

- (void)draggingEnded:(id <NSDraggingInfo>)sender
{
    tell(_viewDropTarget,@selector(draggingEnded:),sender,0);
}

@end
