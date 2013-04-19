//
//  magnet.mm
//  project-x
//
//  Created by WK on 4/5/13.
//  Copyright StreamStan 2013. All rights reserved.
//

#import "magnet.h"


@implementation magnet

-(id)initWithWorld:(b2World *)world 
{
//    int32 count = 4;
    NSString *file = @"watermelon.png";
//    b2Vec2 vertices[] = {
//        b2Vec2(5.0/PTM_RATIO,15.0/PTM_RATIO),
//        b2Vec2(18.0/PTM_RATIO,7.0/PTM_RATIO),
//        b2Vec2(32.0/PTM_RATIO,5.0/PTM_RATIO),
//        b2Vec2(48.0/PTM_RATIO,7.0/PTM_RATIO),
//        b2Vec2(60.0/PTM_RATIO,14.0/PTM_RATIO),
//        b2Vec2(34.0/PTM_RATIO,59.0/PTM_RATIO),
//        b2Vec2(28.0/PTM_RATIO,59.0/PTM_RATIO)
//    };
    CGSize screen = [[CCDirector sharedDirector] winSize];
    
        
    
    //set the magnet in the center of the screen
    //Since that i want the manget to be a Globular-body,i have to create a new method
    // createGlobularBodyForWorld  --- this method is to be examined.
    //*****************WK
    b2Body *body = [self createGlobularBodyForWorld:world position:b2Vec2(screen.width/PTM_RATIO,screen.height/PTM_RATIO) rotation:0 radius:5.0 density:5.0 friction:0.2 restitution:0.2];
    
    
    CCSpriteBatchNode *parentNode = [CCSpriteBatchNode batchNodeWithFile:@"blocks.png" capacity:100];
    CCTexture2D *texture_ = [parentNode texture];
    
    
    //**************** Given that i wanna use the specific texture_ ,
    //i have to use "initWithTexture:(CCTexture2D*)texture body:(b2Body*)body original:(BOOL)original"
    // instead of "initWithFile:file body:body original:YES"
    //             *****************WK
    
//    if ((self = [super initWithFile:file body:body original:YES]))
//    {
//    }
    if ((self = [super  initWithTexture:texture_ body:body original:YES]))
    {
    }
    
    
    return self;
    
}

@end
