ASHEN CROWN — STAGE 1 SEPARATED ASSET PACK

The files here are separated category PNGs from the generated Stage 1
asset artwork. They are organized to match:

res://assets/environments/stage_1/

background/
midground/
foreground/
tiles/
obstacles/
platforms/
props/
water/
misc/

IMPORTANT:
The tiles/platform images are atlas-style sheets and should be used as
sprite/tile resources. The environment category images are separated
from the full overview, but may still contain multiple assets in one
PNG. Do not treat the entire original overview as a single gameplay
texture.

Recommended Godot usage:
- background/midground/foreground -> Parallax2D layers
- tiles -> TileMap/TileMapLayer
- obstacles -> Area2D/StaticBody2D as appropriate
- platforms -> StaticBody2D or TileMap
- props -> decorative Sprite2D nodes
- water -> decorative or hazard Area2D
- misc -> decorative Sprite2D nodes
