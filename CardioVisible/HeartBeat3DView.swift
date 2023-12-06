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
            let interval = rate / 60.0 // Time for one beat
            playbackControllers = modelEntity.availableAnimations.compactMap { animation -> AnimationPlaybackController? in
                modelEntity.playAnimation(animation.repeat())
            }
            
            timer?.invalidate()
            timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
                self?.playbackControllers.forEach { controller in
                    controller.speed = Float(interval)
                    controller.resume() // Start playing each animation
                    // Optionally, you might need to adjust the timeOffset to sync the animation progress
                }
            }
        }
        
        func startAnimation() {
            playbackControllers.forEach { controller in
                controller.resume()
            }
        }
        
        var currentAngleY: Float = 0
        
        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let view = gesture.view as? ARView else { return }
            
            let translation = gesture.translation(in: view)
            let angleY = Float(translation.x) * (Float.pi / 180) // Convert to radians
            
            if gesture.state == .changed {
                let rotation = simd_make_float4x4(rotateAboutY: angleY + currentAngleY)
                view.scene.anchors[0].transform.matrix = rotation
            } else if gesture.state == .ended {
                currentAngleY += angleY
            }
        }
        
        func simd_make_float4x4(rotateAboutY radians: Float) -> simd_float4x4 {
            let rows = [
                simd_float4(cos(radians), 0, -sin(radians), 0),
                simd_float4(0, 1, 0, 0),
                simd_float4(sin(radians), 0, cos(radians), 0),
                simd_float4(0, 0, 0, 1)
            ]
            return float4x4(rows: rows)
        }
        
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator()
    }
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        let filename = "beating-heart-v004a-animated.usdz"
        
        if let modelEntity = try? ModelEntity.loadModel(named: filename) {
            modelEntity.scale = [0.1, 0.1, 0.1]
            modelEntity.position = [0, 0, 0]
            
            let anchorEntity = AnchorEntity()
            addAllChildren(to: anchorEntity, from: modelEntity)
            arView.scene.addAnchor(anchorEntity)
            
            context.coordinator.setupAnimationTimer(rate: rate, modelEntity: modelEntity)
        }
        
        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        arView.addGestureRecognizer(panGesture)
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        // If you need to update the heart rate and animation speed
        if let modelEntity = (uiView.scene.anchors.first as? AnchorEntity)?.children.first as? ModelEntity {
            context.coordinator.setupAnimationTimer(rate: rate, modelEntity: modelEntity)
            context.coordinator.startAnimation()
        }
    }
    
    func addAllChildren(to parentEntity: Entity, from modelEntity: Entity) {
        parentEntity.addChild(modelEntity)
        for child in modelEntity.children {
            addAllChildren(to: parentEntity, from: child)
        }
    }
}



