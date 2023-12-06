//
//  HeartBeat3DView.swift
//  CardioVisible
//
//  Created by Jack Anderson on 12/5/23.
//

import Foundation
import SwiftUI
import SceneKit

struct HeartBeat3DView: UIViewRepresentable {
    var rate: Double

    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.scene = SCNScene(named: "beating-heart-v004a-animated.dae")
        scnView.autoenablesDefaultLighting = true
        // Additional SceneKit setup...
        return scnView
    }

    func updateUIView(_ scnView: SCNView, context: Context) {
        // Handle animation based on heart rate
        // You might need to adjust this part based on how your model is animated
        let animationDuration = 60.0 / rate
        scnView.scene?.rootNode.childNodes.forEach { node in
            node.animationPlayer(forKey: "heartbeat")?.play()
            node.animationPlayer(forKey: "heartbeat")?.speed = CGFloat(Float(animationDuration))
        }
    }
}
