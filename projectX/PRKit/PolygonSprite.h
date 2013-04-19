//
//  PolygonSprite.h
//  project-x
//
//  Created by WK on 4/5/13.
//  Copyright StreamStan 2013. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "Box2D.h"
#import "PRFilledPolygon.h"

#define PTM_RATIO 32

@interface PolygonSprite : PRFilledPolygon {
    b2Body *_body;
    BOOL _original;
    b2Vec2 _centroid;
    BOOL _sliceEntered;
    BOOL _sliceExited;
    b2Vec2 _entryPoint;
    b2Vec2 _exitPoint;
    double _sliceEntryTime;
}

@property(nonatomic,assign)b2Body *body;
@property(nonatomic,readwrite)BOOL original;
@property(nonatomic,readwrite)b2Vec2 centroid;
@property(nonatomic,readwrite)BOOL sliceEntered;
@property(nonatomic,readwrite)BOOL sliceExited;
@property(nonatomic,readwrite)b2Vec2 entryPoint;
@property(nonatomic,readwrite)b2Vec2 exitPoint;
@property(nonatomic,readwrite)double sliceEntryTime;



-(id)initWithTexture:(CCTexture2D*)texture body:(b2Body*)body original:(BOOL)original;
-(id)initWithFile:(NSString*)filename body:(b2Body*)body original:(BOOL)original;
+(id)spriteWithFile:(NSString*)filename body:(b2Body*)body original:(BOOL)original;
+(id)spriteWithTexture:(CCTexture2D*)texture body:(b2Body*)body original:(BOOL)original;
-(id)initWithWorld:(b2World*)world;

//*******************************  Added by wk  ******************************
//We can use this method to add sprite at where we want
//************************************************************************
-(id)initWithWorld:(b2World *)world at:(CGPoint)p;

+(id)spriteWithWorld:(b2World*)world;
-(b2Body*)createBodyForWorld:(b2World*)world position:(b2Vec2)position rotation:(float)rotation vertices:(b2Vec2*)vertices vertexCount:(int32)count density:(float)density friction:(float)friction restitution:(float)restitution;
//*******************************  Added by wk  ******************************
//Create globular body
-(b2Body*)createGlobularBodyForWorld:(b2World *)world position:(b2Vec2)position rotation:(float)rotation  radius:(float)radius density:(float)density friction:(float)friction restitution:(float)restitution;

-(void)activateCollisions;
-(void)deactivateCollisions;




@end
