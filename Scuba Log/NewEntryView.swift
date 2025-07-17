//
//  NewEntryView.swift
//  Scuba Log
//
//  Created by Neha Peace on 4/7/24.
//

import SwiftUI
import MapKit
import PhotosUI
import CoreGraphics

struct NewEntryView: View {
    @Binding var isPresented: Bool
    @State private var newItemTitle: String = ""
    @State private var newEntry: Entry = Entry(timestamp: Date())
//    @State private var isMetric: Bool = false
    var addItem: (Entry) -> Void
    
    var body: some View {
        NavigationView {
            VStack {
                ButtonView(newEntry: $newEntry, isPresented: $isPresented, addItem: addItem)
                EntryFormView(newEntry: $newEntry)
            }
        }
    }
}

struct ButtonView: View {
    @Binding var newEntry: Entry
    @Binding var isPresented: Bool
    var addItem: (Entry) -> Void
    
    var body: some View {
        HStack {
            Button("Cancel") {
                isPresented = false
            }
            .padding()
            
            Spacer()
            
            Text("New Dive")
                .font(.headline)
                .padding()
            
            Spacer()
            
            Button("Create") {
                addItem(newEntry)
                isPresented = false
            }
            .font(.headline)
            .padding()
        }
    }
}

struct EntryFormView: View {
    @Binding var newEntry: Entry
    
    var body: some View {
        TabView {
            // General
            Form {
                Section(header: Text("General")) {
                    LocationFormView(text: $newEntry.title, label: "Dive Title", placeholder: "My dive")
                }
                Section {
                    LocationFormView(text: $newEntry.location, label: "Dive Site", placeholder: "La Jolla Shores")
                }
                Section {
                    DiveTypeFormView(diveType: $newEntry.diveType, label: "Dive Type")
                }
                Section {
                    DateFormView(date: $newEntry.startDate, label: "Start")
                    DateFormView(date: $newEntry.endDate, label: "End")
                }
                Section {
                    DepthFormView(value: $newEntry.maxDepth, label: "Maximum Depth")
                }
            }
            
            // Equipment
            
            Form {
                Section(header: Text("Equipment")) {
                    WeightFormView(weight: $newEntry.weight, weightCategory: $newEntry.weightCategory, label: "Weight")
                }
                Section {
                    TankFormView(tankSize: $newEntry.tankSize, tankMaterial: $newEntry.tankMaterial, gasMixture: $newEntry.gasMixture, label: "Cylinder Size")
                }
                Section {
                    CylinderPressureFormView(startPressure: $newEntry.startPressure, endPressure: $newEntry.endPressure)
                }
                Section {
                    SuitFormView(suitType: $newEntry.suitType)
                }
                Section {
                    OtherGearFormView()
                }
            }
            // Conditions
            Form {
                Section(header: Text("Conditions")) {
                    WaterFormView(waterType: $newEntry.waterType, waterBody: $newEntry.waterBody, waves: $newEntry.waves, current: $newEntry.current, surge: $newEntry.surge)
                }
                Section {
                    VisibilityFormView(visibility: $newEntry.visibility)
                }
                Section {
                    TemperatureFormView(surfTemp: $newEntry.surfTemp, airTemp: $newEntry.airTemp, bottomTemp: $newEntry.bottomTemp)
                }
            }
            // Experience
            Form {
                Section(header: Text("Experience")) {
                    RatingFormView(rating: $newEntry.rating, label: "Rating")
                }
                
                Section {
                    NotesFomView(notes: $newEntry.notes, label: "Notes")
                }
                
                Section {
                    PhotoUploadFormView()
                }
            }
            
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .always))
    }
}

// View model for location autocomplete/suggestions
class LocationSearchViewModel: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var query = ""
    @Published var suggestions: [MKLocalSearchCompletion] = []

    private var completer = MKLocalSearchCompleter()

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = .address
    }

    func updateQuery(_ newQuery: String) {
        query = newQuery
        completer.queryFragment = newQuery
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        self.suggestions = completer.results
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Autocomplete error: \(error.localizedDescription)")
    }
}

