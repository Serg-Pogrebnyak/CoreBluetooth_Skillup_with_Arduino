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
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.global().asyncAfter(deadline: .now()+2) {
            BLE.shared.startScan()
        }
    }

    @IBAction func didTapFirstButton(_ sender: Any) {
        BLE.shared.sendDataOnDevice(comand: .on)
    }
    
    @IBAction func didTapSecondButton(_ sender: Any) {
        BLE.shared.sendDataOnDevice(comand: .off)
    }
    
    @IBAction func scan(_ sender: Any) {
        BLE.shared.startScan()
    }
}

