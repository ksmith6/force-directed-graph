# force-directed-graph

It's an interactive force-directed graph visualization written in Processing, primarily intended for visualizing the structure of software dependencies.

I built this back in late 2010 to visualize the dependencies of Matlab code that I had inherited.  

I was unhappy with the static images produced by GraphViz, and I don't recall if d3.js had arrived on the scene yet.  

Anyhow, I had the intuition to model the graph as a giant spring-mass-damper physical system with local repulsive forces.

It works well enough for my purposes.

If you want to use it, you'll need to use a version of Processing prior to v2.0 due to a change in the Processing file reader.

The tool can parse a file that contains the dependencies in the form of:  
`A->B`  
`B->C` and so forth.
