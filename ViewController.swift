//
//  ViewController.swift
//  BrainBender
//
//  Created by Anirudh Natarajan on 2/4/17.
//  Copyright © 2017 Kodikos. All rights reserved.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController, IXNMuseConnectionListener, IXNMuseDataListener, IXNMuseListener, IXNLogListener, UITableViewDelegate, UITableViewDataSource, CBCentralManagerDelegate {
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var logView: UITextView!
    
    var manager: IXNMuseManagerIos!
    weak var muse: IXNMuse?
    var logLines = [Any]()
    var isLastBlink: Bool = false
    var btManager: CBCentralManager!
    var isBtState: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UIApplication.shared.isIdleTimerDisabled = true
        if !(self.manager != nil) {
            self.manager = IXNMuseManagerIos.shared
        }
    }
    
    override init(nibName nibNameOrNil: String!, bundle nibBundleOrNil: Bundle!) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        self.manager = IXNMuseManagerIos.shared
        self.manager.museListener = self
        self.tableView = UITableView()
        self.logView = UITextView()
        self.logLines = [Any]()
        self.logView.text = ""
        IXNLogManager.instance().logListener = self
        var dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd hh:mm:ss"
        var dateStr: String = dateFormatter.string(from: Date()) + ".log"
        print("\(dateStr)")
        self.btManager = CBCentralManager(delegate: self, queue: nil, options: nil)
        self.isBtState = false
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func log(_ fmt: String) {
        var args: CVaListPointer
        va_start(args, fmt)
        var line = String(format: fmt, arguments: args)
        vm_read(args)
        print("\(line)")
        self.logLines.insert(line, at: 0)
        DispatchQueue.main.async(execute: {() -> Void in
            self.logView.text = (self.logLines as NSArray).componentsJoined(by: "\n")
        })
    }
    
    func receiveLog(_ l: IXNLogPacket) {
        self.log("%@: %llu raw:%d %@", l.tag, l.timestamp, l.raw, l.message)
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        self.isBtState = (self.btManager.state == .poweredOn)
    }
    
    func isBluetoothEnabled() -> Bool {
        return self.isBtState
    }
    
    func museListChanged() {
        self.tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.manager.getMuses().count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var simpleTableIdentifier: String = "nil"
        var cell: UITableViewCell? = tableView.dequeueReusableCell(withIdentifier: simpleTableIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: simpleTableIdentifier)
        }
        var muses: [Any] = self.manager.getMuses()
        if indexPath.row < muses.count {
            var muse: IXNMuse? = self.manager.getMuses()[indexPath.row]
            cell?.textLabel?.text = muse?.getName()
            if !(muse?.isLowEnergy())! {
                cell?.textLabel?.text = (cell?.textLabel?.text?)! + (muse?.getMacAddress())!
            }
        }
        return cell!
    }
    
    func receive(_ packet: IXNMuseConnectionPacket, muse: IXNMuse?) {
        var state: String
        switch packet.currentConnectionState {
        case IXNConnectionStateDisconnected:
            state = "disconnected"
        case IXNConnectionStateConnected:
            state = "connected"
        case IXNConnectionStateConnecting:
            state = "connecting"
        case IXNConnectionStateNeedsUpdate:
            state = "needs update"
        case IXNConnectionStateUnknown:
            state = "unknown"
        default:
            assert(false, "impossible connection state received")
        }
        
        self.log("connect: %@", state)
    }
    
    func connect() {
        self.muse.registerConnectionListener(self)
        self.muse.registerDataListener(self, type: IXNMuseDataPacketTypeArtifacts)
        self.muse.registerDataListener(self, type: IXNMuseDataPacketTypeAlphaAbsolute)
        /*
         [self.muse registerDataListener:self
         type:IXNMuseDataPacketTypeEeg];
         */
        self.muse.runAsynchronously()
    }
    
    func receive(_ packet: IXNMuseDataPacket?, muse: IXNMuse?) {
        if packet.packetType == IXNMuseDataPacketTypeAlphaAbsolute || packet.packetType == IXNMuseDataPacketTypeEeg {
            self.log("%5.2f %5.2f %5.2f %5.2f", CDouble(packet.values[IXNEegEEG1]), CDouble(packet.values[IXNEegEEG2]), CDouble(packet.values[IXNEegEEG3]), CDouble(packet.values[IXNEegEEG4]))
        }
    }
    
    func receive(_ packet: IXNMuseArtifactPacket, muse: IXNMuse) {
        if packet.blink && packet.blink != self.lastBlink {
            self.log("blink detected")
        }
        self.lastBlink = packet.blink
    }
    
    func applicationWillResignActive() {
        print("disconnecting before going into background")
        self.muse.disconnect()
    }
    
    @IBAction func disconnect(_ sender: Any) {
        if self.muse {
            self.muse.disconnect()
        }
    }
    
    @IBAction func scan(_ sender: Any) {
        self.manager.startListening()
        self.tableView.reloadData()
    }
    
    @IBAction func stopScan(_ sender: Any) {
        self.manager.stopListening()
        self.tableView.reloadData()
    }
}
