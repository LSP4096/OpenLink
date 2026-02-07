//
//  Triangle.swift
//  OpenLink
//
//  Created by eleven on 2026/2/7.
//

import SwiftUI

struct Triangle: View {
    enum Direction {
        case up, down, left, right
    }
    
    var color: Color = .white
    var width: CGFloat = 8
    var height: CGFloat = 5
    var direction: Direction = .down
    
    var body: some View {
        Path { path in
            switch direction {
            case .up:
                path.move(to: CGPoint(x: width/2, y: 0))          // 顶中
                path.addLine(to: CGPoint(x: width, y: height))    // 右下
                path.addLine(to: CGPoint(x: 0, y: height))        // 左下
            case .down:
                path.move(to: CGPoint(x: 0, y: 0))                // 左上
                path.addLine(to: CGPoint(x: width, y: 0))         // 右上
                path.addLine(to: CGPoint(x: width/2, y: height))  // 底中
            case .left:
                path.move(to: CGPoint(x: width, y: 0))            // 右上
                path.addLine(to: CGPoint(x: width, y: height))    // 右下
                path.addLine(to: CGPoint(x: 0, y: height/2))      // 左中
            case .right:
                path.move(to: CGPoint(x: 0, y: 0))                // 左上
                path.addLine(to: CGPoint(x: 0, y: height))        // 左下
                path.addLine(to: CGPoint(x: width, y: height/2))  // 右中
            }
            path.closeSubpath()
        }
        .fill(color)
        .frame(width: width, height: height)
    }
}

#Preview {
    Triangle(color: .red, width: 20, height: 12, direction: .up)
    Triangle(color: .blue, width: 20, height: 12, direction: .down)
    Triangle(color: .green, width: 15, height: 20, direction: .left)
    Triangle(color: .orange, width: 15, height: 20, direction: .right)
}
