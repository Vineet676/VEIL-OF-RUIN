ASHEN CROWN — CHECKPOINT / SAVE-POINT ASSETS

Target:
res://assets/checkpoints/

These are actual PNG assets:
- checkpoint.png: main gothic-futuristic checkpoint
- activate_1..5: activation animation frames
- respawn_1..6: respawn/revival effect frames
- particles.png: ambient checkpoint particles
- light_cone.png: environmental glow
- interact_prompt.png: interaction indicator

Suggested gameplay:
1. Player enters checkpoint area.
2. Interaction key activates it.
3. Checkpoint becomes the player's respawn point.
4. Activation animation plays once.
5. Checkpoint remains lit after activation.
6. On player death, respawn at the last activated checkpoint.
7. Health/state should reset according to the game's rules.

Use nearest-neighbor filtering and keep the checkpoint scale consistent
with the player and stage pixel art.
