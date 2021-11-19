import UIKit
import WebKit

class ViewController: UIViewController,WKUIDelegate,WKNavigationDelegate {
    
    @IBOutlet var webViewBackgroundView: UIView!
    
    //MARK: - properties
    var webView: WKWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let websiteDataTypes = NSSet(array: [WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache])
        let date = Date(timeIntervalSince1970: 0)
        WKWebsiteDataStore.default().removeData(ofTypes: websiteDataTypes as! Set<String>, modifiedSince: date, completionHandler:{ })

        initializeWebView()
        
        let firstLaunch = FirstLaunch.shared
        var loadURL = ""
        if firstLaunch.isFirstLaunch {
            loadURL = Constants.BASE_URL.GUIDE_DOMAIN_URL
        } else {
            loadURL = Constants.BASE_URL.USER_DOMAIN_URL
        }
        
        loadWebPage(loadURL)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        willBecomeActive()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        wllBecomeActive_Del()
    }
    
    override func didReceiveMemoryWarning() { super.didReceiveMemoryWarning() } //모달창 닫힐때 앱 종료현상 방지.
    
    //alert 처리
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void){
        let alertController = UIAlertController(title: "", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "확인", style: .default, handler: { (action) in completionHandler() }))
        self.present(alertController, animated: true, completion: nil) }
    
    //confirm 처리
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alertController = UIAlertController(title: "", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "취소", style: .default, handler: { (action) in completionHandler(false) }))
        alertController.addAction(UIAlertAction(title: "확인", style: .default, handler: { (action) in completionHandler(true) }))
        self.present(alertController, animated: true, completion: nil) }
    
    // href="_blank" 처리
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil { webView.load(navigationAction.request) }
        return nil }
    
    func initializeWebView() {
        // Bridge 등록
        let contentController = WKUserContentController()
        contentController.add(self, name: "callNative")
        contentController.add(self, name: "callNativeRtn")
        
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = contentController
        configuration.preferences.javaScriptEnabled = true //자바스크립트 활성화
        self.webView?.allowsBackForwardNavigationGestures = true  //뒤로가기 제스쳐 허용
        
        self.webView = WKWebView(frame: self.view.frame, configuration: configuration)
        self.webView.uiDelegate = self
        self.webView.scrollView.showsVerticalScrollIndicator = false
        self.webView.scrollView.showsHorizontalScrollIndicator = false
        self.webViewBackgroundView.addSubview(self.webView)
        
        
        if #available(iOS 11.0, *) {
            webView.scrollView.contentInsetAdjustmentBehavior = .never
        } else {
            webView.translatesAutoresizingMaskIntoConstraints = false
            view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[v0]|", options: NSLayoutConstraint.FormatOptions(), metrics: nil, views: ["v0":webView]))
            view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-20-[v0]|", options: NSLayoutConstraint.FormatOptions(), metrics: nil, views: ["v0":webView]))
        }
    }
        
    override func viewSafeAreaInsetsDidChange() {
        if #available(iOS 11.0, *) {
            webView.translatesAutoresizingMaskIntoConstraints = false
            
            view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[v0]|", options: NSLayoutConstraint.FormatOptions(), metrics: nil, views: ["v0":webView]))
            
            view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-(\(self.view.safeAreaInsets.top))-[v0]-(\(self.view.safeAreaInsets.bottom))-|", options: NSLayoutConstraint.FormatOptions(), metrics: nil, views: ["v0":webView]))
        }
    }
    
    func loadWebPage(_ loadURL: String) {
        let url = URL(string: loadURL)
        let request = URLRequest(url: url!)
        
        if self.webView == nil {
            initializeWebView()
        }
        
        self.webView.load(request)
    }

    
    private func willBecomeActive() {
            NotificationCenter.default.addObserver(self,
                                                   selector:#selector(appDidBecomeActive),
                                                   name:UIApplication.didBecomeActiveNotification,
                                                   object:nil);
    }
    
    // MainViewController 화면이 사라지면 등록한 이벤트 Observer를 제거합니다.
    private func wllBecomeActive_Del()    {
        NotificationCenter.default.removeObserver(self,
                                                  name: UIApplication.didBecomeActiveNotification,
                                                  object: nil)
    }
    
    //등록한 이벤트로 이벤트가 수신될 경우, 실행될 함수 입니다.
    @objc public func appDidBecomeActive() {
        // * 푸시 클릭 시 "PUSH_URL"의 데이터로 WebView를 이동 시킵니다.
        let userDefault = UserDefaults.standard
        
        guard let loadUrl = userDefault.object(forKey: "PUSH_URL") as? String else {
            return
        }
        
        let request: URLRequest = URLRequest.init(url: NSURL.init(string: loadUrl)! as URL, cachePolicy: URLRequest.CachePolicy.useProtocolCachePolicy, timeoutInterval: 10)
        self.webView?.load(request)

        // * URL 이동 후 "PUSH_URL" 키의 값을 빈 값으로 초기화 합니다.
        userDefault.removeObject(forKey: "PUSH_URL")
        userDefault.synchronize()
    }
}

