//
//  MainViewController.swift
//  GooglePlacesMap
//
//  Created by Sean on 2020/1/24.
//  Copyright © 2020 Sean. All rights reserved.
//

import UIKit
import MapKit
import LBTATools

extension MainViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "id")
        annotationView.canShowCallout = true
        annotationView.image = UIImage(named: "marker")
        return annotationView
    }
}

class MainViewController: UIViewController {
    let mapView = MKMapView()

    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        setupView()
        setupRegionForMap()
        performLocationSearch()
    }
    
    fileprivate func performLocationSearch() {
        let request = MKLocalSearch.Request()
        request.region = customRegion()
        request.naturalLanguageQuery = "Apple"
        let localSearch = MKLocalSearch(request: request)
        localSearch.start { (res, err) in
            if let err = err {
                print("Failed local search: ", err)
                return
            }
            
            // Success
            res?.mapItems.forEach({ (mapItem) in
                print(self.addressString(mapItem.placemark))
                
                self.addAnnotation(mapItem: mapItem)
            })
            self.mapView.showAnnotations(self.mapView.annotations, animated: true)
        }
    }
    
    fileprivate func addAnnotation(mapItem: MKMapItem) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = mapItem.placemark.coordinate
        annotation.title = mapItem.name
        mapView.addAnnotation(annotation)
    }
    
    private func customRegion() -> MKCoordinateRegion{
        let center = CLLocationCoordinate2DMake(37.7666, -122.427290)
        let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        let region = MKCoordinateRegion(center: center, span: span)
        return region
    }
    
    private func setupRegionForMap() {
        mapView.setRegion(customRegion(), animated: true)
    }
    
    private func setupView() {
        view.addSubview(mapView)
        mapView.fillSuperview()
    }
    
    private func addressString(_ placemark: MKPlacemark) -> String {
        var addressString = ""
        if placemark.subThoroughfare != nil {
            addressString = placemark.subThoroughfare! + " "
        }
        if placemark.thoroughfare != nil {
            addressString += placemark.thoroughfare! + ", "
        }
        if placemark.postalCode != nil {
            addressString += placemark.postalCode! + " "
        }
        if placemark.locality != nil {
            addressString += placemark.locality! + ", "
        }
        if placemark.administrativeArea != nil {
            addressString += placemark.administrativeArea! + " "
        }
        if placemark.country != nil {
            addressString += placemark.country!
        }
        return addressString
    }
    
}

import SwiftUI
struct MainPreviews: PreviewProvider {
    static var previews: some View {
        ContainerView().edgesIgnoringSafeArea(.all)
    }
    
    struct ContainerView: UIViewControllerRepresentable {
        func makeUIViewController(context: UIViewControllerRepresentableContext<MainPreviews.ContainerView>) -> MainViewController {
            return MainViewController()
        }
        
        func updateUIViewController(_ uiViewController: MainViewController, context: UIViewControllerRepresentableContext<MainPreviews.ContainerView>) {
        }
        
        typealias UIViewControllerType = MainViewController
        
    }
    
}
