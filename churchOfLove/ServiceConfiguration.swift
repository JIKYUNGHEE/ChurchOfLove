//
//  ServiceConfiguration.swift
//  churchOfLove
//
//  Created by KYUNGHEE JI on 2021/10/04.
//

import Foundation

class ServiceConfiguration {
    enum DeployType: String {
        case debug
        case alpha
        case beta
        case release
    }
    
    private static let configKey = "DeployPhase"
    
    static func getDeployPhase() -> DeployType {
        let configValue = Bundle.main.object(forInfoDictionaryKey: configKey) as! String
        guard let phase = DeployType(rawValue: configValue) else {
            
            print("Something wrong in project configurations fot Deployment Phase! Check User Defined Settings.")
            return DeployType.release
        }
        return phase
    }
    
    public static func serviceBaseURL() -> URL {
        switch getDeployPhase() {
        case .debug:
            return URL(string: "http://13.125.252.119:8080/")!
        case .beta:
            return URL(string: "http://13.125.252.119:8080/")!
        case .alpha:
            return URL(string: "http://13.125.252.119:8080/")!
        case .release:
            return URL(string: "http://13.125.252.119:8080/")!
        }
    }
}
