//
//  ViewController.swift
//  jwNFCSample
//
//  Created by JW_Macbook on 2020/03/16.
//  Copyright © 2020 JW_Macbook. All rights reserved.
//

import UIKit
import CoreNFC // <-- import Add..

class ViewController: UIViewController {

    //MARK:- IBOutlet
    @IBOutlet weak var scanTextView: UITextView!
    @IBOutlet weak var scanBtn: UIButton!
    
    
    //MARK:-
    var nfcSession: NFCNDEFReaderSession?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    // Scan Btn Click
    @IBAction func doScanAction(_ sender: UIButton) {
        print("Scan Btn Click")
        guard NFCNDEFReaderSession.readingAvailable else {
            let alertController = UIAlertController(
                title: "Scanning Not Supported",
                message: "This device doesn't support tag scanning.",
                preferredStyle: .alert
            )
            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alertController, animated: true, completion: nil)
            return
        }
        
        
        nfcSession = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: false)
        nfcSession?.alertMessage = "스캔 테스트 중..."
        nfcSession?.begin()
    }
}

//MARK:- NFCNDEFReaderSession Delegate
extension ViewController: NFCNDEFReaderSessionDelegate {
    
    // 1)
    func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {
        print("시작시")
    }
    
    // 2)
    func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {
        if tags.count > 1 {
            // Restart polling in 500ms
            let retryInterval = DispatchTimeInterval.milliseconds(500)
            session.alertMessage = "More than 1 tag is detected, please remove all tags and try again."
            DispatchQueue.global().asyncAfter(deadline: .now() + retryInterval, execute: {
                session.restartPolling()
            })
            return
        }
        
        // Connect to the found tag and perform NDEF message reading
        let tag = tags.first!
        session.connect(to: tag, completionHandler: { (error: Error?) in
            if nil != error {
                session.alertMessage = "Unable to connect to tag."
                session.invalidate()
                return
            }
            
            tag.queryNDEFStatus(completionHandler: { (ndefStatus: NFCNDEFStatus, capacity: Int, error: Error?) in
                if .notSupported == ndefStatus {
                    session.alertMessage = "Tag is not NDEF compliant"
                    session.invalidate()
                    return
                } else if nil != error {
                    session.alertMessage = "Unable to query NDEF status of tag"
                    session.invalidate()
                    return
                }
                
                tag.readNDEF(completionHandler: { (message: NFCNDEFMessage?, error: Error?) in
                    var statusMessage: String
                    if nil != error || nil == message {
                        statusMessage = "Fail to read NDEF from tag"
                    } else {
                        statusMessage = "Found 1 NDEF message"
                        DispatchQueue.main.async {
                            // Process detected NFCNDEFMessage objects.
                            var result = ""
                            for record in message!.records {
                                result += "Type name format: \(record.typeNameFormat)\n"
                                result += "Payload: \(String.init(data: record.payload, encoding: .utf8) ?? "XXX")\n"
                                result += "Type: \(String.init(data: record.type, encoding: .utf8) ?? "XXX")\n"
                                result += "Identifier: \(String.init(data: record.identifier, encoding: .utf8) ?? "XXX")\n"
                                
                                // Message 변환?
                            }

                            DispatchQueue.main.async {
                                self.scanTextView.text = result
                            }
                        }
                    }
                    
                    session.alertMessage = statusMessage
                    session.invalidate()
                })
            })
        })
    }

    
    // #) Error
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        print("reader error: \(error.localizedDescription)")
        self.nfcSession = nil
    }
    
    // ??????
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        var message = ""
        for payload in messages.first!.records {
            message += String.init(data: payload.payload.advanced(by: 3), encoding: .utf8) ?? ""
        }

        DispatchQueue.main.async {
            self.scanTextView.text = message
        }
    }
    
    
}
