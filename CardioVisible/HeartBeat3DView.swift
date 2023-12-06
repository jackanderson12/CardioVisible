//
//  HeartBeat3DView.swift
//  CardioVisible
//
//  Created by Jack Anderson on 12/5/23.
//

import SwiftUI
import RealityKit

struct HeartBeat3DView: UIViewRepresentable {
    
    var rate: Double // Heart rate in beats per minute

    class Coordinator {
        var playbackControllers = [AnimationPlaybackController]()
        var timer: Timer?

        func setupAnimationTimer(rate: Double, modelEntity: ModelEntity) {
            let interval = 60.0 / rate // Time for one beat
            playbackControllers = modelEntity.availableAnimations.compactMap { animation -> AnimationPlaybackController? in
                modelEntity.playAnimation(animation.repeat())
            }

            timer?.invalidate()
            timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
                self?.playbackControllers.forEach { controller in
                    controller.resume() // Start playing each animation
                    // Optionally, you might need to adjust the timeOffset to sync the animation progress
                }
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator()
    }

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        let filename = "beating-heart-v004a-animated.usdz"

        if let modelEntity = try? ModelEntity.loadModel(named: filename) {
            let anchorEntity = AnchorEntity()
            anchorEntity.addChild(modelEntity)
            arView.scene.addAnchor(anchorEntity)
            
            context.coordinator.setupAnimationTimer(rate: rate, modelEntity: modelEntity)
        }

        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        // If you need to update the heart rate and animation speed
        if let modelEntity = (uiView.scene.anchors.first as? AnchorEntity)?.children.first as? ModelEntity {
            context.coordinator.setupAnimationTimer(rate: rate, modelEntity: modelEntity)
        }
    }
}



