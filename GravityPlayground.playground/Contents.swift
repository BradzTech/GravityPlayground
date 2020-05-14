/*:
 # GravityPlayground
 
 Welcome to a playground of gravity!
 */

//#-hidden-code
import PlaygroundSupport
import SpriteKit

public class TappableNode: SKNode {
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
            position = CGPoint(x: position.x + (targetPos.x - position.x) / 20, y: position.y + (targetPos.y - position.y) / 20)
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
}

public class Planet: TappableNode {
    public init(position: CGPoint, mass: Float) {
        super.init()
        self.position = position
        
        // Choose a random radius for a little variety
        let radius = CGFloat.random(in: 36...52)
        
        // Create the shape
        let shape = SKShapeNode(ellipseOf: CGSize(width: radius * 2, height: radius * 2))
        shape.fillColor = UIColor.green
        addChild(shape)
        
        // Create the gravity field
        let field = SKFieldNode.radialGravityField()
        field.falloff = 2
        field.strength = mass
        field.position = position
        addChild(field)
        
        // Create the static physics body
        let physics = SKPhysicsBody(circleOfRadius: radius)
        physics.isDynamic = false
        physicsBody = physics
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public class Satellite: TappableNode {
    public init(position: CGPoint, velocity: CGVector, scene: SKScene) {
        super.init()
        self.position = position
        
        // Choose a random radius smaller than Planet
        let radius = CGFloat.random(in: 14...20)
        
        // Create the shape
        let shape = SKShapeNode(ellipseOf: CGSize(width: radius * 2, height: radius * 2))
        shape.fillColor = UIColor.yellow
        addChild(shape)
        
        // Create the particle emitter for orbit tracing
        if let emitter = SKEmitterNode(fileNamed: "TraceParticle") {
            emitter.targetNode = scene
            emitter.particleZPosition = -1
            addChild(emitter)
        }
        
        // Create the dynamic physics body
        let physics = SKPhysicsBody(circleOfRadius: radius)
        physics.velocity = velocity
        physics.friction = 0
        physics.angularDamping = 0
        physics.linearDamping = 0
        physics.mass = 1
        physics.allowsRotation = false
        physics.contactTestBitMask = physics.collisionBitMask
        physicsBody = physics
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public class GameScene: SKScene, SKPhysicsContactDelegate {
    private var tappedNode: TappableNode?
    
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
    
    public func makePlanet(position: CGPoint, mass: Float) -> SKNode {
        let planet = Planet(position: position, mass: mass)
        addChild(planet)
        return planet
    }
    
    public func makeSatellite(position: CGPoint, velocity: CGVector) -> SKNode {
        let satellite = Satellite(position: position, velocity: velocity, scene: self)
        addChild(satellite)
        return satellite
    }
    
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
    
    public func didBegin(_ contact: SKPhysicsContact) {
        [contact.bodyA, contact.bodyB].forEach({(body) in
            if body.isDynamic {
                body.velocity = CGVector.zero
            }
        })
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

scene.makePlanet(position: CGPoint(x: 0, y: 0), mass: 1)
scene.makeSatellite(position: CGPoint(x: 0, y: 300), velocity: CGVector(dx: 150 / sqrt(2), dy: 0))
scene.makeSatellite(position: CGPoint(x: -150, y: 0), velocity: CGVector(dx: 0, dy: 150))

//#-end-editable-code
