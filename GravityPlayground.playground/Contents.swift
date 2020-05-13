/*:
 # GravityPlayground
 
 Welcome to a playground of gravity!
 */

//#-hidden-code
import PlaygroundSupport
import SpriteKit

public class GameScene: SKScene {
    
    public override func didMove(to view: SKView) {
    }
    
    public func makePlanet(position: CGPoint, mass: Float) -> SKNode {
        let radius = CGFloat.random(in: 36...52)
        let field = SKFieldNode.radialGravityField()
        field.falloff = 2
        field.strength = mass
        field.position = position
        let shape = SKShapeNode(ellipseOf: CGSize(width: radius * 2, height: radius * 2))
        let physics = SKPhysicsBody(circleOfRadius: radius)
        physics.isDynamic = false
        shape.physicsBody = physics
        shape.fillColor = UIColor.green
        shape.position = CGPoint(x: 0, y: 0)
        shape.addChild(field)
        addChild(shape)
        return shape
    }
    
    public func makeSatellite(position: CGPoint, velocity: CGVector) -> SKNode {
        let radius = CGFloat.random(in: 14...20)
        let shape = SKShapeNode(ellipseOf: CGSize(width: radius * 2, height: radius * 2))
        let physics = SKPhysicsBody(circleOfRadius: radius)
        physics.velocity = velocity
        physics.friction = 0
        physics.angularDamping = 0
        physics.linearDamping = 0
        physics.mass = 1
        shape.physicsBody = physics
        shape.fillColor = UIColor.yellow
        shape.position = position
        addChild(shape)
        if let emitter = SKEmitterNode(fileNamed: "TraceParticle") {
            emitter.targetNode = self
            emitter.particleZPosition = -1
            shape.addChild(emitter)
        }
        return shape
    }
    
    public func polarToRect(radius: CGFloat, theta: CGFloat) -> CGPoint {
        return CGPoint(x: radius, y: 0).applying(CGAffineTransform(rotationAngle: theta))
    }
    
    @objc public static override var supportsSecureCoding: Bool {
        // SKNode conforms to NSSecureCoding, so any subclass going
        // through the decoding process must support secure coding
        get {
            return true
        }
    }
    
    func touchDown(atPoint pos : CGPoint) {
        self.nodes(at: pos)
        /*guard let n = spinnyNode.copy() as? SKShapeNode else { return }
        
        n.position = pos
        n.strokeColor = SKColor.green
        addChild(n)*/
    }
    
    func touchMoved(toPoint pos : CGPoint) {
        /*guard let n = self.spinnyNode.copy() as? SKShapeNode else { return }
        
        n.position = pos
        n.strokeColor = SKColor.blue
        addChild(n)*/
    }
    
    func touchUp(atPoint pos : CGPoint) {
        /*guard let n = spinnyNode.copy() as? SKShapeNode else { return }
        
        n.position = pos
        n.strokeColor = SKColor.red
        addChild(n)*/
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
        //sqrt(dynamicNode.position.x * dynamicNode.position.x + dynamicNode.position.y * dynamicNode.position.y)
    }
}

let sceneView = SKView(frame: CGRect(x: 0, y: 0, width: 640, height: 480))
guard let scene = GameScene(fileNamed: "GameScene") else {
    exit(1)
}
scene.scaleMode = .aspectFill
sceneView.presentScene(scene)
PlaygroundSupport.PlaygroundPage.current.liveView = sceneView
//#-end-hidden-code

//#-editable-code

scene.makePlanet(position: CGPoint(x: 0, y: 0), mass: 1)
scene.makeSatellite(position: CGPoint(x: 0, y: 300), velocity: CGVector(dx: 150 / sqrt(2), dy: 0))
scene.makeSatellite(position: CGPoint(x: -150, y: 0), velocity: CGVector(dx: 0, dy: 150))

//#-end-editable-code
