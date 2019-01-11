//
//  ViewController.swift
//  EX-Xylophone
//
//  Created by JIN ZHAO on 1/5/19.
//  Copyright © 2019/Users/martini/Desktop/IOS 12 Practice/BLE/EX-Xylophone/EX-Xylophone JIN ZHAO. All rights reserved.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController, CBCentralManagerDelegate,  CBPeripheralDelegate, UIPickerViewDelegate, UIPickerViewDataSource{
    
    //MARK:
    @IBOutlet weak var pickerView: UIPickerView!
    var pickerData = ["1","2","3","4","5","6","7","8"]
    var selectOneValue = 0
    
    var hc08CentralManager:CBCentralManager!
    var hc08Perripheral:CBPeripheral?
    var hc08Characteristic:CBCharacteristic?
    
    var keepScanning = true;
    var timerScanInterval:TimeInterval = 2.0;
    @objc var timerPauseInterval:TimeInterval = 10.0;
    
    var DEVICENAME:String = "HC-08"
    var SERVICEUUID:String = "FFE0"
    var CHARACTERISTIC:String = "FFE1"
    
    let pitches = [[33, 37, 41, 44, 49, 55, 62],
                   [65, 73, 82, 87, 98, 110, 123],
                   [131, 147, 165, 175, 196, 220, 247],
                   [262, 294, 330, 349, 392, 440, 494],
                   [523, 587, 659, 698, 784, 880, 988],
                   [1047, 1175, 1319, 1397, 1568, 1760, 1976],
                   [2093, 2349, 2637, 2794, 3136, 3520, 3951],
                   [4186, 4699]]
