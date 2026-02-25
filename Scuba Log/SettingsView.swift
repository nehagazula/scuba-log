//
//  SettingsView.swift
//  Scuba Log
//
//  Created by Neha Peace on 7/15/25.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

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

enum CSVImportError: LocalizedError {
    case emptyFile
    case missingHeaders
    case unexpectedColumnCount(expected: Int, got: Int, row: Int)
    case invalidDateFormat(value: String, row: Int)

    var errorDescription: String? {
        switch self {
        case .emptyFile:
            return "The selected file is empty."
        case .missingHeaders:
            return "The file does not contain the expected CSV headers. Please use a file exported from Scuba Log."
        case .unexpectedColumnCount(let expected, let got, let row):
            return "Row \(row) has \(got) columns but \(expected) were expected."
        case .invalidDateFormat(let value, let row):
            return "Invalid date \"\(value)\" on row \(row). Expected format: yyyy-MM-dd HH:mm."
        }
    }
}

struct SettingsView: View {
    @AppStorage("isMetric") private var isMetric = true
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @AppStorage("appAppearance") private var appAppearanceRawValue: String = AppAppearance.system.rawValue
    @Query(sort: \Entry.startDate, order: .reverse) private var entries: [Entry]
    @State private var csvFileURL: URL?
    @State private var showingShareSheet = false
    @State private var showingFileImporter = false
    @State private var showingImportSuccessAlert = false
    @State private var showingImportErrorAlert = false
    @State private var showingDuplicateWarning = false
    @State private var importedCount = 0
    @State private var importErrorMessage = ""
    @State private var duplicateTitles: [String] = []
    @State private var pendingCSVString: String?

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

                Button {
                    showingFileImporter = true
                } label: {
                    Label("Import Dive Log", systemImage: "square.and.arrow.down")
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
        .sheet(isPresented: $showingShareSheet) {
            if let url = csvFileURL {
                ShareSheet(activityItems: [url])
            }
        }
        .fileImporter(
            isPresented: $showingFileImporter,
            allowedContentTypes: [.commaSeparatedText, .plainText],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result)
        }
        .alert("Import Successful", isPresented: $showingImportSuccessAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("\(importedCount) dive\(importedCount == 1 ? "" : "s") imported successfully.")
        }
        .alert("Import Error", isPresented: $showingImportErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(importErrorMessage)
        }
        .alert("Duplicate Entries Found", isPresented: $showingDuplicateWarning) {
            Button("Import with Renamed Titles") {
                guard let csvString = pendingCSVString else { return }
                do {
                    let count = try importCSV(csvString)
                    importedCount = count
                    showingImportSuccessAlert = true
                } catch {
                    importErrorMessage = error.localizedDescription
                    showingImportErrorAlert = true
                }
                pendingCSVString = nil
            }
            Button("Cancel", role: .cancel) {
                pendingCSVString = nil
            }
        } message: {
            let names = duplicateTitles.prefix(5).joined(separator: ", ")
            let extra = duplicateTitles.count > 5 ? " and \(duplicateTitles.count - 5) more" : ""
            Text("The following entries already exist: \(names)\(extra). Duplicates will be renamed with a number suffix.")
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

    // MARK: - CSV Import

    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }

            guard url.startAccessingSecurityScopedResource() else {
                importErrorMessage = "Unable to access the selected file."
                showingImportErrorAlert = true
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }

            do {
                let csvString = try String(contentsOf: url, encoding: .utf8)
                let dupes = try findDuplicateTitles(in: csvString)

                if dupes.isEmpty {
                    let count = try importCSV(csvString)
                    importedCount = count
                    showingImportSuccessAlert = true
                } else {
                    duplicateTitles = dupes
                    pendingCSVString = csvString
                    showingDuplicateWarning = true
                }
            } catch let error as CSVImportError {
                importErrorMessage = error.localizedDescription ?? "Unknown import error."
                showingImportErrorAlert = true
            } catch {
                importErrorMessage = "Failed to read file: \(error.localizedDescription)"
                showingImportErrorAlert = true
            }

