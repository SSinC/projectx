//
//  Box2DUtils.cpp
//  projectX
//
//  Created by Stream on 5/27/13.
//  Copyright (c) 2013 StreamStan. All rights reserved.
//

#include "Box2DUtils.h"
#include <set>
class ExplosionQueryCallback : public b2QueryCallback
{
    private:
            b2Vec2 m_pos;
            float m_radius;
    public:
    
    ExplosionQueryCallback(const b2Vec2 &pos, float radius)
    {
        m_pos = pos;
        m_radius = radius;
    }
    
    bool ReportFixture(b2Fixture* fixture)
    {
        b2Body* body = fixture->GetBody();
        if (body->GetType() == b2_dynamicBody && !fixture->IsSensor() && !IsContain(body))
        {
            b2CircleShape circle;
            circle.m_radius = m_radius;
            circle.m_p = m_pos;
            b2Transform t;
            t.SetIdentity();
            
            if (b2TestOverlap(&circle,0, fixture->GetShape(),0, t, body->GetTransform()))
                QueryResult.insert(body);
        }
        return true;
    }
    bool IsContain(b2Body* body)
    {
        std::set<b2Body*>::iterator pos;
        pos = QueryResult.find(body);
        return pos != QueryResult.end();
    }
    public:
    std::set<b2Body*> QueryResult;
    
    
};

void Box2DUtils::PhysExplosion(b2World *world, const b2Vec2 &pos, float radius, float force)
{
    b2AABB aabb;
    aabb.lowerBound.Set(pos.x-radius, pos.y-radius);
    aabb.upperBound.Set(pos.x+radius, pos.y+radius);
    ExplosionQueryCallback callback(pos,radius);
    world->QueryAABB(&callback, aabb);
    
    b2Vec2 hitVector;
    float hitForce;
    float distance;
    std::set<b2Body*>::iterator iter;
    for (iter = callback.QueryResult.begin(); iter != callback.QueryResult.end(); ++iter)
    {
        b2Body* effectBody = (*iter);
        b2Vec2 bodyPos = effectBody->GetWorldCenter();
        hitVector = (bodyPos-pos);
        distance = hitVector.Normalize(); //Makes a 1 unit length vector from HitVector, while getting the length.
        hitForce = (radius-distance)*force; //TODO: This is linear, but that's not realistic.
        effectBody->ApplyLinearImpulse(hitForce * hitVector, effectBody->GetWorldCenter());
        
    }
    
}


/*
 - (void) ccTouchEnded:(UITouch*)touch withEvent:(UIEvent*)event
 {
 CGPoint nodePosition = [self convertTouchToNodeSpace:touch];
 Box2DUtils::PhysExplosion(world, b2Vec2(nodePosition.x / PTM_RATIO, nodePosition.y /PTM_RATIO), 5, 100);
 }
 */
