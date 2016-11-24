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
import processing.pdf.*;
import processing.video.*;

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

void setup() {
  // noLoop();
  
  // size(round(displayWidth*0.9),round(displayHeight*0.9));
  size(round(screen.width*0.9),round(screen.height*0.9));
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

void draw() {
  //println("Optimizing = " + optimizing);
  background(0);
  
  /* Done */
  //println("Eval sim triggers");
  evaluateSimulationTriggers();
  
  /* Done */
  //println("Managing keyboard input");
  manageKeyboardInput();
  
  /* Done */
  //println("Drawing selection boundaries");
  drawSelectionBoundaries();
  
  /* Done */
  //println("Detecting hover");
  detectHover();
  
  /* Done */
  //println("Displaying balls");
  displayBalls();
  
  //println("displaying ball names");
  displayBallNames();
  
  /* Done */
  //println("Drawing text overlays");
  drawTextOverlays();
  
  
  if (record) {
   endRecord(); 
  }
  
  //mm.addFrame();
  
}

void displayBallNames() {
 for (Ball b: balls) {
  b.displayName();
 } 
}

void mousePressed() {
  
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

void mouseReleased() {
  //println("Released Mouse");
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

void mouseDragged() {
  println("Dragging mouse");
  if (drawing == true) {
    mousePositions.add(new PVector(mouseX, mouseY));
  } else if (dragging == true) {
    println("Clearing mouse positions");
    mousePositions.clear();
    if (selectedBalls.size() == 1) {
      println("Moving selected ball to mouse position...");
      selectedBalls.get(0).position = new PVector(mouseX, mouseY);
    } else {
      println("Shifting group of balls...");
      for (int i = 0; i<selectedBalls.size(); i++) {
        Ball b = selectedBalls.get(i);
        PVector displacement = PVector.sub(new PVector(mouseX,mouseY),anchor);
        b.position = PVector.add(displacement, preDragBallPositions.get(i));
      }
    }
  }

}

void displayBalls() {
  // println("Displaying balls...");
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

void drawSelectionBoundaries() {
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

void manageKeyboardInput() {
  // println("watching keyboard input");
  /* KEYBOARD COMMANDS */
  if (keyPressed) {
    
    /* Toggle between enabling/disabling the node dynamics */
    if (key == 'd') {
      optimizing = true;
    } else if (key == 'f') {
     optimizing = false; 
    }
    
    
    
    /* Commented out for the LOLz */
    
    
    

    /* Clear the selection */
    if (key == 'c') {
        for (Ball b: selectedBalls) {
         b.deSelect(); 
        }
        selectedBalls.clear();
        mousePositions.clear();
    }
    
    /* Increase equilibrium distance */
    float eqDistanceUpdate = 0.03;
    if (key == 'q') {
     for (Ball b : balls) {
      b.desiredEquilibriumDistance *= 1.0+eqDistanceUpdate;
     } 
     /* Decrease equilibrium distance */
     } else if (key == 'a') {
      for (Ball b : balls) {
      b.desiredEquilibriumDistance *= 1.0-eqDistanceUpdate;
     } 
      
    }
    
    
    
  }
  
}

void keyPressed() {
  if (key == 'p') {
       // String pdfName = gr.filename.substring(0,gr.filename.length()-4) + ".pdf";
       displayPDFMessage = true;
       PDF_Message_Countdown = frameRate*2.5;
       // println("Created PDF @ " + pdfName);
      
      
       String outputPDF = selectOutput();
       if (outputPDF != null) {
         beginRecord(PDF,outputPDF);
         textFont(font);
         record = true;
         background(0);
       }
    }
  
 if (key=='w') {
      ArrayList<String> dependencies = new ArrayList<String>();
      for (Ball b : selectedBalls) {
        dependencies.addAll(b.getDependencies());
      }
      println("There are " + dependencies.size() + " dependencies.");
      String[] dependenciesArr = new String[dependencies.size()];
      for (int i=0; i<dependencies.size();i++) {
       dependenciesArr[i] = dependencies.get(i);
      }
      println(dependenciesArr);
      String filename = selectOutput();
      
      if (filename !=null) {
        println("Writing dependencies of to " + filename);
        saveStrings(filename, dependenciesArr);
      }
      
    } 
}

void evaluateSimulationTriggers() {
  // println("Evaluating sim triggers");
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
     // println("Stopping simulation because maxVel < allowableSpeedPerBall");
     // optimizing = false;
   }
  }
}

void drawTextOverlays() {
  fill(255);
  text(totalVel + "px/frame",width/2.0,15);
  
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
  int yy = 110;
  text(" Directions:",5,height-(yy-=10));
  text(" d : resume",5,height-(yy-=10));
  text(" f : pause",5,height-(yy-=10));
  text(" q : expand nodes",5,height-(yy-=10));
  text(" a : tighten nodes",5,height-(yy-=10));
  text(" c : clear selection",5,height-(yy-=10));
  text(" p : export to PDF",5,height-(yy-=10));
  text(" w : export dependencies of selected nodes",5,height-(yy-=10));
  text("right click : explosion",5,height-(yy-=10));
  text("dragging left-click : selection",5,height-(yy-=10));
  /* Ownership label */
  text("Created by NASA/JSC/DM42 Kelly Smith",0,height-(yy-=10));
  
  if (displayPDFMessage) {
    PDF_Message_Countdown -= 1;
    textAlign(CENTER);
    text("Printed PDF", width/2.0, height/2.0);
    if (PDF_Message_Countdown <= 0) {
       displayPDFMessage = false; 
    }
  }
  
}



void detectHover() {
  
  PVector mousePos = new PVector(mouseX, mouseY);
 for (Ball b: balls) {
   // If the ball center is within BALLSIZE square distance of the mouse (cheaper).
  if (abs(mouseY-b.position.y) <= b.ballSize && abs(mouseX-b.position.x) <= b.ballSize
      && PVector.dist(mousePos, b.position) <= b.ballSize) {
      b.hover();
  } else {
      //if (!b.parentHovered) { 
        b.noHover(); 
      //}
  }
 } 
}

boolean insidePolygon(PVector here, ArrayList<PVector> polygon) {
  
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

void displaySelectedBalls() {
  for (Ball b : selectedBalls) {
       fill(b.ballColor);
       strokeWeight(4);
       stroke(255,0,0);
       PVector pos = (PVector) b.position;
       ellipse(pos.x, pos.y, b.ballSize, b.ballSize); 
  }
}

float computeTotalVelocity() {
 float velocity = 0; 
 for (Ball b : balls) {
  velocity += b.velocity.mag();
 }
 return velocity;
}

void explode() {
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

