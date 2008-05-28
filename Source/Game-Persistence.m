//
//  Game-Persistence.m
//  GeekGameBoard
//
//  Created by Jens Alfke on 3/16/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "Game-Persistence.h"


static NSDictionary* parseURLFields( NSURL* url );


@implementation Game (Persistence)


static NSMutableDictionary *sPersistentGames;


- (id) initWithCoder: (NSCoder*)decoder
{
    self = [self init];
    if( self ) {
        _players = [[decoder decodeObjectForKey: @"players"] mutableCopy];
        _states  = [[decoder decodeObjectForKey: @"states"] mutableCopy];
        _moves   = [[decoder decodeObjectForKey: @"moves"] mutableCopy];
        self.currentTurn = self.maxTurn;
    }
    return self;
}


- (void) encodeWithCoder: (NSCoder*)coder
{
    [coder encodeObject: _players forKey: @"players"];
    [coder encodeObject: _states  forKey: @"states"];
    [coder encodeObject: _moves   forKey: @"moves"];
}


- (NSURL*) asURL
{
    return [NSURL URLWithString: 
            [NSString stringWithFormat: @"game:type=%@&id=%@&turn=%u&move=%@",
             [[self class] identifier], _uniqueID, self.currentTurn,_moves.lastObject]];
}


+ (Game*) gameWithURL: (NSURL*)url
{
    if( 0 != [@"game" caseInsensitiveCompare: url.scheme] )
        return nil;
    NSDictionary *fields = parseURLFields(url);
    NSString *type = [fields objectForKey: @"type"];
    NSString *uuid = [fields objectForKey: @"id"];
    int turn = [[fields objectForKey: @"turn"] intValue];
    if( !type || !uuid || turn<=0 )
        return nil;
    
    Game *game = [sPersistentGames objectForKey: uuid];
    if( game ) {
        if( ![type isEqualToString: [[game class] identifier]] )
            return nil;
    } else if( turn == 1 ) {
        Class gameClass = NSClassFromString( [type stringByAppendingString: @"Game"] );
        if( ! gameClass || ! [gameClass isSubclassOfClass: [Game class]] )
            return nil;
        game = [[gameClass alloc] initWithUniqueID: uuid];
        [game setNumberOfPlayers: 2];
        if( ! sPersistentGames )
            sPersistentGames = [[NSMutableDictionary alloc] init];
        [sPersistentGames setObject: game forKey: uuid];
        [game release];
    }
    return game;
}


- (BOOL) addMoveFromURL: (NSURL*)url
{
    NSDictionary *fields = parseURLFields(url);
    NSString *uuid = [fields objectForKey: @"id"];
    NSString *move = [fields objectForKey: @"move"];
    int turn = [[fields objectForKey: @"turn"] intValue];
    return [uuid isEqualToString: self.uniqueID]
        && turn==self.currentTurn
        && move.length > 0
        && [self applyMoveString: move];
}



@end



static NSDictionary* parseURLFields( NSURL* url )
{
    // Parse the URL into key-value pairs:
    NSMutableDictionary *fields = [NSMutableDictionary dictionary];
    for( NSString *field in [url.resourceSpecifier componentsSeparatedByString: @"&"] ) {
        NSRange e = [field rangeOfString: @"="];
        NSString *key, *value;
        if( e.length>0 ) {
            key = [field substringToIndex: e.location];
            value = [field substringFromIndex: NSMaxRange(e)];
        } else {
            key= field;
            value = @"";
        }
        [fields setObject: value forKey: key];
    }
    return fields;
}
