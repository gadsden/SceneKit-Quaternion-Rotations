//
//  GameViewController+SCNSceneRendererDelegate .swift
//  TestRotation
//
//  Created by Jacob Waechter on 8/29/18.
//  Copyright © 2018 Jacob Waechter. All rights reserved.
//

import SceneKit

// MARK: - SCNSceneRendererDelegate methods
extension GameViewController: SCNSceneRendererDelegate{
    
    /// called 60 times per second
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        
        if mode == .inertialHomegrown{
            if let to = self.touchedObject,
                var phB = to.simplePhysicsBody{
                if let rotationQuaternion = phB.rotation(for: time){
                    // multiply rotationQuaternion by
                    // current orientaion to get new orientation
                    to.simdOrientation = rotationQuaternion * to.presentation.simdOrientation
                }
                // update simplePhysicsBody
                to.simplePhysicsBody = phB
            }
        }
    }
}
