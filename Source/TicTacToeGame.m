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
#import "TicTacToeGame.h"
#import "Grid.h"
#import "Dispenser.h"
#import "Piece.h"
#import "QuartzUtils.h"


@implementation TicTacToeGame

- (void) x_createDispenser: (NSString*)imageName forPlayer: (int)playerNumber
{
    Piece *p = [[Piece alloc] initWithImageNamed: imageName scale: 80];
    p.owner = [self.players objectAtIndex: playerNumber];
    CGFloat x = floor(CGRectGetMidX(_board.bounds));
#if TARGET_OS_ASPEN
    x = x - 80 + 160*playerNumber;
    CGFloat y = 360;
#else
    x += (playerNumber==0 ?-230 :230);
    CGFloat y = 175;
#endif
    _dispenser[playerNumber] = [[Dispenser alloc] initWithPrototype: p quantity: 0
                                                        frame: CGRectMake(x-45,y-45, 90,90)];
    [_board addSublayer: _dispenser[playerNumber]];
}

- (id) initWithBoard: (GGBLayer*)board
{
    self = [super initWithBoard: board];
    if (self != nil) {
        [self setNumberOfPlayers: 2];
        
        // Create a 3x3 grid:
        CGFloat center = floor(CGRectGetMidX(board.bounds));
        _grid = [[RectGrid alloc] initWithRows: 3 columns: 3 frame: CGRectMake(center-150,0, 300,300)];
        [_grid addAllCells];
        _grid.allowsMoves = _grid.allowsCaptures = NO;
        _grid.cellColor = CreateGray(1.0, 0.25);
        _grid.lineColor = kTranslucentLightGrayColor;
        [board addSublayer: _grid];
        
        // Create piece dispensers for the two players:
        [self x_createDispenser: @"X.tiff" forPlayer: 0];
        [self x_createDispenser: @"O.tiff" forPlayer: 1];
        
        // And they're off!
        [self nextPlayer];
    }
    return self;
}

- (void) nextPlayer
{
    [super nextPlayer];
    // Give the next player another piece to put down:
    _dispenser[self.currentPlayer.index].quantity = 1;
}

static Player* ownerAt( Grid *grid, int index )
{
    return [grid cellAtRow: index/3 column: index%3].bit.owner;
}

/** Should return the winning player, if the current position is a win. */
- (Player*) checkForWinner
{
    static const int kWinningTriples[8][3] =  { {0,1,2}, {3,4,5}, {6,7,8},  // rows
                                                {0,3,6}, {1,4,7}, {2,5,8},  // cols
                                                {0,4,8}, {2,4,6} };         // diagonals
    for( int i=0; i<8; i++ ) {
        const int *triple = kWinningTriples[i];
        Player *p = ownerAt(_grid,triple[0]);
        if( p && p == ownerAt(_grid,triple[1]) && p == ownerAt(_grid,triple[2]) )
            return p;
    }
    return nil;
}

@end
