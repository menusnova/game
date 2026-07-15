class_name BattleStats
extends RefCounted
# ════════════════════════════════════════════════════════════
#  CHEMIA — Buff / Debuff / Status / Formula core
#  Godot 4.7. Self-contained data model shared by the player and
#  any number of enemies — nothing here is battle_scene-specific.
# ════════════════════════════════════════════════════════════

enum DamageType { NORMAL, CRIT, HEAL, SHIELD, POISON }

# Buff/debuff stat multipliers are clamped so stacking can't run away.
const ATK_MULT_MIN := 0.0
const ATK_MULT_MAX := 2.0
const DEF_MULT_MIN := 0.0   # DEF is a mitigation fraction (0 = no mitigation)
const DEF_MULT_MAX := 0.8   # ...capped at 80% damage reduction

const BUFF_COLOR   := Color("#7F5AF0")   # void violet
const DEBUFF_COLOR := Color("#FF3CAC")   # magenta
const POISON_COLOR := Color("#7FFF00")


## One timed stat modifier: {stat, value, turns, source}.
## `stat` names its own direction (e.g. "ATK_UP" lives in buffs, "ATK_DOWN" in debuffs)
## so there's no sign confusion — `value` is always a positive magnitude.
class Modifier:
	var stat: String
	var value: float
	var turns: int
	var source: String

	func _init(p_stat: String, p_value: float, p_turns: int, p_source: String) -> void:
		stat = p_stat
		value = p_value
		turns = p_turns
		source = p_source


## One combatant's full stat/status state (used for both the player and any enemy).
class Unit:
	var hp: int
	var max_hp: int
	var base_atk: int
	var buffs: Array[Modifier]   = []   # e.g. ATK_UP, DEF_UP
	var debuffs: Array[Modifier] = []   # e.g. ATK_DOWN, DEF_DOWN
	var status: Dictionary = {}         # name -> {"amount": int, "turns": int} (poison, weak, burn, ...)
	var shield_hp: int = 0
	var void_shield_charges: int = 0

	func _init(p_max_hp: int, p_atk: int) -> void:
		max_hp = p_max_hp
		hp = p_max_hp
		base_atk = p_atk

	func add_buff(stat: String, value: float, turns: int, source: String) -> void:
		buffs.append(Modifier.new(stat, value, turns, source))

	func add_debuff(stat: String, value: float, turns: int, source: String) -> void:
		debuffs.append(Modifier.new(stat, value, turns, source))

	## Stacks onto an existing status of the same name (amount adds, turns refreshes
	## to the longer of the two). Use for poison/burn/weak/anything with a turn timer
	## that isn't a plain ATK/DEF modifier.
	func add_status(status_name: String, amount: int, turns: int) -> void:
		if status.has(status_name):
			status[status_name]["amount"] += amount
			status[status_name]["turns"] = maxi(status[status_name]["turns"], turns)
		else:
			status[status_name] = {"amount": amount, "turns": turns}

	func has_status(status_name: String) -> bool:
		return status.has(status_name)

	func status_turns(status_name: String) -> int:
		return int(status.get(status_name, {}).get("turns", 0))

	func status_amount(status_name: String) -> int:
		return int(status.get(status_name, {}).get("amount", 0))

	func clear_status(status_name: String) -> void:
		status.erase(status_name)

	## Net ATK multiplier from ATK_UP buffs / ATK_DOWN debuffs, clamped 0..2.0.
	func atk_mult() -> float:
		var mult := 1.0
		for b in buffs:
			if b.stat == "ATK_UP": mult += b.value
		for d in debuffs:
			if d.stat == "ATK_DOWN": mult -= d.value
		return clampf(mult, ATK_MULT_MIN, ATK_MULT_MAX)

	## Net DEF mitigation from DEF_UP buffs / DEF_DOWN debuffs, clamped 0..0.8.
	func def_mult() -> float:
		var mult := 0.0
		for b in buffs:
			if b.stat == "DEF_UP": mult += b.value
		for d in debuffs:
			if d.stat == "DEF_DOWN": mult -= d.value
		return clampf(mult, DEF_MULT_MIN, DEF_MULT_MAX)

	func has_buff(stat: String) -> bool:
		for b in buffs:
			if b.stat == stat: return true
		return false

	func has_debuff(stat: String) -> bool:
		for d in debuffs:
			if d.stat == stat: return true
		return false

	## All active buffs/debuffs/status combined, ready for the UI icon row.
	func active_effects() -> Array[Dictionary]:
		var out: Array[Dictionary] = []
		for b in buffs:
			out.append({"kind": "buff", "label": b.stat, "turns": b.turns, "color": BUFF_COLOR})
		for d in debuffs:
			out.append({"kind": "debuff", "label": d.stat, "turns": d.turns, "color": DEBUFF_COLOR})
		for key in status:
			var col: Color = POISON_COLOR if key == "poison" else DEBUFF_COLOR
			out.append({"kind": "status", "label": key, "turns": status[key]["turns"],
				"stack": status[key]["amount"], "color": col})
		return out

	## Status-damage phase (poison etc). Returns [{"name", "amount"}, ...] for the
	## caller to apply as HP loss + floating numbers. Does not mutate turns (see decay()).
	func tick_status_damage() -> Array[Dictionary]:
		var out: Array[Dictionary] = []
		for key in status:
			var s: Dictionary = status[key]
			if s["turns"] > 0 and s["amount"] > 0 and key != "weak":
				out.append({"name": key, "amount": s["amount"]})
		return out

	## Decays buff/debuff/status turn counters by 1, dropping anything that expires.
	## Call once per full turn cycle (see BattleStats.TURN_FLOW).
	func decay() -> void:
		var kept_buffs: Array[Modifier] = []
		for b in buffs:
			b.turns -= 1
			if b.turns > 0: kept_buffs.append(b)
		buffs = kept_buffs

		var kept_debuffs: Array[Modifier] = []
		for d in debuffs:
			d.turns -= 1
			if d.turns > 0: kept_debuffs.append(d)
		debuffs = kept_debuffs

		for key in status.keys().duplicate():
			status[key]["turns"] -= 1
			if status[key]["turns"] <= 0:
				status.erase(key)


