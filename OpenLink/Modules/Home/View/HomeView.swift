//
//  HomeView.swift
//  OpenLink
//
//  Created by eleven on 2026/2/6.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @ObservedObject var connectionManager = VPNConnectManager.shared
    @State private var rotation: Double = 0
    @State private var isProfessional: Bool = false

    var body: some View {
        ZStack {
            // Base Background
            Color(hex: "#1C2F2C").ignoresSafeArea()

            VStack(spacing: 0) {
                // Top Custom Header
                ZStack(alignment: .top) {
                    // Top Background Circuitry
                    Image("topbg")
                        .resizable()
                        .frame(height: 200)
                        .ignoresSafeArea()

                    VStack(spacing: 20) {
                        // Navigation Bar
                        HStack {
                            Button(action: { /* Share */  }) {
                                Image("home_share")
                                    .resizable()
                                    .frame(width: 34, height: 34)
                            }

                            Spacer()

                            Button(action: { /* VIP */  }) {
                                Image("home_vip")
                                    .resizable()
                                    .frame(width: 34, height: 34)
                            }
                        }
                        .padding(.horizontal, 16)
                        //                        .padding(.top, 19)

                        // Status Section
                        HStack(spacing: 12) {
                            Image(viewModel.statusIcon)
                                .rotationEffect(.degrees(viewModel.vpnManager.tunnelState == .connecting ? rotation : 0))

                            Text(viewModel.statusTitle)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(viewModel.statusColor)
                        }
                    }
                    .padding(.horizontal)
                }

                // Connection Area
                ZStack(alignment: .top) {
                    // Layer 0: Background Ring
                    Image("connect_btn_bg")
                        .resizable()
                        .frame(width: 420, height: 420)
                        .zIndex(0)

                    // Layer 1: Time info Panel (Middle)
                    VStack(spacing: 0) {
                        Spacer()
                        Text(viewModel.vpnManager.sessionDuration)
                            .font(.system(size: 40, weight: .bold, design: .monospaced))
                            .foregroundColor(viewModel.vpnManager.tunnelState == .connected ? Color(hex: "#0AD8B4") : .white)
                            .padding(.bottom, 8)

                        HStack(spacing: 4) {
                            Text("试用时长剩余:")
                                .foregroundColor(.white)
                            Text("30")
                                .foregroundColor(Color(hex: "#0AD8B4"))
                            Text("分钟")
                                .foregroundColor(.white)
                        }
                        .font(.system(size: 13))
                        .padding(.bottom, 26)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 214)
                    .background(
                        Image("home_bottom_bg")
                            .resizable()
                            .frame(maxWidth: .infinity)
                            .frame(height: 214)
                            .clipped()
                            .overlay(
                                // 渐变边框
                                RoundedCorner(radius: 30, corners: [.topLeft, .topRight])
                                    .stroke(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.white.opacity(0.3),
                                                Color.clear,
                                            ]),
                                            startPoint: .top,
                                            endPoint: .bottom
                                        ),
                                        lineWidth: 2
                                    )
                            )
                    )
                    .padding(.horizontal, 16)
                    .offset(y: 210)  // Centered relative to the ring height (420/2)
                    .zIndex(1)

                    // Layer 2: Lightning Button (Top)
                    Image(viewModel.connectButtonImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 147, height: 147)
                        .frame(width: 420, height: 420)
                        .zIndex(2)
                        .onTapGesture {
                            Task {
                                await VPNConnectManager.shared.startVPN()
                            }
                        }
                }
                .padding(.top, -50)

                Spacer()

                // Node Selector
                Button(action: {
                    AppRouter.shared.push(.nodeList)
                }) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle().fill(Color.white.opacity(0.1)).frame(width: 32, height: 32)
                            if let node = connectionManager.currentSelectedNode {
                                if node.flag == "auto" {
                                    Image(systemName: "bolt.fill")
                                        .foregroundColor(Color(hex: "#0AD8B4"))
                                } else {
                                    // 使用国旗图标
                                    Image(node.flagImageName)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 20, height: 20)
                                }
                            } else {
                                Image(systemName: "globe.americas.fill")
                                    .foregroundColor(.white)
                            }
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("当前服务器")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.7))
                            Text(connectionManager.currentSelectedNode?.country ?? "未选择节点")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                        }

                        Spacer()

                        Image(systemName: "chevron.down")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                            .padding(.trailing, 4)
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 64)
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 24)
                    .padding(.bottom, 25)
                }

                Spacer()
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}

// Simple Diamond shape for the VIP icon border
struct DiamondShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Shape & View Extensions
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

#Preview {
    HomeView()
}
