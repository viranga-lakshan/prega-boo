import SwiftUI

struct FetusHeartView: View {
    let accentColor: Color
    
    var body: some View {
        ZStack {
            // Heart container
            HeartShape()
                .fill(Color.white.opacity(0.75))
                .shadow(color: Color.black.opacity(0.15), radius: 24, x: 0, y: 12)
            
            // Fetus silhouette inside
            VStack {
                HStack {
                    Spacer()
                    Circle()
                        .fill(accentColor.opacity(0.8))
                        .frame(width: 45, height: 45)
                        .offset(x: -8, y: -20)
                }
                .padding(.top, 20)
                .padding(.right, 30)
                
                Spacer()
                
                HStack {
                    VStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(accentColor.opacity(0.7))
                            .frame(width: 16, height: 32)
                        
                        RoundedRectangle(cornerRadius: 8)
                            .fill(accentColor.opacity(0.6))
                            .frame(width: 12, height: 24)
                    }
                    .offset(x: 12, y: 8)
                    
                    Spacer()
                }
                .padding(.bottom, 40)
                .padding(.leading, 20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 280, height: 320)
    }
}

struct HeartShape: Shape {
    func path(in rect: CGRect) -> Path {
        let width = rect.width
        let height = rect.height
        let midX = width / 2
        
        var path = Path()
        
        // Start at bottom
        path.move(to: CGPoint(x: midX, y: height * 0.95))
        
        // Right side curve
        path.addCurve(
            to: CGPoint(x: width * 0.85, y: height * 0.35),
            control1: CGPoint(x: width, y: height * 0.75),
            control2: CGPoint(x: width, y: height * 0.45)
        )
        
        // Right lobe
        path.addCurve(
            to: CGPoint(x: midX * 0.75, y: height * 0.15),
            control1: CGPoint(x: width * 0.75, y: 0),
            control2: CGPoint(x: midX * 0.85, y: 0)
        )
        
        // Left lobe
        path.addCurve(
            to: CGPoint(x: width * 0.15, y: height * 0.35),
            control1: CGPoint(x: midX * 0.15, y: 0),
            control2: CGPoint(x: width * 0.25, y: 0)
        )
        
        // Left side curve back to bottom
        path.addCurve(
            to: CGPoint(x: midX, y: height * 0.95),
            control1: CGPoint(x: 0, y: height * 0.45),
            control2: CGPoint(x: 0, y: height * 0.75)
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
