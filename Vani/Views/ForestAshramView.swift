//
//  ForestAshramView.swift
//  Vani
//
//  Forest Ashram theme animations - falling leaves.
//

import SwiftUI

// MARK: - Falling Leaf Model

struct FallingLeaf: Identifiable {
    let id: UUID
    let startX: CGFloat
    let size: CGFloat
    let duration: Double
    let swayAmount: CGFloat
    let rotationSpeed: Double
    let leafType: Int // 0, 1, 2 for variety
    let color: Color
}

// MARK: - Falling Leaf View

struct FallingLeafView: View {
    let leaf: FallingLeaf
    
    @State private var progress: CGFloat = 0
    @State private var rotation: Double = 0
    @State private var swayPhase: Double = 0
    
    var body: some View {
        GeometryReader { geo in
            let screenHeight = geo.size.height
            
            // Calculate position - falls with natural swaying
            let yPos = -30 + ((screenHeight + 60) * progress)
            let swayOffset = sin(Double(progress) * .pi * 4 + swayPhase) * Double(leaf.swayAmount)
            let xPos = leaf.startX + CGFloat(swayOffset)
            
            // Leaf shape
            LeafShape(type: leaf.leafType)
                .fill(leaf.color)
                .frame(width: leaf.size, height: leaf.size * 1.3)
                .shadow(color: Color.black.opacity(0.2), radius: 1, y: 1)
                .rotationEffect(.degrees(rotation))
                .rotation3DEffect(.degrees(sin(Double(progress) * .pi * 2) * 30), axis: (x: 1, y: 0, z: 0))
                .position(x: xPos, y: yPos)
        }
        .allowsHitTesting(false)
        .onAppear {
            swayPhase = Double.random(in: 0...(.pi * 2))
            
            // Falling animation
            withAnimation(.linear(duration: leaf.duration)) {
                progress = 1.0
            }
            
            // Tumbling rotation
            withAnimation(.linear(duration: leaf.duration / leaf.rotationSpeed).repeatForever(autoreverses: false)) {
                rotation = Bool.random() ? 360 : -360
            }
        }
    }
}

// MARK: - Leaf Shape

struct LeafShape: Shape {
    let type: Int
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        
        switch type {
        case 0:
            // Oval leaf
            path.move(to: CGPoint(x: width * 0.5, y: 0))
            path.addQuadCurve(
                to: CGPoint(x: width, y: height * 0.5),
                control: CGPoint(x: width * 0.9, y: height * 0.1)
            )
            path.addQuadCurve(
                to: CGPoint(x: width * 0.5, y: height),
                control: CGPoint(x: width * 0.9, y: height * 0.9)
            )
            path.addQuadCurve(
                to: CGPoint(x: 0, y: height * 0.5),
                control: CGPoint(x: width * 0.1, y: height * 0.9)
            )
            path.addQuadCurve(
                to: CGPoint(x: width * 0.5, y: 0),
                control: CGPoint(x: width * 0.1, y: height * 0.1)
            )
            
        case 1:
            // Maple-like leaf
            path.move(to: CGPoint(x: width * 0.5, y: 0))
            path.addLine(to: CGPoint(x: width * 0.65, y: height * 0.25))
            path.addLine(to: CGPoint(x: width, y: height * 0.3))
            path.addLine(to: CGPoint(x: width * 0.7, y: height * 0.45))
            path.addLine(to: CGPoint(x: width * 0.8, y: height * 0.7))
            path.addLine(to: CGPoint(x: width * 0.5, y: height * 0.55))
            path.addLine(to: CGPoint(x: width * 0.2, y: height * 0.7))
            path.addLine(to: CGPoint(x: width * 0.3, y: height * 0.45))
            path.addLine(to: CGPoint(x: 0, y: height * 0.3))
            path.addLine(to: CGPoint(x: width * 0.35, y: height * 0.25))
            path.closeSubpath()
            
        default:
            // Simple rounded leaf
            path.move(to: CGPoint(x: width * 0.5, y: 0))
            path.addCurve(
                to: CGPoint(x: width * 0.5, y: height),
                control1: CGPoint(x: width * 1.1, y: height * 0.3),
                control2: CGPoint(x: width * 0.8, y: height * 0.8)
            )
            path.addCurve(
                to: CGPoint(x: width * 0.5, y: 0),
                control1: CGPoint(x: width * 0.2, y: height * 0.8),
                control2: CGPoint(x: -width * 0.1, y: height * 0.3)
            )
        }
        
        return path
    }
}

// MARK: - Leaf Colors

extension Color {
    static let leafColors: [Color] = [
        Color(red: 0.2, green: 0.5, blue: 0.2),      // Forest green
        Color(red: 0.3, green: 0.55, blue: 0.25),    // Light green
        Color(red: 0.4, green: 0.6, blue: 0.3),      // Sage green
        Color(red: 0.5, green: 0.55, blue: 0.2),     // Yellow-green
        Color(red: 0.35, green: 0.45, blue: 0.2),    // Olive green
    ]
}

// MARK: - Preview

#Preview("Forest Ashram") {
    ZStack {
        LinearGradient(
            colors: [
                Color(red: 0.15, green: 0.25, blue: 0.15),
                Color(red: 0.1, green: 0.2, blue: 0.1)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        
        FallingLeafView(
            leaf: FallingLeaf(
                id: UUID(),
                startX: 200,
                size: 20,
                duration: 8,
                swayAmount: 50,
                rotationSpeed: 2,
                leafType: 0,
                color: .leafColors[0]
            )
        )
    }
    .ignoresSafeArea()
}




