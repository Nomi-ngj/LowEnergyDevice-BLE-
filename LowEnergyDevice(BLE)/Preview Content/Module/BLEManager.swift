//
//  BLEManager.swift
//  LowEnergyDevice(BLE)
//
//  Created by Nouman Gul Junejo on 07/03/2025.
//

import Foundation
import CoreBluetooth

//Device password = "Command"

/// `BLEManager` is a Bluetooth Low Energy (BLE) controller class for managing BLE connections in SwiftUI.
/// It handles scanning, connecting, sending commands, receiving notifications, and updating UI state using Combine.
/// This class conforms to `ObservableObject` to allow real-time UI updates in SwiftUI apps.
class BLEManager: NSObject, ObservableObject {
    
    // MARK: - Published Properties (for UI Bindings)
    @Published var isScanning = false                       // Scanning status
    @Published var isConnected = false                      // Connection status
    @Published var receivedData: String = ""                // Latest received response
    @Published var discoveredDevices: [CBPeripheral] = []   // Discovered peripherals
    @Published var peripheral: CBPeripheral?                // Currently connected peripheral

    // MARK: - Private BLE Properties
    private var centralManager: CBCentralManager!           // CoreBluetooth manager
    private var writeCharacteristic: CBCharacteristic?      // For sending commands
    private var notifyCharacteristic: CBCharacteristic?     // For receiving notifications

    // MARK: - Initialization
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: .main)
    }

    // MARK: - Public BLE Controls

    /// Start scanning for all nearby BLE devices.
    func startScanning() {
        isScanning = true
        discoveredDevices.removeAll()
        centralManager.scanForPeripherals(withServices: nil, options: nil)
    }

    /// Stop scanning for BLE devices.
    func stopScanning() {
        isScanning = false
        centralManager.stopScan()
    }

    /// Disconnect from the currently connected device.
    func disconnectDevice() {
        guard let peripheral else { return }
        centralManager.cancelPeripheralConnection(peripheral)
    }

    /// Send a command to the connected BLE device using HEX format.
    func sendCommand(_ command: BLECommand) {
        guard let peripheral = peripheral, let writeCharacteristic = writeCharacteristic else {
            print("❌ No connected device.")
            return
        }
        
        if let data = command.packet(){
            peripheral.writeValue(data, for: writeCharacteristic, type: .withResponse)
            print("📤 Sent HEX Command: \(data) (\(command.rawValue))")
        }
    }
}

// MARK: - Private BLE Utility Extensions
private extension BLEManager {

    /// Subscribe to notifications on a characteristic.
    func subscribeToNotifications(for characteristic: CBCharacteristic) {
        peripheral?.setNotifyValue(true, for: characteristic)
        print("📡 Subscribed to notifications for \(characteristic.uuid.uuidString)")
    }
}


// MARK: - CBCentralManagerDelegate and CBPeripheralDelegate Conformance
extension BLEManager: CBCentralManagerDelegate, CBPeripheralDelegate {
    
    /// Connect to the specified BLE peripheral.
    func connectToDevice(_ peripheral: CBPeripheral) {
        self.peripheral = peripheral
        self.peripheral?.delegate = self
        centralManager.stopScan()
        centralManager.connect(peripheral, options: nil)
        self.sendCommand(.sendPassword)
        debugPrint("Connect to Selected Device \(peripheral)")
    }
    
    /// Called when BLE state changes.
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            print("✅ Bluetooth is ON")
        } else {
            print("❌ Bluetooth is OFF or unavailable.")
            print(central.state)
        }
    }

    /// Called when a BLE peripheral is discovered during scanning.
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        
        guard let deviceName = peripheral.name, deviceName == "iPowerUp Uno" else {
            return // Ignore devices not matching the expected name
        }
        debugPrint("✅ Peripheral is Discover")
        
        // Avoid duplicates
        DispatchQueue.main.async {
            if !self.discoveredDevices.contains(where: { $0.identifier == peripheral.identifier }) {
                self.discoveredDevices.append(peripheral)
                self.centralManager.stopScan()
                print("✅ Discovered: \(deviceName) (\(peripheral.identifier.uuidString))")
            }
        }
    }

    /// Called when a connection to a BLE device is successful.
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("🎉 Connected to \(peripheral.name ?? "Unknown Device")")
        isConnected = true
        peripheral.delegate = self
        peripheral.discoverServices(nil) // Start discovering services
    }

    /// Called when connection to a BLE device fails.
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("❌ Failed to connect: \(error?.localizedDescription ?? "Unknown error")")
    }

    /// Called when the BLE device is disconnected.
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("🔌 Disconnected from \(peripheral.name ?? "Unknown Device")")
        isConnected = false
        self.peripheral = nil
    }

    /// Called when services are discovered on the connected peripheral.
//    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
//        guard let services = peripheral.services else { return }
//        for service in services {
//            print("🔍 Found Service: \(service.uuid.uuidString)")
//            peripheral.discoverCharacteristics(nil, for: service)
//        }
//    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }

        let rxUUID = CBUUID(string: "000033F3-0000-1000-8000-00805F9B34FB")
        let txUUID = CBUUID(string: "000033F4-0000-1000-8000-00805F9B34FB")
        let characteristicUUIDs = [rxUUID, txUUID]

        for service in services {
            print("🔍 Found Service: \(service.uuid)")
            if service.uuid == CBUUID(string: "000056FF") {
                print("✅ Discover Characteristics: \(service.uuid.uuidString)")
                peripheral.discoverCharacteristics(characteristicUUIDs, for: service)
            }
        }
    }


    /// Called when characteristics are discovered for a specific service.
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        
        for characteristic in characteristics {
            
            
            // Store write characteristic
            if characteristic.properties.contains(.write) || characteristic.properties.contains(.writeWithoutResponse) && characteristic.uuid.uuidString == "33F3"{
                print("✅ Found Characteristic: \(characteristic.uuid.uuidString)")
                writeCharacteristic = characteristic
                print("✍️ Write Characteristic Found: \(characteristic.uuid.uuidString)")
            }

            // Subscribe to notifications if supported and matches expected UUID
            if characteristic.properties.contains(.notify) && characteristic.uuid.uuidString == "33F3" {
                notifyCharacteristic = characteristic
                subscribeToNotifications(for: characteristic)
                print("📡 Subscribed to notifications for \(characteristic)")
            }
        }
    }

    /// Called when notification subscription is successful or fails.
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("❌ Failed to subscribe to \(characteristic.uuid): \(error.localizedDescription)")
        } else {
            print("✅ Successfully subscribed to \(characteristic.uuid)")
        }
    }

    /// Called when notification data is received from the peripheral.
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let data = characteristic.value else { return }
        let hexString = BLECommand.sendPassword.dataToHexString(data)
        print("📥 (HEX: \(hexString))")

        DispatchQueue.main.async {
            // Try matching received hex string to a known BLE response
            if let response = BLEResponse.allCases.first(where: { $0.hexValue() == hexString }) {
                self.receivedData = response.rawValue
                print("📥 Received: \(response.rawValue) (HEX: \(hexString))")
            }

            print("📥 Received Notification: \(hexString) from \(characteristic.uuid.uuidString)")
        }
    }
}
