//
//  contactListener.h
//  project-x--test
//  Created by Stream on 4/5/13.
//  Copyright (c) 2013 StreamStan. All rights reserved.
//

#import "Box2D.h"
#import <vector>
#import <algorithm>

struct MyContact {
    b2Fixture *fixtureA;
    b2Fixture *fixtureB;
    bool operator==(const MyContact& other) const
    {
        return (fixtureA == other.fixtureA) && (fixtureB == other.fixtureB);
    }
    };
    
    class contactListener : public b2ContactListener {
        
    public:
        std::vector<MyContact>_contacts;
        
        contactListener();
        ~contactListener();
        
        virtual void BeginContact(b2Contact* contact);
        virtual void EndContact(b2Contact* contact);
        virtual void PreSolve(b2Contact* contact, const b2Manifold* oldManifold);
        virtual void PostSolve(b2Contact* contact, const b2ContactImpulse* impulse);
        
    };
