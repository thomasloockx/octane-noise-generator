octane-noise-generator
======================

Created this Lua script as an example of how to develop modular Lua plugins on top of the Octane API.
The idea is to create an application where it's really easy to add new noise patterns based on the existing functionality. You don't have to worry about creating the user interface, that's all done automatically.

The supported noise patterns are:
    * Perlin noise
    * Wood rings (based on Perlin noise).
    * Cellular noise (a.k.a. Voronoi noise).

To install, unzip the archive into your OctaneRender Lua scripting directory (The directory configured via File > Preferences > Application Tab > Script Directory). You should have a file noise-generator.lua and a directory noise-generator in this directory.
