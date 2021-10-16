//
//  ContentType.swift
//  churchOfLove
//
//  Created by KYUNGHEE JI on 2021/09/30.
//

enum contentType {
    case ONLY_TEXT
    case ONLY_IMG
    case BOTH
    case EMPTY

    
    init?(_ text:String?, _ img:String?) {
        if text != nil && (img == nil || img!.isEmpty) {
            self = .ONLY_TEXT
        } else if (text == nil || text!.isEmpty) && img != nil {
            self = .ONLY_IMG
        } else if text != nil && img != nil {
            self = .BOTH
        } else {
            self = .EMPTY
        }
    }
}
