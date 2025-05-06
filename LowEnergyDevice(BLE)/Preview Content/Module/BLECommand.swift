//
//  BLECommand.swift
//  LowEnergyDevice(BLE)
//
//  Created by Nouman Gul Junejo on 07/03/2025.
//

import Foundation

/// ✅ Enum representing commands sent from the App to the BLE Device
enum BLECommand: String, CaseIterable {
    case sendPassword = "Password"
    case maxChargeVoltage = "MaxChgV"         // 2 Bytes - Stop charging level
    case minChargeVoltage = "MinChgV"         // 2 Bytes - Low voltage to start charging
    case enablePhoneCharger = "EnPhCharger"   // 1 Byte  - Enable/Disable phone charging
    case enableSolarCharging = "EnSolar"      // 1 Byte  - Enable/Disable solar charging
    case enableUSBCharging = "EnUSBCharging"  // 1 Byte  - Enable/Disable USB charging
    case burstThreshold = "BurstThreshL"      // 2 Bytes - Burst mode threshold
    case pwmThreshold = "PWMThreshL"          // 2 Bytes - PWM mode threshold
    case minSolarVoltage = "MinSolar"         // 2 Bytes - Minimum voltage to start solar charging
    case updatePeriod = "Period"              // 1 Byte  - Loop frequency
    case firmwareUpdate = "FWUpdate"          // X Bytes - Trigger firmware update
    case caseTempMax = "CaseTempMax"          // 1 Byte  - Max temp for HOT warning
    case caseTempMin = "CaseTempMin"          // 1 Byte  - Min temp for COLD warning

    /// 🆔 Convert command id to its corresponding HEX value for BLE transmission
    func hexValue() -> String {
        switch self {
        case .sendPassword:        return "19888888"
        case .maxChargeVoltage:    return "01"
        case .minChargeVoltage:    return "02"
        case .enablePhoneCharger:  return "03"
        case .enableSolarCharging: return "040000000000000000000"
        case .enableUSBCharging:   return "05"
        case .burstThreshold:      return "06"
        case .pwmThreshold:        return "07"
        case .minSolarVoltage:     return "08"
        case .updatePeriod:        return "09"
        case .firmwareUpdate:      return "0A"
        case .caseTempMax:         return "0B"
        case .caseTempMin:         return "0C"
        }
    }

    /// Convert HEX string to Data.
    func hexStringToData() -> Data? {
        var hex = hexValue()

        // Remove optional "0x" prefix if present
        if hex.hasPrefix("0x") {
            hex = String(hex.dropFirst(2))
        }

        // Pad with a leading 0 if the string has odd length
        if hex.count % 2 != 0 {
            hex = "0" + hex
        }

        var data = Data()
        var index = hex.startIndex
        while index < hex.endIndex {
            let nextIndex = hex.index(index, offsetBy: 2)
            let byteString = String(hex[index..<nextIndex])
            if let byte = UInt8(byteString, radix: 16) {
                data.append(byte)
            } else {
                return nil // Invalid hex string
            }
            index = nextIndex
        }
        return data
    }

    /// Convert Data to HEX string.
    func dataToHexString(_ data: Data) -> String {
        return data.map { String(format: "%02X", $0) }.joined()
    }
    
    /// 📝 User-friendly description for each command
    var text: String {
        switch self {
        case .maxChargeVoltage:
            return "Set maximum battery voltage for charging"
        case .minChargeVoltage:
            return "Set minimum battery voltage to start charging"
        case .enablePhoneCharger:
            return "Enable or disable phone charging from case"
        case .enableSolarCharging:
            return "04 Enable or disable solar charging"
        case .enableUSBCharging:
            return "Enable or disable USB charging"
        case .burstThreshold:
            return "Set burst charging current threshold"
        case .pwmThreshold:
            return "Set PWM charging current threshold"
        case .minSolarVoltage:
            return "Set minimum solar voltage to start charging"
        case .updatePeriod:
            return "Set loop interval for status updates"
        case .firmwareUpdate:
            return "Trigger firmware update from app"
        case .caseTempMax:
            return "Set max case temperature for heat warning"
        case .caseTempMin:
            return "Set min case temperature for cold warning"
        case .sendPassword:
            return "19888888"
        }
    }
    
    func packet(with value: Int? = nil) -> Data? {
        switch self {
        case .sendPassword:
            // Parse "19888888" into 4 bytes
            let payload = Data([0x19, 0x88, 0x88, 0x88])
            let data = makeFixedPacket(command: 0x01, payload: payload)
            debugPrint(data)
            return data


        case .firmwareUpdate:
            return makeFixedPacket(command: 0x0A, payload: Data()) // Placeholder

        case .maxChargeVoltage:
            fallthrough
        case .minChargeVoltage:
            fallthrough
        case .enablePhoneCharger, .enableSolarCharging, .enableUSBCharging:
            guard let value else { return nil }
            let byte = UInt8(clamping: value)
            return makeFixedPacket(command: UInt8(hexValue(), radix: 16) ?? 0x00, payload: Data([byte]))

        case .burstThreshold, .pwmThreshold, .minSolarVoltage:
            guard let value else { return nil }
            let le = UInt16(clamping: value).littleEndian
            return makeFixedPacket(command: UInt8(hexValue(), radix: 16) ?? 0x00, payload: withUnsafeBytes(of: le) { Data($0) })

        case .updatePeriod, .caseTempMax, .caseTempMin:
            guard let value else { return nil }
            let byte = UInt8(clamping: value)
            return makeFixedPacket(command: UInt8(hexValue(), radix: 16) ?? 0x00, payload: Data([byte]))
        }
    }

    private func makeFixedPacket(command: UInt8, payload: Data) -> Data {
        var data = Data()
        data.append(command)
        data.append(payload)
        if data.count < 20 {
            data.append(Data(repeating: 0x00, count: 20 - data.count))
        }
        return data
    }

    
    
    var defaultValue: Int {
        switch self {
        case .maxChargeVoltage: return 100
        case .minChargeVoltage: return 95
        case .enablePhoneCharger: return 1
        case .enableSolarCharging: return 1
        case .enableUSBCharging: return 1
        case .burstThreshold: return 40
        case .pwmThreshold: return 50
        case .minSolarVoltage: return 4000
        case .updatePeriod: return 10
        case .firmwareUpdate: return 0 // Placeholder; handled differently
        case .caseTempMax: return 60
        case .caseTempMin: return 0
        case .sendPassword: return 0
        }
    }
}

