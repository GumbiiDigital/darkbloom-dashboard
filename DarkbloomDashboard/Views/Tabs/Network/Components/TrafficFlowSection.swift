import SwiftUI
import MapKit
import FiveKit

extension NetworkTab {
    struct TrafficFlowSection: View {
        static var animationDefaultValue: Bool {
            #if os(macOS)
            true
            #else
            false
            #endif
        }
        
        @State private var shouldAnimate: Bool = Self.animationDefaultValue
        @State private var mapStyle: TrafficFlowGraph.FlowMapStyle = .globe
        
        let stats: DarkbloomStats
        
        var body: some View {
            Section {
                TrafficFlowGraph(shouldAnimate: $shouldAnimate, mapStyle: $mapStyle)
            } header: {
                HStack(alignment: .bottom) {
                    Text("Traffic Flow")
                    Spacer()
                    #if os(macOS)
                    HStack {
                        Picker("Style", selection: $mapStyle) {
                            Text("2D").tag(TrafficFlowGraph.FlowMapStyle.flat)
                            Text("3D").tag(TrafficFlowGraph.FlowMapStyle.globe)
                        }
                        .pickerStyle(.segmented)
                        Toggle("Animate", isOn: $shouldAnimate)
                    }
                    .controlSize(.small)
                    #endif
                }
            }
        }
    }
}

extension NetworkTab.TrafficFlowSection {
    struct TrafficFlowGraph: View {
        @Environment(APIDataController.self) private var dataController
        
        private static let globeDistance: CLLocationDistance = 30_000_000
        private static let globeSpinDegreesPerSecond: CLLocationDegrees = 8
        
        @State private var globeLongitude: CLLocationDegrees = 0
        @State private var position: MapCameraPosition = .camera(Self.globeCamera(centerLongitude: 0))
        
        enum MapLocation: Hashable {
            case provider(DarkbloomProviderLocation)
            case request(DarkbloomRequestLocation)
        }
        
        enum FlowMapStyle: Hashable {
            case globe
            case flat
            
            var displayName: String {
                switch self {
                    case .globe: "3D"
                    case .flat: "2D"
                }
            }
            
            var mapStyle: MapStyle {
                switch self {
                    case .globe: MapStyle.imagery(elevation: .realistic)
                    case .flat: MapStyle.imagery(elevation: .flat)
                }
            }
        }
        
        @State private var selection: MapLocation?
        @State private var dashPhase: CGFloat = 0
        
        @Binding var shouldAnimate: Bool
        @Binding var mapStyle: FlowMapStyle
        
        var body: some View {
            Map(position: $position, interactionModes: [.pan, .zoom], selection: $selection) {
                if let stats = dataController.stats {
                    let minMaxProviders = stats.providerLocations.minmax(byValue: \.providers)
                    let minProviders = minMaxProviders?.min ?? 0
                    let maxProviders = minMaxProviders?.max ?? 1
                    ForEach(stats.providerLocations, id: \.key) { location in
                        let coordinate = CLLocationCoordinate2D(
                            latitude: location.latitude,
                            longitude: location.longitude
                        )
                        let t: CGFloat = CGFloat((location.providers - minProviders) / (maxProviders - minProviders))
                        let size: CGFloat = CGFloat.lerp(a: 12, b: 20, t: t)
                        Annotation(
                            coordinate: coordinate,
                            content: {
                                RoundedRectangle(cornerRadius: 6)
                                    .rotation(.degrees(45))
                                    .fill(Color.accent)
                                    .frame(width: size, height: size)
                            },
                            label: {
                                VStack(alignment: .leading) {
                                    Text("\(location.city), \(location.regionCode), \(location.countryCode)").bold()
                                    Text("\(location.providers) providers")
                                }
                            }
                        )
                        .mapItemDetailSelectionAccessory(.callout(.full))
                        .tag(MapLocation.provider(location))
                    }
                    
                    let minMaxRequests = stats.requestLocations.minmax(byValue: \.providers)
                    let minRequests = minMaxRequests?.min ?? 0
                    let maxRequests = minMaxRequests?.max ?? 1
                    ForEach(stats.requestLocations, id: \.key) { location in
                        let coordinate = CLLocationCoordinate2D(
                            latitude: location.latitude,
                            longitude: location.longitude
                        )
                        let t: CGFloat = CGFloat((location.providers - minRequests) / (maxProviders - maxRequests))
                        let size: CGFloat = CGFloat.lerp(a: 8, b: 16, t: t)
                        Annotation(
                            coordinate: coordinate,
                            content: {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: size, height: size)
                            },
                            label: {
                                VStack(alignment: .leading) {
                                    Text("\(location.city), \(location.regionCode), \(location.countryCode)").bold()
                                    Text("\(location.providers) requests")
                                }
                            }
                        )
                        .mapItemDetailSelectionAccessory(.callout(.full))
                        .tag(MapLocation.request(location))
                    }
                    
                    ForEach(stats.requestFlows, id: \.key) { flow in
                        let coordinates: [CLLocationCoordinate2D] = [
                            CLLocationCoordinate2D(
                                latitude: flow.from.latitude,
                                longitude: flow.from.longitude
                            ),
                            CLLocationCoordinate2D(
                                latitude: flow.to.latitude,
                                longitude: flow.to.longitude
                            ),
                        ]
                        let directionalColor = switch flow.from.kind {
                            case .provider: Color.green
                            case .consumer: Color.accent
                        }
                        MapPolyline(coordinates: coordinates, contourStyle: .geodesic)
                            .stroke(
                                directionalColor,
                                style: StrokeStyle(
                                    lineWidth: 1,
                                    dash: [2, 10],
                                    dashPhase: dashPhase
                                )
                            )
                    }
                }
            }
            .mapStyle(mapStyle.mapStyle)
            .frame(height: 350)
            .clipShape(.rect(cornerRadius: 8))
            .onMapCameraChange(frequency: .continuous) { context in
                if !shouldAnimate {
                    globeLongitude = Self.normalizedLongitude(context.camera.centerCoordinate.longitude)
                }
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { _ in
                        shouldAnimate = false
                    }
            )
            .task {
                var lastFrame = Date.now
                
                while !Task.isCancelled {
                    try? await Task.sleep(for: .milliseconds(0.33))
                    
                    let now = Date.now
                    let elapsed = now.timeIntervalSince(lastFrame)
                    lastFrame = now
                    
                    dashPhase += 1
                    
                    guard shouldAnimate else { continue }
                    
                    globeLongitude = Self.normalizedLongitude(globeLongitude + Self.globeSpinDegreesPerSecond * elapsed)
                    position = .camera(Self.globeCamera(centerLongitude: globeLongitude))
                }
            }
        }
        
        private static func globeCamera(centerLongitude: CLLocationDegrees) -> MapCamera {
            MapCamera(
                centerCoordinate: CLLocationCoordinate2D(latitude: 0, longitude: centerLongitude),
                distance: globeDistance,
                heading: 0,
                pitch: 0
            )
        }
        
        private static func normalizedLongitude(_ longitude: CLLocationDegrees) -> CLLocationDegrees {
            var longitude = longitude.truncatingRemainder(dividingBy: 360)
            if longitude > 180 {
                longitude -= 360
            } else if longitude < -180 {
                longitude += 360
            }
            return longitude
        }
    }
}

#Preview {
    @Previewable @State var viewModel = APIDataController()
    
    Form {
        if let stats = viewModel.stats {
            NetworkTab.TrafficFlowSection(stats: stats)
        }
    }
    .formStyle(.grouped)
    .environment(viewModel)
}
