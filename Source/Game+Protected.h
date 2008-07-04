//
//  Game+Protected.h
//  YourMove
//
//  Created by Jens Alfke on 7/3/08.
//  Copyright 2008 Jens Alfke. All rights reserved.
//


#import "Game.h"
#import "Player.h"
#import "Turn.h"
#import "Bit.h"
#import "BitHolder.h"


/** Game API for subclasses to use / override */
@interface Game (Protected)

/** Should return a string describing the initial state of a new game.
    The default value is an empty string. */
- (NSString*) initialStateString;


#pragma mark  Abstract methods for subclasses to implement:

/** Called by -setBoard: Should all all necessary Grids/Pieces/Cards/etc. to _board.
    This method is always called during initialization of a new Game, and may be called
    again afterwards, for example if the board area is resized. */
- (void) setUpBoard;

/** Should return the winning player, if the current position is a win, else nil.
    Default implementation returns nil. */
- (Player*) checkForWinner;


#pragma mark  Protected methods for subclasses to call:

/** Sets the number of players in the game. Subclass initializers should call this. */
- (void) setNumberOfPlayers: (unsigned)n;

/** Animate a piece moving from src to dst. Used in implementing -applyMoveString:. */
- (BOOL) animateMoveFrom: (CALayer<BitHolder>*)src to: (CALayer<BitHolder>*)dst;

/** Animate a piece being placed in dst. Used in implementing -applyMoveString:. */
- (BOOL) animatePlacementIn: (CALayer<BitHolder>*)dst;

/** Checks for a winner and advances to the next player. */
- (void) endTurn;

@end


/** Optional Game API for tracking the history of a game, and being able to replay moves. */
@interface Game (State)

/** A string describing the current state of the game (the positions of all pieces,
 orderings of cards, player scores, ... */
@property (copy) NSString* stateString;

/** Add a move to the game based on the contents of the string.
 The string must have been returned by -currentMove at some point. */
- (BOOL) applyMoveString: (NSString*)move;

@end
