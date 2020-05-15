/*:
 # GravityPlayground
 
 You probably know gravity by the phenomena that keeps us pulled down to the ground.
 But if you change your perspective, it is responsible for much more in our universe.
 In this Playground, we will deal with how gravity enables satellites to orbit around
 a planet.
 
 Created by Bradley Klemick in May 2020.
 
 ## Circular Orbit
 Your task is to create a satellite and put it in circular orbit around a central planet.
 Understanding the mathematical equations behind gravity will help you.
 
 For an object to move in a circular fashion, it must have a centripetal force
 compelling it to do so. a = (v^2)/r
 
 According to Newton's Unversal Law of Gravitation our centripetal gravitational
 force will be: a = Gm/(r^2)
 
 By setting these equations equal to each other: v^2 = Gm/r, or v  = sqrt(Gm/r).
 
 Let's take our example satellite that begins at 200 meters above the planet.
 Constant G is approximately 6.674 * 10^-11. The planet's mass is precalculated
 to be 1.49835181 * 10^16 so we can deal with nice numbers. Plugging in:
 
 v = sqrt((6.674e-11) (1.498e16) / (200)) = sqrt(1000000 / (100 * 2)) = 100 / sqrt(2)
 
 So that is the initial velocity the satellite must move tangential to the planet in order
 to have a circular orbit around the planet- it has already been plugged into the code.
 A different velocity would result in an elliptical orbit, or worse, the satellite crashing
 down into the planet or flying off into space.
 
 ## Relevant functions and parameters
 
 `scene.makePlanet`
 * `x`: horiztonal offset from screen center in meters
 * `y`: vertical offset from screen center in meters
 * `mass`: the mass in kg, which determines the gravity strength
 * `radius` (optional): a custom radius of this planet in meters
 
 `scene.makeSatellite`
 * `x`: horiztonal offset from screen center in meters
 * `y`: vertical offset from screen center in meters
 * `dx`: horizontal initial velocity in m/s
 * `dy`: vertical initial velocity in m/s
 * `radius` (optional): a custom radius of this planet in meters
 
 ## Bonus Tasks
 Once you successfully create a circular orbit, you can continue experimenting with
 gravity by adding more planets and/or satellites and modifying their properties.
 Here are some ideas:
 
 * Try purposely creating a satellite with an elliptical orbit, which represents how the
 Earth orbits the sun. This is done by setting a lower initial velocity than circular orbit,
 but not so low that the satellite crashes into the planet. Notice how the satellite's velocity
 fluctuates as it moves.
 
 * Try placing two planets at (-100, 0) and (100, 0); then create a satellite at (0, 200).
 
 * Place several satellites around one central planet with different orbits without making
 them collide. Design your own satellite system!
 
 * You can try dragging around planets and satellites as well to see how they react,
 though doing so is less precise than through code!
 */

//#-hidden-code

import PlaygroundSupport
import SpriteKit

public class TappableNode: SKNode {
    // Percent to move by closer to targetPos per frame
    private static let dragSpeed: CGFloat = 0.04
    
    // The position we're moving toward if dragged
    private var targetPos: CGPoint?
    
    // Whether this node was dynamic before being dragged
    private var wasDynamic: Bool?
    
    /**
     A touch has started, so freeze, and store the previous state
     */
    public func pauseVelocity() {
        if let physics = physicsBody {
            wasDynamic = physics.isDynamic
            targetPos = position
            physics.isDynamic = false
        }
    }
    
    /**
     Reset the target position if touch has moved
     */
    public func retarget(toPosition: CGPoint) {
        targetPos = toPosition
    }
    
    /**
     Step closer to the target if this node is being dragged
     */
    public func updatePosition() {
        if let targetPos = targetPos {
            // Every frame, get a set percentage closer to target
            position = CGPoint(x: position.x + (targetPos.x - position.x) * TappableNode.dragSpeed, y: position.y + (targetPos.y - position.y) * TappableNode.dragSpeed)
        }
    }
    
    /**
     Restore the previous state and apply velocity based on current distance from targetPos.
     */
    public func resumeVelocity() {
        if let physics = physicsBody,
            let dynamic = wasDynamic,
            let target = targetPos {
            physics.isDynamic = dynamic
            let releaseFactor = 40 * TappableNode.dragSpeed
            physics.velocity = CGVector(dx: (target.x - position.x) * releaseFactor, dy: (target.y - position.y) * releaseFactor)
            wasDynamic = nil
            targetPos = nil
        }
    }
    
