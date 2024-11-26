//
//  BleDetail.swift
//  BLEAppTest
//
//  Created by JSenen on 25/11/24.
//

import SwiftUI
import CoreBluetooth

struct BleDetail: View {
    let device: BleData
    @ObservedObject var bluetoothManager: BluetoothManager // Observa el estado del manager

    var body: some View {
        VStack(spacing: 20) {
            CircleView(image: device.image)
                .padding(.top, 40)

            Text(device.name)
                .font(.largeTitle)
                .bold()

            Text("MAC: \(device.mac)")
                .font(.title3)
                .foregroundColor(.gray)

            Text("Estado: \(bluetoothManager.connectionStatus)") // Estado dinámico
                .foregroundColor(.blue)
                .font(.headline)

            Button(action: {
                bluetoothManager.connectToDevice(device.peripheral)
            }) {
                Text(bluetoothManager.isConnecting ? "Conectando..." : "Conectar")
                    .padding()
                    .background(bluetoothManager.isConnecting ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(bluetoothManager.isConnecting)

            // Lista de características descubiertas
            if !bluetoothManager.discoveredCharacteristics.isEmpty {
                List(bluetoothManager.discoveredCharacteristics, id: \.uuid) { characteristic in
                    VStack(alignment: .leading) {
                        Text("Característica: \(characteristic.uuid.uuidString)")
                            .font(.headline)
                        Text("Propiedades: \(characteristicPropertiesDescription(characteristic.properties))")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                .frame(height: 200) // Limitar el tamaño de la lista
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Detalles BLE")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            bluetoothManager.resetConnectionState()
        }
    }
}
