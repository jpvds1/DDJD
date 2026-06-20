class_name Palette
extends RefCounted

# Heaven Run shared UI palette 

const ACCENT      := Color(0.91, 0.59, 0.18)   # stars lit, equipped gear, sets, level-card stars

const SELECTED    := Color(0.16, 0.18, 0.27)   # selected slot / normal entry text (dark)
const UNSELECTED  := Color(0.45, 0.48, 0.56)   # unselected / muted
const BONUS_POS   := Color(0.16, 0.62, 0.27)   # positive gear stat (green on white)
const BONUS_NEG   := Color(0.80, 0.23, 0.23)   # negative gear stat (red on white)
const BONUS_NONE  := Color(0.48, 0.52, 0.60)   # zero stat / separators
const BUYABLE     := Color(0.18, 0.52, 0.78)   # purchasable gear (sky blue)
const LOCKED      := Color(0.62, 0.65, 0.72)   # locked gear (muted grey-blue)

const TEXT_ACTIVE := Color(0.95, 0.96, 1.0)    # active lives / jumps / dash fill
const TEXT_DIM    := Color(0.55, 0.58, 0.66)   # inactive boxes / stars unlit
const BOX_EMPTY   := Color(0.20, 0.22, 0.30, 0.6)  # empty indicator box background
