//
//  NewEntryView.swift
//  Scuba Log
//
//  Created by Neha Peace on 4/7/24.
//

import SwiftUI

struct NewEntryView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var isPresented: Bool
    @State private var newItemTitle: String = ""
    @State private var newEntry: Entry = Entry(timestamp: Date())
    @State private var isMetric: Bool = false
    var addItem: (Entry) -> Void
    
    var body: some View {
        NavigationView {
            VStack {
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
                
                Form {
                    Section {
                        TextFormView(text: $newEntry.title, label: "Dive Location", placeholder: "Breakwater")
                    }
                    Section {
                        DateFormView(date: $newEntry.startDate, label: "Start")
                        DateFormView(date: $newEntry.endDate, label: "End")
                    }
                    Section {
                        NumberFormView(value: $newEntry.maxDepth, isMetric: $isMetric, label: "Maximum Depth")
                    }
                }
            }
        }
    }
}

struct TextFormView: View {
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

struct NumberFormView: View {
    @Binding var value: Float
    @Binding var isMetric: Bool
    var label: String
    
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
                            .tag(Float(depth) / 3.28084)
                    }
                }
            }
            .pickerStyle(WheelPickerStyle())
        }
    }
}
