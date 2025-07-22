//
//  EntryView.swift
//  Scuba Log
//
//  Created by Neha Peace on 4/8/24.
//

import SwiftUI
import MapKit

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
                // You could render photos here if saved — let me know if you store them.
                
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
        return value > 0 ? "\(String(format: "%.1f", value)) \(unit)" : "N/A"
    }

    var weightText: String {
        guard let weight = entry.weight else { return "N/A" }
        let unit = isMetric ? "kg" : "lb"
        return "\(String(format: "%.1f", weight)) \(unit)"
    }

    var tankText: String {
        guard let tank = entry.tankSize else { return "N/A" }
        let unit = isMetric ? "L" : "cu ft"
        return "\(String(format: "%.1f", tank)) \(unit)"
    }

    func pressureText(_ value: Float?) -> String {
        guard let value = value else { return "N/A" }
        return "\(Int(value)) \(isMetric ? "Bar" : "PSI")"
    }

    func tempText(_ value: Float?) -> String {
        guard let value = value else { return "N/A" }
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
            Text(value ?? "N/A")
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
