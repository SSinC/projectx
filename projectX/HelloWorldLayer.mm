//
//  HelloWorldLayer.mm
//  project-x
//
//  Created by Stream on 4/5/13.
//  Copyright StreamStan 2013. All rights reserved.
//

// Import the interfaces
#import "HelloWorldLayer.h"

// Not included in "cocos2d.h"
//#import "CCPhysicsSprite.h"

// Needed to obtain the Navigation Controller
#import "AppDelegate.h"
#import <math.h>

#import "watermelon.h"
//#import "body2.h"
#import "magnet.h"
#import "weapon.h"
#import "target.h"
#import "Box2DUtils.h"

enum {
	kTagParentNode = 1,
};

#define pi 3.14159265358979323846
#define ARC4RANDOM_MAX      0x100000000
#define G 9.8

#pragma mark - HelloWorldLayer

@interface HelloWorldLayer()
-(void) initPhysics;
-(void) addNewSpriteAtPosition:(CGPoint)p;
-(void) createMenu;
//-(void) createBody1;
//-(void) createBody2;
//-(void) createBody3;
//-(void) splitObj:(b2Body*)sliceBody A:(b2Vec2)A B:(b2Vec2)B;
//-(float)  det:(NSInteger)x1  y1:(NSInteger)y1 x2:(NSInteger)x2 y2:(NSInteger)y2 x3:(NSInteger)x3  y3:(NSInteger)y3;
//-(b2Vec2 *)  setExplosionVelocity:(b2Body *)b;

@end


int comparator(const void *a, const void *b) {
    const b2Vec2 *va = (const b2Vec2 *)a;
    const b2Vec2 *vb = (const b2Vec2 *)b;
    
    if (va->x > vb->x) {
        return 1;
    } else if (va->x < vb->x) {
        return -1;
    }
    return 0;
}


HelloWorldLayer* instance;
@implementation HelloWorldLayer
//@synthesize enterPointsVecCPP = enterPointsVecCPP_;
//@synthesize explodingBodiesCPP = explodingBodiesCPP_;
//@synthesize pos1 = pos1_;
//@synthesize pos2 = pos2_;



+(HelloWorldLayer*)shareInstance
{
    if(!instance)
		instance = [[HelloWorldLayer alloc] init];
	return instance;
}


+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	HelloWorldLayer *layer = [HelloWorldLayer node];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	// return the scene
	return scene;
}

-(id) init
{
	if( (self=[super init])) {
        CCLOG(@"init");
		
		// enable events
        self.touchEnabled         = YES;
		self.accelerometerEnabled = YES;
        
        tagBodyA              = 1;
        tagBodyB              = 500;
        tagBody1              = 1000;
        chooseBodyNumber      = 0;
        
        cutMode               = false;
        addBodyMode           = true;
        aiMode                = false;
        
        isBloom               = false;
        
        targetDamageStep       = 1;
        playerDamageStep       = 1;
        targetHitted           = false;
        playerHitted           = false;
        criticalStrikeToTarget = false;
        criticalStrikeToPlayer = false;
        
        targetBlood     = 500;
        curTargetBlood  = 500;
        playerBlood     = 500;
        curPlayerBlood  = 500;
 
        AICouldFire             = false;
        
        weaponToTargetExploded  = false;
        weaponToPlayerExploded  = false;
        targetBloodNeedUpdate   = false;
        playerBloodNeedUpdate   = false;
       
        
        globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        mainQueue   = dispatch_get_main_queue();
        
		CGSize winSize = [CCDirector sharedDirector].winSize;
		
		// init physics
		[self initPhysics];
		
		// create reset button
		[self createMenu];
		
        movableSprites = [[NSMutableArray alloc] init];
        catchSprite = [[CCArray alloc] initWithCapacity:53];
        
		//Set up sprite
		
#if 1
		// Use batch node. Faster
		CCSpriteBatchNode *parentNode = [CCSpriteBatchNode batchNodeWithFile:@"blocks.png" capacity:100];
		spriteTexture_ = [parentNode texture];
#else
		// doesn't use batch node. Slower
		spriteTexture_ = [[CCTextureCache sharedTextureCache] addImage:@"blocks.png"];
		CCNode *parent = [CCNode node];
#endif
		
		CCLOG(@"parent %@",parent);
        
        //[self addChild:parent z:0 tag:kTagParentNode];
		[self addChild:parentNode z:0 tag:kTagParentNode];
        
        
		
        //		[self addNewSpriteAtPosition:ccp(s.width/2, s.height/2+200)];
        
		
		CCLabelTTF *label = [CCLabelTTF labelWithString:@"Tap screen" fontName:@"Marker Felt" fontSize:32];
		[self addChild:label z:0];
		[label setColor:ccc3(0,0,255)];
		label.position = ccp( winSize.width/2, winSize.height-50);
        
        //add contactListener
        _contactListener = new contactListener();
        world->SetContactListener(_contactListener);
        
        //add rayCastCallBack
        _raycastCallback = new RaycastCallback();
        
        //Loop-update
		[self scheduleUpdate];
	}
	return self;
}

-(void) dealloc
{
	delete world;
	world = NULL;
	
	delete m_debugDraw;
	m_debugDraw = NULL;
    
    [movableSprites release];
    movableSprites = nil;
    
    [catchSprite release];
    catchSprite = nil;
	
	[super dealloc];
}

-(void) createMenu
{
	// Default font size will be 22 points.
	[CCMenuItemFont setFontSize:22];
	
	// Reset Button
	CCMenuItemLabel *reset = [CCMenuItemFont itemWithString:@"Reset" block:^(id sender){
		[[CCDirector sharedDirector] replaceScene: [HelloWorldLayer scene]];
	}];
    
    
    CGSize size = [[CCDirector sharedDirector] winSize];
    
    
	// to avoid a retain-cycle with the menuitem and blocks
	__block id copy_self = self;
    
	// Achievement Menu Item using blocks
	CCMenuItem *itemAchievement = [CCMenuItemFont itemWithString:@"Achievements" block:^(id sender) {
		
		
		GKAchievementViewController *achivementViewController = [[GKAchievementViewController alloc] init];
		achivementViewController.achievementDelegate = copy_self;
		
		AppController *app = (AppController*) [[UIApplication sharedApplication] delegate];
		
		[[app navController] presentModalViewController:achivementViewController animated:YES];
		
		[achivementViewController release];
	}];
	
	// Leaderboard Menu Item using blocks
	CCMenuItem *itemLeaderboard = [CCMenuItemFont itemWithString:@"Leaderboard" block:^(id sender) {
		
		
		GKLeaderboardViewController *leaderboardViewController = [[GKLeaderboardViewController alloc] init];
		leaderboardViewController.leaderboardDelegate = copy_self;
		
		AppController *app = (AppController*) [[UIApplication sharedApplication] delegate];
		
		[[app navController] presentModalViewController:leaderboardViewController animated:YES];
		
		[leaderboardViewController release];
	}];
	
	CCMenu *menu = [CCMenu menuWithItems:itemAchievement, itemLeaderboard, reset, nil];
	
	[menu alignItemsVertically];
	
    [menu setPosition:ccp( size.width/2, size.height/2)];
    //z代表图像层次
    [self addChild: menu z:-1];
    
    //__block int copy_chooseBodyNumber = chooseBodyNumber;
    CCMenuItem *chooseBody1 = [CCMenuItemFont itemWithString:@"Watermelon" block:^(id sender){
        chooseBodyNumber = createWatermelon;
        
    }];
    
    CCMenuItem *chooseBody2 = [CCMenuItemFont itemWithString:@"Block" block:^(id sender){
        chooseBodyNumber = createBody1;
        
    }];
    
    CCMenuItem *chooseBody3 = [CCMenuItemFont itemWithString:@"Weapon" block:^(id sender){
        chooseBodyNumber = createWeapon;
        
    }];
    
    CCMenuItem *chooseBody4 = [CCMenuItemFont itemWithString:@"target" block:^(id sender){
        chooseBodyNumber = createTarget;
        
    }];
    
    CCMenuItem *chooseBody5 = [CCMenuItemFont itemWithString:@"airfan" block:^(id sender){
        airfanExist = airfanExist ? false : true;
        
    }];
    
    CCMenuItem *add = [CCMenuItemFont itemWithString:@"add-body Mode   " block:^(id sender){
        // Switch the mode to Cut-Mode
        addBodyMode = true;
    }];
    
    CCMenuItem *cut = [CCMenuItemFont itemWithString:@"CutCut  " block:^(id sender){
        // Switch the mode to Cut-Mode
        cutMode = true;
    }];
    
    CCMenuItem *notCut = [CCMenuItemFont itemWithString:@"shoot" block:^(id sender){
        // Switch the mode back to Drag-Shoot mode
        cutMode = false;
    }];
    
    CCMenuItem *bloomSplit = [CCMenuItemFont itemWithString:@"explode" block:^(id sender){
        // explode the last created-body 
        [self goBloom];
    }];
    
    CCMenuItem *createMagnet = [CCMenuItemFont itemWithString:@"maganet" block:^(id sender){
        if(!magnetExist)
        {
            [self createMagnet];
            magnetExist = true;
        }else{
            [self destroyMagnet];
            magnetExist = false;
        }
    }];
	
    CCMenuItem *AI = [CCMenuItemFont itemWithString:@"AI" block:^(id sender){
       aiMode = aiMode ? ! false :true;
    }];

    CCMenu *menuChooseBody1 = [CCMenu menuWithItems:chooseBody1, chooseBody2, chooseBody3,chooseBody4,chooseBody5,  nil];
	
	[menuChooseBody1 alignItemsHorizontally];
	
    [menuChooseBody1 setPosition:ccp( size.width/6, size.height/2+150)];
    
    [self addChild: menuChooseBody1 z:-1];
    
    CCMenu *menuChooseBody2 = [CCMenu menuWithItems:add,cut, notCut, bloomSplit, createMagnet, AI, nil];
	
	[menuChooseBody2 alignItemsHorizontally];
	
    [menuChooseBody2 setPosition:ccp( size.width/6+150, size.height/2+350)];
    
    [self addChild: menuChooseBody2 z:-1];
    
}

