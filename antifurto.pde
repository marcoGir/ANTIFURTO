import processing.serial.*;
import processing.net.*;
import cc.arduino.*;
import org.firmata.*;

Arduino arduino;
Server s;

void setup(){
  size(200,100);
  println(Arduino.list());
  arduino = new Arduino(this, Arduino.list()[2], 57600);//connessione ad arduino
  background(150,0,0);
  s = new Server(this, 32580); 
  arduino.pinMode(2,Arduino.INPUT);
  arduino.pinMode(5,Arduino.OUTPUT);
  arduino.digitalWrite(5,Arduino.HIGH);
  fill(255);
  textSize(20);
  text("antifurto attivo",20,60);
  
}

void draw(){
  if(arduino.digitalRead(2)==1)
    s.write("1");
  else
    s.write("0");
  delay(300);
}