//
//  Turn.h
//  YourMove
//
//  Created by Jens Alfke on 7/3/08.
//  Copyright 2008 Jens Alfke. All rights reserved.
//

#import <Foundation/Foundation.h>
@class Game, Player;


typedef enum {
    kTurnEmpty,             // No action yet
    kTurnPartial,           // Action taken, but more needs to be done
    kTurnComplete,          // Action complete, but player needs to confirm
    kTurnFinished           // Turn is confirmed and finished
} TurnStatus;


extern NSString* const kTurnCompleteNotification;


/** A record of a particular turn in a Game, including the player's move and the resulting state. */
@interface Turn : NSObject <NSCoding>
{
    Game *_game;
    Player *_player;
    TurnStatus _status;
    NSString *_move;
    NSString *_boardState;
    NSDate *_date;
    NSString *_comment;
    BOOL _replaying;
}

- (id) initWithPlayer: (Player*)player;
- (id) initStartOfGame: (Game*)game;

@property (readonly)      Game      *game;
@property (readonly)      Player    *player, *nextPlayer;
@property (readonly)      Turn      *previousTurn;
@property (readonly)      unsigned   turnNumber;
@property (readonly)      BOOL       isLatestTurn;

@property                 TurnStatus status;

@property (readonly,copy) NSString  *move;
@property (readonly,copy) NSString  *boardState;
@property (readonly,retain)NSDate   *date;
@property (copy)          NSString  *comment;

/** Appends to the move string. Only allowed if the status is Empty or Partial. */
- (void) addToMove: (NSString*)move;

/** Copies the current state of the Game's board to my boardState */
- (void) captureBoardState;

@property BOOL replaying;

@end
