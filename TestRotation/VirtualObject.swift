//
//  VirtualObject.swift
//  TestRotation
//
//  Created by Jacob Waechter on 8/25/18.
//  Copyright © 2018 Jacob Waechter. All rights reserved.
//

import SceneKit

/// Container for some useful extra variables
class VirtualObject: SCNNode{
    
    // keeps normalized location of previous touch
    var previousTouch: simd_float3?
    // simple homegrown physics body (when not using SCNPhysicsBody)
    var simplePhysicsBody: SimplePhysicsBody?
   
    override init() {
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func applyTorque(from previousTouch: simd_float3, to currentTouch: simd_float3){
        let previousTouch = simd_normalize(previousTouch)
        let currentTouch = simd_normalize(currentTouch)
        self.simplePhysicsBody?.applyTorque(from: previousTouch, to: currentTouch)
        //self.previousTouch = currentTouch
    }
    
    /// calculates and applies quaternion rotation between two vectors
    /// - parameter previousTouch: normalized previous touch
    /// - parameter currentTouch: normalized curent touch
    func rotate(from previousTouch: simd_float3, to currentTouch: simd_float3){
        //print("changed \(previousTouch) \(currentTouch)")
        let previousTouch = simd_normalize(previousTouch)
        let currentTouch = simd_normalize(currentTouch)
        //make sure to normalize axis to make unit quaternion
        let axis = simd_normalize(simd_cross(currentTouch, previousTouch))
        
        // sometimes dot product goes outside the the range of -1 to 1
        // keep it in the range
        let dot = max(min(1, simd_dot(currentTouch, previousTouch)), -1)
        
        let angle = acosf(dot)
        let rotation = simd_quaternion(-angle, axis)
        
        let length = rotation.length
        if !length.isNaN{
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.15
            self.simdOrientation = rotation * self.simdOrientation
            SCNTransaction.commit()
        }
        //self.previousTouch = currentTouch
    }
}

struct SimplePhysicsBody{
    
    var mass = Float(1.6)
    var radius = Float(0.1524)
    
    /// Moment of inertia for hollow sphere
    lazy var momentOfInertia: Float = {
        return (2 * mass * pow(radius, 2))/3
    }()
    
    var angularAcceleration = simd_float3()
    var angularVelocity = simd_float3()
    
    /// last time angularVelocity and angularAcceleration were updated
    var lastUpdated: TimeInterval?
    
    init(mass: Float, radius: Float){
        self.mass = mass
        self.radius = radius
        self.angularAcceleration = simd_float3()
        self.angularVelocity = simd_float3()
    }
    
    /// Calculates torque between two vectors
    /// - Parameters: normalized vectors
    ///
    /// - Returns: torque: simd_float3?
    func torque(from previousTouch: simd_float3, to currentTouch: simd_float3)->simd_float3?{
        
        let forceVector = currentTouch - previousTouch
        let leverArmVector = previousTouch
        let rotationAxis = simd_cross(leverArmVector, forceVector)
        if !simd_length(simd_normalize(rotationAxis)).isNaN{
            return rotationAxis
        }
        return nil
    }
    
    /// calculate torque and set angularAcceleration from it
    mutating func applyTorque(from previousTouch: simd_float3, to currentTouch: simd_float3){
        
        if let torque = self.torque(from: previousTouch, to: currentTouch){
            self.angularAcceleration  =  torque / self.momentOfInertia
        }
    }
    
    /// calculate rotation quaternion for time inteval from
    /// angular velocity and angular acceleration
    /// update angular velocity and angular accelertion to next value
    mutating func rotation(for time: TimeInterval)->simd_quatf?{
        var rotationQuaternion: simd_quatf?
        if let previousTime = self.lastUpdated{
            let timeInterval = Float(time - previousTime)
            
            // 1. Calculate new angular velocity
            var ω = self.angularVelocity
            //decay angular velocity by 2% in every frame
            ω -= ω * 0.02
            
            // apply angular aceleration
            if !simd_length(self.angularAcceleration).isZero {
                // calculate the fraction of angular acceleration
                // to be applied at this time interval, and
                // update angular velocity
                ω += self.angularAcceleration * timeInterval
            }
            //update to new angular velocity
            self.angularVelocity = ω
            
            // 2. use angular velocity
            // to create a unit quaternion representing
            // rotation in this time interval
            let ωl = simd_length(ω) // magnitude
            if !ωl.isNaN && !ωl.isZero{
                // unit quaternion has axis of length 1
                let axis = simd_normalize(ω)
                // calculate fraction of rotation
                // for this time interval
                let angle = ωl * timeInterval
                rotationQuaternion = simd_quaternion(angle, axis)
            }
        }
        // update time and simplePhysicsBody
        self.lastUpdated = time
        return rotationQuaternion
    }
}

extension SCNNode{
    // the Apple way
    func applyTorque(startLocation: simd_float3, endLocation: simd_float3){
        guard let physicsBody = self.physicsBody else{
            return
        }
        
        let nodeCenterWorld = self.simdConvertPosition(self.simdPosition, to: nil)
        let forceVector = endLocation - startLocation
        let leverArmVector = startLocation - nodeCenterWorld
        let rotationAxis = simd_cross(leverArmVector, forceVector)
        let magnitude = simd_length(rotationAxis)
        // torqueAxis is a unit vector
        var torqueAxis = simd_normalize(rotationAxis)
        if simd_length(torqueAxis).isNaN {
            return
        }
        
        let orientationQuaternion = self.presentation.simdOrientation
        // align torque axis with current orientation
        torqueAxis = orientationQuaternion.act(torqueAxis)
        let torque = SCNVector4(torqueAxis.x, torqueAxis.y, torqueAxis.z, magnitude)
        //print("torque \(torque)")
        physicsBody.applyTorque(torque, asImpulse: true)
    }
}
