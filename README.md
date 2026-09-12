# Nexus Strike

A fast-paced arcade space shooter built with Swift and SpriteKit for iOS. Survive endless waves of enemies, collect power-ups, and defeat bosses.

[Project website](https://watsoncolin.github.io/nexus-strike/) · [Download on the App Store](https://apps.apple.com/us/app/nexus-strike/id6753197968)

## Features

- Progressive difficulty and level advancement as you defeat enemies.
- Boss battles every three levels.
- Three enemy types: standard red enemies, fast yellow enemies, and tougher purple tanks.
- Shield, rapid-fire, and multi-shot power-ups.
- Scrolling starfields, particle effects, explosions, and screen shake.
- Locally saved high scores and a pause menu.

## Build from source

The current project targets **iOS 26.0** and uses **Swift 5 language mode**. Use Xcode 26 or later with the iOS 26 SDK.

```sh
git clone https://github.com/watsoncolin/nexus-strike.git
cd nexus-strike
open ArcadeShooter.xcodeproj
```

1. Select the `ArcadeShooter` scheme and an iPhone simulator or device.
2. For a physical device, choose your development team in Signing & Capabilities.
3. Build and run with **⌘R**.

## How to play

- **Move:** Touch and hold on the screen; your ship follows your finger.
- **Shoot:** Tap to fire, or keep moving for automatic fire.
- **Collect:** Touch power-up icons to activate abilities.
- **Survive:** Avoid enemy contact and destroy incoming enemies.
- **Fight bosses:** Face a boss every three levels.

## Project structure

- `ArcadeShooter/` — Swift source, scenes, audio, and game assets.
- `ArcadeShooter.xcodeproj/` — Xcode project and shared scheme.
- `asset-sources/` — Source artwork.
- `docs/` — Product page and privacy policy, published with GitHub Pages.

## Game design

Built as a learning project exploring SpriteKit scene management, touch input, collision detection, particle effects, game states, and local persistence with `UserDefaults`.

## Assets and credits

- Graphics: **Space Shooter Redux** by Kenney (CC0), credited in the original project documentation.
- Laser sound: **Laser_07.wav** by LittleRobotSoundFactory (CC BY 4.0), from Freesound.
- Code: Swift and SpriteKit, by **Colin Watson**.

## Privacy

Nexus Strike does not collect user data. High scores are stored locally on your device. See the [privacy policy](https://watsoncolin.github.io/nexus-strike/privacy-policy.html).
