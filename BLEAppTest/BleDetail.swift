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
    @State private var selectedCharacteristic: CBCharacteristic?
    @State private var isShowingCharacteristicDetail = false

    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                CircleView(image: device.image)
                    .padding(.top, 40)

                VStack(spacing: 10) {
                    Text(device.name)
                        .font(.title)
                        .fontWeight(.bold)

                    Text("MAC: \(device.mac)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                VStack(spacing: 15) {
                    Text("Estado: \(bluetoothManager.connectionStatus)")
                        .foregroundColor(.blue)
                        .font(.headline)

                    if let firmwareVersion = bluetoothManager.firmwareVersion {
                        Text("Versión de Firmware: \(firmwareVersion)")
                            .font(.subheadline)
                            .foregroundColor(.purple)
                    }
                }

                VStack(spacing: 20) {
                    Button(action: {
                        bluetoothManager.connectToDevice(device.peripheral)
                    }) {
                        Text(bluetoothManager.isConnecting ? "Conectando..." : "Conectar")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(bluetoothManager.isConnecting ? Color.gray : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .disabled(bluetoothManager.isConnecting || bluetoothManager.connectionStatus == "Conectado, buscando servicios...")

                    Button(action: {
                        showingFilePicker = true
                    }) {
                        Text("Seleccionar archivo para OTA")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
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
                }

                if bluetoothManager.connectionStatus.contains("OTA") {
                    ProgressView(value: bluetoothManager.progress, total: 100)
                        .padding()
                        .progressViewStyle(LinearProgressViewStyle())
                }

                if !bluetoothManager.discoveredCharacteristics.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Características Descubiertas")
                            .font(.headline)
                            .padding(.bottom, 5)

                        ForEach(bluetoothManager.discoveredCharacteristics, id: \ .uuid) { characteristic in
                            VStack(alignment: .leading, spacing: 5) {
                                Button(action: {
                                    if characteristic.properties.contains(.read) {
                                        selectedCharacteristic = characteristic
                                        isShowingCharacteristicDetail = true
                                    }
                                }) {
                                    VStack(alignment: .leading) {
                                        Text("Característica: \(characteristic.uuid.uuidString)")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(characteristic.properties.contains(.read) ? .blue : .primary)

                                        Text("Propiedades: \(describeCharacteristicProperties(characteristic.properties))")
                                            .font(.footnote)
                                            .foregroundColor(.secondary)

                                        if let value = characteristic.value, !value.isEmpty {
                                            Text("Valor: \(value.hexEncodedString())")
                                                .font(.footnote)
                                                .foregroundColor(.black)
                                        }
                                    }
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                    }
                    .padding()
                }
            }
            .padding()
        }
        .navigationTitle("Detalles BLE")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            bluetoothManager.resetConnectionState()
        }
        .sheet(isPresented: $isShowingCharacteristicDetail) {
            if let characteristic = selectedCharacteristic {
                CharacteristicDetailView(characteristic: characteristic)
            }
        }
    }
}

struct CharacteristicDetailView: View {
    let characteristic: CBCharacteristic

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Característica: \(characteristic.uuid.uuidString)")
                .font(.title)
                .fontWeight(.bold)

            Text("Propiedades: \(describeCharacteristicProperties(characteristic.properties))")
                .font(.headline)
                .foregroundColor(.secondary)

            if let value = characteristic.value, !value.isEmpty {
                Text("Valor: \(value.hexEncodedString())")
                    .font(.body)
                    .foregroundColor(.black)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Detalle de Característica")
        .navigationBarTitleDisplayMode(.inline)
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
