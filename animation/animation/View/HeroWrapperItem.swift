//
//  HeroWrapperItem.swift
//  animation
//
import SwiftUI

struct HeroWrapper<Content: View>: View {
    @ViewBuilder var content: Content
    /// View Properties
    @Environment(\.scenePhase) private var scene
    @State private var overlayWindow: UIWindow?
    @StateObject private var model: HeroModel = .init()

    var body: some View {
        content
            .customOnChange(value: scene) { newValue in
                if newValue == .active { addOverlayWindow() }
            }
            .environmentObject(model)
    }
    
    /// Adding overlay window
    func addOverlayWindow() {
        for scene in UIApplication.shared.connectedScenes {
            /// Finding active scene
            if let windowScene = scene as? UIWindowScene, scene.activationState == .foregroundActive, overlayWindow == nil {
                let window = UIWindow(windowScene: windowScene)
                window.backgroundColor = .clear
                window.isUserInteractionEnabled = false
                window.isHidden = false
                
                let rootController = UIHostingController(rootView: HeroLayerView().environmentObject(model))
                rootController.view.frame = windowScene.screen.bounds
                rootController.view.backgroundColor = .clear
                window.rootViewController = rootController
                
                self.overlayWindow = window
            }
        }
        
        if overlayWindow == nil {
            print("No window scene found")
        }
    }
}

struct SourceView<Content: View>: View {
    let id: String
    @EnvironmentObject private var model: HeroModel
    @ViewBuilder var content: Content
    var body: some View {
        content
            .opacity(opacity)
            .anchorPreference(key: AnchorKey.self, value: .bounds, transform: { anchor in
                if let index, model.info[index].isActive {
                    return [id: anchor]
                }
                return [:]
            })
            .onPreferenceChange(AnchorKey.self, perform: { value in
                if let index, 
                    model.info[index].isActive,
                    model.info[index].sourceAnchor == nil {
                    model.info[index].sourceAnchor = value[id]
                }
            })
    }
    
    var index: Int? {
        if let index = model.info.firstIndex(where: { $0.infoID == id }) {
            return index
        }
        return nil
    }
    
    var opacity: CGFloat {
        if let index {
            return model.info[index].isActive ? 0 : 1
        }
        return 1
    }
}

struct DestinationView<Content: View>: View {
    var id: String
    @EnvironmentObject private var model: HeroModel
    @ViewBuilder var content: Content
    var body: some View {
        content
            .opacity(opacity)
            .anchorPreference(key: AnchorKey.self, value: .bounds, transform: { anchor in
                if let index, model.info[index].isActive {
                    return ["\(id)DESTINATION": anchor]
                }
                return [:]
            })
            .onPreferenceChange(AnchorKey.self, perform: { value in
                if let index,
                    model.info[index].isActive {
                    model.info[index].destinationAnchor = value["\(id)DESTINATION"]
                }
            })
    }
    
    var index: Int? {
        if let index = model.info.firstIndex(where: { $0.infoID == id }) {
            return index
        }
        return nil
    }
    
    var opacity: CGFloat {
        if let index {
            return model.info[index].isActive ? (model.info[index].hideView ? 1: 0) : 0
        }
        return 1
    }
}

extension View {
    @ViewBuilder
    func heroLayer<Content: View>(
          id:String,
          animate: Binding<Bool>,
          sourceCornerRadius: CGFloat = 0,
          destinationCornerRadius: CGFloat = 0,
          @ViewBuilder content: @escaping () -> Content,
          completion: @escaping (Bool) -> ()
    ) -> some View {
        self
            .modifier(HeroLayerViewModifier(
                id: id,
                animate: animate,
                sourceCornerRadius: sourceCornerRadius,
                destinationCornerRadius: destinationCornerRadius,
                layer: content,
                completion: completion
            ))
    }
}

