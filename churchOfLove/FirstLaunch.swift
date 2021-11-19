//
//  FirstLaunch.swift
//  churchOfLove
//
//  Created by KYUNGHEE JI on 2021/10/04.
//

import Foundation

final class FirstLaunch {
    static let shared = FirstLaunch()
    
    let userDefaults: UserDefaults = .standard
    let wasLaunchedBefore: Bool
    
    var isFirstLaunch: Bool { return !wasLaunchedBefore }
    
    private init() {
        let key = "com.FirstLaunch.WasLaunchedBefore"
        let wasLaunchedBefore = userDefaults.bool(forKey: key)
        self.wasLaunchedBefore = wasLaunchedBefore
        if !wasLaunchedBefore {
            userDefaults.set(true, forKey: key)
        }
    }
}
