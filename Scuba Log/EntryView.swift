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
                Text("Max Depth \(entry.maxDepth)m. Start: \(entry.startDate, format: Date.FormatStyle(date: .numeric, time: .standard))")
            }
            .navigationBarTitle(entry.title, displayMode: .large)
        }
        
    }
}
