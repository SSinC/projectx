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

//Pixel to metres ratio. Box2D uses metres as the unit for measurement.
//This ratio defines how many pixels correspond to 1 Box2D "metre"
//Box2D is optimized for objects of 1x1 metre therefore it makes sense
//to define the ratio so that your most common object type is 1x1 metre.
#define PTM_RATIO 32

//添加userData 结合贴图和物体编号，方便使用
//typedef struct userdata{
//    int bodyType;
//    CCPhysicsSprite *sprite;
//}myUserData;

// HelloWorldLayer
@interface HelloWorldLayer : CCLayer <GKAchievementViewControllerDelegate, GKLeaderboardViewControllerDelegate>
{
	CCTexture2D *spriteTexture_;	// weak ref
	b2World* world;					// strong ref
	GLESDebugDraw *m_debugDraw;		// strong ref
    
    CCSprite * background;
    CCPhysicsSprite * selSprite;
    PolygonSprite *selSprite1;
    NSMutableArray * movableSprites;
    contactListener *_contactListener;
    CCSpriteBatchNode *parent;
    CGPoint locationBegin;
    
    //added copy_chooseBodyNumber to choose body type
    __block int copy_chooseBodyNumber;
    
    //add explodeing center
    float explosionX;
    float explosionY;
    float explosionRadius ;
    NSMutableDictionary *enterPoints;
    NSMutableArray *explodingBodies;
    
    //add tagBody to create uniqe Body ID
    int32 tagBodyA;
    int32 tagBodyB;
    
    //add rayCastCallBack
    RaycastCallback *_raycastCallback;
    
     CCArray *_cache;
    
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
 areVerticesAcceptable: 目前，此方法假设所有的顶点都是合理的。
 ********************************************************/
-(b2Vec2*)arrangeVertices:(b2Vec2*)vertices count:(int)count;
-(void)splitPolygonSprite:(PolygonSprite*)sprite;
-(BOOL)areVerticesAcceptable:(b2Vec2*)vertices count:(int)count;
-(b2Body*)createBodyWithPosition:(b2Vec2)position rotation:(float)rotation vertices:(b2Vec2*)vertices vertexCount:(int32)count density:(float)density friction:(float)friction restitution:(float)restitution;

@end