struct LocationFormView: View {
    @Binding var text: String
    var label: String
    var placeholder: String
    
    // Location autocomplete and map view
    @StateObject private var viewModel = LocationSearchViewModel()
    @State private var showSuggestions = false
    @State private var selectedCoordinate: CLLocationCoordinate2D? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .frame(alignment: .leading)
                Spacer()
                TextField(placeholder, text: $text)
                    .multilineTextAlignment(.trailing)
                    .onChange(of: text) {
                        showSuggestions = !text.isEmpty
                        viewModel.updateQuery(text)
                        selectedCoordinate = nil
                    }
            }
            // Location suggestions list
            if showSuggestions && !viewModel.suggestions.isEmpty {
                VStack(spacing: 0) {
                    Divider()
                    ForEach(viewModel.suggestions, id: \.self) { suggestion in
                        Button(action: {
                            // set the selected text
                            text = suggestion.title /*+ (suggestion.subtitle.isEmpty ? "" : ", \(suggestion.subtitle)")*/
                            
                            // clear suggestions and hide list
                            viewModel.suggestions = []
                            showSuggestions = false
                            
                            //dismiss keyboard
                            //UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            
                            // look up coordinates for selected suggestion
                            fetchCoordinate(for: suggestion.title)
                        }) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(suggestion.title).bold()
                                if !suggestion.subtitle.isEmpty {
                                    Text(suggestion.subtitle)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .background(Color(UIColor.systemBackground))
                .cornerRadius(6)
                .shadow(radius: 1)
            }
            
            //Map preview with pin
            if let coordinate = selectedCoordinate {
                            Map(position: .constant(.region(MKCoordinateRegion(
                                center: coordinate,
                                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                            )))) {
                                Annotation("Location", coordinate: coordinate) {
                                    Image(systemName: "mappin.circle.fill")
                                        .foregroundColor(.red)
                                        .font(.title)
                                }
                            }
                            .frame(height: 200)
                            .cornerRadius(8)
                            .padding(.top)
                        }
                    }
                }

                private func fetchCoordinate(for placeName: String) {
                    let searchRequest = MKLocalSearch.Request()
                    searchRequest.naturalLanguageQuery = placeName

                    let search = MKLocalSearch(request: searchRequest)
                    search.start { response, error in
                        guard
                            error == nil,
                            let coordinate = response?.mapItems.first?.placemark.coordinate
                        else {
                            selectedCoordinate = nil
                            return
                        }

                        DispatchQueue.main.async {
                            selectedCoordinate = coordinate
                        }
                    }
                }
            }

// Wrapper for Map annotation
struct MapPinItem: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

struct DiveTypeFormView: View {
    @Binding var diveType: diveCategory?
    var label: String
    
    var body: some View {
        VStack {
            Picker("Dive Type",
                   selection: $diveType) {
                ForEach(diveCategory.allCases) { diveType in
                    Text(diveType.rawValue.capitalized)
                        .tag(diveType as diveCategory?)
                }
            }
        }
    }
}

struct DateFormView: View {
    @Binding var date: Date
    var label: String
    
    var body: some View {
        DatePicker(label, selection: $date, displayedComponents: [.date, .hourAndMinute])
            .datePickerStyle(.compact)
    }
}

struct DepthFormView: View {
    @Binding var value: Float
//    @Binding var isMetric: Bool
    @AppStorage("isMetric") private var isMetric = true
    var label: String
    
    let MetersToFeet: Float = 3.28084
    var body: some View {
        Section(header: Text(label)) {
            Picker("Depth", selection: $value) {
                if isMetric {
                    ForEach(1..<100) { depth in
                        Text("\(depth) meters")
                            .tag(Float(depth))
                    }
                } else {
                    ForEach(1..<300) { depth in
                        Text("\(depth) feet")
                            .tag(Float(depth) / MetersToFeet)
                    }
                }
            }
            .pickerStyle(WheelPickerStyle())
        }
    }
}

struct WeightFormView: View {
    @Binding var weight: Float?
    @Binding var weightCategory: Weighting?
//    @Binding var isMetric: Bool
    @AppStorage("isMetric") private var isMetric = true
    
