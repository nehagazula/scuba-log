//
//  SettingsView.swift
//  Scuba Log
//
//  Created by Neha Peace on 7/15/25.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("isMetric") private var isMetric = true
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Form {
            Section (header: Text("Units")) {
                Picker("Depth & Weight Units", selection: $isMetric) {
                    Text("Metric (meters, kg, °C)").tag(true)
                    Text("Imperial (feet, lb, °F)").tag(false)
                }
                .pickerStyle(SegmentedPickerStyle())
            }
        }
        .navigationTitle("Settings")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
}
