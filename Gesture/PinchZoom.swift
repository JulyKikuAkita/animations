//
//  PinchZoom.swift
//  animation

import SwiftUI

struct PinchZoomDemoView: View {
    var body: some View {
        ZoomContainer {
            TabView {
                NavigationStack {
                    ScrollView {
                        VStack(spacing: 15) {
                            ForEach(profiles) { profile in
                                CardView(profile)
                            }
                        }
                        .padding(15)
                    }
                    .navigationTitle("Instagram")
                }
                .tabItem {
                    Image(systemName: "house")
                    Text("Home")
                }
                
                Text("test")
                    .tabItem {
                        Image(systemName: "person.circle")
                        Text("Profile")
                    }
            }
        }
    }
    
    @ViewBuilder
    func CardView(_ profile: Profile) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            GeometryReader {
                let size = $0.size
                Image(profile.profilePicture)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size.width, height: size.height)
                    .clipShape(.rect(cornerRadius: 10))
                    .pinchZoom()
            }
            .frame(height: 240)
            
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(profile.lastMsg)
                        .font(.callout)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    Text("By " + profile.username)
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
                
                Spacer(minLength: 0)
                
                if let link = URL(string: "https://www.youtube.com/watch?v=Z1_49kXP5U0&list=PLimqJDzPI-H97JcePxWNwBXJoGS-Ro3a-&index=91") {
                    Link("Visit", destination: link)
                        .font(.caption)
                        .buttonStyle(.bordered)
                        .buttonBorderShape(.capsule)
                        .tint(.blue)
                }
            }
            .padding(.horizontal, 10)
        }
    }
}

extension View {
    @ViewBuilder
    func pinchZoom(_ dimsBackground: Bool = true) -> some View {
        PinchZoomHelper(dimsBackground: dimsBackground) {
            self
        }
    }
}

/// Zoom container view
/// wrapped the entire tab view with this consenter so that
/// the zooming view will be displayed and zoomed above the tab view
fileprivate struct ZoomContainer<Content: View>: View {
    var content: Content
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content()
    }
    private var containerData = ZoomContainerData()
    var body: some View {
        GeometryReader { _ in
            content
                .environment(containerData)
            
            ZStack(alignment: .topLeading) {
                if let view = containerData.zoomingView {
                    Group {
                        if containerData.dimsBackground {
                            Rectangle()
                                .fill(.black.opacity(0.25))
                                .opacity(containerData.zoom - 1)
                        }
                        
                        view
                            .scaleEffect(containerData.zoom, anchor: containerData.zoomAnchor)
                            .offset(containerData.dragOffset)
                            /// view position
                            .offset(x: containerData.viewRect.minX, y: containerData.viewRect.minY)

                    }
                }
            }
            .ignoresSafeArea()
        }
    }
}

/// Observable class to share data between container, which manages offset updating and zoom
/// and child views, which manages gestures
@Observable
fileprivate class ZoomContainerData {
    var zoomingView: AnyView?
    var viewRect: CGRect = .zero
    var dimsBackground: Bool = false
    /// View properties
    var zoom: CGFloat = 1
    var zoomAnchor: UnitPoint = .center
    var dragOffset: CGSize = .zero
    var isResetting:Bool = false /// avoid new event triggered while animation is still in progress
}

/// Helper View
private struct PinchZoomHelper<Content: View>: View {
    var dimsBackground: Bool
    @ViewBuilder var content: Content
    