    var label: String
    
    var body: some View {
        let metricPlaceholder = isMetric ? "kg" : "lb"
        
        HStack {
            Text(label)
                .frame(alignment: .leading)
            Spacer()
            TextField("0", value: $weight, format: .number)
                .multilineTextAlignment(.trailing)
            Text(metricPlaceholder)
        }
        
        VStack {
            Picker("Weight Correctness",
                   selection: $weightCategory) {
                ForEach(Weighting.allCases) { weightCategory in
                    Text(weightCategory.rawValue.capitalized)
                        .tag(weightCategory as Weighting?)
                }
            }
        }
        .pickerStyle(.segmented)
    }
}

struct TankFormView: View {
    @Binding var tankSize: Float?
    @Binding var tankMaterial: tankCategory?
    @Binding var gasMixture: gasCategory?
//    @Binding var isMetric: Bool
    @AppStorage("isMetric") private var isMetric = true
    
    var label: String
    
    var body: some View {
        let metricPlaceholder = isMetric ? "Litres" : "Cubic Feet"
        HStack {
            Text(label)
                .frame(alignment: .leading)
            Spacer()
            TextField("0", value: $tankSize, format: .number)
                .multilineTextAlignment(.trailing)
            Text(metricPlaceholder)
        }
        
        VStack {
            Picker("Cylinder Type",
                   selection: $tankMaterial) {
                ForEach(tankCategory.allCases) { tankMaterial in
                    Text(tankMaterial.rawValue.capitalized)
                        .tag(tankMaterial as tankCategory?)
                }
            }
        }
        VStack {
            Picker("Gas Mixture",
                   selection: $gasMixture) {
                ForEach(gasCategory.allCases) { gasMixture in
                    Text(gasMixture.rawValue.capitalized)
                        .tag(gasMixture as gasCategory?)
                }
            }
        }
    }
}

struct SuitFormView: View {
    @Binding var suitType: suitCategory?
    
    var body: some View
    {
        VStack {
            Picker("Suit Type",
                   selection: $suitType) {
                ForEach(suitCategory.allCases) { suitType in
                    Text(suitType.name)
                        .tag(suitType as suitCategory?)
                }
            }
        }
    }
}

// additional gear options
enum DiveGear: String, CaseIterable, Hashable {
    case hood = "Hood"
    case boots = "Boots"
    case gloves = "Gloves"
}

// custom button design for the additional gear
struct GearButton: View {
    let gear: DiveGear
    @Binding var selectedGear: Set<DiveGear>

    var isSelected: Bool {
        selectedGear.contains(gear)
    }

    var body: some View {
        Button(action: {
            if isSelected {
                selectedGear.remove(gear)
            } else {
                selectedGear.insert(gear)
            }
        }) {
            Text(gear.rawValue)
                .frame(maxWidth: .infinity)
                .padding()
                .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(isSelected ? .white : .black)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle()) // to remove weird default tap behavior
    }
}

struct OtherGearFormView: View {
    @State private var showAdditionalGearOptions: Bool = false
    @State private var selectedGear: Set<DiveGear> = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Section {
                Toggle("Additional gear used?", isOn: $showAdditionalGearOptions)
            }
            
            if showAdditionalGearOptions {
                HStack(spacing: 12) {
                    ForEach(DiveGear.allCases, id: \.self) { gear in
                        GearButton(gear: gear, selectedGear: $selectedGear)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            
            if !selectedGear.isEmpty {
                Text("Selected gear: \(selectedGear.map { $0.rawValue }.joined(separator: ", "))")
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .padding(.top, 4)
            }
        }
        .padding(.horizontal)
    }
}

struct CylinderPressureFormView: View {
    @Binding var startPressure: Float?
    @Binding var endPressure: Float?
//    @Binding var isMetric: Bool
    @AppStorage("isMetric") private var isMetric = true
    
    // State for controlling error alert visibility
    
    @State private var showPressureErrorAlert: Bool = false
    @State private var pressureErrorMessage: String = ""
    @State private var calculatedAmountUsed: Float? = nil
    
