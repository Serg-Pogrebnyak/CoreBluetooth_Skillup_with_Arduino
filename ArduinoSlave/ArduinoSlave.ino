#include <BLEDevice.h>
#include <BLECharacteristic.h>
#include <BLEServer.h>

#define SERVICE_UUID_FOR_WRITE        "6e400001-b5a3-f393-e0a9-e50e24dcca9e"
#define CHARACTERISTIC_UUID_FOR_WRITE "6e400003-b5a3-f393-e0a9-e50e24dcca9e"
#define SERVICE_UUID_FOR_READ         "6e400002-b5a3-f393-e0a9-e50e24dcca9e"
#define CHARACTERISTIC_UUID_FOR_READ  "6e400004-b5a3-f393-e0a9-e50e24dcca9e"
BLECharacteristic *pCharacteristicStatus;

void switchLedStatus(String text) {
  if (text == "on") {
    digitalWrite(LED_BUILTIN, HIGH);
    pCharacteristicStatus->setValue(text.c_str());
    pCharacteristicStatus->notify();
  } else if (text == "off") {
    digitalWrite(LED_BUILTIN, LOW);
    pCharacteristicStatus->setValue(text.c_str());
    pCharacteristicStatus->notify();
  } else {
    Serial.println("got wrong data");
    pCharacteristicStatus->setValue("Wrong data");
    pCharacteristicStatus->notify();
  }
}

class MyCallbacks: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic) {
      std::string value = pCharacteristic->getValue();

      Serial.println("");
      Serial.println("Got data: ");
      Serial.print(value.c_str());

      switchLedStatus(value.c_str());
    }
};

void setup() {
  Serial.begin(115200);
  pinMode(LED_BUILTIN, OUTPUT);
  setupBluetooth();
}

void loop() {
  
}

void setupBluetooth() {
  BLEDevice::init("ESP32");
  BLEServer *pServer = BLEDevice::createServer();

  BLEService *pService = pServer->createService(SERVICE_UUID_FOR_WRITE);
  BLECharacteristic *pCharacteristic = pService->createCharacteristic(CHARACTERISTIC_UUID_FOR_WRITE, BLECharacteristic::PROPERTY_WRITE);
  pCharacteristic->setCallbacks(new MyCallbacks());
  pCharacteristic->setWriteNoResponseProperty(true); // false - with response, true - without //write with response or without
  pService->start();

  BLEService *pServiceStatus = pServer->createService(SERVICE_UUID_FOR_READ);
  pCharacteristicStatus = pServiceStatus->createCharacteristic(CHARACTERISTIC_UUID_FOR_READ, BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY);
  pCharacteristicStatus->setWriteNoResponseProperty(true); // false - with response, true - without //write with response or without
  pServiceStatus->start();

  BLEAdvertising *pAdvertising = pServer->getAdvertising();
  pAdvertising->setMinPreferred(0x06);
  pAdvertising->start();
}
