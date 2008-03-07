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
#import "KlondikeGame.h"
#import "Deck.h"
#import "PlayingCard.h"
#import "Stack.h"


#define kStackHeight 500


/**  WARNING: THIS CODE REQUIRES GARBAGE COLLECTION!
 **  This sample application uses Objective-C 2.0 garbage collection.
 **  Therefore, the source code in this file does NOT perform manual object memory management.
 **  If you reuse any of this code in a process that isn't garbage collected, you will need to
 **  add all necessary retain/release/autorelease calls, and implement -dealloc methods,
 **  otherwise unpleasant leakage will occur!
 **/


@implementation KlondikeGame


- (id) initWithBoard: (CALayer*)board
{
    self = [super initWithBoard: board];
    if (self != nil) {
        [self setNumberOfPlayers: 1];
        
        _deck = [[Deck alloc] initWithCardsOfClass: [PlayingCard class]];
        [_deck shuffle];
        _deck.position = CGPointMake(kCardWidth/2+16,kCardHeight/2+16);
        [board addSublayer: _deck];
        
        _sink = [[Deck alloc] init];
        _sink.position = CGPointMake(3*kCardWidth/2+32,kCardHeight/2+16);
        [board addSublayer: _sink];
        
        for( CardSuit suit=kSuitClubs; suit<=kSuitSpades; suit++ ) {
            Deck *aces = [[Deck alloc] init];
            aces.position = CGPointMake(kCardWidth/2+16+(kCardWidth+16)*(suit%2),
                                        120+kCardHeight+(kCardHeight+16)*(suit/2));
            [board addSublayer: aces];
            _aces[suit] = aces;
        }
        
        for( int s=0; s<7; s++ ) {
            Stack *stack = [[Stack alloc] initWithStartPos: CGPointMake(kCardWidth/2,
                                                                        kStackHeight-kCardHeight/2.0)
                                                   spacing: CGSizeMake(0,-22)];
            stack.frame = CGRectMake(260+s*(kCardWidth+16),16, kCardWidth,kStackHeight);
            stack.backgroundColor = nil;
            stack.dragAsStacks = YES;
            [board addSublayer: stack];
            
            // According to the rules, one card should be added to each stack in turn, instead
            // of populating entire stacks one at a time. However, if one trusts the Deck's
            // -shuffle method (which uses the random() function, seeded with a high-entropy
            // cryptographically-strong value), it shouldn't make any difference :-)
            for( int c=0; c<=s; c++ )
                [stack addBit: [_deck removeTopCard]];
            ((Card*)stack.bits.lastObject).faceUp = YES;
        }
        
        [self nextPlayer];
    }
    return self;
}


- (BOOL) clickedBit: (Bit*)bit
{
    if( [bit isKindOfClass: [Card class]] ) {
        Card *card = (Card*)bit;
        if( card.holder == _deck ) {
            // Click on deck deals 3 cards to the sink:
            for( int i=0; i<3; i++ ) {
                Card *card = [_deck removeTopCard];
                if( card ) {
                    [_sink addCard: card];
                    card.faceUp = YES;
                }
            }
            [self endTurn];
            return YES;
        } else if( card.holder == _sink ) {
            // Clicking the sink when the deck is empty re-deals:
            if( _deck.empty ) {
                [_deck addCards: [_sink removeAllCards]];
                [_deck flip];
                [self endTurn];
                return YES;
            }
        } else {
            // Click on a card elsewhere turns it face-up:
            if( ! card.faceUp ) {
                card.faceUp = YES;
                return YES;
            }
        }
    }
    return NO;
}


- (BOOL) canBit: (Bit*)bit moveFrom: (id<BitHolder>)src
{
    if( [bit isKindOfClass: [DraggedStack class]] ) {
        Card *bottomSrc = [[(DraggedStack*)bit bits] objectAtIndex: 0];
        if( ! bottomSrc.faceUp )
            return NO;
    }
    return YES;
}


- (BOOL) canBit: (Bit*)bit moveFrom: (id<BitHolder>)src to: (id<BitHolder>)dst
{
    if( src==_deck || dst==_deck || dst==_sink )
        return NO;
    
    // Find the bottom card being moved, and the top card it's moving onto:
    PlayingCard *bottomSrc;
    if( [bit isKindOfClass: [DraggedStack class]] )
        bottomSrc = [[(DraggedStack*)bit bits] objectAtIndex: 0];
    else
        bottomSrc = (PlayingCard*)bit;
    
    PlayingCard *topDst;
    if( [dst isKindOfClass: [Deck class]] ) {
        // Dragging to an ace pile:
        if( ! [bit isKindOfClass: [Card class]] )
            return NO;
        topDst = (PlayingCard*) ((Deck*)dst).topCard;
        if( topDst == nil )
            return bottomSrc.rank == kRankAce;
        else
            return bottomSrc.suit == topDst.suit && bottomSrc.rank == topDst.rank+1;
        
    } else {
        // Dragging to a card stack:
        topDst = (PlayingCard*) ((Stack*)dst).topBit;
        if( topDst == nil )
            return bottomSrc.rank == kRankKing;
        else
            return bottomSrc.color != topDst.color && bottomSrc.rank == topDst.rank-1;
    }
}


- (Player*) checkForWinner
{
    for( CardSuit suit=kSuitClubs; suit<=kSuitSpades; suit++ )
        if( _aces[suit].cards.count < 13 )
            return nil;
    return _currentPlayer;
}



@end
