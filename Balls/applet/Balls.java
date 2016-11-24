import processing.core.*; 
import processing.xml.*; 

import processing.pdf.*; 
import processing.video.*; 

import java.applet.*; 
import java.awt.Dimension; 
import java.awt.Frame; 
import java.awt.event.MouseEvent; 
import java.awt.event.KeyEvent; 
import java.awt.event.FocusEvent; 
import java.awt.Image; 
import java.io.*; 
import java.net.*; 
import java.text.*; 
import java.util.*; 
import java.util.zip.*; 
import java.util.regex.*; 

public class Balls extends PApplet {

/*
Written by Kelly Michael Smith.
Organization: NASA Johnson Space Center : Descent Analysis (DM42)
Created in July 2011.
Last modified on August 31, 2011.

This program executes a physical simulation of a network of nodes to find a decluttered visual arrangement.
   * Nodes connected to each other exert spring forces on each other.
   * Nodes not connected to each other exert repulsive forces upon one another 
      (within some radius of influence).
   
   This simulation implicitly seeks to minimize the global strain energy in the network.
   There is no explicit optimization occurring in this program.

   Once converged, the simulation will provide "de-cluttered" views of the network.
   
   In the event that the network of nodes gets "stuck" in a local minima, the user
   can RIGHT-CLICK to release an explosive force to "jolt" the system out of the local minima.
   
   MOUSE CONTROLS:
     How to Select Nodes:
       Individual Node Selection
       * An individual node may be selected by simply clicking on the node.  It will change its outline to a thick red outline to show that it is selected.
       
       Multiple Node Selection
       * Left-click and drag to draw a lasso around the nodes you would like to select.
       
     * Clicking left-button and holding will "lasso" nodes.
     * Nodes selected via lasso method can all be moved by clicking into the lasso area and dragging
        with the left-mouse button.  All of the nodes will move as the mouse moves.
     *

     * RIGHT-CLICK: releases explosive force to jolt the system.
   
   KEYBOARD CONTROLS:
     * d : resumes the simulation
     * f : pauses the simulation
     * c : clears the selection

*/



ArrayList<Ball> balls;
ArrayList<PVector> mousePositions;
float framerate;
boolean optimizing;
boolean drawing;
ArrayList<Ball> selectedBalls;
float lastRunTime;
float totalVel;
PVector anchor;
boolean dragging;
ArrayList<PVector> preDragBallPositions;
ArrayList<PVector> preDragShapePositions;
boolean record;
PFont font;
GraphReader gr;
boolean displayPDFMessage;
float PDF_Message_Countdown;
// MovieMaker mm;

public void setup() {
  // noLoop();
  
  // size(round(displayWidth*0.9),round(displayHeight*0.9));
  size(round(screen.width*0.9f),round(screen.height*0.9f));
  font = createFont("Arial",12);
  background(0);
  record = false;
  framerate = 60;
  smooth();
  
  /* Not going to use this movie export for now.
  mm = new MovieMaker(this,width,height,"graph2.mov",30,MovieMaker.JPEG,MovieMaker.HIGH);
  */
  frameRate(round(framerate));
  selectedBalls = new ArrayList();
  lastRunTime = millis();
  optimizing = true;
  
  displayPDFMessage = false;
  
  gr = new GraphReader();
  gr.selectFile();
  if (gr.filename==null) {
    exit();
  } else {
    gr.buildGraph();
    balls = gr.getGraph();
    PDF_Message_Countdown = 0;
    
    
    dragging = false;
    mousePositions = new ArrayList<PVector>();
    preDragBallPositions = new ArrayList<PVector>();
    preDragShapePositions = new ArrayList<PVector>();
    println("Finished initialization");
  }
}

public void draw() {
  println("Optimizing = " + optimizing);
  background(0);
  
  /* Done */
  println("Eval sim triggers");
  evaluateSimulationTriggers();
  
  /* Done */
  println("Managing keyboard input");
  manageKeyboardInput();
  
  /* Done */
  println("Drawing selection boundaries");
  drawSelectionBoundaries();
  
  /* Done */
  println("Detecting hover");
  detectHover();
  
  /* Done */
  println("Displaying balls");
  displayBalls();
  
  println("displaying ball names");
  displayBallNames();
  
  /* Done */
  println("Drawing text overlays");
  drawTextOverlays();
  
  
  if (record) {
   endRecord(); 
  }
  
  //mm.addFrame();
  
}

public void displayBallNames() {
 for (Ball b: balls) {
  b.displayName();
 } 
}

public void mousePressed() {
  
  dragging = false;
  drawing = false;
  
  if (mouseButton == LEFT) {
    
    PVector mousePosition = new PVector(mouseX, mouseY);
    
    boolean clearFlag;
    if (keyPressed == true && key == CODED && keyCode == CONTROL) {
     clearFlag = false;
    } else {
     clearFlag = true;
    }
      
    
      
    
      boolean userClickingOnSelectedBall = false;
      for (Ball b : selectedBalls) {
        if (PVector.dist(mousePosition, b.position) <= b.ballSize) {
         userClickingOnSelectedBall = true; 
        }
      }
      
      boolean userClickingInLasso = false;
      if (mousePositions.size() > 0 && insidePolygon(mousePosition, mousePositions)) {
       userClickingInLasso = true; 
      }
      
      // Test: Is the user clicking on a previously selected ball or clicking within the lasso?
      if (userClickingOnSelectedBall || userClickingInLasso) {
        dragging = true;
        anchor = new PVector(mouseX, mouseY);
      } else {
       
        // We are not clicking within the selection area or on a previously selected ball.
        
        // What we could be doing at this point:
        // 1) doing a CTRL+SELECT to select additional points
        // 2) Not doing a CTRL+SELECT -> this would mean we would clear our selected balls
        
        if (clearFlag) {
         mousePositions.clear();
         for (Ball b: selectedBalls) {
          b.deSelect();
         } 
         selectedBalls.clear();
         preDragBallPositions.clear();
        }
        
        // Are we clicking on a node (after hovering over it)?
        boolean clickingOnABall = false;
        for (Ball b : balls) {
         if (PVector.dist(new PVector(mouseX,mouseY),b.position) <= b.ballSize) {
          selectedBalls.add(b);
          b.select();
          preDragBallPositions.add(new PVector(b.position.x, b.position.y));
          dragging = true;
          clickingOnABall = true;
         }
        }
        
        
        if (!clickingOnABall) {
          if (clearFlag) {
            for (Ball b: selectedBalls) {
              b.deSelect();
            }
            selectedBalls.clear();
          }
          mousePositions.clear();
          drawing = true;
        }
      }
   
    
  } else if (mouseButton == RIGHT) {
   explode();
   optimizing = true;
  }
  
}

public void mouseReleased() {
  println("Released Mouse");
  // DeSelect any currently selected balls, then clear the selectedBalls ArrayList.
  
  boolean isThereALasso = mousePositions.size() > 0;
  
  if ((dragging || drawing) && isThereALasso) {
    
    boolean clearFlag;
    if (keyPressed == true && key == CODED && keyCode == CONTROL) {
     clearFlag = false;
    } else {
     clearFlag = true;
    }
    
    if (clearFlag) {
    for (Ball b: selectedBalls) {
     println("Deselected " + b.name);
     b.deSelect(); 
    }
    selectedBalls.clear();
  
    preDragBallPositions.clear();
    }
    /* Detect if balls are in selection*/
    for (Ball b: balls) {
      if (insidePolygon(b.position, mousePositions)) {
        /* Yes, this ball is in the selection, so add it to selectedBalls */
        println(b.name + " is inside selection");
        selectedBalls.add(b);
        b.select();
        preDragBallPositions.add(new PVector(b.position.x, b.position.y));
      }
    }
  } else {
    preDragBallPositions.clear();
    for (Ball b : selectedBalls) {
      preDragBallPositions.add(new PVector(b.position.x, b.position.y));
    } 
    
  }
  
  drawing = false;
  dragging = false;
}

public void mouseDragged() {
  println("Dragging mouse");
  if (drawing == true) {
    mousePositions.add(new PVector(mouseX, mouseY));
  } else if (dragging == true) {
    mousePositions.clear();
    if (selectedBalls.size() == 1) {
      selectedBalls.get(0).position = new PVector(mouseX, mouseY);
    } else {
      for (int i = 0; i<selectedBalls.size(); i++) {
        Ball b = selectedBalls.get(i);
        PVector displacement = PVector.sub(new PVector(mouseX,mouseY),anchor);
        b.position = PVector.add(displacement, preDragBallPositions.get(i));
      }
    }
  }

}

public void displayBalls() {
  println("Displaying balls...");
  /* Update and Draw all of the balls */
  for (int i = 0; i < balls.size(); i++) {
    Ball b = (Ball) balls.get(i);

    if (optimizing && !selectedBalls.contains(b)) {
      b.update(framerate);  
      b.checkWalls(width, height);
    }
    b.display();
  }
}

public void drawSelectionBoundaries() {
  /* Draw the selection */
  if (mousePositions.size() > 0) {
    stroke(255); // Set line color to white
    
    /* If the user isn't currently drawing, then draw filled polygon */
    if (drawing == false || dragging == true) {
      fill(255,200,200,200);
      beginShape();
      for (int i= 0; i < mousePositions.size(); i++) {
        PVector thisPos = (PVector) mousePositions.get(i);
        vertex(thisPos.x,thisPos.y);
      }
      endShape(CLOSE);
    }
    
    /* Now draw the edges of the selection */
    for (int i = 0; i < mousePositions.size()-1; i++) {
      PVector thisPos = (PVector) mousePositions.get(i);
      PVector nextPos = (PVector) mousePositions.get(i+1);
      line(thisPos.x,thisPos.y,nextPos.x,nextPos.y);
    }
  }
}

public void manageKeyboardInput() {
  println("watching keyboard input");
  /* KEYBOARD COMMANDS */
  if (keyPressed) {
    
    /* Toggle between enabling/disabling the node dynamics */
    if (key == 'd') {
      optimizing = true;
    } else if (key == 'f') {
     optimizing = false; 
    }
    
    
    
    /* Commented out for the LOLz */
    
    if (key == 'p') {
      String pdfName = gr.filename.substring(0,gr.filename.length()-4) + ".pdf";
      displayPDFMessage = true;
      PDF_Message_Countdown = frameRate*2.5f;
      println("Created PDF @ " + pdfName);
      
      
      
     beginRecord(PDF,pdfName);
     textFont(font);
     record = true;
     background(0);
    }
    

    /* Clear the selection */
    if (key == 'c') {
        for (Ball b: selectedBalls) {
         b.deSelect(); 
        }
        selectedBalls.clear();
        mousePositions.clear();
    }
    
    /* Increase equilibrium distance */
    float eqDistanceUpdate = 0.03f;
    if (key == 'q') {
     for (Ball b : balls) {
      b.desiredEquilibriumDistance *= 1.0f+eqDistanceUpdate;
     } 
     /* Decrease equilibrium distance */
     } else if (key == 'a') {
      for (Ball b : balls) {
      b.desiredEquilibriumDistance *= 1.0f-eqDistanceUpdate;
     } 
      
    }
  }
  
}

public void evaluateSimulationTriggers() {
  println("Evaluating sim triggers");
  if (millis()-lastRunTime > 500 && optimizing && frameCount > 300) {
   // totalVel = computeTotalVelocity();
   float maxVel = 0;
   for (Ball b: balls) {
    float thisVel = b.velocity.mag();
    if (thisVel > maxVel) {
     maxVel = thisVel; 
    }
   }
   float allowableSpeedPerBall = 15;
   lastRunTime = millis();
   if (maxVel < allowableSpeedPerBall) {
     /* Stop the simulation */
     println("Stopping simulation because maxVel < allowableSpeedPerBall");
     // optimizing = false;
   }
  }
}

public void drawTextOverlays() {
  fill(255);
  text(totalVel + "px/frame",width/2.0f,15);
  
   /* If the node dynamics are being simulated (optimized), 
  then display the appropriate status message */
  fill(255);
  if (optimizing) {
    text("Simulating",width/2,height-10);
  } 
  else {
    text("Static",width/2,height-10);
  }
  
  textAlign(LEFT);
  text("Directions:",5,height-100);
  text("d : resume",5,height-90);
  text("f : pause",5,height-80);
  text("q : expand nodes",5,height-70);
  text("a : tighten nodes",5,height-60);
  text("c : clear selection",5,height-50);
  text("p : export to PDF",5,height-40);
  text("right click : explosion",5,height-30);
  text("dragging left-click : selection",5,height-20);
  /* Ownership label */
  text("Created by NASA/JSC/DM42 Kelly Smith",0,height-10);
  
  if (displayPDFMessage) {
    PDF_Message_Countdown -= 1;
    textAlign(CENTER);
    text("Printed PDF", width/2.0f, height/2.0f);
    if (PDF_Message_Countdown <= 0) {
       displayPDFMessage = false; 
    }
  }
  
}



public void detectHover() {
  
  PVector mousePos = new PVector(mouseX, mouseY);
 for (Ball b: balls) {
  if (abs(mouseY-b.position.y) <= b.ballSize && abs(mouseX-b.position.x) <= b.ballSize) {
    if (PVector.dist(mousePos, b.position) <= b.ballSize) {
      b.hover();
    } else {
      b.noHover();
    }
  } else {
   b.noHover(); 
  }
 } 
}

public boolean insidePolygon(PVector here, ArrayList<PVector> polygon) {
  
  boolean inSelection = false;
  
  /* Compute Bounding Box for selection */
    float minY = height;
    float maxY = 0;
    float minX = width;
    float maxX = 0;
    for (int i= 0; i < mousePositions.size(); i++) {
      PVector v = (PVector) mousePositions.get(i);
      if (v.x > maxX) {
        maxX = v.x;
      } else if (v.x < minX) {
       minX = v.x; 
      }
      
      if (v.y > maxY) {
        maxY = v.y;
      } else if (v.y < minY) {
       minY = v.y; 
      }
        
    }
  
  if (here.y > minY && here.y < maxY && here.x > minX && here.x < maxX) {
        /* Yes it is within the bounding box (passed first simple filter) */

        int k = polygon.size()-1;
        boolean oddNodes = false;

        PVector endVertex = polygon.get(k);
        
        for (int i = 0; i < polygon.size(); i++) {
          PVector thisVertex = polygon.get(i);
          if (thisVertex.y < here.y && endVertex.y >= here.y || 
            endVertex.y < here.y && thisVertex.y >= here.y)
          {
            if (thisVertex.x + (here.y - thisVertex.y)/ (endVertex.y-thisVertex.y)*(endVertex.x-thisVertex.x) < here.x) {
             oddNodes = !oddNodes; 
            }
          }
          endVertex = thisVertex;
        }
        if (oddNodes) {
         inSelection = true; 
        } else {
         inSelection = false; 
        }
        
      } else {
        inSelection = false;
      }
  
  return inSelection;
  
}

public void displaySelectedBalls() {
  for (Ball b : selectedBalls) {
       fill(b.ballColor);
       strokeWeight(4);
       stroke(255,0,0);
       PVector pos = (PVector) b.position;
       ellipse(pos.x, pos.y, b.ballSize, b.ballSize); 
  }
}

public float computeTotalVelocity() {
 float velocity = 0; 
 for (Ball b : balls) {
  velocity += b.velocity.mag();
 }
 return velocity;
}

public void explode() {
  println("Boom!");
  PVector mousePos = new PVector(mouseX,mouseY); 
  for (int i = 0; i < balls.size(); i++) {
    Ball b = (Ball) balls.get(i);
    PVector radius = PVector.sub(b.position,mousePos);
    PVector e = new PVector(radius.x,radius.y);
    e.normalize();
    PVector newVel = PVector.mult(e,width*100/radius.mag());
    b.velocity.add(newVel);
  }
}

class Ball {
  float desiredEquilibriumDistance;
  PVector position;
  PVector velocity;
  float mass;
  float ballSize;
  ArrayList<Ball> attractiveBalls;
  ArrayList<Ball> children;
  ArrayList<Ball> repulsiveBalls;
  float springConstant;
  float nomSpringDistance;
  float repulsiveConstant;
  float dampingConstant;
  float playbackSpeed;
  int ballColor;
  String name;
  boolean isHoveredOver;
  boolean isSelected;
  float hoverBeginTime;
  float hoverEndTime;
  float DEFAULT_BALL_SIZE = 10;
  float MAX_BALL_SIZE_FACTOR = 3;
  boolean applyUniformForce;

