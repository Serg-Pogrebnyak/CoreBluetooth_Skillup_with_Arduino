#include <BLEDevice.h>
#include <BLECharacteristic.h>
#include <BLEServer.h>
#include "DHT.h"

#define DHTPIN 14

#define SERVICE_UUID_FOR_WRITE        "6e400001-b5a3-f393-e0a9-e50e24dcca9e"
#define CHARACTERISTIC_UUID_FOR_WRITE "6e400003-b5a3-f393-e0a9-e50e24dcca9e"
#define SERVICE_UUID_FOR_READ         "6e400002-b5a3-f393-e0a9-e50e24dcca9e"
#define CHARACTERISTIC_UUID_FOR_READ  "6e400004-b5a3-f393-e0a9-e50e24dcca9e"
BLECharacteristic *pCharacteristicStatus;
DHT dht(DHTPIN, DHT11);
float oldTemperature = 0.0;

void setup() {
  Serial.begin(115200);
  setupBluetooth();
  dht.begin();
}

void loop() {
  float t = dht.readTemperature();
  if (isnan(t)) {
    Serial.println("ошибка считывания данных");
  } else {
    if (abs(oldTemperature - t)> 0.1) {
      Serial.println(t);
      pCharacteristicStatus->setValue(String(t).c_str());
      pCharacteristicStatus->notify();
      oldTemperature = t;
    }
  }
}

void setupBluetooth() {
  BLEDevice::init("ESP32");
  BLEServer *pServer = BLEDevice::createServer();

  BLEService *pService = pServer->createService(SERVICE_UUID_FOR_WRITE);
  BLECharacteristic *pCharacteristic = pService->createCharacteristic(CHARACTERISTIC_UUID_FOR_WRITE, BLECharacteristic::PROPERTY_WRITE);
  pCharacteristic->setWriteNoResponseProperty(true); // false - with response, true - without //write with response or without
  pService->start();

  BLEService *pServiceStatus = pServer->createService(SERVICE_UUID_FOR_READ);
  pCharacteristicStatus = pServiceStatus->createCharacteristic(CHARACTERISTIC_UUID_FOR_READ, BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY);
  pCharacteristicStatus->setWriteNoResponseProperty(true); // false - with response, true - without //write with response or without
  pServiceStatus->start();

  BLEAdvertising *pAdvertising = pServer->getAdvertising();
  pAdvertising->setMinPreferred(0x06);
  pAdvertising->addServiceUUID(SERVICE_UUID_FOR_WRITE);
  pAdvertising->addServiceUUID(SERVICE_UUID_FOR_READ);
  pAdvertising->start();
}