        case .failure(let error):
            importErrorMessage = "File selection failed: \(error.localizedDescription)"
            showingImportErrorAlert = true
        }
    }

    private func findDuplicateTitles(in csvString: String) throws -> [String] {
        let rows = parseCSVRows(csvString)
        guard rows.count >= 2 else { throw CSVImportError.emptyFile }
        guard rows[0].count == 27 else { throw CSVImportError.missingHeaders }

        let existingTitles = Set(entries.map { $0.title })
        var duplicates: [String] = []

        for rowIndex in 1..<rows.count {
            let fields = rows[rowIndex]
            if fields.count == 1 && fields[0].trimmingCharacters(in: .whitespaces).isEmpty {
                continue
            }
            guard fields.count == 27 else { continue }
            let title = fields[0]
            if !title.isEmpty && existingTitles.contains(title) {
                duplicates.append(title)
            }
        }

        return duplicates
    }

    private func importCSV(_ csvString: String) throws -> Int {
        let rows = parseCSVRows(csvString)
        let expectedColumnCount = 27

        guard rows.count >= 2 else {
            throw CSVImportError.emptyFile
        }

        let headerRow = rows[0]
        guard headerRow.count == expectedColumnCount else {
            throw CSVImportError.missingHeaders
        }

        // Detect metric vs imperial from the depth header (column 5)
        let depthHeader = headerRow[5]
        let fileIsImperial = depthHeader.contains("ft")

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")

        // Build a set of existing titles for deduplication
        var existingTitles = Set(entries.map { $0.title })
        var importedCount = 0

        for rowIndex in 1..<rows.count {
            let fields = rows[rowIndex]

            // Skip empty trailing rows
            if fields.count == 1 && fields[0].trimmingCharacters(in: .whitespaces).isEmpty {
                continue
            }

            guard fields.count == expectedColumnCount else {
                throw CSVImportError.unexpectedColumnCount(
                    expected: expectedColumnCount, got: fields.count, row: rowIndex + 1
                )
            }

            let entry = Entry(timestamp: Date())

            let baseTitle = fields[0]
            if existingTitles.contains(baseTitle) {
                var counter = 2
                while existingTitles.contains("\(baseTitle) \(counter)") {
                    counter += 1
                }
                entry.title = "\(baseTitle) \(counter)"
            } else {
                entry.title = baseTitle
            }
            existingTitles.insert(entry.title)
            entry.location = fields[1]
            entry.diveType = diveCategory(rawValue: fields[2])

            if let date = dateFormatter.date(from: fields[3]) {
                entry.startDate = date
            } else if !fields[3].isEmpty {
                throw CSVImportError.invalidDateFormat(value: fields[3], row: rowIndex + 1)
            }

            if let date = dateFormatter.date(from: fields[4]) {
                entry.endDate = date
            } else if !fields[4].isEmpty {
                throw CSVImportError.invalidDateFormat(value: fields[4], row: rowIndex + 1)
            }

            if let depthVal = Float(fields[5]) {
                entry.maxDepth = fileIsImperial ? depthVal / 3.28084 : depthVal
            }

            if let vis = Float(fields[6]) {
                entry.visibility = vis
            }

            if let rat = Int(fields[7]) {
                entry.rating = rat
            }

            entry.weight = parseOptionalFloat(fields[8])
            entry.weightCategory = Weighting(rawValue: fields[9])
            entry.tankSize = parseOptionalFloat(fields[10])
            entry.tankMaterial = tankCategory(rawValue: fields[11])
            entry.gasMixture = gasCategory(rawValue: fields[12])
            entry.startPressure = parseOptionalFloat(fields[13])
            entry.endPressure = parseOptionalFloat(fields[14])
            entry.suitType = suitCategoryFromName(fields[15])
            entry.waterType = waterCategory(rawValue: fields[16])
            entry.waterBody = waterbodyCategory(rawValue: fields[17])
            entry.waves = wavesCategory(rawValue: fields[18])
            entry.current = currentCategory(rawValue: fields[19])
            entry.surge = surgeCategory(rawValue: fields[20])
            entry.airTemp = parseOptionalFloat(fields[21])
            entry.surfTemp = parseOptionalFloat(fields[22])
            entry.bottomTemp = parseOptionalFloat(fields[23])
            entry.notes = fields[24]

            if let lat = Double(fields[25]) {
                entry.latitude = lat
            }
            if let lon = Double(fields[26]) {
                entry.longitude = lon
            }

            modelContext.insert(entry)
            importedCount += 1
        }

        return importedCount
    }

    private func parseCSVRows(_ csv: String) -> [[String]] {
        var rows: [[String]] = []
        var currentField = ""
        var currentRow: [String] = []
        var insideQuotes = false
        let characters = Array(csv)
        var i = 0

        while i < characters.count {
            let char = characters[i]

            if insideQuotes {
                if char == "\"" {
                    if i + 1 < characters.count && characters[i + 1] == "\"" {
                        currentField.append("\"")
                        i += 2
                        continue
                    } else {
                        insideQuotes = false
                        i += 1
                        continue
                    }
                } else {
                    currentField.append(char)
                    i += 1
                    continue
                }
            }

            if char == "\"" {
                insideQuotes = true
                i += 1
            } else if char == "," {
                currentRow.append(currentField)
                currentField = ""
                i += 1
            } else if char == "\n" || char == "\r" {
                if char == "\r" && i + 1 < characters.count && characters[i + 1] == "\n" {
                    i += 1
                }
                currentRow.append(currentField)
                currentField = ""
                if !currentRow.isEmpty {
                    rows.append(currentRow)
                }
                currentRow = []
                i += 1
            } else {
                currentField.append(char)
                i += 1
            }
        }

        if !currentField.isEmpty || !currentRow.isEmpty {
            currentRow.append(currentField)
            rows.append(currentRow)
        }

        return rows
    }

    private func suitCategoryFromName(_ name: String) -> suitCategory? {
        switch name {
        case "Full Suit 3mm": return .fullSuit3
        case "Full Suit 5mm": return .fullSuit5
        case "Full Suit 7mm": return .fullSuit7
        case "Dry Suit": return .drySuit
        case "Semi Dry": return .semiDry
        case "Shorty": return .shorty
        case "None": return suitCategory.none
        default: return nil
        }
    }

    private func parseOptionalFloat(_ string: String) -> Float? {
        let trimmed = string.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        return Float(trimmed)
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
