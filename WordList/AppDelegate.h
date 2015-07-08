//
//  AppDelegate.h
//  WordList
//
//  Created by Alexander Doloz on 7/8/15.
//  Copyright (c) 2015 -. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Persistence;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) Persistence *persistence;

@end

