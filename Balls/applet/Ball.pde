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
  color ballColor;
  String name;
  boolean isHoveredOver;
  boolean isSelected;
  float hoverBeginTime;
  float hoverEndTime;
  float DEFAULT_BALL_SIZE = 10;
  float MAX_BALL_SIZE_FACTOR = 3;
  boolean applyUniformForce;

  Ball(PVector _position, PVector _velocity) {
    ballColor = color(int(random(50,255)),int(random(50,255)),int(random(50,255)));
    springConstant = 2;
    nomSpringDistance = 1;
    repulsiveConstant = springConstant * (desiredEquilibriumDistance*desiredEquilibriumDistance);
    dampingConstant = 0.5*springConstant; //2*springConstant;
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

  void select() {
    isSelected = true;
  }
  void deSelect() {
    isSelected = false;
  }

  void hover() {
    if (!isHoveredOver) {
      hoverBeginTime = millis();
    }
    isHoveredOver = true;
  }

  void noHover() {
    if (isHoveredOver) {
      hoverEndTime = millis();
    }
    isHoveredOver = false;
  }

  void setName(String _name) {
    name = _name;
  }

  void display() {

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
      d.limit(d.mag()-DEFAULT_BALL_SIZE/2.0);
      if (d.mag() > n*DEFAULT_BALL_SIZE) {
        // Draw an arrow
        pushMatrix();
        translate(position.x+d.x, position.y+d.y);
        rotate(atan2(b.position.y-position.y, b.position.x-position.x));

        float triSize = ballSize/5.0;
        triangle(0, 0, -triSize, triSize, -triSize, -triSize);
        popMatrix();
      }

      line(position.x,position.y, position.x+d.x, position.y+d.y);
    }


    if (isHoveredOver) {
      float elapsedTime = millis() - hoverBeginTime;
      float growthSpeed = 10.0;
      float sizeIncrease = elapsedTime/growthSpeed;
      ballSize =  min(MAX_BALL_SIZE_FACTOR*DEFAULT_BALL_SIZE, DEFAULT_BALL_SIZE + sizeIncrease);
    } 
    else {
      float elapsedTime = millis() - hoverEndTime;
      float growthSpeed = 10.0;
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

  void displayName() {
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

  void update(float framerate) {

    float dt = playbackSpeed *(1.0/framerate);

    PVector ballForce = computeForce();
    PVector acceleration = PVector.div(ballForce,mass);


    velocity.add(PVector.mult(acceleration,dt));
    position.add(PVector.mult(velocity,dt));
    // println("Ball at ("  + round(position.x) + "," + round(position.y) + "): Vel = (" + velocity.x +","+velocity.y+"); Accel = (" + acceleration.x + "," + acceleration.y + ")");
  }

  /* Check for collisions with the walls */
  void checkWalls(float _width, float _height) {
    float eps = 1.0;
    if (position.x < 0 || position.x > _width) {
      velocity.x = -0.9*velocity.x;
      if (position.x < 0) {
        position.x = eps;
      } 
      else {
        position.x = _width - eps;
      }
    }
    if (position.y < 0 || position.y > _height) {
      velocity.y = -0.9*velocity.y;
      if (position.y < 0) {
        position.y = eps;
      } 
      else {
        position.y = _height - eps;
      }
    }
  }

  void addChild(Ball b) {
    children.add(b);
  }

  void addAttractiveBall(Ball ball) {
    attractiveBalls.add(ball);
  }
  void addRepulsiveBall(Ball ball) {
    repulsiveBalls.add(ball);
  }

  ArrayList<Ball> getAttractiveBalls() {
    return attractiveBalls;
  }

  ArrayList<Ball> getRepulsiveBalls() {
    return repulsiveBalls;
  }

  PVector computeForce() {
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

