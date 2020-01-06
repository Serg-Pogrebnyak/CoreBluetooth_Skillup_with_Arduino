//
//  ViewController.swift
//  IPhoneApp
//
//  Created by Sergey Pohrebnuak on 26.10.2019.
//  Copyright © 2019 Sergey Pohrebnuak. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet fileprivate weak var firstButton: UIButton!
    @IBOutlet fileprivate weak var secondButton: UIButton!
    @IBOutlet fileprivate weak var connectedStatusImage: UIImageView!
    @IBOutlet fileprivate weak var lightStatusImage: UIImageView!
    @IBOutlet fileprivate weak var temperatureLabel: UILabel!
    @IBOutlet fileprivate weak var lightStatusLabel: UILabel!
    
    fileprivate enum СonnectedAndLightStatusEnum: String {
        case connected = "switch-on"
        case disconnected = "switch-off"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        BLE.shared.bleDidChangeStatus = { [weak self] bleState in
            switch bleState {
            case .connected:
                DispatchQueue.main.async {
                    self?.firstButton.isEnabled = true
                    self?.secondButton.isEnabled = true
                    self?.connectedStatusImage.image = UIImage.init(named: СonnectedAndLightStatusEnum.connected.rawValue)
                }
            default:
                DispatchQueue.main.async {
                    self?.connectedStatusImage.image = UIImage.init(named: СonnectedAndLightStatusEnum.disconnected.rawValue)
                    self?.firstButton.isEnabled = false
                    self?.secondButton.isEnabled = false
                }
            }
            
        }
        
        BLE.shared.callbackAfterSendOrRead = { [weak self] (responseText, responseTemperature) in
            DispatchQueue.main.async {
                self?.setLightState(responseText)
            }
            
            DispatchQueue.main.async {
                self?.setTemperatureInLabel(responseTemperature)
            }
        }
    }

    @IBAction func didTapFirstButton(_ sender: Any) {
        BLE.shared.sendDataOnDevice(comand: .on)
    }
    
    @IBAction func didTapSecondButton(_ sender: Any) {
        BLE.shared.sendDataOnDevice(comand: .off)
    }
    
    @IBAction func scan(_ sender: Any) {
        BLE.shared.connectToDevice()
    }
    
    //MARK: - Fileprivate functions
    fileprivate func setTemperatureInLabel(_ temperature: Float?) {
        if temperature == nil {
            temperatureLabel.isHidden = true
            return
        } else {
            temperatureLabel.isHidden = false
        }
        
        temperatureLabel.text = String(temperature!)
        switch temperature! {
        case 0.0...5.0:
            temperatureLabel.textColor = UIColor.blue
        case 5.1...10.0:
            temperatureLabel.textColor = UIColor.cyan
        case 10.1...15.0:
            temperatureLabel.textColor = UIColor.orange
        case 15.1...20.0:
            temperatureLabel.textColor = UIColor.yellow
        case 20.1...25.0:
            temperatureLabel.textColor = UIColor.green
        case 25.1...30.0:
            temperatureLabel.textColor = UIColor.magenta
        case 30.1...35.0:
            temperatureLabel.textColor = UIColor.purple
        case 35.1...40.0:
            temperatureLabel.textColor = UIColor.red
        default:
            temperatureLabel.textColor = UIColor.black
        }
    }
    
    fileprivate func setLightState(_ text: String?) {
        if text == nil {
            lightStatusLabel.isHidden = true
            lightStatusImage.isHidden = true
            return
        } else {
            lightStatusLabel.isHidden = false
            lightStatusImage.isHidden = false
        }
        
        switch text! {
        case BLECommand.on.rawValue:
            lightStatusImage.image = UIImage.init(named: СonnectedAndLightStatusEnum.connected.rawValue)
        case BLECommand.off.rawValue:
            lightStatusImage.image = UIImage.init(named: СonnectedAndLightStatusEnum.disconnected.rawValue)
        default:
            print("error")
        }
    }
}

