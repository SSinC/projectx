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
#import "CCPhysicsSprite.h"

// Needed to obtain the Navigation Controller
#import "AppDelegate.h"


enum {
	kTagParentNode = 1,
};


#pragma mark - HelloWorldLayer

@interface HelloWorldLayer()
-(void) initPhysics;
-(void) addNewSpriteAtPosition:(CGPoint)p;
-(void) createMenu;
-(void) createBody1;
-(void) createBody2;
-(void) createBody3;

@end

@implementation HelloWorldLayer

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
				self.touchEnabled = YES;
		self.accelerometerEnabled = YES;
		CGSize s = [CCDirector sharedDirector].winSize;
		
		// init physics
		[self initPhysics];
		
		// create reset button
		[self createMenu];
		
        movableSprites = [[NSMutableArray alloc] init];
        
		//Set up sprite
		
#if 1
		// Use batch node. Faster
		CCSpriteBatchNode *parent = [CCSpriteBatchNode batchNodeWithFile:@"blocks.png" capacity:100];
		spriteTexture_ = [parent texture];
#else
		// doesn't use batch node. Slower
		spriteTexture_ = [[CCTextureCache sharedTextureCache] addImage:@"blocks.png"];
		CCNode *parent = [CCNode node];
#endif
		[self addChild:parent z:0 tag:kTagParentNode];
		
		
		[self addNewSpriteAtPosition:ccp(s.width/2, s.height/2+200)];
        
		
		CCLabelTTF *label = [CCLabelTTF labelWithString:@"Tap screen" fontName:@"Marker Felt" fontSize:32];
		[self addChild:label z:0];
		[label setColor:ccc3(0,0,255)];
		label.position = ccp( s.width/2, s.height-50);
        
        //add contactListener
          _contactListener = new contactListener();
		 world->SetContactListener(_contactListener);
        
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
    CCMenuItem *chooseBody1 = [CCMenuItemFont itemWithString:@"Body1" block:^(id sender){
        copy_chooseBodyNumber = 1;
        
    }];
    
    CCMenuItem *chooseBody2 = [CCMenuItemFont itemWithString:@"Body2" block:^(id sender){
        copy_chooseBodyNumber = 2;
        
    }];
    
    CCMenuItem *chooseBody3 = [CCMenuItemFont itemWithString:@"Body3" block:^(id sender){
        copy_chooseBodyNumber = 3;
        
    }];
	
    CCMenu *menuChooseBody = [CCMenu menuWithItems:chooseBody1, chooseBody2, chooseBody3, nil];
	
	[menuChooseBody alignItemsHorizontally];
	
    [menuChooseBody setPosition:ccp( size.width/6, size.height/2+150)];
    //z代表图像层次
    [self addChild: menuChooseBody z:-1];
    
	
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
	
	world->DrawDebugData();	
	
	kmGLPopMatrix();
}

-(void) createBody1:(CGPoint)p
{
    CCLOG(@"Add sprite %0.2f x %02.f",p.x,p.y);
	// Define the dynamic body.
	//Set up a 1m squared box in the physics world
	b2BodyDef bodyDef;
	bodyDef.type = b2_dynamicBody;
	bodyDef.position.Set(p.x/PTM_RATIO, p.y/PTM_RATIO);
	b2Body *body = world->CreateBody(&bodyDef);
	
	// Define another box shape for our dynamic body.
	b2PolygonShape dynamicBox;
	dynamicBox.SetAsBox(.5f, .5f);//These are mid points for our 1m box
	
	// Define the dynamic body fixture.
	b2FixtureDef fixtureDef;
	fixtureDef.shape = &dynamicBox;
	fixtureDef.density = 1.5f;
	fixtureDef.friction = 0.7f;
    fixtureDef.restitution = 0.7f;
	body->CreateFixture(&fixtureDef);
	
    
	CCNode *parentSprite = [self getChildByTag:kTagParentNode];
	
	//We have a 64x64 sprite sheet with 4 different 32x32 images.  The following code is
	//just randomly picking one of the images
	//int idx = (CCRANDOM_0_1() > .5 ? 0:1);
	//int idy = (CCRANDOM_0_1() > .5 ? 0:1);
	CCPhysicsSprite *sprite = [CCPhysicsSprite spriteWithTexture:spriteTexture_ rect:CGRectMake(0,0,32,32)];
    //添加tag用来给碰撞检测时判断物体类型
    sprite.tag = 1;
   
	[parentSprite addChild:sprite];
	
	[sprite setPTMRatio:PTM_RATIO];
	[sprite setB2Body:body];
	[sprite setPosition: ccp( p.x, p.y)];
    
    //暂时注释掉setUserData中存入结构体
//    myUserData *data1 ;
//    data1->bodyType = 1;
//    data1->sprite = sprite;
//    body->SetUserData(data1);
    
    body->SetUserData(sprite);
    [movableSprites addObject:sprite];
}

