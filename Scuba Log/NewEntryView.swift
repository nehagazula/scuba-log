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
            }
            // Conditions
            Form {
                Section(header: Text("Conditions")) {
                    WaterFormView(waterType: $newEntry.waterType)
                }
                Section {
                    VisibilityFormView(visibility: $newEntry.visibility)
                }
            }
            // Experience
            Form {
                Section {
                    RatingFormView(rating: $newEntry.rating, label: "Rating")
                }
                
                Section(header: Text("Experience")) {
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

struct WaterFormView: View {
    @Binding var waterType: waterCategory?
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
    }
}

// implement slider view
// add images to slider labels
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








