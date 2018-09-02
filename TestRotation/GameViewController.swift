//
//  GameViewController.swift
//  TestRotation
//
//  Created by Jacob Waechter on 8/20/18.
//  Copyright © 2018 Jacob Waechter. All rights reserved.
//

import UIKit
import QuartzCore
import SceneKit

enum RotationMode: Int{
    case quaternion, inertialHomegrown, inertialApplePhysics
}

class GameViewController: UIViewController {
    
    @IBOutlet weak var scnView: SCNView!
    @IBOutlet weak var modeSelector: UISegmentedControl!
    
    let sphere = VirtualObject()
    /// parent object for sphere
    let sphereAnchor = SCNNode()
    /// last obect touched in pan gesture (we only have one)
    var touchedObject: VirtualObject?
    
    var previousScale = simd_float3()
    
    let updateQueue = DispatchQueue(label: "update queue")
    
    /// get rotation mode from mode selector control
    var mode: RotationMode = .quaternion
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // create a new scene
        let scene = SCNScene()
        
        // create and add a camera to the scene
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        scene.rootNode.addChildNode(cameraNode)
        
        // place the camera
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 2)
        
        // create and add a light to the scene
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = .omni
        lightNode.position = SCNVector3(x: 0, y: 10, z: 10)
        scene.rootNode.addChildNode(lightNode)
        
        // create and add an ambient light to the scene
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = .ambient
        ambientLightNode.light!.color = UIColor.darkGray
        scene.rootNode.addChildNode(ambientLightNode)
        
        // create a sphere that we are going to rotate
        let radius = Float(0.1524) //6 inches
        let mass = Float(0.8) // 0.8 kg
        
        sphere.geometry = SCNSphere(radius: CGFloat(radius))
        sphere.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "world")
        sphere.geometry?.firstMaterial?.lightingModel = .physicallyBased
        sphere.geometry?.firstMaterial?.metalness.contents = 0.5
        
        // hollow sphere with 0.8kg and 12 inches diameter
        sphere.simplePhysicsBody = SimplePhysicsBody(mass: mass, radius: radius)
        ///
        //sphere.addChildNode(Axis())
        //sphere.opacity = 0.3
        
        ///
        // add Apple physicsBody for comparison
        let physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(node: sphere, options: [:]))
        physicsBody.isAffectedByGravity = false
        sphereAnchor.physicsBody = physicsBody
        sphere.physicsBody?.mass = CGFloat(mass)
        
        sphereAnchor.addChildNode(sphere)
        scene.rootNode.addChildNode(sphereAnchor)
        
        scnView.delegate = self
        // so that we keep receiving calls to updateAtTime
        scnView.isPlaying = true
        
        // set the scene to the view
        scnView.scene = scene
        
        // allows the user to manipulate the camera
        scnView.allowsCameraControl = false
        
        // show statistics such as fps and timing information
        scnView.showsStatistics = true
        
        scnView.debugOptions = [
            //.showPhysicsShapes,
        ]
        
        // configure the view
        scnView.backgroundColor = UIColor.black
        
        // add pan gesture recognizer to rotate
        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        scnView.addGestureRecognizer(panRecognizer)
        
        // add pinch gesture recognizer to zoom
        let pinchRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        scnView.addGestureRecognizer(pinchRecognizer)
        
        //add target method for mod selection change
        self.modeSelector.addTarget(self, action: #selector(rotationModeChanged), for: .valueChanged)
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }
    
    @objc func rotationModeChanged(sender: UISegmentedControl){
        self.mode = RotationMode(rawValue: sender.selectedSegmentIndex) ?? .quaternion
        self.clear()
        self.touchedObject?.simplePhysicsBody?.angularVelocity = simd_float3()
        
        if self.mode == .inertialApplePhysics{
            sphereAnchor.physicsBody?.resetTransform()
        }else{
            // we applied torque to sphereAnchor, so reset it
            // and rotate the sphere to compensate
            updateQueue.async {
                self.sphereAnchor.physicsBody?.clearAllForces()
                let anchorOrientation = self.sphereAnchor.presentation.simdOrientation
                self.sphereAnchor.simdOrientation = simd_quatf()
                self.sphere.simdOrientation = anchorOrientation *  self.sphere.simdOrientation
            }
        }
    }
}


