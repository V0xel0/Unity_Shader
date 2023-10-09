# Unity_Shaders
 Shaders that I previously worked on and can share their source code. (No assets, only code)
 
- [Water & Waves](#water-&-waves)
- [Smoother](#smoother)
- [Painter](#painter)
- [Fake PBR](#fake-pbr)
- [Toon](#toon)
## Water & Waves
Water shaders optimized for some mobile usage. Supports reflections through reflection probes and refractions. Toggleable options to tailor performance/quality. Ability to modulate colors through gradient and also water muddines & crisspness. 
Ocean shader is based on few gerstner waves.
### Water


https://github.com/V0xel0/Unity_Shader/assets/45827365/ec8bd4d5-38f3-4058-8bdc-3ff45d237cf8


UI Controls  

![image](https://github.com/V0xel0/Unity_Shader/assets/45827365/ade03fef-ba87-4ed1-bfdd-431e5f9de1d3)

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

## Painter
Allows automatic smooth applying of second texture based on direction vector and normal vectors of the mesh. Useful for dirt, snow etc.
### Typical Usage

https://github.com/V0xel0/Unity_Shader/assets/45827365/4edc0cda-4a4c-44bc-9f7f-dc506aa0bb39

### Changing direction

https://github.com/V0xel0/Unity_Shader/assets/45827365/16404356-4f23-4127-89d8-116f3b3412fe

## Outglow
Applying inner or outer glow to a mesh, useful for fast fake lights, special effects, marking/selecting objects by hilighting them.

https://github.com/V0xel0/Unity_Shader/assets/45827365/8ac87709-1ee2-42af-8f7b-066f4307b39f

## Fake PBR
This was created to approximate unity standard PBR shader but taking some shortcuts in terms of being PBR "correct" in order to gain on efficiency on really old, mobile platforms. It allows easy extenbility to more lights and customization.    
![image](https://github.com/V0xel0/Unity_Shader/assets/45827365/2c1d5078-e0be-4a2c-b8d3-28f6f75d4811)
On the right Unity standard on the left the Fake one
![image](https://github.com/V0xel0/Unity_Shader/assets/45827365/7be799cf-d65f-4bdc-a19a-86eb2478cd08)
On the right Unity standard on the left the Fake one
![image](https://github.com/V0xel0/Unity_Shader/assets/45827365/aefa4515-da50-47c3-bbe6-df830f933787)
Support of standard PBR game meshes (normal, albedo, metallic, roughness maps)
![image](https://github.com/V0xel0/Unity_Shader/assets/45827365/976cb79e-c844-4a52-904b-151a75ba78c1)

## Toon
Typical toon shader with outline rendered by pushing backfaces, allows adding additonal rims and steps for achieving different effects.

![image](https://github.com/V0xel0/Unity_Shader/assets/45827365/58f93403-9744-43e4-aecb-bbf557f591af)

