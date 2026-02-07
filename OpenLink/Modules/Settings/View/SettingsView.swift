//
//  SettingsView.swift
//  OpenLink
//
//  Created by eleven on 2026/2/6.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        ZStack {
            Color(hex: "#1C2F2C").ignoresSafeArea()
            VStack {
                Text("设置")
                    .foregroundColor(.white)
            }
        }
        .navigationBarTitle("设置", displayMode: .inline)
    }
}

#Preview {
    SettingsView()
}
