//
//  AuthFlow.swift
//  LowEnergyDevice(BLE)
//
//  Created by Nouman Gul Junejo on 07/05/2025.
//

import Foundation

enum AuthFlow: Hashable {
    case bleDetails(bleManager: BLEManager)
    
    func hash(into hasher: inout Hasher) {
        switch self {
        case .bleDetails(let bleManager):
            hasher.combine(bleManager)
        }
    }
    
    static func == (lhs: AuthFlow, rhs: AuthFlow) -> Bool {
        switch (lhs, rhs) {
        case (.bleDetails(let lhsManager), .bleDetails(let rhsManager)):
            return lhsManager === rhsManager
        }
    }
}
