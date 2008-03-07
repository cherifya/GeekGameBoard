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


@interface Game ()
@property (copy) NSArray *players;
@property (assign) Player *currentPlayer, *winner;
@end


/**  WARNING: THIS CODE REQUIRES GARBAGE COLLECTION!
 **  This sample application uses Objective-C 2.0 garbage collection.
 **  Therefore, the source code in this file does NOT perform manual object memory management.
 **  If you reuse any of this code in a process that isn't garbage collected, you will need to
 **  add all necessary retain/release/autorelease calls, and implement -dealloc methods,
 **  otherwise unpleasant leakage will occur!
 **/


@implementation Game


+ (NSString*) displayName
{
    NSString* name = [self description];
    if( [name hasSuffix: @"Game"] )
        name = [name substringToIndex: name.length-4];
    return name;
}


- (id) initWithBoard: (CALayer*)board
{
    self = [super init];
    if (self != nil) {
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
    [super dealloc];
}


@synthesize players=_players, currentPlayer=_currentPlayer, winner=_winner;


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


- (void) nextPlayer
{
    if( ! _currentPlayer ) {
        NSLog(@"*** The %@ Begins! ***", self.class);
        self.currentPlayer = [_players objectAtIndex: 0];
    } else {
        self.currentPlayer = _currentPlayer.nextPlayer;
    }
    NSLog(@"Current player is %@",_currentPlayer);
}


- (void) endTurn
{
    NSLog(@"--- End of turn");
    Player *winner = [self checkForWinner];
    if( winner ) {
        NSLog(@"*** The %@ Ends! The winner is %@ ! ***", self.class, winner);
        self.winner = winner;
    } else
        [self nextPlayer];
}


#pragma mark -
#pragma mark GAMEPLAY METHODS TO BE OVERRIDDEN:


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

- (BOOL) clickedBit: (Bit*)bit
{
    return YES;
}

- (Player*) checkForWinner
{
    return nil;
}


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