    /// View properties
    @Environment(ZoomContainerData.self) private var containerData
    @State private var config: Config = .init()
    var body: some View {
        content
            .opacity(config.hideSourceView ? 0 : 1)
            .overlay(GestureOverlay(config: $config))
            .overlay {
                GeometryReader {
                    let rect = $0.frame(in: .global)
                    
                    Color.clear
                        .onChange(of: config.isGestureActive) { oldValue, newValue in
                            if newValue {
                                guard !containerData.isResetting else { return }
                                /// Showing view on zoom container
                                containerData.viewRect = rect
                                containerData.zoomAnchor = config.zoomAnchor
                                containerData.dimsBackground = dimsBackground
                                containerData.zoomingView = .init(erasing: content)
                                /// Hiding source view
                                config.hideSourceView = true
                            } else {
                                /// Resetting to it's initial position with animation
                                containerData.isResetting = true
                                withAnimation(.snappy(duration: 0.3, extraBounce: 0), completionCriteria: .logicallyComplete) {
                                    containerData.dragOffset = .zero
                                    containerData.zoom = 1
                                } completion: {
                                    /// Resetting Config
                                    config = .init()
                                    /// Removing view from container layer
                                    containerData.zoomingView = nil
                                    containerData.isResetting = false
                                }
                            }
                            
                        }
                        .onChange(of: config) { oldValue, newValue in
                            if config.isGestureActive && !containerData.isResetting {
                                /// Updating View's position and scale in Zoom container
                                containerData.zoom = config.zoom
                                containerData.dragOffset = config.dragOffset
                            }
                        }
                }
            }
    }
}

/// UIKit gestures overlay
fileprivate struct GestureOverlay: UIViewRepresentable {
    @Binding var config: Config
    
    func makeCoordinator() -> Coordinator {
        Coordinator(config: $config)
    }
    
    func makeUIView(context: Context) -> some UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear
        
        // Pan Gesture
        let panGesture = UIPanGestureRecognizer()
        panGesture.name = "PINCHPANGESTURE"
        panGesture.minimumNumberOfTouches = 2
        panGesture.addTarget(context.coordinator, action: #selector(Coordinator.panGesture(gesture:)))
        panGesture.delegate = context.coordinator
        view.addGestureRecognizer(panGesture)
        
        // Pinch Gesture
        let pinchGesture = UIPinchGestureRecognizer()
        pinchGesture.name = "PINCHZOOMGESTURE"
        pinchGesture.addTarget(context.coordinator, action: #selector(Coordinator.pinchGesture(gesture:)))
        pinchGesture.delegate = context.coordinator
        view.addGestureRecognizer(pinchGesture)

        return view
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {}
    
    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        @Binding var config: Config
        init(config: Binding<Config>) {
            self._config = config
        }
        
        @objc
        func panGesture(gesture: UIPanGestureRecognizer) {
            if gesture.state == .began || gesture.state == .changed {
                let translation = gesture.translation(in: gesture.view)
                config.dragOffset = .init(width: translation.x, height: translation.y)
                config.isGestureActive = true
            } else { /// update gesture state and then reset the zoom and offset values in Swift UI with animations
                config.isGestureActive = false
            }
        }
        
        @objc
        func pinchGesture(gesture: UIPinchGestureRecognizer) {
            if gesture.state == .began {
                let location = gesture.location(in: gesture.view)
                if let bounds = gesture.view?.bounds { /// pinpoint the anchor point where the pinch begin and zoom the view from here
                    config.zoomAnchor = .init(x: location.x / bounds.width, y: location.y / bounds.height)
                }
            }
            if gesture.state == .began || gesture.state == .changed {
                let scale = max(gesture.scale, 1)
                config.zoom = scale
                config.isGestureActive = true
            } else {
                config.isGestureActive = false
            }
        }
        
        /// make both pan and pinch gesture work simultaneously
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            if gestureRecognizer.name == "PINCHPANGESTURE" && otherGestureRecognizer.name == "PINCHZOOMGESTURE" {
                return true
            }
            return false
        }
    }
}

fileprivate struct Config: Equatable {
    var isGestureActive: Bool = false
    var zoom: CGFloat = 1
    var zoomAnchor: UnitPoint = .center
    var dragOffset: CGSize = .zero
    var hideSourceView: Bool = false
}


#Preview {
    PinchZoomDemoView()
}
