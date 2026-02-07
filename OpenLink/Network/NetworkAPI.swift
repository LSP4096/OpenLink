//
//  NetworkAPI.swift
//  OpenLink
//
//  Created by eleven on 2026/2/6.
//

#if DEBUG
    //    let baseDomain = "https://192.168.2.19"
    let baseDomain = "https://38.180.124.60"
#else
    let baseDomain = "https://tr3bg.wetg65.org"
#endif

var webSocketBaseURL: String {
    let wsUrl =
        baseDomain
        .replacingOccurrences(of: "https://", with: "wss://")
        .replacingOccurrences(of: "http://", with: "ws://")
    return wsUrl
}

let wsPath = "/api/mobile/ws/chat"
let restBase = "/api/mobile/chat"

/// 设备登录
let api_imie_login = "/api/mobile/guest/login"
/// 用户登录
let api_login = "/api/mobile/login"
/// 注册
let api_register = "/api/mobile/register"
/// 获取验证码
let api_captcha = "/api/mobile/captcha"
/// 提交反馈
let api_feedback = "/api/mobile/feedback/create"
/// 上传图片
let api_upload_image = "/api/upload/image"
/// 节点列表
let api_node_list = "/api/mobile/node/list"
/// 退出登录
let api_logout = "/api/mobile/logout"
/// 节点详情
let api_node_detail = "/api/mobile/node/detail"
/// 检查版本
let api_check_version = "/api/mobile/version"
/// 分流配置列表
let api_shunt_list = "/api/mobile/list_by_category"
/// VPN 计数
let api_vpn_count = "/api/mobile/vpn/count"
/// 搜索 App 配置
let api_search_app_config = "/api/mobile/search_app_config"
/// 解绑设备
let api_unbind = "/api/mobile/unbind"
/// 注销账号
let api_signout = "/api/mobile/signout"
/// 公告
let api_announcement = "/api/mobile/announcement"
