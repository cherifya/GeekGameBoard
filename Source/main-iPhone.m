//
//  main.m
//  GGB-iPhone
//
//  Created by Jens Alfke on 3/7/08.
//  Copyright __MyCompanyName__ 2008. All rights reserved.
//

#import <UIKit/UIKit.h>

int main(int argc, char *argv[])
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    int retVal = UIApplicationMain(argc, argv, nil, @"GGB_iPhoneAppDelegate");
    [pool release];
    return retVal;
}
