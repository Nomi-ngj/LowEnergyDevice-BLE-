//
//  BLECommand.swift
//  LowEnergyDevice(BLE)
//
//  Created by Nouman Gul Junejo on 07/03/2025.
//

import Foundation
import UIKit

/// ✅ Enum representing commands sent from the App to the BLE Device
enum BLECommand: CaseIterable {
    case sendPassword
    case queryPowerBankStatus
    case setPowerBankTime
    case maxChargeVoltage
    case minChargeVoltage
    case enablePhoneCharger
    case enableSolarCharging
    case enableUSBCharging
    case burstThreshold
    case pwmThreshold
    case minSolarVoltage
    case updatePeriod
    case firmwareUpdate
    case caseTempMax
    case caseTempMin
    
    var description: String {
        switch self {
        case .setPowerBankTime:
            return "SetPowerBankTime"
        case .sendPassword:
            return "Password"
        case .queryPowerBankStatus:
            return "QueryPowerBankStatus"
        case .maxChargeVoltage:
            return "MaxChgV"
        case .minChargeVoltage:
            return "MinChgV"
        case .enablePhoneCharger:
            return "EnPhCharger"
        case .enableSolarCharging:
            return "EnSolar"
        case .enableUSBCharging:
            return "EnUSBCharging"
        case .burstThreshold:
            return "BurstThreshL"
        case .pwmThreshold:
            return "PWMThreshL"
        case .minSolarVoltage:
            return "MinSolar"
        case .updatePeriod:
            return "Period"
        case .firmwareUpdate:
            return "FWUpdate"
        case .caseTempMax:
            return "CaseTempMax"
        case .caseTempMin:
            return "CaseTempMin"
        }
    }

    /// Convert Data to HEX string.
    func dataToHexString(_ data: Data) -> String {
        return data.map { String(format: "%02X", $0) }.joined()
    }
    
    /// 📝 User-friendly description for each command
    var text: String {
        switch self {
        case .sendPassword:
            return "Send Password Command"
        case .setPowerBankTime:
            return "Set power bank time"
        case .queryPowerBankStatus:
            return "Query power bank status"
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
        }
    }
    
    func toLittleEndian20BitBytes(_ value: UInt32) -> [UInt8] {
        precondition(value <= 0xFFFFF, "Value exceeds 20-bit limit")
        return [
            UInt8(value & 0xFF),
            UInt8((value >> 8) & 0xFF),
            UInt8((value >> 16) & 0x0F) // only lower 4 bits of the 3rd byte
        ]
    }
    
    func createCommandData(_ bytes: [UInt8]) -> Data {
        return Data(bytes)
    }

