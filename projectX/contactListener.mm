//
//  contactListener.m
//  project-x
//
//  Created by Stream on 4/5/13.
//  Copyright (c) 2013 StreamStan. All rights reserved.
//

#import "contactListener.h"

contactListener::contactListener() : _contacts() {
}

contactListener::~contactListener() {
}

void contactListener::BeginContact(b2Contact* contact) {
    // We need to copy out the data because the b2Contact passed in
    // is reused.
    MyContact myContact = { contact->GetFixtureA(), contact->GetFixtureB() };
    _contacts.push_back(myContact);
}

void contactListener::EndContact(b2Contact* contact) {
    MyContact myContact = { contact->GetFixtureA(), contact->GetFixtureB() };
    std::vector<MyContact>::iterator pos;
    pos = std::find(_contacts.begin(), _contacts.end(), myContact);
    if (pos != _contacts.end()) {
        _contacts.erase(pos);
    }
}

void contactListener::PreSolve(b2Contact* contact, const b2Manifold* oldManifold) {
}

void contactListener::PostSolve(b2Contact* contact, const b2ContactImpulse* impulse) {
}

