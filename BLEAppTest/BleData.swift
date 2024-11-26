//
//  BleData.swift
//  BLEAppTest
//
//  Created by JSenen on 25/11/24.
//

import SwiftUI
import Foundation
import CoreBluetooth

struct BleData: Hashable, Identifiable {
    var id: Int
    var mac: String
    var name: String
    var imageName: String // Este campo debe estar presente en la inicialización
    var peripheral: CBPeripheral // Referencia al dispositivo Bluetooth
    var rssi: Int // Potencia de señal
    var manufacturerData: Data? // Datos del fabricante
    var serviceUUIDs: [CBUUID] // UUIDs de servicios
    
    var image: Image {
            if name.contains("Henkel_SmartDrawer") {
                return Image("logohenkel") // Muestra la imagen logohenkel
            } else {
                return Image(imageName) // Muestra la imagen por defecto
            }
        }
}
