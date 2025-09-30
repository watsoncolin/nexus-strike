//
//  GameViewController.swift
//  ArcadeShooter
//
//  Created by Colin Watson on 9/28/25.
//

import GameplayKit
import SpriteKit
import UIKit

class GameViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        // Start with menu scene instead of game scene
        let menuScene = MenuScene(size: CGSize(width: 414, height: 896))
        menuScene.scaleMode = .aspectFill

        if let view = self.view as! SKView? {
            view.presentScene(menuScene)

            view.ignoresSiblingOrder = true

            view.showsFPS = true
            view.showsNodeCount = true
        }
    }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
