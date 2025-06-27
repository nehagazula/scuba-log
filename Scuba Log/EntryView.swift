//
//  EntryView.swift
//  Scuba Log
//
//  Created by Neha Peace on 4/8/24.
//

import SwiftUI

struct EntryView: View {
    var entry: Entry
    
    var body: some View {
        List {
            Section(header: Text("General")) {
                Text("**Dive Site:** \(entry.location)")
                Text("**Date:** \(entry.startDate, format: Date.FormatStyle(date: .numeric))")
                Text("**Time:** \(entry.startDate, style: .time) to \(entry.endDate, style: .time)") //maybe want duration?
                Text("**Max Depth:** \(entry.maxDepth, specifier: "%.0f") ft") // need to modify units according to isMetric
            }
            Section(header: Text("Equipment")) {
                if let weight = entry.weight {
                    Text("**Weight:** \(weight, specifier: "%.1f") lbs") // need to modify units according to isMetric
                }
                if let weightCategory = entry.weightCategory {
                    Text("**Weighting:** \(weightCategory.rawValue.capitalized)")
                }
                if let tankSize = entry.tankSize {
                    Text("**Cylinder Size:** \(tankSize, specifier: "%.0f") Cubic Feet")
                }
                if let tankMaterial = entry.tankMaterial {
                    Text("**Cylinder Type:** \(tankMaterial.rawValue.capitalized)")
                }
            }
            Section(header: Text("Conditions")) {
                if let waterType = entry.waterType {
                    Text("**Water Type:** \(waterType.rawValue.capitalized)")
                }
                if let waterBody = entry.waterBody {
                    Text("**Water Body:** \(waterBody.rawValue.capitalized)")
                }
                Text("**Visibility:** \(entry.visibility, specifier: "%.0f")%")
            }
            Section(header: Text("Experience")) {
                Text("**Rating:** \(entry.rating) Stars") //replace with actual stars?
                Text("**Notes:** \(entry.notes)")
            }
        }
        .navigationBarTitle(entry.title, displayMode: .large)
    }
}
