//
//  BleDetail.swift
//  BLEAppTest
//
//  Created by JSenen on 25/11/24.
//

import SwiftUI

struct BleDetail: View {
    let device: BleData

    var body: some View {
        VStack(spacing: 20) {
            CircleView(image: device.image) // Vista de imagen circular
                .padding(.top, 40)
            
            Text(device.name)
                .font(.largeTitle)
                .bold()
            
            Text("MAC: \(device.mac)")
                .font(.title3)
                .foregroundColor(.gray)
            
            Spacer()
        }
        .padding()
        .navigationTitle("Detalles BLE")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    BleDetail(device: BleData(id: 1, mac: "00:11:22:33:44:55", name: "Dispositivo BLE", imageName: "Ble"))
}

