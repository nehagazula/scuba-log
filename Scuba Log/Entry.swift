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
    @Attribute var diveType: diveCategory?
    @Attribute var startDate: Date
    @Attribute var endDate: Date
    @Attribute var maxDepth: Float // meters
    @Attribute var weight: Float? //kg
    @Attribute var weightCategory: Weighting?
    @Attribute var tankSize: Float?
    @Attribute var tankMaterial: tankCategory?
    @Attribute var suitType: suitCategory?
    @Attribute var waterType: waterCategory?
    @Attribute var waterBody: waterbodyCategory?
    @Attribute var waves: wavesCategory?
    @Attribute var current: currentCategory?
    @Attribute var surge: surgeCategory?
    @Attribute var visibility: Float
    @Attribute var notes: String
    @Attribute var rating: Int
    @Attribute var startPressure: Float?
    @Attribute var endPressure: Float?
    @Attribute var gasMixture: gasCategory?
    @Attribute var surfTemp: Float?
    @Attribute var airTemp: Float?
    @Attribute var bottomTemp: Float?

    
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

enum diveCategory: String, CaseIterable, Codable, Identifiable {
    case shore
    case boat
    case other
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