    var body: some View {
        let metricPlaceholder = isMetric ? "Bar" : "PSI"
        HStack {
            Text("Start Pressure")
                .frame(alignment: .leading)
            Spacer()
            TextField("0", value: $startPressure, format: .number)
                .multilineTextAlignment(.trailing)
            Text(metricPlaceholder)
        }
        
        HStack {
            Text("End Pressure")
                .frame(alignment: .leading)
            Spacer()
            TextField("0", value: $endPressure, format: .number)
                .multilineTextAlignment(.trailing)
            Text(metricPlaceholder)
        }
        
        HStack {
                Text("Amount Used")
                    .frame(alignment: .leading)
                Spacer()
            Text(calculatedAmountUsed != nil ? "\(calculatedAmountUsed!, format: .number) PSI" : "--")
                .foregroundColor(calculatedAmountUsed != nil ? .primary : .gray)
        }
        
        .onChange(of: startPressure) {
            recalculateAmountAndCheckErrors()
        }
        
        .onChange(of: endPressure) {
            recalculateAmountAndCheckErrors()
        }
        
        .alert("Input Error", isPresented: $showPressureErrorAlert) {
            Button("OK") {}
        } message: {
            Text(pressureErrorMessage)
        }
    }
    
    private func recalculateAmountAndCheckErrors() {
        // reset in case previously set
        showPressureErrorAlert = false
        pressureErrorMessage = ""
        calculatedAmountUsed = nil
        
        if let start = startPressure, let end = endPressure {
            if end <= start {
                calculatedAmountUsed = start - end
            } else {
                pressureErrorMessage = "End pressure cannot be higher than start pressure! Please correct the values."
                showPressureErrorAlert = true
            }
        }
    }
}
    
struct WaterFormView: View {
    @Binding var waterType: waterCategory?
    @Binding var waterBody: waterbodyCategory?
    @Binding var waves: wavesCategory?
    @Binding var current: currentCategory?
    @Binding var surge: surgeCategory?
    
    var body: some View {
        VStack {
            Picker("Water Type",
                   selection: $waterType) {
                ForEach(waterCategory.allCases) { waterType in
                    Text(waterType.rawValue.capitalized)
                        .tag(waterType as waterCategory?)
                }
            }
        }
        
        VStack {
            Picker("Water Body",
                   selection: $waterBody) {
                ForEach(waterbodyCategory.allCases) { waterBody in
                    Text(waterBody.rawValue.capitalized)
                        .tag(waterBody as waterbodyCategory?)
                }
            }
        }
        
        VStack {
            Picker("Waves",
                   selection: $waves) {
                ForEach(wavesCategory.allCases) { waves in
                    Text(waves.rawValue.capitalized)
                        .tag(waves as wavesCategory?)
                }
            }
        }
        
        VStack {
            Picker("Current",
                   selection: $current) {
                ForEach(currentCategory.allCases) { current in
                    Text(current.rawValue.capitalized)
                        .tag(current as currentCategory?)
                }
            }
        }
        
        VStack {
            Picker("Surge",
                   selection: $surge) {
                ForEach(surgeCategory.allCases) { surge in
                    Text(surge.rawValue.capitalized)
                        .tag(surge as surgeCategory?)
                }
            }
        }
    }
}

struct TemperatureFormView: View {
    @Binding var surfTemp: Float?
    @Binding var airTemp: Float?
    @Binding var bottomTemp: Float?
//    @Binding var isMetric: Bool
    @AppStorage("isMetric") private var isMetric = true
    
    var body: some View {
        let metricPlaceholder = isMetric ? "°C" : "°F"
        
        HStack {
            Text("Air Temperature")
                .frame(alignment: .leading)
            Spacer()
            TextField("0", value: $airTemp, format: .number)
                .multilineTextAlignment(.trailing)
            Text(metricPlaceholder)
        }
        
        HStack {
            Text("Surface Temperature")
                .frame(alignment: .leading)
            Spacer()
            TextField("0", value: $surfTemp, format: .number)
                .multilineTextAlignment(.trailing)
            Text(metricPlaceholder)
        }
        
        HStack {
            Text("Bottom Temperature")
                .frame(alignment: .leading)
            Spacer()
            TextField("0", value: $bottomTemp, format: .number)
                .multilineTextAlignment(.trailing)
            Text(metricPlaceholder)
        }
    }
}
    

// implements slider view
struct VisibilityFormView: View {
    @Binding var visibility: Float
    
