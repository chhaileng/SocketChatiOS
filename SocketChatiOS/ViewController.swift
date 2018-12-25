//
//  ViewController.swift
//  SocketChatiOS
//
//  Created by Chhaileng Peng on 12/19/18.
//  Copyright © 2018 Chhaileng Peng. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var messageTextField: UITextField!
    
    @IBOutlet weak var inputContainerBottomContraint: NSLayoutConstraint!
    
    var activeUserLabel: UILabel!
    var messages = [Message]()
    var user: User!
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: MessageTableViewCell
        if messages[indexPath.row].user.sessionId == user.sessionId {
            cell = tableView.dequeueReusableCell(withIdentifier: "outgoingCell") as! MessageTableViewCell
        } else {
            cell = tableView.dequeueReusableCell(withIdentifier: "incomingCell") as! MessageTableViewCell
        }
        cell.configureCell(message: messages[indexPath.row])
        return cell
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        messageTextField.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardOpen), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardOpen), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        let tapGuesterHideKeyboard = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        let tapGuesterShowKeyboard = UITapGestureRecognizer(target: self, action: #selector(showKeyboard))
        tableView.addGestureRecognizer(tapGuesterHideKeyboard)
        messageTextField.superview?.addGestureRecognizer(tapGuesterShowKeyboard)

        
        // Custom active user label
        activeUserLabel = UILabel()
        activeUserLabel.textColor = UIColor(red: 24/255, green: 186/255, blue: 0/255, alpha: 1.0)
        activeUserLabel.text = "0 user"
        activeUserLabel.sizeToFit()
        navigationItem.rightBarButtonItems = [UIBarButtonItem(customView: activeUserLabel)]
        navigationItem.leftBarButtonItems = [UIBarButtonItem(title: "Re-login", style: .plain, target: self, action: #selector(reLogin))]
       
        SocketManger.shared.onConnect {
            self.registerUser()
        }
        
        SocketManger.shared.handleNewMessage { (message) in
            self.messages.append(message)
            self.tableView.reloadData()
            self.scrollToBottomOfChat()
        }
        
        SocketManger.shared.handleActiveUserChanged { (count) in
            self.activeUserLabel.text = "\(count) user\(count > 1 ? "s" : "")"
            self.activeUserLabel.sizeToFit()
        }
        
        SocketManger.shared.handleUserTyping {
            self.title = "Typing..."
        }
        
        SocketManger.shared.handleUserStopTyping {
            self.title = "Socket Chat"
        }
    }
    
    @objc func reLogin() {
        UserDefaults.standard.removeObject(forKey: "username")
        SocketManger.shared.disconnect()
        SocketManger.shared.connect()
    }
    
    func scrollToBottomOfChat(){
        let indexPath = IndexPath(row: messages.count - 1, section: 0)
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: false)
    }
    
    func loadChatHistory() {
        URLSession.shared.dataTask(with: URL(string: "http://chat.chhaileng.com/api/messages")!) { (data, rsponse, error) in
            if error == nil {
                if let data = data {
                    if let jsonData = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) {
                        if let arrayJson = jsonData as? NSArray {
                            DispatchQueue.main.async {
                                self.messages.removeAll()
                                self.tableView.reloadData()
                            }
                            for json in arrayJson {
                                let msg = json as! [String: Any]
                                let user = msg["user"] as! [String: String]
                                let message = Message(user: User(sessionId: user["sessionId"]!, username: user["username"]!), message: msg["message"] as! String)
                                self.messages.append(message)
                            }
                            DispatchQueue.main.async {
                                self.tableView.reloadData()
                                self.scrollToBottomOfChat()
                            }
                        }
                    }
                }
            }
        }.resume()
    }
    
    func registerUser() {
        if let username = UserDefaults.standard.string(forKey: "username") {
            if self.user == nil {
                self.user = User(sessionId: SocketManger.shared.socket.sid!, username: username)
                SocketManger.shared.userJoinOnConnect(user: user)
                self.loadChatHistory()
            }
        } else {
            let alert = UIAlertController(title: "What is your name?", message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in
                if let text = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespaces) {
                    if text != "" {
                        self.user = User(sessionId: SocketManger.shared.socket.sid!, username: text)
                        UserDefaults.standard.set(text, forKey: "username")
                        SocketManger.shared.userJoinOnConnect(user: self.user)
                        self.loadChatHistory()
                    } else { self.present(alert, animated: true, completion: nil) }
                }
            }))
            alert.addTextField { (textField) in textField.placeholder = "Enter your name" }
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    
    // Send Message
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendMessage()
        return true
    }
    
    @IBAction func sendButtonDidTap(_ sender: UIButton) {
        sendMessage()
    }
    
    func sendMessage() {
        if let message = messageTextField.text {
            if message.trimmingCharacters(in: .whitespaces) != "" {
                let msg = Message(user: user, message: message.trimmingCharacters(in: .whitespaces))
                SocketManger.shared.sendMessage(message: msg)
                messageTextField.text = ""
                messages.append(msg)
                tableView.reloadData()
                scrollToBottomOfChat()
            }
        }
    }
    // End Send Message
    
    
    // Keyboard handler
    @objc func hideKeyboard() {
        messageTextField.resignFirstResponder()
    }
    
    @objc func showKeyboard() {
        messageTextField.becomeFirstResponder()
    }
    
    @objc func handleKeyboardOpen(notification: Notification) {
        if let userInfo = notification.userInfo {
            if messageTextField.isEditing {
                let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as! CGRect
                if notification.name == UIResponder.keyboardWillShowNotification {
                    inputContainerBottomContraint.constant = -keyboardFrame.height
                } else {
                    inputContainerBottomContraint.constant = 0
                }
                
                UIView.animate(withDuration: 0, delay: 0, options: .curveEaseOut, animations: {
                    self.view.layoutIfNeeded()
                }, completion: nil)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        messageTextField.resignFirstResponder()
    }
    // End Keyboard handler

}

