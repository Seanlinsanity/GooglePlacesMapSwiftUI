//
//  MapSearchingView.swift
//  GooglePlacesMap
//
//  Created by Sean on 2020/2/2.
//  Copyright © 2020 Sean. All rights reserved.
//

import SwiftUI
import MapKit

struct MapView: UIViewRepresentable {
    let mapView = MKMapView()
    
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
        
    }
    
    typealias UIViewType = MKMapView
}

struct MapSearchingView: View {
    var body: some View {
        ZStack(alignment: .top) {
            MapView().edgesIgnoringSafeArea(.all)
            HStack {
                Button(action: {
                    print(123)
                }, label: {
                    Text("Search for airport")
                        .padding()
                        .background(Color.white)
                })
                
                Button(action: {
                    print(456)
                }, label: {
                    Text("Search for restaurant")
                    .padding()
                    .background(Color.white)
                })
            }.shadow(radius: 3)
        }
    }
}

struct MapSearchingView_Previews: PreviewProvider {
    static var previews: some View {
        MapSearchingView()
    }
}
