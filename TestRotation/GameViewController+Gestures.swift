//
//  GameViewController+Gestures.swift
//  TestRotation
//
//  Created by Jacob Waechter on 8/23/18.
//  Copyright © 2018 Jacob Waechter. All rights reserved.
//

import SceneKit

extension GameViewController{
    @objc func handlePan(_ recognizer: UIPanGestureRecognizer){
        let scnView = recognizer.view as! SCNView
        
        // check what we tapped
        let p = recognizer.location(in: scnView)
        let hitResults = scnView.hitTest(p, options: [:])
        // check that we clicked on at least one object
        if hitResults.count > 0 {
            // retrieved the first clicked object
            let result = hitResults[0]
            var newTouch = simd_float3()
            let worldTouch = simd_float3(result.worldCoordinates)
            if result.node == sphere{
                touchedObject = sphere
            }
            
            if touchedObject == sphere{
                newTouch = sphereAnchor.simdConvertPosition(worldTouch, from: nil)
            }
            
            switch recognizer.state{
            case .began:
                updateQueue.async {
                    self.touchedObject?.previousTouch = simd_normalize(newTouch)
                }
                
            case .changed:
                updateQueue.async {
                    if let touchedObject = self.touchedObject,
                        let previousTouch = touchedObject.previousTouch{
                        let currentTouch = simd_normalize(newTouch)
                        switch self.mode{
                        case .quaternion  :
                            self.touchedObject?.rotate(from: previousTouch, to: currentTouch)
                        case .inertialHomegrown:
                            self.touchedObject?.applyTorque(from:
                                previousTouch, to: currentTouch)
                        default:
                            break
                        }
                    }
                }
            case .ended:
                clear()
            default: break
            }
            
        }else{
            clear()
        }
    }
    
    /// Called when finger left the object
    /// or pan gesture eneded.
    /// we want to set prevoiousTouch to nil
    /// and angular acceleration to zero
    internal func clear(){
        updateQueue.async {
            self.touchedObject?.previousTouch = nil
            self.touchedObject?.simplePhysicsBody?.angularAcceleration = simd_float3()
        }
    }
    
    @objc func handlePinch(_ recognizer: UIPinchGestureRecognizer){
        if recognizer.numberOfTouches == 2 {
            let zoom = Float(recognizer.scale)
            if recognizer.state == .began {
                updateQueue.async {
                    self.previousScale = self.sphereAnchor.simdScale
                }
            } else if recognizer.state == .changed {
                let final = previousScale * zoom
                updateQueue.async {
                    SCNTransaction.begin()
                    SCNTransaction.animationDuration = 0.15
                    self.sphereAnchor.simdScale = final
                    SCNTransaction.commit()
                }
            }
        }
    }
}
