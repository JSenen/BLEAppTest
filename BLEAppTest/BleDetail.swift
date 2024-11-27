//
//  BleDetail.swift
//  BLEAppTest
//
//  Created by JSenen on 25/11/24.
//

import SwiftUI
import CoreBluetooth
import UniformTypeIdentifiers


struct BleDetail: View {
    let device: BleData
    @ObservedObject var bluetoothManager: BluetoothManager
    @State private var showingFilePicker = false
    @State private var otaFileData: Data?

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

            Text("Estado: \(bluetoothManager.connectionStatus)")
                .foregroundColor(.blue)
                .font(.headline)
            
            // Mostrar la versión del firmware si está disponible
                        if let firmwareVersion = bluetoothManager.firmwareVersion {
                            Text("Versión de Firmware: \(firmwareVersion)")
                                .font(.headline)
                                .foregroundColor(.purple)
                        }

            // Botón para conectar el dispositivo
            Button(action: {
                bluetoothManager.connectToDevice(device.peripheral)
            }) {
                Text(bluetoothManager.isConnecting ? "Conectando..." : "Conectar")
                    .padding()
                    .background(bluetoothManager.isConnecting ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(bluetoothManager.isConnecting || bluetoothManager.connectionStatus == "Conectado, buscando servicios...")

            // Botón para seleccionar el archivo .bin para la OTA
            Button(action: {
                showingFilePicker = true
            }) {
                Text("Seleccionar archivo para OTA")
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(bluetoothManager.connectedPeripheral == nil || bluetoothManager.connectionStatus != "Características descubiertas")
            .fileImporter(isPresented: $showingFilePicker, allowedContentTypes: [UTType.data], allowsMultipleSelection: false) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        if url.startAccessingSecurityScopedResource() {
                            do {
                                otaFileData = try Data(contentsOf: url)
                                if let otaFile = otaFileData {
                                    print("Archivo OTA seleccionado: \(url.lastPathComponent), tamaño: \(otaFile.count) bytes")
                                    bluetoothManager.startOTA(with: otaFile)
                                }
                            } catch {
                                print("Error al cargar el archivo: \(error.localizedDescription)")
                            }
                            url.stopAccessingSecurityScopedResource()
                        } else {
                            print("No se pudo acceder al recurso de manera segura.")
                        }
                    }
                case .failure(let error):
                    print("Error al seleccionar el archivo: \(error.localizedDescription)")
                }
            }

            // Barra de progreso para la OTA
            if bluetoothManager.connectionStatus.contains("OTA") {
                ProgressView(value: bluetoothManager.progress, total: 100)
                    .padding()
                    .progressViewStyle(LinearProgressViewStyle())
            }

            // Lista de características descubiertas
            if !bluetoothManager.discoveredCharacteristics.isEmpty {
                List(bluetoothManager.discoveredCharacteristics, id: \.uuid) { characteristic in
                    VStack(alignment: .leading) {
                        Text("Característica: \(characteristic.uuid.uuidString)")
                            .font(.headline)
                        Text("Propiedades: \(describeCharacteristicProperties(characteristic.properties))")
                            .font(.subheadline)
                            .foregroundColor(.gray)

                        if let value = characteristic.value, !value.isEmpty {
                            // Mostrar el valor si está disponible
                            Text("Valor: \(value.hexEncodedString())")
                                .font(.body)
                                .foregroundColor(.black)
                        }
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

// Extensión para convertir Data a string hexadecimal legible
extension Data {
    func hexEncodedString() -> String {
        return map { String(format: "%02hhx", $0) }.joined()
    }
}

// Helper para describir las propiedades de las características
func describeCharacteristicProperties(_ properties: CBCharacteristicProperties) -> String {
    var props = [String]()
    if properties.contains(.broadcast) {
        props.append("Broadcast")
    }
    if properties.contains(.read) {
        props.append("Read")
    }
    if properties.contains(.writeWithoutResponse) {
        props.append("Write Without Response")
    }
    if properties.contains(.write) {
        props.append("Write")
    }
    if properties.contains(.notify) {
        props.append("Notify")
    }
    if properties.contains(.indicate) {
        props.append("Indicate")
    }
    if properties.contains(.authenticatedSignedWrites) {
        props.append("Authenticated Signed Writes")
    }
    if properties.contains(.extendedProperties) {
        props.append("Extended Properties")
    }
    return props.joined(separator: ", ")
}
