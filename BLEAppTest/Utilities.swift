//
//  Utilities.swift
//  BLEAppTest
//
//  Created by JSenen on 26/11/24.
//

import CoreBluetooth

func characteristicPropertiesDescription(_ properties: CBCharacteristicProperties) -> String {
    var descriptions: [String] = []
    if properties.contains(.read) { descriptions.append("Leer") }
    if properties.contains(.write) { descriptions.append("Escribir") }
    if properties.contains(.notify) { descriptions.append("Notificar") }
    if properties.contains(.indicate) { descriptions.append("Indicar") }
    return descriptions.joined(separator: ", ")
}
