//
//  ContentView.swift
//  BLEAppTest
//
//  Created by JSenen on 25/11/24.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var bluetoothManager = BluetoothManager()
    
    var body: some View {
        NavigationView {
            List(bluetoothManager.devices) { device in
                NavigationLink(destination: BleDetail(device: device)) {
                    HStack {
                        CircleView(image: device.image) // Vista de imagen circular
                        VStack(alignment: .leading) {
                            Text(device.name)
                                .font(.headline)
                            Text(device.mac)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .refreshable {
                bluetoothManager.restartScan()
            }
            .navigationTitle("Dispositivos BLE")
        }
    }
}

