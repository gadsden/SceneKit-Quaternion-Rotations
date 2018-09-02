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
        if let hit = hitResults.first, hit.node == sphere {
            // retrieved the first clicked object
            touchedObject = sphere
            let worldTouch = simd_float3(hit.worldCoordinates)
            let localTouch = simd_float3(hit.localCoordinates)
        
            switch recognizer.state{
            case .began:
                updateQueue.async {
                    switch self.mode{
                    case .inertialApplePhysics:
                        self.touchedObject?.previousTouch = localTouch
                    default:
                        self.touchedObject?.previousTouch = worldTouch
                    }
                }
                
            case .changed:
                updateQueue.async {
                    if let touchedObject = self.touchedObject,
                        var previousTouch = touchedObject.previousTouch{
                        
                        switch self.mode{
                        case .quaternion  :
                            let currentTouch = self.sphereAnchor.simdConvertPosition(worldTouch, from: nil)
                            previousTouch =  self.sphereAnchor.simdConvertPosition(previousTouch, from: nil)

                            self.touchedObject?.rotate(from: previousTouch, to: currentTouch)
                            self.touchedObject?.previousTouch = worldTouch
                        case .inertialHomegrown:
                            let currentTouch = self.sphereAnchor.simdConvertPosition(worldTouch, from: nil)
                            previousTouch =  self.sphereAnchor.simdConvertPosition(previousTouch, from: nil)
                        
                            self.touchedObject?.applyTorque(from:
                                previousTouch, to: currentTouch)
                            self.touchedObject?.previousTouch = worldTouch
                        case .inertialApplePhysics:
                            let oldWorldPosition = hit.node.simdConvertPosition(previousTouch, to: nil)
                            let newWorldPosition = hit.node.simdConvertPosition(localTouch, to: nil)
                            
                            self.touchedObject?.previousTouch = localTouch
                            self.sphereAnchor.applyTorque(startLocation: oldWorldPosition, endLocation: newWorldPosition)
                            
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
