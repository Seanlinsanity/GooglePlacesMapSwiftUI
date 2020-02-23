//
//  DirectionSearchView.swift
//  GooglePlacesMap
//
//  Created by Sean on 2020/2/15.
//  Copyright © 2020 Sean. All rights reserved.
//

import SwiftUI
import MapKit

struct DirectionsMapView: UIViewRepresentable {
    @EnvironmentObject var env: DirectionsEnvironment
    
    let mapView = MKMapView()
    
    func makeCoordinator() -> DirectionsMapView.Coordinator {
        return Coordinator(mapView: mapView)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        init(mapView: MKMapView) {
            super.init()
            mapView.delegate = self
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            let render = MKPolylineRenderer(overlay: overlay)
            render.strokeColor = .red
            render.lineWidth = 5
            return render
        }
    }
    
    func makeUIView(context: UIViewRepresentableContext<DirectionsMapView>) -> MKMapView {
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: UIViewRepresentableContext<DirectionsMapView>) {
        uiView.removeAnnotations(uiView.annotations)
        uiView.removeOverlays(uiView.overlays)
        
        [env.sourceMapItem, env.destinationMapItem].compactMap{$0}.forEach { (mapItem) in
            let annotation = MKPointAnnotation()
            annotation.title = mapItem.name
            annotation.coordinate = mapItem.placemark.coordinate
            uiView.addAnnotation(annotation)
        }
        
        uiView.showAnnotations(uiView.annotations, animated: true)
        
        if let route = env.route {
            uiView.addOverlay(route.polyline)
        }
    }

    
}

struct SelectLocationView: View {
    @EnvironmentObject var envObj: DirectionsEnvironment
    
    @State var searchQuery = ""
    @State var mapItems = [MKMapItem]()
    var body: some View {
        VStack {
            HStack(spacing: 16) {
                Button(action: {
                    self.envObj.isSelectingSource = false
                    self.envObj.isSelectingDestination = false
                }, label: {
                    Image(uiImage: #imageLiteral(resourceName: "back_arrow")).foregroundColor(Color.black)
                })
                TextField("Enter search term", text: $searchQuery).onReceive(NotificationCenter.default.publisher(for: UITextField.textDidChangeNotification).debounce(for: .milliseconds(500), scheduler: RunLoop.main)) { _ in
                    //search
                    let request = MKLocalSearch.Request()
                    request.naturalLanguageQuery = self.searchQuery
                    let search = MKLocalSearch(request: request)
                    search.start {(resp, error) in
                        self.mapItems = resp?.mapItems ?? []
                    }
                }
            }.padding()
            
            if mapItems.count > 0 {
                ScrollView {
                    ForEach(mapItems, id:\.self) { (item) in
                        Button(action: {
                            if (self.envObj.isSelectingDestination) {
                                self.envObj.destinationMapItem = item
                                self.envObj.isSelectingDestination = false
                            } else {
                                self.envObj.sourceMapItem = item
                                self.envObj.isSelectingSource = false
                            }
                        }, label: {
                            HStack {
                                VStack(alignment: .leading) {
                                   Text("\(item.name ?? "")").font(.headline)
                                   Text("\(item.address())")
                               }
                               Spacer()
                            }.padding()
                        }).foregroundColor(Color.black)
                    }
                }
            }
            Spacer()
        }.edgesIgnoringSafeArea(.bottom)

        .navigationBarTitle("")
        .navigationBarHidden(true)
    }
}

struct DirectionSearchView: View {
    @EnvironmentObject var envObj: DirectionsEnvironment
    @State var isPresentingRoute = false
    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                VStack(spacing: 0) {
                    VStack {
                        MapItemView(isSelecting: $envObj.isSelectingSource, title: envObj.sourceMapItem?.name ?? "Source", image: #imageLiteral(resourceName: "start_location_circles"))
                        MapItemView(isSelecting: $envObj.isSelectingDestination, title: envObj.destinationMapItem?.name ?? "Destination", image: #imageLiteral(resourceName: "annotation_icon"))
                    }.padding().background(Color.blue)
                DirectionsMapView().edgesIgnoringSafeArea(.bottom)
                }
                StatusBarView()
                
                VStack {
                    Spacer()
                    Button(action: {
                        self.isPresentingRoute.toggle()
                    }, label: {
                        HStack {
                            Spacer()
                            Text("SHOW ROUTE")
                                .foregroundColor(.white)
                                .padding()
                            Spacer()
                        }.background(Color.black)
                            .cornerRadius(8)
                            .padding()
                    })
                }.sheet(isPresented: $isPresentingRoute, content: {
                    RouteInfoView(route: self.envObj.route)
                })
                
                if (envObj.isCalculateingDirections) {
                    LoadingView()
                }
        }.navigationBarTitle("Directions").navigationBarHidden(true)
        }
    }
}

