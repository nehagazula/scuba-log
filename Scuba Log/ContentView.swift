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
    @State private var showingSettings = false
    @AppStorage("appAppearance") private var appAppearanceRawValue: String = AppAppearance.system.rawValue
    
    private var appAppearance: AppAppearance {
        AppAppearance(rawValue: appAppearanceRawValue) ?? .system
    }
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Total dives: \(entries.count)")
                    Spacer()
                    Text("Dive time: \(totalTimeFormatted)")
                }
                .font(.subheadline)
                .foregroundColor(.primary)
                .padding(.horizontal)
                
                List {
                    ForEach(entries) { entry in
                        ZStack {
                            NavigationLink(destination: EntryView(entry: entry)) {
                                EmptyView()
                            }
                            .opacity(0)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(entry.title)").bold()
                                Text("\(entry.startDate, format: Date.FormatStyle(date: .abbreviated)), \(entry.location)").font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                    }
                    .onDelete(perform: deleteItems)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                }
                .listStyle(.plain)
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
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            showingSettings = true
                        } label: {
                            Image(systemName: "gear")
                        }
                    }
                }
                .navigationTitle("Scuba Log")
                .navigationBarTitleDisplayMode(.large)
            }
        }
        .sheet(isPresented: $showingNewEntryView) {
            NewEntryView(isPresented: $showingNewEntryView, addItem: addItem)
                .interactiveDismissDisabled()
        }
        .sheet(isPresented: $showingSettings) {
            NavigationView{
                SettingsView()
            }
        }
        .preferredColorScheme(appAppearance.colorScheme)
    }
    
    private var totalTimeFormatted: String {
        let totalSeconds = entries.reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
        let hours = Int(totalSeconds) / 3600
        let minutes = (Int(totalSeconds) % 3600) / 60
        return "\(hours)h \(minutes)m"
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
