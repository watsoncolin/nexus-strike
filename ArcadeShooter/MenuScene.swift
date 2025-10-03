import SpriteKit
import UIKit

class MenuScene: SKScene {

    var highScore: Int = 0
    var starfield: SKEmitterNode!

    override func didMove(to view: SKView) {
        backgroundColor = SKColor.black

        // Load high score
        highScore = UserDefaults.standard.integer(forKey: "highScore")

        // Title
        let titleLabel = SKLabelNode(text: "Nexus Strike")
        titleLabel.fontName = "PressStart2P-Regular"
        titleLabel.fontSize = 24
        titleLabel.fontColor = .white
        titleLabel.position = CGPoint(x: size.width / 2, y: size.height - 150)
        addChild(titleLabel)

        // Play button
        let playButton = SKLabelNode(text: "PLAY")
        playButton.fontName = "PressStart2P-Regular"
        playButton.fontSize = 24
        playButton.fontColor = .green
        playButton.name = "playButton"
        playButton.position = CGPoint(
            x: size.width / 2,
            y: size.height / 2 + 50
        )
        addChild(playButton)

        // High score display
        let highScoreLabel = SKLabelNode(text: "High Score: \(highScore)")
        highScoreLabel.fontName = "PressStart2P-Regular"
        highScoreLabel.fontSize = 18
        highScoreLabel.fontColor = .yellow
        highScoreLabel.position = CGPoint(
            x: size.width / 2,
            y: size.height / 2 - 50
        )
        addChild(highScoreLabel)

        // Credits button
        let creditsButton = SKLabelNode(text: "Credits")
        creditsButton.fontName = "PressStart2P-Regular"
        creditsButton.fontSize = 14
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
            // Show loading screen and start game
            showLoadingScreen()
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

            Tap to close
            """

        let creditsLabel = SKLabelNode()
        creditsLabel.text = creditsText
        creditsLabel.fontName = "PressStart2P-Regular"
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

    func showLoadingScreen() {
        // Hide existing UI elements
        childNode(withName: "playButton")?.alpha = 0.3
        childNode(withName: "creditsButton")?.alpha = 0.3

        // Create loading background
        let loadingBackground = SKShapeNode(rectOf: CGSize(width: size.width, height: size.height))
        loadingBackground.fillColor = SKColor.black.withAlphaComponent(0.8)
        loadingBackground.strokeColor = .clear
        loadingBackground.position = CGPoint(x: size.width / 2, y: size.height / 2)
        loadingBackground.name = "loadingBackground"
        loadingBackground.zPosition = 100
        addChild(loadingBackground)

        // Create loading label
        let loadingLabel = SKLabelNode(text: "LOADING...")
        loadingLabel.fontName = "PressStart2P-Regular"
        loadingLabel.fontSize = 24
        loadingLabel.fontColor = SKColor(red: 0, green: 1, blue: 0.53, alpha: 1) // Neon green
        loadingLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 + 60)
        loadingLabel.name = "loadingLabel"
        loadingLabel.zPosition = 101
        addChild(loadingLabel)

        // Create space-themed loading spinner - rotating hexagon with orbiting dots
        createLoadingSpinner()

        // Animate loading text
        let pulse = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.5, duration: 0.8),
            SKAction.fadeAlpha(to: 1.0, duration: 0.8)
        ])
        loadingLabel.run(SKAction.repeatForever(pulse))

        // Start loading the game after a short delay to show the loading screen
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.loadGame()
        }
    }

    func createLoadingSpinner() {
        // Create hexagonal spinner (original style but optimized)
        let hexagon = SKShapeNode()
        let path = CGMutablePath()
        let radius: CGFloat = 30
        let centerX: CGFloat = size.width / 2
        let centerY: CGFloat = size.height / 2 - 20

        // Draw hexagon
        for i in 0..<6 {
            let angle = CGFloat(i) * .pi / 3
            let x = centerX + radius * cos(angle)
            let y = centerY + radius * sin(angle)
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        path.closeSubpath()

        hexagon.path = path
        hexagon.strokeColor = SKColor(red: 0, green: 0.8, blue: 1, alpha: 1) // Neon cyan
        hexagon.lineWidth = 3
        hexagon.fillColor = .clear
        hexagon.name = "loadingSpinner"
        hexagon.zPosition = 101
        addChild(hexagon)

        // Smooth rotation
        let rotation = SKAction.rotate(byAngle: .pi * 2, duration: 2.0)
        hexagon.run(SKAction.repeatForever(rotation))

        // Create orbiting dots with container nodes for smoother animation
        for i in 0..<3 {
            let dot = SKShapeNode(circleOfRadius: 4)
            dot.fillColor = SKColor(red: 0, green: 1, blue: 0.53, alpha: 1) // Neon green
            dot.strokeColor = .clear
            dot.name = "orbitDot\(i)"
            dot.zPosition = 102

            // Create container for smooth orbital motion
            let orbitContainer = SKNode()
            orbitContainer.position = CGPoint(x: centerX, y: centerY)

            // Position dots at different starting angles
            let startAngle = CGFloat(i) * (2 * .pi / 3)
            orbitContainer.zRotation = startAngle
            addChild(orbitContainer)

            // Position dot at orbit radius
            let orbitRadius: CGFloat = 45
            dot.position = CGPoint(x: orbitRadius, y: 0)
            orbitContainer.addChild(dot)

            // Orbital rotation
            let orbit = SKAction.rotate(byAngle: .pi * 2, duration: 1.5)
            orbitContainer.run(SKAction.repeatForever(orbit))

            // Pulsing effect
            let pulse = SKAction.sequence([
                SKAction.scale(to: 1.5, duration: 0.5),
                SKAction.scale(to: 1.0, duration: 0.5)
            ])
            dot.run(SKAction.repeatForever(pulse))
        }
    }

    func loadGame() {
        // Create the game scene and let it preload
        let gameScene = GameScene(size: self.size)
        gameScene.scaleMode = .aspectFill

        // Set a callback for when loading is complete
        gameScene.onLoadingComplete = { [weak self] in
            DispatchQueue.main.async {
                self?.transitionToGame(gameScene)
            }
        }

        // Start the loading process
        gameScene.startPreloading()
    }

    func transitionToGame(_ gameScene: GameScene) {
        let transition = SKTransition.fade(withDuration: 0.5)
        view?.presentScene(gameScene, transition: transition)
    }
}
