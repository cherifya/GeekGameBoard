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
#import "Game+Protected.h"
#import "QuartzUtils.h"
#import "GGBUtils.h"


@interface Game ()
@property (copy) NSArray *players;
@property (assign) Player *winner;
- (void) _startTurn;
@end


@implementation Game


- (id) init
{
    self = [super init];
    if (self != nil) {
        // Don't create _turns till -initWithCoder or -setNumberOfPlayers:.
    }
    return self;
}


- (id) initWithCoder: (NSCoder*)decoder
{
    self = [self init];
    if( self ) {
        _players = [[decoder decodeObjectForKey: @"players"] mutableCopy];
        _winner =   [decoder decodeObjectForKey: @"winner"];
        _turns   = [[decoder decodeObjectForKey: @"turns"] mutableCopy];
        _extraValues = [[decoder decodeObjectForKey: @"extraValues"] mutableCopy];
        self.currentTurnNo = self.maxTurnNo;
    }
    return self;
}


- (void) encodeWithCoder: (NSCoder*)coder
{
    [coder encodeObject: _players forKey: @"players"];
    [coder encodeObject: _winner forKey: @"winner"];
    [coder encodeObject: _turns   forKey: @"turns"];
    [coder encodeObject: _extraValues forKey: @"extraValues"];
}


- (id) initNewGameWithTable: (GGBLayer*)board
{
    self = [self init];
    if( self ) {
        self.table = board;
        NSAssert1(_players && _turns, @"%@ failed to set numberOfPlayers",self);
    }
    return self;
}


- (void) dealloc
{
    [_table release];
    [_players release];
    [_turns release];
    [_extraValues release];
    [super dealloc];
}


@synthesize players=_players, winner=_winner, turns=_turns, requireConfirmation=_requireConfirmation;


