# City-Generator-Godot-4.2.2
An application that generates a low poly city in godot within a grid.
## Description
The application generates a city with simple geometry. Every mesh is generated individually based on parameters. It uses smooth Simplex noise to simulate a population density. 

I used the Godot game engine because it was required to be used. It was required because this was an academic project for the "3D real-time programming" module. Also the ArrayMesh and SurfaceTool Classes were useful and helped me better understanding how vertices and surfaces work in computer vision.

I faced many problems. My fist approach was to generate all surfaces within one mesh but I dropped the idea really fast. Then I often had the problem that some of my scenes (houses) were not at all generated or spawned at the wrong location (0, 0, 0). Also the programming for the combination logic of the blocks was quite a hustle. But after all it works! Possible enhancements would be implementing a better transition between houses and the scyscrapers, a new block type "industry" and after all the generation not in a grid, but based of junction locations (in my project defined as knot).
## Installation
To get the project working you need Godot version 4.2.2 stable installed on your machine.
## How to use the project
Simply run the project via the project manager from godot or run the project within the editor.
When the program is running you can set the parameters as you wish in th UI and press the "Generate" button to generate the city. It might take longer to build if you don't have a graphics card due to each individual draw call!
## Credits
For understanding the logic of generating a city I have read the paper "Procedural city generation using Perlin noise" by Niclas Olsson and Elias Frank (Faculty of Computing, Blekinge Institute of Technology, June 2017). I tried to implement the logic of districts, blocks and buildings as it's definition in the paper. Due to the small time frame in which the project had to be finished, I simplified some of the logic and decided to generate districs only in grids.

Here is the paper available: http://www.diva-portal.org/smash/get/diva2:1119094/FULLTEXT02.pdf
## License
MIT License

Copyright (c) 2024 Bastian Weiler

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
