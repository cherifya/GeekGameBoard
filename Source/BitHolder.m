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
#import "BitHolder.h"
#import "Bit.h"
#import "QuartzUtils.h"
#import "GGBUtils.h"


@implementation BitHolder


- (void) dealloc
{
    [_bit release];
    [super dealloc];
}


- (Bit*) bit
{
    if( _bit && _bit.superlayer != self && !_bit.pickedUp )
        setObj(&_bit,nil);
    return _bit;
}

- (void) setBit: (Bit*)bit
{
    if( bit != self.bit ) {
        if( bit && _bit )
            [_bit destroy];
        setObj(&_bit,bit);
        ChangeSuperlayer(bit,self,-1);
    }
}

- (BOOL) isEmpty    {return self.bit==nil;}

@synthesize highlighted=_highlighted;

- (Bit*) canDragBit: (Bit*)bit
{
    if( bit.superlayer == self && ! bit.unfriendly )
        return bit;
    else
        return nil;
}

- (void) cancelDragBit: (Bit*)bit                       { }
- (void) draggedBit: (Bit*)bit to: (id<BitHolder>)dst   {self.bit = nil;}

- (BOOL) canDropBit: (Bit*)bit atPoint: (CGPoint)point  {return YES;}
- (void) willNotDropBit: (Bit*)bit                      { }

- (BOOL) dropBit: (Bit*)bit atPoint: (CGPoint)point
{
    self.bit = bit;
    return YES;
}

@end
