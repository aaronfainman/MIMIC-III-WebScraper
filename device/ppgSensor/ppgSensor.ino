#include <Wire.h>
#include "MAX30105.h"
#include <math.h>

MAX30105 particleSensor; // initialize MAX30102 with I2C

bool found = false;
int instr = 0;
double t0 = 0;

void setup() {
  // put your setup code here, to run once:
  int baudRate = 19200;
  Serial.begin(baudRate);
  while(!Serial); //We must wait for Serial to come online
  delay(1000);
  
  // Initialize sensor
  if (particleSensor.begin(Wire, I2C_SPEED_FAST) == false) //Use default I2C port, 400kHz speed
  {
    Serial.println("Initialisation unsuccessful.");
    while (1);
  }

  byte ledBrightness = 128; //Options: 0=Off to 255=50mA
  byte sampleAverage = 1; //Options: 1, 2, 4, 8, 16, 32
  byte ledMode = 2; //Options: 1 = Red only, 2 = Red + IR, 3 = Red + IR + Green
  int sampleRate = 50; //Options: 50, 100, 200, 400, 800, 1000, 1600, 3200
  int pulseWidth = 69; //Options: 69, 118, 215, 411
  int adcRange = 16384; //Options: 2048, 4096, 8192, 16384

  particleSensor.setup(ledBrightness, sampleAverage, ledMode, sampleRate, pulseWidth, adcRange);
  // Send initial handshake
  Serial.println("Initialisation successful.");

  while (!found)
  {
    if (Serial.available() > 0)
    {
      instr = Serial.read();
      found = true;
      t0 = millis();
    }
  }
}

void loop() {
  particleSensor.check(); 
  // put your main code here, to run repeatedly:
  if ((instr == 1) && (particleSensor.available()))
  {
      // read stored IR
      Serial.print(millis() - t0, 6);
      Serial.print(" ");
      
      Serial.print(particleSensor.getFIFORed());
      Serial.print(" ");
      
      // read stored red
      Serial.println(particleSensor.getFIFOIR());
      // read next set of samples
      
      particleSensor.nextSample();
  }
}
