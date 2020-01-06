//
//  BLE.swift
//  IPhoneApp
//
//  Created by Sergey Pohrebnuak on 26.10.2019.
//  Copyright © 2019 Sergey Pohrebnuak. All rights reserved.
//

import Foundation
import CoreBluetooth

enum BLECommand: String {
    case on
    case off
}

enum BLEState {
    case on, off, connected, disconnected, searchAndConnecting
}

class BLE: NSObject {
    static let shared = BLE()
    
    var bleDidChangeStatus: ((BLEState) -> Void)? {
        didSet {
            self.bleDidChangeStatus?(bleState)
        }
    }
    
    var callbackAfterSendOrRead: ((String?) -> Void)?
    
    fileprivate var manager: CBCentralManager!
    fileprivate var remotePeripheral: CBPeripheral?
    fileprivate var characteristicForWrite: CBCharacteristic?
    fileprivate var characteristicForRead: CBCharacteristic? {
        didSet {
            self.readValue()
        }
    }
    
    fileprivate var bleState = BLEState.off {
        didSet {
            self.bleDidChangeStatus?(bleState)
        }
    }
    
    fileprivate var peripheralName = "ESP32"
    
    fileprivate let serviceOfUUIDForWrite = CBUUID(string: "6e400001-b5a3-f393-e0a9-e50e24dcca9e")
    fileprivate let characteristicOfUUIDForWrite = CBUUID(string: "6e400003-b5a3-f393-e0a9-e50e24dcca9e")
    fileprivate let serviceOfUUIDForRead = CBUUID(string: "6e400002-b5a3-f393-e0a9-e50e24dcca9e")
    fileprivate let characteristicOfUUIDForRead = CBUUID(string: "6e400004-b5a3-f393-e0a9-e50e24dcca9e")
    
    override init() {
        super.init()
        manager = CBCentralManager(delegate: self, queue: DispatchQueue.global())
    }
    
    func connectToDevice() {
        guard   let identifier = UserDefaults.standard.value(forKey: "peripheralIdentifier") as? String,
                let uuid = UUID.init(uuidString: identifier),
                let savedPeripheral = manager.retrievePeripherals(withIdentifiers: [uuid]).first
        else {
            self.startScan()
            return
        }
        
        remotePeripheral = savedPeripheral
        remotePeripheral!.delegate = self
        manager.connect(remotePeripheral!, options: nil)
    }
    
    func sendDataOnDevice(comand: BLECommand) {
        remotePeripheral!.writeValue(Data(base64Encoded: comand.rawValue.toBase64())!,
                                     for: characteristicForWrite!,
                                     type: .withoutResponse)
    }
    
    func disconnectFromDevice() {
        if remotePeripheral != nil {
            manager.cancelPeripheralConnection(remotePeripheral!)
        }
    }
    
    fileprivate func startScan() {
        if remotePeripheral != nil {
            manager.cancelPeripheralConnection(remotePeripheral!)
        }
        manager.scanForPeripherals(withServices: [serviceOfUUIDForWrite, serviceOfUUIDForRead], options: nil)
        DispatchQueue.global().asyncAfter(deadline: .now() + 5) {
            self.checkStateAfterScanning()
            self.manager.stopScan()
        }
    }
    
    fileprivate func checkStateAfterScanning() {
        if manager.state == .poweredOn {
            guard remotePeripheral != nil else {
                self.bleState = .on
                return
            }
            switch remotePeripheral!.state {
            case .disconnected, .disconnecting:
                self.bleState = .on
            case .connecting:
                if self.bleState != .searchAndConnecting {
                    self.bleState = .searchAndConnecting
                }
            case .connected:
                self.bleState = .connected
            default:
                fatalError("state not found")
            }
        } else {
            self.bleState = .off
        }
    }
    
    fileprivate func readValue() {
        remotePeripheral?.readValue(for: characteristicForRead!)
    }
}

extension BLE: CBCentralManagerDelegate {
    //MARK: delegate for check update bluetooth state
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            bleState = .on
            connectToDevice()
        } else {
            bleState = .off
        }
    }
}

extension BLE: CBPeripheralDelegate {
    //delegate when find new device
    func centralManager(_ central: CBCentralManager, didDiscover peripheral:CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if bleState != .searchAndConnecting {
            bleState = .searchAndConnecting
        }
        if let deviceName = peripheral.name {
            print(deviceName, advertisementData)
        }
        if peripheral.name == peripheralName {
            manager.connect(peripheral, options: nil)
            remotePeripheral = peripheral
            self.manager.stopScan()
        }
    }
    
    //didConnect
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        bleState = .connected
        peripheral.discoverServices(nil)
        remotePeripheral = peripheral
        remotePeripheral!.delegate = self
        UserDefaults.standard.set(remotePeripheral?.identifier.uuidString, forKey: "peripheralIdentifier")
    }
    
    //didDisconnect
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        bleState = .disconnected
        remotePeripheral = nil
        characteristicForWrite = nil
    }
    
    //describe service
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard peripheral.services!.count > 0 else {return}
        for service in peripheral.services! {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    //describe characteristic
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard service.characteristics!.count > 0 else {return}
//print service and characteristic
//        for characteristics in service.characteristics! {
//            print(service.description)
//            print(characteristics.description)
//        }
        for characteristics in service.characteristics! {
            switch characteristics.uuid {
            case characteristicOfUUIDForWrite:
                characteristicForWrite = characteristics
            case characteristicOfUUIDForRead:
                characteristicForRead = characteristics
                peripheral.setNotifyValue(true, for: characteristics)
            default:
                print("another uuid found")
            }
        }
    }
    
    //result send command
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        guard characteristic.value != nil else {return}
        
        print("result after writing comand: \(String(bytes: characteristic.value!, encoding: .utf8)!)")
    }
    
    //result read and result notification
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard characteristic.value != nil else {return}
        
        let response = String(bytes: characteristic.value!, encoding: .utf8)
        print("data is: \(response ?? "Error")")
        callbackAfterSendOrRead?(response)
    }
}

extension String {
    func toBase64()->String {
        let data = self.data(using: .utf8)
        return (data?.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0)))!
    }
}
