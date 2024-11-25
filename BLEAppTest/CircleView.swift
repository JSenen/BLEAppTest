//
//  CircleView.swift
//  BLEAppTest
//
//  Created by JSenen on 25/11/24.
//

import SwiftUI

struct CircleView: View {
    var image: Image
    
    var body: some View {
        image
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




