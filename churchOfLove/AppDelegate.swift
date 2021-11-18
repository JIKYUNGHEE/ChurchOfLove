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
        
        let firstLaunch = FirstLaunch()
        
        if !firstLaunch.isFirstLaunch {
            Thread.sleep(forTimeInterval: 2.0)
        }

        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    // MARK: UISceneSession Lifecycle
    
    @available(iOS 13.0, *)
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    @available(iOS 13.0, *)
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    //-MARK: Push 응답 왔을 때 동작
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .badge, .sound]) //foreground 상태에서도 알림 옴
    }
    
    //-MARK: Push 알림 눌렀을 때 동작
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                    didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        let pushUrl = userInfo["URL_TO_MOVE"] as? String
        print("📕", (pushUrl ?? "링크 없음") as! String)
        
        if pushUrl != nil {
            print("📗", pushUrl)
            if UIApplication.shared.applicationState == .active {
                print("📗", "clicked foreground")
                let vc = UIApplication.shared.windows.first!.rootViewController as! ViewController
                vc.loadWebPage(pushUrl!)
            } else {
                print("📗", "clicked background")
                //UserDefaults에 URL 정보를 저장
                //PUSH_URL 이름의 키로 userInfo 안 link 데이터를 저장
                let userDefault = UserDefaults.standard
                userDefault.set(pushUrl, forKey: "PUSH_URL")
                userDefault.synchronize()
            }
        } else {
            print("📕", "App delegate push, no link")
        }
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
