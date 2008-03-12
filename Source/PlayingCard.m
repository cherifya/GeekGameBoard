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
#import "PlayingCard.h"
#import "GGBTextLayer.h"
#import "QuartzUtils.h"


@implementation PlayingCard


+ (NSRange) serialNumberRange;
{
    return NSMakeRange(1,52);
}


- (GGBLayer*) createFront
{
    GGBLayer *front = [super createFront];
    NSString *name = [NSString stringWithFormat: @"%@%@",
                      self.rankString, self.suitString];
    
    CGColorRef suitColor = self.suitColor;
    float scale = [Card cardSize].height/150;
    float cornerFontSize = MAX(18*scale, 14);
    float centerFontSize = 80*scale;
    
#if TARGET_OS_ASPEN
    UIFont *cornerFont = [UIFont boldSystemFontOfSize: cornerFontSize];
#else
    NSFont *cornerFont = [NSFont boldSystemFontOfSize: cornerFontSize];
#endif
    GGBTextLayer *label;
    label = [GGBTextLayer textLayerInSuperlayer: front
                                       withText: name
                                           font: cornerFont
                                      alignment: kCALayerMaxXMargin | kCALayerBottomMargin];
    label.foregroundColor = suitColor;
    label = [GGBTextLayer textLayerInSuperlayer: front
                                       withText: name
                                           font: cornerFont
                                      alignment: kCALayerMaxXMargin | kCALayerTopMargin];
    label.foregroundColor = suitColor;
    label.anchorPoint = CGPointMake(1,1);
    [label setValue: [NSNumber numberWithFloat: M_PI] forKeyPath: @"transform.rotation"];
    
    label = [GGBTextLayer textLayerInSuperlayer: front
                                       withText: self.faceSymbol
                                       fontSize: centerFontSize
                                      alignment: kCALayerWidthSizable | kCALayerHeightSizable];
    label.foregroundColor = suitColor;
    //label.borderWidth = 1;
    //label.borderColor = kBlackColor;
    
    return front;
}


- (CardRank) rank       {return (self.serialNumber-1)%13 + 1;}
- (CardSuit) suit       {return (self.serialNumber-1)/13;}

- (CardColor) color
{
    CardSuit suit = self.suit;
    return suit==kSuitDiamonds || suit==kSuitHearts ?kColorRed :kColorBlack;
}


- (NSString*) suitString
{
    return [@"\u2663\u2666\u2665\u2660" substringWithRange: NSMakeRange(self.suit,1)];
}

- (NSString*) rankString
{
    CardRank rank = self.rank;
    if( rank == 10 )
        return @"10";
    else
        return [@"A234567890JQK" substringWithRange: NSMakeRange(rank-1,1)];
}

- (CGColorRef) suitColor
{
    static CGColorRef kSuitColor[4];
    if( ! kSuitColor[0] ) {
        kSuitColor[0] = kSuitColor[3] = kBlackColor;
        kSuitColor[1] = kSuitColor[2] = CreateRGB(1, 0, 0, 1);
    }
    return kSuitColor[self.suit];
}


- (NSString*) faceSymbol
{
    int rank = self.rank;
    if( rank < kRankJack )
        return self.suitString;
    else
        return [@"\u265E\u265B\u265A" substringWithRange: NSMakeRange(rank-kRankJack,1)]; // actually chess symbols
}


- (NSString*) description
{
    return [NSString stringWithFormat: @"%@[%@%@]",self.class,self.rankString,self.suitString];
}


@end
