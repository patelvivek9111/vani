//
//  SplashView.swift
//  Vani
//
//  Premium splash screen for returning users.
//

import SwiftUI

struct SplashView: View {
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var glowIntensity: Double = 0
    @State private var particleOffset: CGFloat = 0
    
    @EnvironmentObject private var settings: SettingsManager
    
    let onComplete: () -> Void
    
    private var theme: AppTheme { settings.appTheme }
    
    var body: some View {
        ZStack {
            // Premium dark gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.08),
                    Color(red: 0.08, green: 0.08, blue: 0.12),
                    Color(red: 0.05, green: 0.05, blue: 0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Subtle texture overlay - floating golden particles
            GeometryReader { geo in
                ForEach(0..<12, id: \.self) { index in
                    let baseX = Double(index) * 0.3 * geo.size.width
                    let baseY = Double(index) * 0.25 * geo.size.height
                    
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.95, green: 0.85, blue: 0.55).opacity(0.4),
                                    Color(red: 0.85, green: 0.70, blue: 0.35).opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 3, height: 3)
                        .position(
                            x: baseX,
                            y: baseY + particleOffset
                        )
                        .blur(radius: 1)
                }
            }
            
            // Radial glow effect
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.95, green: 0.85, blue: 0.55).opacity(glowIntensity * 0.15),
                            Color(red: 0.85, green: 0.70, blue: 0.35).opacity(glowIntensity * 0.08),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 50,
                        endRadius: 300
                    )
                )
                .frame(width: 600, height: 600)
                .blur(radius: 60)
            
            // Main content
            VStack(spacing: 32) {
                Spacer()
                
                // Premium calligraphy logo
                ZStack {
                    // Ink bleed layers
                    CalligraphyDoubleStrokeShape()
                        .fill(Color(red: 0.85, green: 0.70, blue: 0.35).opacity(0.2 * logoOpacity))
                        .frame(width: 70, height: 140)
                        .offset(x: 1.5, y: 1.5)
                        .blur(radius: 2.5)
                    
                    CalligraphyDoubleStrokeShape()
                        .fill(Color(red: 0.85, green: 0.70, blue: 0.35).opacity(0.3 * logoOpacity))
                        .frame(width: 70, height: 140)
                        .offset(x: 0.8, y: 0.8)
                        .blur(radius: 1.5)
                    
                    // Main calligraphy strokes
                    CalligraphyDoubleStrokeShape()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.98, green: 0.88, blue: 0.60),
                                    Color(red: 0.92, green: 0.78, blue: 0.45),
                                    Color(red: 0.88, green: 0.72, blue: 0.40),
                                    Color(red: 0.85, green: 0.70, blue: 0.35),
                                    Color(red: 0.90, green: 0.75, blue: 0.42),
                                    Color(red: 0.95, green: 0.85, blue: 0.55)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 70, height: 140)
                        .shadow(color: Color(red: 0.85, green: 0.70, blue: 0.35).opacity(0.6), radius: 8, x: 0, y: 4)
                        .shadow(color: Color(red: 0.95, green: 0.85, blue: 0.55).opacity(0.4), radius: 12, x: 0, y: -2)
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)
                
                // App name with premium typography
                Text("Vāṇī")
                    .font(.system(size: 48, weight: .light, design: .serif))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.95),
                                Color.white.opacity(0.85)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: Color(red: 0.95, green: 0.85, blue: 0.55).opacity(0.3), radius: 4, x: 0, y: 2)
                    .opacity(textOpacity)
                
                // Elegant tagline
                Text("Daily Wisdom")
                    .font(.system(size: 14, weight: .light, design: .serif))
                    .foregroundStyle(Color.white.opacity(0.5))
                    .tracking(2)
                    .opacity(textOpacity)
                
                Spacer()
            }
        }
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        // Sequence: Logo appears → Glow intensifies → Text fades in → Fade out
        
        // Step 1: Logo scale and fade in
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }
        
        // Step 2: Glow intensifies
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeOut(duration: 0.5)) {
                glowIntensity = 1.0
            }
        }
        
        // Step 3: Text fades in
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeOut(duration: 0.4)) {
                textOpacity = 1.0
            }
        }
        
        // Step 4: Particles animate
        withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
            particleOffset = 100
        }
        
        // Step 5: Fade out and complete (brief display for returning users)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.easeIn(duration: 0.4)) {
                logoOpacity = 0
                textOpacity = 0
                glowIntensity = 0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                onComplete()
            }
        }
    }
}

#Preview {
    SplashView {
        print("Splash complete")
    }
}

