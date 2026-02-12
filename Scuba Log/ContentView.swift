//
//  ContentView.swift
//  Scuba Log
//
//  Created by Neha Peace on 4/7/24.
//

import SwiftUI
import SwiftData
import MapKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var entries: [Entry]
    @State private var showingNewEntryView = false
    @State private var showingSettings = false
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Total dives: \(entries.count)")
                    Spacer()
                    Text("Dive time: \(totalTimeFormatted)")
                }
                .font(.subheadline)
                .foregroundColor(.primary)
                .padding(.horizontal)

                List {
                    ForEach(entries) { entry in
                        ZStack {
                            NavigationLink(destination: EntryView(entry: entry)) {
                                EmptyView()
                            }
                            .opacity(0)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(entry.title)").bold()
                                Text("\(entry.startDate, format: Date.FormatStyle(date: .abbreviated)), \(entry.location)").font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                    }
                    .onDelete(perform: deleteItems)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                }
                .listStyle(.plain)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        EditButton()
                    }
                    ToolbarItem {
                        Button(action: {
                            showingNewEntryView = true
                        }) {
                            Label("Add Item", systemImage: "plus")
                        }
                        .padding()
                    }
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            showingSettings = true
                        } label: {
                            Image(systemName: "gear")
                        }
                    }
                }
                .navigationTitle("Scuba Log")
                .navigationBarTitleDisplayMode(.large)
            }
        }
        .sheet(isPresented: $showingNewEntryView) {
            NewEntryView(isPresented: $showingNewEntryView, addItem: addItem)
                .interactiveDismissDisabled()
        }
        .sheet(isPresented: $showingSettings) {
            NavigationView{
                SettingsView()
            }
        }
    }

    private var totalTimeFormatted: String {
        let totalSeconds = entries.reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
        let hours = Int(totalSeconds) / 3600
        let minutes = (Int(totalSeconds) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }

    private func addItem(_ newItem: Entry) {
        withAnimation {
            modelContext.insert(newItem)
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(entries[index])
            }
        }
    }
}

struct DiveMapView: View {
    @Query private var entries: [Entry]

    @State private var position: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 20, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 140, longitudeDelta: 360)
    ))

    private var locatedEntries: [Entry] {
        entries.filter { $0.latitude != nil && $0.longitude != nil }
    }

    private var mapRegion: MKCoordinateRegion {
        guard !locatedEntries.isEmpty else {
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 20, longitude: 0),
                span: MKCoordinateSpan(latitudeDelta: 140, longitudeDelta: 360)
            )
        }

        let lats = locatedEntries.map { $0.latitude! }
        let lons = locatedEntries.map { $0.longitude! }

        let minLat = lats.min()!
        let maxLat = lats.max()!
        let minLon = lons.min()!
        let maxLon = lons.max()!

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )

        let latDelta = max((maxLat - minLat) * 1.5, 60)
        let lonDelta = max((maxLon - minLon) * 1.5, 90)

        return MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
        )
    }

    var body: some View {
        NavigationView {
            Map(position: $position) {
                ForEach(locatedEntries) { entry in
                    Marker(
                        entry.title,
                        coordinate: CLLocationCoordinate2D(
                            latitude: entry.latitude!,
                            longitude: entry.longitude!
                        )
                    )
                }
            }
            .navigationTitle("Dive Map")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                position = .region(mapRegion)
            }
        }
    }
}

struct MainTabView: View {
    @AppStorage("appAppearance") private var appAppearanceRawValue: String = AppAppearance.system.rawValue

    private var appAppearance: AppAppearance {
        AppAppearance(rawValue: appAppearanceRawValue) ?? .system
    }

    var body: some View {
        TabView {
            ContentView()
                .tabItem {
                    Label("Log", systemImage: "list.bullet")
                }

            DiveMapView()
                .tabItem {
                    Label("Map", systemImage: "map")
                }
        }
        .preferredColorScheme(appAppearance.colorScheme)
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: Entry.self, inMemory: true)
}