-(void) initPhysics
{
	
	CGSize s = [[CCDirector sharedDirector] winSize];
	
	b2Vec2 gravity;
	gravity.Set(0.0f, -10.0f);
	world = new b2World(gravity);
	
	
	// Do we want to let bodies sleep?
	world->SetAllowSleeping(true);
	
	world->SetContinuousPhysics(true);
	
	m_debugDraw = new GLESDebugDraw( PTM_RATIO );
	world->SetDebugDraw(m_debugDraw);
	
	uint32 flags = 0;
	flags += b2Draw::e_shapeBit;
	//		flags += b2Draw::e_jointBit;
	//		flags += b2Draw::e_aabbBit;
	//		flags += b2Draw::e_pairBit;
	//		flags += b2Draw::e_centerOfMassBit;
	m_debugDraw->SetFlags(flags);
	
	
	// Define the ground body.
	b2BodyDef groundBodyDef;
	groundBodyDef.position.Set(0, 0); // bottom-left corner
	
	// Call the body factory which allocates memory for the ground body
	// from a pool and creates the ground box shape (also from a pool).
	// The body is also added to the world.
	b2Body* groundBody = world->CreateBody(&groundBodyDef);
	
	// Define the ground box shape.
	b2EdgeShape groundBox;
	//groundBox.= 0.7f;
	
	// bottom
	
	groundBox.Set(b2Vec2(0,0), b2Vec2(s.width/PTM_RATIO,0));
	groundBody->CreateFixture(&groundBox,1.5f);
	
	// top
	groundBox.Set(b2Vec2(0,s.height/PTM_RATIO), b2Vec2(s.width/PTM_RATIO,s.height/PTM_RATIO));
	groundBody->CreateFixture(&groundBox,1.5f);
	
	// left
	groundBox.Set(b2Vec2(0,s.height/PTM_RATIO), b2Vec2(0,0));
	groundBody->CreateFixture(&groundBox,1.5f);
	
	// right
	groundBox.Set(b2Vec2(s.width/PTM_RATIO,s.height/PTM_RATIO), b2Vec2(s.width/PTM_RATIO,0));
	groundBody->CreateFixture(&groundBox,1.5f);
    
    b2BodyDef bodyDef;
	bodyDef.type = b2_staticBody;
	bodyDef.position.Set(s.width/2, s.height/2+10);
	b2Body *body = world->CreateBody(&bodyDef);
	
	// Define another box shape for our dynamic body.
	b2PolygonShape dynamicBox;
	dynamicBox.SetAsBox(1.5f, 1.5f);//These are mid points for our 1m box
	
	// Define the dynamic body fixture.
	b2FixtureDef fixtureDef;
	fixtureDef.shape = &dynamicBox;
	fixtureDef.density = 1.5f;
	fixtureDef.friction = 0.7f;
	body->CreateFixture(&fixtureDef);
}



-(void)goBloom
{
    //bloom the sprint
    isBloom = true;
    
    NSInteger count = [movableSprites count];
//    if(count > 0)
//    {
//        PolygonSprite *sprite = [movableSprites objectAtIndex:count-1];
//        //get the center of the sprite
//        const b2Vec2& spriteCenter = sprite.body->GetWorldCenter();
//        
//        //create the radom bloom point of the sprite, from 2 to 12;
//        NSInteger radomNum = arc4random() % 10 + 2;
//        CCLOG(@"body valx is %d ", radomNum);
//        for(int i = 0; i < radomNum; i++)
//        {
//            //create the radom point for the cast ray. from -50.0 to 50.0
//            double valx = floorf(((double)arc4random() / ARC4RANDOM_MAX)); // * 10.0f);
//            double valy = floorf(((double)arc4random() / ARC4RANDOM_MAX)); // * 10.0f);
//            
//            
//            
//            CCLOG(@"body valx is %0.2f ", valx);
//            CCLOG(@"body valy is %0.2f ", valy);
//            
//            double valx2 = floorf(((double)arc4random() / ARC4RANDOM_MAX)); //* 10.0f);
//            double valy2 = floorf(((double)arc4random() / ARC4RANDOM_MAX)); // * 10.0f);
//            CCLOG(@"body valx is %0.2f ", valx2);
//            CCLOG(@"body valy is %0.2f ", valy2);
//            //            b2Vec2 startPoint = b2Vec2((spriteCenter.x - valx)/PTM_RATIO, (spriteCenter.y - valy)/PTM_RATIO);
//            //            b2Vec2 endPoint = b2Vec2((spriteCenter.x + valx2)/PTM_RATIO, (spriteCenter.y - valy2)/PTM_RATIO);
//            
//            b2Vec2 startPoint = b2Vec2((_startPoint.x - valx), (_startPoint.y - valy));
//            b2Vec2 endPoint = b2Vec2((_endPoint.x + valx2), (_endPoint.y - valy2));
//            CCLOG(@"body start is %0.2f , %0.2f ", startPoint.x, startPoint.y);
//            CCLOG(@"body start is %0.2f , %0.2f ", endPoint.x, endPoint.y);
//            //            b2Vec2 endPoint = b2Vec2((spriteCenter.x + valx)/PTM_RATIO, (spriteCenter.y + valy)/PTM_RATIO);
//            //
//            world->RayCast(_raycastCallback,
//                           startPoint,
//                           endPoint);
//            
//            world->RayCast(_raycastCallback,
//                           endPoint,
//                           startPoint);
//
//        }//end the for
//        
//    }
}


-(void) draw
{
	//
	// IMPORTANT:
	// This is only for debug purposes
	// It is recommend to disable it
	//
	[super draw];
	
	ccGLEnableVertexAttribs( kCCVertexAttribFlag_Position );
	
	kmGLPushMatrix();
	
    if(cutMode)
    {
        ccDrawLine(_startPoint, _endPoint);
    }
    
	world->DrawDebugData();
	
	kmGLPopMatrix();
}

-(void) createBodyWatermelon:(CGPoint)p
{
    // CCLOG(@"Test before create sprite");
    CCLOG(@"Add sprite position %0.2f x %02.f",p.x,p.y);
    
    PolygonSprite *sprite = [[watermelon alloc] initWithWorld:world at:p ];
        
    //************* We can not use the following methods to add sprite to parentSprite
    //    	CCNode *parentSprite = [self getChildByTag:kTagParentNode];
    //        [parentSprite addChild:sprite];
    
    [self addChild:sprite z:1];
    [sprite activateCollisions];
    [catchSprite addObject:sprite];
    
    sprite.tag = tagBody1++;
    
    //[sprite setPosition: ccp( p.x, p.y)];
    [movableSprites addObject:sprite];
    
    CCLOG(@"body worldCenter is %0.2f x %02.f", sprite.body->GetWorldCenter().x, sprite.body->GetWorldCenter().y);
    CCLOG(@"body localCenter is %0.2f x %02.f", sprite.body->GetLocalCenter().x, sprite.body->GetLocalCenter().y);
    //CCLOG(@"sprite position is %0.2f x %02.f",sprite.body->GetPosition().x,sprite.body->GetPosition().y);
}


-(void) CreateWeapon
{
    //first we should create an invisible holder to hold the weapon 
    [self CreateWeaponHolder];
    
    CGPoint p  = ccp(winSize.width-200,winSize.height/3);    
    CCLOG(@"Add weapon position %0.2f x %02.f",p.x,p.y);
    
    PolygonSprite *sprite = [[weapon alloc] initWithWorld:world at:p ];
        
    [self addChild:sprite z:1];
    
    [sprite activateCollisions];
    
    sprite.tag = weaponTag;
    
    [movableSprites addObject:sprite];
    [catchSprite addObject:sprite];
}


-(void) CreateTarget
{
    CGPoint p  = ccp(winSize.width/5,winSize.height/3);    
    CCLOG(@"Add target position %0.2f x %02.f",p.x,p.y);
    
    PolygonSprite *sprite = [[target alloc] initWithWorld:world at:p ];
    
    [self addChild:sprite z:1];
    
    [sprite activateCollisions];
    
    sprite.tag = targetTag;
    
    [movableSprites addObject:sprite];
    [catchSprite addObject:sprite];
}


-(void) CreateWeaponHolder
{
    dispatch_sync(globalQueue, ^{
        //	b2BodyDef bodyDef;
        //	bodyDef.type = b2_dynamicBody;
        //	bodyDef.position.Set(p.x/PTM_RATIO, p.y/PTM_RATIO);
        //	b2Body *body = world->CreateBody(&bodyDef);
        //
        //	// Define another box shape for our dynamic body.
        //	b2PolygonShape dynamicBox;
        //	dynamicBox.SetAsBox(.5f, .5f);//These are mid points for our 1m box
        //
        //	// Define the dynamic body fixture.
        //	b2FixtureDef fixtureDef;
        //	fixtureDef.shape = &dynamicBox;
        //	fixtureDef.density = 1.5f;
        //	fixtureDef.friction = 0.7f;
        //    fixtureDef.restitution = 0.7f;
        //	body->CreateFixture(&fixtureDef);

    });
}

//-(void) createBody1:(CGPoint)p
//{
//    CCLOG(@"Add sprite %0.2f x %02.f",p.x,p.y);
//	// Define the dynamic body.
//	//Set up a 1m squared box in the physics world
//	b2BodyDef bodyDef;
//	bodyDef.type = b2_dynamicBody;
//	bodyDef.position.Set(p.x/PTM_RATIO, p.y/PTM_RATIO);
//	b2Body *body = world->CreateBody(&bodyDef);
//	
//	// Define another box shape for our dynamic body.
//	b2PolygonShape dynamicBox;
//	dynamicBox.SetAsBox(.5f, .5f);//These are mid points for our 1m box
//	
//	// Define the dynamic body fixture.
//	b2FixtureDef fixtureDef;
//	fixtureDef.shape = &dynamicBox;
//	fixtureDef.density = 1.5f;
//	fixtureDef.friction = 0.7f;
//    fixtureDef.restitution = 0.7f;
//	body->CreateFixture(&fixtureDef);
//	
//    
////	CCNode *parentSprite = [self getChildByTag:kTagParentNode];
//	
//	//We have a 64x64 sprite sheet with 4 different 32x32 images.  The following code is
//	//just randomly picking one of the images
//	//int idx = (CCRANDOM_0_1() > .5 ? 0:1);
//	//int idy = (CCRANDOM_0_1() > .5 ? 0:1);
//    
//	//CCPhysicsSprite *sprite = [CCPhysicsSprite spriteWithTexture:spriteTexture_ rect:CGRectMake(0,0,32,32)];
//    CCLOG(@"before create sprite");
//    PolygonSprite *sprite = [PolygonSprite spriteWithTexture: spriteTexture_ body:body original:NO];
//    CCLOG(@"after create sprite");
//    //添加tag用来给碰撞检测时判断物体类型
//    //暂时用tag的值的范围代表物体类型
//    //1-500之内是BodyA
//    sprite.tag = tagBodyA++;
//    [self addChild:sprite z:1];
//	//[parentSprite addChild:sprite];
//    CCLOG(@"after create sprite1");
//	//[sprite setPTMRatio:PTM_RATIO];
//	//[sprite setB2Body:body];
//	//[sprite setPosition: ccp( p.x, p.y)];
//    
//    //暂时注释掉setUserData中存入结构体
//    //    myUserData *data1 ;
//    //    data1->bodyType = 1;
//    //    data1->sprite = sprite;
//    //    body->SetUserData(data1);
//    
//    body->SetUserData(sprite);
//    [movableSprites addObject:sprite];
//    CCLOG(@"after create sprite1");
//}

-(void) createBody2:(CGPoint)p
{

    CCLOG(@"Add sprite position %0.2f x %02.f",p.x,p.y);    
    catchSprite = [[CCArray alloc] initWithCapacity:53];
    b2BodyDef bodyDef;
    bodyDef.type = b2_dynamicBody; //类型
    bodyDef.position = b2Vec2(p.x/PTM_RATIO,p.y/PTM_RATIO); //位置
    bodyDef.angle = 0; //旋转角度
    b2Body *body = world->CreateBody(&bodyDef);
    
    b2FixtureDef fixtureDef;
	fixtureDef.density = 1.5f;//密度
	fixtureDef.friction = 0.7f;//摩擦系数
    fixtureDef.restitution = 0.7f;//反弹系数

    fixtureDef.filter.categoryBits = 0;  //categoryBits用于定义自己所属的碰撞种类，maskBits则是指定碰撞种类
    fixtureDef.filter.maskBits = 0;
    //fixtureDef.isSensor = YES;
    
    b2PolygonShape shape;
    shape.SetAsBox(1.0f, 1.0f);
//     shape.SetAsBox(1.5f, 1.5f);
//    shape.Set(vertices, count);
    fixtureDef.shape = &shape;
    body->CreateFixture(&fixtureDef);
    NSString *file = @"blocks.png"; 
    PolygonSprite *sprite = [[[PolygonSprite alloc] initWithFile:file body:body original:YES] autorelease];
    
    
    [self addChild:sprite z:1];
    [sprite activateCollisions];
    [catchSprite addObject:sprite];
    
    sprite.tag = tagBodyB++;
    
    //[sprite setPosition: ccp( p.x, p.y)];
    [movableSprites addObject:sprite];
    
    CCLOG(@"body worldCenter is %0.2f x %02.f", sprite.body->GetWorldCenter().x, sprite.body->GetWorldCenter().y);
    CCLOG(@"body localCenter is %0.2f x %02.f", sprite.body->GetLocalCenter().x, sprite.body->GetLocalCenter().y);
}