- (id)valueForUndefinedKey:(NSString *)key
{
    return [_extraValues objectForKey: key];
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key
{
    if( ! _extraValues )
        _extraValues = [[NSMutableDictionary alloc] init];
    if( value )
        [_extraValues setObject: value forKey: key];
    else
        [_extraValues removeObjectForKey: key];
}


#pragma mark -
#pragma mark BOARD:


- (void) setUpBoard
{
    NSAssert1(NO,@"%@ forgot to implement -setUpBoard",[self class]);
}

- (GGBLayer*) table
{
    return _table;
}

- (void) setTable: (GGBLayer*)board
{
    setObj(&_table,board);
    if( board ) {
        // Store a pointer to myself as the value of the "Game" property
        // of my root layer. (CALayers can have arbitrary KV properties stored into them.)
        // This is used by the -[CALayer game] category method defined below, to find the Game.
        [_table setValue: self forKey: @"Game"];
        
        BeginDisableAnimations();
        
        // Tell the game to add the necessary bits to the board:
        [self setUpBoard];
        
        // Re-apply the current state to set up the pieces/cards:
        self.stateString = [[_turns objectAtIndex: _currentTurnNo] boardState];
        
        EndDisableAnimations();
    }
}


#pragma mark -
#pragma mark PLAYERS:


- (void) setNumberOfPlayers: (unsigned)n
{
    NSMutableArray *players = [NSMutableArray arrayWithCapacity: n];
    for( int i=1; i<=n; i++ ) {
        Player *player = [[Player alloc] initWithGame: self];
        player.name = [NSString stringWithFormat: @"Player %i",i];
        [players addObject: player];
        [player release];
    }
    self.players = players;
    self.winner = nil;
    
    Turn *turn = [[Turn alloc] initStartOfGame: self];
    setObj(&_turns, [NSMutableArray arrayWithObject: turn]);
    [turn release];
    [self _startTurn];
}

- (Player*) remotePlayer
{
    for( Player *player in _players )
        if( ! player.local )
            return player;
    return nil;
}

- (BOOL) isLocal
{
    return self.remotePlayer == nil;
}

- (Player*) currentPlayer
{
    return self.currentTurn.player;
}

+ (NSArray*) keyPathsForValuesAffectingCurrentPlayer {return [NSArray arrayWithObject: @"currentTurn"];}


#pragma mark -
#pragma mark TURNS:


- (Turn*) currentTurn
{
    return [_turns objectAtIndex: _currentTurnNo];
}

- (Turn*) latestTurn
{
    return [_turns lastObject];
}

+ (NSArray*) keyPathsForValuesAffectingCurrentTurn {return [NSArray arrayWithObject: @"currentTurnNo"];}
+ (NSArray*) keyPathsForValuesAffectingLatestTurn  {return [NSArray arrayWithObject: @"turns"];}


- (void) _startTurn
{
    Turn *lastTurn = [_turns lastObject];
    NSAssert(lastTurn.status==kTurnFinished,@"Can't _startTurn till previous turn is finished");
    Turn *newTurn = [[Turn alloc] initWithPlayer: lastTurn.nextPlayer];
    
    [self willChangeValueForKey: @"turns"];
    [_turns addObject: newTurn];
    [self willChangeValueForKey: @"turns"];
    [newTurn release];
    self.currentTurnNo = _turns.count-1;
}


- (BOOL) okToMove
{
    Turn *latest = self.latestTurn;
    if( latest.player.local && latest.status < kTurnComplete ) {
        // Automatically skip from latest finished turn, since board state is the same:
        unsigned latestTurnNo = self.maxTurnNo;
        if( _currentTurnNo==latestTurnNo-1 ) {
            NSLog(@"okToMove: skipping from turn %i to %i",_currentTurnNo,latestTurnNo);
            self.currentTurnNo = latestTurnNo;
        }
        if( _currentTurnNo==latestTurnNo )
            return YES;
    }
    return NO;
}


- (void) endTurn
{
    Turn *curTurn = self.currentTurn;
    if( curTurn.isLatestTurn && ! curTurn.replaying ) {
        curTurn.status = kTurnComplete;
        NSLog(@"--- End of %@", curTurn);
        
        Player *winner = [self checkForWinner];
        if( winner ) {
            NSLog(@"*** The %@ Ends! The winner is %@ ! ***", self.class, winner);
            self.winner = winner;
        }
        
        if( ! _requireConfirmation || !curTurn.player.local ) 
            [self confirmCurrentTurn];

        [[NSNotificationCenter defaultCenter] postNotificationName: kTurnCompleteNotification
                                                            object: curTurn];
    }
}

- (void) cancelCurrentTurn
{
    Turn *curTurn = self.currentTurn;
    if( curTurn.status > kTurnEmpty && curTurn.status < kTurnFinished ) {
        if( _winner )
            self.winner = nil;
        if( _table )
            self.stateString = curTurn.previousTurn.boardState;
        curTurn.status = kTurnEmpty;
    }
}

- (void) confirmCurrentTurn
{
    Turn *curTurn = self.currentTurn;
    if( curTurn.status == kTurnComplete ) {
        curTurn.status = kTurnFinished;
        if( ! _winner )
            [self _startTurn];
    }
}


- (BOOL) isLatestTurn
{
    return _currentTurnNo == _turns.count-1;
}

- (unsigned) maxTurnNo
{
    return _turns.count-1;
}

+ (NSArray*) keyPathsForValuesAffectingIsLatestTurn {return [NSArray arrayWithObjects: @"currentTurnNo",@"turns",nil];}
+ (NSArray*) keyPathsForValuesAffectingMaxTurnNo    {return [NSArray arrayWithObjects: @"turns",nil];}

- (unsigned) currentTurnNo
{
    return _currentTurnNo;
}


#pragma mark -
#pragma mark REPLAYING TURNS:


- (void) setCurrentTurnNo: (unsigned)turnNo
{
    NSParameterAssert(turnNo<=self.maxTurnNo);
    unsigned oldTurnNo = _currentTurnNo;
    if( turnNo != oldTurnNo ) {
        if( _table ) {
            Turn *turn = [_turns objectAtIndex: turnNo];
            NSString *state;
            if( turn.status == kTurnEmpty )
                state = turn.previousTurn.boardState;
            else
                state = turn.boardState;
            NSAssert1(state,@"empty boardState at turn #%i",turnNo);
            _currentTurnNo = turnNo;
            if( turnNo==oldTurnNo+1 ) {
                NSString *move = turn.move;
                if( move ) {
                    NSLog(@"Reapplying move '%@'",move);
                    turn.replaying = YES;
                    @try{
                        if( ! [self applyMoveString: move] ) {
                            _currentTurnNo = oldTurnNo;
                            Warn(@"%@ failed to apply stored move '%@'!", self,move);
                            return;
                        }
                    }@finally{
                        turn.replaying = NO;
                    }
                }
            } else {
                NSLog(@"Reapplying state '%@'",state);
                BeginDisableAnimations();
                self.stateString = state;
                EndDisableAnimations();
            }
            if( ! [self.stateString isEqual: state] ) {
                _currentTurnNo = oldTurnNo;
                Warn(@"%@ failed to apply stored state '%@'!", self,state);
                return;
            }
        } else
            _currentTurnNo = turnNo;
    }
}


- (BOOL) animateMoveFrom: (CALayer<BitHolder>*)src to: (CALayer<BitHolder>*)dst
{
    if( src==nil || dst==nil || dst==src )
        return NO;
    Bit *bit = [src canDragBit: src.bit];
    if( ! bit || ! [dst canDropBit: bit atPoint: GetCGRectCenter(dst.bounds)]
              || ! [self canBit: bit moveFrom: src to: dst] )
        return NO;
    
    ChangeSuperlayer(bit, _table.superlayer, -1);
    bit.pickedUp = YES;
    dst.highlighted = YES;
    [bit performSelector: @selector(setPickedUp:) withObject:nil afterDelay: 0.15];
    CGPoint endPosition = [dst convertPoint: GetCGRectCenter(dst.bounds) toLayer: bit.superlayer];
    [bit animateAndBlock: @"position"
#if TARGET_OS_IPHONE
                    from: [NSValue valueWithCGPoint: bit.position]
                      to: [NSValue valueWithCGPoint: endPosition]
#else
                    from: [NSValue valueWithPoint: NSPointFromCGPoint(bit.position)]
                      to: [NSValue valueWithPoint: NSPointFromCGPoint(endPosition)]
#endif
                duration: 0.25];
    dst.bit = bit;
    dst.highlighted = NO;
    bit.pickedUp = NO;
    
    [src draggedBit: bit to: dst];
    [self bit: bit movedFrom: src to: dst];
    return YES;
}


- (BOOL) animatePlacementIn: (CALayer<BitHolder>*)dst
{
    if( dst == nil )
        return NO;
    Bit *bit = [self bitToPlaceInHolder: dst];
    if( ! bit )
        return NO;
    
    CALayer<BitHolder>* oldHolder = (CALayer<BitHolder>*) bit.holder;
    if( oldHolder ) {
        if( oldHolder != dst ) 
            return [self animateMoveFrom: oldHolder to: dst];
    } else
        bit.position = [dst convertPoint: GetCGRectCenter(dst.bounds) toLayer: _table.superlayer];
    ChangeSuperlayer(bit, _table.superlayer, -1);
    bit.pickedUp = YES;
    dst.highlighted = YES;
    
    DelayFor(0.2);
    
    dst.bit = bit;
    dst.highlighted = NO;
    bit.pickedUp = NO;
    
    [self bit: bit movedFrom: nil to: dst];
    return YES;
}
     

#pragma mark -
#pragma mark GAMEPLAY METHODS TO BE OVERRIDDEN:


+ (NSString*) identifier
{
    NSString* name = [self description];
    if( [name hasSuffix: @"Game"] )
        name = [name substringToIndex: name.length-4];
    return name;
}

+ (NSString*) displayName
{
    return [self identifier];
}

+ (BOOL) landscapeOriented
{
    return NO;
}


- (NSString*) initialStateString
{
    return @"";
}


- (CGImageRef) iconForPlayer: (int)playerIndex
{
    return nil;
}


- (BOOL) canBit: (Bit*)bit moveFrom: (id<BitHolder>)src
{
    return YES;
}

- (BOOL) canBit: (Bit*)bit moveFrom: (id<BitHolder>)src to: (id<BitHolder>)dst
{
    return YES;
}

- (void) bit: (Bit*)bit movedFrom: (id<BitHolder>)src to: (id<BitHolder>)dst
{
    [self endTurn];
}

- (Bit*) bitToPlaceInHolder: (id<BitHolder>)holder
{
    return nil;
}


- (BOOL) clickedBit: (Bit*)bit
{
    return YES;
}

- (Player*) checkForWinner
{
    return nil;
}

/* These are abstract
 
- (NSString*) stateString                   {return @"";}
- (void) setStateString: (NSString*)s       { }

- (BOOL) applyMoveString: (NSString*)move   {return NO;}
*/

@end




#pragma mark -
@implementation CALayer (Game)

- (Game*) game
{
    // The Game object stores a pointer to itself as the value of the "Game" property
    // of its root layer. (CALayers can have arbitrary KV properties stored into them.)
    for( CALayer *layer = self; layer; layer=layer.superlayer ) {
        Game *game = [layer valueForKey: @"Game"];
        if( game )
            return game;
    }
    NSAssert1(NO,@"Couldn't look up Game from %@",self);
    return nil;
}

@end
