//
//  AdBlockView.swift
//  OpenLink
//
//  Created by eleven on 2026/2/6.
//

import SwiftUI

struct AdBlockView: View {
    var body: some View {
        ZStack {
            Color(hex: "#1C2F2C").ignoresSafeArea()
            VStack {
                Text("广告拦截")
                    .foregroundColor(.white)
            }
        }
        .navigationBarTitle("广告拦截", displayMode: .inline)
    }
}

#Preview {
    AdBlockView()
}
