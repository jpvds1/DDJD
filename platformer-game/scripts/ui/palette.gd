class_name Palette
extends RefCounted

# Heaven Run shared UI palette

const ACCENT      := Color(1.0, 0.85, 0.2)    # halo gold: stars lit, equipped gear, sets
const TEXT_ACTIVE := Color(0.65, 0.65, 0.65)  # active lives / jumps / dash fill
const TEXT_DIM    := Color(0.35, 0.35, 0.35)  # inactive boxes / stars unlit
const BOX_EMPTY   := Color(0.22, 0.22, 0.22)  # empty indicator box background

const SELECTED    := Color(1.0, 1.0, 1.0)     # selected slot / equippable item
const UNSELECTED  := Color(0.6, 0.6, 0.6)     # unselected slot

const BONUS_POS   := Color(0.35, 1.0, 0.45)   # positive gear stat
const BONUS_NEG   := Color(1.0, 0.38, 0.38)   # negative gear stat
const BONUS_NONE  := Color(0.7, 0.7, 0.7)     # zero stat / separators

const BUYABLE     := Color(0.4, 0.85, 1.0)    # purchasable gear
const LOCKED      := Color(0.45, 0.45, 0.45)  # locked gear
