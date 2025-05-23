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
    
    // Service UUID
    static let serviceUUID = CBUUID(string: "000056ff-0000-1000-8000-00805f9b34fb")
    
    // Characteristic UUIDs
    static let rxCharacteristicUUID = CBUUID(string: "000033F4-0000-1000-8000-00805f9b34fb") // Case to Phone
    static let txCharacteristicUUID = CBUUID(string: "000033f3-0000-1000-8000-00805f9b34fb") // Phone to Case

    // MARK: - Private BLE Properties
    private var centralManager: CBCentralManager!           // CoreBluetooth manager
    private var writeCharacteristic: CBCharacteristic?      // For sending commands
    private var notifyCharacteristic: CBCharacteristic?     // For receiving notifications
    private var discoveredPeripherals: [CBPeripheral] = []
    
    var onPeripheralDiscovered: ((CBPeripheral) -> Void)?
    var onConnectionStateChanged: ((Bool) -> Void)?
    var onDataReceived: ((Data) -> Void)?

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
        isConnected = false
        peripheral = nil
        guard let peripheral else { return }
        centralManager.cancelPeripheralConnection(peripheral)
    }

    /// Send a command to the connected BLE device using HEX format.
    func sendCommand(_ command: BLECommand, value: Int? = nil) {
        guard let writeCharacters = self.writeCharacteristic else {
            print("writeCharacters failed")
            return
        }
        guard let peripheral = peripheral else {
            print("Failed to send in peripheral")
            return
        }
        
        if let data = command.packet(){
            debugPrint(data.base64EncodedString())
            peripheral.writeValue(data, for: writeCharacters, type: .withResponse)
            print("📤 Sent HEX Command: \(data) \(command.description)")
        }
    }
}



// MARK: - CBCentralManagerDelegate and CBPeripheralDelegate Conformance
extension BLEManager: CBCentralManagerDelegate, CBPeripheralDelegate {
    
    /// Connect to the specified BLE peripheral.
    func connectToDevice(_ peripheral: CBPeripheral) {
        self.peripheral = peripheral
        self.peripheral?.delegate = self
        centralManager.stopScan()
        let options: [String: Any] = [
            CBConnectPeripheralOptionNotifyOnConnectionKey: true,         // Notify when connected
            CBConnectPeripheralOptionNotifyOnDisconnectionKey: true,      // Notify when disconnected
            CBConnectPeripheralOptionNotifyOnNotificationKey: true,       // Notify on incoming data
            CBConnectPeripheralOptionEnableTransportBridgingKey: true,    // Enable transport bridging
            CBConnectPeripheralOptionRequiresANCS: true,                  // Requires ANCS support
//            CBConnectPeripheralOptionEnableAutoReconnect: true            // Auto reconnect when available
        ]

        // Connecting to the peripheral with specified options
        centralManager.connect(peripheral, options: options)

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
        self.peripheral = peripheral
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
        disconnectDevice()
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }

        let characteristicUUIDs = [Self.rxCharacteristicUUID, Self.txCharacteristicUUID]
        print("🔍 Found services: \(services)")
        
        for service in services {
            if service.uuid == Self.serviceUUID {
                print("✅ Discover Characteristics: \(service.uuid.uuidString)")
                peripheral.discoverCharacteristics(characteristicUUIDs, for: service)
            }
        }
    }


    /// Called when characteristics are discovered for a specific service.
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        
        for characteristic in service.characteristics ?? [] {
            print("Characteristic UUID: \(characteristic.uuid.uuidString)")
           
            print("Properties: \(characteristic.properties)")
            
            print("is Notifying: \(characteristic.isNotifying)")
        }
        
        
        for characteristic in characteristics {
            
            print("✅ Found Characteristic: \(characteristic.uuid.uuidString)")
            
            
            if characteristic.properties.contains(.write) {
                // Safe to write with response
                print("✅✅✅✅✅✅✅Safe to write with response: \(characteristic.uuid.uuidString)")
            } else if characteristic.properties.contains(.writeWithoutResponse) {
                // Write without response
                print("✅ Write without response: \(characteristic.uuid.uuidString)")
            } else {
                print("❌ Writing not allowed for \(characteristic.uuid)")
            }

            
            
            // Store write characteristic
            if characteristic.uuid == CBUUID(string: "33F3") {
                writeCharacteristic = characteristic
                print("✍️ Write Characteristic Found: \(characteristic.uuid.uuidString)")
            }

            // Subscribe to notifications if supported and matches expected UUID
            if characteristic.properties.contains(.notify) || characteristic.properties.contains(.indicate) {
                notifyCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
                
                print("📡 Subscribed to notifications for \(characteristic.uuid.uuidString)")
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
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        print("✅ Wrote to \(characteristic.uuid), error: \(String(describing: error))")
        
        guard let value = characteristic.value else { return }
        let bytes = [UInt8](value)

        // If response is 2 bytes, e.g., [0x12, 0x34]
        let response16 = UInt16(bytes[0]) | UInt16(bytes[1]) << 8  // 0x3412
        print("16-bit response: \(String(format: "%04X", response16))")

        // For 4 bytes
        if bytes.count >= 4 {
            let response32 = UInt32(bytes[0])
                           | UInt32(bytes[1]) << 8
                           | UInt32(bytes[2]) << 16
                           | UInt32(bytes[3]) << 24
            print("32-bit response: \(String(format: "%08X", response32))")
        }
    }


    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        print("📥 Received update from \(characteristic.uuid): \(String(describing: characteristic.value))")
    }

}
