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
    @State private var pendingUDDFData: Data?
    @State private var showingExportFormatPicker = false

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
                    showingExportFormatPicker = true
                } label: {
                    Label("Export Dive Log", systemImage: "square.and.arrow.up")
                }
                .disabled(entries.isEmpty)
                .confirmationDialog("Export Format", isPresented: $showingExportFormatPicker) {
                    Button("CSV") { exportCSV() }
                    Button("UDDF") { exportUDDF() }
                    Button("Cancel", role: .cancel) {}
                }

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
            allowedContentTypes: [.commaSeparatedText, .plainText, .xml, .data],
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
                if let csvString = pendingCSVString {
                    do {
                        let count = try importCSV(csvString)
                        importedCount = count
                        showingImportSuccessAlert = true
                    } catch {
                        importErrorMessage = error.localizedDescription
                        showingImportErrorAlert = true
                    }
                    pendingCSVString = nil
                } else if let uddfData = pendingUDDFData {
                    do {
                        let count = try importUDDF(uddfData)
                        importedCount = count
                        showingImportSuccessAlert = true
                    } catch {
                        importErrorMessage = error.localizedDescription
                        showingImportErrorAlert = true
                    }
                    pendingUDDFData = nil
                }
            }
            Button("Cancel", role: .cancel) {
                pendingCSVString = nil
                pendingUDDFData = nil
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

        let visUnit = isMetric ? "m" : "ft"
        let headers = [
            "Title", "Location", "Dive Type", "Date", "Bottom Time (min)",
            "Start Time", "End Time",
            "Max Depth (\(depthUnit))", "Visibility (\(visUnit))", "Visibility Rating", "Rating",
            "Weight (\(weightUnit))", "Weighting",
            "Tank Size (\(tankUnit))", "Tank Material", "Gas Mixture",
            "Start Pressure (\(pressureUnit))", "End Pressure (\(pressureUnit))",
            "Suit Type", "Water Type", "Water Body",
            "Waves", "Current", "Surge",
            "Air Temp (\(tempUnit))", "Surface Temp (\(tempUnit))", "Bottom Temp (\(tempUnit))",
            "Notes", "Latitude", "Longitude"
        ]

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"

        var csv = headers.joined(separator: ",") + "\n"

        for entry in entries {
            let depth = isMetric ? entry.maxDepth : entry.maxDepth * 3.28084
            let bottomTime = Int(entry.endDate.timeIntervalSince(entry.startDate) / 60)

            let calendar = Calendar.current
            let startComps = calendar.dateComponents([.hour, .minute], from: entry.startDate)
            let hasStartTime = (startComps.hour ?? 0) != 0 || (startComps.minute ?? 0) != 0
            let endComps = calendar.dateComponents([.hour, .minute], from: entry.endDate)
            let hasEndTime = (endComps.hour ?? 0) != 0 || (endComps.minute ?? 0) != 0

            let row: [String] = [
                csvEscape(entry.title),
                csvEscape(entry.location),
                entry.diveType?.rawValue ?? "",
                dateFormatter.string(from: entry.startDate),
                bottomTime > 0 ? "\(bottomTime)" : "",
                hasStartTime ? timeFormatter.string(from: entry.startDate) : "",
                hasEndTime ? timeFormatter.string(from: entry.endDate) : "",
                depth > 0 ? String(format: "%.1f", depth) : "",
                formatOptionalFloat(entry.visibility),
                entry.visibilityCategory?.rawValue ?? "",
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

    // MARK: - UDDF Export

    private func exportUDDF() {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime]

        let now = isoFormatter.string(from: Date())

        // Collect unique locations
        var siteMap: [String: Int] = [:]  // location name → site index
        var siteEntries: [(name: String, lat: Double?, lon: Double?)] = []
        for entry in entries {
            let loc = entry.location.trimmingCharacters(in: .whitespaces)
            if !loc.isEmpty && siteMap[loc] == nil {
                siteMap[loc] = siteEntries.count
                siteEntries.append((name: loc, lat: entry.latitude, lon: entry.longitude))
            }
        }

        // Collect unique gas mixtures
        var mixMap: [gasCategory: Int] = [:]
        var mixEntries: [(gas: gasCategory, o2: Double, he: Double)] = []
        for entry in entries {
            if let gas = entry.gasMixture, mixMap[gas] == nil {
                let fractions = gasCategoryToFractions(gas)
                mixMap[gas] = mixEntries.count
                mixEntries.append((gas: gas, o2: fractions.o2, he: fractions.he))
            }
        }

        // Build XML
        var xml = "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n"
        xml += "<uddf version=\"3.2.0\">\n"

        // Generator
        xml += "  <generator>\n"
        xml += "    <name>Scuba Log</name>\n"
        xml += "    <manufacturer id=\"scubalog\">\n"
        xml += "      <name>Scuba Log</name>\n"
        xml += "    </manufacturer>\n"
        xml += "    <datetime>\(now)</datetime>\n"
        xml += "  </generator>\n"

        // Gas definitions
        xml += "  <gasdefinitions>\n"
        for (index, mix) in mixEntries.enumerated() {
            let n2 = max(0, 1.0 - mix.o2 - mix.he)
            xml += "    <mix id=\"mix_\(index)\">\n"
            xml += "      <o2>\(mix.o2)</o2>\n"
            xml += "      <n2>\(String(format: "%.4f", n2))</n2>\n"
            xml += "      <he>\(mix.he)</he>\n"
            xml += "    </mix>\n"
        }
        xml += "  </gasdefinitions>\n"

        // Dive sites
        xml += "  <divesite>\n"
        for (index, site) in siteEntries.enumerated() {
            xml += "    <site id=\"site_\(index)\">\n"
            xml += "      <name>\(xmlEscape(site.name))</name>\n"
            if let lat = site.lat, let lon = site.lon {
                xml += "      <geography>\n"
                xml += "        <latitude>\(lat)</latitude>\n"
                xml += "        <longitude>\(lon)</longitude>\n"
                xml += "      </geography>\n"
            }
            xml += "    </site>\n"
        }
        xml += "  </divesite>\n"

        // Profile data
        xml += "  <profiledata>\n"
        xml += "    <repetitiongroup>\n"

        for entry in entries {
            xml += "      <dive>\n"

            // Information before dive
            xml += "        <informationbeforedive>\n"
            xml += "          <datetime>\(isoFormatter.string(from: entry.startDate))</datetime>\n"
            if let airTemp = entry.airTemp {
                xml += "          <airtemperature>\(String(format: "%.2f", Double(airTemp) + 273.15))</airtemperature>\n"
            }
            let loc = entry.location.trimmingCharacters(in: .whitespaces)
            if !loc.isEmpty, let siteIndex = siteMap[loc] {
                xml += "          <link ref=\"site_\(siteIndex)\"/>\n"
            }
            xml += "        </informationbeforedive>\n"

            // Tank data
            if entry.gasMixture != nil || entry.tankSize != nil || entry.startPressure != nil || entry.endPressure != nil {
                xml += "        <tankdata>\n"
                if let gas = entry.gasMixture, let mixIndex = mixMap[gas] {
                    xml += "          <link ref=\"mix_\(mixIndex)\"/>\n"
                }
                if let tankSize = entry.tankSize {
                    xml += "          <tankvolume>\(String(format: "%.1f", tankSize))</tankvolume>\n"
                }
                if let startP = entry.startPressure {
                    xml += "          <tankpressurebegin>\(String(format: "%.0f", Double(startP) * 100000.0))</tankpressurebegin>\n"
                }
                if let endP = entry.endPressure {
                    xml += "          <tankpressureend>\(String(format: "%.0f", Double(endP) * 100000.0))</tankpressureend>\n"
                }
                xml += "        </tankdata>\n"
            }

            // Information after dive
            xml += "        <informationafterdive>\n"
            if entry.maxDepth > 0 {
                xml += "          <greatestdepth>\(String(format: "%.1f", entry.maxDepth))</greatestdepth>\n"
            }
            let duration = entry.endDate.timeIntervalSince(entry.startDate)
            if duration > 0 {
                xml += "          <diveduration>\(String(format: "%.0f", duration))</diveduration>\n"
            }
            if let bottomTemp = entry.bottomTemp {
                xml += "          <lowesttemperature>\(String(format: "%.2f", Double(bottomTemp) + 273.15))</lowesttemperature>\n"
            }
            xml += "        </informationafterdive>\n"

            xml += "      </dive>\n"
        }

        xml += "    </repetitiongroup>\n"
        xml += "  </profiledata>\n"
        xml += "</uddf>\n"

        // Write to temp file
        let dateStamp = DateFormatter()
        dateStamp.dateFormat = "yyyy-MM-dd"
        let filename = "ScubaLog_Export_\(dateStamp.string(from: Date())).uddf"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

        do {
            try xml.write(to: tempURL, atomically: true, encoding: .utf8)
            csvFileURL = tempURL
            showingShareSheet = true
        } catch {
            print("Failed to write UDDF: \(error)")
        }
    }

    private func gasCategoryToFractions(_ gas: gasCategory) -> (o2: Double, he: Double) {
        switch gas {
        case .air:        return (0.21, 0.0)
        case .eanx32:     return (0.32, 0.0)
        case .eanx36:     return (0.36, 0.0)
        case .eanx40:     return (0.40, 0.0)
        case .enriched:   return (0.32, 0.0)
        case .trimix:     return (0.21, 0.35)
        case .rebreather: return (0.21, 0.0)
        }
    }

    private func xmlEscape(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
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

            let ext = url.pathExtension.lowercased()

            do {
                if ext == "uddf" || ext == "xml" {
                    let data = try Data(contentsOf: url)
                    let dupes = try findUDDFDuplicateTitles(in: data)

                    if dupes.isEmpty {
                        let count = try importUDDF(data)
                        importedCount = count
                        showingImportSuccessAlert = true
                    } else {
                        duplicateTitles = dupes
                        pendingUDDFData = data
                        showingDuplicateWarning = true
                    }
                } else {
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
        guard rows[0].count == 30 else { throw CSVImportError.missingHeaders }

        let existingTitles = Set(entries.map { $0.title })
        var duplicates: [String] = []

        for rowIndex in 1..<rows.count {
            let fields = rows[rowIndex]
            if fields.count == 1 && fields[0].trimmingCharacters(in: .whitespaces).isEmpty {
                continue
            }
            guard fields.count == 30 else { continue }
            let title = fields[0]
            if !title.isEmpty && existingTitles.contains(title) {
                duplicates.append(title)
            }
        }

        return duplicates
    }

    private func importCSV(_ csvString: String) throws -> Int {
        let rows = parseCSVRows(csvString)
        let expectedColumnCount = 30

        guard rows.count >= 2 else {
            throw CSVImportError.emptyFile
        }

        let headerRow = rows[0]
        guard headerRow.count == expectedColumnCount else {
            throw CSVImportError.missingHeaders
        }

        // Detect metric vs imperial from the depth header (column 7)
        let depthHeader = headerRow[7]
        let fileIsImperial = depthHeader.contains("ft")

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        timeFormatter.locale = Locale(identifier: "en_US_POSIX")

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

            // Column 0: Title (with deduplication)
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

            // Column 1: Location
            entry.location = fields[1]
            // Column 2: Dive Type
            entry.diveType = diveCategory(rawValue: fields[2])

            // Column 3: Date (yyyy-MM-dd)
            let calendar = Calendar.current
            var diveDate = Date()
            if let date = dateFormatter.date(from: fields[3]) {
                diveDate = date
            } else if !fields[3].isEmpty {
                throw CSVImportError.invalidDateFormat(value: fields[3], row: rowIndex + 1)
            }

            // Column 4: Bottom Time (min)
            let bottomTimeMinutes = Int(fields[4]) ?? 0

            // Column 5: Start Time (HH:mm, optional)
            if !fields[5].isEmpty, let time = timeFormatter.date(from: fields[5]) {
                let timeComps = calendar.dateComponents([.hour, .minute], from: time)
                var dateComps = calendar.dateComponents([.year, .month, .day], from: diveDate)
                dateComps.hour = timeComps.hour
                dateComps.minute = timeComps.minute
                entry.startDate = calendar.date(from: dateComps) ?? diveDate
            } else {
                entry.startDate = diveDate
            }

            // Column 6: End Time (HH:mm, optional)
            if !fields[6].isEmpty, let time = timeFormatter.date(from: fields[6]) {
                let timeComps = calendar.dateComponents([.hour, .minute], from: time)
                var dateComps = calendar.dateComponents([.year, .month, .day], from: diveDate)
                dateComps.hour = timeComps.hour
                dateComps.minute = timeComps.minute
                entry.endDate = calendar.date(from: dateComps) ?? diveDate
            } else {
                entry.endDate = entry.startDate.addingTimeInterval(TimeInterval(bottomTimeMinutes * 60))
            }

            // Column 7: Max Depth
            if let depthVal = Float(fields[7]) {
                entry.maxDepth = fileIsImperial ? depthVal / 3.28084 : depthVal
            }

            // Column 8: Visibility
            entry.visibility = parseOptionalFloat(fields[8])

            // Column 9: Visibility Rating
            entry.visibilityCategory = visibilityRating(rawValue: fields[9])

            // Column 10: Rating
            if let rat = Int(fields[10]) {
                entry.rating = rat
            }

            // Columns 11-29
            entry.weight = parseOptionalFloat(fields[11])
            entry.weightCategory = Weighting(rawValue: fields[12])
            entry.tankSize = parseOptionalFloat(fields[13])
            entry.tankMaterial = tankCategory(rawValue: fields[14])
            entry.gasMixture = gasCategory(rawValue: fields[15])
            entry.startPressure = parseOptionalFloat(fields[16])
            entry.endPressure = parseOptionalFloat(fields[17])
            entry.suitType = suitCategoryFromName(fields[18])
            entry.waterType = waterCategory(rawValue: fields[19])
            entry.waterBody = waterbodyCategory(rawValue: fields[20])
            entry.waves = wavesCategory(rawValue: fields[21])
            entry.current = currentCategory(rawValue: fields[22])
            entry.surge = surgeCategory(rawValue: fields[23])
            entry.airTemp = parseOptionalFloat(fields[24])
            entry.surfTemp = parseOptionalFloat(fields[25])
            entry.bottomTemp = parseOptionalFloat(fields[26])
            entry.notes = fields[27]

            if let lat = Double(fields[28]) {
                entry.latitude = lat
            }
            if let lon = Double(fields[29]) {
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

    // MARK: - UDDF Import

    private func findUDDFDuplicateTitles(in data: Data) throws -> [String] {
        let parser = UDDFParser()
        try parser.parse(data)

        let existingTitles = Set(entries.map { $0.title })
        var duplicates: [String] = []

        for (index, dive) in parser.dives.enumerated() {
            let title = uddfTitleForDive(dive, index: index, sites: parser.sites)
            if existingTitles.contains(title) {
                duplicates.append(title)
            }
        }

        return duplicates
    }

    private func importUDDF(_ data: Data) throws -> Int {
        let parser = UDDFParser()
        try parser.parse(data)

        var existingTitles = Set(entries.map { $0.title })
        var count = 0

        for (index, dive) in parser.dives.enumerated() {
            let entry = Entry(timestamp: Date())

            // Title with deduplication
            let baseTitle = uddfTitleForDive(dive, index: index, sites: parser.sites)
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

            // Location from site reference
            if let siteRef = dive.siteRef, let site = parser.sites[siteRef] {
                entry.location = site.name
                entry.latitude = site.latitude
                entry.longitude = site.longitude
            }

            // Date and time
            if let datetime = dive.datetime {
                entry.startDate = parseUDDFDate(datetime) ?? Date()
            }

            // Duration → endDate
            if let duration = dive.diveDurationSeconds {
                entry.endDate = entry.startDate.addingTimeInterval(duration)
            } else {
                entry.endDate = entry.startDate
            }

            // Depth (already in meters)
            if let depth = dive.greatestDepthMeters {
                entry.maxDepth = Float(depth)
            }

            // Temperatures (Kelvin → °C)
            if let airTemp = dive.airTemperatureKelvin {
                entry.airTemp = Float(airTemp - 273.15)
            }
            if let bottomTemp = dive.lowestTemperatureKelvin {
                entry.bottomTemp = Float(bottomTemp - 273.15)
            }

            // Gas mixture
            if let mixRef = dive.gasMixRef, let mix = parser.gasMixes[mixRef] {
                entry.gasMixture = mapGasCategory(o2: mix.o2, he: mix.he)
            }

            // Tank data (Pascals → Bar, volume in liters)
            if let volume = dive.tankVolumeLiters {
                entry.tankSize = Float(volume)
            }
            if let startP = dive.startPressurePascals {
                entry.startPressure = Float(startP / 100000.0)
            }
            if let endP = dive.endPressurePascals {
                entry.endPressure = Float(endP / 100000.0)
            }

            modelContext.insert(entry)
            count += 1
        }

        return count
    }

    private func uddfTitleForDive(_ dive: UDDFParser.Dive, index: Int, sites: [String: UDDFParser.Site]) -> String {
        if let siteRef = dive.siteRef, let site = sites[siteRef], !site.name.isEmpty {
            return site.name
        }
        if let number = dive.diveNumber {
            return "Dive \(number)"
        }
        return "UDDF Dive \(index + 1)"
    }

    private func mapGasCategory(o2: Double, he: Double) -> gasCategory {
        if he > 0.01 { return .trimix }
        if abs(o2 - 0.21) < 0.02 { return .air }
        if abs(o2 - 0.32) < 0.02 { return .eanx32 }
        if abs(o2 - 0.36) < 0.02 { return .eanx36 }
        if abs(o2 - 0.40) < 0.02 { return .eanx40 }
        if o2 > 0.21 { return .enriched }
        return .air
    }

    private func parseUDDFDate(_ string: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: string) { return date }
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: string) { return date }
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return df.date(from: string)
    }
}

// MARK: - UDDF Parser

private class UDDFParser: NSObject, XMLParserDelegate {
    struct Site {
        var name: String = ""
        var latitude: Double?
        var longitude: Double?
    }

    struct Dive {
        var datetime: String?
        var diveNumber: Int?
        var siteRef: String?
        var airTemperatureKelvin: Double?
        var greatestDepthMeters: Double?
        var diveDurationSeconds: Double?
        var lowestTemperatureKelvin: Double?
        var gasMixRef: String?
        var tankVolumeLiters: Double?
        var startPressurePascals: Double?
        var endPressurePascals: Double?
    }

    private(set) var sites: [String: Site] = [:]
    private(set) var gasMixes: [String: (o2: Double, he: Double)] = [:]
    private(set) var dives: [Dive] = []

    private var elementStack: [String] = []
    private var currentText = ""

    private var currentSiteId: String?
    private var currentSite: Site?
    private var currentMixId: String?
    private var currentMixO2: Double = 0.21
    private var currentMixHe: Double = 0.0
    private var currentDive: Dive?

    func parse(_ data: Data) throws {
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.shouldProcessNamespaces = false
        guard parser.parse() else {
            if let error = parser.parserError {
                throw error
            }
            throw NSError(domain: "UDDFParser", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Failed to parse UDDF file."])
        }
    }

    // MARK: XMLParserDelegate

    func parser(_ parser: XMLParser, didStartElement elementName: String,
                namespaceURI: String?, qualifiedName: String?,
                attributes attributeDict: [String: String] = [:]) {
        elementStack.append(elementName)
        currentText = ""

        switch elementName {
        case "site":
            if let id = attributeDict["id"] {
                currentSiteId = id
                currentSite = Site()
            }
        case "mix":
            if let id = attributeDict["id"] {
                currentMixId = id
                currentMixO2 = 0.21
                currentMixHe = 0.0
            }
        case "dive":
            currentDive = Dive()
        case "link":
            if let ref = attributeDict["ref"] {
                if isInContext("informationbeforedive") {
                    currentDive?.siteRef = ref
                } else if isInContext("tankdata") {
                    currentDive?.gasMixRef = ref
                }
            }
        default:
            break
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentText += string
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String,
                namespaceURI: String?, qualifiedName: String?) {
        let text = currentText.trimmingCharacters(in: .whitespacesAndNewlines)

        switch elementName {
        // Site elements
        case "name":
            if currentSite != nil {
                currentSite?.name = text
            }
        case "latitude":
            if currentSite != nil, let val = Double(text) {
                currentSite?.latitude = val
            }
        case "longitude":
            if currentSite != nil, let val = Double(text) {
                currentSite?.longitude = val
            }
        case "site":
            if let id = currentSiteId, let site = currentSite {
                sites[id] = site
            }
            currentSiteId = nil
            currentSite = nil

        // Gas mix elements
        case "o2":
            if currentMixId != nil, let val = Double(text) {
                currentMixO2 = val
            }
        case "he":
            if currentMixId != nil, let val = Double(text) {
                currentMixHe = val
            }
        case "mix":
            if let id = currentMixId {
                gasMixes[id] = (o2: currentMixO2, he: currentMixHe)
            }
            currentMixId = nil

        // Dive elements
        case "datetime":
            if currentDive != nil {
                currentDive?.datetime = text
            }
        case "divenumber":
            if currentDive != nil, let val = Int(text) {
                currentDive?.diveNumber = val
            }
        case "airtemperature":
            if currentDive != nil, let val = Double(text) {
                currentDive?.airTemperatureKelvin = val
            }
        case "greatestdepth":
            if currentDive != nil, let val = Double(text) {
                currentDive?.greatestDepthMeters = val
            }
        case "diveduration":
            if currentDive != nil, let val = Double(text) {
                currentDive?.diveDurationSeconds = val
            }
        case "lowesttemperature":
            if currentDive != nil, let val = Double(text) {
                currentDive?.lowestTemperatureKelvin = val
            }
        case "tankvolume":
            if currentDive != nil, let val = Double(text) {
                currentDive?.tankVolumeLiters = val
            }
        case "tankpressurebegin":
            if currentDive != nil, let val = Double(text) {
                currentDive?.startPressurePascals = val
            }
        case "tankpressureend":
            if currentDive != nil, let val = Double(text) {
                currentDive?.endPressurePascals = val
            }
        case "dive":
            if let dive = currentDive {
                dives.append(dive)
            }
            currentDive = nil

        default:
            break
        }

        if !elementStack.isEmpty {
            elementStack.removeLast()
        }
    }

    private func isInContext(_ element: String) -> Bool {
        guard elementStack.count >= 2 else { return false }
        return elementStack.dropLast().contains(element)
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
