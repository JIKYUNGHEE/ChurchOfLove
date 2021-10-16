//
//  String.swift
//  churchOfLove
//
//  Created by KYUNGHEE JI on 2021/09/30.
//

import UIKit

extension String {
    
    
    func toImage() -> UIImage? {
        if let data = Data(base64Encoded: self, options: .ignoreUnknownCharacters){
            return UIImage(data: data)
        }
        return nil
    }

}
