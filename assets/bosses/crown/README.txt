ASHEN CROWN — CROWN BOSS FIXED ASSET PACK

This is the corrected boss pack. It contains actual PNG files inside
the folders instead of only the master sheet.

Target:
res://assets/bosses/crown/

Folders:
idle/         Crown idle frames
attacks/      Boss attack categories
hurt/         Hurt/stagger
phases/       Phase 2 and Phase 3 transformations
death/        Death animation
parts/        Separate boss components
vfx/          Crown-specific effects
projectiles/  Boss projectiles

IMPORTANT:
Each PNG is a separated category sheet cropped from the generated boss
master artwork. Some sheets contain multiple frames/poses. They should
be configured as SpriteFrames or regions in Godot. Do NOT use the old
CROWN_MASTER_SPRITE_ATLAS.png as the boss texture.

Replace the old crown asset folder with this fixed pack.