  Ball(PVector _position, PVector _velocity) {
    ballColor = color(PApplet.parseInt(random(50,255)),PApplet.parseInt(random(50,255)),PApplet.parseInt(random(50,255)));
    springConstant = 2;
    nomSpringDistance = 1;
    repulsiveConstant = springConstant * (desiredEquilibriumDistance*desiredEquilibriumDistance);
    dampingConstant = 0.5f*springConstant; //2*springConstant;
    playbackSpeed = 5;
    mass = 1;
    isHoveredOver = false;
    isSelected = false;
    ballSize = DEFAULT_BALL_SIZE;
    desiredEquilibriumDistance = ballSize*4;
    position = _position;
    velocity = _velocity;
    attractiveBalls = new ArrayList<Ball>();
    repulsiveBalls = new ArrayList<Ball>();
    children = new ArrayList<Ball>();
    applyUniformForce = false;
  } 

  public void select() {
    isSelected = true;
  }
  public void deSelect() {
    isSelected = false;
  }

  public void hover() {
    if (!isHoveredOver) {
      hoverBeginTime = millis();
    }
    isHoveredOver = true;
  }

  public void noHover() {
    if (isHoveredOver) {
      hoverEndTime = millis();
    }
    isHoveredOver = false;
  }

  public void setName(String _name) {
    name = _name;
  }