    func packet(with value: Int? = nil) -> Data? {
        switch self {
        case .sendPassword:
            //1988888
            let commandBytes: [UInt8] = [0x19, 0x88, 0x88, 0x88]

            let payload = createCommandData(commandBytes)
            return payload

        case .queryPowerBankStatus:
            let batteryLevel = UIDevice.current.batteryLevel * 100
            let phoneBatteryPercentage = UInt16(max(0, min(100, Int(batteryLevel))))

            var payload = Data([UInt8](repeating: 0x00, count: 6)) // First 6 bytes = AA–FF = 0x00

            // Append phone battery percentage in little-endian
            payload.append(contentsOf: withUnsafeBytes(of: phoneBatteryPercentage.littleEndian) { Array($0) }) // GG-HH

            // Remaining bytes (II–SS) = 10 bytes
            payload.append(contentsOf: [UInt8](repeating: 0x00, count: 10))

            return makeFixedPacket(command: 0x04, payload: payload)


        case .setPowerBankTime:
            let date = Date()
            let calendar = Calendar.current
            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
            
            var payload = Data()
            
            // Year (2 bytes, little-endian)
            let year = UInt16(components.year ?? 2025)
            payload.append(contentsOf: withUnsafeBytes(of: year.littleEndian) { Data($0) })
            
            // Month (1 byte)
            payload.append(UInt8(components.month ?? 1))
            
            // Day (1 byte)
            payload.append(UInt8(components.day ?? 1))
            
            // Hour (1 byte)
            payload.append(UInt8(components.hour ?? 0))
            
            // Minute (1 byte)
            payload.append(UInt8(components.minute ?? 0))
            
            // Second (1 byte)
            payload.append(UInt8(components.second ?? 0))
            
            // Add remaining bytes (set to 00)
            payload.append(contentsOf: [UInt8](repeating: 0x00, count: 12))
            
            return makeFixedPacket(command: 0x0D, payload: payload)

        case .maxChargeVoltage:
            guard let value = value else { return nil }
            let voltage = UInt16(value)
            var payload = Data()
            payload.append(contentsOf: withUnsafeBytes(of: voltage.littleEndian) { Data($0) })
            payload.append(contentsOf: [UInt8](repeating: 0x00, count: 17))
            return makeFixedPacket(command: 0x01, payload: payload)

        case .minChargeVoltage:
            guard let value = value else { return nil }
            let voltage = UInt16(value)
            var payload = Data()
            payload.append(contentsOf: withUnsafeBytes(of: voltage.littleEndian) { Data($0) })
            payload.append(contentsOf: [UInt8](repeating: 0x00, count: 17))
            return makeFixedPacket(command: 0x02, payload: payload)

        case .enablePhoneCharger:
            guard let value = value else { return nil }
            var payload = Data()
            payload.append(UInt8(value))
            payload.append(contentsOf: [UInt8](repeating: 0x00, count: 18))
            return makeFixedPacket(command: 0x03, payload: payload)

        case .enableSolarCharging:
            guard let value = value else { return nil }
            var payload = Data()
            payload.append(UInt8(value))
            payload.append(contentsOf: [UInt8](repeating: 0x00, count: 18))
            return makeFixedPacket(command: 0x04, payload: payload)

        case .enableUSBCharging:
            guard let value = value else { return nil }
            var payload = Data()
            payload.append(UInt8(value))
            payload.append(contentsOf: [UInt8](repeating: 0x00, count: 18))
            return makeFixedPacket(command: 0x05, payload: payload)

        case .burstThreshold:
            guard let value = value else { return nil }
            let threshold = UInt16(value)
            var payload = Data()
            payload.append(contentsOf: withUnsafeBytes(of: threshold.littleEndian) { Data($0) })
            payload.append(contentsOf: [UInt8](repeating: 0x00, count: 17))
            return makeFixedPacket(command: 0x06, payload: payload)

        case .pwmThreshold:
            guard let value = value else { return nil }
            let threshold = UInt16(value)
            var payload = Data()
            payload.append(contentsOf: withUnsafeBytes(of: threshold.littleEndian) { Data($0) })
            payload.append(contentsOf: [UInt8](repeating: 0x00, count: 17))
            return makeFixedPacket(command: 0x07, payload: payload)

        case .minSolarVoltage:
            guard let value = value else { return nil }
            let voltage = UInt16(value)
            var payload = Data()
            payload.append(contentsOf: withUnsafeBytes(of: voltage.littleEndian) { Data($0) })
            payload.append(contentsOf: [UInt8](repeating: 0x00, count: 17))
            return makeFixedPacket(command: 0x08, payload: payload)

        case .updatePeriod:
            guard let value = value else { return nil }
            let period = UInt16(value)
            var payload = Data()
            payload.append(contentsOf: withUnsafeBytes(of: period.littleEndian) { Data($0) })
            payload.append(contentsOf: [UInt8](repeating: 0x00, count: 17))
            return makeFixedPacket(command: 0x09, payload: payload)

        case .firmwareUpdate:
            let payload = Data([UInt8](repeating: 0x00, count: 19))
            return makeFixedPacket(command: 0x0A, payload: payload)

        case .caseTempMax:
            guard let value = value else { return nil }
            let temp = UInt16(value)
            var payload = Data()
            payload.append(contentsOf: withUnsafeBytes(of: temp.littleEndian) { Data($0) })
            payload.append(contentsOf: [UInt8](repeating: 0x00, count: 17))
            return makeFixedPacket(command: 0x0B, payload: payload)

        case .caseTempMin:
            guard let value = value else { return nil }
            let temp = UInt16(value)
            var payload = Data()
            payload.append(contentsOf: withUnsafeBytes(of: temp.littleEndian) { Data($0) })
            payload.append(contentsOf: [UInt8](repeating: 0x00, count: 17))
            return makeFixedPacket(command: 0x0C, payload: payload)
        }
    }

    private func makeFixedPacket(command: UInt8?, payload: Data) -> Data {
        var data = Data()
        if let command = command {
            data.append(command)
        }
        data.append(payload)
        if data.count < 20 {
            data.append(Data(repeating: 0x00, count: 20 - data.count))
        }
        return data
    }
}