    /**
     Return the current velocity vector
     */
    public var velocity: CGVector {
        physicsBody?.velocity ?? CGVector.zero
    }
    
    /**
     Return the current speed, which is the scalar equivalent of velocity
     */
    public var currentSpeed: CGFloat {
        sqrt(pow(velocity.dx, 2) + pow(velocity.dy, 2))
    }
}

public class Planet: TappableNode {
    /**
     Create a Planet, a generic SKNode with some children.
     * `position`: The CGPoint in scene-relative units
     * `mass`: The SpriteKit "strength" factor to use for this planet
     * `radius`: A parameters that allows overriding the default radius of 48
     */
    public init(position: CGPoint, mass: Double, radius: Double?) {
        super.init()
        self.position = position
        
        // Used customized radius or default
        let radius = radius ?? 48
        
        // Create the sprite
        let size = CGSize(width: radius * 2, height: radius * 2)
        let sprite = SKSpriteNode(texture: SKTexture(imageNamed: "earth.png"), size: size)
        addChild(sprite)
        
        // Create an oscillating color effect
        sprite.color = UIColor.blue
        sprite.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.colorize(withColorBlendFactor: 0.2, duration: 1.75),
            SKAction.colorize(withColorBlendFactor: 0, duration: 1)
        ])))
        
        // Create the gravity field
        let field = SKFieldNode.radialGravityField()
        field.falloff = 2
        field.strength = Float(mass)
        addChild(field)
        
        // Create the static physics body
        let physics = SKPhysicsBody(circleOfRadius: CGFloat(radius))
        physics.isDynamic = false
        physicsBody = physics
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public class Satellite: TappableNode {
    // A reference to the label under this satellite for updating
    private var labelNode: SKLabelNode!
    
    /**
     Create a Satellite, a generic SKNode with some children.
     * `position`: The CGPoint in scene-relative units
     * `velocity`: A CGVector in scene points of the satellite's initial velocity
     * `scene`: The scene that should be the targetNode of the trace emitter
     * `radius`: A parameters that allows overriding the default random radius
     */
    public init(position: CGPoint, velocity: CGVector, scene: SKScene, radius: Double?) {
        super.init()
        self.position = position
        
        // Choose a random radius for a little variety
        let radius = radius ?? Double.random(in: 13...21)
        
        // Create the sprite
        let size = CGSize(width: radius * 2, height: radius * 2)
        let sprite = SKSpriteNode(texture: SKTexture(imageNamed: "moon.png"), size: size)
        addChild(sprite)
        
        // Create the info label
        labelNode = SKLabelNode()
        labelNode.fontSize = 19
        labelNode.color = UIColor(white: 1.0, alpha: 1/3)
        labelNode.position = CGPoint(x: 0, y: -16 - radius)
        addChild(labelNode)
        
        // Create the particle emitter for orbit tracing
        if let emitter = SKEmitterNode(fileNamed: "TraceParticle") {
            emitter.targetNode = scene
            emitter.particleZPosition = -1
            addChild(emitter)
        }
        
        // Create the dynamic physics body
        let physics = SKPhysicsBody(circleOfRadius: CGFloat(radius))
        physics.velocity = velocity
        physics.friction = 0
        physics.angularDamping = 0
        physics.linearDamping = 0
        physics.mass = 1
        physics.restitution = 0.6
        physics.allowsRotation = false
        physics.contactTestBitMask = physics.collisionBitMask
        physicsBody = physics
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func setText(_ newText: String) {
        labelNode.text = newText
    }
}

public class GameScene: SKScene, SKPhysicsContactDelegate {
    /**
     The Universal Gravitational Constant G
     */
    private static let gravitationConstant: Double = 6.674e-11
    
    /**
     Number of simulated meters per each point, the unit used by SpriteKit
     */
    private static let metersPerPoint: Double = 1
    
    /**
     Number of real meters per "physics engine meter" in mass gravity calculation
     */
    private static let metersPerEngineMeters: Double = 150 * metersPerPoint
    
    // Non-nil if a node is currently being dragged
    private var tappedNode: TappableNode?
    
    // Count of rendered frames to execute only every x frames
    private var frameCnt: Int = 0
    
    // A function can be set from outside and is called several times per second
    public var quickUpdate: ((GameScene) -> ())?
    
    // Mutable private lists of Planets and Satellites
    private var _planets = [Planet]()
    private var _satellites = [Satellite]()
    
    /**
     The list of created Planets
     */
    public var planets: [Planet] {
        _planets
    }
    
    /**
     The list of created Satellites
     */
    public var satellites: [Satellite] {
        _satellites
    }
    
    /**
     Add and return a Planet at position (x, y) m and mass in kg.
     */
    public func makePlanet(x: Double, y: Double, mass: Double, radius: Double? = nil) -> SKNode {
        let planet = Planet(position: CGPoint(x: x, y: y), mass: mass * GameScene.gravitationConstant / pow(GameScene.metersPerEngineMeters, 3), radius: radius)
        addChild(planet)
        _planets.append(planet)
        return planet
    }
    
    /**
     Add and return a Satellite at position (x, y) m and initial velocity (dx, dy) m/s.
     */
    public func makeSatellite(x: Double, y: Double, dx: Double, dy: Double, radius: Double? = nil) -> SKNode {
        let satellite = Satellite(position: CGPoint(x: x, y: y), velocity: CGVector(dx: dx, dy: dy), scene: self, radius: radius)
        addChild(satellite)
        _satellites.append(satellite)
        return satellite
    }
    
    // MARK: SKScene
    
    public override func didMove(to view: SKView) {
        physicsWorld.contactDelegate = self
    }
    
    @objc public static override var supportsSecureCoding: Bool {
        // SKNode conforms to NSSecureCoding, so any subclass going
        // through the decoding process must support secure coding
        get {
            return true
        }
    }
    
    // MARK: SKPhysicsContactDelegate
    
    public func didBegin(_ contact: SKPhysicsContact) {
        // If a satellite crashes into a Planet, halt its motion
        if let _ = (contact.bodyA.node as? Planet) ?? (contact.bodyB.node as? Planet),
            let satellite = (contact.bodyA.node as? Satellite) ?? (contact.bodyB.node as? Satellite) {
            satellite.physicsBody?.velocity = CGVector.zero
        }
    }
    
    // MARK: Touch handling
    
    private func touchDown(atPoint pos: CGPoint) {
        // Find the parent of the tapped ShapeNode
        if let tapped = self.nodes(at: pos).filter({(node) in
            node is SKSpriteNode && node.parent is TappableNode
        }).first?.parent as? TappableNode {
            tapped.pauseVelocity()
            tappedNode = tapped
        }
    }
    
    private func touchMoved(toPoint pos: CGPoint) {
        tappedNode?.retarget(toPosition: pos)
    }
    
    private func touchUp(atPoint pos: CGPoint) {
        tappedNode?.resumeVelocity()
        tappedNode = nil
    }
    
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { touchDown(atPoint: t.location(in: self)) }
    }
    
    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { touchMoved(toPoint: t.location(in: self)) }
    }
    
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { touchUp(atPoint: t.location(in: self)) }
    }
    
    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { touchUp(atPoint: t.location(in: self)) }
    }
    
    public override func update(_ currentTime: TimeInterval) {
        // If a node is tapped, step its position closer to the target
        tappedNode?.updatePosition()
        
        // Call quickUpdate() only every 6th frame to save CPU time
        self.frameCnt += 1
        if self.frameCnt % 6 == 1 {
            quickUpdate?(self)
        }
    }
}

let sceneView = SKView(frame: CGRect(x: 0, y: 0, width: 640, height: 640))
guard let scene = GameScene(fileNamed: "GameScene") else {
    exit(1)
}
scene.scaleMode = .aspectFill
sceneView.isMultipleTouchEnabled = false
sceneView.presentScene(scene)
PlaygroundSupport.PlaygroundPage.current.liveView = sceneView

//#-end-hidden-code

//#-editable-code

// A central planet
scene.makePlanet(x: 0, y: 0, mass: 1.49835181e16)

// An example circular orbiting satellite, as described above
scene.makeSatellite(x: 0, y: 200, dx: 100 / sqrt(2), dy: 0)

// An example elliptical orbiting satellite
scene.makeSatellite(x: -100, y: -100, dx: -54, dy: 54)



// Insert code here to execute several times per second
scene.quickUpdate = {(scene) in
    // Update the velocity label on each Satellite
    scene.satellites.forEach({(satellite) in
        satellite.setText(satellite.currentSpeed >= 1 ? String(format: "%.0f m/s", satellite.currentSpeed) : "")
    })
}
//#-end-editable-code
