# SceneKit-Quaternion-Rotations

## ABOUT
Illustrates pan gesture rotaions in SceneKit using quaternions and simulated physics for inertial rotation.


## Simple Rotations

SCNNode includes animatable property simdOrientation: simd_quatf
The node’s orientation, expressed as a rotation angle about an axis.

simd_quatf is a simd_float4 vector where first 3 components x, y, z represent the axis of rotation, and 
the last one an angle of rotation in radians.
There is a convenent initializer to create simd_quatf(angle: Float, axis: float3).

Quaternions can be used to represent any rotation as an angle and an axis. 
A unit quaternion is a quaternin with the norm of 1.
If we could convert the motion of a finger on screen to a unit quaternion (call it newRotation), we could easily rotate 
a node by multiplying newRotation * simdOrientation, and assigning this value back to it's simdOrientation:
```swift
let newRotation: simd_quatf...
node.simdOrientation = newRotation * node.simdOrientation
```

How do we obtain newRotation from pan gesture?

We will need to figure out what the axis and angle of our rotation are so
that we can call:
```swift
let newRotation: simd_quatf = simd_quatf(angle: Float, axis: float3)
```

For simplicity we will use a sphere and attempt to rotate it about it's center.

What we will need is two vectors representing the start and end of the gesture:
A vector from the center of the sphere to a point on it's surface where we first touched the finger (start: sim_float3),
and another one from it's center to the point on it's surface where gesture ended (end: simd_float3).

In the pan gesture recognizer, get world cordinates of the point where finger touched the sphere:

```swift
let scnView = recognizer.view as! SCNView
let p = recognizer.location(in: scnView)
let hitResults = scnView.hitTest(p, options: [:])
if let hit = hitResults.first{
    let worldTouch = simd_float3(result.worldCoordinates)
    ...
}
```
We need a vector from the point we want to rotate about to the point on the surface.
If we are rotating sphere about it's origin, our pivot is at simd_float(0, 0, 0)
(center of the sphere in it's local coordinates).
So our touch vector is just worldTouch converted to local sphere coordinates:
```swift
var touch = sphere.simdConvertPosition(worldTouch, from: nil)
```

In recognizer state .began we calculate touch and save it as a start vector.
Then at each .changed state we calculate touch again and
use the new touch as end vector.
 
We can get the axis as a cross product of these vectors:
```swift
let axis = simd_cross(end, start)
```

If both start and end are unit vectors, then their dot product is a cosine of the angle between them.
```swift
let endNorm = simd_normalize(end)
let startNorm = simd_normalize(start)
let angle = acosf(simd_dot(endNorm, startNorm))
```

Now we have both angle and axis, and we can construct rotation quaternion.
It's importnat to note that rotation quaternion must be a unit quaternion, so we need to make sure that 
the axis is a unit vector:
```swift
let newRotation: simd_quatf = simd_quatf(angle: angle, axis: simd_normalize(axis))
```
Now we can rotate our node:
//start touch from prevous example
node.simdOrientation = newRotation * node.simdOrientation

Finally, we update start vector to the new touch:
```swift
start = touch
```

## Inertial Rotations

To make it more realistic , we can rotate the sphere by simulating torque.
Torque is defined as cross product between force applied and lever arm vector.
For a sphere lever arm vector is a vector from the center to the point on the surface where
force is applied, and force in our case can be the vector between two points on the surface, from where gesture started to where it ended.
```swift
//start touch from prevous example
let leverArm: simd_float3 = start 
//end touch from prevous example
let force: simd_float3 = end - start
let torque = simd_cross(leverArm, force)
```
We can calculate angular acceleration (in radians per second) from torque:
```swift
let angularAcceleration = torque / momentOfInertia
```
Moment of inertia is a tensor, experessed as a 3x3 matrix, but fortunately for the hollow sphere it's a scalar:
```swift
let momentOfInertia = 2 * mass * pow(radius, 2))/3
```
We will store current angularVelocity and current angularAcceleration in a struct SimplePhysicsBody,
attached to the sphere node:
```swift
struct SimplePhysicsBody{
    
    var mass = Float(1)
    var radius = Float(1)
    
    /// Moment of inertia for hollow sphere
    lazy var momentOfInertia: Float = {
        return (2 * mass * pow(radius, 2))/3
    }()
    
    var angularAcceleration = simd_float3()
    var angularVelocity = simd_float3()
    
    /// last time angularVelocity and angularAcceleration were updated
    var lastUpdated: TimeInterval?
}
```
As finger moves over the sphere we use pan gesture recognzer to calculate end and start vector
like in the prevous example, then calculate torque and angularAcceleration.
Then save angularAcceleration in sphere's SimplePhysicsBody.

SCNSceneRendererDelegate contains 
```swift
func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval)
``` 
that is called for each frame (approximately 60 times per second)

Inside this method we can calculate changes to angular velocity at each time interval:
```swift
//get time interval
let timeInterval = Float(time - previousTime)
// 1. Calculate new angular velocity
var ω = self.angularVelocity
//decay angular velocity by 2% in every frame
ω -= ω * 0.02
// apply angular acceleration
// calculate the fraction of angular acceleration
// to be applied at this time interval, and
// update angular velocity
ω += self.angularAcceleration * timeInterval
```
Now all that's left is to calculate how much was the shpere supposed to rotate 
during the time interval. It can be expressed as a unit quaternion with
axis parallel to the axis of angular velocity vector, and angle a fraction of this vector's magnitude
during the time interval:
```swift
let ωl = simd_length(ω)
// axis as unit quaternion
let axis = simd_normalize(ω)
// calculate fraction of rotation
// for this time interval
let angle = ωl * timeInterval
rotationQuaternion = simd_quaternion(angle, axis)
```
That's it, we can now multiply rotationQuaternion by the current sphere orientation,
to get it to rotate where the torque takes it:
```swift
sphere.simdOrientation = rotationQuaternion * sphere.presentation.simdOrientation
```

## Evolution of the project

### Version 1.0









