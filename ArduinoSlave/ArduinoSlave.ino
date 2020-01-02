#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEServer.h>

#define SERVICE_UUID        "6e400001-b5a3-f393-e0a9-e50e24dcca9e"
#define CHARACTERISTIC_UUID "6e400002-b5a3-f393-e0a9-e50e24dcca9e"

void switchLedStatus(String text) {
  if (text == "on") {
    digitalWrite(LED_BUILTIN, HIGH);
  } else if (text == "off") {
    digitalWrite(LED_BUILTIN, LOW);
  } else {
    Serial.println("got wrong data");
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

  BLEService *pService = pServer->createService(SERVICE_UUID);

  BLECharacteristic *pCharacteristic = pService->createCharacteristic(CHARACTERISTIC_UUID, BLECharacteristic::PROPERTY_WRITE);
  pCharacteristic->setCallbacks(new MyCallbacks());
  pCharacteristic->setWriteNoResponseProperty(true); // false - with response, true - without //write with response or without
  pService->start();

  BLEAdvertising *pAdvertising = pServer->getAdvertising();
  pAdvertising->setMinPreferred(0x06);
  pAdvertising->start();
}
