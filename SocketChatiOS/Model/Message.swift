//
//  Message.swift
//  SocketChatiOS
//
//  Created by Chhaileng Peng on 12/19/18.
//  Copyright © 2018 Chhaileng Peng. All rights reserved.
//

import Foundation

class Message: CustomStringConvertible {
    var user: User
    var message: String
    
    init(user: User, message: String) {
        self.user = user
        self.message = message
    }
    
    var description: String {
        return "[user: \(user), message: \(message)]"
    }
}