  public void display() {

    if (isHoveredOver) {
      strokeWeight(6);
      stroke(ballColor,200);
    } 
    else {
      strokeWeight(3);
      stroke(ballColor,50);
    }

    fill(ballColor,150);
    for (int i = 0; i < children.size(); i++) {
      Ball b = children.get(i);


      int n = 3;  
      PVector d= new PVector(b.position.x-position.x,b.position.y-position.y);
      d.limit(d.mag()-DEFAULT_BALL_SIZE/2.0f);
      if (d.mag() > n*DEFAULT_BALL_SIZE) {
        // Draw an arrow
        pushMatrix();
        translate(position.x+d.x, position.y+d.y);
        rotate(atan2(b.position.y-position.y, b.position.x-position.x));

        float triSize = ballSize/5.0f;
        triangle(0, 0, -triSize, triSize, -triSize, -triSize);
        popMatrix();
      }

      line(position.x,position.y, position.x+d.x, position.y+d.y);
    }


    if (isHoveredOver) {
      float elapsedTime = millis() - hoverBeginTime;
      float growthSpeed = 10.0f;
      float sizeIncrease = elapsedTime/growthSpeed;
      ballSize =  min(MAX_BALL_SIZE_FACTOR*DEFAULT_BALL_SIZE, DEFAULT_BALL_SIZE + sizeIncrease);
    } 
    else {
      float elapsedTime = millis() - hoverEndTime;
      float growthSpeed = 10.0f;
      float sizeDecrease = elapsedTime/growthSpeed;
      if (ballSize > DEFAULT_BALL_SIZE) {
        ballSize = max(DEFAULT_BALL_SIZE, ballSize - sizeDecrease);
      } 
      else {
        ballSize = DEFAULT_BALL_SIZE;
      }
    }

    fill(ballColor);
    if (isSelected) {
      strokeWeight(4);
      stroke(255,0,0);
    } 
    else {
      strokeWeight(1);
      stroke(255);
    }    
    ellipse(position.x,position.y,ballSize,ballSize);
  }

