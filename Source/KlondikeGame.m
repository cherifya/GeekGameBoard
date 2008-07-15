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
#import "QuartzUtils.h"


#define kStackHeight 500


@implementation KlondikeGame


+ (BOOL) landscapeOriented
{
    return YES;
}


- (id) init
{
    self = [super init];
    if (self != nil)
        [self setNumberOfPlayers: 1];
    return self;
}

        
- (void) setUpBoard
{
    CGSize boardSize = _table.bounds.size;
    CGFloat xSpacing = floor(boardSize.width/7);
    CGSize kCardSize;
    kCardSize.width  = round(xSpacing * 0.9);  // 1/7th of width, with 10% gap
    kCardSize.height = round(kCardSize.width * 1.5);
    CGFloat gap = xSpacing-kCardSize.width;
    [Card setCardSize: kCardSize];
    
    CGPoint pos = {floor(gap/2)+kCardSize.width/2, floor(boardSize.height-kCardSize.height/2)};
    _deck = [[[Deck alloc] initWithCardsOfClass: [PlayingCard class]] autorelease];
    [_deck shuffle];
    _deck.position = pos;
    [_table addSublayer: _deck];
    
    pos.x += xSpacing;
    _sink = [[[Deck alloc] init] autorelease];
    _sink.position = pos;
    [_table addSublayer: _sink];
    
    pos.x += xSpacing;
    for( CardSuit suit=kSuitClubs; suit<=kSuitSpades; suit++ ) {
        pos.x += xSpacing;
        Deck *aces = [[[Deck alloc] init] autorelease];
        aces.position = pos;
        [_table addSublayer: aces];
        _aces[suit] = aces;
    }
    
    CGRect stackFrame = {{floor(gap/2), gap}, 
                         {kCardSize.width, boardSize.height-kCardSize.height-2*gap}};
    CGPoint startPos = CGPointMake(kCardSize.width/2,kCardSize.height/2);
    CGSize spacing = {0, floor((stackFrame.size.height-kCardSize.height)/11.0)};
    for( int s=0; s<7; s++ ) {
        Stack *stack = [[Stack alloc] initWithStartPos: startPos spacing: spacing];
        stack.frame = stackFrame;
        stackFrame.origin.x += xSpacing;
        stack.backgroundColor = nil; //kAlmostInvisibleWhiteColor;
        stack.dragAsStacks = YES;
        [_table addSublayer: stack];
        
        // According to the rules, one card should be added to each stack in turn, instead
        // of populating entire stacks one at a time. However, if one trusts the Deck's
        // -shuffle method (which uses the random() function, seeded with a high-entropy
        // cryptographically-strong value), it shouldn't make any difference :-)
        for( int c=0; c<=s; c++ )
            [stack addBit: [_deck removeTopCard]];
        ((Card*)stack.bits.lastObject).faceUp = YES;
    }
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
    return self.currentPlayer;
}



@end
