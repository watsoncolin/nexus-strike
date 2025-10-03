//
//  GameScene.swift
//  ArcadeShooter
//
//  Created by Colin Watson on 9/28/25.
//

import GameplayKit
import SpriteKit

class GameScene: SKScene {

    var starfield: SKEmitterNode!
    var player: SKSpriteNode!
    var bullets: [SKSpriteNode] = []
    var enemies: [SKSpriteNode] = []
    var lastShotTime: TimeInterval = 0
    var lastEnemySpawnTime: TimeInterval = 0
    var shotCooldown: TimeInterval = 0.3
    let enemySpawnInterval: TimeInterval = 1.5  // Spawn enemy every 1.5 seconds
    var score: Int = 0
    var scoreLabel: SKLabelNode!
    var gameRunning = true
    var difficulty: CGFloat = 1.0  // Multiplier for difficulty
    var survivalTime: TimeInterval = 0
    var health: Int = 3
    var powerUps: [SKSpriteNode] = []
    var lastPowerUpSpawnTime: TimeInterval = 0
    let powerUpSpawnInterval: TimeInterval = 10.0  // Spawn every 10 seconds
    var rapidFireActive = false
    var shieldCount: Int = 0
    var shieldIcons: [SKShapeNode] = []
    var gamePaused = false
    var pauseButton: SKLabelNode!
    var multiShotCount: Int = 0
    var currentLevel: Int = 1
    var enemiesKilledThisLevel: Int = 0
    var enemiesNeededForNextLevel: Int = 10
    var levelLabel: SKLabelNode!
    var bossActive = false
    var boss: SKSpriteNode?
    var bossHealthBar: SKShapeNode?

    enum EnemyType {
        case normal  // Red, standard speed
        case fast  // Yellow, moves faster, worth more points
        case tank  // Purple, slower but takes 2 hits
    }

    enum PowerUpType {
        case rapidFire  // Green - shoot faster
        case shield  // Blue - survive one hit
        case multiShot  // Orange - shoot 3 bullets
    }

    var enemyHealthMap: [SKSpriteNode: Int] = [:]  // Track enemy health

    // Preloaded sound actions
    var laserSoundAction: SKAction!
    var explosionSoundAction: SKAction?
    var soundCache: [String: SKAction] = [:]

    // Loading callback
    var onLoadingComplete: (() -> Void)?
    var isPreloaded = false

