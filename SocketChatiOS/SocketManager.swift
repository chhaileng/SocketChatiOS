//
//  SocketManager.swift
//  SocketChatiOS
//
//  Created by Chhaileng Peng on 12/19/18.
//  Copyright © 2018 Chhaileng Peng. All rights reserved.
//

import Foundation
import SocketIO

class SocketManger {
    
    static let shared = SocketManger()
    
    let socket = SocketIOClient(socketURL: URL(string: "http://chat.chhaileng.com:1111")!, config: [.log(false), .forceWebsockets(true), .nsp("/chat")])
    
    func connect() {
        socket.connect()
    }
    
    func disconnect() {
        socket.disconnect()
    }
    
    
    func onConnect(handler: @escaping () -> Void) {
        socket.on("connect") { (_, _) in
            handler()
        }
    }
    
    func userJoinOnConnect(user: User) {
        let u: [String: String] = ["sessionId": socket.sid!, "username": user.username]
        self.socket.emit("userJoin", with: [u])
    }
    
    func handleNewMessage(handler: @escaping (_ message: Message) -> Void) {
        socket.on("newMessage") { (data, ack) in
            let msg = data[0] as! [String: Any]
            let usr = msg["user"] as! [String: Any]
            let user = User(sessionId: usr["sessionId"] as! String, username: usr["username"] as! String)
            let message = Message(user: user, message: msg["message"] as! String)
            handler(message)
        }
    }
    
    func handleUserTyping(handler: @escaping () -> Void) {
        socket.on("userTyping") { (_, _) in
            handler()
        }
    }
    
    func handleUserStopTyping(handler: @escaping () -> Void) {
        socket.on("userStopTyping") { (_, _) in
            handler()
        }
    }
    
    func handleActiveUserChanged(handler: @escaping (_ count: Int) -> Void) {
        socket.on("count") { (data, ack) in
            let count = data[0] as! Int
            handler(count)
        }
    }
    
    func sendMessage(message: Message) {
        let msg: [String: Any] = ["message": message.message,
                                  "user": ["sessionId": message.user.sessionId,
                                           "username": message.user.username
                                          ]
                                 ]
        socket.emit("sendMessage", with: [msg])
    }
    
}
