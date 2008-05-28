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


@interface BoardUIView ()
- (void) _findDropTarget: (CGPoint)pos;
@end


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
    Class gameClass = NSClassFromString(gameClassName);
    NSAssert1(gameClass,@"Unknown game '%@'",gameClassName);
    
    setObj(&_game,nil);
    if( _gameboard ) {
        [_gameboard removeFromSuperlayer];
        _gameboard = nil;
    }

    CALayer *rootLayer = self.layer;
    self.layer.affineTransform = CGAffineTransformIdentity;
    CGRect frame = rootLayer.frame;
    frame.origin.x = frame.origin.y = 0;
    rootLayer.bounds = frame;

    if( [gameClass landscapeOriented] && frame.size.height > frame.size.width ) {
        rootLayer.affineTransform = CGAffineTransformMakeRotation(M_PI/2);
        frame = CGRectMake(0,0,frame.size.height,frame.size.width);
        rootLayer.bounds = frame;
    }
    
    _gameboard = [[GGBLayer alloc] init];
    _gameboard.frame = frame;
    [rootLayer addSublayer: _gameboard];
    [_gameboard release];
    
    _game = [[gameClass alloc] initWithBoard: _gameboard];
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
    
    BOOL placing = NO;
    _dragStartPos = [touch locationInView: self];
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
                    _dragBit.position = _dragStartPos;
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
            Beep();
            return;
        }
    }
    // Start dragging:
    _oldSuperlayer = _dragBit.superlayer;
    _oldLayerIndex = [_oldSuperlayer.sublayers indexOfObjectIdenticalTo: _dragBit];
    _oldPos = _dragBit.position;
    ChangeSuperlayer(_dragBit, self.layer, self.layer.sublayers.count);
    _dragBit.pickedUp = YES;
    
    if( placing ) {
        if( _oldSuperlayer )
            _dragBit.position = _dragStartPos;      // animate Bit to new position
        _dragMoved = YES;
        [self _findDropTarget: _dragStartPos];
    }
}


- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSAssert(touches.count==1,@"No multitouch support yet");
    UITouch *touch = touches.anyObject;
    
    if( _dragBit ) {
        // Get the mouse position, and see if we've moved 3 pixels since the mouseDown:
        CGPoint pos = [touch locationInView: self];
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
        [self _findDropTarget: pos];
    }
}


- (void) _findDropTarget: (CGPoint)pos
{
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
                Beep();
        }
        _dropTarget = nil;
        _dragBit = nil;
    }
}


@end