-(void) createBody2:(CGPoint)p
{
    CCLOG(@"Add sprite %0.2f x %02.f",p.x,p.y);
	// Define the dynamic body.
	//Set up a 1m squared box in the physics world
	b2BodyDef bodyDef;
	bodyDef.type = b2_dynamicBody;
	bodyDef.position.Set(p.x/PTM_RATIO, p.y/PTM_RATIO);
	b2Body *body = world->CreateBody(&bodyDef);
	
	// Define another box shape for our dynamic body.
	b2PolygonShape dynamicBox;
	dynamicBox.SetAsBox(.5f, .5f);//These are mid points for our 1m box
	
	// Define the dynamic body fixture.
	b2FixtureDef fixtureDef;
	fixtureDef.shape = &dynamicBox;
	fixtureDef.density = 1.5f;
	fixtureDef.friction = 0.7f;
    fixtureDef.restitution = 0.7f;
	body->CreateFixture(&fixtureDef);
	
    
	CCNode *parentSprite = [self getChildByTag:kTagParentNode];
	
	//We have a 64x64 sprite sheet with 4 different 32x32 images.  The following code is
	//just randomly picking one of the images
//	int idx = (CCRANDOM_0_1() > .5 ? 0:1);
//	int idy = (CCRANDOM_0_1() > .5 ? 0:1);
	CCPhysicsSprite *sprite = [CCPhysicsSprite spriteWithTexture:spriteTexture_ rect:CGRectMake(32 ,0,32,32)];
    //添加tag用来给碰撞检测时判断物体类型
    sprite.tag = 2;
    
	[parentSprite addChild:sprite];
	
	[sprite setPTMRatio:PTM_RATIO];
	[sprite setB2Body:body];
	[sprite setPosition: ccp( p.x, p.y)];
    
    //暂时注释掉setUserData中存入结构体
    //    myUserData *data1 ;
    //    data1->bodyType = 1;
    //    data1->sprite = sprite;
    //    body->SetUserData(data1);
    
    body->SetUserData(sprite);
    [movableSprites addObject:sprite];
}

-(void) createBody3:(CGPoint)p
{
    
}

