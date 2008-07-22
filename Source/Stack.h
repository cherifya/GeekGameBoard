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
#import "Bit.h"
#import "BitHolder.h"


/** A holder for multiple Bits that lines them up in stacks or rows.
    For example, this is used in solitaire card games for each pile in the "tableau". */
@interface Stack : BitHolder
{
    CGPoint _startPos;                      // see properties below for descriptions
    CGSize _spacing;       
    CGSize _wrapSpacing;   
    int _wrapInterval;     
    NSMutableArray *_bits; 
    BOOL _dragAsStacks;    
}

- (id) initWithStartPos: (CGPoint)startPos spacing: (CGSize)spacing;

- (id) initWithStartPos: (CGPoint)startPos spacing: (CGSize)spacing
           wrapInterval: (int)wrapInterval wrapSpacing: (CGSize)wrapSpacing;

@property CGPoint startPos;                 // Position where first Bit should go
@property CGSize spacing;                   // Spacing between successive Bits
@property CGSize wrapSpacing;               // Spacing between wrapped-around sub-piles
@property int wrapInterval;                 // How many Bits to add before wrapping
@property BOOL dragAsStacks;                // If set to YES, dragging a Bit drags a DraggedStack
@property (readonly) NSArray *bits;         // The Bits, in order
@property NSUInteger numberOfBits;          // Number of bits (can be used to remove bits, but not add)
@property (readonly) Bit *topBit;           // The topmost Bit (last item in self.bits)

/** Adds a Bit to the end */
- (void) addBit: (Bit*)bit;

- (void) removeBit: (Bit*)bit;

@end


/** A subset of a Stack, dragged out of it if its dragAsStacks flag is set.
    This is used in typical card solitaire games.
    A DraggedStack exists only during a drag; afterwards, its Cards
    are incorporated into the destination Stack. */
@interface DraggedStack : Bit

- (id) initWithBits: (NSArray*)bits;

@property (readonly) NSArray *bits;

@end
