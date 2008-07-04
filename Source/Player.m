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
        _uuid = [[decoder decodeObjectForKey: @"UUID"] copy];
        _address = [[decoder decodeObjectForKey: @"address"] copy];
        _addressType = [[decoder decodeObjectForKey: @"addressType"] copy];
        _local=  [decoder decodeBoolForKey:   @"local"];
    }
    return self;
}

- (void) encodeWithCoder: (NSCoder*)coder
{
    [coder encodeObject: _game  forKey: @"game"];
    [coder encodeObject: _name  forKey: @"name"];
    [coder encodeObject: _uuid  forKey: @"UUID"];
    [coder encodeObject: _address forKey: @"address"];
    [coder encodeObject: _addressType forKey: @"addressType"];
    [coder encodeBool:   _local forKey: @"local"];
}

- (void) dealloc
{
    [_name release];
    [_uuid release];
    [_address release];
    [_addressType release];
    [super dealloc];
}


@synthesize game=_game, name=_name, UUID=_uuid, address=_address, addressType=_addressType, local=_local;

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
