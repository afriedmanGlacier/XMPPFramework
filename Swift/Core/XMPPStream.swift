//
//  XMPPStream.swift
//  XMPPFramework
//
//  Created by andyfriedman on 11/10/23.
//

import Foundation

public extension XMPPStream {
    func sendXMLElement(_ element: XMLElement) {
        self.send(element)
    }
}
