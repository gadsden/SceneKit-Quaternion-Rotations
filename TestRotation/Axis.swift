//
//  Axis.swift
//  TestRotation
//
//  Created by Jacob Waechter on 8/30/18.
//  Copyright © 2018 Jacob Waechter. All rights reserved.
//

import SceneKit

class Axis: SCNNode{
    
    let shaft = SCNNode(geometry: SCNCylinder(radius: 0.05, height: 5))
    
    let top = SCNNode(geometry: SCNCone(topRadius: 0, bottomRadius: 0.2, height: 0.1) )
    
    override init() {
        super.init()
        //shaft.pivot
        shaft.geometry?.firstMaterial?.diffuse.contents = UIColor.red
        self.addChildNode(shaft)
        self.addChildNode(top)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
