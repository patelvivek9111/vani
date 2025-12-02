//
//  CherryBlossomView.swift
//  Vani
//
//  Cherry blossom falling animation for Sacred Lotus theme.
//

import SwiftUI

// MARK: - Cherry Blossom Model

struct CherryBlossomPetal: Identifiable {
    let id: UUID
    let startX: CGFloat
    let size: CGFloat
    let duration: Double
    let delay: Double
    let swayAmount: CGFloat
    let rotationSpeed: Double
}

// MARK: - Cherry Blossom Petal View

struct CherryBlossomPetalView: View {
    let petal: CherryBlossomPetal
    
    @State private var progress: CGFloat = 0
    @State private var rotation: Double = 0
    
    var body: some View {
        GeometryReader { geo in
            let screenHeight = geo.size.height
            
            // Calculate position - falls from top to bottom with gentle sway
            let yPos = -50 + ((screenHeight + 100) * progress)
            let swayOffset = sin(progress * .pi * 3) * petal.swayAmount
            let xPos = petal.startX + swayOffset
            
            // Petal shape
            CherryPetalShape()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.75, blue: 0.8).opacity(0.9),
                            Color(red: 0.95, green: 0.6, blue: 0.7).opacity(0.7)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: petal.size, height: petal.size * 0.7)
                .shadow(color: Color(red: 0.85, green: 0.55, blue: 0.6).opacity(0.3), radius: 2, y: 1)
                .rotationEffect(.degrees(rotation))
                .rotation3DEffect(.degrees(progress * 180), axis: (x: 0.5, y: 1, z: 0))
                .position(x: xPos, y: yPos)
        }
        .allowsHitTesting(false)
        .onAppear {
            // Start the falling animation
            withAnimation(.linear(duration: petal.duration)) {
                progress = 1.0
            }
            
            // Continuous rotation
            withAnimation(.linear(duration: petal.duration / petal.rotationSpeed).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}

// MARK: - Cherry Petal Shape

struct CherryPetalShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        
        // Create a petal-like shape
        path.move(to: CGPoint(x: width * 0.5, y: 0))
        
        // Right curve
        path.addQuadCurve(
            to: CGPoint(x: width, y: height * 0.6),
            control: CGPoint(x: width * 0.9, y: height * 0.1)
        )
        
        // Bottom right
        path.addQuadCurve(
            to: CGPoint(x: width * 0.5, y: height),
            control: CGPoint(x: width * 0.8, y: height * 0.95)
        )
        
        // Bottom left
        path.addQuadCurve(
            to: CGPoint(x: 0, y: height * 0.6),
            control: CGPoint(x: width * 0.2, y: height * 0.95)
        )
        
        // Left curve back to top
        path.addQuadCurve(
            to: CGPoint(x: width * 0.5, y: 0),
            control: CGPoint(x: width * 0.1, y: height * 0.1)
        )
        
        return path
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color(red: 0.95, green: 0.9, blue: 0.85)
        
        CherryBlossomPetalView(
            petal: CherryBlossomPetal(
                id: UUID(),
                startX: 200,
                size: 20,
                duration: 6,
                delay: 0,
                swayAmount: 50,
                rotationSpeed: 2
            )
        )
    }
    .ignoresSafeArea()
}




