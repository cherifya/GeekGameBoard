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
#import "Deck.h"
#import "Card.h"
#import "Stack.h"
#import "QuartzUtils.h"
#import "GGBUtils.h"


@interface Deck ()
- (void) setCards: (NSMutableArray*)cards;
- (void) x_showTopCard;
@end


@implementation Deck


- (id) init
{
    self = [super init];
    if (self != nil) {
        self.bounds = (CGRect){{0,0},[Card cardSize]};
        self.cornerRadius = 8;
        self.backgroundColor = kAlmostInvisibleWhiteColor;
        self.borderColor = kHighlightColor;
        self.cards = [NSMutableArray array];
    }
    return self;
}

- (id) initWithCardsOfClass: (Class)klass
{
    self = [self init];
    if (self != nil) {
        // Create a full deck of cards:
        NSRange serials = [klass serialNumberRange];
        for( int i=serials.location; i<NSMaxRange(serials); i++ ) {
            Card *card = [[klass alloc] initWithSerialNumber: i
                                                    position: CGPointZero];
            [_cards addObject: card];
            [card release];
        }
        [self x_showTopCard];
    }
    return self;
}


- (void) dealloc
{
    [_cards release];
    [super dealloc];
}


- (NSArray*) cards                          {return _cards;}
- (void) setCards: (NSMutableArray*)cards   {setObj(&_cards,cards);}

- (Card*) topCard   {return (Card*)_bit;}


- (void) setBit: (Bit*)bit
{
    NSAssert(NO,@"Don't call -setBit");
}


- (void) x_removeObsoleteCard: (Card*)card
{
    if( [_cards containsObject: card] && card != _bit )
        RemoveImmediately(card);
}


/** Sync up my display with the _cards array. The last element of _cards should be shown,
    and no others (they shouldn't even be in the layer tree, for performance reasons.) */
- (void) x_showTopCard
{
    Card *curTopCard = [_cards lastObject];
    if( curTopCard != _bit ) {
        if( _bit ) {
            // Remove card that used to be the top one
            if( [_cards containsObject: _bit] )   // wait till new card animates on top of it
                [self performSelector: @selector(x_removeObsoleteCard:) withObject: _bit afterDelay: 1.0];
            else
                RemoveImmediately(_bit);
        }
        _bit = curTopCard;
        if( curTopCard ) {
            if( curTopCard.superlayer==self ) {
                [self addSublayer: curTopCard]; // move to top
                curTopCard.position = GetCGRectCenter(self.bounds);
            } else {
                if( curTopCard.superlayer )
                    ChangeSuperlayer(curTopCard, self, -1);
                curTopCard.position = GetCGRectCenter(self.bounds);
                if( ! curTopCard.superlayer )
                    [self addSublayer: curTopCard];
            }
        }
    }
}


- (void) shuffle
{
    int n = _cards.count;
    NSMutableArray *shuffled = [NSMutableArray arrayWithCapacity: n];
    for( ; n > 0; n-- ) {
        int i = random() % n;
        Card *card = [_cards objectAtIndex: i];
        [shuffled addObject: card];
        [_cards removeObjectAtIndex: i];
    }
    self.cards = shuffled;
    [self x_showTopCard];
}


- (void) flip
{
    int n = _cards.count;
    NSMutableArray *flipped = [NSMutableArray arrayWithCapacity: n];
    while( --n >= 0 ) {
        Card *card = [_cards objectAtIndex: n];
        card.faceUp = ! card.faceUp;
        [flipped addObject: card];
    }
    self.cards = flipped;
    [self x_showTopCard];
}


- (void) addCard: (Card*)card
{
    [_cards addObject: card];
    [self x_showTopCard];
}

- (void) addCardAtBottom: (Card*)card
{
    [_cards insertObject: card atIndex: 0];
    if( _cards.count==1 )
        [self x_showTopCard];
}

- (void) addCardAtRandom: (Card*)card
{
    // Put the card at some random location, but _not_ on top (unless the deck is empty.)
    int n = _cards.count;
    if( n==0 )
        [self addCard: card];
    else
        [_cards insertObject: card atIndex: (random() % (n-1))];
}


- (void) addCards: (NSArray*)cards
{
    [_cards addObjectsFromArray: cards];
    [self x_showTopCard];
}


- (BOOL) addBit: (Bit*)bit
{
    if( [bit isKindOfClass: [DraggedStack class]] ) {
        // Convert a DraggedStack back to a group of Cards:
        for( Bit *subBit in [(DraggedStack*)bit bits] )
            if( ! [self addBit: subBit] )
                return NO;
        return YES;
    } else if( [bit isKindOfClass: [Card class]] ) {
        [self addCard: (Card*)bit];
        return YES;
    } else
        return NO;
}


- (Card*) removeTopCard
{
    Card *card = [_cards lastObject];
    if( card ) {
        [[card retain] autorelease];
        [_cards removeLastObject];
        _bit = nil;   // keep it from being removed from superlayer by _showTopCard
        [self x_showTopCard];
    }
    return card;
}


- (NSArray*) removeAllCards
{
    NSArray *removedCards = [[_cards retain] autorelease];
    self.cards = [NSMutableArray array];
    [removedCards makeObjectsPerformSelector: @selector(removeFromSuperlayer)];
    [self x_showTopCard];
    return removedCards;
}


#pragma mark -
#pragma mark BITHOLDER INTERFACE:


- (Bit*) canDragBit: (Bit*)bit
{
    if( bit == _bit ) {
        [bit retain];
        [_cards removeObjectIdenticalTo: bit];
        _bit = nil;   // prevent the card from being removed from my layer
        [self x_showTopCard];
        return [bit autorelease];
    } else
        return nil;
}

- (void) cancelDragBit: (Bit*)bit
{
    [self addCard: (Card*)bit];
}

- (void) draggedBit: (Bit*)bit to: (id<BitHolder>)dst   {}


- (void) setHighlighted: (BOOL)h    
{
    [super setHighlighted: h];
    self.borderWidth = h ?6 :0;
}

- (BOOL) canDropBit: (Bit*)bit atPoint: (CGPoint)point
{
    return [bit isKindOfClass: [Card class]] || [bit isKindOfClass: [DraggedStack class]];
}

- (BOOL) dropBit: (Bit*)bit atPoint: (CGPoint)point
{
    return [self addBit: bit];
}



@end