# ════════════════════════════════════════════════════════════
#  DAMAGE FORMULA
#  ATK buff -> DEF debuff (mitigation) -> weakness amplifier -> final damage.
# ════════════════════════════════════════════════════════════
static func compute_damage(attacker: Unit, defender: Unit, base_dmg: int) -> int:
	var dmg := float(base_dmg) * attacker.atk_mult() * (1.0 - defender.def_mult())
	# "weak" status (e.g. a weakness-break reaction) amplifies damage taken beyond
	# what DEF mitigation alone can express (mitigation only ever reduces, 0..0.8).
	if defender.has_status("weak"):
		dmg *= 1.0 + (float(defender.status_amount("weak")) / 100.0)
	return maxi(1, int(ceil(dmg)))

## Applies damage to a unit's void-shield first (absorbs the whole hit, consumes one
## charge), then flat shield_hp (Salt-style), then HP. Returns the HP actually lost.
static func apply_damage_with_shields(unit: Unit, amount: int) -> int:
	var dmg := amount
	if unit.void_shield_charges > 0 and dmg > 0:
		unit.void_shield_charges -= 1
		return 0
	if unit.shield_hp > 0 and dmg > 0:
		var blocked := mini(unit.shield_hp, dmg)
		unit.shield_hp -= blocked
		dmg -= blocked
	unit.hp = maxi(0, unit.hp - dmg)
	return dmg


# ════════════════════════════════════════════════════════════
#  FORMULA (element-reaction) EFFECTS
#  A recipe carries `effects: Array[Dictionary]` instead of a single `type`, so
#  one reaction can do several things at once:
#      effects = [{"kind":"heal","amount":20}, {"kind":"shield","amount":10}]
#      for effect in effects: BattleStats.apply_effect(target, effect)
# ════════════════════════════════════════════════════════════
static func apply_effect(target: Unit, effect: Dictionary, source: String = "") -> Dictionary:
	var kind: String = str(effect.get("kind", ""))
	match kind:
		"damage":
			var lost := apply_damage_with_shields(target, int(effect.get("amount", 0)))
			return {"kind": "damage", "amount": lost}
		"heal":
			var amt: int = int(effect.get("amount", 0))
			target.hp = mini(target.max_hp, target.hp + amt)
			return {"kind": "heal", "amount": amt}
		"shield":
			var amt: int = int(effect.get("amount", 0))
			target.shield_hp += amt
			return {"kind": "shield", "amount": amt}
		"void_shield":
			var charges: int = int(effect.get("amount", 1))
			target.void_shield_charges += charges
			return {"kind": "shield", "amount": charges}
		"poison":
			target.add_status("poison", int(effect.get("amount", 0)), int(effect.get("turns", 3)))
			return {"kind": "poison", "amount": int(effect.get("amount", 0))}
		"weak":
			target.add_status("weak", int(effect.get("amount", 50)), int(effect.get("turns", 2)))
			return {"kind": "status", "amount": int(effect.get("amount", 50))}
		"atk_up":
			target.add_buff("ATK_UP", float(effect.get("value", 0.2)), int(effect.get("turns", 2)), source)
			return {"kind": "buff", "amount": 0}
		"atk_down":
			target.add_debuff("ATK_DOWN", float(effect.get("value", 0.2)), int(effect.get("turns", 2)), source)
			return {"kind": "debuff", "amount": 0}
		"def_up":
			target.add_buff("DEF_UP", float(effect.get("value", 0.2)), int(effect.get("turns", 2)), source)
			return {"kind": "buff", "amount": 0}
		"def_down":
			target.add_debuff("DEF_DOWN", float(effect.get("value", 0.2)), int(effect.get("turns", 2)), source)
			return {"kind": "debuff", "amount": 0}
		_:
			push_warning("BattleStats.apply_effect: unknown effect kind '%s'" % kind)
			return {"kind": "none", "amount": 0}

