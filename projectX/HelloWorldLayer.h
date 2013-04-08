//
//  HelloWorldLayer.h
//  project-x
//
//  Created by Stream on 4/5/13.
//  Copyright StreamStan 2013. All rights reserved.
//


#import <GameKit/GameKit.h>

// When you import this file, you import all the cocos2d classes
#import "cocos2d.h"
#import "Box2D.h"
#import "GLES-Render.h"
#import "CCPhysicsSprite.h"
#import "contactListener.h"

//Pixel to metres ratio. Box2D uses metres as the unit for measurement.
//This ratio defines how many pixels correspond to 1 Box2D "metre"
//Box2D is optimized for objects of 1x1 metre therefore it makes sense
//to define the ratio so that your most common object type is 1x1 metre.
#define PTM_RATIO 32

//添加userData 结合贴图和物体编号，方便使用
typedef struct userdata{
    int bodyType;
    CCPhysicsSprite *sprite;
}myUserData;

// HelloWorldLayer
@interface HelloWorldLayer : CCLayer <GKAchievementViewControllerDelegate, GKLeaderboardViewControllerDelegate>
{
	CCTexture2D *spriteTexture_;	// weak ref
	b2World* world;					// strong ref
	GLESDebugDraw *m_debugDraw;		// strong ref
    
    CCSprite * background;
    CCPhysicsSprite * selSprite;
    NSMutableArray * movableSprites;
    contactListener *_contactListener;
    CCSpriteBatchNode *parent;
    CGPoint locationBegin;
    __block int copy_chooseBodyNumber;
    float explosionX;
    float explosionY;
    float explosionRadius ;
    NSMutableDictionary *enterPoints;
    NSMutableArray *explodingBodies;
    int32 tagBodyA;
    int32 tagBodyB;
    
}

// returns a CCScene that contains the HelloWorldLayer as the only child
+(CCScene *) scene;

@end
