//
//  Player.h
//  YourMove
//
//  Created by Jens Alfke on 7/3/08.
//  Copyright 2008 Jens Alfke. All rights reserved.
//

#import <Foundation/Foundation.h>
@class Game;


/** A mostly-passive object used to represent a player. */
@interface Player : NSObject <NSCoding>
{
    Game *_game;
    NSString *_name, *_uuid, *_address, *_addressType;
    BOOL _local;
}

- (id) initWithGame: (Game*)game;
- (id) initWithName: (NSString*)name;

- (id) initWithCoder: (NSCoder*)decoder;
- (void) encodeWithCoder: (NSCoder*)coder;

@property (readonly) Game *game;
@property (copy) NSString *name,                            // Display name
                          *UUID,                            // Address Book UUID
                          *address,                         // Contact address
                          *addressType;                     // Contact address type (an AB property type)
@property (readonly) int index;                             // Player's index in the Game's -players array
@property (readwrite,getter=isLocal) BOOL local;            // Is the player on this computer? (Defaults to YES)
@property (readonly, getter=isCurrent) BOOL current;        // Is it this player's turn?
@property (readonly, getter=isFriendly) BOOL friendly;      // Is this player the current player or an ally?
@property (readonly, getter=isUnfriendly) BOOL unfriendly;  // Is this player an opponent of the current player?
@property (readonly) Player *nextPlayer, *previousPlayer;   // The next/previous player in sequence
@property (readonly) CGImageRef icon;
@end



@interface CALayer (Game)

/** Called on any CALayer in the game's layer tree, will return the current Game object. */
@property (readonly) Game *game;

@end