extension ViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        switch message.name {
        case "callNative":
            let body = message.body
            print(body)
            
            if let content :[String:String] = message.body as? Dictionary {
                print(content)
                
                if let function = content["FUNC"] {
                    if function == "requestDeviceInfo" {
                        callResponseDeviceInfo()
                    }
                    
                    if function == "shareImage" {
                        shareImage(content)
                    }
                }
            }
            
        case "callNativeRtn":
            let content = message.body
            print(content)
            let alert = UIAlertController(title: nil, message: "callNativeRtn 호출", preferredStyle: .alert)
            let action = UIAlertAction(title: "확인", style: .default, handler: nil)
            alert.addAction(action)
            self.present(alert, animated: true, completion: nil)
            
            //            let dataString = ""
            //            webView.evaluateJavaScript("callWeb('\(dataString)')", completionHandler: nil)

        default:
            break
        }
    }
        
    func callResponseDeviceInfo() {
        do {
            //기기 정보를 json string 으로 만든다.
            var transferData : [String: Any] = [
                "OS_VER": UIDevice.current.systemVersion,
                "APP_VER": currentAppVersion(),
                "MODEL_NM": UIDevice.modelName,
                "ANDROID_ID": UIDevice.current.identifierForVendor!.uuidString,
                "FCM_TOKEN": UserDefaults.standard.string(forKey: "fcmToken")
            ]
            
            let jsonData = try JSONSerialization.data(withJSONObject: transferData, options: [])
            let jsonString = String(data: jsonData, encoding: String.Encoding.ascii)!
            print (jsonString)
            
            webView.evaluateJavaScript("native.callWeb('responseDeviceInfo', '\(jsonString)')", completionHandler: {
                result, error in
                if let anError = error {
                    print("* error \(anError.localizedDescription)")
                }
            })
        } catch {
            //TODO.
        }
    }
    
    func currentAppVersion() -> String {
      if let info: [String: Any] = Bundle.main.infoDictionary,
          let currentVersion: String
            = info["CFBundleShortVersionString"] as? String {
            return currentVersion
      }
      return "nil"
    }
    
    func shareImage(_ content: Dictionary<String, String>) {
        let type = content["TYPE"]
        let title = content["TITLE"]
        let text = content["TEXT"]
        let img = content["IMG"]
        let textColor = content["TEXT_COLOR"]
        
        let contentType = contentType(text, img)
        
        let uiImage = base64Convert(img)
        let mergedImage = mergeTextToImage(title: title, contents: text, textColor: textColor, image: uiImage)
        
        //데이터 검증
        if(contentType == .ONLY_TEXT) {
            if(text == nil) {
                shareImageRtn(type, "FAIL", "type is \(type), contentType is \(contentType), TEXT is null")
                return
            }
        } else if(contentType == .ONLY_IMG) {
            if(uiImage == nil) {
                shareImageRtn(type, "FAIL", "type is \(type), contentType is \(contentType), IMAGE is null")
                return
            }
        } else if(contentType == .BOTH) {
            if(mergedImage == nil) {
                shareImageRtn(type, "FAIL", "type is \(type), contentType is \(contentType), MERGE IMAGE is null")
                return
            }
        }
        
        
        //저장 - image nil 아닐 때
        if type == "SAVE" {
            if(contentType == .ONLY_TEXT) { //text만 있을 때
                shareImageRtn(type, "FAIL", "type is \(type), contentType is \(contentType), not support ONLY TEXT")
                return
            }
            
            if(contentType == .ONLY_IMG) {  //image만 있을 때
                //갤러리저장
                UIImageWriteToSavedPhotosAlbum(uiImage!,self, nil, nil)
            }
            
            if(contentType == .BOTH) {  //text+image 있을 때
                //갤러리저장
                UIImageWriteToSavedPhotosAlbum(mergedImage!, self, nil, nil)
            }
        }
        
        //공유
        if type == "SHARE" {
            var shareContent:Any? = nil

            if(contentType == .ONLY_TEXT) { //text만 있을 때
                shareContent = text
            }
            
            if(contentType == .ONLY_IMG) {  //image만 있을 때
                shareContent = uiImage
            }
            
            if(contentType == .BOTH) {  //text+image 있을 때
                shareContent = mergedImage
            }
            
            if(shareContent == nil) {
                shareImageRtn(type, "FAIL", "type is \(type), contentType is \(contentType), shareContent is null")
                return
            }
            else {
                let vc = UIActivityViewController(activityItems: [shareContent], applicationActivities: nil)
                vc.excludedActivityTypes = [.saveToCameraRoll] //
                present(vc, animated: true)
            }
        }
    }
    
    func base64Convert(_ base64String: String?) -> UIImage? {
        if(base64String == nil) {
            return nil
        }
        
        if (base64String?.isEmpty)! {
            return nil
        } else {
            // !!! Separation part is optional, depends on your Base64String !!!
            let temp = base64String?.components(separatedBy: ",")
            let dataDecoded : Data = Data(base64Encoded: temp![1], options: .ignoreUnknownCharacters)!
            guard let decodedimage = UIImage(data: dataDecoded) else {
                return nil
            }
            return decodedimage
        }
    }
    
    func shareImageRtn(_ type: String?, _ isSuccess: String?, _ msg: String?) {
        let transferData : [String: String?] = [
            "TYPE": type,
            "RESULT": isSuccess,
            "MSG": msg
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: transferData, options: [])
            
            let jsonString = String(data: jsonData, encoding: String.Encoding.ascii)!
            print (jsonString)
            
            webView.evaluateJavaScript("native.callWeb('shareImageRtn', '\(jsonString)')", completionHandler: {
                result, error in
                if let anError = error {
                    print("* error \(anError.localizedDescription)")
                }
            })
        } catch {
            
        }
        
    }
    
    func mergeTextToImage(title: String?, contents: String?, textColor: String? , image: UIImage?) -> UIImage? {
        guard let title = title else {
            return nil
        }
        guard let contents = contents else {
            return nil
        }
        guard let image = image else {
            return nil
        }
        
        let color = (textColor == "#000000") ? UIColor.black : UIColor.white
        
        let imageSize = image.size
        UIGraphicsBeginImageContextWithOptions(CGSize(width: imageSize.width, height: imageSize.height), false, 1.0)
        let currentView = UIView(frame: CGRect(x: 0, y: 0, width: imageSize.width, height: imageSize.height))
        let currentImage = UIImageView(image: image)
        currentImage.frame = CGRect(x: 0, y: 0, width: imageSize.width, height: imageSize.height)
        currentView.addSubview(currentImage)
        
        let label = UILabel()
        label.frame = currentView.frame


        let text = title + "\n\n" + contents
        let font = UIFont(name:"HelveticaNeue-Medium" , size: 28)
        let titleFont = UIFont(name:"Noteworthy-Bold" , size: 32)

        let attributedStr = NSMutableAttributedString(string: text)
        attributedStr.addAttribute(NSAttributedString.Key(rawValue: kCTFontAttributeName as String), value: font ?? .init(), range: (text as NSString).range(of: text))
        attributedStr.addAttribute(NSAttributedString.Key.foregroundColor, value: color, range: (text as NSString).range(of: text))
//
//        attributedStr.addAttribute(NSAttributedString.Key(rawValue: kCTFontAttributeName as String), value: titleFont ?? .init(), range: (text as NSString).range(of: title))

        
        label.attributedText = attributedStr
        label.numberOfLines = 0
        label.textAlignment = .center
        label.text = text
        label.center = currentView.center
        currentView.addSubview(label)
        
        guard let currentContext = UIGraphicsGetCurrentContext() else {
            return nil
        }
        currentView.layer.render(in: currentContext)
        guard let image = UIGraphicsGetImageFromCurrentImageContext() else {
            return nil
        }
        
        UIGraphicsEndImageContext()
        return image
    }
}
