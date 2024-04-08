//
//  Item.swift
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
    @Attribute var startDate: Date
    @Attribute var endDate: Date
    @Attribute var maxDepth: Float // meters
    
    init(timestamp: Date) {
        self.id = UUID()
        self.timestamp = timestamp
        self.title = ""
        self.startDate = Date.now - 8 * .hour
        self.endDate = Date.now - 7 * .hour
        self.maxDepth = 0
    }
}

extension TimeInterval {
    static var hour: TimeInterval { 60 * 60 }
    static var day: TimeInterval { 24 * Self.hour }
    
}
