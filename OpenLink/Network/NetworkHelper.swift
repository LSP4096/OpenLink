//
//  NetworkHelper.swift
//  OpenLink
//
//  Created by eleven on 2026/2/6.
//

import Alamofire
import Foundation
import SwiftyJSON
import UIKit

class NetworkHelper: NSObject {
    static let shared = NetworkHelper()
    private var session: Session

    override init() {
        let config = URLSessionConfiguration.af.default
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 20
        let manager = ServerTrustManager(
            allHostsMustBeEvaluated: false,
            evaluators: ["aiAcceleration": PinnedCertificatesTrustEvaluator()]
        )
        session = Session(configuration: config, serverTrustManager: manager)
    }
    // MARK: - Model Request
    func requestModel<T: Decodable>(
        _ url: String,
        method: HTTPMethod = .get,
        parameters: Parameters? = nil,
        timeoutInterval: TimeInterval? = nil
    ) async throws -> T {
        let json = try await request(url, method: method, parameters: parameters, timeoutInterval: timeoutInterval)
        return try handleModelDecode(json)
    }


    // MARK: - Standard Request
    func request(
        _ url: String,
        method: HTTPMethod = .get,
        parameters: Parameters? = nil,
        timeoutInterval: TimeInterval? = nil
    ) async throws -> JSON {
        let encoder: ParameterEncoding = (method == .get) ? URLEncoding.default : JSONEncoding.default
        let finalUrl = url.contains("https://") ? url : baseDomain + url
        
        let headers = commonHeaders()

        let response = await session.request(
            finalUrl,
            method: method,
            parameters: parameters,
            encoding: encoder,
            headers: headers,
            requestModifier: { $0.timeoutInterval = timeoutInterval ?? $0.timeoutInterval }
        )
        .validate(statusCode: 200..<300)
        .serializingData()
        .response

        switch response.result {
        case .success(let data):
            guard let responseStr = String(data: data, encoding: .utf8) else {
                throw NetworkError.decodingError
            }
            return try handleResponse(responseStr, url: url)

        case .failure(let error):
            throw NetworkError.requestFailed(error.localizedDescription)
        }
    }


    // MARK: - Secure Request
    func secureRequest(
        _ url: String,
        method: HTTPMethod = .get,
        parameters: Parameters? = nil,
        timeoutInterval: TimeInterval? = nil
    ) async throws -> JSON {
        // 1. Prepare payload
        let methodStr = method.rawValue.uppercased()
        var params: [String: AnyCodable] = [:]
        
        if let p = parameters {
          for (k, v) in p {
            params[k] = AnyCodable(v)
          }
        }
        
        let rewritePayload = RewriteParam(
          method: methodStr,
          url: url,
          param: params.isEmpty ? nil : params
        )

        guard let jsonData = try? JSONEncoder().encode(rewritePayload),
              let jsonStr = String(data: jsonData, encoding: .utf8) else {
            throw NetworkError.requestFailed("Failed to encode payload")
        }

        // 2. Encrypt
        let unix = SecureTunnel.getUtcMinuteString()
        let rawPath = SecureTunnel.generatePath(unixWithNoMillis: unix)
        let confusedPath = SecureTunnel.confusePath(path: rawPath)
        
        guard let encryptedBody = SecureTunnel.encrypt(text: jsonStr, unix: unix) else {
            throw NetworkError.requestFailed("Failed to encrypt payload")
        }

        // 3. Construct Tunnel Request
        let finalUrl = baseDomain + confusedPath
        
        var headers = commonHeaders()
        headers.update(name: "Content-Type", value: "text/plain")

        olog("\n----- 🔒 [Secure Request Start] -----")
        olog("Target: \(methodStr) \(url)")
        olog("Tunnel URL: \(finalUrl)")
        olog("Encrypted Body Length: \(encryptedBody.count)")
        
        let response = await session.request(
            finalUrl,
            method: .post,
            parameters: nil,
            headers: headers,
            requestModifier: { $0.timeoutInterval = timeoutInterval ?? $0.timeoutInterval; $0.httpBody = encryptedBody.data(using: .utf8) }
        )
        .validate(statusCode: 200..<300)
        .serializingData()
        .response
        
        olog("\n----- 🔓 [Secure Response Received] -----")
        olog("Status Code: \(response.response?.statusCode ?? -1)")

        switch response.result {
        case .success(let data):
            guard let responseStr = String(data: data, encoding: .utf8) else {
                throw NetworkError.decodingError
            }
            
            if let (plainText, _) = SecureTunnel.tryDecryptResponse(responseStr, currentUnix: unix) {
                return try handleResponse(plainText, url: url)
            } else {
                 olog("Decryption Failed.")
                 if SecureTunnel.timeOffset == 0, let newOffset = SecureTunnel.probeServerTimeOffset(encryptedResponse: responseStr) {
                     olog("🔄 [SecureTunnel] Apply new time offset (\(newOffset)s) and retry...")
                     SecureTunnel.timeOffset = newOffset
                     return try await secureRequest(url, method: method, parameters: parameters, timeoutInterval: timeoutInterval)
                 }
                 throw NetworkError.requestFailed("Failed to decrypt secure response")
            }
            
        case .failure(let error):
            throw NetworkError.requestFailed(error.localizedDescription)
        }
    }

    // MARK: - Centralized Response Handling
    private func handleResponse(_ text: String, url: String) throws -> JSON {
        let json = JSON(parseJSON: text)
        olog("接口返回的数据 = \(json)\nurl = \(url)")
        
        let code = json["code"].intValue
        
        // Handle common codes (similar to handleResponseError)
        if code == 104 {
//            NotificationCenter.default.post(name: .loginExpired, object: url)
            throw NetworkError.unauthorized
        }
        
        if code != 0 && code != 200 { // Assuming 0 or 200 is success
            let msg = json["msg"].string ?? json["message"].stringValue
            throw NetworkError.serverError(code: code, message: msg)
        }
        
        return json
    }

    private func handleModelDecode<T: Decodable>(_ json: JSON) throws -> T {
        guard let data = try? json["data"].rawData() else {
            throw NetworkError.decodingError
        }
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            olog("❌ Model Decoding Error: \(error)")
            throw NetworkError.decodingError
        }
    }

    // MARK: - Helper
    private func commonHeaders() -> HTTPHeaders {
        let device = UIDevice.current
        let systemVersion = device.systemVersion.replacingOccurrences(of: ".", with: "_")
        let model = device.model
        // S7VPN format: Mozilla/5.0 (\(model); CPU iPhone OS \(systemVersion))
        let userAgent = "Mozilla/5.0 (\(model); CPU iPhone OS \(systemVersion))"

        var headers: HTTPHeaders = [
            "User-Agent": userAgent,
//            "appid": NETWORK_APP_ID,
//            "version": AppConstants.appVersion,
//            "language": LanguageManager.shared.appLan,
//            "imie": DeviceManager.shared.getDeviceID()
        ]
        
        if let token = UserDefaults.standard.string(forKey: UserDefaultsKeys.imieToken) {
            headers["X-User-Token"] = token
        }
        
        return headers
    }
}
