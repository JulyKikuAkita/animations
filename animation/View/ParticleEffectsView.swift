//
//  ParticleEffectsView.swift
//  animation
// https://www.youtube.com/watch?v=sLdQdOtpf7A
// Key frame animation: 8:01
// https://www.youtube.com/watch?v=HDZdM-YW2iM&list=PLimqJDzPI-H97JcePxWNwBXJoGS-Ro3a-&index=20
import SwiftUI

struct ParticleEffectsView: View {
    /// View properties
    @State private var heart: Bool = true
    @State private var star: Bool = true
    @State private var firework: Bool = true

    /// View properties for keyFrame buttons
    @State private var count: Int = 0

    @State private var imageName: String = "bubbles.and.sparkles"
    @State private var imageName2: String = "ladybug.fill"

    /// Temporary Button Values
    @State private var buttonFrames: [ButtonFrame] = []
    @State private var buttonFrames2: [ButtonFrame] = []

    var body: some View {
        VStack(spacing: 15) {
            HStack(spacing: 20) {
                CustomButton(systemImage: "fireworks", status: firework, activeTint: .orange, inActiveTint: .orange, drop: false, useKeyFrame: true) {
                    firework.toggle()
                    let frame = ButtonFrame(value: count)
                    buttonFrames2.append(frame)
                    toggleAnimation(frame.id, false)
                }
                .buttonRepeatBehavior(.enabled)
                
                CustomNumberKeyFrameView(count: $count, imageName: $imageName)
                
                CustomButton(systemImage: "suit.heart.fill", status: heart, activeTint: .pink, inActiveTint: .red) {
                    heart.toggle()
                }
                
                CustomButton(systemImage: "star.fill", status: star, activeTint: .yellow, inActiveTint: .yellow) {
                    star.toggle()
                }
            }
        }
    }
    
    @ViewBuilder
    func CustomButton(systemImage: String, status: Bool, activeTint: Color, inActiveTint: Color, drop: Bool = true, useKeyFrame: Bool = false, onTap: @escaping () -> ()) -> some View {
        Button(action: onTap) {
            Image(systemName: systemImage)
                .font(.title2)
                .particleEffect(
                    systemImage: systemImage,
                    font: .title2,
                    status: status,
                    activeTint: activeTint,
                    inActiveTint: inActiveTint,
                    drop: drop
                )
                .foregroundColor(status ? activeTint : inActiveTint)
                .padding(.horizontal, 18)
                .padding(.vertical, 8)
                .background {
                    Capsule()
                        .fill(status ? activeTint.opacity(0.25) : Color("ButtonColor"))
                }
                .overlay {
                    if useKeyFrame {
                        ForEach(buttonFrames2) { frame in
                            KeyframeAnimator(initialValue: ButtonFrame(value: 0), trigger: frame.triggerKeyFrame) { frame in
                                /// text with same font style
                                HStack {
                                    Image(systemName: systemImage)
                                }
                                .foregroundColor(status ? activeTint : inActiveTint)
                                .fontWeight(.bold)
                                /// adding background to contrast blur effect
                                .background(.black.opacity(0.6 - frame.opacity))
                                .offset(frame.offset)
                                .opacity(frame.opacity)
                                /// adding blur effect
                                .blur(radius: (1 - frame.opacity) * 10)
                                
                            } keyframes: { _ in
                                /// Definitng key frames
                                KeyframeTrack(\.offset) {
                                    LinearKeyframe(CGSize(width: 0, height: -30), duration: 0.2)
                                    LinearKeyframe(CGSize(width: .random(in: -2...2), height: -70), duration: 0.2)
                                    LinearKeyframe(CGSize(width: .random(in: -2...2), height: -110), duration: 0.4)
                                }
                                
                                KeyframeTrack(\.opacity) {
                                    LinearKeyframe(1, duration: 0.2)
                                    LinearKeyframe(1, duration: 0.2)
                                    LinearKeyframe(0.7, duration: 0.2)
                                    LinearKeyframe(0, duration: 0.2)
                                }
                                
                            }
                        }
                    }
                }
        }
    }
    
    func toggleAnimation(_ id: UUID, _ increment: Bool = true) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) { // we need the delay for keyFrame animation to show up
            if let index = buttonFrames2.firstIndex(where: { $0.id == id }) {
                /// triggering keyframe animation
                buttonFrames2[index].triggerKeyFrame = true
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { /// keyframe animation takes about 0.8, use the same delay to remove frame to decrease memory usage
                    buttonFrames2.removeAll(where: { $0.id  == id })
                }
            }
        }
    }
}

struct CustomNumberKeyFrameView: View {
    @Binding var count: Int
    @Binding var imageName: String
    /// Temporary Button Values
    @State private var buttonFrames: [ButtonFrame] = []

    var body: some View {
        HStack(spacing: 12) {
            Button(action: {
                if count != 0 {
                    let frame = ButtonFrame(value: count)
                    buttonFrames.append(frame)
                    toggleAnimation(frame.id, false)
                }
            }, label: {
                Image(systemName: "minus")
            })
            .buttonRepeatBehavior(.enabled)
            
            Text("\(count)")
                .frame(width: 45, height: 45)
                .background(.white.shadow(.drop(color: .black.opacity(0.15), radius: 5)), in: .rect(cornerRadius: 10))
                .overlay {
                    ForEach(buttonFrames) { frame in
                        KeyframeAnimator(initialValue: ButtonFrame(value: 0), trigger: frame.triggerKeyFrame) { frame in
                            /// text with same font style
                            HStack {
                                Text("\(count)")
//                                Image(systemName: imageName)
                            }
                            .fontWeight(.bold)
                            /// adding background to contrast blur effect
                            .background(.black.opacity(0.6 - frame.opacity))
                            .offset(frame.offset)
                            .opacity(frame.opacity)
                            /// adding blur effect
                            .blur(radius: (1 - frame.opacity) * 10)
                            
                        } keyframes: { _ in
                            /// Definitng key frames
                            KeyframeTrack(\.offset) {
                                LinearKeyframe(CGSize(width: 0, height: -20), duration: 0.2)
                                LinearKeyframe(CGSize(width: .random(in: -2...2), height: -40), duration: 0.2)
                                LinearKeyframe(CGSize(width: .random(in: -2...2), height: -90), duration: 0.4)
                            }
                            
                            KeyframeTrack(\.opacity) {
                                LinearKeyframe(1, duration: 0.2)
                                LinearKeyframe(1, duration: 0.2)
                                LinearKeyframe(0.7, duration: 0.2)
                                LinearKeyframe(0, duration: 0.2)
                            }
                            
                        }
                    }
                }
            
            Button(action: {
                let frame = ButtonFrame(value: count)
                buttonFrames.append(frame)
                toggleAnimation(frame.id)
                
            }, label: {
                Image(systemName: "plus")
            })
            .buttonRepeatBehavior(.enabled)
        }
        .fontWeight(.bold)
        }
    func toggleAnimation(_ id: UUID, _ increment: Bool = true) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) { // we need the delay for keyFrame animation to showup
            if let index = buttonFrames.firstIndex(where: { $0.id == id }) {
                /// triggering keyframe animation
                buttonFrames[index].triggerKeyFrame = true
                
                if increment {
                    count += 1
                } else {
                    count -= 1
                }
                
                removeFrame(id)
            }
        }
    }
    
    func removeFrame(_ id: UUID) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { /// keyframe animation takes about 0.8, use the same delay to remove frame to decrease memory usage
            buttonFrames.removeAll(where: { $0.id  == id })
        }
    }
}

#Preview {
    ParticleEffectsView()
}
