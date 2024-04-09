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
        Form {
            Section {
                LocationFormView(text: $newEntry.title, label: "Dive Location", placeholder: "Breakwater")
            }
            Section {
                DateFormView(date: $newEntry.startDate, label: "Start")
                DateFormView(date: $newEntry.endDate, label: "End")
            }
            Section {
                DepthFormView(value: $newEntry.maxDepth, isMetric: $isMetric, label: "Maximum Depth")
            }
            Section {
                WeightFormView(weight: $newEntry.weight, weightCategory: $newEntry.weightCategory, isMetric: $isMetric, label: "Weight")
            }
        }
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


