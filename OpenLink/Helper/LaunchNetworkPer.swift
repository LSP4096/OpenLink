//
//  LaunchNetworkPer.swift
//  OpenLink
//
//  Created by eleven on 2026/2/6.
//

class LaunchNetworkPer {
    
    func requestData() async {
        let isImieLogin = await NetworkService.shared.requestImieLogin()
        if !isImieLogin { return }
        
        
    }
}
