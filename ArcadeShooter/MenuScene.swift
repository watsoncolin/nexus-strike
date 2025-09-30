import SpriteKit

class MenuScene: SKScene {

    var highScore: Int = 0
    var starfield: SKEmitterNode!

    override func didMove(to view: SKView) {
        backgroundColor = SKColor.black

        // Load high score
        highScore = UserDefaults.standard.integer(forKey: "highScore")

        // Title
        let titleLabel = SKLabelNode(text: "Nexus Strike")
        titleLabel.fontSize = 56
        titleLabel.fontColor = .white
        titleLabel.position = CGPoint(x: size.width / 2, y: size.height - 150)
        addChild(titleLabel)

        // Play button
        let playButton = SKLabelNode(text: "PLAY")
        playButton.fontSize = 48
        playButton.fontColor = .green
        playButton.name = "playButton"
        playButton.position = CGPoint(
            x: size.width / 2,
            y: size.height / 2 + 50
        )
        addChild(playButton)

        // High score display
        let highScoreLabel = SKLabelNode(text: "High Score: \(highScore)")
        highScoreLabel.fontSize = 32
        highScoreLabel.fontColor = .yellow
        highScoreLabel.position = CGPoint(
            x: size.width / 2,
            y: size.height / 2 - 50
        )
        addChild(highScoreLabel)

        // Credits button
        let creditsButton = SKLabelNode(text: "Credits")
        creditsButton.fontSize = 24
        creditsButton.fontColor = .white
        creditsButton.name = "creditsButton"
        creditsButton.position = CGPoint(x: size.width / 2, y: 100)
        addChild(creditsButton)

        // Add camera
        let camera = SKCameraNode()
        camera.position = CGPoint(x: size.width / 2, y: size.height / 2)
        self.camera = camera
        addChild(camera)
        
        createStarfield()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let tappedNode = atPoint(location)

        if tappedNode.name == "playButton" {
            // Start game
            let gameScene = GameScene(size: self.size)
            gameScene.scaleMode = .aspectFill
            let transition = SKTransition.fade(withDuration: 0.5)
            view?.presentScene(gameScene, transition: transition)
        }

        if tappedNode.name == "creditsButton" {
            showCredits()
        }
    }

    func showCredits() {
        // Check if credits already showing
        if childNode(withName: "credits") != nil {
            childNode(withName: "credits")?.removeFromParent()
            childNode(withName: "creditsBackground")?.removeFromParent()
            return
        }

        let creditsText = """
            CREDITS

            Sound Effects:
            Laser_07.wav by LittleRobotSoundFactory
            https://freesound.org/s/270551/
            License: Attribution 4.0
            
            Spaceships:
            https://kenney.nl/assets/space-shooter-redux

            Tap to close
            """

        let creditsLabel = SKLabelNode()
        creditsLabel.text = creditsText
        creditsLabel.fontSize = 16
        creditsLabel.fontColor = .white
        creditsLabel.numberOfLines = 0
        creditsLabel.lineBreakMode = .byWordWrapping
        creditsLabel.preferredMaxLayoutWidth = size.width - 40
        creditsLabel.verticalAlignmentMode = .center
        creditsLabel.horizontalAlignmentMode = .center
        creditsLabel.position = CGPoint(x: size.width / 2, y: size.height / 2)
        creditsLabel.name = "credits"

        let background = SKShapeNode(
            rectOf: CGSize(width: size.width - 20, height: 300)
        )
        background.fillColor = SKColor.black.withAlphaComponent(0.8)
        background.strokeColor = .white
        background.lineWidth = 2
        background.position = CGPoint(x: size.width / 2, y: size.height / 2)
        background.name = "creditsBackground"

        addChild(background)
        addChild(creditsLabel)
        backgroundColor = SKColor(red: 0.05, green: 0.05, blue: 0.15, alpha: 1.0)
    }
    func createStarfield() {
        starfield = SKEmitterNode()
        starfield.particleTexture = SKTexture(imageNamed: "spark")
        starfield.particleBirthRate = 50
        starfield.particleLifetime = 30
        starfield.particleSpeed = 20
        starfield.particleSpeedRange = 10
        starfield.particlePositionRange = CGVector(dx: size.width, dy: 0)
        starfield.position = CGPoint(x: size.width / 2, y: size.height)
        starfield.particleColor = .white
        starfield.particleColorBlendFactor = 1
        starfield.particleAlpha = 0.6
        starfield.particleAlphaRange = 0.3
        starfield.particleScale = 0.05
        starfield.particleScaleRange = 0.03
        starfield.emissionAngle = CGFloat.pi * 1.5  // Downward
        starfield.advanceSimulationTime(100)  // Start with stars already visible
        starfield.zPosition = -1  // Behind everything

        addChild(starfield)
    }
}
