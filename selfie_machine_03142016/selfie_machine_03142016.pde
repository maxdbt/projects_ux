import de.looksgood.ani.*;
import de.looksgood.ani.easing.*;
import processing.video.*; 
import processing.serial.*; 
import java.io.File;

Capture cam;  //fotocamera
Serial porta; // Create object from Serial class
String val ="";    // Data received from the serial port

/*creo un timer per il timeout*/
int timeOut = 30000; // timeOut che regola lo stato di standby
int tempoPassato;  // start + tempoCorrente 
int tempoCorrente; // nel setup è definito = millis();


/*il timer regola lo stato standby. 
Attivo il timer nelle seguenti funzioni:
- dopo preview live (se non c'è contatto per 3 minuti, torna a standby = true)
dopo lo scatto --- mostra preview --- se non c'è interazione per 1 minuto
(ti piace/non ti piace) torna a standby = true)*/

//creo lo stato di standby
boolean standby = true;
boolean showPreviewState = false, shotState=false, showPicState=false, savedState=false;

PImage bg;// background image

PImage button;// button variables

PImage miPiace;// bottone "mi piace"

PImage nonMiPiace;// bottone "non mi piace"

PImage domanda;  //domanda "Ti piace?"

PImage sfondoSalvata; // sfondo 
PImage salvata;  // testo img salvata 

PImage lastPic;//ultima foto scattata
PImage savedPic; // foto da salvare nella directory
PImage[] photoList; //array delle foto contenute nella directory

PImage resized;// foto resized

float transparency = 255;// fade foto
PImage showImage; //mostra l'immagine

int x1 = 535;// position x bottone start
int y1 = 590;// posiione y borronw atart

int buttonLikeUpX = 320, buttonLikeUpY = 590;

int buttonLikeDownX = 842, buttonLikeDownY = 590;

// button width & height
int bW;//start
int bH;//start
int nW;//NONMIPIACE
int nH;//NONMIPIACE
int mH;//MIPIACE
int mW;//MIPIACE

String nomeFile;//nome del file salvato
PImage file;
int numFrames = 12;  // The number of frames in the animation
int currentFrame = 0;//contatore frame
PImage[] images = new PImage[numFrames];//file raw dell'immagine



void setup() 
{ 
  
  bg = loadImage("sfondo.png");
  button = loadImage ("bottone.png");
  miPiace = loadImage ("MiPiace.png");
  nonMiPiace = loadImage ("nonMiPiace.png");
  domanda = loadImage ("domanda.png");
  salvata = loadImage("salvata.png");
  sfondoSalvata = loadImage("sfondo_salvata.png");
    
  String portName = Serial.list() [1]; //porta arduino
  porta = new Serial (this, portName, 9600);//porta arduino
  
  size(1280, 720);//ampiezza dello schermo
    
  cam = new Capture(this, 1280, 720, 30);
  cam.start(); 
  
  
  bW  = button.width;
  bH  = button.height;
  nW  = nonMiPiace.width;
  nH  = nonMiPiace.height;
  
  File dir = new File("/Users/dasic2/Documents/Processing/selfie_machine_03142016/documenti");
  lastPic = createImage(10, 10, ARGB);
  frameRate(24);
  Ani.init(this);//fADEIN-FADEOUT
} 


void draw()//metodo che scatta la foto
{
  //println(standby);
  if (standby)//se è in standby
  {
    showMainMenu();//mostra il menù inziale
  } else {
    println("non è in standby");
    showPreview();// mostra la preview
    if(showPreviewState) //se è mostrata la preview
      {
        shot();//scatta la foto
        if(shotState)//se si è scattata la foto
         {
            showPic();//mostra la foto
            if(showPicState)//
            {
             showLikeOrNoLike();
             if(savedState)
            {
              //textSize(32);
              image(sfondoSalvata, 0, 0);
              image(salvata, 100, 500);
              //text("foto salvata!", 12, 45, -30);  // Specify a z-axis value
              //text("word", 12, 60);
              delay(2000);
              //standby = true;
            }
            }
//            if(savedState)
//            {
//              //textSize(32);
//              image(sfondoSalvata, 0, 0);
//              image(salvata, 100, 500);
//              //text("foto salvata!", 12, 45, -30);  // Specify a z-axis value
//              //text("word", 12, 60);
//              delay(2000);
//              //standby = true;
//            }
         }  
      }
   }
//   else
//   {
//     standby = !standby; //ritorna in standby
//   }
}  
  
void showMainMenu()//mostra il menù principale
{
  println("sono in mainmenu");
  background(bg);//setta il background
  image(button, x1, y1);//mostra il bottone
  photoSlider();//mostra la galleria delle foto
}




