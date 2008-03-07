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


/** Hardcoded dimensions of a Card */
#define kCardWidth  100
#define kCardHeight 150


/* A card of some type (playing card, Community Chest, money, ...)
   Has an identifying serial number (could be in the range 1..52 for playing cards).
   Can be face-up or down. */
@interface Card : Bit 
{
    @private
    int _serialNumber;
    CALayer *_front, *_back;
    BOOL _faceUp;
}

/** The range of serialNumbers used for this type of card. Used when instantiating Decks.
    Abstract; must be overridden. */
+ (NSRange) serialNumberRange;

- (id) initWithSerialNumber: (int)serial position: (CGPoint)pos;

@property (readonly) int serialNumber;

/** Cards can be face-up or face-down, of course. */
@property BOOL faceUp;


//protected -- for subclasses only:

/** Creates the sub-layer that displays the front side of the card.
    Subclasses should probably call the superclass method, configure the layer it returns
    (based on the card's serialNumber) and then return that layer. */
- (CALayer*) createFront;

/** Creates the sub-layer that displays the back side of the card.
    Subclasses should probably call the superclass method, configure the layer it returns and
    return that layer. */
- (CALayer*) createBack;

@end
