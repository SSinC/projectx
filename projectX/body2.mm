//
//  body2.m
//  projectX
//
//  Created by Stream on 4/23/13.
//  Copyright (c) 2013 StreamStan. All rights reserved.
//

#import "body2.h"

@implementation body2
-(id)initWithWorld:(b2World *)world at:(CGPoint)p
{
    int32 count = 7;
    NSString *file = @"blocks.png";
    
    //how to define the points???  added by stream.
    b2Vec2 vertices[] = {
        b2Vec2(5.0/PTM_RATIO,15.0/PTM_RATIO),
        b2Vec2(18.0/PTM_RATIO,7.0/PTM_RATIO),
        b2Vec2(32.0/PTM_RATIO,5.0/PTM_RATIO),
        b2Vec2(48.0/PTM_RATIO,7.0/PTM_RATIO),
        b2Vec2(60.0/PTM_RATIO,14.0/PTM_RATIO),
        b2Vec2(34.0/PTM_RATIO,59.0/PTM_RATIO),
        b2Vec2(28.0/PTM_RATIO,59.0/PTM_RATIO)
    };
    

    //    CGSize screen = [[CCDirector sharedDirector] winSize];
    
    //CCLOG(@"screen is %0.2f x %02.f",screen.width/2/PTM_RATIO,screen.height/2/PTM_RATIO);
    
    b2Body *body = [self createBodyForWorld:world position:b2Vec2(p.x/PTM_RATIO,p.y/PTM_RATIO) rotation:0 vertices:vertices vertexCount:count density:5.0 friction:0.2 restitution:0.2];
    
    //CCLOG(@"Creat sprite position is %0.2f x %02.f",body->GetPosition().x,body->GetPosition().y);
    
    if ((self = [super initWithFile:file body:body original:YES]))
    {
    }
    return self;
    
}

@end
