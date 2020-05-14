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
        let radius = CGFloat.random(in: 36...54)
        
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
        field.strength = mass
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
    private var labelNode: SKLabelNode!
    
    public init(position: CGPoint, velocity: CGVector, scene: SKScene) {
        super.init()
        self.position = position
        
        // Choose a random radius smaller than Planet
        let radius = CGFloat.random(in: 15...21)
        
        // Create the shape
        let shape = SKShapeNode(ellipseOf: CGSize(width: radius * 2, height: radius * 2))
        shape.fillColor = UIColor.yellow
        shape.lineWidth = 2
        addChild(shape)
        
        // Create the info label
        labelNode = SKLabelNode()
        labelNode.fontSize = 22
        labelNode.color = UIColor(white: 1.0, alpha: 0.36)
        labelNode.position = CGPoint(x: 0, y: -23 - radius)
        addChild(labelNode)
        
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
    
    public func setText(_ newText: String) {
        labelNode.text = newText
    }
}

public class GameScene: SKScene, SKPhysicsContactDelegate {
    private var tappedNode: TappableNode?
    private var frameCnt: Int = 0
    
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
    
    public func makePlanet(x: CGFloat, y: CGFloat, mass: Float) -> SKNode {
        let planet = Planet(position: CGPoint(x: x, y: y), mass: mass)
        addChild(planet)
        return planet
    }
    
    public func makeSatellite(x: CGFloat, y: CGFloat, dx: CGFloat, dy: CGFloat) -> SKNode {
        let satellite = Satellite(position: CGPoint(x: x, y: y), velocity: CGVector(dx: dx, dy: dy), scene: self)
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
    
    public var planets: [Planet] {
        children.filter({(node) in
            node is Planet
        }) as! [Planet]
    }
    
    public var satellites: [Satellite] {
        children.filter({(node) in
            node is Satellite
        }) as! [Satellite]
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

scene.makePlanet(x: 0, y: 0, mass: 1)
//scene.makePlanet(x: 0, y: 200, mass: 1)
scene.makeSatellite(x: 0, y: 300, dx: 150 / sqrt(2), dy: 0)
scene.makeSatellite(x: -150, y: 0, dx: 0, dy: 150)


// Optional
func quickCheck(scene: GameScene) {
    // Insert any code here you would like to execute several times per second.
    scene.satellites.forEach({(satellite) in
        if let velo = satellite.physicsBody?.velocity {
            let speed = sqrt(velo.dx * velo.dx + velo.dy * velo.dy)
            satellite.setText(String(format: "%.0f m/s", speed))
        }
    })
}

//#-end-editable-code
