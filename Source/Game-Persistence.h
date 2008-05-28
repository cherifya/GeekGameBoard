//
//  Game-Persistence.h
//  GeekGameBoard
//
//  Created by Jens Alfke on 3/16/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "Game.h"


@interface Game (Persistence) <NSCoding>

+ (Game*) gameWithURL: (NSURL*)url;

- (NSURL*) asURL;

- (BOOL) addMoveFromURL: (NSURL*)url;

@end
