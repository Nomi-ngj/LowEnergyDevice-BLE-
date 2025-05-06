//
//  LowEnergyDevice_BLE_App.swift
//  LowEnergyDevice(BLE)
//
//  Created by Nouman Gul Junejo on 07/03/2025.
//

import SwiftUI

@main
struct LowEnergyDevice_BLE_App: App {
    var body: some Scene {
        WindowGroup {
            BLEDeviceListView()
        }
    }
}
