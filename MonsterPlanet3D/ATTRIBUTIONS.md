# Monster Planet 3D — Asset provenance

## Animated 3D characters

The four selected character files in `Assets/ThirdParty/Quaternius/` come from the [Quaternius Ultimate Space Kit](https://quaternius.com/packs/ultimatespacekit.html), distributed under **CC0 1.0 Universal**.

| Local file | Original model | Included animation set |
| --- | --- | --- |
| `reclaimer-finn.gltf` | Astronaut_FinnTheFrog | Idle, Walk, Run, Punch, HitReact, Death, Duck, Jump set, Wave, Weapon and reactions |
| `reclaimer-rae.gltf` | Astronaut_RaeTheRedPanda | Same 18-clip set |
| `overseer-mech-animated.gltf` | Mech_FinnTheFrog | Idle, Walk, Run, Kick, Shoot, Hit, Death, Jump and reactions |
| `ventlurker-glub.gltf` | Enemy_Flying | Flying idle, fast flying, headbutt, punch, hit, death and reactions |

The self-contained glTF conversions were obtained from the public [Aetherium sample asset directory](https://github.com/danvanderboom/Aetherium/tree/main/samples/unity/Aphelion/Assets/ThirdParty/Quaternius/Animated), whose provenance record traces them to the pack's public Google Drive distribution. The committed `License.txt` says “Ultimate Platformer Pack” in its heading; the upstream provenance notes this is an authoring slip in the Drive folder. Its operative license text is CC0 1.0, matching the Ultimate Space Kit page.

## Generated audio and graphics

- Mandarin guide clips under `Assets/Audio/Voice/` were generated locally for this prototype with the macOS Tingting system voice.
- Combat sounds, particles, trails, shockwaves, arena geometry and fallback character meshes are synthesized by the project's C# code and contain no extracted film or television material.