struct RouteInfoView: View {
    var route: MKRoute?
    
    var body: some View {
        ScrollView {
            VStack {
                Text("\(route?.name ?? "")")
                    .font(.headline)
                    .padding()
                ForEach(route!.steps, id: \.self) { (step) in
                    VStack {
                        if !(step.instructions.isEmpty) {
                            HStack {
                                Text(step.instructions)
                                Spacer()
                                Text("\(String(format: "%.2f mi", step.distance * 0.0062137))")
                            }.padding()
                        }
                    }
                }
            }
        }
    }
}

struct MapItemView: View {

    @EnvironmentObject var envObj: DirectionsEnvironment
    @Binding var isSelecting: Bool
    var title: String
    var image: UIImage
    
    var body: some View {
        HStack(spacing: 16) {
            Image(uiImage: image.withRenderingMode(.alwaysTemplate)).foregroundColor(Color.white).frame(width: 24)
            NavigationLink(destination: SelectLocationView(), isActive: $isSelecting) {
                HStack {
                    Text(title)
                    Spacer()
                }.padding().background(Color.white).cornerRadius(3)
            }
        }
    }
}

struct LoadingView: View {
    var body: some View {
        VStack {
            Spacer()
            VStack {
                LoadingHUD()
                Text("Loading...")
                    .font(.headline)
                    .foregroundColor(.white)
            }.padding()
                .background(Color.black)
                .cornerRadius(5)
            Spacer()
        }
    }
}

struct LoadingHUD: UIViewRepresentable {
    typealias UIViewType = UIActivityIndicatorView
    
    func makeUIView(context: UIViewRepresentableContext<LoadingHUD>) -> UIActivityIndicatorView {
        let aiv = UIActivityIndicatorView(style: .large)
        aiv.color = .white
        aiv.startAnimating()
        return aiv
    }
    
    func updateUIView(_ uiView: UIActivityIndicatorView, context: UIViewRepresentableContext<LoadingHUD>) {
        
    }
}

struct StatusBarView: View {
    var body: some View {
        Spacer().frame(width: UIApplication.shared.windows.filter{$0.isKeyWindow}.first?.frame.width, height: UIApplication.shared.windows.filter{$0.isKeyWindow}.first?.safeAreaInsets.top)
            .background(Color.blue)
            .edgesIgnoringSafeArea(.top)
    }
}

import Combine

class DirectionsEnvironment: ObservableObject {
    @Published var isSelectingSource = false
    @Published var isSelectingDestination = false
    @Published var isCalculateingDirections = false
    
    @Published var sourceMapItem: MKMapItem?
    @Published var destinationMapItem: MKMapItem?
    @Published var route: MKRoute?
    
    var cancellable: AnyCancellable?
    
    init() {
        cancellable = Publishers.CombineLatest($sourceMapItem, $destinationMapItem).sink(receiveValue: { [weak self] (items) in
            let request = MKDirections.Request()
            request.source = items.0
            request.destination = items.1
            self?.isCalculateingDirections = true
            self?.route = nil
            let directions = MKDirections(request: request)
            directions.calculate {(resp, err) in
                self?.isCalculateingDirections = false
                if let err = err {
                    print("Failed to calculate directions: ", err)
                    return
                }
                self?.route = resp?.routes.first
            }
        })
    }
}

struct DirectionSearchView_Previews: PreviewProvider {
    static var env = DirectionsEnvironment()
    static var previews: some View {
        DirectionSearchView().environmentObject(env)
    }
}
