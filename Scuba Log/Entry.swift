//
//  Entry.swift
//  Scuba Log
//
//  Created by Neha Peace on 4/7/24.
//

import Foundation
import SwiftData

@Model
final class Entry {
    @Attribute(.unique) var id: UUID
    @Attribute var timestamp: Date
    @Attribute var title: String
    @Attribute var location: String
    @Attribute var startDate: Date
    @Attribute var endDate: Date
    @Attribute var maxDepth: Float // meters
    @Attribute var weight: Float? //kg
    @Attribute var weightCategory: Weighting?
    @Attribute var tankSize: Float?
    @Attribute var tankMaterial: tankCategory?
    @Attribute var waterType: waterCategory?
    @Attribute var visibility: Float
    @Attribute var notes: String
    @Attribute var rating: Int
    
    init(timestamp: Date) {
        self.id = UUID()
        self.timestamp = timestamp
        self.title = ""
        self.location = ""
        self.startDate = Date.now - 8 * .hour
        self.endDate = Date.now - 7 * .hour
        self.maxDepth = 0
        self.weight = nil
        self.weightCategory = nil
        self.visibility = 0.5
        self.notes = ""
        self.rating = 0
    }
}

enum Weighting: String, CaseIterable, Codable, Identifiable {
    case underweight
    case good
    case overweight
    var id: Self { self }
}

enum tankCategory: String, CaseIterable, Codable, Identifiable {
    case aluminium
    case steel
    case other
    var id: Self { self }
}

enum waterCategory: String, CaseIterable, Codable, Identifiable {
    case Salt
    case Fresh
    var id: Self { self }
}
