//
//  EntryView.swift
//  Scuba Log
//
//  Created by Neha Peace on 4/8/24.
//

import SwiftUI
import MapKit

struct MapPreview: View {
    var locationName: String
    var storedLatitude: Double?
    var storedLongitude: Double?

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var coordinate: CLLocationCoordinate2D?

    var body: some View {
        Group {
            if let coordinate = coordinate {
                Map(position: .constant(.region(region))) {
                    Marker(locationName, coordinate: coordinate)
                }
                .frame(height: 200)
                .cornerRadius(12)
                .onTapGesture {
                    openInAppleMaps(coordinate: coordinate)
                }
            } else {
                Text("Loading map...")
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
            }
        }
        .onAppear {
            if let lat = storedLatitude, let lon = storedLongitude {
                let coord = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                self.coordinate = coord
                self.region.center = coord
            } else {
                geocode()
            }
        }
    }

    private func geocode() {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(locationName) { placemarks, error in
            guard let placemark = placemarks?.first,
                  let loc = placemark.location else { return }
            let coord = loc.coordinate
            self.coordinate = coord
            self.region.center = coord
        }
    }

    private func openInAppleMaps(coordinate: CLLocationCoordinate2D) {
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = locationName
        mapItem.openInMaps(launchOptions: nil)
    }

}


struct EntryView: View {
    let entry: Entry
    
    @State private var isEditing = false
    @State private var editableEntry: Entry

       // Initialize editableEntry with entry value
       init(entry: Entry) {
           self.entry = entry
           _editableEntry = State(initialValue: entry)
       }
    
    // makes background of a section grey within a rectangular box
    struct SectionCard<Content: View>: View {
        let content: Content
        init(@ViewBuilder content: () -> Content) {
            self.content = content()
        }