-(void) createBody3:(CGPoint)p
{
    
}


-(void) createMagnet
{
    magnetSprite = [[magnet alloc] initWithWorld:world  ];
    
    [self addChild:magnetSprite z:1];
    
    [magnetSprite activateCollisions];
        
    magnetSprite.tag = 5000;
  
}

-(void) destroyMagnet
{
    world->DestroyBody(magnetSprite.body);
    [self removeChild:magnetSprite cleanup:YES];
}


-(void) addNewSpriteAtPosition:(CGPoint)p
{
	if(!selSprite)
    {
        CCLOG(@"chooseBodyNumber %i",chooseBodyNumber);
        switch (chooseBodyNumber)
        {
            case 1:
                //[self createBody1:p];  replace the globalQueue by "dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)"
                //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self createBodyWatermelon:p];
                });
                break;
            case 2:
                //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                 dispatch_async(dispatch_get_main_queue(), ^{
                   [self createBody2:p];
                });
                //[self createBodyTest:p];
                break;
            case 3:
                [self createBody3:p];                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                
                break;
                
            default:
                break;
        }
    }
    selSprite = nil;
}

//**
//  ************------------------ Main Loop  -------------------************
//**
-(void) update: (ccTime) dt
{
	//It is recommended that a fixed time step is used with Box2D for stability
	//of the simulation, however, we are using a variable time step here.
	//You need to make an informed choice, the following URL is useful
	//http://gafferongames.com/game-physics/fix-your-timestep/
	
	int32 velocityIterations = 8;
	int32 positionIterations = 1;
	
	// Instruct the world to perform a single step of simulation. It is
	// generally best to keep the time step and iterations fixed.
	world->Step(dt, velocityIterations, positionIterations);
    // Updates the physics simulation for 10 iterations for velocity/position
    
    
    
    //**
    //If the cut-mode is on,we need to examine all the bodyA to
    // find out if they should be spliced
    if(cutMode)
    {
        [self checkAndSliceObjects];
    }
    
    [self handleContact];
    
//  [self physicsEffect];
    
    [self animation];
    
    [self updateBloodStatus];

//  [self simpleAI：Time];
    
    world->ClearForces();
    
}


//**
//  ************************    Handle contact    ************************
//**
-(void)handleContact
{
//    globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    dispatch_async(globalQueue, ^{
//        __block CCNode *parent1 = [self getChildByTag:kTagParentNode];
        
        @autoreleasepool {
            
            __block std::vector<b2Body *>toDestroy;
            __block std::vector<MyContact>::iterator pos;
            __block std::vector<b2Body *>::iterator pos2;
            
            //*******************  handle contact  ***********************
            for(pos = _contactListener->_contacts.begin(); pos != _contactListener->_contacts.end(); ++pos)
            {
                MyContact contact = *pos;
                
                // Get the box2d bodies for each object
                b2Body *bodyA = contact.fixtureA->GetBody();
                b2Body *bodyB = contact.fixtureB->GetBody();
                
                if (bodyA->GetUserData() != NULL && bodyB->GetUserData() != NULL)
                {
                    if(([(id)bodyA->GetUserData() isKindOfClass:[PolygonSprite class]]) &&([(id)bodyB->GetUserData() isKindOfClass:[PolygonSprite class]]))
                    {
                        PolygonSprite *spriteA = (PolygonSprite *) bodyA->GetUserData();
                        PolygonSprite *spriteB = (PolygonSprite *) bodyB->GetUserData();
                        
                        //we can destroy the specific body we want.
                        //Now i destroy the contacted watermelon for just testing
                        if (((spriteA.tag >= 1000 && spriteB.tag >= 1000)|| (spriteA.tag >= 1000 && spriteB.tag >= 1000)))
                        {
                            //[parent1 removeChild:spriteA];
                            //[parent1 removeChild:spriteB];
                            toDestroy.push_back(bodyA);
                            toDestroy.push_back(bodyB);
                        }
                        
                        //We can determine if the weapon is contacting the target
                        if((spriteA.tag == weaponTag && spriteB.tag == targetTag) || (spriteB.tag == weaponTag && spriteA.tag == targetTag))
                        {
                            targetHitted = true;
                        }
                        
                        //Detect if the player is being hitted by AI-weapon
                        if((spriteA.tag == playerTag && spriteB.tag == AIWeaponTag) || (spriteB.tag == AIWeaponTag && spriteA.tag == playerTag))
                        {
                            playerHitted = true;
                        }
                    }
                }
            } // end of for
            
            //***************   Use contacted-information to update graphic  ****************
            dispatch_async(mainQueue, ^{
                // Loop through all of the box2d bodies we wnat to destroy...
                
                for(pos2 = toDestroy.begin(); pos2 != toDestroy.end(); ++pos2)
                {
                    
                    b2Body *body = *pos2;
                    
                    // See if there's any user data attached to the Box2D body
                    // There should be, since we set it in addBoxBodyForSprite
                    if (body->GetUserData() != NULL)
                    {
                        
                        // We know that the user data is a sprite since we set
                        // it that way, so cast it...
                        PolygonSprite *sprite = (PolygonSprite *) body->GetUserData();
                        
                        // Remove the sprite from the scene
                        [self removeChild:sprite];
                    }
                    
                    // Destroy the Box2D body as well
                    world->DestroyBody(body);//
                }
            });
        }// end of @autoreleasepool
    });
}

                   
//**
//  ************************    Physics-Effect    ************************
//**
-(void)physicsEffect
{
    //**********************  magnet-effect  *********************
    if (magnetExist)
    {
        dispatch_async ( globalQueue, ^{
            @autoreleasepool{
                
                float weaponX = weaponTest.body->GetWorldCenter().x * PTM_RATIO;
                float weaponY = weaponTest.body->GetWorldCenter().y * PTM_RATIO;
                float diffX   = winSize.width  - weaponX;
                float diffY   = winSize.height - weaponY;
                float criticalDistance = 50.0;
                
                if(sqrt(pow(diffX,2)+pow(diffY,2))< criticalDistance)
                {
                    float forceX = (diffX < 0 ? -1:1)* abs(diffX) / sqrt(pow(diffX,2)+pow(diffY,2)) ;
                    float forceY = (diffY < 0 ? -1:1)* abs(diffY) / sqrt(pow(diffX,2)+pow(diffY,2)) ;
                    b2Vec2 force = * new b2Vec2(forceX,forceY);
                    
                    weaponTest.body->ApplyLinearImpulse(force, weaponTest.body->GetWorldCenter());
                }
            }// end of @autoreleasepool
        });
    }
    
    //**********************  airfan-effect  *********************
    if (airfanExist)
    {
        dispatch_async ( globalQueue, ^{
            
            @autoreleasepool{
                
                float weaponX = weaponTest.body->GetWorldCenter().x   * PTM_RATIO;
                float weaponY = weaponTest.body->GetWorldCenter().y   * PTM_RATIO;
                float airfanX = airfanSprite.body->GetWorldCenter().x * PTM_RATIO;
                float airfanY = airfanSprite.body->GetWorldCenter().y * PTM_RATIO;
                float criticalMin = airfanY - 100;
                float criticalMax = airfanY + 100;
                float diffX       = weaponX - airfanX;
                float diffY       = weaponY - airfanY;
                float MAXforceX   = 300; //The max force
                
                if((criticalMin < weaponY < criticalMax) && (diffX < 300) )
                {
                    float forceX = MAXforceX / sqrt(pow(diffX,2)+pow(diffY,2)) ;
                    float forceY = 0 ;
                    b2Vec2 force = * new b2Vec2(forceX,forceY);
                    
                    weaponTest.body->ApplyLinearImpulse(force, weaponTest.body->GetWorldCenter());
                }
            }// end of @autoreleasepool
        });
    }
    
    //**********************  shock wave effect  *********************
    if (targetHitted)
    {
        targetHitted = false;
        
        dispatch_async(globalQueue, ^{
            
            @autoreleasepool{
                
                float weaponX       = weaponTest.body->GetWorldCenter().x   * PTM_RATIO;
                float weaponY       = weaponTest.body->GetWorldCenter().y   * PTM_RATIO;
                float targetSpriteX = targetSprite.body->GetWorldCenter().x * PTM_RATIO;
                float targetSpriteY = targetSprite.body->GetWorldCenter().y * PTM_RATIO;
                float diffX         = weaponX - targetSpriteX;
                float diffY         = weaponY - targetSpriteY;
                
                //************   Here is how the forceX and forceY are generated:
                //       Fx / Fy             = diffX / diffY
                //       distance            = sqrt( pow (diffX, 2) + pow (diffY, 2))
                //       F (proportional to) = pow( ratio / distance, 2)
                //       pow( F, 2 )         = pow(Fx,2)+pow(Fy,2)
                //
                //==>    Fx  = pow(ratio,2) * diffX / sqrt( pow( ( pow(diffX,2) + pow(diffY,2) ),3) )
                //==>    Fy  = pow(ratio,2) * diffY / sqrt( pow( ( pow(diffX,2) + pow(diffY,2) ),3) )
                
                
                //The ratio must be chosen very carefully.
                //Here i use a random ratio so critical strike would happen sometimes
                float ratio = frandom_range(100,400);
                
                float forceX = pow(ratio,2) * diffX / sqrt (pow ((pow(diffX,2) + pow(diffY,2)),3));
                float forceY = pow(ratio,2) * diffY / sqrt (pow ((pow(diffX,2) + pow(diffY,2)),3));
                b2Vec2 force = * new b2Vec2(forceX,forceY);
                
                //target should be blown away by the shockWave
                targetSprite.body->ApplyLinearImpulse(force, targetSprite.body->GetWorldCenter());
                
                //Now the weapon is exploded
                weaponToTargetExploded = true;
                
                //**
                //  ***************  handle damage   *******************
                //**
                float damage = sqrt((pow(force.x,2) + pow(force.y,2)));
                CCLOG(@"damage is %f",damage);
                // if the damage is bigger than a certain number,we consider the strike as a critical strike
                // and the damage-sprite should be bigger than usual
                if(damage >= 500)
                {
                    criticalStrikeToTarget = true;
                }
                curTargetBlood = targetBlood - damage;
                
                
                //We neet to generate a damage sprite based on the damage.
                //For now, i just use a png to test anyway.
                dispatch_async(mainQueue, ^{
                    
                    if(!criticalStrikeToTarget)
                    {
                        targetDamageSprite = [CCSprite spriteWithFile:@"blocks.png" rect:CGRectMake(32,32,32,32)];
                    }
                    else
                    {
                        targetDamageSprite = [CCSprite spriteWithFile:@"blocks.png" rect:CGRectMake(32,32,32,32)];
                        
                    }
                    [self addChild:targetDamageSprite];
                    [targetDamageSprite setPosition: ccp( targetSpriteX, targetSpriteY + 20)];
                    
                    //now the target-damage-sprite is appeared
                    targetDamageSpritePresented  = true;
                    targetBloodNeedUpdate = true;
                });
                
                ///If the curTargetBlood is smaller than 0,the target should be exploded and than destroyed
                if(curTargetBlood < 1.0)
                {
                    [self targetDestroyed:targetSprite];
                }
         }// end of @autoreleasepool
      });
    } // end of if(targetHitted)
    
    
    if (playerHitted)
    {
        playerHitted = false;
        
        dispatch_async(globalQueue, ^{
            
            @autoreleasepool{
                
                float weaponX       = weaponAI.body->GetWorldCenter().x     * PTM_RATIO;
                float weaponY       = weaponAI.body->GetWorldCenter().y     * PTM_RATIO;
                float targetSpriteX = playerSprite.body->GetWorldCenter().x * PTM_RATIO;
                float targetSpriteY = playerSprite.body->GetWorldCenter().y * PTM_RATIO;
                float diffX         = weaponX - targetSpriteX;
                float diffY         = weaponY - targetSpriteY;
                
                //************   Here is how the forceX and forceY are generated:
                //       Fx / Fy             = diffX / diffY
                //       distance            = sqrt( pow (diffX, 2) + pow (diffY, 2))
                //       F (proportional to) = pow( ratio / distance, 2)
                //       pow( F, 2 )         = pow(Fx,2)+pow(Fy,2)
                //
                //==>    Fx  = pow(ratio,2) * diffX / sqrt( pow( ( pow(diffX,2) + pow(diffY,2) ),3) )
                //==>    Fy  = pow(ratio,2) * diffY / sqrt( pow( ( pow(diffX,2) + pow(diffY,2) ),3) )
                
                
                //The ratio must be chosen very carefully.
                //Here i use a random ratio so critical strike would happen sometimes
                float ratio = frandom_range(100,400);
                
                float forceX = pow(ratio,2) * diffX / sqrt (pow ((pow(diffX,2) + pow(diffY,2)),3));
                float forceY = pow(ratio,2) * diffY / sqrt (pow ((pow(diffX,2) + pow(diffY,2)),3));
                b2Vec2 force = * new b2Vec2(forceX,forceY);
                
                //target should be blown away by the shockWave
                playerSprite.body->ApplyLinearImpulse(force, playerSprite.body->GetWorldCenter());
                
                //Now the weapon is exploded
                weaponToPlayerExploded = true;
                
                //**
                //  ***************  handle damage   *******************
                //**
                float damage = sqrt((pow(force.x,2) + pow(force.y,2)));
                CCLOG(@"damage is %f",damage);
                // if the damage is bigger than a certain number,we consider the strike as a critical strike
                // and the damage-sprite should be bigger than normal
                if(damage >= 500)
                {
                    criticalStrikeToPlayer = true;
                }
                curPlayerBlood = playerBlood - damage;
                
                //We neet to generate a damage sprite based on the damage.
                //For now, i just use a png to test anyway.
                dispatch_async(mainQueue, ^{
                    
                    if(!criticalStrikeToPlayer)
                    {
                        playerDamageSprite = [CCSprite spriteWithFile:@"blocks.png" rect:CGRectMake(32,32,32,32)];
                    }
                    else
                    {
                        playerDamageSprite = [CCSprite spriteWithFile:@"blocks.png" rect:CGRectMake(32,32,32,32)];
                        
                    }
                    [self addChild:playerDamageSprite];
                    [playerDamageSprite setPosition: ccp( targetSpriteX, targetSpriteY + 20)];
                    
                    //now the player-damage-sprite is presented
                    playerDamageSpritePresented  = true;
                    playerBloodNeedUpdate = true;
                });
                
                ///If the curTargetBlood is smaller than 0,the player should be exploded and than destroyed
                if(curPlayerBlood < 1.0)
                {
                    [self targetDestroyed:playerSprite];
                }
            } // end of @autoreleasepool
        });
    }//end of if(playerHitted)
    
    
    [self test:^(PolygonSprite *weapon ,
                 PolygonSprite *sprite,
                 BOOL hitted,
                 BOOL criticalStrike,
                 float curBlood,
                 float blood,
                 BOOL weaponExploded,
                
                 BOOL damageSpritePresented ,
                 BOOL bloodNeedUpdate)
    {
        hitted = false;
        
//        dispatch_async(globalQueue, ^{
            
            @autoreleasepool{
                
                float weaponX       = weapon.body->GetWorldCenter().x * PTM_RATIO;
                float weaponY       = weapon.body->GetWorldCenter().y * PTM_RATIO;
                float targetSpriteX = sprite.body->GetWorldCenter().x * PTM_RATIO;
                float targetSpriteY = sprite.body->GetWorldCenter().y * PTM_RATIO;
                float diffX         = weaponX - targetSpriteX;
                float diffY         = weaponY - targetSpriteY;
                
                //************   Here is how the forceX and forceY are generated:
                //       Fx / Fy             = diffX / diffY
                //       distance            = sqrt( pow (diffX, 2) + pow (diffY, 2))
                //       F (proportional to) = pow( ratio / distance, 2)
                //       pow( F, 2 )         = pow(Fx,2)+pow(Fy,2)
                //
                //==>    Fx  = pow(ratio,2) * diffX / sqrt( pow( ( pow(diffX,2) + pow(diffY,2) ),3) )
                //==>    Fy  = pow(ratio,2) * diffY / sqrt( pow( ( pow(diffX,2) + pow(diffY,2) ),3) )
                
                
                //The ratio must be chosen very carefully.
                //Here i use a random ratio so critical strike would happen sometimes
                float ratio = frandom_range(100,400);
                
                float forceX = pow(ratio,2) * diffX / sqrt (pow ((pow(diffX,2) + pow(diffY,2)),3));
                float forceY = pow(ratio,2) * diffY / sqrt (pow ((pow(diffX,2) + pow(diffY,2)),3));
                b2Vec2 force = * new b2Vec2(forceX,forceY);
                
                //target should be blown away by the shockWave
                sprite.body->ApplyLinearImpulse(force, sprite.body->GetWorldCenter());
                
                //Now the weapon is exploded
                weaponExploded = true;
                
                //**
                //  ***************  handle damage   *******************
                //**
                float damage = sqrt((pow(force.x,2) + pow(force.y,2)));
                CCLOG(@"damage is %f",damage);
                // if the damage is bigger than a certain number,we consider the strike as a critical strike
                // and the damage-sprite should be bigger than normal
                if(damage >= 500)
                {
                    criticalStrike = true;
                }
                curBlood = blood - damage;
                
                //We neet to generate a damage sprite based on the damage.
                //For now, i just use a png to test anyway.
                dispatch_async(mainQueue, ^{
                    PolygonSprite *damageSprite;
                    if(!criticalStrikeToPlayer)
                    {
                        damageSprite = [CCSprite spriteWithFile:@"blocks.png" rect:CGRectMake(32,32,32,32)];
                    }
                    else
                    {
                        damageSprite = [CCSprite spriteWithFile:@"blocks.png" rect:CGRectMake(32,32,32,32)];
                        
                    }
                    [self addChild:damageSprite];
                    [damageSprite setPosition: ccp( targetSpriteX, targetSpriteY + 20)];
                    
                    
                });
                
                //now the player-damage-sprite is presented
                damageSpritePresented  = true;
                bloodNeedUpdate = true;
                
                ///If the curTargetBlood is smaller than 0,the player should be exploded and than destroyed
                if(curBlood < 1.0)
                {
                    [self targetDestroyed:sprite];
                }
            } // end of @autoreleasepool
//        });

    }];
}

