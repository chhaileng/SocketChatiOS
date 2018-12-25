//
//  User.swift
//  SocketChatiOS
//
//  Created by Chhaileng Peng on 12/19/18.
//  Copyright © 2018 Chhaileng Peng. All rights reserved.
//

import Foundation

class User: CustomStringConvertible {
    var sessionId: String
    var username: String
    
    init(sessionId: String, username: String) {
        self.sessionId = sessionId
        self.username = username
    }
    
    var description: String {
        return "[sessionId: \(sessionId), username: \(username)]"
    }
}
