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
        Image(imageName)
    }
}
