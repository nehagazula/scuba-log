//
//  ContentView.swift
//  Scuba Log
//
//  Created by Neha Peace on 4/7/24.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var entries: [Entry]
    @State private var showingNewEntryView = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(entries) { entry in
                    NavigationLink {
                        EntryView(entry: entry)
                    } label: {
                        VStack(alignment: .leading, spacing: 4){
                            Text("\(entry.title)").bold()
                            Text("\(entry.startDate, format: Date.FormatStyle(date: .abbreviated)), \(entry.location)").font(.footnote)
                        }
                    }
                }
                .onDelete(perform: deleteItems)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: {
                        showingNewEntryView = true
                    }) {
                        Label("Add Item", systemImage: "plus")
                    }
                    .padding()
                }
            }
            .navigationBarTitle("Scuba Log", displayMode: .large)
        }
        .sheet(isPresented: $showingNewEntryView) {
            NewEntryView(isPresented: $showingNewEntryView, addItem: addItem)
                .interactiveDismissDisabled()
        }
    }
    
    private func addItem(_ newItem: Entry) {
        withAnimation {
            modelContext.insert(newItem)
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(entries[index])
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Entry.self, inMemory: true)
}
