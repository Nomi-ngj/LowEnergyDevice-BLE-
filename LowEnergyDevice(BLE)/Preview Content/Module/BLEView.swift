//
//  BLEView.swift
//  LowEnergyDevice(BLE)
//
//  Created by Nouman Gul Junejo on 07/03/2025.
//

import SwiftUI

struct BLEView: View {
    var bleManager: BLEManager!
    @EnvironmentObject var router: Router
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Bluetooth Connection")
                .font(.title)

            // ✅ Connection Status
            if bleManager.isConnected {
                Text("✅ Connected to BLE Device")
                    .foregroundColor(.green)
                
                // ✅ Show received BLE data
                Text("Received Data: \(bleManager.receivedData)")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
            } else {
                Text("❌ Not Connected")
                    .foregroundColor(.red)
            }

            Divider().padding(.vertical, 10)

            Text("🔧 BLE Commands")
                .font(.headline)

            // ✅ List of BLE Commands
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    
                    ForEach(BLECommand.allCases, id: \.self) { command in
                        Button(command.text) {
                            bleManager.sendCommand(command)
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            // ✅ Disconnect Button
            Button("Disconnect") {
                bleManager.isConnected = false
                bleManager.disconnectDevice()
                router.navigateBack()
            }
            .buttonStyle(.bordered)
            .foregroundColor(.red)
            .padding()
            .padding(.top)
        }
        .padding()
    }
}

