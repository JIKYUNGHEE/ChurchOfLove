//
//  WKWebViewConfiguration.swift
//  churchOfLove
//
//  Created by KYUNGHEE JI on 2021/10/04.
//

import WebKit
import KeychainAccess

extension WKWebViewConfiguration {
    static func includeCookie(cookies: [HTTPCookie], completion: @escaping (WKWebViewConfiguration?) -> Void) {
           let config = WKWebViewConfiguration()
           let dataStore = WKWebsiteDataStore.nonPersistent()

           DispatchQueue.main.async {
               let waitGroup = DispatchGroup()

               for cookie in cookies {
                   waitGroup.enter()
                   dataStore.httpCookieStore.setCookie(cookie) {
                       waitGroup.leave()
                   }
               }

               waitGroup.notify(queue: DispatchQueue.main) {
                   config.websiteDataStore = dataStore
                   completion(config)
               }
           }
       }
    
    func prepareWebConfiguration(completion: @escaping (WKWebViewConfiguration?) -> Void) {
            guard let authCookie = HTTPCookie(properties: [
                .domain: "http://13.125.252.119:8080", //ServiceConfiguration.webBaseDomain,
                .path: "/",
                .name: "CID_AUT", //authTokenCookieName, // "CID_AUT"
                .value: UIDevice.current.identifierForVendor!.uuidString, //KeychainService.shared.getUserAccessToken(),
                .secure: "TRUE",
            ]) else {
                return
            }

            guard let uuidCookie = HTTPCookie(properties: [
                .domain: "http://13.125.252.119:8080", //ServiceConfiguration.webBaseDomain,
                .path: "/",
                .name: "CID_AUT", //uuidCookieName,  // "CID_AUT"
                .value: UIDevice.current.identifierForVendor!.uuidString, //KeychainService.shared.getUUID(),
                .secure: "TRUE",
            ]) else {
                return
            }

            WKWebViewConfiguration.includeCookie(cookies: [authCookie, uuidCookie]) {
                completion($0)
            }
        }
}