-(void)test:(void (^)(PolygonSprite *weapon ,
                      PolygonSprite *sprite,
                      BOOL hitted,
                      BOOL criticalStrike,
                      float curBlood,
                      float blood,
                      BOOL weaponExploded,
                      BOOL damageSpritePresented ,
                      BOOL bloodNeedUpdate)) testBlock
{
    if(playerHitted){
        dispatch_async(globalQueue, ^{
            testBlock(weaponAI,
                      playerSprite,
                      playerHitted,
                      criticalStrikeToPlayer,
                      curPlayerBlood,
                      playerBlood,
                      weaponToPlayerExploded,
                      playerDamageSpritePresented ,
                      playerBloodNeedUpdate);
        });
    }
    if(targetHitted){
        dispatch_async(globalQueue, ^{
            testBlock(weaponTest,
                      targetSprite,
                      targetHitted,
                      criticalStrikeToTarget,
                      curTargetBlood,
                      targetBlood,
                      weaponToTargetExploded,
                      targetDamageSpritePresented ,
                      targetBloodNeedUpdate);
        });
    }
}

//**
//  ***************************  Animation  ********************************
//**
-(void) animation
{
    
    if(weaponToTargetExploded)
    {
        /// Animation of target
        if(targetDamageSpritePresented)
        {
            //Since the main-loop is about 60 frame/s, if using the dispatch_async could improve the performance is to be examined.
            
            //dispatch_async(globalQueue, ^{
            
                float targetSpriteX = targetSprite.body->GetWorldCenter().x * PTM_RATIO;
                float targetSpriteY = targetSprite.body->GetWorldCenter().y * PTM_RATIO;
                
                //dispatch_async(mainQueue, ^{
                    
                    if(targetDamageStep <= 40)
                    {
                        id actionMove = [CCMoveTo actionWithDuration:0.05
                                                            position:ccp(targetSpriteX , targetSpriteY + 20 + 3 * targetDamageStep)];
                        
                        id actionFade = [CCFadeTo actionWithDuration:0.05
                                                             opacity:255-6 * targetDamageStep++];
                        
                        [targetDamageSprite runAction:[CCSequence actions:actionMove, actionFade, nil]];
                    }
                    else
                    {
                        //destroy the damage sprite
                        [self removeChild:targetDamageSprite cleanup:YES];
                        
                        // reset all the arguments after destroying the damage sprite
                        targetDamageStep            = 0;
                        weaponToTargetExploded      = false;
                        targetDamageSpritePresented = false;
                    }                
               // });
        //});
        }// end of if(targetDamageSpritePresented)
        
    }// end of if(weaponToTargetExploded)
    
//     UIBezierPath *movePath = [UIBezierPath bezierPath];
//    CABasicAnimation *animation=[CABasicAnimation animationWithKeyPath:@"transform.translation"];
//    animation.duration = 1.0f;
//   
//    
//    CGMutablePathRef path = CGPathCreateMutable();
//    
    if(weaponToPlayerExploded)
    {
        /// Animation of player
        if(playerDamageSpritePresented)
        {
            //Since the main-loop is about 60 frame/s, if using the dispatch_async could improve the performance is to be examined.
            
            //dispatch_async(globalQueue, ^{
            
            float playerSpriteX = playerSprite.body->GetWorldCenter().x * PTM_RATIO;
            float playerSpriteY = playerSprite.body->GetWorldCenter().y * PTM_RATIO;
            
            //dispatch_async(mainQueue, ^{
            
            if(playerDamageStep <= 40)
            {
                id actionMove = [CCMoveTo actionWithDuration:0.05
                                                    position:ccp(playerSpriteX , playerSpriteY + 20 + 3 * playerDamageStep)];
                
                id actionFade = [CCFadeTo actionWithDuration:0.05
                                                     opacity:255-6 * playerDamageStep++];
                
                [playerDamageSprite runAction:[CCSequence actions:actionMove, actionFade, nil]];
            }
            else
            {
                //destroy the damage sprite
                [self removeChild:playerDamageSprite cleanup:YES];
                
                // reset all the arguments after destroying the damage sprite
                playerDamageStep            = 0;
                weaponToPlayerExploded      = false;
                playerDamageSpritePresented = false;
            }
            // });
            //});
        } // end of if(playerDamageSpritePresented)

    }// end of if(weaponToPlayerExploded) 
}

