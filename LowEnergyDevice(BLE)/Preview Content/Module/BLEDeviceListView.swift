//
//  BLEDeviceListView.swift
//  LowEnergyDevice(BLE)
//
//  Created by Nouman Gul Junejo on 07/03/2025.
//

import SwiftUI

struct BLEDeviceListView: View {
    @ObservedObject private var bleManager = BLEManager()
    @EnvironmentObject var router: Router
    var body: some View {
            VStack {
                Text("Bluetooth Devices")
                    .font(.title)
                    .padding()
                
                // ✅ Show Scanning Status
                if bleManager.isScanning {
                    Text("🔍 Scanning...")
                        .foregroundColor(.blue)
                } else {
                    Text("✅ Scan Complete")
                        .foregroundColor(.green)
                }
                
                // ✅ List of Discovered Devices
                List(bleManager.discoveredDevices, id: \.identifier) { device in
                    Button(action: {
                        bleManager.connectToDevice(device) // ✅ Connect on selection
                    }) {
                        HStack {
                            
                            if bleManager.peripheral == device {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                            Text(device.name ?? "Unknown Device")
                                .font(.headline)
                            Spacer()
                            if bleManager.peripheral == device {
                                
                                Button("Disconnect") {
                                    bleManager.disconnectDevice() // ✅ Disconnect to selected device
                                }
                            }
                            else {
                                Button("Connect") {
                                    bleManager.connectToDevice(device) // ✅ Connect to selected device
                                }
                            }
                        }
                    }
                }
                
                // ✅ Scan / Stop Button
                Button(bleManager.isScanning ? "Stop Scanning" : "Start Scanning") {
                    if bleManager.isScanning {
                        bleManager.stopScanning()
                    } else {
                        bleManager.startScanning()
                    }
                }
                .buttonStyle(.borderedProminent)
                .padding()
            }
            .onChange(of: bleManager.isConnected) { newValue in
                if newValue {
                    router.navigate(to: .bleDetails(bleManager: self.bleManager))
                }
            }
    }
}
