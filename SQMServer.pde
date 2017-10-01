import processing.net.*;
import processing.serial.*;
import cc.arduino.*;
import org.firmata.*;


int screenX=900;
int screenY=500;

float longitude = 11.59;
float latitude = 45.66;    
int letture,mediaInvio,x=0,y,oldTime,day,fusoOrario,sommaText,lettura;
float somma,media,oldMedia=screenY,sunrise,sunset,mediaText;
boolean screenshot;
Arduino arduino;
Server s;
Client c;
int giorni;




boolean calcoloBisestile(int anno){ //calcolo se l' anno è bisestile per il calcolo del giornod ella settimana
  if((anno%4==0 && anno%100!=0) || anno%400==0)
     return true;
  else
  return false;
}

int giorniMese(int mese,int anno){ //calcolo dei giorni del mese considerato
  if(mese==8 || mese==3 || mese==5 ||mese==6 )             //se il mese ha 30 giorni (novembre,aprile, giugno, settembre)
     return 30;
     
  else if(mese==1){                                        //se il mese è febbraio
    if(calcoloBisestile(anno)==true)                           //se l' anno è bisestile
      return 29;
    else
      return 28;                                           //se l' anno non è bisestile
  }
  
  else                                                     //altrimenti il mese ha 31 giorni
  return 31;
}
  
     
int calcoloGiornoSettimana(int day){                            //restituisce 0 se è domenica
  int anno,mese;
  for(anno=2016;anno<year();anno++){
    if(calcoloBisestile(anno))
      giorni+=366;
    else
      giorni+=365;
  }
  for(mese=0;mese<month()-1;mese++)
    giorni+=giorniMese(mese,anno);
  giorni+=day;
  return giorni%7-3;
}



void calcoloFusoOrario(){//calcola il fuso orario: se il giorno corrente è fra l' ultima domenica di marzo o la terza di ottobre fuso orario =2
  int dayMarch=25,dayOctober=15;
  
  while(calcoloGiornoSettimana(dayMarch)!=0)
    dayMarch++;
  while(calcoloGiornoSettimana(dayOctober)!=0);
    dayOctober++;
    
  if((month()==3 && day()>=dayOctober) || (month()>3 && month()<10) || (month()==10 && day()<=dayOctober))
     fusoOrario=2;
  else 
     fusoOrario=1;
     
  println("fuso orario: "+fusoOrario);
}



float calcoloOrarioAlbaTramonto(boolean sunrise){ //calcola gli orari locali di alba e tramonto in base a latitudine, longitudine, giorno, mese, anno, fuso orario

    float zenith = 90.83333333333333;
    float D2R = PI / 180;
    float R2D = 180 /PI;
    float M,L,RA,Lquadrant,RAquadrant,sinDec,cosDec,cosH,UT,localT,T,N1,N2,N3,N,lnHour,t;
 
    lnHour = longitude / 15;
    N1= int(275*month()/9);
    N2= int((month()+9)/12);
    N3 = (1+int((year()-4*int(year()/4)+2)/3));
    N = N1-(N2*N3)+day()-30;
    if (sunrise) {
        t = N + ((6 - lnHour) / 24);
    } else {
        t = N + ((18 - lnHour) / 24);
    };
    M = (0.9856 * t) - 3.289;
    L = M + (1.916 * sin(M * D2R)) + (0.020 * sin(2 * M * D2R)) + 282.634;
    if (L > 360) {
        L = L - 360;
    } else if (L < 0) {
        L = L + 360;
    };
    RA = R2D * atan(0.91764 * tan(L * D2R));
    if (RA > 360) {
        RA = RA - 360;
    } else if (RA < 0) {
        RA = RA + 360;
    };
    Lquadrant = (floor(L / (90))) * 90;
    RAquadrant = (floor(RA / 90)) * 90;
    RA = RA + (Lquadrant - RAquadrant);
    RA = RA / 15;
    sinDec = 0.39782 * sin(L * D2R);
    cosDec = cos(asin(sinDec));
    cosH = (cos(zenith * D2R) - (sinDec * sin(latitude * D2R))) / (cosDec * cos(latitude * D2R));
    float H;
    if (sunrise) {
        H = 360 - R2D * acos(cosH);
    } else {
        H = R2D * acos(cosH);
    };
    H = H / 15;
    T = H + RA - (0.06571 * t) - 6.622;
    UT = T - lnHour;
    if (UT > 24) {
        UT = UT - 24;
    } else if (UT < 0) {
        UT = UT + 24;
    }
    calcoloFusoOrario();
    localT = UT + fusoOrario;
    return localT;
}