    // to remove fraction digits
    let numberFormatter: NumberFormatter = {
        let num = NumberFormatter()
        num.maximumFractionDigits = 0
        return num
    }()
    
    var body: some View {
        VStack{
            Slider(value: $visibility, in: 0...100)
            Text("Visibility: \(numberFormatter.string(from: NSNumber(value: visibility))!)%")
        }
    }
}

struct NotesFomView: View {
    @Binding var notes: String
    var label: String
    
    var body: some View {
        Text(label)
        TextField("Write down any notable moments", text: $notes, axis: .vertical)
            .lineLimit(4...)
    }
}

struct RatingFormView: View {
    @Binding var rating: Int
    private let maxRating = 5
    var label: String


    var body: some View {
        VStack {
            Text(label)
                .frame(alignment: .leading)
        }
            HStack {
                ForEach(1..<maxRating + 1, id: \.self) { value in
                    Image(systemName: "star")
                        .symbolVariant(value <= rating ? .fill : .none)
                        .foregroundColor(.accentColor)
                        .onTapGesture {
                            if value != rating {
                                rating = value
                            } else {
                                rating = 0
                            }
                        }
                }
            }
        }
    }

 //wrap images with an identifiable struct
struct IdentifiableImage: Identifiable, Equatable {
    let id = UUID()
    let image: UIImage
}

struct PhotoUploadFormView: View {
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedImages: [IdentifiableImage] = []
    @State private var isLoading = false
    @State private var imageToPreview: IdentifiableImage? = nil
    @State private var sheetDidAppear = false

    var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("Dive Photos")
                
                PhotosPicker(
                    selection: $selectedItems,
                    maxSelectionCount: 5,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    Label("Select Photos", systemImage: "photo.on.rectangle")
                }
                .disabled(selectedImages.count >= 5)
                .onChange(of: selectedItems) {
                    isLoading = true
                    Task {
                        var loadedImages = [IdentifiableImage]()
                        for item in selectedItems {
                            if let data = try? await item.loadTransferable(type: Data.self),
                               let uiImage = UIImage(data: data) {
                                loadedImages.append(IdentifiableImage(image: uiImage))
                            }
                        }
                        await MainActor.run {
                            selectedImages = loadedImages
                            isLoading = false
                        }
                    }
                }

                if isLoading {
                    ProgressView()
                        .padding(.top, 8)
                }

                if !selectedImages.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(selectedImages) { identifiableImage in
                                ZStack(alignment: .topTrailing) {
                                    Image(uiImage: identifiableImage.image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                        .clipped()
                                        .onTapGesture {
                                            if sheetDidAppear {
                                                // Small delay to ensure clean presentation
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                                    imageToPreview = identifiableImage
                                                }
                                            }
                                        }

                                    Button(action: {
                                        if let index = selectedImages.firstIndex(of: identifiableImage) {
                                            selectedImages.remove(at: index)
                                            if index < selectedItems.count {
                                                selectedItems.remove(at: index)
                                            }
                                        }
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.white)
                                            .background(Color.black.opacity(0.6))
                                            .clipShape(Circle())
                                    }
                                    .offset(x: -5, y: 5)
                                }
                            }
                        }
                        .id(selectedImages.map(\.id))
                        .padding(.top, 8)
                    }
                }
            }
        }
        .onAppear {
            // Only trigger once
            if !sheetDidAppear {
                sheetDidAppear = true
            }
        }
        .fullScreenCover(item: $imageToPreview) { image in
            ZStack(alignment: .topTrailing) {
                Color.black.ignoresSafeArea()
                Image(uiImage: image.image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black)

                Button {
                    imageToPreview = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                        .padding()
                }
            }
        }
    }
}
