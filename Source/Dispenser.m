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
#import "Dispenser.h"
#import "Piece.h"
#import "QuartzUtils.h"
#import "GGBUtils.h"


@implementation Dispenser


- (id) initWithPrototype: (Bit*)prototype quantity: (unsigned)quantity frame: (CGRect)frame
{
    self = [super init];
    if (self != nil) {
        self.backgroundColor = kTranslucentLightGrayColor;
        self.borderColor = kTranslucentGrayColor;
        self.borderWidth = 3;
        self.cornerRadius = 16;
        self.zPosition = kBoardZ;
        self.masksToBounds = YES;
        self.frame = frame;
        self.prototype = prototype;
        self.quantity = quantity;
    }
    return self;
}


- (void) dealloc
{
    [_prototype release];
    [super dealloc];
}


@synthesize bit=_bit;


- (Bit*) createBit
{
    if( _prototype ) {
        Bit *bit = [_prototype copy];
        CGRect bounds = self.bounds;
        bit.position = GetCGRectCenter(bounds);
        return [bit autorelease];
    } else
        return nil;
}

- (void) x_regenerateCurrentBit
{
    NSAssert(_bit==nil,@"Already have a currentBit");

    BeginDisableAnimations();
    self.bit = [self createBit];
    CGPoint pos = _bit.position;
    _bit.position = CGPointMake(pos.x, pos.y+70);
    [self addSublayer: _bit];
    EndDisableAnimations();
    
    _bit.position = pos;
}


- (Bit*) prototype
{
    return _prototype;
}

- (void) setPrototype: (Bit*)prototype
{
    setObj(&_prototype, prototype);
    if( _bit ) {
        [_bit removeFromSuperlayer];
        self.bit = nil;
        if( prototype )
            [self x_regenerateCurrentBit];
    }
}


- (unsigned) quantity
{
    return _quantity;
}

- (void) setQuantity: (unsigned)quantity
{
    _quantity = quantity;
    if( quantity > 0 && !_bit )
        [self x_regenerateCurrentBit];
    else if( quantity==0 && _bit ) {
        [_bit removeFromSuperlayer];
        self.bit = nil;
    }
}


#pragma mark -
#pragma mark DRAGGING BITS:


- (Bit*) canDragBit: (Bit*)bit
{
    bit = [super canDragBit: bit];
    if( bit==_bit ) {
        [[bit retain] autorelease];
        self.bit = nil;
    }
    return bit;
}

- (void) cancelDragBit: (Bit*)bit
{
    if( ! _bit )
        self.bit = bit;
    else
        [bit removeFromSuperlayer];
}

- (void) draggedBit: (Bit*)bit to: (id<BitHolder>)dst
{
    if( --_quantity > 0 )
        [self performSelector: @selector(x_regenerateCurrentBit) withObject: nil afterDelay: 0.0];
}

- (BOOL) canDropBit: (Bit*)bit atPoint: (CGPoint)point  
{
    return [bit isEqual: _bit];
}

- (BOOL) dropBit: (Bit*)bit atPoint: (CGPoint)point
{
    [bit removeFromSuperlayer];
    return YES;
}


#pragma mark -
#pragma mark DRAG-AND-DROP:


#if ! TARGET_OS_IPHONE

// An image from another app can be dragged onto a Dispenser to change the Piece's appearance.


- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
    if( ! [_prototype isKindOfClass: [Piece class]] )
        return NSDragOperationNone;
    NSPasteboard *pb = [sender draggingPasteboard];
    if( [NSImage canInitWithPasteboard: pb] )
        return NSDragOperationCopy;
    else
        return NSDragOperationNone;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
    if( ! [_prototype isKindOfClass: [Piece class]] )
        return NO;
    CGImageRef image = GetCGImageFromPasteboard([sender draggingPasteboard]);
    if( image ) {
        [(Piece*)_prototype setImage: image];
        self.prototype = _prototype; // recreates _bit
        return YES;
    } else
        return NO;
}


#endif

@end
