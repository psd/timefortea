volatile uint8_t count = 0;
ISR(ANALOG_COMP_vect) {
  ++count; // counts up and down transitions
}

// Moving coil meter control
int meterPin1 =  5;    // meter wire connected to digital pin 5
int meterPin2 =  3;    // meter wire connected to digital pin 3

void sendPositive(int voltage) {
  digitalWrite(meterPin2, LOW);    // set the Pin meterPin2 LOW
  analogWrite(meterPin1, voltage); //
}

void sendNegative(int voltage){
  digitalWrite(meterPin1, LOW);    // set the Pin meterPin1 LOW
  analogWrite(meterPin2, voltage); //
}

void printLog(unsigned long now, unsigned long millihz) {
  Serial.print(now);
  Serial.print(" microseconds ");
  Serial.print(millihz/1000);
  Serial.print('.');
  Serial.print((millihz/100) % 10, DEC);
  Serial.print((millihz/10) % 10, DEC);
  Serial.print((millihz) % 10, DEC);
  Serial.print(" Hz ");
  if (millihz >= 50000UL)
    Serial.print('+');
  Serial.print((millihz - 50000UL) * 0.002);
  Serial.println(" % ");
}

void setup() {
  Serial.begin(57600);
  Serial.println("\n[hertz]");

  // compare against 1.1v reference
  ACSR = _BV(ACBG) | _BV(ACI) | _BV(ACIE);

  // use MUX to select AIO port 1
  ADCSRA &= ~ bit(ADEN);
  ADCSRB |= bit(ACME);
  ADMUX = 0;

  // initialize the digital pins as an output:
  pinMode(meterPin1, OUTPUT);
  pinMode(meterPin2, OUTPUT);

}

void loop() {
  unsigned long lastTime;
  unsigned long now;
  unsigned long interval;
  uint8_t ccount;
  unsigned long millihz;
  //unsigned long mainz = 5000000000UL;
    unsigned long mainz = 500000000UL;

  cli();
  now = micros();
  ccount = count;
  if (count >= 100)
    count -= 100;
  sei();

  if (ccount >= 100) {
    if (lastTime > 0 && lastTime < now) {
      interval = now - lastTime;
      millihz = mainz / (interval / 10UL);

      printLog(now, millihz);

      if (millihz > 50250UL)
        millihz = 50250UL;
      if (millihz < 49750UL)
        millihz = 49750UL;

      if (millihz >= 50000UL)
        sendPositive(millihz - 50000UL);
      else
        sendNegative(50000UL - millihz);
    }
    lastTime = now;
  }
}