## Applies every effect in `effects` (in order) to `target`.
static func apply_effects(target: Unit, effects: Array, source: String = "") -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	for effect in effects:
		results.append(apply_effect(target, effect as Dictionary, source))
	return results


# ════════════════════════════════════════════════════════════
#  TURN FLOW
#  Status Damage -> Buff/Debuff decay -> Passive -> Recover AP -> Cooldown -> Start Turn
#  Documented as an ordered list of step names; battle_scene.gd (or any battle
#  controller) drives the actual per-step logic and calls back into the Unit
#  helpers above at each step.
# ════════════════════════════════════════════════════════════
const TURN_FLOW := [
	"status_damage",
	"buff_debuff",
	"passive",
	"recover_ap",
	"cooldown",
	"start_turn",
]


# ════════════════════════════════════════════════════════════
#  UI — Buff/Debuff/Status icon row (HBoxContainer of small chips)
# ════════════════════════════════════════════════════════════
## Builds (or rebuilds) `container`'s children to reflect `unit`'s active effects.
## Each chip shows a glyph, the remaining turns, and a stack count when > 1.
static func rebuild_effect_row(container: HBoxContainer, unit: Unit) -> void:
	for c in container.get_children():
		c.queue_free()
	for eff in unit.active_effects():
		container.add_child(_make_effect_chip(eff))

static func _make_effect_chip(eff: Dictionary) -> Panel:
	var col: Color = eff.get("color", DEBUFF_COLOR)
	var chip := Panel.new()
	chip.custom_minimum_size = Vector2(30, 30)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(col.r * 0.18, col.g * 0.18, col.b * 0.18, 0.92)
	sb.border_color = Color(col.r, col.g, col.b, 0.85)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(6)
	chip.add_theme_stylebox_override("panel", sb)

	var glyph := Label.new()
	glyph.text = _effect_glyph(str(eff.get("label", "")))
	glyph.add_theme_font_size_override("font_size", 13)
	glyph.add_theme_color_override("font_color", col)
	glyph.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	glyph.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	glyph.offset_left = -12; glyph.offset_right = 12
	glyph.offset_top  = -10; glyph.offset_bottom = 6
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_child(glyph)

	var turns_lbl := Label.new()
	turns_lbl.text = str(int(eff.get("turns", 0)))
	turns_lbl.add_theme_font_size_override("font_size", 8)
	turns_lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.85))
	turns_lbl.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	turns_lbl.offset_top = -10
	turns_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	turns_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_child(turns_lbl)

	if int(eff.get("stack", 0)) > 1:
		var stack_lbl := Label.new()
		stack_lbl.text = "x%d" % int(eff["stack"])
		stack_lbl.add_theme_font_size_override("font_size", 8)
		stack_lbl.add_theme_color_override("font_color", Color(1, 0.9, 0.5, 0.95))
		stack_lbl.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
		stack_lbl.position = Vector2(chip.custom_minimum_size.x - 16, -2)
		stack_lbl.size = Vector2(16, 12)
		stack_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chip.add_child(stack_lbl)

	return chip

static func _effect_glyph(label: String) -> String:
	match label:
		"ATK_UP":  return "⚔+"
		"ATK_DOWN": return "⚔-"
		"DEF_UP":  return "🛡+"
		"DEF_DOWN": return "🛡-"
		"poison":  return "☠"
		"weak":    return "💔"
		"burn":    return "🔥"
		"bleed":   return "🩸"
		"shock":   return "⚡"
		_: return "•"
