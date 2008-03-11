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
#import "GGBLayer.h"
@class Bit;


/** Protocol for a layer that acts as a container for Bits. */
@protocol BitHolder <NSObject>

/** Current Bit, or nil if empty */
@property (retain) Bit* bit;

/** Conveniences for comparing self.bit with nil */
@property (readonly, getter=isEmpty) BOOL empty;

/** BitHolders will be highlighted while the target of a drag operation */
@property BOOL highlighted;


/** Tests whether the bit is allowed to be dragged out of me.
    Returns the input bit, or possibly a different Bit to drag instead, or nil if not allowed.
    Either -cancelDragBit: or -draggedBit:to: must be called next. */
- (Bit*) canDragBit: (Bit*)bit;

/** Cancels a pending drag (begun by -canDragBit:). */
- (void) cancelDragBit: (Bit*)bit;

/** Called after a drag finishes. */
- (void) draggedBit: (Bit*)bit to: (id<BitHolder>)dst;


/** Tests whether the bit is allowed to be dropped into me.
    Either -willNotDropBit: or -dropBit:atPoint: must be called next. */
- (BOOL) canDropBit: (Bit*)bit atPoint: (CGPoint)point;

/** Cancels a pending drop (after -canDropBit:atPoint: was already called.) */
- (void) willNotDropBit: (Bit*)bit;

/** Finishes a drop. */
- (BOOL) dropBit: (Bit*)bit atPoint: (CGPoint)point;

@end


/** A basic implementation of the BitHolder protocol. */
@interface BitHolder : GGBLayer <BitHolder>
{
    @protected
    Bit *_bit;
    BOOL _highlighted;
}

@end
