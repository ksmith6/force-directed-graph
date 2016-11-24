class GraphReader {

  String filename;
  HashMap<String,Ball> hm;
  String dlm = "->";
  GraphReader() {
  }

  void selectFile() {
    // selectInput("Select a file","processFile");
    
    filename = selectInput();
   
    //println("Selected " + filename);
    //File f = new File(filename);
    //processFile(f);
    //buildGraph();
  }
  
  void processFile(File selection) {
   filename = selection.getName();
   buildGraph();
  }

  void buildGraph() {
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
  
  ArrayList<Ball> getGraph() {
    ArrayList<Ball> balls = new ArrayList<Ball>();
    
    for (Ball b : hm.values()) {
      balls.add(b);
    }
    return balls;
  }  
}