//**
//  Update blood status
//**
- (void) updateBloodStatus
{
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSaveGState(ctx);
    CGContextSetLineCap(ctx, kCGLineCapRound);
    
    //blood-status-line width
    CGContextSetLineWidth(ctx, 2.0);
    CGContextSetAllowsAntialiasing(ctx, YES);
    
    float *color;
//    color[0] = [self generateBloodColor][0];
//    color[1] = [self generateBloodColor][1];
//    color[2] = [self generateBloodColor][2];
    if(targetBloodNeedUpdate)
    {
        color = [self generateBloodColor:targetBlood curBlood:curTargetBlood];
        targetBloodNeedUpdate = false;
        
        CGContextSetRGBStrokeColor(ctx, color[0], color[1], color[2], 1.0);
        
        CGContextBeginPath(ctx);
        CGContextMoveToPoint(ctx, 10, 35);
        CGContextAddLineToPoint(ctx, winSize.width-150, 35);
        
        CGContextStrokePath(ctx);

    }
    if(playerBloodNeedUpdate)
    {
        color = [self generateBloodColor:playerBlood curBlood:curPlayerBlood];
        playerBloodNeedUpdate = false;
        
        CGContextSetRGBStrokeColor(ctx, color[0], color[1], color[2], 1.0);
        
        CGContextBeginPath(ctx);
        CGContextMoveToPoint(ctx, winSize.width-140, 35);
        CGContextAddLineToPoint(ctx, winSize.width-10, 35);
        
        CGContextStrokePath(ctx);
    }
}

//**
//  generate blood status color
//**
- (float *) generateBloodColor:(float)targetBlood curBlood:(float)curTargetBlood
{
    // green is (127,255,0) and red is (139,0,0)
    
    float ratio = (targetBlood - curTargetBlood)/ targetBlood;
    float c1 = (127.0 + ratio * (139.0 - 127.0)) / 256.0;
    float c2 = (255.0 + ratio * (0.0 - 255.0)) / 256.0;
    float c3 = 0;
    
    float color[3] = {c1,c2,c3};
//    float *bloodColor = (float *)calloc(3, sizeof(float));
//    bloodColor[0] = c1;
//    bloodColor[1] = c2;
//    bloodColor[2] = c3;
    
    return color;
    
}


//**
//  Explode and destroy the given polygonSprite target
//**
-(void) targetDestroyed :(PolygonSprite*)target
{
    
}

//**
//  simple AI test
//**
-(void) simpleAI:(float)time
{
    if(AICouldFire){
        
            dispatch_async(globalQueue, ^{
                
                @autoreleasepool{

                AICouldFire = false;
                    
                /// Step 1
                // get the position of the player
                // Do we use the precise position or the approximately position ?
                // Do we use the real-time traced position or a certain fixed position ?
                float playerPosX ;
                float playerPosY ;
                attackWay attackWay;
                
                float Time = time;
                
                /// Step 2
                // determine the attack way
                (frandom_range(1,10) <= 5) ? (attackWay = parabolic) :(attackWay = straight);
                
                float weaponX       = weaponAI.body->GetWorldCenter().x     * PTM_RATIO;
                float weaponY       = weaponAI.body->GetWorldCenter().y     * PTM_RATIO;
                float targetSpriteX = playerSprite.body->GetWorldCenter().x * PTM_RATIO;
                float targetSpriteY = playerSprite.body->GetWorldCenter().y * PTM_RATIO;
                float diffX         = weaponX - targetSpriteX;
                float diffY         = weaponY - targetSpriteY;
                
                float Vx,Vy;
                
                /// Step 3
                // Compute the Velocity of the AI-weapon
                if( attackWay == parabolic)
                {
                    
                    ///  |Time| is a given certain argument
                    ///        Vx  * Time         = Dx
                    ///        0.5 * G * (t1 ^ 2) = Hmax           ~ 5 * (t1 ^ 2) = Hmax
                    ///        0.5 * G * (t2 ^ 2) = Hmax - Dy      ~ 5 * (t1 ^ 2) = Hmax - Dy
                    ///        t1  + t2           = Time
                    
                    /// ==>    Vx = diffX / Time
                    /// ==>    t1 = 0.5 * ( Time + Dy / 0.5 * G * Time )
                    /// ==>    t2 = 0.5 * ( Time - Dy / 0.5 * G * Time )
                    /// ==>    Vy = G * t1 = 0.5 * G * Time + Dy / 0.5 * Time
                    
                    Vx =  diffX / Time / PTM_RATIO;
                    Vy =  (0.5 * G * Time + diffY / 0.5 * Time)/ PTM_RATIO;
                    
                }
                else
                {
                    ///        Vy * T - 0.5 * G * T ^ 2 = Dy
                    
                    /// ==>    Vy = (Dy + 0.5 * G * T ^ 2) / T
                    
                    Vx = diffX / Time / PTM_RATIO;
                    Vy = (diffY + 0.5 * G * pow( Time, 2 ) ) / Time / PTM_RATIO;
                    
                } 
                
                /// Step 4
                // Fire the AI-weapon
                b2Vec2 Velocity = * new b2Vec2(Vx,Vy);
                targetSprite.body->SetLinearVelocity(Velocity);
                    
            }// end of @autoreleasepool
        });
    } // end of if(AICouldFire)
}

//**
//  Handle damage1.0
//**
-(void) handleDamage:(b2Vec2)force
{
    float damageValue = sqrt((pow(force.x,2) + pow(force.y,2)));
    if(damageValue >= 500)
    {
        criticalStrikeToTarget = true;
    }
}


//**
//  Split the specific PolygonSprite that the method world->RayCast returnd into 2 pieces,both b2body and sprtie 
//**
-(void)splitPolygonSprite:(PolygonSprite*)sprite
{
    dispatch_queue_t splitQueue =  dispatch_queue_create("split", NULL);
    
    dispatch_async(splitQueue, ^{
        
        //declare & initialize variables to be used for later
        __block PolygonSprite *newSprite1, *newSprite2;
        
        //our original shape's attributes
        b2Fixture *originalFixture = sprite.body->GetFixtureList();
        b2PolygonShape *originalPolygon = (b2PolygonShape*)originalFixture->GetShape();
        int vertexCount = originalPolygon->GetVertexCount();
        
        //    for (int i = 0 ; i < vertexCount; i++)
        //    {
        //        b2Vec2 point = originalPolygon->GetVertex(i);
        //    }
        
        //our determinant(to be described later) and iterator
        float determinant;
        int i;
        
        //we store the vertices of our two new sprites here
        b2Vec2 *sprite1Vertices = (b2Vec2*)calloc(24, sizeof(b2Vec2));
        b2Vec2 *sprite2Vertices = (b2Vec2*)calloc(24, sizeof(b2Vec2));
        __block b2Vec2 *sprite1VerticesSorted, *sprite2VerticesSorted;
        
        //we store how many vertices there are for each of the two new sprites here
        int sprite1VertexCount = 0;
        int sprite2VertexCount = 0;
        
        //step 1:
        //the entry and exit point of our cut are considered vertices of our two new shapes, so we add these before anything else
        sprite1Vertices[sprite1VertexCount++] = sprite.entryPoint;
        sprite1Vertices[sprite1VertexCount++] = sprite.exitPoint;
        sprite2Vertices[sprite2VertexCount++] = sprite.entryPoint;
        sprite2Vertices[sprite2VertexCount++] = sprite.exitPoint;
        CCLOG(@"Split-body setp 1 end");
        //step 2:
        //iterate through all the vertices and add them to each sprite's shape
        for (i=0; i<vertexCount; i++)
        {
            //get our vertex from the polygon
            b2Vec2 point = originalPolygon->GetVertex(i);
            
            //we check if our point is not the same as our entry or exit point first
            b2Vec2 diffFromEntryPoint = point - sprite.entryPoint;
            b2Vec2 diffFromExitPoint = point - sprite.exitPoint;
            
            if ((diffFromEntryPoint.x == 0 && diffFromEntryPoint.y == 0) || (diffFromExitPoint.x == 0 && diffFromExitPoint.y == 0))
            {
            }
            else
            {
                determinant = calculate_determinant_2x3(sprite.entryPoint.x, sprite.entryPoint.y, sprite.exitPoint.x, sprite.exitPoint.y, point.x, point.y);
                
                if (determinant > 0)
                {
                    //if the determinant is positive, then the three points are in clockwise order
                    sprite1Vertices[sprite1VertexCount++] = point;
                }
                else
                {
                    //if the determinant is 0, the points are on the same line. if the determinant is negative, then they are in counter-clockwise order
                    sprite2Vertices[sprite2VertexCount++] = point;
                    
                }//endif
            }//endif
        }//endfor
        CCLOG(@"Split-body setp 2 end");
        //step 3:
        //Box2D needs vertices to be arranged in counter-clockwise order so we reorder our points using a custom function
        //step 4:
        //Box2D has some restrictions with defining shapes, so we have to consider these. We only cut the shape if both shapes pass certain requirements from our function
        
        
        //***************************************  NOTICE ******************************************
        //Note that if we want to use -(void)splitPolygonSprite:(PolygonSprite*)sprite to make some Explosion-effect
        //The entry and exit point MUST be chosen carefully.If they are not appropriate enough,the Step 5 would not be invoked.
        //****************************************   WK  *******************************************
        __block dispatch_semaphore_t sem = dispatch_semaphore_create(0);
        __block BOOL sprite1VerticesAcceptable,sprite2VerticesAcceptable;
        
        dispatch_async(globalQueue, ^{
            
            sprite1VerticesSorted = [self arrangeVertices:sprite1Vertices count:sprite1VertexCount];
            sprite1VerticesAcceptable = [self areVerticesAcceptable:sprite1VerticesSorted count:sprite1VertexCount];
            
            if(!sprite1VerticesAcceptable ){
                CCLOG(@"sprite1 is NOT VerticesAcceptable");
            }
        });
        
        dispatch_async(globalQueue, ^{
            
            sprite2VerticesSorted = [self arrangeVertices:sprite2Vertices count:sprite2VertexCount];
            sprite2VerticesAcceptable = [self areVerticesAcceptable:sprite1VerticesSorted count:sprite2VertexCount];
            
            if(!sprite2VerticesAcceptable ){
                CCLOG(@"sprite2 is NOT VerticesAcceptable");
            }
        });
        
        //use semaphore to wait until the step3 and step4 are done
        dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
        dispatch_release(sem);
        
        CCLOG(@"Split-body setp3 and step4 are done");
        
        //        sprite1VerticesSorted = [self arrangeVertices:sprite1Vertices count:sprite1VertexCount];
        //        sprite2VerticesSorted = [self arrangeVertices:sprite2Vertices count:sprite2VertexCount];
        //step 4:
        //Box2D has some restrictions with defining shapes, so we have to consider these. We only cut the shape if both shapes pass certain requirements from our function
        
        
        //***************************************  NOTICE ******************************************
        //Note that if we want to use -(void)splitPolygonSprite:(PolygonSprite*)sprite to make some Explosion-effect
        //The entry and exit point MUST be chosen carefully.If they are not appropriate enough,the Step 5 would not be invoked.
        //****************************************   WK  *******************************************
        //        BOOL sprite1VerticesAcceptable = [self areVerticesAcceptable:sprite1VerticesSorted count:sprite1VertexCount];
        //        BOOL sprite2VerticesAcceptable = [self areVerticesAcceptable:sprite2VerticesSorted count:sprite2VertexCount];
        //        if(!sprite1VerticesAcceptable ){
        //            CCLOG(@"sprite1 is NOT VerticesAcceptable");
        //        }
        //        
        //        if(!sprite2VerticesAcceptable ){
        //            CCLOG(@"sprite2 is NOT VerticesAcceptable");
        //        }
        
        //step 5:
        //we destroy the old shape and create the new shapes and sprites
        if (sprite1VerticesAcceptable && sprite2VerticesAcceptable)
        {
            //************************************ use GCD to accelerate the game.*****************************
            // Use dispatch_group_async and dispatch_group_notify to get the work done.
            // The priority is to be examined.
            //************************************************************************************************
            //
            dispatch_group_t group = dispatch_group_create();
            //        globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
            __block  b2Body *body1,*body2;
            dispatch_group_async(group, globalQueue, ^{
                
                //create the first sprite's body
                body1 = [self createBodyWithPosition:sprite.body->GetPosition() rotation:sprite.body->GetAngle() vertices:sprite1VerticesSorted vertexCount:sprite1VertexCount density:originalFixture->GetDensity() friction:originalFixture->GetFriction() restitution:originalFixture->GetRestitution()];
                
                //create the first sprite
                //            newSprite1 = [PolygonSprite spriteWithTexture:sprite.texture body:body1 original:NO];
                //
                //            [self addChild:newSprite1 z:1];
                
            });
            
            dispatch_group_async(group, globalQueue, ^{
                
                //create the second sprite's body
                body2 = [self createBodyWithPosition:sprite.body->GetPosition() rotation:sprite.body->GetAngle() vertices:sprite2VerticesSorted vertexCount:sprite2VertexCount density:originalFixture->GetDensity() friction:originalFixture->GetFriction() restitution:originalFixture->GetRestitution()];
                
                //create the second sprite
                //            newSprite2 = [PolygonSprite spriteWithTexture:sprite.texture body:body2 original:NO];
                //
                //            [self addChild:newSprite2 z:1];
                
            });
            
            //****************************      Notice    ************************************
            // As we can only destroy sprite after 2 b2body are both created,we have to use dispatch_group_notify
            // to wait for the dispatch_group_async
            
            dispatch_group_notify(group, mainQueue, ^{
                
                //create sprite and add them
                newSprite1 = [PolygonSprite spriteWithTexture:sprite.texture body:body1 original:NO];
                newSprite2 = [PolygonSprite spriteWithTexture:sprite.texture body:body2 original:NO];
                
                [self addChild:newSprite1 z:1];
                [self addChild:newSprite2 z:1];
                
                //we don't need the old shape & sprite anymore so we either destroy it or squirrel it away
                CCLOG(@"in Split-body setp 5 ,create sprite1,2");
                if (sprite.original)
                {
                    [sprite deactivateCollisions];
                    sprite.position = ccp(-256,-256);   //cast them faraway
                    sprite.sliceEntered = NO;
                    sprite.sliceExited = NO;
                    sprite.entryPoint.SetZero();
                    sprite.exitPoint.SetZero();
                }
                else
                {
                    world->DestroyBody(sprite.body);
                    [self removeChild:sprite cleanup:YES];
                }
                
            });
            
            // release the group
            dispatch_release(group);
            
        }//end of  if (sprite1VerticesAcceptable && sprite2VerticesAcceptable)
        
        else
        {
            sprite.sliceEntered = NO;
            sprite.sliceExited = NO;
        }
        
        //free up our allocated vectors
        free(sprite1VerticesSorted);
        free(sprite2VerticesSorted);
        free(sprite1Vertices);
        free(sprite2Vertices);
        
    });//end of  dispatch_async(splitQueue
}


