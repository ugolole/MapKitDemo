import MapKit
import SwiftUI

extension CLLocationCoordinate2D {
    // A set of coordinates where you can find parking.
    static let parking = CLLocationCoordinate2D(latitude: 43.25356054444856, longitude: -79.87475675469192)
    
    // place of temporary placement
    static let work = CLLocationCoordinate2D(latitude: 43.25925488994178, longitude: -79.81125751224114)
    
    // place of a random catholic area 43.21347255761558, -79.91862956339779
    static let catholicArea = CLLocationCoordinate2D(latitude: 43.21347255761558, longitude: -79.91862956339779)
    
}

// you can create an extension to be used by other code blocks only if they bare the name of the code
// block they support.
extension MKCoordinateSpan{
    static let basicSpan = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
}

extension MKCoordinateRegion{
    
    //Work place coordinates 43.25925488994178, -79.81125751224114
    static let workPlace = MKCoordinateRegion(
        center: .work,
        span: .basicSpan
    )
    
    // Apple store coordinates 43.32501104137199, -79.819872988301
    static let appleStore = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 43.32501104137199, longitude: -79.819872988301), 
        span: .basicSpan
    )
    
    // Parking coordinates
    static let parkingSite = MKCoordinateRegion(
        center: .parking, span: .basicSpan
    )

}

// Behind the scenes what the map shows is controlled by the map Camera position.
// The camera looks at coordinates on the ground from a certain distance.
// The orientation of the camera determines what is visiable on the map.
// Currently we are not configuring the camera but what we are is specifying what
// should be in view using the MapCmeraPosition.

struct ContentView: View {
    // When a user changes the current position of the map we need to reset the camera position.
    // The automatic state modifier ensure the search results are visible even after the user interacts with
    // the map.
    // Note: the automatic camera position is used to frame content.
    @State private var position : MapCameraPosition = .automatic
    
    // Stores the search results of the markers
    @State private var searchResults: [MKMapItem] = []
    
    // Get the visible region when the state camera changes. Allows you to see markers that have been searched for
    // within the visiable region, this region is acquired when you move the map to that specific location.
    @State private var visibleRegion: MKCoordinateRegion?
    
    // Current the markers are not selected we need to enable them and adding a state
    @State private var selectedResult : MKMapItem?
        
    var body: some View {
        Map(position: $position, selection: $selectedResult) {
            
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
            
            Annotation("Catholic", coordinate:  .catholicArea){
                ZStack{
                    RoundedRectangle(cornerRadius: 10).fill(Color(.systemBackground))
                    RoundedRectangle(cornerRadius: 10).stroke(Color.secondary, lineWidth: 5)
                    Image(systemName: "projective").padding(5)
                }
            }.annotationTitles(.hidden)
            
            // List all the marks found using the search function.
            ForEach(searchResults, id: \.self){
                result in Marker(item: result) // These markes come with inbuilt styles
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
                
                // A button that can show you were you park.
                // This works because we are able to change the position of the camera using
                // the MapCameraPosition and pass coordinates to it.
                // I added an with animation object which make the camera changing process much smoother.
                Button{
                    withAnimation(.smooth(duration: 0.1)){
                        //position = .region(.parkingSite)
                        position = .camera(
                            MapCamera(
                                centerCoordinate: .parking,
                                distance: 980,
                                heading: 242,
                                pitch: 60))
                    }
                }label: {
                    Label("Parking", systemImage: "car")
                }.buttonStyle(.bordered)
                
                Button{
                    withAnimation(.smooth(duration: 0.1)){
                        // position = .region(.catholic)
                        
                        // the approach allows us to change the camera position while including distance
                        // heading and pitch which determines how a user will see the given map area.
                        position = .camera(
                            MapCamera(
                                centerCoordinate: .catholicArea,
                                distance: 980,
                                heading: 242,
                                pitch: 60)
                        )
                        
                        // you can provide a position that follows a user and set a default location when the
                        // users location is not know as shown in the code shown below
                        // position = .userLocation(fallback: automatic)
                    }
                }label: {
                    Label("Catholic", systemImage: "projective")
                }.buttonStyle(.bordered)
    
                Spacer()
                
            }.padding(.top).background(.ultraThinMaterial).labelStyle(.iconOnly)
        }.onChange(of: searchResults){
            withAnimation(.smooth(duration: 0.1)){
                position = .automatic
            }
        // This informs us when we have a change on what's visisble.
        }.onMapCameraChange {context in
            visibleRegion = context.region
        }
    }
    
    
    
    // Returns the result of a search based on the query string passed to this function.
    func search(for query: String, latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.resultTypes = .pointOfInterest
        request.region = visibleRegion ?? MKCoordinateRegion(
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