  public void displayName() {
    float yOffset = ballSize + 5;
    float yText = position.y - yOffset;
    if (yText < 0) {
      yText = position.y + yOffset;
    }

    float xText = position.x;
    textAlign(CENTER);
    
    rectMode(CENTER);    
    fill(color(0,200));
    noStroke();
    rect(xText,yText-3,textWidth(name),15);
    
    fill(ballColor);
    text(name,xText,yText);
  }

  public void update(float framerate) {

    float dt = playbackSpeed *(1.0f/framerate);

    PVector ballForce = computeForce();
    PVector acceleration = PVector.div(ballForce,mass);


    velocity.add(PVector.mult(acceleration,dt));
    position.add(PVector.mult(velocity,dt));
    // println("Ball at ("  + round(position.x) + "," + round(position.y) + "): Vel = (" + velocity.x +","+velocity.y+"); Accel = (" + acceleration.x + "," + acceleration.y + ")");
  }

  /* Check for collisions with the walls */
  public void checkWalls(float _width, float _height) {
    float eps = 1.0f;
    if (position.x < 0 || position.x > _width) {
      velocity.x = -0.9f*velocity.x;
      if (position.x < 0) {
        position.x = eps;
      } 
      else {
        position.x = _width - eps;
      }
    }
    if (position.y < 0 || position.y > _height) {
      velocity.y = -0.9f*velocity.y;
      if (position.y < 0) {
        position.y = eps;
      } 
      else {
        position.y = _height - eps;
      }
    }
  }

