//
//  MapSearchingView.swift
//  GooglePlacesMap
//
//  Created by Sean on 2020/2/2.
//  Copyright © 2020 Sean. All rights reserved.
//

import SwiftUI
import MapKit
import Combine

struct MapView: UIViewRepresentable {
    var annotations = [MKAnnotation]()
    let mapView = MKMapView()
    var selectItem: MKMapItem?
    var currentLocation = CLLocationCoordinate2DMake(37.7666, -122.427290)
    
    class Coordinator: NSObject, MKMapViewDelegate {
        init(mapView: MKMapView) {
            super.init()
            mapView.delegate = self
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if !(annotation is MKPointAnnotation) {
                return nil
            }
            
            let pinAnnotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "id")
            pinAnnotationView.canShowCallout = true
            return pinAnnotationView
        }
    }
    
    func makeCoordinator() -> MapView.Coordinator {
        return Coordinator(mapView: mapView)
    }
    
    func makeUIView(context: UIViewRepresentableContext<MapView>) -> MKMapView {
        setupRegionForMap()
        mapView.showsUserLocation = true
        return mapView
    }
    
    fileprivate func customRegion() -> MKCoordinateRegion{
        let center = CLLocationCoordinate2DMake(37.7666, -122.427290)
        let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        let region = MKCoordinateRegion(center: center, span: span)
        return region
    }
    
    fileprivate func setupRegionForMap() {
        mapView.setRegion(customRegion(), animated: true)
    }
    
    func updateUIView(_ uiView: MKMapView, context: UIViewRepresentableContext<MapView>) {
        let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        let region = MKCoordinateRegion(center: currentLocation, span: span)
        uiView.setRegion(region, animated: false)
        
        if annotations.isEmpty {
            uiView.removeAnnotations(uiView.annotations)
            return
        }
        
        if shouldRefreshAnnotations(mapView: uiView) {
            uiView.removeAnnotations(uiView.annotations)
            uiView.addAnnotations(annotations)
            uiView.showAnnotations(uiView.annotations, animated: false)
        }
        
        annotations.forEach { (annotation) in
            if annotation.title == selectItem?.name {
                uiView.selectAnnotation(annotation, animated: true)
            }
        }
    }
    
    fileprivate func shouldRefreshAnnotations(mapView: MKMapView) -> Bool {
        let grouped = Dictionary(grouping: mapView.annotations, by: { $0.title ?? ""})
        for (_, annotation) in annotations.enumerated() {
            if grouped[annotation.title ?? ""] == nil {
                return true
            }
        }
        return false
    }
    
    typealias UIViewType = MKMapView
}

class MapSearchingViewModel:NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var annotations = [MKAnnotation]()
    @Published var isSearching = false
    @Published var searchQuery = "" {
        didSet {
            print("search query changing: \(searchQuery)")
        }
    }
    @Published var mapItems = [MKMapItem]()
    @Published var selectedItem: MKMapItem?
    @Published var currentLocation = CLLocationCoordinate2DMake(37.7666, -122.427290)
    @Published var keyboardHeight: CGFloat = 0

    var cancellabe: AnyCancellable?
    let locationManager = CLLocationManager()
    
    override init() {
        super.init()
        cancellabe = $searchQuery.debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink(receiveValue: { [weak self] (query) in
                self?.performSearch(query: query)
            })
        listenForKeyboardNotifications()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            locationManager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let fisrtLocation = locations.first else { return }
        currentLocation = fisrtLocation.coordinate
    }
    
    fileprivate func listenForKeyboardNotifications() {
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { [weak self] (notification) in
            guard let value = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
            let keyboardFrame = value.cgRectValue
            let window = UIApplication.shared.windows.filter({$0.isKeyWindow}).first
            
            withAnimation(.easeOut(duration: 0.25)) {
                self?.keyboardHeight = keyboardFrame.height - window!.safeAreaInsets.bottom
            }
        }
        
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { [weak self] (notification) in
            withAnimation(.easeOut(duration: 0.25)) {
                self?.keyboardHeight = 0
            }
        }
    }

    fileprivate func performSearch(query: String) {
        isSearching = true
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        let localSearch = MKLocalSearch(request: request)
        localSearch.start {(resp, err) in
            var queryAnnotations = [MKAnnotation]()
            self.mapItems = resp?.mapItems ?? []
            resp?.mapItems.forEach({ (mapItem) in
                let annotation = MKPointAnnotation()
                annotation.title = mapItem.name ?? ""
                annotation.coordinate = mapItem.placemark.coordinate
                queryAnnotations.append(annotation)
            })
            
            self.annotations = queryAnnotations
            self.isSearching = false
        }
    }
}

struct MapSearchingView: View {
    @ObservedObject var viewModel = MapSearchingViewModel()
    
    var body: some View {
        ZStack(alignment: .top) {
            MapView(annotations: viewModel.annotations, selectItem: viewModel.selectedItem, currentLocation:  viewModel.currentLocation).edgesIgnoringSafeArea(.all)
            VStack(spacing: 12) {
                HStack {
                    TextField("Search terms", text: $viewModel.searchQuery)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.white)
                    
                }.padding()
                
                if (viewModel.isSearching) {
                    Text("Searching....")
                }
                
                Spacer()
                
                ScrollView(.horizontal) {
                    HStack(spacing: 16) {
                        ForEach(viewModel.mapItems, id: \.self) { item in
                            Button(action: {
                                self.viewModel.selectedItem = item
                            }) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.name ?? "")
                                        .font(.headline)
                                    Text(item.placemark.title ?? "")
                                }
                                .padding()
                                .frame(width: 200)
                                .background(Color.white)
                                .cornerRadius(5)
                            }.foregroundColor(Color.black)
                        }
                    }.padding(.horizontal, 16)
                }.shadow(radius: 5)
                
                Spacer().frame(height: viewModel.keyboardHeight)
            }
        }
    }
}

//Button(action: {
//    self.viewModel.performSearch(query: "airport")
//}, label: {
//    Text("Search for airport")
//        .padding()
//        .background(Color.white)
//})
//
//Button(action: {
//    self.viewModel.annotations.removeAll()
//}, label: {
//    Text("Clear")
//    .padding()
//    .background(Color.white)
//})

struct MapSearchingView_Previews: PreviewProvider {
    static var previews: some View {
        MapSearchingView()
    }
}
