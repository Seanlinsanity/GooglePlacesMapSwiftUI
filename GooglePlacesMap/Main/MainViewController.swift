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
import Combine

extension MainViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if (annotation is MKPointAnnotation) {
            let annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "id")
            annotationView.canShowCallout = true
            return annotationView
        }
        return nil
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let annotation = view.annotation as? CustomAnnotation else { return }
        guard let index = self.locationsController.items.firstIndex(where: {$0.name == annotation.mapItem?.name}) else { return }
        self.locationsController.collectionView.scrollToItem(at: [0, index], at: .centeredHorizontally, animated: true)
    }
    
}

class MainViewController: UIViewController, CLLocationManagerDelegate {
    let mapView = MKMapView()
    let searchTextField = UITextField(placeholder: "Search query...")
    var cancellable: AnyCancellable?
    let locationManager = CLLocationManager()
    let locationsController = LocationsCarouselController(scrollDirection: .horizontal)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        requestUserLocation()
        mapView.delegate = self
        setupView()
        setupRegionForMap()
        setupSearchBar()
        setupLocationsCarousel()
        navigationController?.pushViewController(DirectionsController(), animated: true)
    }
    
    fileprivate func requestUserLocation() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.delegate = self
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse:
            print("Received authorization of user location")
            // request for where the user actually is
            locationManager.startUpdatingLocation()
        default:
            print("Failed to authorize")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let firstLocation = locations.first else { return }
        mapView.setRegion(.init(center: firstLocation.coordinate, span: .init(latitudeDelta: 0.1, longitudeDelta: 0.1)), animated: false)
        
//        locationManager.stopUpdatingLocation()
    }
    
    fileprivate func performLocationSearch() {
        let request = MKLocalSearch.Request()
        request.region = customRegion()
        request.naturalLanguageQuery = self.searchTextField.text
        let localSearch = MKLocalSearch(request: request)
        localSearch.start { (res, err) in
            if let err = err {
                print("Failed local search: ", err)
                return
            }
            // Success
            self.mapView.removeAnnotations(self.mapView.annotations)
            self.locationsController.items.removeAll()

            res?.mapItems.forEach({ (mapItem) in
                print(mapItem.address())
                self.addAnnotation(mapItem: mapItem)
                self.locationsController.items.append(mapItem)
            })
            
            if res?.mapItems.count != 0 { self.locationsController.collectionView.scrollToItem(at: [0, 0], at: .centeredHorizontally, animated: true)
            }
            self.mapView.showAnnotations(self.mapView.annotations, animated: true)
        }
    }
    
    fileprivate func addAnnotation(mapItem: MKMapItem) {
        let annotation = CustomAnnotation()
        annotation.mapItem = mapItem
        annotation.coordinate = mapItem.placemark.coordinate
        annotation.title = mapItem.name
        mapView.addAnnotation(annotation)
    }
    
    fileprivate func setupSearchBar() {
        let whiteContainerView = UIView(backgroundColor: .white)
        view.addSubview(whiteContainerView)
        whiteContainerView.anchor(top: view.safeAreaLayoutGuide.topAnchor, leading: view.leadingAnchor, bottom: nil, trailing: view.trailingAnchor, padding: .init(top: 0, left: 16, bottom: 0, right: 32))
        whiteContainerView.stack(searchTextField).withMargins(.allSides(16))
        
        //Search Throttling
        self.cancellable = NotificationCenter.default
            .publisher(for: UITextField.textDidChangeNotification, object: searchTextField)
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink(receiveValue: { [weak self] (notification) in
                let tf = notification.object as? UITextField
                print("search text: \(tf?.text ?? "")")
                self?.performLocationSearch()
            })
    }
    
    private func customRegion() -> MKCoordinateRegion{
        let center = CLLocationCoordinate2DMake(37.7666, -122.427290)
        let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        let region = MKCoordinateRegion(center: center, span: span)
        return region
    }
    
    fileprivate func setupLocationsCarousel() {
        let locationsView = locationsController.view!
        locationsController.mainController = self
        view.addSubview(locationsView)
        locationsView.anchor(top: nil, leading: view.leadingAnchor, bottom: view.safeAreaLayoutGuide.bottomAnchor, trailing: view.trailingAnchor, size: .init(width: 0, height: 150))
    }
    
    private func setupRegionForMap() {
        mapView.setRegion(customRegion(), animated: true)
    }
    
    private func setupView() {
        view.addSubview(mapView)
        mapView.fillSuperview()
        mapView.showsUserLocation = true
    }
    
}

class CustomAnnotation: MKPointAnnotation {
    var mapItem: MKMapItem?
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
