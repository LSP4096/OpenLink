//
//  VPNPermissionPOPView.swift
//  OpenLink
//
//  Created by eleven on 2026/2/7.
//

import SwiftUI

struct VPNPermissionPopupView: View {
    @Binding var isShow: Bool
    var onConfirm: (() -> Void)?

    var body: some View {
        ZStack {
            // 半透明背景
            Color.black.opacity(0.8)

            // 主体内容
            VStack {
                // 这里放顶部文字说明
                Text("154".localized())
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 30)

                Text("155".localized())
                    .font(.system(size: 15))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 50)

            }
            .padding(.bottom, 300)

            // ✅ 模拟系统弹窗（居中 + 固定高度）
            VStack(spacing: 0) {
                Text("156".localized())
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity)
                    .background(Color(white: 0.15))

                VStack(alignment: .leading, spacing: 8) {
                    // 中间长条形
                    Rectangle()
                        .fill(Color(.sRGB, white: 0.3, opacity: 1))
                        .frame(width: 180, height: 8)
                        .padding(.top, 5)

                    // 中间长条形
                    Rectangle()
                        .fill(Color(.sRGB, white: 0.3, opacity: 1))
                        .frame(width: 120, height: 8)
                }

                // 下面按钮区域
                HStack(spacing: 0) {
                    Button("157".localized()) {}
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.green)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)

                    Divider().background(Color.gray)

                    Button("158".localized()) {}
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.gray)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }

                .frame(height: 50)
                .padding(.top, 20)
            }
            .frame(width: 280, height: 150)  // ✅ 固定大小
            .background(Color(white: 0.15))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: Color.black.opacity(0.4), radius: 10)
            .position(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY)  // ✅ 居中定位

            VStack {
                HStack {
                    // ✅ 向上的小箭头
                    Triangle(color: .green, width: 10, height: 8, direction: .up)
                    Spacer()
                }
                .frame(width: 140)
                
                Text("159".localized())
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .padding(.top, 12)

                Button(action: {
                    onConfirm?()
                }) {
                    Text("知道了")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(30)
                        .padding(.horizontal, 40)
                        .padding(.top, 10)
                }
            }
            .padding(.top, 320)
        }
        .ignoresSafeArea()

    }
}

#Preview {
    VPNPermissionPopupView(isShow: .constant(true)) {}
}
