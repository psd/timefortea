

volatile uint8_t count = 0;
ISR(ANALOG_COMP_vect) {
  ++count; // counts up and down transitions
}

//Moving coil meter control

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
static long lastTime;

  cli();
  if (count >= 100) {
    long now = micros();
    count -= 100;
    sei();

    if (lastTime != 0) {
      long millihz = long(50e9 / (now - lastTime));
      Serial.print(now);
      Serial.print(" microseconds ");
      Serial.print(millihz/1000);
      Serial.print('.');
      Serial.print((millihz/100) % 10, DEC);
      Serial.print((millihz/10) % 10, DEC);
      Serial.print((millihz) % 10, DEC);
      Serial.print(" Hz ");
      if (millihz >= 50000)
        Serial.print('+');
      Serial.print((millihz - 50000) * 0.002);
      Serial.println(" % ");

      if (millihz > 50250)
        millihz = 50250;
      if (millihz < 49750)
        millihz = 49750;
      if (millihz >= 50000)
        sendPositive(millihz - 50000);
      else
        sendNegative(50000 - millihz);
    }

    lastTime = now;
  } 
  else
    sei();
}