  public void addChild(Ball b) {
    children.add(b);
  }

  public void addAttractiveBall(Ball ball) {
    attractiveBalls.add(ball);
  }
  public void addRepulsiveBall(Ball ball) {
    repulsiveBalls.add(ball);
  }

  public ArrayList<Ball> getAttractiveBalls() {
    return attractiveBalls;
  }

  public ArrayList<Ball> getRepulsiveBalls() {
    return repulsiveBalls;
  }

  public PVector computeForce() {
    // Compute forces from attractive balls

    PVector displacement = new PVector(0,0);
    for (int i = 0; i < attractiveBalls.size(); i++) {
      Ball b = (Ball) attractiveBalls.get(i);
      PVector distance = PVector.sub(position,b.position);
      PVector e = new PVector(distance.x, distance.y);
      e.normalize();
      e.mult(desiredEquilibriumDistance);
      distance.sub(e);
      displacement.add(distance);
    }
    PVector attractiveForce = PVector.mult(displacement,-springConstant);


    /* Compute Cumulative Repulsive Force 
     (net displacement is allowable because 
     force is linear combinations of vectors
     (principle of superposition))
     */
    int n = 3;
    PVector repulsiveForce = new PVector(0,0);
    float Fmax = 100;
    for (int i = 0; i < repulsiveBalls.size(); i++) {
      Ball b = (Ball) repulsiveBalls.get(i);
      displacement = PVector.sub(position, b.position);

      if (displacement.mag() < desiredEquilibriumDistance*n && displacement.mag() > 0) {

        PVector d_hat = PVector.div(displacement,displacement.mag());
        PVector repel = PVector.mult(d_hat,Fmax + (-Fmax/ (n*desiredEquilibriumDistance)) * displacement.mag());

        repulsiveForce.add(repel);
      }
    }






    // Compute damping force to prevent endless oscillation (used to bleed energy from total system).
    // TODO -> PVector relativeVelocity = PVector.sub(velocity
    PVector dampingForce = PVector.mult(velocity,-dampingConstant);
    
    
    float uniformForceMag = 100;
    PVector uniformForce = new PVector(0,uniformForceMag);
    

    /* Sum up the vectors */
    PVector totalForce = new PVector(0,0);
    totalForce.add(attractiveForce);
    totalForce.add(repulsiveForce);
    totalForce.add(dampingForce);
    
    if (applyUniformForce) {
      totalForce.add(uniformForce);
    }
    return totalForce;
  }
}

class GraphReader {

