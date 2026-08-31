ASHEN CROWN — ENEMY VFX FIXED PACK

This version contains ACTUAL PNG FILES inside the folders.
The previous ZIP only contained empty folders plus the master sheet.

The files here are separated effect panels cropped from the generated
master sheet. They are individual category PNGs, but some PNGs still
contain multiple animation frames because the source artwork was a
sprite atlas.

For Godot:
- Use each PNG as a Sprite2D/region or crop its frames in SpriteFrames.
- Do not use the full master sheet.
- Keep filtering disabled for pixel art and preserve nearest-neighbor
  texture sampling.
- For true frame-by-frame animations, the individual frames should be
  cropped from these category sheets in Godot or exported separately.

Target:
res://assets/effects/enemies/
