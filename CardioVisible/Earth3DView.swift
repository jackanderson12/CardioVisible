//
//  Earth3DView.swift
//  CardioVisible
//
//  Created by Jack Anderson on 12/9/23.
//

import SwiftUI
import RealityKit

struct Earth3DView: UIViewRepresentable {
    class Coordinator {
        var rotationTimer: Timer?
        
        func startRotation(for entity: ModelEntity) {
            rotationTimer?.invalidate()
            rotationTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 600.0, repeats: true, block: { _ in
                var currentTransform = entity.transform
                currentTransform.rotation *= simd_quatf(angle: Float.pi / 1800, axis: SIMD3<Float>(0, 1, 0)) // Adjust angle for speed
                entity.transform = currentTransform
            })
        }
    }
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        if let modelEntity = try? ModelEntity.loadModel(named: "earth.usdz") {
            modelEntity.scale = SIMD3<Float>(repeating: 0.005)
            
            let anchorEntity = AnchorEntity(world: [0, 0, -1])
            anchorEntity.addChild(modelEntity)
                        
            // Create and configure a directional light
            let directionalLight = DirectionalLight()
            directionalLight.light.intensity = 1000 // Adjust intensity as needed
            directionalLight.light.color = .white // Adjust color as needed
            directionalLight.orientation = simd_quatf(angle: .pi / 4, axis: [1, 0, 0]) // Adjust orientation as needed
            anchorEntity.addChild(directionalLight)
            
            arView.scene.addAnchor(anchorEntity)

            
            context.coordinator.startRotation(for: modelEntity)
        } else {
            print("Failed to load the model.")
        }
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
}



