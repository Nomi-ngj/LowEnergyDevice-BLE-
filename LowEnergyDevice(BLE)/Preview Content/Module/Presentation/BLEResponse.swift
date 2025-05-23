//
//  BLEResponse.swift
//  LowEnergyDevice(BLE)
//
//  Created by Nouman Gul Junejo on 07/03/2025.
//

import Foundation

/// ✅ Enum representing responses received from the BLE Device (Case → App)
enum BLEResponse: String, CaseIterable {
    case caseBatteryVoltage = "CaseBatV"  // 2 Bytes - Current battery voltage (LSB = 1mV)
    case caseBatteryLevel = "CaseBatPct"  // 1 Byte - Current battery level in percentage
    case status = "Status"                // 1 Byte - Charging status bits
    case caseSolarChargeInfo = "CaseSolChgInfo"  // 18 Bytes - Solar charge history (past 9 days) //05
    case caseUSBChargeInfo = "CaseUSBChgInfo"    // 18 Bytes - USB charge history (past 9 days)
    case phoneChargeInfo = "PhnChgFromCaseInfo"  // 18 Bytes - Phone charge history (past 9 days)
    case todayChargeInfo = "TodayChgInfo"  // 6 Bytes - Charge data for today
    case caseTemperature = "CaseTemp"      // 2 Bytes - Case temperature (triggers when above or below limits)
    case solarCurrent = "SolarCurr"        // 2 Bytes - Solar charging current in mA

    /// ✅ Convert response type to corresponding HEX identifier for BLE communication
    func hexValue() -> String {
        switch self {
        case .caseBatteryVoltage:
            return "A1"
        case .caseBatteryLevel:
            return "A2"
        case .status:
            return "A3"
        case .caseSolarChargeInfo:
            return "A4"
        case .caseUSBChargeInfo:
            return "A5"
        case .phoneChargeInfo:
            return "A6"
        case .todayChargeInfo:
            return "A7"
        case .caseTemperature:
            return "A8"
        case .solarCurrent:
            return "A9"
        }
    }
}