// access HeroModel environment object for passing details to source and destination views
fileprivate struct HeroLayerViewModifier<Layer: View>: ViewModifier {
    let id:String
    @Binding var animate: Bool
    var sourceCornerRadius: CGFloat
    var destinationCornerRadius: CGFloat
    @ViewBuilder var layer:Layer
    var completion: (Bool) -> ()
    @EnvironmentObject private var model: HeroModel
    func body(content: Content) -> some View {
        content
            .onAppear {
                if !model.info.contains(where: { $0.infoID == id }) {
                    model.info.append(.init(id: id))
                }
            }
            .customOnChange(value: animate) { newValue in
                if let index = model.info.firstIndex(where: { $0.infoID == id }) {
                    /// setting up properites required for animation
                    model.info[index].isActive = true
                    model.info[index].layerView = AnyView(layer)
                    model.info[index].sCornerRadius = sourceCornerRadius
                    model.info[index].dCornerRadius = destinationCornerRadius
                    model.info[index].completion = completion
                    
                    if newValue {
                        /// delay for desintation view to loaded with anchor vlaues
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
                            withAnimation(.snappy(duration: 0.35, extraBounce: 0)) {
                                model.info[index].animateView = true
                            }
                        }
                    } else {
                        model.info[index].hideView = false
                        withAnimation(.snappy(duration: 0.35, extraBounce: 0)) {
                            model.info[index].animateView = false
                        }
                    }
                }
            }
    }
}

/// Environment Object
fileprivate class HeroModel: ObservableObject {
    @Published var info: [HeroInfo] = []
}

/// Individual Hero Animation View
fileprivate struct HeroInfo: Identifiable {
    private(set) var id: UUID = .init()
    private(set) var infoID: String
    var isActive: Bool = false
    var layerView: AnyView?
    var animateView: Bool = false
    var hideView: Bool = false
    var sourceAnchor: Anchor<CGRect>?
    var destinationAnchor: Anchor<CGRect>?
    var sCornerRadius: CGFloat = 0
    var dCornerRadius: CGFloat = 0
    var completion: (Bool) -> () = { _ in }
    
    init(id: String) {
        self.infoID = id
    }
}

//fileprivate struct AnchorKey: PreferenceKey {
//    static func reduce(value: inout [String : Anchor<CGRect>], 
//                       nextValue: () -> [String : Anchor<CGRect>]) {
//        value.merge(nextValue()) { $1 }
//    }
//    static var defaultValue: [String: Anchor<CGRect>] = [:]
//}
extension View {
    @ViewBuilder
    func customOnChange<Value: Equatable>(value: Value, completion: @escaping (Value) -> ()) -> some View {
        if #available(iOS 17, *) {
            self
                .onChange(of: value) { oldValue, newValue in
                    completion(newValue)
                }
        } else {
            self
                .onChange(of: value, perform: { value in
                    completion(value)
                })
        }
    }
}

fileprivate struct HeroLayerView: View {
    @EnvironmentObject private var model: HeroModel
    var body: some View {
        GeometryReader { proxy in
            ForEach($model.info) { $info in
                ZStack {
                    if let sourceAnchor = info.sourceAnchor,
                       let desitinationAnchor = info.destinationAnchor,
                       let layerView = info.layerView,
                       !info.hideView {
                        /// Retrieving bounds data from anchor values
                        let sRect = proxy[sourceAnchor]
                        let dRect = proxy[desitinationAnchor]
                        let animateView = info.animateView
                        let size = CGSize(
                            width: animateView ? dRect.size.width : sRect.size.width,
                            height: animateView ? dRect.size.height : sRect.size.height
                        )
                        
                        /// Position
                        let offset = CGSize(
                            width: animateView ? dRect.minX : sRect.minX,
                            height: animateView ? dRect.minY : sRect.minY
                        )
                        
                        layerView
                            .frame(width: size.width, height: size.height)
                            .clipShape(.rect(cornerRadius: animateView ? info.dCornerRadius : info.sCornerRadius))
                            .offset(offset)
                            .transition(.identity)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    }
                }
                .customOnChange(value: info.animateView) { newValue in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                        if !newValue {
                            /// resetting all properties once view goes to source state
                            info.isActive = false
                            info.layerView = nil
                            info.sourceAnchor = nil
                            info.destinationAnchor = nil
                            info.sCornerRadius = 0
                            info.dCornerRadius = 0
                            
                            info.completion(false)
                        } else {
                            info.hideView = true
                            info.completion(true)
                        }
                    }
                }
            }
        }
        
    }
}

fileprivate class PassthroughWindow: UIWindow {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let view = super.hitTest(point, with: event) else { return nil }
        return rootViewController?.view == view ? view : nil
    }
}
