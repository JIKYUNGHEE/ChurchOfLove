//
//  UIImageView.swift
//  churchOfLove
//
//  Created by KYUNGHEE JI on 2021/09/30.
//

import UIKit

extension UIImageView {
    func createImageWithLabelOverlay(text: String, isFromCamera: Bool = false) -> UIImage? {
        let imageSize = self.image?.size ?? .zero
        UIGraphicsBeginImageContextWithOptions(CGSize(width: imageSize.width, height: imageSize.height), false, 1.0)
        let currentView = UIView(frame: CGRect(x: 0, y: 0, width: imageSize.width, height: imageSize.height))
        let currentImage = UIImageView(image: self.image)
        currentImage.frame = CGRect(x: 0, y: 0, width: imageSize.width, height: imageSize.height)
        currentView.addSubview(currentImage)
        
        let label = UILabel()
        label.frame = currentView.frame
        
        //        for family in UIFont.familyNames {
        //             print("family:", family)
        //             for font in UIFont.fontNames(forFamilyName: family) {
        //                 print("font:", font)
        //             }
        //         }
        let fontSize: CGFloat = isFromCamera ? 100 : 34
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
            return nil
        }
        currentView.layer.render(in: currentContext)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        image = img
        return img
    }
}