-(b2Body*)createBodyWithPosition:(b2Vec2)position rotation:(float)rotation vertices:(b2Vec2*)vertices vertexCount:(int32)count density:(float)density friction:(float)friction restitution:(float)restitution
{
    b2BodyDef bodyDef;
    bodyDef.type = b2_dynamicBody;
    bodyDef.position = position;
    bodyDef.angle = rotation;
    b2Body *body = world->CreateBody(&bodyDef);
    
    b2FixtureDef fixtureDef;
    fixtureDef.density = density;
    fixtureDef.friction = friction;
    fixtureDef.restitution = restitution;
    
    b2PolygonShape shape;
    shape.Set(vertices, count);
    fixtureDef.shape = &shape;
    body->CreateFixture(&fixtureDef);
    
    return body;
}

-(b2Vec2*)arrangeVertices:(b2Vec2*)vertices count:(int)count
{
    float determinant;
    int iCounterClockWise = 1;
    int iClockWise = count - 1;
    int i;
    
    b2Vec2 referencePointA,referencePointB;
    b2Vec2 *sortedVertices = (b2Vec2*)calloc(count, sizeof(b2Vec2));
    
    //sort all vertices in ascending order according to their x-coordinate so we can get two points of a line
    qsort(vertices, count, sizeof(b2Vec2), comparator);
    
    sortedVertices[0] = vertices[0];
    referencePointA = vertices[0];          //leftmost point
    referencePointB = vertices[count-1];    //rightmost point
    
    //we arrange the points by filling our vertices in both clockwise and counter-clockwise directions using the determinant function
    for (i=1;i<count-1;i++)
    {
        determinant = calculate_determinant_2x3(referencePointA.x, referencePointA.y, referencePointB.x, referencePointB.y, vertices[i].x, vertices[i].y);
        if (determinant<0)
        {
            sortedVertices[iCounterClockWise++] = vertices[i];
        }
        else
        {
            sortedVertices[iClockWise--] = vertices[i];
        }//endif
    }//endif
    
    sortedVertices[iCounterClockWise] = vertices[count-1];
    return sortedVertices;
}

-(BOOL)areVerticesAcceptable:(b2Vec2*)vertices count:(int)count
{
    //check 1: polygons need to at least have 3 vertices
    if (count < 3)
    {
        return NO;
    }
    
    //check 2: the number of vertices cannot exceed b2_maxPolygonVertices
    if (count > b2_maxPolygonVertices)
    {
        return NO;
    }
    
    //check 3: Box2D needs the distance from each vertex to be greater than b2_epsilon
    int32 i;
    for (i=0; i<count; ++i)
    {
        int32 i1 = i;
        int32 i2 = i + 1 < count ? i + 1 : 0;
        b2Vec2 edge = vertices[i2] - vertices[i1];
        if (edge.LengthSquared() <= b2_epsilon * b2_epsilon)
        {
            return NO;
        }
    }
    
    //check 4: Box2D needs the area of a polygon to be greater than b2_epsilon
    float32 area = 0.0f;
    
    b2Vec2 pRef(0.0f,0.0f);
    
    for (i=0; i<count; ++i)
    {
        b2Vec2 p1 = pRef;
        b2Vec2 p2 = vertices[i];
        b2Vec2 p3 = i + 1 < count ? vertices[i+1] : vertices[0];
        
        b2Vec2 e1 = p2 - p1;
        b2Vec2 e2 = p3 - p1;
        
        float32 D = b2Cross(e1, e2);
        
        float32 triangleArea = 0.5f * D;
        area += triangleArea;
    }
    
    if (area <= 0.0001)
    {
        return NO;
    }
    
    //check 5: Box2D requires that the shape be Convex.
    float determinant;
    float referenceDeterminant;
    b2Vec2 v1 = vertices[0] - vertices[count-1];
    b2Vec2 v2 = vertices[1] - vertices[0];
    referenceDeterminant = calculate_determinant_2x2(v1.x, v1.y, v2.x, v2.y);
    
    for (i=1; i<count-1; i++)
    {
        v1 = v2;
        v2 = vertices[i+1] - vertices[i];
        determinant = calculate_determinant_2x2(v1.x, v1.y, v2.x, v2.y);
        //we use the determinant to check direction from one point to another. A convex shape's points should only go around in one direction. The sign of the determinant determines that direction. If the sign of the determinant changes mid-way, then we have a concave shape.
        if (referenceDeterminant * determinant < 0.0f)
        {
            //if multiplying two determinants result to a negative value, we know that the sign of both numbers differ, hence it is concave
            return NO;
        }
    }
    v1 = v2;
    v2 = vertices[0]-vertices[count-1];
    determinant = calculate_determinant_2x2(v1.x, v1.y, v2.x, v2.y);
    if (referenceDeterminant * determinant < 0.0f)
    {
        return NO;
    }
    return YES;
}


-(void)checkAndSliceObjects
{
    double curTime = CACurrentMediaTime();
    for (b2Body* b = world->GetBodyList(); b; b = b->GetNext())
    {
        if (b->GetUserData() != NULL) {
            PolygonSprite *sprite = (PolygonSprite*)b->GetUserData();
            
            if (sprite.sliceEntered && curTime > sprite.sliceEntryTime)
            {
                //CCLOG(@"not split body");
                sprite.sliceEntered = NO;
            }
            else if (sprite.sliceEntered && sprite.sliceExited)
            {
                //CCLOG(@"it to split body");
                [self splitPolygonSprite:sprite];
            }
        }
    }
}


//*******************     wk    ***********************
//Add this funtion to splice a specific body we want
//    to be used **************************************
-(void)checkAndSliceObjects:(b2Body *)b
{
    double curTime = CACurrentMediaTime();
    
    if (b->GetUserData() != NULL) {
        if([(id)b->GetUserData() isKindOfClass:[PolygonSprite class]])
        {
        
        PolygonSprite *sprite = (PolygonSprite*)b->GetUserData();
        if(sprite.sliceEntered){
            CCLOG(@"in checkAndSliceObjects ,sprite.sliceEntered: YES");
            
        }else{
            CCLOG(@"in checkAndSliceObjects ,sprite.sliceEntered: NO");
            
        }
        if (sprite.sliceEntered && curTime > sprite.sliceEntryTime)
        {
            CCLOG(@"not split body");
            sprite.sliceEntered = NO;
        }
        else if (sprite.sliceEntered && sprite.sliceExited)
        {
            CCLOG(@"it to split body");
            [self splitPolygonSprite:sprite];
        }
      }
    }
    
}

