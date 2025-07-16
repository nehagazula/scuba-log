//
//  SettingsView.swift
//  Scuba Log
//
//  Created by Neha Peace on 7/15/25.
//

import SwiftUI

enum AppAppearance: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .system: return "System Default"
        case .light: return "Light Mode"
        case .dark: return "Dark Mode"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

struct SettingsView: View {
    @AppStorage("isMetric") private var isMetric = true
    @Environment(\.dismiss) private var dismiss
    @AppStorage("appAppearance") private var appAppearanceRawValue: String = AppAppearance.system.rawValue
    
    private var appAppearance: AppAppearance {
        get { AppAppearance(rawValue: appAppearanceRawValue) ?? .system }
        set { appAppearanceRawValue = newValue.rawValue }
    }
    
    var body: some View {
        Form {
            Section (header: Text("Units")) {
                Picker("Depth & Weight Units", selection: $isMetric) {
                    Text("Metric (meters, kg, °C)").tag(true)
                    Text("Imperial (feet, lb, °F)").tag(false)
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            Section(header: Text("Appearance")) {
                Picker("Appearance", selection: $appAppearanceRawValue) {
                    ForEach(AppAppearance.allCases) { appearance in
                        Text(appearance.displayName).tag(appearance.rawValue)
                    }
                }
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
