//
//  BleToothManager.swift
//  BLEAppTest
//
//  Created by JSenen on 25/11/24.
//

import Foundation
import CoreBluetooth

class BluetoothManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    static let shared = BluetoothManager() // Singleton compartido
    
    @Published var devices: [BleData] = []
    @Published var isConnecting: Bool = false
    private var discoveredDeviceMACs: Set<String> = []
    private var centralManager: CBCentralManager!
    @Published var connectedPeripheral: CBPeripheral?
    @Published var connectionStatus: String = "Desconectado"

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    
    // Estado del Bluetooth
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            centralManager.scanForPeripherals(withServices: nil, options: nil)
        } else {
            print("Bluetooth no está disponible o no está activado.")
        }
    }

    
    // Descubrimiento de dispositivos
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        guard let name = peripheral.name else { return }
        let mac = peripheral.identifier.uuidString
        
        if !discoveredDeviceMACs.contains(mac) {
            discoveredDeviceMACs.insert(mac)
            let newDevice = BleData(id: devices.count + 1, mac: mac, name: name, imageName: "Ble", peripheral: peripheral)
            DispatchQueue.main.async {
                self.devices.append(newDevice)
            }
        }
    }
    
    // Conectar a un dispositivo
    func connectToDevice(_ peripheral: CBPeripheral) {
        guard centralManager.state == .poweredOn else {
            print("Central Manager no está listo.")
            return
        }
        
        isConnecting = true
        connectionStatus = "Intentando conectar..."
        connectedPeripheral = peripheral
        peripheral.delegate = self
        centralManager.connect(peripheral, options: nil)
    }



    
    // Evento de conexión exitosa
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Conectado a \(peripheral.name ?? "dispositivo desconocido")")
        
        connectedPeripheral = peripheral
        peripheral.delegate = self // Configura el delegado
        peripheral.discoverServices(nil) // Descubre todos los servicios
        
        DispatchQueue.main.async {
            self.connectionStatus = "Conectado, buscando servicios..."
            self.isConnecting = false
        }
    }

    // Evento de desconexión
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Desconectado de \(peripheral.name ?? "dispositivo desconocido")")
        DispatchQueue.main.async {
            self.connectionStatus = "Desconectado"
            self.isConnecting = false
        }
    }

    
    // Fallo en la conexión
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Error al conectar con \(peripheral.name ?? "dispositivo desconocido"): \(error?.localizedDescription ?? "Desconocido")")
        DispatchQueue.main.async {
            self.connectionStatus = "Error al conectar"
            self.isConnecting = false
        }
    }

    
    func restartScan() {
        centralManager.stopScan()
        devices.removeAll()
        discoveredDeviceMACs.removeAll()
        centralManager.scanForPeripherals(withServices: nil, options: nil)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("Error al descubrir servicios: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.connectionStatus = "Error al descubrir servicios"
            }
            return
        }
        
        guard let services = peripheral.services, !services.isEmpty else {
            print("No se encontraron servicios.")
            DispatchQueue.main.async {
                self.connectionStatus = "Conectado pero sin servicios"
            }
            return
        }
        
        for service in services {
            print("Servicio encontrado: \(service.uuid)")
            peripheral.discoverCharacteristics(nil, for: service) // Descubre características
        }
    }



}
