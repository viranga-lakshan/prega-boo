import SwiftUI

struct FetusHeartView: View {
    let accentColor: Color
    
    var body: some View {
        ZStack {
            // Heart container with gradient
            HeartShape()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.95),
                            Color.white.opacity(0.70)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color.black.opacity(0.25), radius: 32, x: 4, y: 16)
                .shadow(color: accentColor.opacity(0.15), radius: 20, x: 0, y: 8)
            
            // Inner heart gradient overlay
            HeartShape()
                .stroke(Color.white.opacity(0.4), lineWidth: 2)
            
            // Fetus inside heart
            VStack {
                HStack {
                    Spacer()
                    
                    // Head
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    accentColor.opacity(0.9),
                                    accentColor.opacity(0.6)
                                ]),
                                center: .topLeading,
                                startRadius: 5,
                                endRadius: 30
                            )
                        )
                        .frame(width: 50, height: 50)
                        .offset(x: -12, y: -18)
                }
                .padding(.top, 24)
                .padding(.trailing, 28)
                
                Spacer()
                
                // Body
                HStack(spacing: 0) {
                    VStack(spacing: 4) {
                        // Torso
                        RoundedRectangle(cornerRadius: 10)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        accentColor.opacity(0.85),
                                        accentColor.opacity(0.6)
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 20, height: 38)
                        
                        // Legs
                        HStack(spacing: 6) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(accentColor.opacity(0.7))
                                .frame(width: 8, height: 20)
                            
                            RoundedRectangle(cornerRadius: 6)
                                .fill(accentColor.opacity(0.65))
                                .frame(width: 8, height: 20)
                        }
                    }
                    .offset(x: 8, y: 0)
                    
                    Spacer()
                }
                .padding(.bottom, 48)
                .padding(.leading, 16)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 280, height: 340)
    }
}

struct HeartShape: Shape {
    func path(in rect: CGRect) -> Path {
        let width = rect.width
        let height = rect.height
        let midX = width / 2
        
        var path = Path()
        
        // Bottom point
        path.move(to: CGPoint(x: midX, y: height * 0.95))
        
        // Right side
        path.addCurve(
            to: CGPoint(x: width * 0.88, y: height * 0.32),
            control1: CGPoint(x: width * 1.05, y: height * 0.80),
            control2: CGPoint(x: width * 1.05, y: height * 0.42)
        )
        
        // Right lobe
        path.addCurve(
            to: CGPoint(x: midX * 0.70, y: height * 0.08),
            control1: CGPoint(x: width * 0.88, y: height * -0.05),
            control2: CGPoint(x: midX * 0.78, y: height * -0.05)
        )
        
        // Left lobe
        path.addCurve(
            to: CGPoint(x: width * 0.12, y: height * 0.32),
            control1: CGPoint(x: midX * 0.22, y: height * -0.05),
            control2: CGPoint(x: width * 0.12, y: height * -0.05)
        )
        
        // Left side back to bottom
        path.addCurve(
            to: CGPoint(x: midX, y: height * 0.95),
            control1: CGPoint(x: -0.05, y: height * 0.42),
            control2: CGPoint(x: -0.05, y: height * 0.80)
        )
        
        return path
    }
}

#Preview {
    ZStack {
        LinearGradient(
            colors: [
                Color(red: 1.0, green: 0.94, blue: 0.94),
                Color(red: 0.99, green: 0.76, blue: 0.84)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
        
        FetusHeartView(accentColor: Color(red: 0.87, green: 0.22, blue: 0.42))
    }
}
