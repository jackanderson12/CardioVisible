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
        
        var currentAngleX: Float = 0
        var currentAngleY: Float = 0
        
        func setupAnimationTimer(rate: Double, modelEntity: ModelEntity) {
            let interval = (rate / 60.0) * 1.2 // Animation is 50BPM, correction factor of 1.2
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
        
        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let view = gesture.view as? ARView else { return }
            
            let translation = gesture.translation(in: view)
            let angleY = Float(translation.x) * (Float.pi / 180)
            let angleX = Float(translation.y) * (Float.pi / 180)
            
            if gesture.state == .changed {
                let rotationY = simd_make_float4x4(rotateAboutY: angleY + currentAngleY)
                let rotationX = simd_make_float4x4(rotateAboutX: angleX + currentAngleX)
                let combinedRotation = simd_mul(rotationY, rotationX)
                view.scene.anchors[0].transform.matrix = combinedRotation
            } else if gesture.state == .ended {
                currentAngleY += angleY
                currentAngleX += angleX
            }
        }
        
        func simd_make_float4x4(rotateAboutY radians: Float) -> simd_float4x4 {
            let rows = [
                simd_float4(cos(radians), 0, sin(radians), 0),
                simd_float4(0, 1, 0, 0),
                simd_float4(-sin(radians), 0, cos(radians), 0),
                simd_float4(0, 0, 0, 1)
            ]
            return float4x4(rows: rows)
        }
        
        func simd_make_float4x4(rotateAboutX radians: Float) -> simd_float4x4 {
            let rows = [
                simd_float4(1, 0, 0, 0),
                simd_float4(0, cos(radians), -sin(radians), 0),
                simd_float4(0, sin(radians), cos(radians), 0),
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
            modelEntity.position = [0, -0.08, 0]
            
            let anchorEntity = AnchorEntity()
            addAllChildren(to: anchorEntity, from: modelEntity)
            arView.scene.addAnchor(anchorEntity)
            
            context.coordinator.setupAnimationTimer(rate: rate, modelEntity: modelEntity)
            
            // Create and configure a directional light
            let directionalLight = DirectionalLight()
            directionalLight.light.intensity = 500 // Adjust intensity as needed
            directionalLight.light.color = .white // Adjust color as needed
            directionalLight.orientation = simd_quatf(angle: .pi / 4, axis: [1, 0, 0]) // Adjust orientation as needed
            
            // Add lights to the scene
            let lightAnchor = AnchorEntity()
            lightAnchor.addChild(directionalLight)
            arView.scene.addAnchor(lightAnchor)
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



