//
//  AppDelegate.swift
//  churchOfLove
//
//  Created by 지경희 on 2021/08/10.
//

import UIKit
import Firebase
import FirebaseCore
import FirebaseMessaging
import UserNotifications

//특정 URL 로 이동
//https://sosoingkr.tistory.com/12

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions, completionHandler: {_, _ in })
        application.registerForRemoteNotifications()
        

        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    // MARK: UISceneSession Lifecycle
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // * Push에서 전달받은 UserInfo 데이터를 변수에 담습니다.
        let userInfo = notification.request.content.userInfo
        print("\(userInfo)")
        print("\(userInfo["URL_TO_MOVE"])")
        // * UserDefaults에 URL 정보를 저장합니다.
        //    - PUSH_URL 이름의 키로 userInfo 안 link 데이터를 저장합니다.
        let userDefault = UserDefaults.standard
        userDefault.set(userInfo["URL_TO_MOVE"] ?? "", forKey: "PUSH_URL")
        userDefault.synchronize()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                    didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        // * Push에서 전달받은 UserInfo 데이터를 변수에 담습니다.
        let userInfo = response.notification.request.content.userInfo

        // * UserDefaults에 URL 정보를 저장합니다.
        //    - PUSH_URL 이름의 키로 userInfo 안 link 데이터를 저장합니다.
        let userDefault = UserDefaults.standard
        userDefault.set(userInfo["link"] ?? "", forKey: "PUSH_URL")
        userDefault.synchronize()

        print("\(#function)")
        
        completionHandler()
    }
    
}


extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("Firebase registration token: \(fcmToken ?? "")")
        let dataDict: [String: String] = ["token": fcmToken ?? ""]
        
        let ud: UserDefaults = UserDefaults.standard
        ud.set(fcmToken, forKey: "fcmToken")
        
        NotificationCenter.default.post(name: Notification.Name("FCMToken"), object: nil, userInfo: dataDict)
    }
}

extension AppDelegate {
    func applicationDidBecomeActive(_ application: UIApplication) {
        self.loadCookie()
    }
    func applicationDidEnterBackground(_ application: UIApplication) {
        self.saveCookie()
    }
    
    func saveCookie(){
        let cookieJar: HTTPCookieStorage = HTTPCookieStorage.shared
        let data: NSData = NSKeyedArchiver.archivedData(withRootObject: cookieJar.cookies as Any) as NSData
        let ud: UserDefaults = UserDefaults.standard
        ud.set(data, forKey: "cookie")
    }

    
    func loadCookie(){
        let ud: UserDefaults = UserDefaults.standard
        let data: NSData? = ud.object(forKey: "cookie") as? NSData
        
        if let cookie = data {
            let datas: NSArray? = NSKeyedUnarchiver.unarchiveObject(with: cookie as Data) as? NSArray
            if let cookies = datas {
                for c in cookies as! [HTTPCookie] {
                    HTTPCookieStorage.shared.setCookie(c)
                }
            }
        }
    }
}
