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
    var id: UUID = UUID()
    var timestamp: Date = Date()
    var title: String = ""
    var location: String = ""
    var diveType: diveCategory?
    var startDate: Date = Date()
    var endDate: Date = Date()
    var maxDepth: Float = 0 // meters
    var weight: Float? //kg
    var weightCategory: Weighting?
    var tankSize: Float?
    var tankMaterial: tankCategory?
    var suitType: suitCategory?
    var waterType: waterCategory?
    var waterBody: waterbodyCategory?
    var waves: wavesCategory?
    var current: currentCategory?
    var surge: surgeCategory?
    var visibility: Float?
    var visibilityCategory: visibilityRating?
    var notes: String = ""
    var rating: Int = 0
    var startPressure: Float?
    var endPressure: Float?
    var gasMixture: gasCategory?
    var surfTemp: Float?
    var airTemp: Float?
    var bottomTemp: Float?
    var photos: [Data] = []
    var latitude: Double?
    var longitude: Double?


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
        self.visibility = nil
        self.visibilityCategory = nil
        self.notes = ""
        self.rating = 0
    }
}

enum diveCategory: String, CaseIterable, Codable, Identifiable {
    case shore
    case boat
    case other
    var id: Self { self }
}

enum visibilityRating: String, CaseIterable, Codable, Identifiable {
    case low
    case average
    case high
    var id: Self { self }
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

enum gasCategory: String, CaseIterable, Codable, Identifiable {
    case air
    case eanx32
    case eanx36
    case eanx40
    case enriched
    case trimix
    case rebreather
    var id: Self { self }
}

enum suitCategory: CaseIterable, Codable, Identifiable {
    case fullSuit3
    case fullSuit5
    case fullSuit7
    case drySuit
    case semiDry
    case shorty
    case none
    var id: Self { self }
    
    var name: String {
        switch self {
        case .fullSuit3:
            return "Full Suit 3mm"
        case .fullSuit5:
            return "Full Suit 5mm"
        case .fullSuit7:
            return  "Full Suit 7mm"
        case .drySuit:
            return "Dry Suit"
        case .semiDry:
            return "Semi Dry"
        case .shorty:
            return "Shorty"
        case .none:
            return "None"
        }
    }
}

enum waterCategory: String, CaseIterable, Codable, Identifiable {
    case Salt
    case Fresh
    var id: Self { self }
}

enum waterbodyCategory: String, CaseIterable, Codable, Identifiable {
    case Ocean
    case Lake
    case Quarry
    case River
    case Other
    var id: Self { self }
}

enum wavesCategory: String, CaseIterable, Codable, Identifiable {
    case None
    case Small
    case Medium
    case Large
    var id: Self { self }
}

enum currentCategory: String, CaseIterable, Codable, Identifiable {
    case None
    case Light
    case Medium
    case Strong
    var id: Self { self }
}

enum surgeCategory: String, CaseIterable, Codable, Identifiable {
    case Light
    case Medium
    case Strong
    var id: Self { self }
}
