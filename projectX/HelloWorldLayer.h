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

//added to support slice and draw Polygon-body
#import "PolygonSprite.h"
#import "RaycastCallback.h"

#define calculate_determinant_2x2(x1,y1,x2,y2) x1*y2-y1*x2
#define calculate_determinant_2x3(x1,y1,x2,y2,x3,y3) x1*y2+x2*y3+x3*y1-y1*x2-y2*x3-y3*x1

//**
//  some useful macros
//**
#define calculate_determinant_2x2(x1,y1,x2,y2) x1*y2-y1*x2
#define calculate_determinant_2x3(x1,y1,x2,y2,x3,y3) x1*y2+x2*y3+x3*y1-y1*x2-y2*x3-y3*x1
#define frandom (float)arc4random()/UINT64_C(0x100000000)
#define frandom_range(low,high) ((high-low)*frandom)+low
#define random_range(low,high) (arc4random()%(high-low+1))+low
#define midpoint(a,b) (float)(a+b)/2

//**
//  Sprite Tag
//**
#define weaponTag      9999       // weapon tag
#define targetTag      10000      // target tag
#define playerTag      10001      // weapon tag
#define AIWeaponTag    10002      // weapon tag

//**
//  body type
//**
#define createWatermelon 1   // create Watermelon
#define createBody1      2   // create Body1
#define createWeapon     3   // create weapon
#define createTarget     4   // create target

//Pixel to metres ratio. Box2D uses metres as the unit for measurement.
//This ratio defines how many pixels correspond to 1 Box2D "metre"
//Box2D is optimized for objects of 1x1 metre therefore it makes sense
//to define the ratio so that your most common object type is 1x1 metre.
#define PTM_RATIO 32


//typedef struct userdata{
//    int bodyType;
//    CCPhysicsSprite *sprite;
//}myUserData;


typedef enum{
    straight  = 1UL << 0,
    parabolic = 1UL << 1
}attackWay;


typedef enum{
    impactForce     = 1UL << 0,
    attractiveForce = 1UL << 1
}weaponType;



// HelloWorldLayer
@interface HelloWorldLayer : CCLayer <GKAchievementViewControllerDelegate, GKLeaderboardViewControllerDelegate>
{
	CCTexture2D *spriteTexture_;	// weak ref
	b2World* world;					// strong ref
	GLESDebugDraw *m_debugDraw;		// strong ref
    
    CCSprite * background;
    PolygonSprite * selSprite;
    PolygonSprite *selSprite1;
    NSMutableArray * movableSprites;
    contactListener *_contactListener;
    CCSpriteBatchNode *parent;
    CGPoint locationBegin;
    CGSize winSize;
    
    //added copy_chooseBodyNumber to choose body type
    __block int chooseBodyNumber;
    //added cut option used to switch touch-mode
    __block BOOL cutMode;
    
    //add for blooming
    __block BOOL isBloom;
    
    //add-body mode
    __block BOOL addBodyMode;

    ///add simple ai 
    __block BOOL aiMode;
    
    //add explodeing center
    float explosionX;
    float explosionY;
    float explosionRadius ;
    NSMutableDictionary *enterPoints;
    NSMutableArray *explodingBodies;
    
    //add tagBody to create uniqe Body ID
    int32 tagBodyA;
    int32 tagBodyB;
    int32 tagBody1;
    
    //add rayCastCallBack
    RaycastCallback *_raycastCallback;
    
    //add  array to store sprites
    CCArray *catchSprite;
    
    CGPoint _startPoint;
    CGPoint _endPoint;
    
    
    //add physics-effect related parameters
    __block BOOL magnetExist;
    PolygonSprite *magnetSprite;
    __block BOOL airfanExist;
    PolygonSprite *airfanSprite;
    
    //target-hitted flag
    BOOL targetHitted;
    
    /// player-hitted flag
    BOOL playerHitted;
    
    ///add targetWeaponExploded flag
    BOOL weaponToTargetExploded;
    
    ///add weaponExploded flag
    BOOL weaponToPlayerExploded;
    
    //add targetSprite
    PolygonSprite *targetSprite;
    
    //add weaponTest
    PolygonSprite *weaponTest;
    
    //add targetSprite
    PolygonSprite *playerSprite;
    
    //add weaponTest
    PolygonSprite *weaponAI;
    
    //add damageSprite
    CCSprite *targetDamageSprite;
    
    //add playerDamageSprite
    CCSprite *playerDamageSprite;
    
    ////damage-sprite appeared flag
    BOOL targetDamageSpritePresented;
    
    ////damage-sprite appeared flag
    BOOL playerDamageSpritePresented;
    
    //add global_queue -default
    dispatch_queue_t globalQueue ;
    
    //add main_queue
    dispatch_queue_t mainQueue ;
    
    //add critical strike flag
    BOOL criticalStrikeToTarget;
    
    //add critical strike flag
    BOOL criticalStrikeToPlayer;
    
    //add exploded damage
    //float damage;
    
    //add target blood;
    float targetBlood;
    
    //add current target blood;
    float curTargetBlood;
    
    //add target blood;
    float playerBlood;
    
    //add current target blood;
    float curPlayerBlood;
    
    //add bloodNeedUpdate flag
    BOOL targetBloodNeedUpdate;
    BOOL playerBloodNeedUpdate;
    
    ///add damage sprite time step
    int targetDamageStep;
    
    ///add damage sprite time step
    int playerDamageStep;

    
    /// add AI-could-fire flag
    BOOL AICouldFire;
    

    
    //add C++ style Array 
//    std::vector<b2Body*> explodingBodiesCPP_;
//    std::vector<b2Vec2> enterPointsVecCPP_;
//    std::vector<b2Body*> enterPointsVecBodyCPP_;
//    std::vector<b2Body*> slicedBodiesCPP_;
//    
//    std::vector<b2Body*>::iterator pos1_;
//    std::vector<b2Vec2>::iterator pos2_;
//    std::vector<b2Body*>::iterator pos3_;
//    std::vector<b2Body*>::iterator pos4_;
    
}


//@property(nonatomic) std::vector<b2Body*> explodingBodiesCPP;
//@property(nonatomic) std::vector<b2Vec2> enterPointsVecCPP;
//@property(nonatomic) std::vector<b2Body*> ::iterator pos1;
//@property(nonatomic) std::vector<b2Vec2> ::iterator pos2;
// returns a CCScene that contains the HelloWorldLayer as the only child
+(CCScene *) scene;

+(HelloWorldLayer*)shareInstance;


/***********************************************************
 createBody: 此方法创建了活跃的可以和其他body产生碰撞的Box2D body。
 arrangeVertices: 此方法按照逆时针的顺序重排顶点。它使用qsort方法按x坐标升序排列，然后使用determinants来完成最终的重排。
 comparator: 此方法被qsort使用，它完成顶点比较并返回结果给qsort。
 areVerticesAcceptable: 此方法假设所有的顶点都是合理的。
 ********************************************************/
-(b2Vec2*)arrangeVertices:(b2Vec2*)vertices count:(int)count;
-(void)splitPolygonSprite:(PolygonSprite*)sprite;
-(BOOL)areVerticesAcceptable:(b2Vec2*)vertices count:(int)count;
-(b2Body*)createBodyWithPosition:(b2Vec2)position rotation:(float)rotation vertices:(b2Vec2*)vertices vertexCount:(int32)count density:(float)density friction:(float)friction restitution:(float)restitution;

@end
