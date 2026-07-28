class_name UIConstants
extends RefCounted

## Shared icon sizes so every panel stays in sync - change here instead of
## hunting down each icon individually.

const TROOP_ICON_SIZE: int = 40 ## Hub - icon nhân vật trong party roster

## Debug ID tag ("#001"...) shown at the top of every UI panel so it can be
## referred to by number instead of description while testing. Flip this off
## to hide every one of them at once (eg. before a real build).
const SHOW_DEBUG_TAGS: bool = true