//    let pitches = [1, 2, 3, 4, 5, 6, 7]

    override func viewDidLoad() {
        super.viewDidLoad()
        hc08CentralManager = CBCentralManager(delegate: self, queue: nil)
        pickerView.dataSource = self
        pickerView.delegate = self
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return 8
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1;
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerData[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if(component == 0){
            //记录用户选择的值
            selectOneValue = Int(pickerData[row]) ?? 1
        }
//        selectOneValue = Int(pickerData[row]) ?? 1
    }
    
    @IBAction func noteReleased(_ sender: UIButton) {
        if (keepScanning == false) {
            let command = ("-1\n").data(using: .utf8)
//            var value:UInt8 = 0
//            let command = Data(bytes: &value, count: MemoryLayout.size(ofValue: value))
            hc08Perripheral?.writeValue(command!, for: hc08Characteristic!, type: .withoutResponse)
        }
    }
    
    @IBAction func notePressed(_ sender: UIButton) {
        if (keepScanning == false) {
            var index = 0
            if (selectOneValue == 8) {
                index = 1
            }
            else {
                index = sender.tag - 1
            }
            let command = ((String)(pitches[selectOneValue - 1][index]) + "\n").data(using: .utf8)
//            var value:UInt8 = UInt8(pitches[sender.tag - 1])
//            let command = Data(bytes: &value, count: MemoryLayout.size(ofValue: value))
            hc08Perripheral?.writeValue(command!, for: hc08Characteristic!, type: .withoutResponse)
        }
    }
    
    
    // MARK: - CBCentralManagerDelegate methods
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        var message = ""
        
        switch central.state {
        case .poweredOff:
            message = "Bluetooth on this device is currently powered off."
        case .unsupported:
            message = "This device does not support Bluetooth Low Energy."
        case .unauthorized:
            message = "This app is not authorized to use Bluetooth Low Energy."
        case .resetting:
            message = "The BLE Manager is resetting; a state update is pending."
        case .unknown:
            message = "The state of the BLE Manager is unknown."
        case .poweredOn:
//            showAlert = false
            message = "Bluetooth LE is turned on and ready for communication."
            
            print(message)
            keepScanning = true
            _ = Timer(timeInterval: timerScanInterval, target: self, selector: #selector(getter: timerPauseInterval), userInfo: nil, repeats: false)
            
            // Initiate Scan for Peripherals
            //Option 1: Scan for all devices
            hc08CentralManager.scanForPeripherals(withServices: nil, options: nil)
            
            // Option 2: Scan for devices that have the service you're interested in...
            //let sensorTagAdvertisingUUID = CBUUID(string: Device.SensorTagAdvertisingUUID)
            //print("Scanning for SensorTag adverstising with UUID: \(sensorTagAdvertisingUUID)")
            //centralManager.scanForPeripheralsWithServices([sensorTagAdvertisingUUID], options: nil)
            
        }
        
//        if showAlert {
//            let alertController = UIAlertController(title: "Central Manager State", message: message, preferredStyle: UIAlertController.Style.alert)
//            let okAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.cancel, handler: nil)
//            alertController.addAction(okAction)
//            self.show(alertController, sender: self)
//        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
//        print("centralManager didDiscoverPeripheral - CBAdvertisementDataLocalNameKey is \"\(CBAdvertisementDataLocalNameKey)\"")
        
        // Retrieve the peripheral name from the advertisement data using the "kCBAdvDataLocalName" key
        if let peripheralName = advertisementData[CBAdvertisementDataLocalNameKey] as? String {
            print("NEXT PERIPHERAL NAME: \(peripheralName)")
            print("NEXT PERIPHERAL UUID: \(peripheral.identifier.uuidString)")
            
            if peripheralName == DEVICENAME {
                print("HC-08 FOUND! ADDING NOW!!!")
                // to save power, stop scanning for other devices
                keepScanning = false
//                disconnectButton.enabled = true
                
                // save a reference to the sensor tag
                hc08Perripheral = peripheral
                hc08Perripheral!.delegate = self
                
                // Request a connection to the peripheral
                hc08CentralManager.connect(hc08Perripheral!, options: nil)
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("**** SUCCESSFULLY CONNECTED TO HC-08!!!")
        
        // Now that we've successfully connected to the SensorTag, let's discover the services.
        // - NOTE:  we pass nil here to request ALL services be discovered.
        //          If there was a subset of services we were interested in, we could pass the UUIDs here.
        //          Doing so saves battery life and saves time.
        peripheral.discoverServices(nil)
    }
    
    //MARK: - CBPeripheralDelegate methods
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if error != nil {
            print("ERROR DISCOVERING SERVICES: \(String(describing: error?.localizedDescription))")
            return
        }
        
        // Core Bluetooth creates an array of CBService objects —- one for each service that is discovered on the peripheral.
        if let services = peripheral.services {
            for service in services {
                print("Discovered service \(service)")
//                // If we found either the temperature or the humidity service, discover the characteristics for those services.
                if (service.uuid == CBUUID(string: SERVICEUUID)) {
                    peripheral.discoverCharacteristics(nil, for: service)
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if error != nil {
            print("ERROR DISCOVERING CHARACTERISTICS: \(String(describing: error?.localizedDescription))")
            return
        }
        
        if let characteristics = service.characteristics {
            let commandString = "led_on"
            let command = commandString.data(using: .utf8)
            
            for characteristic in characteristics {
                // Temperature Data Characteristic
                print("Discovered characteristic \(characteristic)")

                if characteristic.uuid == CBUUID(string: CHARACTERISTIC) {
                    // Enable the IR Temperature Sensor notifications
                    hc08Characteristic = characteristic
//                    hc08Perripheral?.setNotifyValue(true, for: hc08Characteristic!)
                    hc08Perripheral?.writeValue(command!, for: hc08Characteristic!, type: .withoutResponse)

                }
//
//                // Temperature Configuration Characteristic
//                if characteristic.UUID == CBUUID(string: Device.TemperatureConfig) {
//                    // Enable IR Temperature Sensor
//                    sensorTag?.writeValue(enableBytes, forCharacteristic: characteristic, type: .WithResponse)
//                }
//
//                if characteristic.UUID == CBUUID(string: Device.HumidityDataUUID) {
//                    // Enable Humidity Sensor notifications
//                    humidityCharacteristic = characteristic
//                    sensorTag?.setNotifyValue(true, forCharacteristic: characteristic)
//                }
//
//                if characteristic.UUID == CBUUID(string: Device.HumidityConfig) {
//                    // Enable Humidity Temperature Sensor
//                    sensorTag?.writeValue(enableBytes, forCharacteristic: characteristic, type: .WithResponse)
//                }
            }
        }
    }
    
}

