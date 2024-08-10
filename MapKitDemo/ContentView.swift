import MapKit
import SwiftUI

extension CLLocationCoordinate2D {
    // A set of coordinates where you can find parking.
    static let parking = CLLocationCoordinate2D(latitude: 43.25356054444856, longitude: -79.87475675469192)
    
    static let work = CLLocationCoordinate2D(latitude: 43.25925488994178, longitude: -79.81125751224114)
}

extension MKCoordinateRegion{
    
    //Work place coordinates 43.25925488994178, -79.81125751224114
    static let workPlace = MKCoordinateRegion(
        center: .work,
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    
    // Apple store coordinates 43.32501104137199, -79.819872988301
    static let appleStore = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 43.32501104137199, longitude: -79.819872988301), 
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
}

struct ContentView: View {
    // When a user changes the current position of the map we need to reset the camera position.
    @State private var position : MapCameraPosition = .automatic
    
    // Stores the search results of the markers
    @State private var searchResults: [MKMapItem] = []
    
    var body: some View {
        Map(position: $position) {
            
            // used to display content based on a coordinate on a map.
            Annotation("Parking", coordinate: .parking) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10).fill(Color(.systemBackground))
                    RoundedRectangle(cornerRadius: 10).stroke(Color.secondary, lineWidth: 5)
                    Image(systemName: "car").padding(5)
                }
            }.annotationTitles(.hidden)
            
            // used to display content based on the a coordinate on a map.
            Annotation("Work", coordinate: .work){
                ZStack{
                    RoundedRectangle(cornerRadius: 10).fill(Color(.systemBackground))
                    RoundedRectangle(cornerRadius: 10).stroke(Color.secondary, lineWidth: 5)
                    Image(systemName: "building.2").padding(5)
                }
            }.annotationTitles(.hidden)
            
            // List all the marks found using the search function.
            ForEach(searchResults, id: \.self){
                result in Marker(item: result)
            }
        }
        .mapStyle(.standard(elevation: .realistic))
        .safeAreaInset(edge: .bottom) {
            HStack {
                Spacer()
                // A button that allows you to search for play grounds.
                Button {
                    search(for: "Playgrounds", latitude: 0.0125, longitude: 0.0125)
                    
                } label: {
                    Label("Playgrounds", systemImage: "figure.and.child.holdinghands")
                }.buttonStyle(.borderedProminent)

                // A button that allows you to search for beaches.
                Button {
                    search(for: "Beaches", latitude: 0.0125, longitude: 0.0125)
                } label: {
                    Label("Beaches", systemImage: "beach.umbrella")
                }.buttonStyle(.borderedProminent)
                
                // A button that can show you were you work.
                Button{
                    // allows for easy animation transition.
                    withAnimation(.smooth(duration: 0.1)){
                        position = .region(.workPlace)
                    }
                } label: {
                    Label("Dofasco", systemImage: "building.2")
                }.buttonStyle(.bordered)
    
                Spacer()
                
            }.padding(.top).background(.ultraThinMaterial).labelStyle(.iconOnly)
        }.onChange(of: searchResults){
            withAnimation(.smooth(duration: 0.1)){
                position = .automatic
            }
        }
    }
    
    func search(for query: String, latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.resultTypes = .pointOfInterest
        request.region = MKCoordinateRegion(
            center: .parking,
            span: MKCoordinateSpan(latitudeDelta: latitude, longitudeDelta: longitude)
        )

        Task {
            let search = MKLocalSearch(request: request)
            
            let response = try? await search.start()
            searchResults  = response?.mapItems ?? []
        }
    }
}

#Preview {
    ContentView()
}
