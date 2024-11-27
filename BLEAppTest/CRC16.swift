//
//  CRC16.swift
//  BLEAppTest
//
//  Created by JSenen on 26/11/24.
//

import Foundation

class EspCRC16 {
    static func crc(_ data: [UInt8]) -> Int {
        return crc(data, offset: 0, length: data.count)
    }

    static func crc(_ data: [UInt8], offset: Int, length: Int) -> Int {
        var crc16: UInt16 = 0

        for cur in offset..<length {
            let byte = data[cur]
            crc16 ^= UInt16(byte) << 8
            for _ in 0..<8 {
                if (crc16 & 0x8000) != 0 {
                    crc16 = (crc16 << 1) ^ 0x1021
                } else {
                    crc16 = crc16 << 1
                }
            }
        }

        return Int(crc16 & 0xffff)
    }
}

