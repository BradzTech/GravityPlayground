//: A SpriteKit based Playground

import PlaygroundSupport
import SpriteKit

class GameScene: SKScene {
    
    var dynamicNode: SKNode!
    
    override func didMove(to view: SKView) {
        let staticNode = createStaticNode(radius: 40, position: CGPoint(x: 0, y: 0), mass: 1)
        addChild(staticNode)
        dynamicNode = createDynamicNode(radius: 15, position: CGPoint(x: 0, y: 300), velocity: CGVector(dx: 150 / sqrt(2), dy: 0))
        addChild(dynamicNode)
    }
    
    func createStaticNode(radius: CGFloat, position: CGPoint, mass: Float) -> SKNode {
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
        return shape
    }
    
    func createDynamicNode(radius: CGFloat, position: CGPoint, velocity: CGVector) -> SKNode {
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
        return shape
    }
    
    @objc static override var supportsSecureCoding: Bool {
        // SKNode conforms to NSSecureCoding, so any subclass going
        // through the decoding process must support secure coding
        get {
            return true
        }
    }
    
    func touchDown(atPoint pos : CGPoint) {
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
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { touchDown(atPoint: t.location(in: self)) }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { touchMoved(toPoint: t.location(in: self)) }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { touchUp(atPoint: t.location(in: self)) }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { touchUp(atPoint: t.location(in: self)) }
    }
    
    override func update(_ currentTime: TimeInterval) {
        sqrt(dynamicNode.position.x * dynamicNode.position.x + dynamicNode.position.y * dynamicNode.position.y)
    }
}

// Load the SKScene from 'GameScene.sks'
let sceneView = SKView(frame: CGRect(x: 0, y: 0, width: 640, height: 480))
if let scene = GameScene(fileNamed: "GameScene") {
    // Set the scale mode to scale to fit the window
    scene.scaleMode = .aspectFill
    
    // Present the scene
    sceneView.presentScene(scene)
}

PlaygroundSupport.PlaygroundPage.current.liveView = sceneView
