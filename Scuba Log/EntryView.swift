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
        NavigationView {
            VStack {
                Text("From \(entry.startDate, format: Date.FormatStyle(date: .numeric, time: .standard)) to \(entry.endDate, format: Date.FormatStyle(date: .numeric, time: .standard))")
                Text("Max Depth \(entry.maxDepth) ft") // need to modify units according to isMetric
                if let weight = entry.weight {
                    Text("Weight \(weight) lbs") // need to modify units according to isMetric
                }
                if let weightCategory = entry.weightCategory {
                    Text("Weighting: \(weightCategory.rawValue.capitalized)")
                }
            }
            .navigationBarTitle(entry.title, displayMode: .large)
        }
    }
}