// - (float) intersection:(b2Fixture *)fixture point:(b2Vec2 *)point normal:(b2Vec2 *)normal fraction:(float)fraction
//{
//    b2Body* currentBody = fixture->GetBody();
//
//    if ([explodingBodies containsObject:currentBody])
//        // explodingBodies.indexOf(fixture.GetBody())!=-1)
//    {
//        CCPhysicsSprite *spr=(CCPhysicsSprite *)fixture->GetBody()->GetUserData();
//        //if (spr is userData) {
//        //var userD:userData=spr as userData;
//        if ([enterPoints objectForKey:spr.tag]) {
//            // If this body has already had an intersection point, then it now has two intersection points, thus it must be split in two - thats where the splitObj() method comes in.
//            b2Vec2 *point_copy = point;
//            splitObj(fixture->GetBody(), [enterPoints objectForKey:spr.tag], point_copy);
//        }
//        else {
//            //enterPoints[spr.tag]=point;
//            [enterPoints setObject:point forKey:(spr.tag)];
//            // }
//        }
//        return 1;
//    }
//
//
//-(void) splitObj:(b2Body *)sliceBody A:(b2Vec2 *)A B:(b2Vec2 *)B
//{
//        b2Fixture * origFixture=sliceBody.GetFixtureList();
//        b2PolygonShape *poly=(b2PolygonShape *)origFixture->GetShape();
//        std::vector<b2Vec2 *>verticesVec;
//        int numVertices=poly.GetVertexCount();
//        std::vector<b2Vec2 *>shape1Vertices;
//        std::vector<b2Vec2 *>shape2Vertices;
//        var origUserData:userData=sliceBody.GetUserData();
//        int origUserDataId = origUserData.id;
//        int d;
//        b2PolygonShape polyShape = new b2PolygonShape();
//        b2Body body;
//        // First, I destroy the original body and remove its Sprite representation from the childlist.
//        world->DestroyBody(sliceBody);
//        removeChild(origUserData);
//        // The world.RayCast() method returns points in world coordinates, so I use the b2Body.GetLocalPoint() to convert them to local coordinates.;
//
//        A=sliceBody->GetLocalPoint(A);
//        B=sliceBody->GetLocalPoint(B);
//        // I use shape1Vertices and shape2Vertices to store the vertices of the two new shapes that are about to be created.
//        // Since both point A and B are vertices of the two new shapes, I add them to both vectors.
//        shape1Vertices.push_back(A, B);
//        shape2Vertices.push_back(A, B);
//        // I iterate over all vertices of the original body. ;
//        // I use the function det() ("det" stands for "determinant") to see on which side of AB each point is standing on. The parameters it needs are the coordinates of 3 points:
//        // - if it returns a value >0, then the three points are in clockwise order (the point is under AB)
//        // - if it returns a value =0, then the three points lie on the same line (the point is on AB)
//        // - if it returns a value <0, then the three points are in counter-clockwise order (the point is above AB).
//        for (int i=0; i<numVertices; i++) {
//            d=[self det:A->x y1:A.y x2:B->x y2:B->y x3:verticesVec[i]->x y3:verticesVec[i]->y];
//            if (d>0) {
//                shape1Vertices.push_back(verticesVec[i]);
//            }
//            else {
//                shape2Vertices.push_back(verticesVec[i]);
//            }
//        }
//        // In order to be able to create the two new shapes, I need to have the vertices arranged in clockwise order.
//        // I call my custom method, arrangeClockwise(), which takes as a parameter a vector, representing the coordinates of the shape's vertices and returns a new vector, with the same points arranged clockwise.
//        shape1Vertices=arrangeClockwise(shape1Vertices);
//        shape2Vertices=arrangeClockwise(shape2Vertices);
//        // setting the properties of the two newly created shapes
//        var bodyDef:b2BodyDef = new b2BodyDef();
//        bodyDef.type=b2Body.b2_dynamicBody;
//        bodyDef.position=sliceBody.GetPosition();
//        var fixtureDef:b2FixtureDef = new b2FixtureDef();
//        fixtureDef.density=origFixture.GetDensity();
//        fixtureDef.friction=origFixture.GetFriction();
//        fixtureDef.restitution=origFixture.GetRestitution();
//        // creating the first shape, if big enough
//        if (getArea(shape1Vertices,shape1Vertices.length)>=0.05) {
//            polyShape.SetAsVector(shape1Vertices);
//            fixtureDef.shape=polyShape;
//            bodyDef.userData=new userData(origUserDataId,shape1Vertices,origUserData.texture);
//            addChild(bodyDef.userData);
//            enterPointsVec[origUserDataId]=null;
//            body=world.CreateBody(bodyDef);
//            body.SetAngle(sliceBody.GetAngle());
//            body.CreateFixture(fixtureDef);
//            // setting a velocity for the debris
//            body.SetLinearVelocity(setExplosionVelocity(body));
//            // the shape will be also part of the explosion and can explode too
//            explodingBodies.push(body);
//        }
//        // creating the second shape, if big enough
//        if (getArea(shape2Vertices,shape2Vertices.length)>=0.05) {
//            polyShape.SetAsVector(shape2Vertices);
//            fixtureDef.shape=polyShape;
//            bodyDef.userData=new userData(numEnterPoints,shape2Vertices,origUserData.texture);
//            addChild(bodyDef.userData);
//            enterPointsVec.push(null);
//            numEnterPoints++;
//            body=world.CreateBody(bodyDef);
//            body.SetAngle(sliceBody.GetAngle());
//            body.CreateFixture(fixtureDef);
//            // setting a velocity for the debris
//            body.SetLinearVelocity(setExplosionVelocity(body));
//            // the shape will be also part of the explosion and can explode too
//            explodingBodies.push(body);
//        }
//    }
//
////计算分裂后各碎片的方向与速度
//-(b2Vec2 *)  setExplosionVelocity:(b2Body *)b
//{
//    // 参数explosionRadius，分裂中心点explosionX，explosionY
//    explosionRadius = 50;
//    float distX=b->GetWorldCenter().x*PTM_RATIO-explosionX;
//    if (distX<0) {
//        if (distX<-explosionRadius) {
//            distX=0;
//        }
//        else {
//            distX=- explosionRadius-distX;
//        }
//    }
//    else {
//        if (distX>explosionRadius) {
//            distX=0;
//        }
//        else {
//            distX=explosionRadius-distX;
//        }
//    }
//    float distY =b->GetWorldCenter().y*PTM_RATIO-explosionY;
//    if (distY<0) {
//        if (distY<-explosionRadius) {
//            distY=0;
//        }
//        else {
//            distY=- explosionRadius-distY;
//        }
//    }
//    else {
//        if (distY>explosionRadius) {
//            distY=0;
//        }
//        else {
//            distY=explosionRadius-distY;
//        }
//    }
//    distX*=0.25;
//    distY*=0.25;
//    return new b2Vec2(distX,distY);
//}
//
////将传入的一系列坐标变为顺时针坐标点排列输出，用于分裂碎片建模
//-(NSMutableArray *)  arrangeClockwise:(NSMutableArray *)  vec {
//    // The algorithm is simple:
//    // First, it arranges all given points in ascending order, according to their x-coordinate.
//    // Secondly, it takes the leftmost and rightmost points (lets call them C and D), and creates tempVec, where the points arranged in clockwise order will be stored.
//    // Then, it iterates over the vertices vector, and uses the det() method I talked about earlier. It starts putting the points above CD from the beginning of the vector, and the points below CD from the end of the vector.
//    // That was it!
//    int n=[vec count];
//    float d;
//    int i1=1,i2=n-1;
//    //var tempVec:Vector.<b2Vec2>=new Vector.<b2Vec2>(n);
//    NSMutableArray *tempVec = [NSMutableArray arrayWithCapacity:10];
//    b2Vec2 *C;
//    b2Vec2 *D;
//    //vec.sort(comp1);
//    [vec sortedArrayUsingComparator:^NSComparisonResult(id obj1 ,id obj2) {
//        if (((b2Vec2*)obj1)->x > ((b2Vec2*)obj2)->x) {
//            return 1;
//        }
//        else if (((b2Vec2*)obj1)->x < ((b2Vec2*)obj2)->x) {
//            return -1;
//        }
//        return 0;
//    }];
//   // [tempVec objectAtIndex:0]=[vec objectAtIndex:0];
//    [tempVec replaceObjectAtIndex:0 withObject:[vec objectAtIndex:0]];
//    C=(b2Vec2*)[vec objectAtIndex:0];
//    D=(b2Vec2*)[vec objectAtIndex:n-1];
//    for ( int i=1; i<n-1; i++) {
//        d=[self det:C->x y1:C->y x2:D->x y2:D->y x3:((b2Vec2*)[vec objectAtIndex:i])->x y3:((b2Vec2*)[vec objectAtIndex:i])->y];
//        if (d<0) {
//            [tempVec replaceObjectAtIndex:i1++ withObject:[vec objectAtIndex:i]];
//            //tempVec[i1++]=vec[i];
//        }
//        else {
//            [tempVec replaceObjectAtIndex:i2-- withObject:[vec objectAtIndex:i]];
//            //tempVec[i2--]=vec[i];
//        }
//    }
//    tempVec[i1]=vec[n-1];
//    return tempVec;
//}
//
//// 计算不规则碎片的面积，忽略非常小的部分以提高性能
//-(float)  getArea:(NSMutableArray *)vs count:(int)count
//{
//    float area=0.0;
//    float p1X=0.0;
//    float p1Y=0.0;
//    float inv3=1.0/3.0;
//    for (int i = 0; i < count; ++i) {
//        b2Vec2 *p2=(b2Vec2 *)[vs objectAtIndex:i];
//        b2Vec2 *p3=(b2Vec2 *)(（i+1)< count ?((b2Vec2 *)[vs objectAtIndex:i+1]):((b2Vec2 *)[vs objectAtIndex:0]));
//        float e1X=p2->x-p1X;
//        float e1Y=p2->y-p1Y;
//        float e2X=p3->x-p1X;
//        float e2Y=p3->y-p1Y;
//        float D = (e1X * e2Y - e1Y * e2X);
//        float triangleArea=0.5*D;
//        area+=triangleArea;
//    }
//    return area;
//}
//
//
//
//
//
//-(int)  comp1:(b2Vec2 * )a comp2:(b2Vec2*)b {
////    // This is a compare function, used in the arrangeClockwise() method - a fast way to arrange the points in ascending order, according to their x-coordinate.
////    if (a->x>b->x) {
////        return 1;
////    }
////    else if (a->x<b->x) {
////        return -1;
////    }
////    return 0;
//}
//
//
//-(float) det:(NSInteger)x1  y1:(NSInteger)y1 x2:(NSInteger)x2 y2:(NSInteger)y2 x3:(NSInteger)x3  y3:(NSInteger)y3{
//    // This is a function which finds the determinant of a 3x3 matrix.
//    // If you studied matrices, you'd know that it returns a positive number if three given points are in clockwise order, negative if they are in anti-clockwise order and zero if they lie on the same line.
//    // Another useful thing about determinants is that their absolute value is two times the face of the triangle, formed by the three given points.
//    return x1*y2+x2*y3+x3*y1-y1*x2-y2*x3-y3*x1;
//}



/////////////////////////////////////////////////////////////////////
#pragma mark GameKit delegate

-(void) achievementViewControllerDidFinish:(GKAchievementViewController *)viewController
{
	AppController *app = (AppController*) [[UIApplication sharedApplication] delegate];
	[[app navController] dismissModalViewControllerAnimated:YES];
}

-(void) leaderboardViewControllerDidFinish:(GKLeaderboardViewController *)viewController
{
	AppController *app = (AppController*) [[UIApplication sharedApplication] delegate];
	[[app navController] dismissModalViewControllerAnimated:YES];
}


