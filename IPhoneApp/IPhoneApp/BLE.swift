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
    
    fileprivate var manager: CBCentralManager!
    fileprivate var remotePeripheral: CBPeripheral?
    fileprivate var characteristicForWrite: CBCharacteristic?
    fileprivate var bleState = BLEState.off {
        didSet {
            self.bleDidChangeStatus?(bleState)
        }
    }
    
    fileprivate let uuidForWrite = "FFD9"//"beb5483e-36e1-4688-b7f5-ea07361b26a8"//"FFE1"
    fileprivate var peripheralName = "Triones#FFFF9401EA58"//"ESP32"//"BT05"//'Triones#FFFF9401EA58'
    
    override init() {
        super.init()
        manager = CBCentralManager(delegate: self, queue: DispatchQueue.global())
    }
    
    func hasRemotePeripheral() -> Bool {
        return remotePeripheral != nil
    }
    
    func startScan() {
        if remotePeripheral != nil {
            manager.cancelPeripheralConnection(remotePeripheral!)
        }
        manager.scanForPeripherals(withServices: nil, options: nil)
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
    
    func isCanWrite() -> Bool {
        return characteristicForWrite != nil
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
}
//
extension BLE: CBCentralManagerDelegate {
    //MARK: delegate for check update bluetooth state
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            bleState = .on
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
            print(deviceName)
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
        for characteristics in service.characteristics! {
            print(Date())
            print(characteristics.description)
            print(service.description)
        }
        for characteristics in service.characteristics! where characteristics.uuid == CBUUID(string: uuidForWrite) {
            characteristicForWrite = characteristics
            peripheral.setNotifyValue(true, for: characteristicForWrite!)
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
        print("data is: \(String(bytes: characteristic.value!, encoding: .utf8)!)")
    }
    
    func peripheralDidUpdateName(_ peripheral: CBPeripheral) {
        print(peripheral)
    }
}

extension String {
    func toBase64()->String {
        let data = self.data(using: .utf8)
        return (data?.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0)))!
    }
}
