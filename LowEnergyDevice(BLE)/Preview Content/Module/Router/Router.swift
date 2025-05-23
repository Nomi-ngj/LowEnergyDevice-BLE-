//
//  File.swift
//  LowEnergyDevice(BLE)
//
//  Created by Nouman Gul Junejo on 07/05/2025.
//

import SwiftUI

final class Router: ObservableObject {
    @Published var navPath = NavigationPath()
    private var destinations: [AnyHashable] = []

    @Published var root:RootFlow = .bleConnection
    
    func navigate(to destination: AuthFlow) {
        destinations.append(destination)
        navPath.append(destination)
    }
    
    func navigateBack() {
        if !destinations.isEmpty {
            destinations.removeLast()
            navPath.removeLast()
        }
    }
    
    func navigateToRoot() {
        destinations.removeAll()
        navPath.removeLast(navPath.count)
    }
    
    func containsDestination<T: Hashable>(_ destination: T) -> Bool {
        return destinations.contains(where: { $0 == destination as AnyHashable })
    }
}

import SwiftUI
extension Router {
    @ViewBuilder
    func destination(for destination: AuthFlow) -> some View {
        switch destination {
        case .bleDetails(let bleManager):
            BLEView(bleManager: bleManager)
        }
    }
}
