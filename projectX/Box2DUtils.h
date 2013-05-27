//
//  Box2DUtils.h
//  projectX
//
//  Created by Stream on 5/27/13.
//  Copyright (c) 2013 StreamStan. All rights reserved.
//

#ifndef Box2DUtils_h
#define Box2DUtils_h
#include "Box2D.h"
class Box2DUtils
{
    public:
    static void PhysExplosion(b2World *world, const b2Vec2 &pos, float radius, float force);
};
#endif
