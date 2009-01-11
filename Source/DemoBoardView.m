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
#import "Turn.h"
#import "Player.h"
#import "GGBTextLayer.h"
#import "QuartzUtils.h"


@implementation DemoBoardView


/** Class names of available games */
static NSString* const kMenuGameNames[] = {@"KlondikeGame", @"CheckersGame", @"HexchequerGame",
                                           @"TicTacToeGame", @"GoGame"};

/** Class name of the current game. */
static NSString* sCurrentGameName = @"CheckersGame";


- (IBAction) toggleRemoteOpponent: (id)sender
{
    NSAssert(self.game.currentTurnNo==0,@"Game has already begun");
    Player *opponent = [self.game.players objectAtIndex: 1];
    opponent.local = !opponent.local;
}


- (void) startGameNamed: (NSString*)gameClassName
{
    [self.game removeObserver: self 
           forKeyPath: @"currentPlayer"];
    [self.game removeObserver: self
           forKeyPath: @"winner"];

    [super startGameNamed: gameClassName];
    
    [self.game addObserver: self 
           forKeyPath: @"currentPlayer"
              options: NSKeyValueObservingOptionInitial
              context: NULL];
    [self.game addObserver: self
           forKeyPath: @"winner"
              options: 0 
              context: NULL];
    
    self.window.title = [(id)[self.game class] displayName];
}


- (CGRect) gameBoardFrame
{
    CGRect bounds = [super gameBoardFrame];
    bounds.size.height -= 32;                   // Leave room for headline
    return CGRectInset(bounds,4,4);
}


- (BOOL)canBecomeKeyView        {return YES;}
- (BOOL)acceptsFirstResponder   {return YES;}


- (void) awakeFromNib
{
    srandomdev();
    
    // BoardView supports receiving dragged images, but you have to register for them:
    [self registerForDraggedTypes: [NSImage imagePasteboardTypes]];
    [self registerForDraggedTypes: [NSArray arrayWithObject: NSFilenamesPboardType]];
    
    CGRect bounds = self.layer.bounds;
    self.layer.backgroundColor = GetCGPatternNamed(@"Background.png");
        
    bounds.size.height -= 32;
    _headline = [GGBTextLayer textLayerInSuperlayer: self.layer
                                           withText: nil
                                           fontSize: 24
                                          alignment: kCALayerWidthSizable | kCALayerMinYMargin];
    
    [self startGameNamed: sCurrentGameName];
    
    [_turnSlider bind: @"value"    toObject: self withKeyPath: @"game.currentTurnNo" options: nil];
}


- (IBAction) startGameFromMenu: (id)sender
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
        NSLog(@"maxTurnNo = %u, currentTurnNo = %u", 
              self.game.maxTurnNo,self.game.currentTurnNo);
        NSLog(@"Game state = '%@'", self.game.currentTurn.boardState);

        _turnSlider.maxValue = self.game.maxTurnNo;
        _turnSlider.numberOfTickMarks = self.game.maxTurnNo+1;
        
        Player *p = game.winner;
        NSString *msg;
        if( p ) {
            // The game is won
            [[NSSound soundNamed: @"Sosumi"] play];
            if( self.game.local )
                msg = @"%@ wins! Congratulations!";
            else
                msg = p.local ?@"You Win! Congratulations!" :@"You Lose ... :-(";
        } else {
            // Otherwise go on to the next turn:
            p = game.currentPlayer;
            msg = @"Your turn, %@";
        }
        _headline.string = [NSString stringWithFormat: msg, p.name];
    }
}


- (IBAction) undo: (id)sender
{
    if( self.game.currentTurn > 0 )
        self.game.currentTurnNo--;
    else
        NSBeep();
}


- (IBAction) redo: (id)sender
{
    if( self.game.currentTurnNo < self.game.maxTurnNo )
        self.game.currentTurnNo++;
    else
        NSBeep();
}


#pragma mark -
#pragma mark NSAPPLICATION DELEGATE:


- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    return YES;
}

@end
