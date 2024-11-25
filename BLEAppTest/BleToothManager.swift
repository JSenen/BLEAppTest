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
    
    private var centralManager: CBCentralManager!
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            // Inicia la exploración de dispositivos
            centralManager.scanForPeripherals(withServices: nil, options: nil)
        } else {
            print("Bluetooth no está disponible o no está activado.")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        guard let name = peripheral.name else { return }
        let mac = peripheral.identifier.uuidString
        
        // Verificar si el dispositivo ya está en la lista
            if !devices.contains(where: { $0.mac == mac }) {
                let newDevice = BleData(id: devices.count + 1, mac: mac, name: name, imageName: "Ble")
                DispatchQueue.main.async {
                    self.devices.append(newDevice)
                }
            }
    }
    
    func restartScan() {
        centralManager.stopScan()
        devices.removeAll() // Limpiar la lista de dispositivos
        centralManager.scanForPeripherals(withServices: nil, options: nil)
    }
}
