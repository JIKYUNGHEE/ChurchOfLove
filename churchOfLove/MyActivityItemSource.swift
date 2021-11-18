//
//  MyActivityItemSource.swift
//  churchOfLove
//
//  Created by KYUNGHEE JI on 2021/11/14.
//

import LinkPresentation

@available(iOS 13.0, *)
class MyActivityItemSource: NSObject, UIActivityItemSource {
    var title: String
    var text: String
    var shareContents: Any
    
    init(title: String, text: String?, shareContents: Any) {
        self.title = title
        guard text = text else {
            text = "공유합니다."
        }
        self.shareContents = shareContents
        super.init()
    }
    
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return text
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        return text
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
        return title
    }

    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        let metadata = LPLinkMetadata()
        metadata.title = title
        metadata.iconProvider = NSItemProvider(object: UIImage(systemName: "AppIcon")!)
        //This is a bit ugly, though I could not find other ways to show text content below title.
        //https://stackoverflow.com/questions/60563773/ios-13-share-sheet-changing-subtitle-item-description
        //You may need to escape some special characters like "/".
        metadata.originalURL = URL(fileURLWithPath: text)
        return metadata
    }

}