-(void) addNewSpriteAtPosition:(CGPoint)p
{
	if(!selSprite){
      CCLOG(@"chooseBodyNumber %i",copy_chooseBodyNumber);
        switch (copy_chooseBodyNumber) {
            case 1:
                [self createBody1:p];
                break;
            case 2:
                [self createBody2:p];
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
   
    
    // Loop through all of the Box2D bodies in our Box2D world..
    for(b2Body *b = world->GetBodyList(); b; b=b->GetNext()) {
        
        // See if there's any user data attached to the Box2D body
        // There should be, since we set it in addBoxBodyForSprite
        if (b->GetUserData() != NULL) {
            
            // We know that the user data is a sprite since we set
            // it that way, so cast it...
            CCPhysicsSprite *sprite = (CCPhysicsSprite *)b->GetUserData();
            
            // Convert the Cocos2D position/rotation of the sprite to the Box2D position/rotation
            b2Vec2 b2Position = b2Vec2(sprite.position.x/PTM_RATIO,
                                       sprite.position.y/PTM_RATIO);
            float32 b2Angle = -1 * CC_DEGREES_TO_RADIANS(sprite.rotation);
            
            // Update the Box2D position/rotation to match the Cocos2D position/rotation
            b->SetTransform(b2Position, b2Angle);
        }
    }
    CCNode *parent1 = [self getChildByTag:kTagParentNode];

    std::vector<b2Body *>toDestroy;
    std::vector<MyContact>::iterator pos;
    for(pos = _contactListener->_contacts.begin(); pos != _contactListener->_contacts.end(); ++pos) {
        MyContact contact = *pos;
        
        // Get the box2d bodies for each object
        b2Body *bodyA = contact.fixtureA->GetBody();
        b2Body *bodyB = contact.fixtureB->GetBody();
        
        if (bodyA->GetUserData() != NULL && bodyB->GetUserData() != NULL) {
          
            
              CCPhysicsSprite *spriteA = (CCPhysicsSprite *) bodyA->GetUserData();
              CCPhysicsSprite *spriteB = (CCPhysicsSprite *) bodyB->GetUserData();
            
             //只让A和B碰撞后销毁
            if ((spriteA.tag == 1 && spriteB.tag == 2)|| (spriteA.tag == 2 && spriteB.tag == 1)) {
                [parent1 removeChild:spriteA];
                [parent1 removeChild:spriteB];
                //经试验，先销毁图像再在下个循环销毁body，效果最好。如果不先销毁图像，渲染会莫名其妙延迟。
                toDestroy.push_back(bodyA);
                toDestroy.push_back(bodyB);
                
                // 不能立刻销毁body
                //            world->DestroyBody(bodyA);
                //            world->DestroyBody(bodyB);
            }
            
          }
        
        }
//销毁body
    // Loop through all of the box2d bodies we wnat to destroy...
    std::vector<b2Body *>::iterator pos2;
    for(pos2 = toDestroy.begin(); pos2 != toDestroy.end(); ++pos2) {
        b2Body *body = *pos2;
        
        // See if there's any user data attached to the Box2D body
        // There should be, since we set it in addBoxBodyForSprite
        if (body->GetUserData() != NULL) {
            
            // We know that the user data is a sprite since we set
            // it that way, so cast it...
            CCPhysicsSprite *sprite = (CCPhysicsSprite *) body->GetUserData();
            
            // Remove the sprite from the scene
            [parent removeChild:sprite];
        }
        
        // Destroy the Box2D body as well
        world->DestroyBody(body);
    }
    
    world->ClearForces();
   }


///////////////////////一些用于计算分裂效果的基础函数

//计算分裂后各碎片的方向与速度
-(b2Vec2)  setExplosionVelocity:(b2Body *)b
{
    // 参数explosionRadius，分裂中心点explosionX，explosionY
    explosionRadius = 50;
    float distX=b->GetWorldCenter().x*PTM_RATIO-explosionX;
    if (distX<0) {
        if (distX<-explosionRadius) {
            distX=0;
        }
        else {
            distX=- explosionRadius-distX;
        }
    }
    else {
        if (distX>explosionRadius) {
            distX=0;
        }
        else {
            distX=explosionRadius-distX;
        }
    }
    float distY =b->GetWorldCenter().y*PTM_RATIO-explosionY;
    if (distY<0) {
        if (distY<-explosionRadius) {
            distY=0;
        }
        else {
            distY=- explosionRadius-distY;
        }
    }
    else {
        if (distY>explosionRadius) {
            distY=0;
        }
        else {
            distY=explosionRadius-distY;
        }
    }
    distX*=0.25;
    distY*=0.25;
    return *new b2Vec2(distX,distY);
}
////////////////////////Stream,下面的代码是移植于as代码，有点问题/////////////////////////
////////////////////////Stream,下面的代码是移植于as代码，有点问题/////////////////////////
////////////////////////Stream,下面的代码是移植于as代码，有点问题/////////////////////////
////////////////////////Stream,下面的代码是移植于as代码，有点问题/////////////////////////
//将传入的一系列坐标变为顺时针坐标点排列输出，用于分裂碎片建模
-(NSMutableArray *)  arrangeClockwise:(NSMutableArray *)  vec {
    // The algorithm is simple:
    // First, it arranges all given points in ascending order, according to their x-coordinate.
    // Secondly, it takes the leftmost and rightmost points (lets call them C and D), and creates tempVec, where the points arranged in clockwise order will be stored.
    // Then, it iterates over the vertices vector, and uses the det() method I talked about earlier. It starts putting the points above CD from the beginning of the vector, and the points below CD from the end of the vector.
    // That was it!
    int n=[vec count];
    float d;
    int i1=1,i2=n-1;
    //var tempVec:Vector.<b2Vec2>=new Vector.<b2Vec2>(n);
    NSMutableArray *tempVec = [NSMutableArray arrayWithCapacity:10];
    b2Vec2 C;
    b2Vec2 D;
    //vec.sort(comp1);
    [vec sortedArrayUsingComparator:^NSComparisonResult(b2Vec2 a ,b2Vec2 b) {
        if (((b2Vec2)a).x>((b2Vec2)b).x) {
            return 1;
        }
        else if (a.x<b.x) {
            return -1;
        }
        return 0;
    }];
   // [tempVec objectAtIndex:0]=[vec objectAtIndex:0];
    [tempVec replaceObjectAtIndex:0 withObject:[vec objectAtIndex:0]];
    C=[vec objectAtIndex:0];
    D=[vec objectAtIndex:n-1];
    for ( int i=1; i<n-1; i++) {
        d=[self det:C.x y1:C.y x2:D.x y2:D.y x3:[vec objectAtIndex:i].x y3:[vec objectAtIndex:i].y];
        if (d<0) {
            [tempVec replaceObjectAtIndex:i1++ withObject:[vec objectAtIndex:i]];
            //tempVec[i1++]=vec[i];
        }
        else {
            [tempVec replaceObjectAtIndex:i2-- withObject:[vec objectAtIndex:i]];
            //tempVec[i2--]=vec[i];
        }
    }
    tempVec[i1]=vec[n-1];
    return tempVec;
}







-(int)  comp1:(b2Vec2)a comp2:(b2Vec2)b {
    // This is a compare function, used in the arrangeClockwise() method - a fast way to arrange the points in ascending order, according to their x-coordinate.
    if (a.x>b.x) {
        return 1;
    }
    else if (a.x<b.x) {
        return -1;
    }
    return 0;
}
-(float)  det:(NSInteger)x1  y1:(NSInteger)y1 x2:(NSInteger)x2 y2:(NSInteger)y2 x3:(NSInteger)x3  y3:(NSInteger)y3{
    // This is a function which finds the determinant of a 3x3 matrix.
    // If you studied matrices, you'd know that it returns a positive number if three given points are in clockwise order, negative if they are in anti-clockwise order and zero if they lie on the same line.
    // Another useful thing about determinants is that their absolute value is two times the face of the triangle, formed by the three given points.
    return x1*y2+x2*y3+x3*y1-y1*x2-y2*x3-y3*x1;
}


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




//************************* add touch-control******************************
- (void)selectSpriteForTouch:(CGPoint)touchLocation {
    CCPhysicsSprite * newSprite = nil;
    for (CCPhysicsSprite *sprite in movableSprites) {
        if (CGRectContainsPoint(sprite.boundingBox, touchLocation)) {
            newSprite = sprite;
            break;
        }
    }
    if (newSprite != selSprite) {
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
//用新的touch-api，可以扩展为多点触摸
- (void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	//Add a new body/atlas sprite at the touched location
	for( UITouch *touch in touches ) {
		CGPoint location = [touch locationInView: [touch view]];
		
		CGPoint location1 = [[CCDirector sharedDirector] convertToGL: location];
       
		if(selSprite){
            CCLOG(@"fuck");
            b2Vec2 b = *new b2Vec2(-10*(location1.x-locationBegin.x),-10*(location1.y-locationBegin.y));
            selSprite.b2Body->ApplyForce(b, selSprite.b2Body->GetWorldCenter());
        }
		[self addNewSpriteAtPosition: location1];
	}
}

- (BOOL)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
//    CGPoint touchLocation = [self convertTouchToNodeSpace:touch];
    for( UITouch *touch in touches ) {
		CGPoint location = [touch locationInView: [touch view]];
		
		location = [[CCDirector sharedDirector] convertToGL: location];
        locationBegin = location;
        [self selectSpriteForTouch:location];
    CCLOG(@"touchbegin");
    }
    return TRUE;
}

- (void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    //CGPoint touchLocation = [self convertTouchToNodeSpace:touch];
    for( UITouch *touch in touches ) {
    CGPoint touchLocation = [touch locationInView: [touch view]];
    
    touchLocation = [[CCDirector sharedDirector] convertToGL: touchLocation];
    
    CGPoint oldTouchLocation = [touch previousLocationInView:touch.view];
    oldTouchLocation = [[CCDirector sharedDirector] convertToGL:oldTouchLocation];
    //oldTouchLocation = [self convertToNodeSpace:oldTouchLocation];
    
    CGPoint translation = ccpSub(touchLocation, oldTouchLocation);
    [self panForTranslation:translation];
    }
}

//Use boundLayerPos to check boundary conditions
- (CGPoint)boundLayerPos:(CGPoint)newPos {
    CGSize winSize = [CCDirector sharedDirector].winSize;
    CGPoint retval = newPos;
    retval.x = MIN(retval.x, 0);
    retval.x = MAX(retval.x, -background.contentSize.width+winSize.width);
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
              selSprite.b2Body->GetPosition().x * PTM_RATIO,
              selSprite.b2Body->GetPosition().y * PTM_RATIO);
               
    } else {
        CGPoint newPos = ccpAdd(self.position, translation);
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
