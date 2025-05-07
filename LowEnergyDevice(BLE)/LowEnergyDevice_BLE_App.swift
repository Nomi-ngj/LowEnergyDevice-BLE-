//
//  LowEnergyDevice_BLE_App.swift
//  LowEnergyDevice(BLE)
//
//  Created by Nouman Gul Junejo on 07/03/2025.
//

import SwiftUI

@main
struct LowEnergyDevice_BLE_App: App {
    @ObservedObject var router = Router()
    
    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $router.navPath) {
                BLEDeviceListView()
                    .navigationDestination(for: AuthFlow.self) { destination in
                        router.destination(for: destination)
                            .navigationBarBackButtonHidden()
                    }
            }
            .environmentObject(router)
        }
    }
}
