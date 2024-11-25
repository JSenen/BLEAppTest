//
//  BleData.swift
//  BLEAppTest
//
//  Created by JSenen on 25/11/24.
//

import SwiftUI
import Foundation

struct BleData: Hashable, Codable, Identifiable {
    var id: Int
    var mac: String
    var name: String
    var imageName: String // Este campo debe estar presente en la inicialización
    
    var image: Image {
            if name.contains("Henkel_SmartDrawer") {
                return Image("logohenkel") // Muestra la imagen logohenkel
            } else {
                return Image(imageName) // Muestra la imagen por defecto
            }
        }
}
