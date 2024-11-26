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
            List(bluetoothManager.devices, id: \.mac) { device in
                NavigationLink(destination: BleDetail(device: device, bluetoothManager: bluetoothManager)) {
                    HStack {
                        CircleView(image: device.image)
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


#Preview {
    ContentView()
        
}

