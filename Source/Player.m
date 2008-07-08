//
//  Player.m
//  YourMove
//
//  Created by Jens Alfke on 7/3/08.
//  Copyright 2008 Jens Alfke. All rights reserved.
//

#import "Player.h"
#import "Game.h"


#pragma mark -
@implementation Player


- (id) initWithGame: (Game*)game
{
    self = [super init];
    if (self != nil) {
        _game = game;
        _local = YES;
    }
    return self;
}

- (id) initWithName: (NSString*)name
{
    self = [super init];
    if (self != nil) {
        self.name = name;
    }
    return self;
}


- (id) initWithCoder: (NSCoder*)decoder
{
    self = [self init];
    if( self ) {
        _game =  [decoder decodeObjectForKey: @"game"];
        _name = [[decoder decodeObjectForKey: @"name"] copy];
        _local=  [decoder decodeBoolForKey:   @"local"];
        _extraValues = [[decoder decodeObjectForKey: @"extraValues"] mutableCopy];
    }
    return self;
}

- (void) encodeWithCoder: (NSCoder*)coder
{
    [coder encodeObject: _game  forKey: @"game"];
    [coder encodeObject: _name  forKey: @"name"];
    [coder encodeBool:   _local forKey: @"local"];
    [coder encodeObject: _extraValues forKey: @"extraValues"];
}

- (void) dealloc
{
    [_name release];
    [_extraValues release];
    [super dealloc];
}


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


@synthesize game=_game, name=_name, local=_local;

- (BOOL) isCurrent      {return self == _game.currentPlayer;}
- (BOOL) isFriendly     {return self == _game.currentPlayer;}   // could be overridden for games with partners
- (BOOL) isUnfriendly   {return ! self.friendly;}

+ (NSArray*) keyPathsForValuesAffectingCurrent {return [NSArray arrayWithObject: @"game.currentPlayer"];}


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

- (CGImageRef) icon
{
    return [_game iconForPlayer: self.index];
}

- (NSString*) description
{
    return [NSString stringWithFormat: @"%@[%@]", self.class,self.name];
}

@end
