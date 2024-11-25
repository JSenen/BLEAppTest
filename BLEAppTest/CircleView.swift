//
//  CircleView.swift
//  BLEAppTest
//
//  Created by JSenen on 25/11/24.
//

import SwiftUI

struct CircleView: View {
    var body: some View {
        Image("Ble") // Usa el nombre correcto de tu imagen
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: 50, height: 50)
            .clipShape(Circle())
            .overlay {
                Circle().stroke(.white, lineWidth: 4)
            }
            .shadow(radius: 7)
    }
}

#Preview {
    CircleView()
}