  String filename;
  HashMap<String,Ball> hm;
  String dlm = "->";
  GraphReader() {
  }

  public void selectFile() {
    // selectInput("Select a file","processFile");
    
    filename = selectInput();
   
    //println("Selected " + filename);
    //File f = new File(filename);
    //processFile(f);
    //buildGraph();
  }
  
  public void processFile(File selection) {
   filename = selection.getName();
   buildGraph();
  }

  public void buildGraph() {
    hm = new HashMap<String,Ball>();

    BufferedReader reader = createReader(filename);
    String tline = "";
    try {
    while (tline != null) {
      tline = reader.readLine();
      if (tline != null) {
      
      String[] nodes = split(tline,dlm);

      Ball b1;
      Ball b2;
      if (!hm.containsKey(trim(nodes[0]))) {
        b1 = new Ball(new PVector(random(width), random(height)), new PVector(0,0));
        b1.setName(trim(nodes[0]));
      } else {
        b1 = hm.get(trim(nodes[0]));
      }
      
      if (!hm.containsKey(trim(nodes[1]))) {
        b2 = new Ball(new PVector(random(width), random(height)), new PVector(0,0) );
        b2.setName(trim(nodes[1]));
      } else {
        b2 = hm.get(trim(nodes[1]));
      }
      
      b1.addAttractiveBall(b2);
      b1.addChild(b2);
      
      b2.addAttractiveBall(b1);
      
      hm.put(nodes[0],b1);
      hm.put(nodes[1],b2);
      }
    }
    for (Ball b : hm.values()) {
     ArrayList<Ball> attBalls = b.getAttractiveBalls();
     for (Ball other : hm.values()) {
      if (!b.equals(other)) {
        if (!attBalls.contains(other)) {
          b.addRepulsiveBall(other);
        }
      }
     } 
    }
    
    
    } catch (IOException e) {
     e.printStackTrace(); 
    }
  }
  
  public ArrayList<Ball> getGraph() {
    ArrayList<Ball> balls = new ArrayList<Ball>();
    
    for (Ball b : hm.values()) {
      balls.add(b);
    }
    return balls;
  }  
}

  static public void main(String args[]) {
    PApplet.main(new String[] { "--present", "--bgcolor=#666666", "--stop-color=#cccccc", "Balls" });
  }
}
