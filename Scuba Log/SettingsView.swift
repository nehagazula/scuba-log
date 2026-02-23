//
//  SettingsView.swift
//  Scuba Log
//
//  Created by Neha Peace on 7/15/25.
//

import SwiftUI
import SwiftData

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
    @Query(sort: \Entry.startDate, order: .reverse) private var entries: [Entry]
    @State private var csvFileURL: URL?
    @State private var showingShareSheet = false

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

            Section(header: Text("Data")) {
                Button {
                    exportCSV()
                } label: {
                    Label("Export Dive Log", systemImage: "square.and.arrow.up")
                }
                .disabled(entries.isEmpty)
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
        .sheet(isPresented: $showingShareSheet) {
            if let url = csvFileURL {
                ShareSheet(activityItems: [url])
            }
        }
    }

    // MARK: - CSV Export

    private func exportCSV() {
        let depthUnit = isMetric ? "m" : "ft"
        let weightUnit = isMetric ? "kg" : "lb"
        let tempUnit = isMetric ? "°C" : "°F"
        let pressureUnit = isMetric ? "Bar" : "PSI"
        let tankUnit = isMetric ? "L" : "cu ft"

        let headers = [
            "Title", "Location", "Dive Type", "Start Date", "End Date",
            "Max Depth (\(depthUnit))", "Visibility (m)", "Rating",
            "Weight (\(weightUnit))", "Weighting",
            "Tank Size (\(tankUnit))", "Tank Material", "Gas Mixture",
            "Start Pressure (\(pressureUnit))", "End Pressure (\(pressureUnit))",
            "Suit Type", "Water Type", "Water Body",
            "Waves", "Current", "Surge",
            "Air Temp (\(tempUnit))", "Surface Temp (\(tempUnit))", "Bottom Temp (\(tempUnit))",
            "Notes", "Latitude", "Longitude"
        ]

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"

        var csv = headers.joined(separator: ",") + "\n"

        for entry in entries {
            let depth = isMetric ? entry.maxDepth : entry.maxDepth * 3.28084

            let row: [String] = [
                csvEscape(entry.title),
                csvEscape(entry.location),
                entry.diveType?.rawValue ?? "",
                dateFormatter.string(from: entry.startDate),
                dateFormatter.string(from: entry.endDate),
                depth > 0 ? String(format: "%.1f", depth) : "",
                entry.visibility > 0 ? String(format: "%.1f", entry.visibility) : "",
                entry.rating > 0 ? "\(entry.rating)" : "",
                formatOptionalFloat(entry.weight),
                entry.weightCategory?.rawValue ?? "",
                formatOptionalFloat(entry.tankSize),
                entry.tankMaterial?.rawValue ?? "",
                entry.gasMixture?.rawValue ?? "",
                formatOptionalFloat(entry.startPressure),
                formatOptionalFloat(entry.endPressure),
                entry.suitType.map { csvEscape($0.name) } ?? "",
                entry.waterType?.rawValue ?? "",
                entry.waterBody?.rawValue ?? "",
                entry.waves?.rawValue ?? "",
                entry.current?.rawValue ?? "",
                entry.surge?.rawValue ?? "",
                formatOptionalFloat(entry.airTemp),
                formatOptionalFloat(entry.surfTemp),
                formatOptionalFloat(entry.bottomTemp),
                csvEscape(entry.notes),
                entry.latitude.map { String($0) } ?? "",
                entry.longitude.map { String($0) } ?? ""
            ]

            csv += row.joined(separator: ",") + "\n"
        }

        let dateStamp = DateFormatter()
        dateStamp.dateFormat = "yyyy-MM-dd"
        let filename = "ScubaLog_Export_\(dateStamp.string(from: Date())).csv"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

        do {
            try csv.write(to: tempURL, atomically: true, encoding: .utf8)
            csvFileURL = tempURL
            showingShareSheet = true
        } catch {
            print("Failed to write CSV: \(error)")
        }
    }

    private func csvEscape(_ string: String) -> String {
        if string.contains(",") || string.contains("\"") || string.contains("\n") {
            return "\"" + string.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return string
    }

    private func formatOptionalFloat(_ value: Float?) -> String {
        guard let value = value else { return "" }
        return String(format: "%.1f", value)
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
