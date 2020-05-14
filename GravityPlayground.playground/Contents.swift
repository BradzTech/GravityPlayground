/*:
 # GravityPlayground
 
 You probably know gravity by the phenomena that keeps us pulled down to the ground.
 But if you change your perspective, it is responsible for much more in our universe.
 In this Playground, we will deal with how gravity enables satellites to orbit around
 a planet.
 
 ## Your Task
 Your task is to create a satellite and put it in circular orbit around a central planet.
 Understanding the mathematical equations behind gravity will help you.
 
 For an object to move in a circular fashion, it must have a centripetal force
 compelling it to do so. a = (v^2)/r
 
 According to Newton's Unversal Law of Gravitation our centripetal gravitational
 force will be: a = Gm/(r^2)
 
 By setting these equations equal to each other: v^2 = Gm/r, or v  = sqrt(Gm/r).
 
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
 
 * Try purposely creating a satellite with an elliptical orbit; this is more complex but
 represents how the Earth orbits the sun.
 
 * Try placing two planets at (-100, 0) and (100, 0); then create a satellite at (0, 200).
 
 * You can try dragging around planets and satellites as well to see how they react,
 though doing so is less precise than through code!
 */

//#-hidden-code
import PlaygroundSupport
import SpriteKit

public class TappableNode: SKNode {
    private static let dragSpeed: CGFloat = 0.05
    private var targetPos: CGPoint?
    private var wasDynamic: Bool?
    
    public func pauseVelocity() {
        if let physics = physicsBody {
            wasDynamic = physics.isDynamic
            targetPos = position
            physics.isDynamic = false
        }
    }
    
    public func retarget(toPosition: CGPoint) {
        targetPos = toPosition
    }
    
    public func updatePosition() {
        if let targetPos = targetPos {
            // Every frame, get 5% closer to target
            position = CGPoint(x: position.x + (targetPos.x - position.x) * TappableNode.dragSpeed, y: position.y + (targetPos.y - position.y) * TappableNode.dragSpeed)
        }
    }
    
    public func resumeVelocity() {
        if let physics = physicsBody,
            let dynamic = wasDynamic,
            let target = targetPos {
            physics.isDynamic = dynamic
            physics.velocity = CGVector(dx: (target.x - position.x) * 2, dy: (target.y - position.y) * 2)
            wasDynamic = nil
            targetPos = nil
        }
    }
    
    public var velocityString: String {
        if let velo = physicsBody?.velocity {
            let speed = sqrt(velo.dx * velo.dx + velo.dy * velo.dy)
            if speed >= 1 {
                return String(format: "%.0f m/s", speed)
            }
        }
        return ""
    }
}

public class Planet: TappableNode {
    public init(position: CGPoint, mass: Double, radius: Double?) {
        super.init()
        self.position = position
        
        // Used customized radius or default
        let radius = radius ?? 50
        
        // Create the shape
        let shape = SKShapeNode(ellipseOf: CGSize(width: radius * 2, height: radius * 2))
        shape.fillColor = UIColor.cyan
        shape.lineWidth = 2
        addChild(shape)
        shape.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.75, duration: 1.75),
            SKAction.fadeAlpha(to: 1.0, duration: 0.75)
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
    private var labelNode: SKLabelNode!
    
    public init(position: CGPoint, velocity: CGVector, scene: SKScene, radius: Double?) {
        super.init()
        self.position = position
        
        // Choose a random radius for a little variety
        let radius = radius ?? Double.random(in: 15...22)
        
        // Create the shape
        let shape = SKShapeNode(ellipseOf: CGSize(width: radius * 2, height: radius * 2))
        shape.fillColor = UIColor.yellow
        shape.lineWidth = 2
        addChild(shape)
        
        // Create the info label
        labelNode = SKLabelNode()
        labelNode.fontSize = 22
        labelNode.color = UIColor(white: 1.0, alpha: 0.35)
        labelNode.position = CGPoint(x: 0, y: -22 - radius)
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
    
    // Non-nil if a node is currently being dragged
    private var tappedNode: TappableNode?
    
    // Count of rendered frames to execute only every x frames
    private var frameCnt: Int = 0
    
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
    
    /**
     Add and return a Planet at position (x, y) m and mass in kg.
     */
    public func makePlanet(x: Double, y: Double, mass: Double, radius: Double? = nil) -> SKNode {
        let planet = Planet(position: CGPoint(x: x, y: y), mass: mass * GameScene.gravitationConstant / pow(150, 3), radius: radius)
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
    
    // MARK: SKPhysicsContactDelegate
    
    public func didBegin(_ contact: SKPhysicsContact) {
        if let _ = (contact.bodyA.node as? Planet) ?? (contact.bodyB.node as? Planet),
            let satellite = (contact.bodyA.node as? Satellite) ?? (contact.bodyB.node as? Satellite) {
            satellite.physicsBody?.velocity = CGVector.zero
        }
    }
    
    // MARK: Touch handling
    
    private func touchDown(atPoint pos: CGPoint) {
        if let tapped = self.nodes(at: pos).filter({(node) in
            node is SKShapeNode && node.parent is TappableNode
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
        tappedNode?.updatePosition()
        self.frameCnt += 1
        if self.frameCnt % 9 == 1 {
            quickCheck(scene: self)
        }
    }
}

let sceneView = SKView(frame: CGRect(x: 0, y: 0, width: 640, height: 480))
guard let scene = GameScene(fileNamed: "GameScene") else {
    exit(1)
}
scene.scaleMode = .aspectFill
sceneView.isMultipleTouchEnabled = false
sceneView.presentScene(scene)
PlaygroundSupport.PlaygroundPage.current.liveView = sceneView
//#-end-hidden-code

//#-editable-code

scene.makePlanet(x: 0, y: 0, mass: 1.49835181e16)

scene.makeSatellite(x: 0, y: 200, dx: <#horizontal speed of satellite#>, dy: 0)


//#-end-editable-code

// Optional: any code in this function will be executed several
// times per second for real-time updates.
func quickCheck(scene: GameScene) {
    //#-editable-code
    scene.satellites.forEach({(satellite) in
        satellite.setText(satellite.velocityString)
    })
    //#-end-editable-code
}
