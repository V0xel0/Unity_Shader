# Unity_Shaders
 Shaders that I previously worked on and can share their source code. (No assets, only code)
 
- [Water & Waves](water-&-waves)
- [Smoother](smoother)
## Water & Waves
Water shaders optimized for some mobile usage. Supports reflections through reflection probes and refractions. Toggleable options to tailor performance/quality. Ability to modulate colors through gradient and also water muddines & crisspness. 
Ocean shader is based on few gerstner waves.
### Water
https://github.com/V0xel0/Unity_Shader/assets/45827365/26dcdc44-a389-4f6c-be63-1502c45ad438

### Waves

https://github.com/V0xel0/Unity_Shader/assets/45827365/b86708b7-f785-4fb2-b3e0-8641aa385334

## Smoother
Shader + script that allows creations of semi-interactive mud, snow, skidmarks etc. Works by writing to red-channel of intermediate texture, raycasting and converting the hit to UV space and then using that data to move vertices, alter normal map and albedo.
Featuring options to change the strength, size, ray distance, and also natural "regeneration" or further "degeneration" of mesh in time.
Vertex movement can be disabled if our platform is computation starved.

### Typical behaviour

https://github.com/V0xel0/Unity_Shader/assets/45827365/76662879-620d-44df-97a4-7a558c095bd6

### Regeneration effect

https://github.com/V0xel0/Unity_Shader/assets/45827365/c18f98b6-d255-491e-8ee1-c62b82af80f7

