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


https://github.com/V0xel0/Unity_Shader/assets/45827365/d27fdedd-1c7a-4fb4-ba6a-8af116acad9a


UI Controls  

![image](https://github.com/V0xel0/Unity_Shader/assets/45827365/594a03c0-7a22-418a-8da5-dd802d0a678f)

### Waves

https://github.com/V0xel0/Unity_Shader/assets/45827365/805b0f0d-4fef-468a-9f6a-9b850ec563dc

## Smoother
Shader + script that allows creations of semi-interactive mud, snow, skidmarks etc. Works by writing to red-channel of intermediate texture, raycasting and converting the hit to UV space and then using that data to move vertices, alter normal map and albedo.
Featuring options to change the strength, size, ray distance, and also natural "regeneration" or further "degeneration" of mesh in time.
Vertex movement can be disabled if our platform is computation starved.

### Typical behaviour

https://github.com/V0xel0/Unity_Shader/assets/45827365/4e6b13b2-53a0-4efd-888f-538208cf2bc1

### Regeneration effect

https://github.com/V0xel0/Unity_Shader/assets/45827365/8c031357-6b81-4865-9e7b-6f3b860fd61f

## Painter
Allows automatic smooth applying of second texture based on direction vector and normal vectors of the mesh. Useful for dirt, snow etc.
### Typical Usage

https://github.com/V0xel0/Unity_Shader/assets/45827365/cc99ae18-d6a8-4a1b-ad36-75bcb679efe5

### Changing direction

https://github.com/V0xel0/Unity_Shader/assets/45827365/aa78b6e5-a12a-4faf-9165-51e51fca9121

## Outglow
Applying inner or outer glow to a mesh, useful for fast fake lights, special effects, marking/selecting objects by hilighting them.

https://github.com/V0xel0/Unity_Shader/assets/45827365/873ea6f9-1086-4f44-9a32-f87820954b82

## Fake PBR
This was created to approximate unity standard PBR shader but taking some shortcuts in terms of being PBR "correct" in order to gain on efficiency on really old, mobile platforms. It allows easy extenbility to more lights and customization.    
![image](https://github.com/V0xel0/Unity_Shader/assets/45827365/af75e45e-f28a-4e9b-ab4e-58d42a814146)
On the left Unity standard on the right the Fake one
![image](https://github.com/V0xel0/Unity_Shader/assets/45827365/7a5c6565-261f-4c15-a4f8-5b1dd234ae02)
On the right Unity standard on the left the Fake one
![image](https://github.com/V0xel0/Unity_Shader/assets/45827365/fadb962a-a119-40f1-925c-68ac11f8282d)
Support of standard PBR game meshes (normal, albedo, metallic, roughness maps)
![image](https://github.com/V0xel0/Unity_Shader/assets/45827365/701b17ff-21f8-4869-88c1-00fba3f34824)

## Toon
Typical toon shader with outline rendered by pushing backfaces, allows adding additonal rims and steps for achieving different effects.

![image](https://github.com/V0xel0/Unity_Shader/assets/45827365/69bca90e-5554-4eb6-bb09-d80f598ce3d9)


