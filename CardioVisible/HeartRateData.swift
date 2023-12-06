//
//  HeartRateData.swift
//  CardioVisible
//
//  Created by Jack Anderson on 12/5/23.
//

import Foundation

struct HeartRateData: Identifiable {
    let id = UUID()
    var date: Date?
    var minimum: Double?
    var maximum: Double?
    var resting: Double?
    var current: Double?
}
