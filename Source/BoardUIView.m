//
//  BoardUIView.m
//  GeekGameBoard
//
//  Created by Jens Alfke on 3/7/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "BoardUIView.h"
#import "Bit.h"
#import "BitHolder.h"
#import "Game.h"
#import "QuartzUtils.h"
#import "GGBUtils.h"


@implementation BoardUIView


- (id)initWithFrame:(CGRect)frame {
    if ( (self = [super initWithFrame:frame]) ) {
        // Initialization code here.
    }
    return self;
}


- (void)dealloc
{
    [_game release];
    [super dealloc];
}


@synthesize game=_game, gameboard=_gameboard;


- (void) startGameNamed: (NSString*)gameClassName
{
    if( _gameboard ) {
        [_gameboard removeFromSuperlayer];
        _gameboard = nil;
    }
    _gameboard = [[GGBLayer alloc] init];
    _gameboard.frame = [self gameBoardFrame];
    _gameboard.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;
    [self.layer addSublayer: _gameboard];
    [_gameboard release];
    
    Class gameClass = NSClassFromString(gameClassName);
    NSAssert1(gameClass,@"Unknown game '%@'",gameClassName);
    setObj(&_game, [[gameClass alloc] initWithBoard: _gameboard]);
}


- (CGRect) gameBoardFrame
{
    return self.layer.bounds;
}


#pragma mark -
#pragma mark HIT-TESTING:


// Hit-testing callbacks (to identify which layers caller is interested in):
typedef BOOL (*LayerMatchCallback)(CALayer*);

static BOOL layerIsBit( CALayer* layer )        {return [layer isKindOfClass: [Bit class]];}
static BOOL layerIsBitHolder( CALayer* layer )  {return [layer conformsToProtocol: @protocol(BitHolder)];}


/** Locates the layer at a given point in window coords.
    If the leaf layer doesn't pass the layer-match callback, the nearest ancestor that does is returned.
    If outOffset is provided, the point's position relative to the layer is stored into it. */
- (CALayer*) hitTestPoint: (CGPoint)where
         forLayerMatching: (LayerMatchCallback)match
                   offset: (CGPoint*)outOffset
{
    where = [_gameboard convertPoint: where fromLayer: self.layer];
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


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSAssert(touches.count==1,@"No multitouch support yet");
    UITouch *touch = touches.anyObject;
    
    _dragStartPos = touch.locationInView;
    _dragBit = (Bit*) [self hitTestPoint: _dragStartPos
                        forLayerMatching: layerIsBit 
                                  offset: &_dragOffset];
    if( _dragBit ) {
        _dragMoved = NO;
        _dropTarget = nil;
        _oldHolder = _dragBit.holder;
        // Ask holder's and game's permission before dragging:
        if( _oldHolder )
            _dragBit = [_oldHolder canDragBit: _dragBit];
        if( _dragBit && ! [_game canBit: _dragBit moveFrom: _oldHolder] ) {
            [_oldHolder cancelDragBit: _dragBit];
            _dragBit = nil;
        }
        if( ! _dragBit ) {
            _oldHolder = nil;
            Beep();
            return;
        }
        // Start dragging:
        _oldSuperlayer = _dragBit.superlayer;
        _oldLayerIndex = [_oldSuperlayer.sublayers indexOfObjectIdenticalTo: _dragBit];
        _oldPos = _dragBit.position;
        ChangeSuperlayer(_dragBit, self.layer, self.layer.sublayers.count);
        _dragBit.pickedUp = YES;
    } else
        Beep();
}


- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSAssert(touches.count==1,@"No multitouch support yet");
    UITouch *touch = touches.anyObject;
    
    if( _dragBit ) {
        // Get the mouse position, and see if we've moved 3 pixels since the mouseDown:
        CGPoint pos = touch.locationInView;
        if( fabs(pos.x-_dragStartPos.x)>=3 || fabs(pos.y-_dragStartPos.y)>=3 )
            _dragMoved = YES;
        
        // Move the _dragBit (without animation -- it's unnecessary and slows down responsiveness):
        pos.x += _dragOffset.x;
        pos.y += _dragOffset.y;
        
        CGPoint newPos = [_dragBit.superlayer convertPoint: pos fromLayer: self.layer];

        [CATransaction flush];
        [CATransaction begin];
        [CATransaction setValue:(id)kCFBooleanTrue
                         forKey:kCATransactionDisableActions];
        _dragBit.position = newPos;
        [CATransaction commit];

        // Find what it's over:
        id<BitHolder> target = (id<BitHolder>) [self hitTestPoint: pos
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
}


- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if( _dragBit ) {
        if( _dragMoved ) {
            // Update the drag tracking to the final mouse position:
            [self touchesMoved: touches withEvent: event];
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
                ChangeSuperlayer(_dragBit, _oldSuperlayer, _oldLayerIndex);
                _dragBit.position = _oldPos;
                [_oldHolder cancelDragBit: _dragBit];
            }
        } else {
            // Just a click, without a drag:
            _dropTarget.highlighted = NO;
            _dragBit.pickedUp = NO;
            ChangeSuperlayer(_dragBit, _oldSuperlayer, _oldLayerIndex);
            [_oldHolder cancelDragBit: _dragBit];
            if( ! [_game clickedBit: _dragBit] )
                Beep();
        }
        _dropTarget = nil;
        _dragBit = nil;
    }
}


@end
