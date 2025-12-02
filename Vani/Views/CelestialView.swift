//
//  CelestialView.swift
//  Vani
//
//  Celestial theme animations - shooting stars and star field.
//

import SwiftUI

// MARK: - Celestial Stars Background

struct CelestialStarsBackground: View {
    let seed: Int  // Use for random generation
    let size: CGSize
    
    var body: some View {
        ZStack {
            // Scattered stars - more stars for full screen
            ForEach(0..<60, id: \.self) { i in
                let position = starPosition(for: i)
                let starSize = starSize(for: i)
                let opacity = starOpacity(for: i)
                
                Circle()
                    .fill(Color.white.opacity(opacity))
                    .frame(width: starSize, height: starSize)
                    .position(x: position.x * size.width, y: position.y * size.height)
            }
        }
    }
    
    private func starPosition(for index: Int) -> CGPoint {
        // Use a hash function to create truly random-looking positions
        // This creates a pseudo-random distribution without visible patterns
        func hash(_ value: Int) -> UInt32 {
            var x = UInt32(truncatingIfNeeded: value)
            x = (x ^ (x >> 16)) &* 0x45d9f3b
            x = (x ^ (x >> 16)) &* 0x45d9f3b
            x = x ^ (x >> 16)
            return x
        }
        
        // Generate two independent random values for x and y using different primes
        let xHash = hash(seed + index * 7919) // 7919 is a prime number
        let yHash = hash(seed + index * 104729) // 104729 is another prime number
        
        // Convert to 0.0-1.0 range
        let xSeed = Double(xHash) / Double(UInt32.max)
        let ySeed = Double(yHash) / Double(UInt32.max)
        
        return CGPoint(x: xSeed, y: ySeed)
    }
    
    private func starSize(for index: Int) -> CGFloat {
        let sizes: [CGFloat] = [1.0, 1.5, 2.0, 2.5, 1.2, 1.8, 2.2]
        return sizes[(seed + index) % sizes.count]
    }
    
    private func starOpacity(for index: Int) -> Double {
        let opacities: [Double] = [0.3, 0.5, 0.7, 0.4, 0.6, 0.8, 0.35, 0.55, 0.65]
        return opacities[(seed + index) % opacities.count]
    }
}

// MARK: - Shooting Star View (iOS Weather App Style)

struct ShootingStarView: View {
    let progress: CGFloat  // 0 to 1
    let fromLeft: Bool
    let startY: CGFloat
    
    private let tailLength: CGFloat = 100
    
    var body: some View {
        GeometryReader { geo in
            let screenWidth = geo.size.width
            let travelDistance = screenWidth + 300
            let dropDistance: CGFloat = 200
            
            // Calculate position based on progress
            let xPos: CGFloat = fromLeft
                ? -100 + (travelDistance * progress)
                : screenWidth + 100 - (travelDistance * progress)
            let yPos: CGFloat = startY + (dropDistance * progress)
            
            // Rotation angle for the tail (pointing back along travel path)
            let angle: Double = fromLeft
                ? atan2(Double(dropDistance), Double(travelDistance)) * 180 / .pi
                : 180 - atan2(Double(dropDistance), Double(travelDistance)) * 180 / .pi
            
            ZStack {
                // Outer glow layer
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.6), Color.white.opacity(0.1), Color.clear],
                            startPoint: .trailing,
                            endPoint: .leading
                        )
                    )
                    .frame(width: tailLength, height: 6)
                    .blur(radius: 3)
                
                // Middle glow layer
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.8), Color.white.opacity(0.3), Color.clear],
                            startPoint: .trailing,
                            endPoint: .leading
                        )
                    )
                    .frame(width: tailLength * 0.9, height: 4)
                    .blur(radius: 1.5)
                
                // Core streak
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.white, Color.white.opacity(0.6), Color.clear],
                            startPoint: .trailing,
                            endPoint: .leading
                        )
                    )
                    .frame(width: tailLength * 0.8, height: 2)
                
                // Bright head
                Circle()
                    .fill(Color.white)
                    .frame(width: 4, height: 4)
                    .blur(radius: 1)
                    .offset(x: tailLength * 0.4)
                
                Circle()
                    .fill(Color.white)
                    .frame(width: 3, height: 3)
                    .offset(x: tailLength * 0.4)
            }
            .rotationEffect(.degrees(angle))
            .position(x: xPos, y: yPos)
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Preview

#Preview("Shooting Star") {
    ZStack {
        LinearGradient(
            colors: [
                Color(red: 0.05, green: 0.05, blue: 0.15),
                Color(red: 0.1, green: 0.1, blue: 0.25)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        
        ShootingStarView(
            progress: 0.5,
            fromLeft: true,
            startY: 100
        )
    }
    .ignoresSafeArea()
}