void azzeramentoGrafico(){
        text(day()+"/"+month()+"/"+year(),screenX-100,30); //scrive a schermo la data di acquisizione
        //saveFrame("SQM-##.png");      //salva immagine
        background(150,0,0);          //azzera schermata
        while(y<screenY){             //ridisegna le linee di riferimento e valori
           stroke(0);
           line(0,y,screenX,y);
           fill(255);
           textSize(11);
           text(int(1000-map(y,0,screenY,0,1000)),screenX-25,y); //scrive i valori corrispondenti alle linee di riferimento
           y=y+50;
       }
       x=0;                          //azzera le variabili utilizzate dal ciclo
       y=0;
}




void lettura(){
    sommaText=0;
    if(x>screenX-35)             //se termina lo spaziondisponibile nella schermata salva uno screenshot e azzera la schermata
       azzeramentoGrafico();
    for(letture=0;letture<100;letture++){              //esegue 30 letture
       lettura=arduino.analogRead(0);
       sommaText+=lettura;
       somma+=map(lettura,100,1023,120,screenY);            
       delay(10);
     }
     println("sommaT: "+sommaText);
     mediaText=sommaText/100;         //salva una media da stampare a schermo (mi serve per tararlo, in questo modo vedo direttamente il valore letto dall' arduino e non un valore mappato)
     media=somma/100;                 //media le letture
     
     //DISEGNO GRAFICO
     fill(0);
     if(oldMedia>media){    //disegna il grafico attraverso un rettangolo ed un triangolo che ne smussa la parte alta dando l' effetto curva 
       triangle(x,screenY-oldMedia,x,screenY-media,x+10,screenY-media);
       rect(x,screenY,10,-int(media));
     }
     else if(oldMedia<media){
       triangle(x,screenY-oldMedia,x+10,screenY-oldMedia,x+10,screenY-media);
       rect(x,screenY,10,-int(oldMedia));
     }
     else
       rect(x,screenY,10,-int(oldMedia));
       
     oldMedia=media;
     fill(255);
     rotate(-PI/2);
     translate(-screenY,x+9);
     fill(255);
     textSize(9);
     text(nf(hour(),2)+":"+nf(minute(),2)+"   "+nf(sommaText,4,4),0,0); //scrive alla base della barra ora e valore letto
     x=x+10;  //avanzamento per la lettura successiva
     s.write(str(sommaText));            //invio dati a client
     println("mediaText"+mediaText+"    media"+media);
     somma=0;                         //azzera la somma
     sommaText=0;
     delay(300000);
}





void setup(){
  size(900,500);
  println(Arduino.list());
  arduino = new Arduino(this, Arduino.list()[3], 57600);//connessione ad arduino
  background(150,0,0);
  while(y<screenY){ //crea il grafico per la prima volta
    stroke(0);
    line(0,y,screenX,y);
    fill(255);
    textSize(11);
    text(int(1000-map(y,0,screenY,0,1000)),screenX-25,y);
    y=y+50;
  }
  y=0;
  s = new Server(this, 12345); //apre server per l' altro sketch processing per visualizzare da remoto le letture
  day=day();
  sunrise=calcoloOrarioAlbaTramonto(true);
  sunset=calcoloOrarioAlbaTramonto(false);
}

void draw(){
     if(day!=day()&& hour()>3){ //se cambia giorno esegue i calcoli di orario di alba e tramonto e segnala di dover ancora riprendere lo screenshot all' alba
       calcoloFusoOrario();
       sunrise=calcoloOrarioAlbaTramonto(true);
       sunset=calcoloOrarioAlbaTramonto(false);
       screenshot=false;
       day=day();
     }
     
     if((hour()==int(sunset)+1) && (minute()>int((sunset-int(sunset))*60)) || (hour()>int(sunset)+1)  ||  (hour()==int(sunrise)-1) &&  (minute()<int((sunrise-int(sunrise))*60)) || (hour()<int(sunrise)+1)){ //verifica di trovarsi fra gli orari di tramonto e di alba
       println("lettura delle ore: ",hour(),":",minute(),"    alba ",int(sunrise),":",int((sunrise-int(sunrise))*60),"    tramonto ",int(sunset),":",int((sunset-int(sunset))*60));
       lettura();
     }
     else if(screenshot==false){ //prima di fermare le letture ed azzerare il grafico all' alba ne acquisisce uno screenshot
       azzeramentoGrafico();
       screenshot=true;
     }
     delay(1000);
}