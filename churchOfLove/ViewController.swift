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
        
        let firstLaunch = FirstLaunch()
        var loadURL = ""
        if firstLaunch.isFirstLaunch {
            loadURL = Constants.BASE_URL.GUIDE_DOMAIN_URL
        } else {
            loadURL = Constants.BASE_URL.ADMIN_DOMAIN_URL
        }
        
        loadWebPage(loadURL)
        
        //Crashlytics 테스트
        let button = UIButton(type: .roundedRect)
        button.frame = CGRect(x: 20, y: 50, width: 100, height: 30)
        button.setTitle("Crash", for: [])
        button.addTarget(self, action: #selector(self.crashButtonTapped(_:)), for: .touchUpInside)
        self.view.addSubview(button)
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
        //self.webView?.allowsBackForwardNavigationGestures = true  //뒤로가기 제스쳐 허용
        
        self.webView = WKWebView(frame: self.view.frame, configuration: configuration)
        self.webView.uiDelegate = self
        self.webViewBackgroundView.addSubview(self.webView)
    }
        
    func loadWebPage(_ loadURL: String) {
        let url = URL(string: loadURL)
        let request = URLRequest(url: url!)
        
        if self.webView == nil {
            initializeWebView()
        }
        
        self.webView.load(request)
    }
    
    @IBAction func crashButtonTapped(_ sender: AnyObject) {
        fatalError()
    }
    
    private func willBecomeActive() {
//            NotificationCenter.default.addObserver(self,
//                                                   selector:#selector(appWillResignActive),
//                                                   name:UIScene.willDeactivateNotification,
//                                                   object:nil);
//            NotificationCenter.default.addObserver(self,
//                                                   selector:#selector(appDidBecomeActive),
//                                                   name:UIScene.didActivateNotification,
//                                                   object:nil);
        
        //            NotificationCenter.default.addObserver(self,
//                                                   selector:#selector(appWillResignActive),
//                                                   name:UIApplication.willResignActiveNotification,
//                                                   object:nil);
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
        case "outLink":
            guard let outLink = message.body as? String, let url = URL(string: outLink) else {
                return
            }
            
            let alert = UIAlertController(title: "OutLink 버튼 클릭", message: "URL : \(outLink)", preferredStyle: .alert)
            let openAction = UIAlertAction(title: "링크 열기", style: .default) { _ in
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
            let cancelAction = UIAlertAction(title: "취소", style: .cancel, handler: nil)
            alert.addAction(openAction)
            alert.addAction(cancelAction)
            
            self.present(alert, animated: true, completion: nil)
        default:
            break
        }
    }
    
    func callResponseDeviceInfo() {
        do {
            //기기 정보를 json string 으로 만든다.
            var transferData : [String: Any] = [
                "OS_VER": UIDevice.current.systemVersion,
                "APP_VER": "1.0.0",
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
    
    func shareImage(_ content: Dictionary<String, String>) {
        let type = content["TYPE"]
        let img = content["IMG"]
        let text = content["TEXT"]
        
        let contentType = contentType(text, img)
        
        let uiImage = base64Convert(img)
        let mergedImage = mergeTextToImage(text, uiImage)
        
        //저장 - image nil 아닐 때
        if type == "SAVE" {
            if(contentType == .ONLY_TEXT) { //text만 있을 때
                print("text 만은 저장하지 않습니다.")
            }
            
            if(contentType == .ONLY_IMG) {  //image만 있을 때
                //갤러리저장
                UIImageWriteToSavedPhotosAlbum(uiImage, self, nil, nil)
            }
            
            if(contentType == .BOTH) {  //text+image 있을 때
                //갤러리저장
                UIImageWriteToSavedPhotosAlbum(mergedImage, self, nil, nil)
            }
        }
        
        //공유
        if type == "SHARE" {
            var shareContent:Any = text
            if(contentType == .ONLY_TEXT) { //text만 있을 때
                shareContent = text
            }
            
            if(contentType == .ONLY_IMG) {  //image만 있을 때
                shareContent = uiImage
            }
            
            if(contentType == .BOTH) {  //text+image 있을 때
                shareContent = mergedImage
            }
            
            let vc = UIActivityViewController(activityItems: [shareContent], applicationActivities: nil)
            vc.excludedActivityTypes = [.saveToCameraRoll] //
            present(vc, animated: true)
        }
    }
    
    func base64Convert(_ base64String: String?) -> UIImage {
        if (base64String?.isEmpty)! {
            return #imageLiteral(resourceName: "no_image_icon")
        }else {
            // !!! Separation part is optional, depends on your Base64String !!!
            let temp = base64String?.components(separatedBy: ",")
            let dataDecoded : Data = Data(base64Encoded: temp![1], options: .ignoreUnknownCharacters)!
            guard let decodedimage = UIImage(data: dataDecoded) else {
                return #imageLiteral(resourceName: "no_image_icon")
            }
            return decodedimage
        }
    }
    
    func mergeTextToImage(_ text: String?, _ uiImage:UIImage) -> UIImage {
        guard let text = text else { return uiImage }
        
        let imageSize = uiImage.size
        UIGraphicsBeginImageContextWithOptions(CGSize(width: imageSize.width, height: imageSize.height), false, 1.0)
        let currentView = UIView(frame: CGRect(x: 0, y: 0, width: imageSize.width, height: imageSize.height))
        let currentImage = UIImageView(image: uiImage)
        currentImage.frame = CGRect(x: 0, y: 0, width: imageSize.width, height: imageSize.height)
        currentView.addSubview(currentImage)
        
        let label = UILabel()
        label.frame = currentView.frame
        
        let fontSize: CGFloat = 34
        let font = UIFont(name:"Noteworthy-Light" , size: fontSize)
        let attributedStr = NSMutableAttributedString(string: text)
        attributedStr.addAttribute(NSAttributedString.Key(rawValue: kCTFontAttributeName as String), value: font ?? .init(), range: (text as NSString).range(of: text))
        attributedStr.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.white, range: (text as NSString).range(of: text))
        
        label.attributedText = attributedStr
        label.numberOfLines = 0
        label.textAlignment = .center
        label.text = text
        label.center = currentView.center
        currentView.addSubview(label)
        
        guard let currentContext = UIGraphicsGetCurrentContext() else {
            return uiImage
        }
        currentView.layer.render(in: currentContext)
        guard let image = UIGraphicsGetImageFromCurrentImageContext() else {
            return uiImage
        }
        
        UIGraphicsEndImageContext()
        return image
    }
}
