//
//  DeviceOrientationManager.swift
//  Espresso House
//
//  Created by KibbeWater on 18/12/24.
//


import SwiftUI
import CoreMotion

class DeviceOrientationManager: ObservableObject {
    private let motionManager = CMMotionManager()
    @Published var isUpsideDown = false
    
    init() {
        setupMotionTracking()
    }
    
    private func setupMotionTracking() {
        guard motionManager.isDeviceMotionAvailable else { return }
        
        motionManager.deviceMotionUpdateInterval = 0.1 // Update every 0.1 seconds
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] (motion, error) in
            guard let motion = motion else { return }
            
            // Use gravity vector to detect orientation
            let gravity = motion.gravity
            
            // Check if device is tilted significantly upside down
            if gravity.y > 0.4 {
                self?.isUpsideDown = true
            } else if gravity.y < -0.2 {
                self?.isUpsideDown = false
            }
        }
    }
    
    deinit {
        motionManager.stopDeviceMotionUpdates()
    }
}

// View Modifier for Sensitive Orientation Detection
struct SensitiveOrientationModifier: ViewModifier {
    @StateObject private var orientationManager = DeviceOrientationManager()
    @Binding var isUpsideDown: Bool
    
    func body(content: Content) -> some View {
        content
            .onReceive(orientationManager.$isUpsideDown) { newValue in
                isUpsideDown = newValue
            }
    }
}

// SwiftUI View Extension
extension View {
    func sensitiveUpsideDownDetection(isUpsideDown: Binding<Bool>) -> some View {
        modifier(SensitiveOrientationModifier(isUpsideDown: isUpsideDown))
    }
}