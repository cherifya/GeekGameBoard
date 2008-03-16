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
#import "Game.h"
#import "Bit.h"
#import "BitHolder.h"
#import "QuartzUtils.h"


@interface Game ()
@property (copy) NSArray *players;
@property (assign) Player *currentPlayer, *winner;
@end


@implementation Game


+ (NSString*) displayName
{
    NSString* name = [self description];
    if( [name hasSuffix: @"Game"] )
        name = [name substringToIndex: name.length-4];
    return name;
}


- (id) initWithBoard: (GGBLayer*)board
{
    self = [super init];
    if (self != nil) {
        _states = [[NSMutableArray alloc] init];
        _moves = [[NSMutableArray alloc] init];
        _currentMove = [[NSMutableString alloc] init];
        _board = [board retain];
        // Store a pointer to myself as the value of the "Game" property
        // of my root layer. (CALayers can have arbitrary KV properties stored into them.)
        // This is used by the -[CALayer game] category method defined below, to find the Game.
        [board setValue: self forKey: @"Game"];
    }
    return self;
}


- (void) dealloc
{
    [_board release];
    [_players release];
    [_currentMove release];
    [_states release];
    [_moves release];
    [super dealloc];
}


@synthesize players=_players, currentPlayer=_currentPlayer, winner=_winner, 
            currentMove=_currentMove, states=_states, moves=_moves;


- (void) setNumberOfPlayers: (unsigned)n
{
    NSMutableArray *players = [NSMutableArray arrayWithCapacity: n];
    for( int i=1; i<=n; i++ ) {
        Player *player = [[Player alloc] initWithGame: self];
        player.name = [NSString stringWithFormat: @"Player %i",i];
        [players addObject: player];
        [player release];
    }
    self.winner = nil;
    self.currentPlayer = nil;
    self.players = players;
}


- (void) addToMove: (NSString*)str;
{
    [_currentMove appendString: str];
}


- (BOOL) _rememberState
{
    if( self.isLatestTurn ) {
        [_states addObject: self.stateString];
        return YES;
    } else
        return NO;
}


- (void) nextPlayer
{
    BOOL latestTurn = [self _rememberState];
    if( ! _currentPlayer ) {
        NSLog(@"*** The %@ Begins! ***", self.class);
        self.currentPlayer = [_players objectAtIndex: 0];
    } else {
        self.currentPlayer = _currentPlayer.nextPlayer;
        if( latestTurn ) {
            [self willChangeValueForKey: @"currentTurn"];
            _currentTurn++;
            [self didChangeValueForKey: @"currentTurn"];
        }
    }
    NSLog(@"Current player is %@",_currentPlayer);
}


- (void) endTurn
{
    NSLog(@"--- End of turn (move was '%@')", _currentMove);
    if( self.isLatestTurn ) {
        [self willChangeValueForKey: @"maxTurn"];
        [_moves addObject: [[_currentMove copy] autorelease]];
        [_currentMove setString: @""];
        [self didChangeValueForKey: @"maxTurn"];
    }

    Player *winner = [self checkForWinner];
    if( winner ) {
        NSLog(@"*** The %@ Ends! The winner is %@ ! ***", self.class, winner);
        [self _rememberState];
        self.winner = winner;
    } else
        [self nextPlayer];
}


- (unsigned) maxTurn
{
    return _moves.count;
}

- (unsigned) currentTurn
{
    return _currentTurn;
}

- (void) setCurrentTurn: (unsigned)turn
{
    NSParameterAssert(turn<=self.maxTurn);
    if( turn != _currentTurn ) {
        if( turn==_currentTurn+1 ) {
            [self applyMoveString: [_moves objectAtIndex: _currentTurn]];
        } else {
            [CATransaction begin];
            [CATransaction setValue:(id)kCFBooleanTrue
                             forKey:kCATransactionDisableActions];
            self.stateString = [_states objectAtIndex: turn];
            [CATransaction commit];
        }
        _currentTurn = turn;
        self.currentPlayer = [_players objectAtIndex: (turn % _players.count)];
    }
}


- (BOOL) isLatestTurn
{
    return _currentTurn == MAX(_states.count,1)-1;
}


- (BOOL) animateMoveFrom: (BitHolder*)src to: (BitHolder*)dst
{
    if( src==nil || dst==nil || dst==src )
        return NO;
    Bit *bit = [src canDragBit: src.bit];
    if( ! bit || ! [dst canDropBit: bit atPoint: GetCGRectCenter(dst.bounds)]
              || ! [self canBit: bit moveFrom: src to: dst] )
        return NO;
    
    ChangeSuperlayer(bit, _board.superlayer, -1);
    bit.pickedUp = YES;
    dst.highlighted = YES;
    [bit performSelector: @selector(setPickedUp:) withObject:nil afterDelay: 0.15];
    CGPoint endPosition = [dst convertPoint: GetCGRectCenter(dst.bounds) toLayer: bit.superlayer];
    [bit animateAndBlock: @"position"
                    from: [NSValue valueWithPoint: NSPointFromCGPoint(bit.position)]
                      to: [NSValue valueWithPoint: NSPointFromCGPoint(endPosition)]
                duration: 0.25];
    dst.bit = bit;
    dst.highlighted = NO;
    bit.pickedUp = NO;
    
    [src draggedBit: bit to: dst];
    [self bit: bit movedFrom: src to: dst];
    src = dst;
    return YES;
}
     

#pragma mark -
#pragma mark GAMEPLAY METHODS TO BE OVERRIDDEN:


+ (BOOL) landscapeOriented
{
    return NO;
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


- (NSString*) stateString                   {return @"";}
- (void) setStateString: (NSString*)s       { }

- (BOOL) applyMoveString: (NSString*)move   {return NO;}

@end




@implementation Player


- (id) initWithGame: (Game*)game
{
    self = [super init];
    if (self != nil) {
        _game = game;
    }
    return self;
}


@synthesize game=_game, name=_name;

- (BOOL) isCurrent      {return self == _game.currentPlayer;}
- (BOOL) isFriendly     {return self == _game.currentPlayer;}   // could be overridden for games with partners
- (BOOL) isUnfriendly   {return ! self.friendly;}

- (int) index
{
    return [_game.players indexOfObjectIdenticalTo: self];
}

- (Player*) nextPlayer
{
    return [_game.players objectAtIndex: (self.index+1) % _game.players.count];
}

- (Player*) previousPlayer
{
    return [_game.players objectAtIndex: (self.index-1) % _game.players.count];
}

- (NSString*) description
{
    return [NSString stringWithFormat: @"%@[%@]", self.class,self.name];
}

@end




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
