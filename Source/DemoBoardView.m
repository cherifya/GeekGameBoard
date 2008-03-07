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
#import "DemoBoardView.h"
#import "Game.h"
#import "QuartzUtils.h"


/**  WARNING: THIS CODE REQUIRES GARBAGE COLLECTION!
 **  This sample application uses Objective-C 2.0 garbage collection.
 **  Therefore, the source code in this file does NOT perform manual object memory management.
 **  If you reuse any of this code in a process that isn't garbage collected, you will need to
 **  add all necessary retain/release/autorelease calls, and implement -dealloc methods,
 **  otherwise unpleasant leakage will occur!
 **/


@implementation DemoBoardView


/** Class names of available games */
static NSString* const kMenuGameNames[] = {@"KlondikeGame", @"CheckersGame", @"HexchequerGame",
                                           @"TicTacToeGame", @"GoGame"};

/** Class name of the current game. */
static NSString* sCurrentGameName = @"KlondikeGame";


- (void) startGameNamed: (NSString*)gameClassName
{
    [super startGameNamed: gameClassName];
    
    Game *game = self.game;
    [game addObserver: self 
           forKeyPath: @"currentPlayer"
              options: NSKeyValueObservingOptionInitial
              context: NULL];
    [game addObserver: self
           forKeyPath: @"winner"
              options: 0 
              context: NULL];
    
    self.window.title = [(id)[game class] displayName];
}


- (CGRect) gameBoardFrame
{
    CGRect bounds = [super gameBoardFrame];
    bounds.size.height -= 32;                   // Leave room for headline
    return CGRectInset(bounds,4,4);
}


- (void) awakeFromNib
{
    srandomdev();
    
    [self registerForDraggedTypes: [NSImage imagePasteboardTypes]];
    [self registerForDraggedTypes: [NSArray arrayWithObject: NSFilenamesPboardType]];
    
    CGRect bounds = self.layer.bounds;
    self.layer.backgroundColor = GetCGPatternNamed(@"/Library/Desktop Pictures/Small Ripples graphite.png");
        
    bounds.size.height -= 32;
    _headline = AddTextLayer(self.layer,
                             nil, [NSFont boldSystemFontOfSize: 24], 
                             kCALayerWidthSizable | kCALayerMinYMargin);
    
    [self startGameNamed: sCurrentGameName];
}


- (void) startGameFromMenu: (id)sender
{
    sCurrentGameName = kMenuGameNames[ [sender tag] ];
    [self startGameNamed: sCurrentGameName];
}


- (void)observeValueForKeyPath:(NSString *)keyPath 
                      ofObject:(id)object 
                        change:(NSDictionary *)change
                       context:(void *)context
{
    Game *game = self.game;
    if( object == game ) {
        Player *p = game.winner;
        NSString *msg;
        if( p ) {
            [[NSSound soundNamed: @"Sosumi"] play];
            msg = @"%@ wins! Congratulations!";
        } else {
            p = game.currentPlayer;
            msg = @"Your turn, %@";
        }
        _headline.string = [NSString stringWithFormat: msg, p.name];
    }
}


- (IBAction) enterFullScreen: (id)sender
{
    [super enterFullScreen: sender];
    [self startGameNamed: sCurrentGameName];        // restart game so it'll use the new size
}


#pragma mark -
#pragma mark NSAPPLICATION DELEGATE:


- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    return YES;
}

@end
