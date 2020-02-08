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
    
    func makeUIView(context: UIViewRepresentableContext<MapView>) -> MKMapView {
        setupRegionForMap()
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

class MapSearchingViewModel: ObservableObject {
    @Published var annotations = [MKAnnotation]()
    @Published var isSearching = false
    @Published var searchQuery = "" {
        didSet {
            print("search query changing: \(searchQuery)")
        }
    }
    @Published var mapItems = [MKMapItem]()
    @Published var selectedItem: MKMapItem?

    var cancellabe: AnyCancellable?
    
    init() {
        cancellabe = $searchQuery.debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink(receiveValue: { [weak self] (query) in
                self?.performSearch(query: query)
            })
    }

    func performSearch(query: String) {
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
            MapView(annotations: viewModel.annotations, selectItem: viewModel.selectedItem).edgesIgnoringSafeArea(.all)
            VStack(spacing: 12) {
                HStack {
                    TextField("Search terms", text: $viewModel.searchQuery)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.white)
                    
                }.shadow(radius: 3)
                    .padding()
                if (viewModel.isSearching) {
                    Text("Searching....")
                }
                
                Spacer()
                
                ScrollView(.horizontal) {
                    HStack(spacing: 16) {
                        ForEach(viewModel.mapItems, id: \.self) { item in
                            Button(action: {
                                print(item.name ?? "")
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
