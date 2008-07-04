//
//  Turn.m
//  YourMove
//
//  Created by Jens Alfke on 7/3/08.
//  Copyright 2008 Jens Alfke. All rights reserved.
//

#import "Turn.h"
#import "Game+Protected.h"
#import "Player.h"


NSString* const kTurnCompleteNotification = @"TurnComplete";


@interface Turn ()
@property (copy) NSString *move, *boardState;
@property (retain) NSDate *date;
@end



@implementation Turn


- (id) initWithPlayer: (Player*)player
{
    NSParameterAssert(player!=nil);
    self = [super init];
    if (self != nil) {
        _game = player.game;
        _player = player;
        _status = kTurnEmpty;
        self.boardState = _game.latestTurn.boardState;
    }
    return self;
}

- (id) initStartOfGame: (Game*)game
{
    NSParameterAssert(game!=nil);
    self = [super init];
    if (self != nil) {
        _game = game;
        _status = kTurnFinished;
        self.boardState = game.initialStateString;
        self.date = [NSDate date];
    }
    return self;
}


- (id) initWithCoder: (NSCoder*)decoder
{
    self = [self init];
    if( self ) {
        _game =        [decoder decodeObjectForKey: @"game"];
        _player =      [decoder decodeObjectForKey: @"player"];
        _status =      [decoder decodeIntForKey: @"status"];
        _move =       [[decoder decodeObjectForKey: @"move"] copy];
        _boardState = [[decoder decodeObjectForKey: @"boardState"] copy];
        _date =       [[decoder decodeObjectForKey: @"date"] copy];
        _comment =    [[decoder decodeObjectForKey: @"comment"] copy];
    }
    return self;
}

- (void) encodeWithCoder: (NSCoder*)coder
{
    [coder encodeObject: _game       forKey: @"game"];
    [coder encodeObject: _player     forKey: @"player"];
    [coder encodeInt:    _status     forKey: @"status"];
    [coder encodeObject: _move       forKey: @"move"];
    [coder encodeObject: _boardState forKey: @"boardState"];
    [coder encodeObject: _date       forKey: @"date"];
    [coder encodeObject: _comment    forKey: @"comment"];
}

- (void) dealloc
{
    [_move release];
    [_boardState release];
    [_date release];
    [_comment release];
    [super dealloc];
}


- (NSString*) description
{
    return [NSString stringWithFormat: @"%@[%@, #%i, %@]", self.class, _game.class, self.turnNumber, _move];
}


@synthesize game=_game, player=_player, move=_move, boardState=_boardState, date=_date, comment=_comment,
            replaying=_replaying;


- (unsigned) turnNumber     {return [_game.turns indexOfObjectIdenticalTo: self];}
- (BOOL) isLatestTurn       {return _game.turns.lastObject == self;}
- (Turn*) previousTurn      {return [_game.turns objectAtIndex: self.turnNumber-1];}
- (Player*) nextPlayer      {return _player ?_player.nextPlayer :[_game.players objectAtIndex: 0];}

- (TurnStatus) status       {return _status;}

- (void) setStatus: (TurnStatus)status
{
    BOOL ok = NO;
    switch( _status ) {
        case kTurnEmpty:
            ok = (status==kTurnPartial) || (status==kTurnComplete);
            break;
        case kTurnPartial:
            ok = (status==kTurnEmpty) || (status==kTurnComplete) || (status==kTurnFinished);
            break;
        case kTurnComplete:
            ok = (status==kTurnEmpty) || (status==kTurnPartial) || (status==kTurnFinished);
            break;
        case kTurnFinished:
            break;
    }
    NSAssert2(ok,@"Illegal Turn status transition %i -> %i", _status,status);
    
    [self captureBoardState];
    _status = status;
    if( _status==kTurnEmpty ) {
        self.move = nil;
        self.date = nil;
    } else
        self.date = [NSDate date];
}


- (void) addToMove: (NSString*)move
{
    if( ! _replaying ) {
        NSParameterAssert(move.length);
        NSAssert(_status<kTurnComplete,@"Complete Turn can't be modified");
        if( _move )
            move = [_move stringByAppendingString: move];
        self.move = move;
        [self captureBoardState];
        self.date = [NSDate date];
        if( _status==kTurnEmpty )
            self.status = kTurnPartial;
    }
}


- (void) captureBoardState
{
    if( ! _replaying ) {
        NSAssert(_status<kTurnFinished,@"Finished Turn can't be modified");
        if( _game.board )
            self.boardState = _game.stateString;
    }
}


@end
