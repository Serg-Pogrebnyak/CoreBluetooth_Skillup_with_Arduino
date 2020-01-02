#include <BLEDevice.h>
#include <BLECharacteristic.h>
#include <BLEServer.h>

#define SERVICE_UUID_FOR_WRITE        "6e400001-b5a3-f393-e0a9-e50e24dcca9e"
#define CHARACTERISTIC_UUID_FOR_WRITE "6e400003-b5a3-f393-e0a9-e50e24dcca9e"
#define SERVICE_UUID_FOR_READ         "6e400002-b5a3-f393-e0a9-e50e24dcca9e"
#define CHARACTERISTIC_UUID_FOR_READ  "6e400004-b5a3-f393-e0a9-e50e24dcca9e"
BLECharacteristic *pCharacteristicStatus;
bool work = false;

class MyCallbacks: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic) {
      std::string value = pCharacteristic->getValue();

      Serial.println("Got data: ");
      Serial.println(value.c_str());

      if (value == "on") {
        work = true;
      } else if (value == "off") {
        work = false;
      } else {
        Serial.println("got wrong data");
      }
    }
};

void digitalChangeStatus() {
  if (digitalRead(LED_BUILTIN) == HIGH) {
    digitalWrite(LED_BUILTIN, LOW);
    pCharacteristicStatus->setValue("off");
    pCharacteristicStatus->notify();
  } else {
    digitalWrite(LED_BUILTIN, HIGH);
    pCharacteristicStatus->setValue("on");
    pCharacteristicStatus->notify();
  }
}

void setup() {
  Serial.begin(115200);
  pinMode(LED_BUILTIN, OUTPUT);
  setupBluetooth();
}

void loop() {
  if (work) {
    digitalChangeStatus();
    delay(random(1000, 10000));
  }
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
