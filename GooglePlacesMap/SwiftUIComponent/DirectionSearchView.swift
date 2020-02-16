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
    
    func makeUIView(context: UIViewRepresentableContext<DirectionsMapView>) -> MKMapView {
        return MKMapView()
    }
    
    func updateUIView(_ uiView: MKMapView, context: UIViewRepresentableContext<DirectionsMapView>) {
        uiView.removeAnnotations(uiView.annotations)
        
        [env.sourceMapItem, env.destinationMapItem].compactMap{$0}.forEach { (mapItem) in
            let annotation = MKPointAnnotation()
            annotation.title = mapItem.name
            annotation.coordinate = mapItem.placemark.coordinate
            uiView.addAnnotation(annotation)
        }
        
        uiView.showAnnotations(uiView.annotations, animated: true)
    }
    
    typealias UIViewType = MKMapView
    
    
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

    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                VStack(spacing: 0) {
                    VStack {
                        HStack(spacing: 16) {
                            Image(uiImage: #imageLiteral(resourceName: "start_location_circles")).frame(width: 24)
                            NavigationLink(destination: SelectLocationView(), isActive: $envObj.isSelectingSource) {
                                HStack {
                                    Text(envObj.sourceMapItem?.name ?? "Source")
                                    Spacer()
                                }.padding().background(Color.white).cornerRadius(3)
                            }
                            
                        }
                        
                        HStack(spacing: 16) {
                            Image(uiImage: #imageLiteral(resourceName: "annotation_icon").withRenderingMode(.alwaysTemplate)).foregroundColor(Color.white).frame(width: 24)
                            NavigationLink(destination: SelectLocationView(), isActive: $envObj.isSelectingDestination) {
                                HStack {
                                    Text(envObj.destinationMapItem?.name ?? "Destination")
                                    Spacer()
                                }.padding().background(Color.white).cornerRadius(3)
                            }
                        }
                    }.padding().background(Color.blue)
                    DirectionsMapView().edgesIgnoringSafeArea(.bottom)
                }
                //Status bar
                Spacer().frame(width: UIApplication.shared.windows.filter{$0.isKeyWindow}.first?.frame.width, height: UIApplication.shared.windows.filter{$0.isKeyWindow}.first?.safeAreaInsets.top)
                    .background(Color.blue)
                    .edgesIgnoringSafeArea(.top)
                
                }.navigationBarTitle("Directions").navigationBarHidden(true)
        }
    }
}

class DirectionsEnvironment: ObservableObject {
    @Published var isSelectingSource = false
    @Published var isSelectingDestination = false
    
    @Published var sourceMapItem: MKMapItem?
    @Published var destinationMapItem: MKMapItem?
}

struct DirectionSearchView_Previews: PreviewProvider {
    static var env = DirectionsEnvironment()
    static var previews: some View {
        DirectionSearchView().environmentObject(env)
    }
}
