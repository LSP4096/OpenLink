//
//  ShuntView.swift
//  OpenLink
//
//  Created by eleven on 2026/2/6.
//

import SwiftUI

struct ShuntView: View {
    var body: some View {
        ZStack {
            Color(hex: "#1C2F2C").ignoresSafeArea()
            VStack {
                Text("应用分流")
                    .foregroundColor(.white)
            }
        }
        .navigationBarTitle("应用分流", displayMode: .inline)
    }
}

#Preview {
    ShuntView()
}