        var body: some View {
            content
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                
                // General
                SectionHeader("General")
                SectionCard {
                    VStack(alignment: .leading, spacing: 8) {
                        EntryRow(label: "Title", value: entry.title)
                        EntryRow(label: "Location", value: entry.location)
                        
                        if !entry.location.isEmpty {
                            MapPreview(locationName: entry.location, storedLatitude: entry.latitude, storedLongitude: entry.longitude)
                        }
                        
                        EntryRow(label: "Dive Type", value: entry.diveType?.rawValue.capitalized)
                        EntryRow(label: "Start", value: entry.startDate.formatted(.dateTime))
                        EntryRow(label: "End", value: entry.endDate.formatted(.dateTime))
                        EntryRow(label: "Max Depth", value: depthText)
                    }
                }
                
                // Equipment
                SectionHeader("Equipment")
                SectionCard {
                    VStack(alignment: .leading, spacing: 8) {
                        EntryRow(label: "Weight", value: weightText)
                        EntryRow(label: "Weight Type", value: entry.weightCategory?.rawValue.capitalized)
                        EntryRow(label: "Tank Size", value: tankText)
                        EntryRow(label: "Tank Material", value: entry.tankMaterial?.rawValue.capitalized)
                        EntryRow(label: "Gas Mixture", value: entry.gasMixture?.rawValue.capitalized)
                        EntryRow(label: "Start Pressure", value: pressureText(entry.startPressure))
                        EntryRow(label: "End Pressure", value: pressureText(entry.endPressure))
                        let pressureUsed = (entry.startPressure ?? 0) - (entry.endPressure ?? 0)
                        EntryRow(label: "Amount Used", value: pressureUsed > 0 ? pressureText(pressureUsed) : "--")
                        EntryRow(label: "Suit Type", value: entry.suitType?.name)
                    }
                }
                
                // Conditions
                SectionHeader("Conditions")
                SectionCard {
                    VStack(alignment: .leading, spacing: 8) {
                        EntryRow(label: "Water Type", value: entry.waterType?.rawValue.capitalized)
                        EntryRow(label: "Water Body", value: entry.waterBody?.rawValue.capitalized)
                        EntryRow(label: "Waves", value: entry.waves?.rawValue.capitalized)
                        EntryRow(label: "Current", value: entry.current?.rawValue.capitalized)
                        EntryRow(label: "Surge", value: entry.surge?.rawValue.capitalized)
                        EntryRow(label: "Visibility", value: "\(Int(entry.visibility))%")
                        EntryRow(label: "Air Temp", value: tempText(entry.airTemp))
                        EntryRow(label: "Surface Temp", value: tempText(entry.surfTemp))
                        EntryRow(label: "Bottom Temp", value: tempText(entry.bottomTemp))
                    }
                }
                
                // Experience
                SectionHeader("Experience")
                SectionCard {
                    VStack(alignment: .leading, spacing: 8) {
                        EntryRow(label: "Rating", value: "\(entry.rating)/5")
                        if !entry.notes.isEmpty {
                            Text("Notes:")
                                .font(.subheadline.bold())
                            Text(entry.notes)
                                .font(.body)
                                .foregroundColor(.primary)
                                .padding(.bottom, 8)
                        }
                    }
                }
                
                // Photos
                if !entry.photos.isEmpty {
                    SectionHeader("Photos")
                    SectionCard {
                        PhotosDisplayView(photoDataList: entry.photos)
                    }
                }

            }
            .padding()
        }
        .navigationTitle("Dive Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button("Edit") {
                isEditing = true
            }
        }
        .sheet(isPresented: $isEditing) {
            EditEntryView(isPresented: $isEditing, entryToEdit: $editableEntry) { updatedEntry in
                // Handle save here
                print("Updated entry: \(updatedEntry)")
            }
        }
    }
    
    // Computed Display Texts
    var isMetric: Bool {
        UserDefaults.standard.bool(forKey: "isMetric")
    }

    var depthText: String {
        let unit = isMetric ? "m" : "ft"
        let value = isMetric ? entry.maxDepth : entry.maxDepth * 3.28084
        return value > 0 ? "\(String(format: "%.1f", value)) \(unit)" : "--"
    }

    var weightText: String {
        guard let weight = entry.weight else { return "--" }
        let unit = isMetric ? "kg" : "lb"
        return "\(String(format: "%.1f", weight)) \(unit)"
    }

    var tankText: String {
        guard let tank = entry.tankSize else { return "--" }
        let unit = isMetric ? "L" : "cu ft"
        return "\(String(format: "%.1f", tank)) \(unit)"
    }

    func pressureText(_ value: Float?) -> String {
        guard let value = value else { return "--" }
        return "\(Int(value)) \(isMetric ? "Bar" : "PSI")"
    }

    func tempText(_ value: Float?) -> String {
        guard let value = value else { return "--" }
        return "\(String(format: "%.1f", value))°\(isMetric ? "C" : "F")"
    }
}

// Helper Views

struct EntryRow: View {
    var label: String
    var value: String?

    var body: some View {
        HStack {
            Text("\(label):")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value ?? "--")
                .font(.subheadline)
                .foregroundColor(.primary)
                .multilineTextAlignment(.trailing)
        }
    }
}

struct SectionHeader: View {
    var title: String
    init(_ title: String) { self.title = title }

    var body: some View {
        Text(title)
            .font(.title2)
            .bold()
            .padding(.top, 12)
    }
}

struct PhotosDisplayView: View {
    let photoDataList: [Data]
    @State private var imageToPreview: IdentifiableImage? = nil

    private var images: [IdentifiableImage] {
        photoDataList.compactMap { data in
            UIImage(data: data).map { IdentifiableImage(image: $0) }
        }
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(images) { identifiableImage in
                    Image(uiImage: identifiableImage.image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .clipped()
                        .contentShape(RoundedRectangle(cornerRadius: 10))
                        .onTapGesture {
                            imageToPreview = identifiableImage
                        }
                }
            }
        }
        .fullScreenCover(item: $imageToPreview) { image in
            ZStack(alignment: .topTrailing) {
                Color.black.ignoresSafeArea()
                Image(uiImage: image.image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black)

                Button {
                    imageToPreview = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                        .padding()
                }
            }
        }
    }
}