void mousePressed()
{
  
   //println("premuto");
  if (mouseX >= x1 && mouseX <= x1+bW && mouseY > y1 && mouseY < y1+bH)//se viene premuto il bottone start
  { 
    // fai partire il sistema;
     standby = !standby; //setta lo standby a FALSE
     showPreview(); 
     //tempoCorrente = millis(); //conta i millisecondi
     println("ho premuto start");  
  }   
  
  
  if(mouseX >= buttonLikeDownX && mouseX <= buttonLikeDownX+nW && mouseY > buttonLikeDownY && mouseY < buttonLikeDownY+nH)
  { 
    showPreviewState=true;
    resetSystem();
  }
  
  if (mouseX >= buttonLikeUpX && mouseX <= buttonLikeUpX+mW && mouseY > buttonLikeUpY && mouseY < buttonLikeUpY+mH)
  {
    println("mipiace, foto salvata"); 
    //image(bg, 0, 0);
   
    lastPic.save("/Users/dasic2/Documents/Processing/selfie_machine_03142016/documenti/"+nomeFile+".jpg");
    savedState = true;
    
    
    //resetSystem();
//    image(sfondoSalvata, 0, 0);
//    image(salvata, 100, 500);
    
  }
}

void showPreview()
{
  
  if(!shotState){
    if (cam.available()) { 
    // Reads the new frame
    cam.read(); 
    }else{
     cam.start();  
    }
    image(cam, 0, 0);   //         L I V E   P R E V I E W
    showPreviewState = true;   //         L I V E   P R E V I E W
    println("sono nella preview");
  }else{
    background(bg);//setta il background
  }
  
  
} 
  


void shot()
{
      // comunica con Arduino 
      //se la porta è disponibile, leggi il valore che manda
      if (porta.available() > 0 && standby == false)
      {
        val = porta.readStringUntil('\n');
        println("Sono nell'if dello shot");
      }
    
      // se c'è contatto entro il timeout, fai foto, altrimento torna a standby
      if(val!=null){
        val=trim(val);
       println(val);
       if ("start".equals(val))
       {
        //println("val--------------->: "+val);
        //val=""; 
        int year = year();
        int month = month();
        int day = day();
        int hour = hour();
        int minute = minute();
        int second = second();
        nomeFile = year+"-"+month+"-"+day+"-"+hour+"-"+minute+"-"+second; //creo il nome file
        println(nomeFile);
        lastPic.copy(cam, 0, 0, cam.width, cam.height, 0, 0, lastPic.width, lastPic.height);
        //saveFrame("/Users/dasic2/Documents/Processing/selfie_machine_03142016/documenti/"+nomeFile+".jpg");
        cam.stop();
        shotState = true;
      }
      }
      
}


void showPic()
{
        
        //lastPic.copy(cam, 0, 0, cam.width, cam.height, 100, 100, 1080, 520);
        println("ho la foto");
        lastPic.resize(640, 360);
        image(lastPic, 320, 200, 640, 360); 
        showPicState = true;  
        println(lastPic.width, lastPic.height);
}    


void showLikeOrNoLike()//mostra la preview dell'immagine con mi piace o non mi piace
{
//  miPiace.resize(155, 120); 
  domanda.resize(295, 100);
  image(domanda, 495, 600);
  image(miPiace, buttonLikeUpX, buttonLikeUpY);
  image(nonMiPiace, buttonLikeDownX, buttonLikeDownY);
  
}

public void Like(int theValue) {
  println("foto salvata!");
  savedState = true;
  image(sfondoSalvata, 0, 0);
  image(salvata, 50, 50);
}

public void Unlike(int theValue) {
  println("Unlike");
  //standby = true;
  resetSystem();
}

void debugState()
{
        println("standby value: " + standby);
        println("showPreviewState value: " + showPreviewState);
        println("shotState value: " + shotState);
        println("showPicState value: " + showPicState);
  
}

void photoSlider()
{

  File dir = new File("/Users/dasic2/Documents/Processing/selfie_machine_03142016/documenti");
  String[] list = dir.list(); //image File names

  photoList = new PImage[list.length];

 
  for(int i = list.length-1; i> 0; i--)
  {
   photoList[i] = loadImage("documenti/"+list[i]);
   photoList[i].resize(640, 360); 
  } 
  // manca il fade in/out delle foto
  //Ani.to(this, 0.5, "photoList[i]", 255);
  int index = frameCount % list.length;
  println(index);
  if(index == 0) index = 1;
  image(photoList[index], 320, 200, 640, 360);   
  
}


void resetSystem(){
  showPreviewState = false;
  shotState=false;
  showPicState=false;
  savedState=false;
}
