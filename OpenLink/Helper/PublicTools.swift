//
//  PublicTools.swift
//  OpenLink
//
//  Created by eleven on 2026/2/6.
//

import Foundation
import SwiftUI

// MARK: - 调试工具

func olog<T>(
   _ message: T,
   file: String = #file,
   function: String = #function,
   line: Int = #line
) {

   #if DEBUG
       let fileName = (file as NSString).lastPathComponent
       print("👉 [\(fileName):\(line)] | \(function) | \(message)")
   #endif
}
