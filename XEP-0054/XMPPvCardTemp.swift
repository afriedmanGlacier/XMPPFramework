//
//  XMPPvCardTemp.swift
//  XMPPFramework
//
//  Created by andyfriedman on 11/15/23.
//

import Foundation

public extension XMPPvCardTemp {
    func setNameAndAvatar(_ displayName:String?, avatar:Data?) {
        self.nickname = displayName
        self.photo = avatar
    }
    /*func sendXMLElement(_ element: XMLElement) {
        self.send(element)
    }*/
}