    func preloadSounds() {
        // Preload laser sound to eliminate first-shot delay
        laserSoundAction = SKAction.playSoundFileNamed(
            "270551__littlerobotsoundfactory__laser_07.wav",
            waitForCompletion: false
        )

        // Try to preload explosion sound if it exists
        if Bundle.main.url(forResource: "explosion", withExtension: "wav")
            != nil
        {
            explosionSoundAction = SKAction.playSoundFileNamed(
                "explosion.wav",
                waitForCompletion: false
            )
            print("Explosion sound preloaded")
        } else {
            print("Explosion sound file not found - skipping preload")
        }

        print("Sounds preloaded")
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

    func createPlayer() {
        // Remove any existing player to prevent duplicates
        childNode(withName: "player")?.removeFromParent()

        player = SKSpriteNode(imageNamed: "player")
        player.setScale(0.2)  // Adjust size as needed
        player.position = CGPoint(x: size.width / 2, y: 100)
        player.name = "player"
        addChild(player)

        // Add engine glow effect
        let engineGlow = SKShapeNode(circleOfRadius: 5)
        engineGlow.fillColor = .orange
        engineGlow.strokeColor = .clear
        engineGlow.position = CGPoint(x: 0, y: -15)
        engineGlow.alpha = 0.8
        player.addChild(engineGlow)

        // Pulse engine glow
        let pulse = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.4, duration: 0.3),
            SKAction.fadeAlpha(to: 0.8, duration: 0.3),
        ])
        engineGlow.run(SKAction.repeatForever(pulse))
    }

    func createBullet(at position: CGPoint) {
        // Check if multi-shot is active
        if multiShotCount > 0 {
            // Fire 3 bullets in spread pattern
            createSingleBullet(at: position)  // Center
            createSingleBullet(at: CGPoint(x: position.x - 15, y: position.y))  // Left
            createSingleBullet(at: CGPoint(x: position.x + 15, y: position.y))  // Right

            multiShotCount -= 1
            updateMultiShotDisplay()
            print("Multi-shot fired! Shots remaining: \(multiShotCount)")
        } else {
            // Normal single bullet
            createSingleBullet(at: position)
        }
    }

    func createSingleBullet(at position: CGPoint) {
        let bullet = SKSpriteNode(imageNamed: "laser_blue")
        bullet.setScale(0.5)
        bullet.position = position
        bullet.name = "bullet"
        addChild(bullet)
        run(laserSoundAction)
        bullets.append(bullet)

        // Move bullet upward off screen
        let moveAction = SKAction.moveBy(
            x: 0,
            y: size.height + 50,
            duration: 2.0
        )
        let removeAction = SKAction.run { [weak self] in
            self?.removeBullet(bullet)
        }
        bullet.run(SKAction.sequence([moveAction, removeAction]))

        // Add bullet trail effect
        let trail = SKEmitterNode()
        trail.particleTexture = SKTexture(imageNamed: "spark")
        trail.particleBirthRate = 200
        trail.particleLifetime = 0.2
        trail.particleSpeed = 0
        trail.particlePositionRange = CGVector(dx: 2, dy: 2)
        trail.particleColor = .yellow
        trail.particleColorBlendFactor = 1
        trail.particleAlpha = 1.0
        trail.particleAlphaSpeed = -3
        trail.particleScale = 0.15
        trail.particleScaleSpeed = -0.3
        trail.particleBlendMode = .add
        trail.position = CGPoint(x: 0, y: -5)
        trail.emissionAngle = CGFloat.pi / 2
        trail.particleSpeedRange = 10
        bullet.addChild(trail)
    }

    func removeBullet(_ bullet: SKSpriteNode) {
        bullet.removeFromParent()
        if let index = bullets.firstIndex(of: bullet) {
            bullets.remove(at: index)
        }
    }

    func spawnEnemy() {
        // Randomly choose enemy type (weighted)
        let random = Int.random(in: 1...100)
        let enemyType: EnemyType

        if random <= 70 {
            enemyType = .normal  // 70% chance
        } else if random <= 90 {
            enemyType = .fast  // 20% chance
        } else {
            enemyType = .tank  // 10% chance
        }

        let enemy: SKSpriteNode
        var duration: TimeInterval = 4.0
        var enemyHealth = 1

        switch enemyType {
        case .normal:
            enemy = SKSpriteNode(imageNamed: "enemy_1")
            enemy.setScale(0.25)

            duration = 4.0
            enemyHealth = 1

        case .fast:
            enemy = SKSpriteNode(imageNamed: "enemy_2")
            enemy.setScale(0.15)
            duration = 2.5  // Faster!
            enemyHealth = 1

        case .tank:
            enemy = SKSpriteNode(imageNamed: "enemy_3")
            enemy.setScale(0.3)
            duration = 5.0  // Slower
            enemyHealth = 2  // Takes 2 hits!
        }

        // Random X position across the top of screen
        let randomX = CGFloat.random(in: 30...(size.width - 30))
        enemy.position = CGPoint(x: randomX, y: size.height + 25)
        enemy.name = "enemy"
        addChild(enemy)
        enemies.append(enemy)
        enemyHealthMap[enemy] = enemyHealth

        // Move enemy downward
        let moveAction = SKAction.moveBy(
            x: 0,
            y: -(size.height + 100),
            duration: duration
        )
        let removeAction = SKAction.run { [weak self] in
            self?.removeEnemy(enemy)
        }
        enemy.run(SKAction.sequence([moveAction, removeAction]))
    }

    func spawnPowerUp() {
        // Randomly choose power-up type
        let powerUpTypes: [PowerUpType] = [.rapidFire, .shield, .multiShot]
        let powerUpType = powerUpTypes.randomElement()!

        let powerUp: SKSpriteNode

        switch powerUpType {
        case .rapidFire:
            powerUp = SKSpriteNode(imageNamed: "power_up_fire_rate")
            powerUp.setScale(0.4)
            powerUp.name = "powerup_rapidfire"

        case .shield:
            powerUp = SKSpriteNode(imageNamed: "power_up_shield")
            powerUp.setScale(0.4)
            powerUp.name = "powerup_shield"

        case .multiShot:
            powerUp = SKSpriteNode(imageNamed: "power_up_multi_shot")
            powerUp.setScale(0.4)
            powerUp.name = "powerup_multishot"
        }

        // Random X position
        let randomX = CGFloat.random(in: 30...(size.width - 30))
        powerUp.position = CGPoint(x: randomX, y: size.height + 25)
        addChild(powerUp)
        powerUps.append(powerUp)

        // Move downward slowly
        let moveAction = SKAction.moveBy(
            x: 0,
            y: -(size.height + 100),
            duration: 6.0
        )
        let removeAction = SKAction.run { [weak self] in
            self?.removePowerUp(powerUp)
        }
        powerUp.run(SKAction.sequence([moveAction, removeAction]))
    }

    func removePowerUp(_ powerUp: SKSpriteNode) {
        powerUp.removeFromParent()
        if let index = powerUps.firstIndex(of: powerUp) {
            powerUps.remove(at: index)
        }
    }

    func removeEnemy(_ enemy: SKSpriteNode) {
        enemy.removeFromParent()
        enemyHealthMap.removeValue(forKey: enemy)  // Clean up health tracking
        if let index = enemies.firstIndex(of: enemy) {
            enemies.remove(at: index)
        }
    }

    func checkCollisions() {
        for bullet in bullets {
            for enemy in enemies {
                if bullet.frame.intersects(enemy.frame) {
                    // Hit! Reduce enemy health
                    if let health = enemyHealthMap[enemy] {
                        enemyHealthMap[enemy] = health - 1

                        if health - 1 <= 0 {
                            if enemy == boss {
                                print("Boss destroyed, calling defeatBoss()")
                                defeatBoss()
                            }
                            // Enemy destroyed
                            createExplosion(at: enemy.position)
                            shakeScreen()
                            removeEnemy(enemy)

                            // Track kills for level progression
                            enemiesKilledThisLevel += 1

                            // Award points based on enemy size
                            if enemy.size.width == 20 {
                                score += 20
                            } else if enemy.size.width == 35 {
                                score += 30
                            } else {
                                score += 10
                            }

                            scoreLabel.text = "\(score)"

                            // Check if ready for next level
                            if enemiesKilledThisLevel
                                >= enemiesNeededForNextLevel
                            {
                                levelUp()
                            }

                            // Play explosion sound if preloaded, otherwise load it
                            if let explosionSound = explosionSoundAction {
                                run(explosionSound)
                            } else {
                                run(
                                    SKAction.playSoundFileNamed(
                                        "explosion.wav",
                                        waitForCompletion: false
                                    )
                                )
                            }
                        } else {
                            // Enemy damaged but not destroyed (tank only)
                            // Flash the enemy
                            let flash = SKAction.sequence([
                                SKAction.fadeAlpha(to: 0.3, duration: 0.1),
                                SKAction.fadeAlpha(to: 1.0, duration: 0.1),
                            ])
                            enemy.run(flash)

                            // Update boss health bar if it's the boss
                            if enemy == boss {
                                let maxHealth = currentLevel * 10
                                updateBossHealthBar(
                                    currentHealth: health - 1,
                                    maxHealth: maxHealth
                                )
                            }
                        }
                    }

                    removeBullet(bullet)
                    return
                }
            }
        }
    }

    func levelUp() {
        currentLevel += 1
        enemiesKilledThisLevel = 0
        enemiesNeededForNextLevel += 5  // Need more kills each level

        levelLabel.text = "\(currentLevel)"

        // Check if it's a boss level (every 3 levels)
        if currentLevel % 3 == 0 {
            spawnBoss()
        } else {
            showLevelUpMessage()
        }
    }

    func spawnBoss() {
        bossActive = true

        // Show boss warning with proper wrapping
        let warningLabel = SKLabelNode(text: "BOSS")
        warningLabel.fontName = "PressStart2P-Regular"
        warningLabel.fontSize = 40
        warningLabel.fontColor = .red
        warningLabel.position = CGPoint(
            x: size.width / 2,
            y: size.height / 2 + 40
        )
        warningLabel.zPosition = 100
        addChild(warningLabel)

        let incomingLabel = SKLabelNode(text: "INCOMING!")
        incomingLabel.fontName = "PressStart2P-Regular"
        incomingLabel.fontSize = 24
        incomingLabel.fontColor = .red
        incomingLabel.position = CGPoint(
            x: size.width / 2,
            y: size.height / 2 - 20
        )
        incomingLabel.zPosition = 100
        addChild(incomingLabel)

        // Flash warning
        let flash = SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.2),
            SKAction.fadeIn(withDuration: 0.2),
        ])
        let flashThrice = SKAction.repeat(flash, count: 3)
        let remove = SKAction.removeFromParent()
        let spawnBossAction = SKAction.run { [weak self] in
            self?.createBoss()
        }

        warningLabel.run(
            SKAction.sequence([flashThrice, remove, spawnBossAction])
        )
        incomingLabel.run(SKAction.sequence([flashThrice, remove]))
    }

    func createBoss() {
        // Create large boss enemy
        boss = SKSpriteNode(imageNamed: "enemy_boss_1")
        boss!.setScale(1.0)  // Make it much bigger than normal enemies
        boss!.name = "boss"

        // Boss shape - make it intimidating
        for i in 1...3 {
            let glow = SKShapeNode(circleOfRadius: 50 + CGFloat(i) * 10)
            glow.fillColor = .red
            glow.strokeColor = .clear
            glow.alpha = 0.1 / CGFloat(i)
            glow.zPosition = -1
            glow.blendMode = .add
            boss!.addChild(glow)
        }

        boss!.position = CGPoint(x: size.width / 2, y: size.height + 100)
        addChild(boss!)

        // Boss has lots of health based on level
        let bossHealth = currentLevel * 10
        enemyHealthMap[boss!] = bossHealth
        enemies.append(boss!)

        // Create health bar
        createBossHealthBar(maxHealth: bossHealth)

        // Move boss into position and start pattern
        let moveIn = SKAction.moveTo(y: size.height - 150, duration: 2.0)
        let startPattern = SKAction.run { [weak self] in
            self?.startBossMovementPattern()
        }
        boss!.run(SKAction.sequence([moveIn, startPattern]))
    }

    func createBossHealthBar(maxHealth: Int) {
        let barWidth: CGFloat = 300
        let barHeight: CGFloat = 20

        // Background bar
        let bgBar = SKShapeNode(
            rectOf: CGSize(width: barWidth, height: barHeight)
        )
        bgBar.fillColor = .red
        bgBar.strokeColor = .white
        bgBar.lineWidth = 2
        bgBar.position = CGPoint(x: size.width / 2, y: size.height - 50)
        bgBar.zPosition = 50
        bgBar.name = "bossHealthBarBg"
        addChild(bgBar)

        // Health bar
        bossHealthBar = SKShapeNode(
            rectOf: CGSize(width: barWidth, height: barHeight)
        )
        bossHealthBar!.fillColor = .green
        bossHealthBar!.strokeColor = .clear
        bossHealthBar!.position = CGPoint(
            x: size.width / 2,
            y: size.height - 50
        )
        bossHealthBar!.zPosition = 51
        addChild(bossHealthBar!)
    }

    func updateBossHealthBar(currentHealth: Int, maxHealth: Int) {
        let percentage = CGFloat(currentHealth) / CGFloat(maxHealth)
        bossHealthBar?.xScale = percentage

        // Change color based on health
        if percentage > 0.6 {
            bossHealthBar?.fillColor = .green
        } else if percentage > 0.3 {
            bossHealthBar?.fillColor = .yellow
        } else {
            bossHealthBar?.fillColor = .red
        }
    }

    func startBossMovementPattern() {
        guard let boss = boss else { return }

        // Boss moves left and right across screen
        let moveLeft = SKAction.moveTo(x: 100, duration: 2.0)
        let moveRight = SKAction.moveTo(x: size.width - 100, duration: 2.0)
        let pattern = SKAction.sequence([moveLeft, moveRight])

        boss.run(SKAction.repeatForever(pattern))
    }

    func defeatBoss() {
        print("⭐️ defeatBoss() called!")
        bossActive = false

        if let boss = boss {
            // Big explosion
            createExplosion(at: boss.position)
            shakeScreen()

            // Award bonus points
            score += 100 * currentLevel
            scoreLabel.text = "\(score)"

            removeEnemy(boss)
            self.boss = nil
        }

        enumerateChildNodes(withName: "bossHealthBarBg") { node, _ in
            print("Removing boss health bar background")
            node.removeFromParent()
        }

        if let healthBar = bossHealthBar {
            print("Removing boss health bar foreground")
            healthBar.removeFromParent()
            bossHealthBar = nil
        }

        // Show victory message - split into two lines
        let victoryLabel = SKLabelNode(text: "BOSS")
        victoryLabel.fontName = "PressStart2P-Regular"
        victoryLabel.fontSize = 32
        victoryLabel.fontColor = .yellow
        victoryLabel.position = CGPoint(
            x: size.width / 2,
            y: size.height / 2 + 30
        )
        victoryLabel.zPosition = 100
        addChild(victoryLabel)

        let defeatedLabel = SKLabelNode(text: "DEFEATED!")
        defeatedLabel.fontName = "PressStart2P-Regular"
        defeatedLabel.fontSize = 24
        defeatedLabel.fontColor = .yellow
        defeatedLabel.position = CGPoint(
            x: size.width / 2,
            y: size.height / 2 - 20
        )
        defeatedLabel.zPosition = 100
        addChild(defeatedLabel)

        let fadeOut = SKAction.fadeOut(withDuration: 2.0)
        let remove = SKAction.removeFromParent()
        victoryLabel.run(SKAction.sequence([fadeOut, remove]))
        defeatedLabel.run(SKAction.sequence([fadeOut, remove]))
    }

    func showLevelUpMessage() {
        let levelUpLabel = SKLabelNode(text: "LEVEL \(currentLevel)")
        levelUpLabel.fontName = "PressStart2P-Regular"
        levelUpLabel.fontSize = 36
        levelUpLabel.fontColor = .yellow
        levelUpLabel.position = CGPoint(x: size.width / 2, y: size.height / 2)
        levelUpLabel.zPosition = 100
        addChild(levelUpLabel)

        // Animate and remove
        let fadeIn = SKAction.fadeIn(withDuration: 0.3)
        let wait = SKAction.wait(forDuration: 1.5)
        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
        let remove = SKAction.removeFromParent()

        levelUpLabel.run(SKAction.sequence([fadeIn, wait, fadeOut, remove]))
    }

    func playSound(named soundName: String) {
        // Use cached sound action if available, otherwise create and cache it
        let sound: SKAction
        if let cachedSound = soundCache[soundName] {
            sound = cachedSound
        } else {
            sound = SKAction.playSoundFileNamed(
                soundName,
                waitForCompletion: false
            )
            soundCache[soundName] = sound
        }
        run(sound)
    }

    func createExplosion(at position: CGPoint) {
        if let explosion = SKEmitterNode(fileNamed: "ExplosionFire") {
            explosion.position = position
            addChild(explosion)

            let wait = SKAction.wait(forDuration: 1.0)
            let remove = SKAction.removeFromParent()
            explosion.run(SKAction.sequence([wait, remove]))
        } else {
            print("Could not load Explosion.sks file")
        }
    }

    func shakeScreen() {
        let shake = SKAction.sequence([
            SKAction.moveBy(x: -5, y: 0, duration: 0.05),
            SKAction.moveBy(x: 10, y: 0, duration: 0.05),
            SKAction.moveBy(x: -5, y: 0, duration: 0.05),
        ])
        camera?.run(shake)
    }

    func checkPlayerCollisions() {
        for enemy in enemies {
            if enemy.frame.intersects(player.frame) {
                if shieldCount > 0 {
                    // Shield absorbs hit
                    shieldCount -= 1
                    updateShieldDisplay()
                    createExplosion(at: enemy.position)
                    removeEnemy(enemy)
                    shakeScreen()
                    return
                }

                removeEnemy(enemy)
                health -= 1
                updateHealthDisplay()
                shakeScreen()

                if health <= 0 {
                    gameOver()
                }
                return
            }
        }
    }

    func gameOver() {
        gameRunning = false

        // Create big player explosion
        createExplosion(at: player.position)

        // Multiple explosions for more drama
        for i in 0..<5 {
            let delay = Double(i) * 0.1
            let randomOffset = CGPoint(
                x: CGFloat.random(in: -20...20),
                y: CGFloat.random(in: -20...20)
            )
            let explosionPos = CGPoint(
                x: player.position.x + randomOffset.x,
                y: player.position.y + randomOffset.y
            )

            let wait = SKAction.wait(forDuration: delay)
            let explode = SKAction.run { [weak self] in
                self?.createExplosion(at: explosionPos)
            }
            run(SKAction.sequence([wait, explode]))
        }

        // Shake screen dramatically
        shakeScreen()
        let shakeAgain = SKAction.wait(forDuration: 0.2)
        let shake2 = SKAction.run { [weak self] in
            self?.shakeScreen()
        }
        run(SKAction.sequence([shakeAgain, shake2]))

        // Hide player
        player.run(
            SKAction.sequence([
                SKAction.fadeOut(withDuration: 0.3),
                SKAction.removeFromParent(),
            ])
        )

        saveHighScore()

        // Delay showing game over screen slightly for drama
        let delayGameOver = SKAction.wait(forDuration: 1.0)
        let showGameOver = SKAction.run { [weak self] in
            self?.showGameOverScreen()
        }
        run(SKAction.sequence([delayGameOver, showGameOver]))
    }

    func showGameOverScreen() {
        // Stop all actions
        removeAllActions()

        // Create game over display
        let gameOverLabel = SKLabelNode(text: "GAME OVER")
        gameOverLabel.fontName = "PressStart2P-Regular"
        gameOverLabel.fontSize = 32
        gameOverLabel.fontColor = .red
        gameOverLabel.position = CGPoint(
            x: size.width / 2,
            y: size.height / 2 + 50
        )
        addChild(gameOverLabel)

        let finalScoreLabel = SKLabelNode(text: "Final Score: \(score)")
        finalScoreLabel.fontName = "PressStart2P-Regular"
        finalScoreLabel.fontSize = 18
        finalScoreLabel.fontColor = .white
        finalScoreLabel.position = CGPoint(
            x: size.width / 2,
            y: size.height / 2 - 20
        )
        addChild(finalScoreLabel)

        let menuLabel = SKLabelNode(text: "Main Menu")
        menuLabel.fontName = "PressStart2P-Regular"
        menuLabel.fontSize = 12
        menuLabel.fontColor = .white
        menuLabel.name = "mainMenu"
        menuLabel.position = CGPoint(
            x: size.width / 2,
            y: size.height / 2 - 130
        )
        addChild(menuLabel)
    }

    override func didMove(to view: SKView) {
        backgroundColor = SKColor.black

        // Only setup scene if preloading is complete
        if isPreloaded {
            setupScene()
        }
    }

    func startPreloading() {
        // Preload sounds immediately
        preloadSounds()

        // Use DispatchQueue for timing since scene might not be presented yet
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.isPreloaded = true
            self?.setupScene()
            self?.onLoadingComplete?()
        }
    }

    func setupScene() {
        createStarfield()
        createPlayer()

        // Create organized HUD
        createHUD()

        // Position camera
        let camera = SKCameraNode()
        camera.position = CGPoint(x: size.width / 2, y: size.height / 2)
        self.camera = camera
        addChild(camera)

        updateHealthDisplay()

        for family in UIFont.familyNames.sorted() {
            print("Family: \(family)")
            for name in UIFont.fontNames(forFamilyName: family) {
                print("  - \(name)")
            }
        }
    }

    func createHUD() {
        var hudLabelFontSize = 14.0
        // Remove any existing HUD elements to prevent duplicates
        enumerateChildNodes(withName: "hudElement") { node, _ in
            node.removeFromParent()
        }

        // Top bar background
        let topBar = SKShapeNode(rectOf: CGSize(width: size.width, height: 120))
        topBar.fillColor = SKColor.black.withAlphaComponent(0.5)
        topBar.strokeColor = .clear
        topBar.position = CGPoint(x: size.width / 2, y: size.height - 60)
        topBar.zPosition = 10
        topBar.name = "hudElement"
        addChild(topBar)

        // Score - Top Left
        let scoreTitle = SKLabelNode(text: "SCORE")
        scoreTitle.fontName = "PressStart2P-Regular"
        scoreTitle.fontSize = hudLabelFontSize
        scoreTitle.fontColor = .gray
        scoreTitle.horizontalAlignmentMode = .left
        scoreTitle.position = CGPoint(x: 20, y: size.height - 70)
        scoreTitle.zPosition = 11
        scoreTitle.name = "hudElement"
        addChild(scoreTitle)

        scoreLabel = SKLabelNode(text: "0")
        scoreLabel.fontName = "PressStart2P-Regular"
        scoreLabel.fontSize = hudLabelFontSize
        scoreLabel.fontColor = .white
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.position = CGPoint(x: 20, y: size.height - 100)
        scoreLabel.zPosition = 11
        scoreLabel.name = "hudElement"
        addChild(scoreLabel)

        // Level - Top Center
        let levelTitle = SKLabelNode(text: "LEVEL")
        levelTitle.fontName = "PressStart2P-Regular"
        levelTitle.fontSize = hudLabelFontSize
        levelTitle.fontColor = .gray
        levelTitle.horizontalAlignmentMode = .center
        levelTitle.position = CGPoint(x: size.width / 2, y: size.height - 70)
        levelTitle.zPosition = 11
        levelTitle.name = "hudElement"
        addChild(levelTitle)

        levelLabel = SKLabelNode(text: "1")
        levelLabel.fontName = "PressStart2P-Regular"
        levelLabel.fontSize = hudLabelFontSize
        levelLabel.fontColor = .cyan
        levelLabel.horizontalAlignmentMode = .center
        levelLabel.position = CGPoint(x: size.width / 2, y: size.height - 100)
        levelLabel.zPosition = 11
        levelLabel.name = "hudElement"
        addChild(levelLabel)

        // Health - Top Right with icons
        let healthTitle = SKLabelNode(text: "HEALTH")
        healthTitle.fontName = "PressStart2P-Regular"
        healthTitle.fontSize = hudLabelFontSize
        healthTitle.fontColor = .gray
        healthTitle.horizontalAlignmentMode = .right
        healthTitle.position = CGPoint(x: size.width - 20, y: size.height - 70)
        healthTitle.zPosition = 11
        healthTitle.name = "hudElement"
        addChild(healthTitle)

        // Create health icons instead of number
        for i in 0..<3 {
            if childNode(withName: "heart_\(i)") != nil { continue }
            let heart = SKShapeNode(circleOfRadius: 8)
            heart.fillColor = .red
            heart.strokeColor = .white
            heart.lineWidth = 2
            heart.name = "heart_\(i)"
            heart.position = CGPoint(
                x: size.width - 60 + CGFloat(i * 25),
                y: size.height - 100
            )
            heart.zPosition = 11
            addChild(heart)
        }

        pauseButton = SKLabelNode(text: "❚❚")
        pauseButton.fontSize = 28
        pauseButton.fontName = "PressStart2P-Regular"
        pauseButton.fontColor = .white
        pauseButton.name = "pauseButton"
        pauseButton.position = CGPoint(x: size.width - 30, y: 30)
        pauseButton.zPosition = 11
        addChild(pauseButton)

        // Shield indicator title (below health)
        let shieldTitle = SKLabelNode(text: "SHIELDS")
        shieldTitle.fontName = "PressStart2P-Regular"
        shieldTitle.fontSize = hudLabelFontSize
        shieldTitle.fontColor = .cyan
        shieldTitle.horizontalAlignmentMode = .right
        shieldTitle.position = CGPoint(x: size.width - 20, y: size.height - 150)
        shieldTitle.zPosition = 11
        shieldTitle.name = "hudElement"
        addChild(shieldTitle)

        // Multi-shot counter (bottom right, above pause button)
        let multiShotLabel = SKLabelNode(text: "x3")
        multiShotLabel.fontName = "PressStart2P-Regular"
        multiShotLabel.fontSize = 24
        multiShotLabel.fontColor = .orange
        multiShotLabel.horizontalAlignmentMode = .right
        multiShotLabel.name = "multiShotLabel"
        multiShotLabel.position = CGPoint(x: size.width - 30, y: 125)
        multiShotLabel.zPosition = 11
        multiShotLabel.isHidden = true  // Hidden by default
        addChild(multiShotLabel)
    }

    func updateMultiShotDisplay() {
        if let label = childNode(withName: "multiShotLabel") as? SKLabelNode {
            if multiShotCount > 0 {
                label.text = "×3 (\(multiShotCount))"
                label.isHidden = false
            } else {
                label.isHidden = true
            }
        }
    }

    func updateHealthDisplay() {
        for i in 0..<3 {
            if let heart = childNode(withName: "heart_\(i)") as? SKShapeNode {
                print("heart found at index \(i)")
                if i < health {
                    print("heart is alive")
                    heart.fillColor = .red
                    heart.alpha = 1.0
                } else {
                    print("heart is grey")
                    heart.fillColor = .gray
                    heart.alpha = 0.3
                }
            }
        }
    }

    func showPauseMenu() {
        gamePaused = true
        scene?.isPaused = true

        // Semi-transparent background
        let background = SKShapeNode(
            rectOf: CGSize(width: size.width, height: size.height)
        )
        background.fillColor = SKColor.black.withAlphaComponent(0.7)
        background.strokeColor = .clear
        background.position = CGPoint(x: size.width / 2, y: size.height / 2)
        background.name = "pauseBackground"
        background.zPosition = 100
        addChild(background)

        // Pause title
        let pauseLabel = SKLabelNode(text: "PAUSED")
        pauseLabel.fontName = "PressStart2P-Regular"
        pauseLabel.fontSize = 32
        pauseLabel.fontColor = .white
        pauseLabel.position = CGPoint(
            x: size.width / 2,
            y: size.height / 2 + 100
        )
        pauseLabel.name = "pauseMenu"
        pauseLabel.zPosition = 101
        addChild(pauseLabel)

        // Resume button
        let resumeButton = SKLabelNode(text: "Resume")
        resumeButton.fontName = "PressStart2P-Regular"
        resumeButton.fontSize = 18
        resumeButton.fontColor = .green
        resumeButton.name = "resumeButton"
        resumeButton.position = CGPoint(x: size.width / 2, y: size.height / 2)
        resumeButton.zPosition = 101
        addChild(resumeButton)

        // Quit button
        let quitButton = SKLabelNode(text: "Main Menu")
        quitButton.fontName = "PressStart2P-Regular"
        quitButton.fontSize = 18
        quitButton.fontColor = .red
        quitButton.name = "quitButton"
        quitButton.position = CGPoint(
            x: size.width / 2,
            y: size.height / 2 - 60
        )
        quitButton.zPosition = 101
        addChild(quitButton)
    }

    func hidePauseMenu() {
        gamePaused = false
        scene?.isPaused = false

        childNode(withName: "pauseBackground")?.removeFromParent()
        childNode(withName: "pauseMenu")?.removeFromParent()
        childNode(withName: "resumeButton")?.removeFromParent()
        childNode(withName: "quitButton")?.removeFromParent()
    }

    func saveHighScore() {
        let currentHighScore = UserDefaults.standard.integer(
            forKey: "highScore"
        )
        if score > currentHighScore {
            UserDefaults.standard.set(score, forKey: "highScore")
            print("New high score: \(score)")
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let tappedNode = atPoint(location)

        // Handle game over state
        if !gameRunning {
            if tappedNode.name == "restart" {
                let newScene = GameScene(size: self.size)
                newScene.scaleMode = .aspectFill
                view?.presentScene(newScene)
            }

            if tappedNode.name == "mainMenu" {
                let menuScene = MenuScene(size: self.size)
                menuScene.scaleMode = .aspectFill
                let transition = SKTransition.fade(withDuration: 0.5)
                view?.presentScene(menuScene, transition: transition)
            }
            return
        }

        // Handle pause menu
        if gamePaused {
            if tappedNode.name == "resumeButton" {
                hidePauseMenu()
            } else if tappedNode.name == "quitButton" {
                let menuScene = MenuScene(size: self.size)
                menuScene.scaleMode = .aspectFill
                let transition = SKTransition.fade(withDuration: 0.5)
                view?.presentScene(menuScene, transition: transition)
            }
            return
        }

        // Handle pause button
        if tappedNode.name == "pauseButton" {
            showPauseMenu()
            return
        }

        // Normal gameplay controls
        let moveAction = SKAction.move(to: location, duration: 0.2)
        player.run(moveAction)

        let currentTime = CACurrentMediaTime()
        if currentTime - lastShotTime > shotCooldown {
            createBullet(at: player.position)
            lastShotTime = currentTime
        }
    }

    func checkPowerUpCollisions() {
        for powerUp in powerUps {
            if powerUp.frame.intersects(player.frame) {
                // Collected power-up!
                activatePowerUp(powerUp)
                removePowerUp(powerUp)
                return
            }
        }
    }
    func activateRapidFire() {
        rapidFireActive = true
        shotCooldown = 0.1

        print("Rapid Fire activated!")

        // Add thruster boost effect
        let thruster = SKSpriteNode(imageNamed: "fire08")
        thruster.setScale(0.4)
        thruster.position = CGPoint(x: 0, y: -20)
        thruster.name = "rapidFireThruster"
        thruster.zPosition = -1
        player.addChild(thruster)

        // Animate thruster
        let flicker = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.5, duration: 0.1),
            SKAction.fadeAlpha(to: 1.0, duration: 0.1),
        ])
        thruster.run(SKAction.repeatForever(flicker))

        // Remove after duration
        let wait = SKAction.wait(forDuration: 5.0)
        let deactivate = SKAction.run { [weak self] in
            self?.rapidFireActive = false
            self?.shotCooldown = 0.3
            thruster.removeFromParent()
            print("Rapid Fire ended")
        }
        run(SKAction.sequence([wait, deactivate]))
    }

    func activateShield() {
        let maxShields = 5

        if shieldCount < maxShields {
            shieldCount += 1
            print("Shield activated! Total shields: \(shieldCount)")
            updateShieldDisplay()
        } else {
            // Already at max shields - convert to points instead
            score += 50
            scoreLabel.text = "\(score)"
            print("Max shields reached! Converted to 50 points")
        }
    }
    func updateShieldDisplay() {
        // Remove old shield icons
        for icon in shieldIcons {
            icon.removeFromParent()
        }
        shieldIcons.removeAll()

        // Create shield icons next to health
        for i in 0..<shieldCount {
            let shield = SKShapeNode(circleOfRadius: 8)
            shield.strokeColor = .cyan
            shield.lineWidth = 2
            shield.fillColor = .cyan.withAlphaComponent(0.3)
            shield.position = CGPoint(
                x: size.width - 60 + CGFloat(i * 25),
                y: size.height - 125
            )
            shield.zPosition = 11
            shield.name = "shieldIcon_\(i)"
            addChild(shield)
            shieldIcons.append(shield)

            // Pulse effect
            let pulse = SKAction.sequence([
                SKAction.fadeAlpha(to: 0.5, duration: 0.5),
                SKAction.fadeAlpha(to: 1.0, duration: 0.5),
            ])
            shield.run(SKAction.repeatForever(pulse))
        }

        // Add shield arc around player if any shields active
        if shieldCount > 0 && player.childNode(withName: "shieldBubble") == nil
        {
            // Create multiple arc layers for fade effect
            let shieldContainer = SKNode()
            shieldContainer.name = "shieldBubble"
            shieldContainer.zPosition = 10

            for i in 0..<5 {
                let baseRadius: CGFloat = 140 + CGFloat(i) * 3
                let alpha: CGFloat = 0.6 - (CGFloat(i) * 0.1)

                // Create an arc instead of full circle
                // Arc goes from -120 degrees to +120 degrees (240 degree arc in front)
                let path = CGMutablePath()

                // Create ellipse by scaling horizontally
                let ellipseTransform = CGAffineTransform(scaleX: 1.25, y: 1.0)  // 1.25x wider

                path.addArc(
                    center: .zero,
                    radius: baseRadius,
                    startAngle: CGFloat.pi * 0.25,  // 45° right of top
                    endAngle: CGFloat.pi * 0.75,  // 45° left of top
                    clockwise: false,
                    transform: ellipseTransform
                )

                let arc = SKShapeNode(path: path)
                arc.strokeColor = .cyan
                arc.lineWidth = 5
                arc.fillColor = .clear
                arc.alpha = alpha
                arc.blendMode = .add
                arc.zPosition = CGFloat(i)

                shieldContainer.addChild(arc)
            }

            player.addChild(shieldContainer)

            let pulse = SKAction.sequence([
                SKAction.scale(to: 1.15, duration: 0.5),
                SKAction.scale(to: 1.0, duration: 0.5),
            ])
            shieldContainer.run(SKAction.repeatForever(pulse))
        } else if shieldCount == 0 {
            player.childNode(withName: "shieldBubble")?.removeFromParent()
        }
    }

    func activateMultiShot() {
        multiShotCount += 10  // Add 10 shots
        updateMultiShotDisplay()

        print("Multi-shot activated! Shots remaining: \(multiShotCount)")

        // Visual feedback - colorize player orange
        player.run(
            SKAction.sequence([
                SKAction.colorize(
                    with: .orange,
                    colorBlendFactor: 0.5,
                    duration: 0.2
                ),
                SKAction.wait(forDuration: 0.5),
                SKAction.colorize(withColorBlendFactor: 0, duration: 0.2),
            ])
        )
    }

    func activatePowerUp(_ powerUp: SKSpriteNode) {
        if let name = powerUp.name {
            switch name {
            case "powerup_rapidfire":
                activateRapidFire()

            case "powerup_shield":
                activateShield()

            case "powerup_multishot":
                activateMultiShot()

            default:
                break
            }
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        // UpdateUpdate player position immediately for smooth following
        player.position = location
    }

    override func update(_ currentTime: TimeInterval) {
        guard gameRunning else { return }

        // Initialize start time on first update
        if survivalTime == 0 {
            survivalTime = currentTime
        }

        // Calculate how long the game has been running
        let gameTime = currentTime - survivalTime

        // Increase difficulty gradually, cap at 3x
        difficulty = 1.0 + (gameTime / 30.0)  // Gets harder every 30 seconds
        difficulty = min(difficulty, 3.0)  // Cap at 3x difficulty

        let adjustedSpawnInterval = enemySpawnInterval / difficulty
        let minimumSpawnInterval: TimeInterval = 0.2  // Never faster than 0.2 seconds
        let finalSpawnInterval = max(
            adjustedSpawnInterval,
            minimumSpawnInterval
        )

        // Spawn power-ups
        if currentTime - lastPowerUpSpawnTime > powerUpSpawnInterval {
            spawnPowerUp()
            lastPowerUpSpawnTime = currentTime
        }

        // Spawn enemies at increasing rate (but not during boss fights)
        if !bossActive && currentTime - lastEnemySpawnTime > finalSpawnInterval
        {
            spawnEnemy()
            lastEnemySpawnTime = currentTime
        }

        // Check for collisions
        checkCollisions()
        checkPlayerCollisions()
        checkPowerUpCollisions()
    }

}

extension SKSpriteNode {
    func addGlow(radius: CGFloat, color: UIColor) {
        // Create multiple glow layers for better effect
        for i in 1...3 {
            let glow = SKShapeNode(
                circleOfRadius: self.size.width / 2 + CGFloat(i) * 3
            )
            glow.fillColor = color
            glow.strokeColor = .clear
            glow.alpha = 0.2 / CGFloat(i)  // Fade out as it gets bigger
            glow.zPosition = -1
            glow.blendMode = .add  // Makes it glow!
            self.addChild(glow)
        }
    }
}