#pragma mark = add touch control
//************************* add touch-control******************************
- (void)selectSpriteForTouch:(CGPoint)touchLocation
{
    PolygonSprite * newSprite = nil;
    for (PolygonSprite *sprite in movableSprites)
    {
        if (CGRectContainsPoint(sprite.boundingBox, touchLocation))
        {
            newSprite = sprite;
            break;
        }
    }
    if (newSprite != selSprite)
    {
        [selSprite stopAllActions];
        [selSprite runAction:[CCRotateTo actionWithDuration:0.1 angle:0]];
        CCRotateTo * rotLeft = [CCRotateBy actionWithDuration:0.1 angle:-4.0];
        CCRotateTo * rotCenter = [CCRotateBy actionWithDuration:0.1 angle:0.0];
        CCRotateTo * rotRight = [CCRotateBy actionWithDuration:0.1 angle:4.0];
        CCSequence * rotSeq = [CCSequence actions:rotLeft, rotCenter, rotRight, rotCenter, nil];
        [newSprite runAction:[CCRepeatForever actionWithAction:rotSeq]];
        selSprite = newSprite;
        CCLOG(@"select");
    }
}

- (void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	//Add a new body/atlas sprite at the touched location
	for( UITouch *touch in touches )
    {
		CGPoint location = [touch locationInView: [touch view]];
		
		CGPoint location1 = [[CCDirector sharedDirector] convertToGL: location];
        
                
        if(!cutMode)
        {
            if(isBloom)
            {
                CGPoint nodePosition = [self convertTouchToNodeSpace:touch];
                Box2DUtils::PhysExplosion(world, b2Vec2(nodePosition.x / PTM_RATIO, nodePosition.y /PTM_RATIO), 5, 100);
            }
            else if(selSprite && (selSprite.tag == weaponTag))
            {
                CCLOG(@"shoot");
                b2Vec2 b = *new b2Vec2(-10*(location1.x-locationBegin.x),-10*(location1.y-locationBegin.y));
                selSprite.body->ApplyForce(b, selSprite.body->GetWorldCenter());
            }
            else if(addBodyMode)
            {
                [self addNewSpriteAtPosition: location1];
            }
        }
        

	}
    

}

- (void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    //    CGPoint touchLocation = [self convertTouchToNodeSpace:touch];
    for( UITouch *touch in touches )
    {
		CGPoint location = [touch locationInView: [touch view]];
		
		location = [[CCDirector sharedDirector] convertToGL: location];
        locationBegin = location;
        
        // select the specific sprite we touch
        [self selectSpriteForTouch:location];
        
        
        if (cutMode)
        {
            _startPoint = location;
            _endPoint = location;
        }
        
        CCLOG(@"touchbegin");
    }
    //return TRUE;
}

- (void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    //CGPoint touchLocation = [self convertTouchToNodeSpace:touch];
    for( UITouch *touch in touches )
    {
        CGPoint touchLocation = [touch locationInView: [touch view]];
        
        touchLocation = [[CCDirector sharedDirector] convertToGL: touchLocation];
        
        //oldTouchLocation = [self convertToNodeSpace:oldTouchLocation];
        
        //*********************The following method is used to cut PolygonSprite-body******************
        //************************************     WK    **********************************************
        // Only if the cut-option is on,could we cut the bodyA
        if (cutMode) {
            _endPoint = touchLocation;
            //if the thouch-lenght is long enough,we can cut the BodyA
            if (ccpLengthSQ(ccpSub(_startPoint, _endPoint)) > 25)
            {
                world->RayCast(_raycastCallback,
                               b2Vec2(_startPoint.x / PTM_RATIO, _startPoint.y / PTM_RATIO),
                               b2Vec2(_endPoint.x / PTM_RATIO, _endPoint.y / PTM_RATIO));
                
                world->RayCast(_raycastCallback,
                               b2Vec2(_endPoint.x / PTM_RATIO, _endPoint.y / PTM_RATIO),
                               b2Vec2(_startPoint.x / PTM_RATIO, _startPoint.y / PTM_RATIO));
                
//                _startPoint = _endPoint;
            }
            
        }
        // Only if the spirte is Weapon,could it be moved
        // else if (selSprite.tag == 9999)
        else
        {
            CGPoint oldTouchLocation = [touch previousLocationInView:touch.view];
            oldTouchLocation = [[CCDirector sharedDirector] convertToGL:oldTouchLocation];
            
            CGPoint translation = ccpSub(touchLocation, oldTouchLocation);
            [self panForTranslation:translation];
        }
    }
}

//Use boundLayerPos to check boundary conditions
- (CGPoint)boundLayerPos:(CGPoint)newPos {
    CGSize windowSize = [CCDirector sharedDirector].winSize;
    CGPoint retval = newPos;
    retval.x = MIN(retval.x, 0);
    retval.x = MAX(retval.x, -background.contentSize.width + windowSize.width);
    retval.y = self.position.y;
    return retval;
}

// If the touch-target is a sprite , we move it to the newPos,
// Otherwise we consider that the touch-target is background-layer which should be moved with the touches.
- (void)panForTranslation:(CGPoint)translation {
    if (selSprite) {
        CGPoint newPos = ccpAdd(selSprite.position, translation);
        selSprite.position = newPos;
        CCLOG(@"move to position %0.2f x %02.f",
              selSprite.body->GetPosition().x * PTM_RATIO,
              selSprite.body->GetPosition().y * PTM_RATIO);
        
    } else {
        //CGPoint newPos = ccpAdd(self.position, translation);
        //暂时注释掉场景移动的代码
        //self.position = [self boundLayerPos:newPos];
    }
}




- (void)handlePanFrom:(UIPanGestureRecognizer *)recognizer {
    
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        
        CGPoint touchLocation = [recognizer locationInView:recognizer.view];
        touchLocation = [[CCDirector sharedDirector] convertToGL:touchLocation];
        touchLocation = [self convertToNodeSpace:touchLocation];
        [self selectSpriteForTouch:touchLocation];
        
    } else if (recognizer.state == UIGestureRecognizerStateChanged) {
        
        CGPoint translation = [recognizer translationInView:recognizer.view];
        translation = ccp(translation.x, -translation.y);
        [self panForTranslation:translation];
        [recognizer setTranslation:CGPointZero inView:recognizer.view];
        
    } else if (recognizer.state == UIGestureRecognizerStateEnded) {
        
        if (!selSprite) {
            float scrollDuration = 0.2;
            //Get the velocity of the panGesture,so we could use it to caculate where the final Pos is after a  animation.
            CGPoint velocity = [recognizer velocityInView:recognizer.view];
            // newPos = oldPos + velocity * factor
            CGPoint newPos = ccpAdd(self.position, ccpMult(velocity, scrollDuration));
            // Use boundLayerPos to check boundary conditions
            newPos = [self boundLayerPos:newPos];
            
            [self stopAllActions];
            CCMoveTo *moveTo = [CCMoveTo actionWithDuration:scrollDuration position:newPos];
            [self runAction:[CCEaseOut actionWithAction:moveTo rate:1]];
        }
        
    }
}

@end


//经试验，先销毁图像再在下个循环销毁body，效果最好。如果不先销毁图像，渲染会莫名其妙延迟。

//            PolygonSprite *spriteA = (PolygonSprite *) bodyA->GetUserData();
//            PolygonSprite *spriteB = (PolygonSprite *) bodyB->GetUserData();
//           if (((spriteA.tag >= 1000 && spriteB.tag >=1000)|| (spriteA.tag >=1000 && spriteB.tag >=1000))){
//               CCLOG(@"in contact");
//
//                explosionX = bodyA->GetWorldCenter().x;
//                explosionY = bodyA->GetWorldCenter().y;
//                CCLOG(@"explosion center is: %0.2f x %02.f",explosionX,explosionY);
//               for (int i=1; i<=1; i++)
//               {
//                   CCLOG(@"in contact");
//                   //float cutAngle = (arc4random()%360)/360 * pi *2;
//                   //b2Vec2 point1(0.0f, 10.0f);
//                    //b2Vec2 p1 = *new b2Vec2((explosionX+i/10 - 10 * cos(cutAngle)), (explosionY-20 * sin(cutAngle)));
//                    //b2Vec2 p2 = *new b2Vec2((explosionX+10 * cos(cutAngle)), (explosionY + 20 * sin(cutAngle)));
//                   b2Vec2 p1,p2;
//                   float cutAngle =rand()*pi*2;
//                   p1.x=(explosionX * PTM_RATIO + i/10.0 - 2000*cos(cutAngle));
//                   p1.y=(explosionY * PTM_RATIO - 2000*sin(cutAngle));
//                   p2.x=(explosionX * PTM_RATIO + 2000*cos(cutAngle));
//                   p2.y=(explosionY * PTM_RATIO + 2000*sin(cutAngle));
//
//                CCLOG(@"explosion point1 is: %0.2f x %02.f",p1.x,p1.y);
//                CCLOG(@"explosion point2 is: %0.2f x %02.f",p2.x,p2.y);
//                CCLOG(@"before world->RayCast");
//                world->RayCast(_raycastCallback,
//                               b2Vec2(p1.x / PTM_RATIO, p1.y / PTM_RATIO),
//                               b2Vec2(p2.x / PTM_RATIO, p2.y / PTM_RATIO));
//
//                CCLOG(@"after world->RayCast  1");
//
//                world->RayCast(_raycastCallback,
//                               b2Vec2(p2.x / PTM_RATIO, p2.y / PTM_RATIO),
//                               b2Vec2(p1.x / PTM_RATIO, p1.y / PTM_RATIO));
//
//                CCLOG(@"after world->RayCast  2");
//
//                  if(spriteA.sliceEntered){
//                       CCLOG(@"after world->RayCast  2 ,sprite.sliceEntered: YES");
//
//                   }else{
//                       CCLOG(@"after world->RayCast  2 ,sprite.sliceEntered: NO");
//
//                   }
//
//                   [self checkAndSliceObjects:bodyA];
//
//                CCLOG(@"after splicing bodyA");

//               }//end for

// 不能立刻销毁body
//            world->DestroyBody(bodyA);
//            world->DestroyBody(bodyB);

// Loop through all of the Box2D bodies in our Box2D world..
//    for(b2Body *b = world->GetBodyList(); b; b=b->GetNext()) {
//
//        // See if there's any user data attached to the Box2D body
//        // There should be, since we set it in addBoxBodyForSprite
//        if (b->GetUserData() != NULL) {
//
//            // We know that the user data is a sprite since we set
//            // it that way, so cast it...
//            CCPhysicsSprite *sprite = (CCPhysicsSprite *)b->GetUserData();
//
//            // Convert the Cocos2D position/rotation of the sprite to the Box2D position/rotation
//            b2Vec2 b2Position = b2Vec2(sprite.position.x/PTM_RATIO,
//                                       sprite.position.y/PTM_RATIO);
//            float32 b2Angle = -1 * CC_DEGREES_TO_RADIANS(sprite.rotation);
//
//            // Update the Box2D position/rotation to match the Cocos2D position/rotation
//            b->SetTransform(b2Position, b2Angle);
//        }
//    }



//
//        // Loop through all of the box2d bodies we wnat to destroy...
//        std::vector<b2Body *>::iterator pos2;
//        for(pos2 = toDestroy.begin(); pos2 != toDestroy.end(); ++pos2)
//        {
//            b2Body *body = *pos2;
//
//            // See if there's any user data attached to the Box2D body
//            // There should be, since we set it in addBoxBodyForSprite
//            if (body->GetUserData() != NULL)
//            {
//
//                // We know that the user data is a sprite since we set
//                // it that way, so cast it...
//                PolygonSprite *sprite = (PolygonSprite *) body->GetUserData();
//
//                // Remove the sprite from the scene
//                [parent1 removeChild:sprite];
//            }
//
//            // Destroy the Box2D body as well
//            world->DestroyBody(body);//
//        }

