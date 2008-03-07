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
@class Card;


/** A pile of Cards. Unlike a Stack, only the top card is visible or accessible;
    so as an optimization, it's the only one that's added to the layer tree. */
@interface Deck : BitHolder
{
    NSMutableArray *_cards;
}

/** Creates an empty Deck. */
- (id) init;

/** Creates a Deck populated with a full set of cards (in order.) */
- (id) initWithCardsOfClass: (Class)klass;

@property (readonly) NSArray *cards;
@property (readonly) Card *topCard;             // same as the -bit property

/** Randomly shuffles all the cards in the Deck. */
- (void) shuffle;

/** Flips over the Deck: Reverses the order of cards, and inverts their -faceUp flags. */
- (void) flip;

- (void) addCard: (Card*)card;
- (void) addCardAtBottom: (Card*)card;
- (void) addCardAtRandom: (Card*)card;
- (void) addCards: (NSArray*)cards;

- (Card*) removeTopCard;
- (NSArray*) removeAllCards;

@end
