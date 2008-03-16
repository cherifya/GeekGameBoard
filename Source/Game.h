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
@class GGBLayer, Bit, BitHolder, Player;
@protocol BitHolder;


/** Abstract superclass. Keeps track of the rules and turns of a game. */
@interface Game : NSObject
{
    GGBLayer *_board;
    NSArray *_players;
    Player *_currentPlayer, *_winner;
    NSMutableString *_currentMove;
    NSMutableArray *_states, *_moves;
    unsigned _currentTurn;
}

/** Returns the human-readable name of this game.
    (By default it just returns the class name with the "Game" suffix removed.) */
+ (NSString*) displayName;

+ (BOOL) landscapeOriented;

@property (readonly, copy) NSArray *players;
@property (readonly) Player *currentPlayer, *winner;

@property (readonly) NSArray *states, *moves;
@property (readonly) unsigned maxTurn;
@property unsigned currentTurn;
@property (readonly) BOOL isLatestTurn;

- (BOOL) animateMoveFrom: (BitHolder*)src to: (BitHolder*)dst;


// Methods for subclasses to implement:

/** Designated initializer. After calling the superclass implementation,
    it should add the necessary Grids, Pieces, Cards, Decks etc. to the board. */
- (id) initWithBoard: (GGBLayer*)board;


/** Should return YES if it is legal for the given bit to be moved from its current holder.
    Default implementation always returns YES. */
- (BOOL) canBit: (Bit*)bit moveFrom: (id<BitHolder>)src;

/** Should return YES if it is legal for the given Bit to move from src to dst.
    Default implementation always returns YES. */
- (BOOL) canBit: (Bit*)bit moveFrom: (id<BitHolder>)src to: (id<BitHolder>)dst;


/** Should handle any side effects of a Bit's movement, such as captures or scoring.
    Does not need to do the actual movement! That's already happened.
    It should end by calling -endTurn, if the player's turn is over.
    Default implementation just calls -endTurn. */
- (void) bit: (Bit*)bit movedFrom: (id<BitHolder>)src to: (id<BitHolder>)dst;

/** Called on mouse-down/touch of an *empty* BitHolder. Should return a Bit if
    it's OK to place a new Bit there; else nil. */
- (Bit*) bitToPlaceInHolder: (id<BitHolder>)holder;

/** Called instead of the above if a Bit is simply clicked, not dragged.
    Should return NO if the click is illegal (i.e. clicking an empty draw pile in a card game.)
    Default implementation always returns YES. */
- (BOOL) clickedBit: (Bit*)bit;

/** Should return the winning player, if the current position is a win, else nil.
    Default implementation returns nil. */
- (Player*) checkForWinner;


@property (copy) NSString* stateString;
- (BOOL) applyMoveString: (NSString*)move;


// Protected methods for subclasses to call:

/** Sets the number of players in the game. Subclass initializers should call this. */
- (void) setNumberOfPlayers: (unsigned)n;

/** The current move in progress. Append text to it as the user makes moves. */
@property (readonly) NSMutableString* currentMove;

/** Advance to the next player, when a turn is over. */
- (void) nextPlayer;

/** Checks for a winner and advances to the next player. */
- (void) endTurn;

@end



/** A mostly-passive object used to represent a player. */
@interface Player : NSObject
{
    Game *_game;
    NSString *_name;
}

- (id) initWithGame: (Game*)game;

@property (readonly) Game *game;
@property (copy) NSString *name;
@property (readonly) int index;
@property (readonly, getter=isCurrent) BOOL current;
@property (readonly, getter=isFriendly) BOOL friendly;
@property (readonly, getter=isUnfriendly) BOOL unfriendly;
@property (readonly) Player *nextPlayer, *previousPlayer;

@end



@interface CALayer (Game)

/** Called on any CALayer in the game's layer tree, will return the current Game object. */
@property (readonly) Game *game;

@end
