//
//  BleToothManager.swift
//  BLEAppTest
//
//  Created by JSenen on 25/11/24.
//

import Foundation
import CoreBluetooth

class BluetoothManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    @Published var devices: [BleData] = []
    private var discoveredDeviceMACs: Set<String> = [] // MACs únicos detectados
    
    private var centralManager: CBCentralManager!
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            centralManager.scanForPeripherals(withServices: nil, options: nil)
        } else {
            print("Bluetooth no está disponible o no está activado.")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        guard let name = peripheral.name else { return }
        let mac = peripheral.identifier.uuidString
        
        // Evitar duplicados comprobando si el MAC ya está en el Set
        if !discoveredDeviceMACs.contains(mac) {
            discoveredDeviceMACs.insert(mac) // Añadir al Set de MACs únicos
            let newDevice = BleData(id: devices.count + 1, mac: mac, name: name, imageName: "Ble")
            DispatchQueue.main.async {
                self.devices.append(newDevice)
            }
        }
    }
    
    func restartScan() {
        centralManager.stopScan()
        devices.removeAll()
        discoveredDeviceMACs.removeAll() // Limpia el Set de MACs únicos
        centralManager.scanForPeripherals(withServices: nil, options: nil)
    }
}
