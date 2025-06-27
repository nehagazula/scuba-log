//
//  NewEntryView.swift
//  Scuba Log
//
//  Created by Neha Peace on 4/7/24.
//

import SwiftUI

struct NewEntryView: View {
    @Binding var isPresented: Bool
    @State private var newItemTitle: String = ""
    @State private var newEntry: Entry = Entry(timestamp: Date())
    @State private var isMetric: Bool = false
    var addItem: (Entry) -> Void
    
    var body: some View {
        NavigationView {
            VStack {
                ButtonView(newEntry: $newEntry, isPresented: $isPresented, addItem: addItem)
                EntryFormView(newEntry: $newEntry, isMetric: $isMetric)
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
    @Binding var isMetric: Bool
    
    var body: some View {
        TabView {
            // General
            Form {
                Section(header: Text("General")) {
                    LocationFormView(text: $newEntry.title, label: "Dive Title", placeholder: "My dive")
                }
                Section {
                    LocationFormView(text: $newEntry.location, label: "Dive Site", placeholder: "Breakwater")
                }
                Section {
                    DiveTypeFormView(diveType: $newEntry.diveType, label: "Dive Type")
                }
                Section {
                    DateFormView(date: $newEntry.startDate, label: "Start")
                    DateFormView(date: $newEntry.endDate, label: "End")
                }
                Section {
                    DepthFormView(value: $newEntry.maxDepth, isMetric: $isMetric, label: "Maximum Depth")
                }
            }
            
            // Equipment
            
            Form {
                Section(header: Text("Equipment")) {
                    WeightFormView(weight: $newEntry.weight, weightCategory: $newEntry.weightCategory, isMetric: $isMetric, label: "Weight")
                }
                Section {
                    TankFormView(tankSize: $newEntry.tankSize, tankMaterial: $newEntry.tankMaterial, label: "Cylinder Size")
                }
                Section {
                    CylinderPressureFormView(startPressure: $newEntry.startPressure, endPressure: $newEntry.endPressure)
                }
                Section {
                    SuitFormView(suitType: $newEntry.suitType)
                }
            }
            // Conditions
            Form {
                Section(header: Text("Conditions")) {
                    WaterFormView(waterType: $newEntry.waterType, waterBody: $newEntry.waterBody)
                }
                Section {
                    VisibilityFormView(visibility: $newEntry.visibility)
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
            }
            
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .always))
    }
}

struct LocationFormView: View {
    @Binding var text: String
    var label: String
    var placeholder: String
    
    var body: some View {
        HStack {
            Text(label)
                .frame(alignment: .leading)
            Spacer()
            TextField(placeholder, text: $text)
                .multilineTextAlignment(.trailing)
        }
    }
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
    @Binding var isMetric: Bool
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
    @Binding var isMetric: Bool
    
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
    var label: String
    
    var body: some View {
        HStack {
            Text(label)
                .frame(alignment: .leading)
            Spacer()
            TextField("0", value: $tankSize, format: .number)
                .multilineTextAlignment(.trailing)
            Text("Cubic Feet")
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

struct CylinderPressureFormView: View {
    @Binding var startPressure: Float?
    @Binding var endPressure: Float?
    
    // State for controlling error alert visibility
    
//    @State private var showPressureErrorAlert: Bool = false
//    @State private var pressureErrorMessage: String = ""
    
    // Compute amountUsed
    
    var amountUsed: Float? {
        if let start = startPressure, let end = endPressure {
            if end <= start {
                return start - end
            } else {
//                pressureErrorMessage = "End pressure cannot be higher than start pressure PSI! Please correct the values."
//                showPressureErrorAlert = true
                return nil
            }
        }
        return nil // if start and end is nil
    }
    
    var body: some View {
        HStack {
            Text("Start Pressure")
                .frame(alignment: .leading)
            Spacer()
            TextField("0", value: $startPressure, format: .number)
                .multilineTextAlignment(.trailing)
            Text("PSI")
        }
        
        HStack {
            Text("End Pressure")
                .frame(alignment: .leading)
            Spacer()
            TextField("0", value: $endPressure, format: .number)
                .multilineTextAlignment(.trailing)
            Text("PSI")
        }
        
        HStack {
                Text("Amount Used")
                    .frame(alignment: .leading)
                Spacer()
            Text(amountUsed != nil ? "\(amountUsed!, format: .number) PSI" : "--")
                .foregroundColor(amountUsed != nil ? .primary : .gray)
        }
        
//        .alert("Input Error", isPresented: $showPressureErrorAlert) {
//            Button("OK") {
//                
//            }
//        } message: {
//            Text(pressureErrorMessage)
//        }
    }
}
    
   


struct WaterFormView: View {
    @Binding var waterType: waterCategory?
    @Binding var waterBody: waterbodyCategory?
    
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








