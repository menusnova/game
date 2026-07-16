extends Control

const SC_MAIN := "res://main_menu.tscn"

# ── Element data (real-world + game) ─────────────────────────────
const ELEMENTS: Array = [
	{
		"id": "Hydrogen", "symbol": "H", "number": 1,
		"name_th": "ไฮโดรเจน", "name_en": "Hydrogen",
		"color": Color(0.5, 0.85, 1.0),
		"type": "Nonmetal",
		"real_desc": "ธาตุที่เบาที่สุดและพบมากที่สุดในจักรวาล คิดเป็น 75% ของมวลสารทั้งหมด ใช้เป็นเชื้อเพลิงจรวดและแหล่งพลังงานสะอาด",
		"how_to_get": "อยู่ในสำรับเริ่มต้น",
		"recipes": ["H + O → น้ำ (Water)"],
	},
	{
		"id": "Oxygen", "symbol": "O", "number": 8,
		"name_th": "ออกซิเจน", "name_en": "Oxygen",
		"color": Color(0.4, 0.9, 0.7),
		"type": "Nonmetal",
		"real_desc": "จำเป็นสำหรับการหายใจของสิ่งมีชีวิต คิดเป็น 21% ของบรรยากาศโลก และเป็นส่วนประกอบหลักของน้ำ",
		"how_to_get": "อยู่ในสำรับเริ่มต้น",
		"recipes": ["O + H → น้ำ (Water)", "O + Fe → สนิม (Rust)"],
	},
	{
		"id": "Iron", "symbol": "Fe", "number": 26,
		"name_th": "เหล็ก", "name_en": "Iron",
		"color": Color(0.75, 0.65, 0.55),
		"type": "Transition Metal",
		"real_desc": "โลหะที่พบมากที่สุดในโลก เป็นส่วนประกอบหลักของแกนโลก ใช้ในการก่อสร้างและอุตสาหกรรมทั่วโลก",
		"how_to_get": "อยู่ในสำรับเริ่มต้น",
		"recipes": ["Fe + O → สนิม (Rust)"],
	},
	{
		"id": "Sodium", "symbol": "Na", "number": 11,
		"name_th": "โซเดียม", "name_en": "Sodium",
		"color": Color(1.0, 0.85, 0.3),
		"type": "Alkali Metal",
		"real_desc": "โลหะอ่อนสีเงิน ระเบิดรุนแรงเมื่อสัมผัสน้ำ ร่างกายต้องการโซเดียมเพื่อควบคุมน้ำและแรงดันเลือด",
		"how_to_get": "อยู่ในสำรับเริ่มต้น",
		"recipes": ["Na + Cl → เกลือ (Salt)"],
	},
	{
		"id": "Chlorine", "symbol": "Cl", "number": 17,
		"name_th": "คลอรีน", "name_en": "Chlorine",
		"color": Color(0.7, 1.0, 0.4),
		"type": "Halogen",
		"real_desc": "แก๊สพิษสีเขียว-เหลือง เคยถูกใช้เป็นอาวุธเคมีในสงครามโลกครั้งที่ 1 ปัจจุบันใช้ฆ่าเชื้อในน้ำประปาและสระว่ายน้ำ",
		"how_to_get": "อยู่ในสำรับเริ่มต้น",
		"recipes": ["Cl + Na → เกลือ (Salt)"],
	},
	{
		"id": "Carbon", "symbol": "C", "number": 6,
		"name_th": "คาร์บอน", "name_en": "Carbon",
		"color": Color(0.55, 0.55, 0.60),
		"type": "Nonmetal",
		"real_desc": "รากฐานของสารอินทรีย์ทั้งหมด พบได้ทั้งในรูปเพชรและถ่านหิน",
		"how_to_get": "อยู่ในสำรับเริ่มต้น",
		"recipes": ["C + O → คาร์บอนไดออกไซด์", "C + H → มีเทน"],
	},
	{
		"id": "Nitrogen", "symbol": "N", "number": 7,
		"name_th": "ไนโตรเจน", "name_en": "Nitrogen",
		"color": Color(0.35, 0.50, 0.95),
		"type": "Nonmetal",
		"real_desc": "ก๊าซที่มากที่สุดในบรรยากาศ (78%) สำคัญต่อการสร้างโปรตีนและ DNA",
		"how_to_get": "อยู่ในสำรับเริ่มต้น",
		"recipes": ["N + O → ไนตริกออกไซด์", "N + Na → โซเดียมไนไตรด์"],
	},
	{
		"id": "Sulfur", "symbol": "S", "number": 16,
		"name_th": "กำมะถัน", "name_en": "Sulfur",
		"color": Color(1.00, 0.85, 0.10),
		"type": "Nonmetal",
		"real_desc": "ของแข็งสีเหลือง กลิ่นฉุน พบในภูเขาไฟ ใช้ผลิตกรดซัลฟิวริก",
		"how_to_get": "อยู่ในสำรับเริ่มต้น",
		"recipes": ["S + O → ซัลเฟอร์ไดออกไซด์", "Fe + S → ไอรอนซัลไฟด์"],
	},
	{
		"id": "Calcium", "symbol": "Ca", "number": 20,
		"name_th": "แคลเซียม", "name_en": "Calcium",
		"color": Color(0.80, 0.75, 0.65),
		"type": "Alkaline Earth Metal",
		"real_desc": "โลหะที่พบมากที่สุดในร่างกายมนุษย์ สร้างกระดูกและฟัน",
		"how_to_get": "อยู่ในสำรับเริ่มต้น",
		"recipes": ["Ca + O → แคลเซียมออกไซด์", "Ca + H → แคลเซียมไฮไดรด์"],
	},
	{
		"id": "Magnesium", "symbol": "Mg", "number": 12,
		"name_th": "แมกนีเซียม", "name_en": "Magnesium",
		"color": Color(0.60, 0.85, 0.60),
		"type": "Alkaline Earth Metal",
		"real_desc": "โลหะเบาที่ติดไฟได้ สำคัญต่อคลอโรฟิลล์และการสังเคราะห์แสง",
		"how_to_get": "อยู่ในสำรับเริ่มต้น",
		"recipes": ["Mg + O → แมกนีเซียมออกไซด์"],
	},
	{
		"id": "Potassium", "symbol": "K", "number": 19,
		"name_th": "โพแทสเซียม", "name_en": "Potassium",
		"color": Color(0.75, 0.30, 0.70),
		"type": "Alkali Metal",
		"real_desc": "แร่ธาตุที่ควบคุมความดันโลหิตและการทำงานของกล้ามเนื้อหัวใจ",
		"how_to_get": "อยู่ในสำรับเริ่มต้น",
		"recipes": ["K + O → โพแทสเซียมออกไซด์"],
	},
	{
		"id": "Copper", "symbol": "Cu", "number": 29,
		"name_th": "ทองแดง", "name_en": "Copper",
		"color": Color(0.20, 0.65, 0.40),
		"type": "Transition Metal",
		"real_desc": "โลหะนำไฟฟ้าดีเยี่ยม มนุษย์ใช้มากว่า 10,000 ปี สีแดง-ส้มเป็นเอกลักษณ์",
		"how_to_get": "ปลดล็อคพิเศษ",
		"recipes": ["Cu + O → คอปเปอร์ออกไซด์"],
	},
	{
		"id": "Zinc", "symbol": "Zn", "number": 30,
		"name_th": "สังกะสี", "name_en": "Zinc",
		"color": Color(0.55, 0.70, 0.75),
		"type": "Transition Metal",
		"real_desc": "โลหะสีขาวอมฟ้า ป้องกันสนิม สำคัญต่อระบบภูมิคุ้มกันของร่างกาย",
		"how_to_get": "ปลดล็อคพิเศษ",
		"recipes": ["Zn + O → ซิงค์ออกไซด์"],
	},
	{
		"id": "Phosphorus", "symbol": "P", "number": 15,
		"name_th": "ฟอสฟอรัส", "name_en": "Phosphorus",
		"color": Color(0.90, 0.50, 0.15),
		"type": "Nonmetal",
		"real_desc": "ธาตุสำคัญใน DNA และ ATP แหล่งพลังงานของเซลล์สิ่งมีชีวิตทุกชนิด",
		"how_to_get": "ปลดล็อคพิเศษ",
		"recipes": [],
	},
	{
		"id": "Silicon", "symbol": "Si", "number": 14,
		"name_th": "ซิลิคอน", "name_en": "Silicon",
		"color": Color(0.45, 0.55, 0.65),
		"type": "Metalloid",
		"real_desc": "กึ่งตัวนำพื้นฐานของยุคดิจิทัล ทรายแก้วและชิปคอมพิวเตอร์ล้วนมาจาก Si",
		"how_to_get": "ปลดล็อคพิเศษ",
		"recipes": ["Si + O → ซิลิคอนไดออกไซด์"],
	},
	{
		"id": "Water", "symbol": "H₂O", "number": 0,
		"name_th": "น้ำ", "name_en": "Water",
		"color": Color(0.3, 0.7, 1.0),
		"type": "Compound",
		"real_desc": "สารประกอบที่จำเป็นต่อสิ่งมีชีวิตทุกชนิด ครอบคลุม 71% ของพื้นผิวโลก มีคุณสมบัติพิเศษคือมีความหนาแน่นสูงสุดที่ 4°C",
		"how_to_get": "สังเคราะห์: H + O",
		"recipes": ["ฟื้นฟู HP +20"],
	},
	{
		"id": "Salt", "symbol": "NaCl", "number": 0,
		"name_th": "เกลือ", "name_en": "Salt",
		"color": Color(0.9, 0.9, 0.95),
		"type": "Compound",
		"real_desc": "โซเดียมคลอไรด์ สารที่มนุษย์ใช้ถนอมอาหารมาหลายพันปี ร่างกายต้องการเกลือในปริมาณที่เหมาะสมเพื่อการทำงานของเซลล์ประสาท",
		"how_to_get": "สังเคราะห์: Na + Cl",
		"recipes": ["เพิ่ม Shield +20"],
	},
	{
		"id": "Rust", "symbol": "Fe₂O₃", "number": 0,
		"name_th": "สนิมเหล็ก", "name_en": "Rust",
		"color": Color(0.85, 0.4, 0.2),
		"type": "Compound",
		"real_desc": "เหล็กออกไซด์ เกิดจากปฏิกิริยาออกซิเดชันของเหล็กกับออกซิเจนในอากาศและความชื้น เป็นปัญหาใหญ่ในอุตสาหกรรมโลหะ",
		"how_to_get": "สังเคราะห์: Fe + O",
		"recipes": ["วางพิษศัตรู +5/เทิร์น (4 เทิร์น)"],
	},
	{
		"id": "CO2", "symbol": "CO₂", "number": 0,
		"name_th": "คาร์บอนไดออกไซด์", "name_en": "Carbon Dioxide",
		"color": Color(0.55, 0.55, 0.60),
		"type": "Compound",
		"real_desc": "ก๊าซที่เกิดจากการเผาไหม้และการหายใจ พืชใช้สังเคราะห์แสง แต่มากเกินไปทำให้หายใจลำบาก",
		"how_to_get": "สังเคราะห์: C + O",
		"recipes": ["ลดเกราะศัตรู 20% (2 เทิร์น)"],
	},
	{
		"id": "NitricOxide", "symbol": "NO", "number": 0,
		"name_th": "ไนตริกออกไซด์", "name_en": "Nitric Oxide",
		"color": Color(0.35, 0.50, 0.95),
		"type": "Compound",
		"real_desc": "ก๊าซไม่มีสี เกิดจากปฏิกิริยาของไนโตรเจนกับออกซิเจนที่อุณหภูมิสูง พบในควันไอเสียและฟ้าผ่า",
		"how_to_get": "สังเคราะห์: N + O",
		"recipes": ["ลด ATK ศัตรู 20% (2 เทิร์น)"],
	},
	{
		"id": "SO2", "symbol": "SO₂", "number": 0,
		"name_th": "ซัลเฟอร์ไดออกไซด์", "name_en": "Sulfur Dioxide",
		"color": Color(1.00, 0.85, 0.10),
		"type": "Compound",
		"real_desc": "ก๊าซพิษกลิ่นฉุน เกิดจากการเผาไหม้กำมะถัน เป็นสาเหตุหลักของฝนกรด",
		"how_to_get": "สังเคราะห์: O + S",
		"recipes": ["วางพิษศัตรู +4/เทิร์น (4 เทิร์น)"],
	},
	{
		"id": "CaO", "symbol": "CaO", "number": 0,
		"name_th": "แคลเซียมออกไซด์", "name_en": "Calcium Oxide",
		"color": Color(0.80, 0.75, 0.65),
		"type": "Compound",
		"real_desc": "หรือปูนขาว ได้จากการเผาหินปูน ใช้ในอุตสาหกรรมก่อสร้างและปรับสภาพดิน",
		"how_to_get": "สังเคราะห์: Ca + O",
		"recipes": ["เพิ่ม Shield +15"],
	},
	{
		"id": "MgO", "symbol": "MgO", "number": 0,
		"name_th": "แมกนีเซียมออกไซด์", "name_en": "Magnesium Oxide",
		"color": Color(0.60, 0.85, 0.60),
		"type": "Compound",
		"real_desc": "ผงสีขาว ใช้เป็นยาลดกรดและยาระบาย มีสมบัติทนความร้อนสูง",
		"how_to_get": "สังเคราะห์: Mg + O",
		"recipes": ["ฟื้นฟู HP +15"],
	},
	{
		"id": "K2O", "symbol": "K₂O", "number": 0,
		"name_th": "โพแทสเซียมออกไซด์", "name_en": "Potassium Oxide",
		"color": Color(0.75, 0.30, 0.70),
		"type": "Compound",
		"real_desc": "สารประกอบที่ทำปฏิกิริยารุนแรงกับน้ำ ใช้เป็นส่วนประกอบของปุ๋ยโพแทช",
		"how_to_get": "สังเคราะห์: K + O",
		"recipes": ["เพิ่ม ATK 20% (2 เทิร์น)"],
	},
	{
		"id": "HCl", "symbol": "HCl", "number": 0,
		"name_th": "กรดเกลือ", "name_en": "Hydrochloric Acid",
		"color": Color(0.75, 0.95, 0.55),
		"type": "Compound",
		"real_desc": "กรดแก่ที่สำคัญในอุตสาหกรรม เกิดจากไฮโดรเจนกับคลอรีน มีฤทธิ์กัดกร่อนสูง",
		"how_to_get": "สังเคราะห์: Cl + H",
		"recipes": ["โจมตีศัตรู 25 ดาเมจ"],
	},
	{
		"id": "FeS", "symbol": "FeS", "number": 0,
		"name_th": "เหล็กซัลไฟด์", "name_en": "Iron Sulfide",
		"color": Color(0.55, 0.48, 0.40),
		"type": "Compound",
		"real_desc": "แร่ธาตุที่พบในธรรมชาติ หรือ 'ทองของคนโง่' เกิดจากเหล็กกับกำมะถัน",
		"how_to_get": "สังเคราะห์: Fe + S",
		"recipes": ["ลดเกราะศัตรู 15% (2 เทิร์น)"],
	},
	{
		"id": "NaH", "symbol": "NaH", "number": 0,
		"name_th": "โซเดียมไฮไดรด์", "name_en": "Sodium Hydride",
		"color": Color(0.95, 0.90, 0.55),
		"type": "Compound",
		"real_desc": "สารประกอบไอออนิกที่ทำปฏิกิริยารุนแรงกับน้ำ ใช้เป็นตัวรีดิวซ์ในอุตสาหกรรมเคมี",
		"how_to_get": "สังเคราะห์: H + Na",
		"recipes": ["เพิ่ม ATK 15% (2 เทิร์น)"],
	},
	{
		"id": "CH4", "symbol": "CH₄", "number": 0,
		"name_th": "มีเทน", "name_en": "Methane",
		"color": Color(0.55, 0.75, 0.95),
		"type": "Compound",
		"real_desc": "ก๊าซเชื้อเพลิงหลักในก๊าซธรรมชาติ เกิดจากคาร์บอนกับไฮโดรเจน ติดไฟได้ง่าย",
		"how_to_get": "สังเคราะห์: C + H",
		"recipes": ["วางพิษศัตรู +3/เทิร์น (3 เทิร์น)"],
	},
	{
		"id": "H2S", "symbol": "H₂S", "number": 0,
		"name_th": "ไฮโดรเจนซัลไฟด์", "name_en": "Hydrogen Sulfide",
		"color": Color(0.80, 0.80, 0.35),
		"type": "Compound",
		"real_desc": "ก๊าซพิษกลิ่นไข่เน่า เกิดจากไฮโดรเจนกับกำมะถัน อันตรายแม้ในความเข้มข้นต่ำ",
		"how_to_get": "สังเคราะห์: H + S",
		"recipes": ["วางพิษศัตรู +6/เทิร์น (2 เทิร์น)"],
	},
	{
		"id": "CaH2", "symbol": "CaH₂", "number": 0,
		"name_th": "แคลเซียมไฮไดรด์", "name_en": "Calcium Hydride",
		"color": Color(0.85, 0.80, 0.70),
		"type": "Compound",
		"real_desc": "สารดูดความชื้นที่ทรงพลัง เกิดจากแคลเซียมกับไฮโดรเจน ใช้กำจัดน้ำในตัวทำละลาย",
		"how_to_get": "สังเคราะห์: Ca + H",
		"recipes": ["เพิ่ม Shield +20"],
	},
	{
		"id": "Na3N", "symbol": "Na₃N", "number": 0,
		"name_th": "โซเดียมไนไตรด์", "name_en": "Sodium Nitride",
		"color": Color(0.55, 0.60, 0.95),
		"type": "Compound",
		"real_desc": "สารประกอบไอออนิกที่ไม่เสถียร เกิดจากไนโตรเจนกับโซเดียม สลายตัวง่ายเมื่อสัมผัสความร้อน",
		"how_to_get": "สังเคราะห์: N + Na",
		"recipes": ["ลด ATK ศัตรู 15% (2 เทิร์น)"],
	},
	{
		"id": "CaC2", "symbol": "CaC₂", "number": 0,
		"name_th": "แคลเซียมคาร์ไบด์", "name_en": "Calcium Carbide",
		"color": Color(0.65, 0.55, 0.45),
		"type": "Compound",
		"real_desc": "ของแข็งที่ทำปฏิกิริยากับน้ำได้ก๊าซอะเซทิลีนไวไฟ เกิดจากคาร์บอนกับแคลเซียม",
		"how_to_get": "สังเคราะห์: C + Ca",
		"recipes": ["โจมตีศัตรู 30 ดาเมจ"],
	},
]

# ── Colors ────────────────────────────────────────────────────────
const C_BG     := Color(0.04, 0.05, 0.10, 1.0)
const C_PANEL  := Color(0.07, 0.09, 0.16, 1.0)
const C_BORDER := Color(0.22, 0.50, 0.90, 0.30)
const C_TEXT   := Color(0.88, 0.92, 1.0,  1.0)
const C_SUB    := Color(0.55, 0.70, 0.90, 0.8)
const C_GOLD   := Color(1.00, 0.82, 0.25, 1.0)
const C_DONE   := Color(0.30, 0.85, 0.55, 1.0)
const C_LOCK   := Color(0.25, 0.28, 0.38, 1.0)

var _tab := 0  # 0=elements (only tab)

# Compound keys already shown in elements tab — skip in compounds tab
const ELEM_COMPOUND_KEYS := [
	"water", "salt", "rust",
	"carbon_dioxide", "nitric_oxide", "sulfur_dioxide",
	"calcium_oxide", "magnesium_oxide", "potassium_oxide",
	"hydrochloric_acid", "iron_sulfide", "sodium_hydride",
	"methane", "hydrogen_sulfide", "calcium_hydride",
	"sodium_nitride", "calcium_carbide",
]
var _detail_overlay: Control
var _discovered: Array[String] = []  # element ids unlocked

@onready var _content: ScrollContainer = $ContentScroll
@onready var _back_btn: Panel = $Header/BackBtn
@onready var _fade: ColorRect = $FadeOverlay

func _ready() -> void:

	_back_btn.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			var tw := _back_btn.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
			tw.tween_property(_back_btn, "scale", Vector2(0.78, 0.78), 0.08)
			tw.tween_property(_back_btn, "scale", Vector2(1.0, 1.0), 0.22)
			tw.tween_callback(_go_back)
	)
	_back_btn.mouse_entered.connect(func():
		_back_btn.create_tween().set_ease(Tween.EASE_OUT).tween_property(_back_btn, "modulate", Color(1.15, 1.15, 1.2, 1.0), 0.10)
	)
	_back_btn.mouse_exited.connect(func():
		_back_btn.create_tween().set_ease(Tween.EASE_OUT).tween_property(_back_btn, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.12)
	)

	const SYM_TO_ID := {
		"H": "Hydrogen", "O": "Oxygen",   "Na": "Sodium",
		"Cl": "Chlorine", "Fe": "Iron",   "C":  "Carbon",
		"N": "Nitrogen",  "S": "Sulfur",  "Ca": "Calcium",
		"Mg": "Magnesium", "K": "Potassium",
		"Cu": "Copper", "Zn": "Zinc", "P": "Phosphorus", "Si": "Silicon",
	}
	# Map lab compound keys → codex element ids (only for compounds the
	# codex tracks separately as their own "element" card, e.g. Water)
	const COMPOUND_TO_ELEM := {
		"water": "Water", "salt": "Salt", "rust": "Rust",
		"carbon_dioxide": "CO2", "nitric_oxide": "NitricOxide",
		"sulfur_dioxide": "SO2", "calcium_oxide": "CaO",
		"magnesium_oxide": "MgO", "potassium_oxide": "K2O",
		"hydrochloric_acid": "HCl", "iron_sulfide": "FeS",
		"sodium_hydride": "NaH", "methane": "CH4",
		"hydrogen_sulfide": "H2S", "calcium_hydride": "CaH2",
		"sodium_nitride": "Na3N", "calcium_carbide": "CaC2",
	}
	_discovered = []
	# Starter elements — same set the lab gives you from the start
	# (ReactionDB.ELEMENTS unlocked=true) count as already discovered,
	# no need to mix them first.
	for e in ReactionDB.ELEMENTS:
		if e.get("unlocked", false):
			var mapped: String = SYM_TO_ID.get(e["symbol"], e["symbol"])
			if mapped not in _discovered:
				_discovered.append(mapped)
	# Everything else (locked lab elements, and compounds) is gated by
	# actual PlayerData discovery from mixing in the lab.
	for entry in PlayerData.discovered_elements:
		var mapped: String = SYM_TO_ID.get(entry, entry)
		if mapped not in _discovered:
			_discovered.append(mapped)
	for comp_key in PlayerData.discovered_compounds:
		var elem_id: String = COMPOUND_TO_ELEM.get(comp_key, "")
		if elem_id != "" and elem_id not in _discovered:
			_discovered.append(elem_id)

	if ResourceLoader.exists("res://image/bgac.png"):
		# The scene has an opaque "Background" ColorRect fallback — hide it
		# or it sits on top of / behind incorrectly and covers this texture.
		var old_bg := get_node_or_null("Background")
		if old_bg:
			old_bg.visible = false

		var bg := TextureRect.new()
		bg.texture      = load("res://image/bgac.png")
		bg.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bg.z_index      = -1
		add_child(bg)
		move_child(bg, 0)

	_build_detail_overlay()
	_switch_tab(0)
	create_tween().tween_property(_fade, "color:a", 0.0, 0.30)

func _flat(col: Color, border: Color = Color(0,0,0,0), r: int = 8, bw: int = 0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.border_color = border
	sb.corner_radius_top_left     = r
	sb.corner_radius_top_right    = r
	sb.corner_radius_bottom_right = r
	sb.corner_radius_bottom_left  = r
	sb.border_width_left   = bw
	sb.border_width_right  = bw
	sb.border_width_top    = bw
	sb.border_width_bottom = bw
	return sb

# ── clipped description label helper ──
func _clipped_desc(parent: Control, txt: String, px: float, py: float,
		w: float, h: float, font_sz: int, col: Color) -> void:
	var clip := Control.new()
	clip.position = Vector2(px, py)
	clip.size = Vector2(w, h)
	clip.clip_contents = true
	clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(clip)

	var lbl := Label.new()
	lbl.text = txt
	lbl.position = Vector2(0, 0)
	lbl.size = Vector2(w, h + 40)   # taller than clip so wrap has room
	lbl.add_theme_font_size_override("font_size", font_sz)
	lbl.add_theme_color_override("font_color", col)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip.add_child(lbl)

func _switch_tab(idx: int) -> void:
	_tab = idx
	for c in _content.get_children():
		c.queue_free()
	_build_element_tab()

# ════════════════════════════════════════════════════════════════
#  TAB 0 — Elements
# ════════════════════════════════════════════════════════════════
func _build_element_tab() -> void:
	var vbox := VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(1152, 0)
	vbox.add_theme_constant_override("separation", 0)
	_content.add_child(vbox)

	# ── Elements section — discovered ones first, locked ones after,
	#    all elements live together here (not mixed into compounds) ──
	var elem_total := ELEMENTS.filter(func(e): return e["type"] != "Compound").size()
	var elem_disc_count := ELEMENTS.filter(func(e): return e["id"] in _discovered and e["type"] != "Compound").size()
	vbox.add_child(_section_label("ธาตุที่ค้นพบ  (%d/%d)" % [elem_disc_count, elem_total]))

	var grid := _make_card_grid()
	vbox.add_child(grid)

	var elem_found: Array = ELEMENTS.filter(func(e): return e["id"] in _discovered)
	var elem_hidden: Array = ELEMENTS.filter(func(e): return e["id"] not in _discovered)
	for elem in elem_found + elem_hidden:
		grid.get_child(0).add_child(_make_element_card(elem))

	# ── Compounds section — split into Tier 1 / Tier 2 / Tier 3 sub-groups,
	#    discovered ones sorted first within each tier ──
	var all_keys: Array = ReactionDB.COMPOUNDS.keys()
	var comp_keys: Array = all_keys.filter(func(k): return k not in ELEM_COMPOUND_KEYS)
	var found_count := comp_keys.filter(func(k): return k in PlayerData.discovered_compounds).size()

	vbox.add_child(_section_label("สารประกอบที่ค้นพบ  (%d/%d)" % [found_count, comp_keys.size()]))

	for tier in [1, 2, 3]:
		var tier_keys: Array = comp_keys.filter(func(k):
			return int(ReactionDB.COMPOUNDS[k].get("tier", 1)) == tier)
		if tier_keys.is_empty():
			continue

		var tier_found: Array = tier_keys.filter(func(k): return k in PlayerData.discovered_compounds)
		var tier_hidden: Array = tier_keys.filter(func(k): return k not in PlayerData.discovered_compounds)

		var tier_lbl := Label.new()
		tier_lbl.text = "Tier %d" % tier
		tier_lbl.add_theme_font_size_override("font_size", 12)
		tier_lbl.add_theme_color_override("font_color", C_SUB)
		var tier_wrap := MarginContainer.new()
		tier_wrap.add_theme_constant_override("margin_left", 28)
		tier_wrap.add_theme_constant_override("margin_top", 8)
		tier_wrap.add_theme_constant_override("margin_bottom", 4)
		tier_wrap.add_child(tier_lbl)
		vbox.add_child(tier_wrap)

		var cgrid := _make_card_grid()
		vbox.add_child(cgrid)
		for key in tier_found + tier_hidden:
			var compound: Dictionary = ReactionDB.COMPOUNDS[key]
			var is_found: bool = key in PlayerData.discovered_compounds
			cgrid.get_child(0).add_child(_make_compound_card(compound, is_found))

	var bottom_spacer := Control.new()
	bottom_spacer.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(bottom_spacer)

# ── shared 5-col card grid wrapped in margins ──
func _make_card_grid() -> MarginContainer:
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var wrap := MarginContainer.new()
	wrap.add_theme_constant_override("margin_left", 28)
	wrap.add_theme_constant_override("margin_right", 28)
	wrap.add_theme_constant_override("margin_top", 16)
	wrap.add_theme_constant_override("margin_bottom", 24)
	wrap.add_child(grid)
	return wrap

func _make_element_card(elem: Dictionary) -> Control:
	const CW := 162.0; const CH := 210.0
	var discovered: bool = elem["id"] in _discovered
	var card := Panel.new()
	card.custom_minimum_size = Vector2(CW, CH)
	var col := elem["color"] as Color
	var border_col := Color(col.r, col.g, col.b, 0.55) if discovered else Color(0.15, 0.18, 0.25, 0.35)
	var bg_col     := Color(col.r * 0.10, col.g * 0.10, col.b * 0.14, 1.0) if discovered else Color(0.06, 0.07, 0.12, 1.0)
	card.add_theme_stylebox_override("panel", _flat(bg_col, border_col, 10, 1))
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.clip_contents = true

	if discovered:
		# Atomic number — top-right
		if elem["number"] > 0:
			var num := Label.new()
			num.text = str(elem["number"])
			num.position = Vector2(CW - 30, 5)
			num.size = Vector2(26, 14)
			num.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			num.add_theme_font_size_override("font_size", 9)
			num.add_theme_color_override("font_color", Color(col.r, col.g, col.b, 0.45))
			num.mouse_filter = Control.MOUSE_FILTER_IGNORE
			card.add_child(num)

		# Symbol — large, centered top
		var badge := Label.new()
		badge.text = elem["symbol"]
		badge.position = Vector2(0, 14)
		badge.size = Vector2(CW, 64)
		badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		badge.add_theme_font_size_override("font_size", 40)
		badge.add_theme_color_override("font_color", Color(col.r, col.g, col.b, 0.95))
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(badge)

		# Divider under symbol
		var div1 := ColorRect.new()
		div1.color = Color(col.r, col.g, col.b, 0.18)
		div1.size = Vector2(CW - 24, 1)
		div1.position = Vector2(12, 82)
		div1.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(div1)

		# Thai name
		var name_lbl := Label.new()
		name_lbl.text = elem["name_th"]
		name_lbl.position = Vector2(4, 88)
		name_lbl.size = Vector2(CW - 8, 22)
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		name_lbl.add_theme_font_size_override("font_size", 13)
		name_lbl.add_theme_color_override("font_color", C_TEXT)
		name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(name_lbl)

		# English · type
		var sub := Label.new()
		sub.text = "%s · %s" % [elem["name_en"], elem["type"]]
		sub.position = Vector2(4, 112)
		sub.size = Vector2(CW - 8, 16)
		sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sub.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		sub.add_theme_font_size_override("font_size", 8)
		sub.add_theme_color_override("font_color", C_SUB)
		sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(sub)

		# Description — clipped to card bottom
		_clipped_desc(card, elem["real_desc"],
			8, 132, CW - 16, CH - 136,
			8, Color(0.68, 0.80, 0.90, 0.62))

		card.gui_input.connect(func(ev):
			if ev is InputEventMouseButton and ev.pressed:
				_open_element_detail(elem)
		)

		# g1 frame overlay
		var cftex := TextureRect.new()
		cftex.texture      = preload("res://image/g1.jpg")
		cftex.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
		cftex.stretch_mode = TextureRect.STRETCH_SCALE
		cftex.size         = Vector2(CW + 4, CH + 4)
		cftex.position     = Vector2(-2, -2)
		cftex.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var cfmat := CanvasItemMaterial.new()
		cfmat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		cftex.material = cfmat
		card.add_child(cftex)
	else:
		# Lock icon centered
		var lock := TextureRect.new()
		lock.texture      = preload("res://image/lock_chain_x.png")
		lock.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
		lock.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		lock.size         = Vector2(48, 48)
		lock.position     = Vector2((CW - 48) * 0.5, 68)
		lock.modulate     = Color(1, 1, 1, 0.70)
		lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(lock)

		var locked_lbl := Label.new()
		locked_lbl.text = "ยังไม่ค้นพบ"
		locked_lbl.size = Vector2(CW, 22)
		locked_lbl.position = Vector2(0, 128)
		locked_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		locked_lbl.add_theme_font_size_override("font_size", 11)
		locked_lbl.add_theme_color_override("font_color", Color(0.45, 0.5, 0.65, 0.65))
		locked_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(locked_lbl)

	return card


func _make_compound_card(compound: Dictionary, is_found: bool) -> Control:
	const CW := 162.0; const CH := 210.0
	var card := Panel.new()
	card.custom_minimum_size = Vector2(CW, CH)
	card.clip_contents = true

	if is_found:
		card.add_theme_stylebox_override("panel", _flat(
			Color(0.05, 0.10, 0.22, 0.92), Color(0.35, 0.60, 1, 0.40), 10, 1))

		# Formula — large, centered top
		var fml := Label.new()
		fml.text = str(compound.get("formula", ""))
		fml.position = Vector2(0, 14)
		fml.size = Vector2(CW, 64)
		fml.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		fml.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		fml.add_theme_font_size_override("font_size", 32)
		fml.add_theme_color_override("font_color", Color(0.48, 0.84, 1, 0.92))
		fml.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(fml)

		var div1 := ColorRect.new()
		div1.color = Color(0.3, 0.6, 1, 0.18)
		div1.size = Vector2(CW - 24, 1)
		div1.position = Vector2(12, 82)
		div1.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(div1)

		var nm := Label.new()
		nm.text = str(compound.get("name", ""))
		nm.position = Vector2(4, 88)
		nm.size = Vector2(CW - 8, 22)
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		nm.add_theme_font_size_override("font_size", 13)
		nm.add_theme_color_override("font_color", Color(0.88, 0.93, 1, 0.90))
		nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(nm)

		var tp := Label.new()
		tp.text = str(compound.get("type", ""))
		tp.position = Vector2(4, 112)
		tp.size = Vector2(CW - 8, 16)
		tp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tp.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		tp.add_theme_font_size_override("font_size", 8)
		tp.add_theme_color_override("font_color", Color(0.55, 0.75, 1, 0.55))
		tp.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(tp)

		# Description — clipped to card bottom
		_clipped_desc(card, str(compound.get("description", "")),
			8, 132, CW - 16, CH - 136,
			8, Color(0.68, 0.80, 0.92, 0.62))

		# Tier frame overlay — g1.jpg (tier 1) / g2.jpg (tier 2) / g3.jpg (tier 3)
		var comp_tier: int = clampi(int(compound.get("tier", 1)), 1, 3)
		var cftex := TextureRect.new()
		match comp_tier:
			1: cftex.texture = preload("res://image/g1.jpg")
			2: cftex.texture = preload("res://image/g2.jpg")
			_: cftex.texture = preload("res://image/g3.jpg")
		cftex.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
		cftex.stretch_mode = TextureRect.STRETCH_SCALE
		cftex.size         = Vector2(CW + 4, CH + 4)
		cftex.position     = Vector2(-2, -2)
		cftex.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var cfmat := CanvasItemMaterial.new()
		cfmat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		cftex.material = cfmat
		card.add_child(cftex)

		card.gui_input.connect(func(ev):
			if ev is InputEventMouseButton and ev.pressed:
				_open_compound_detail(compound)
		)
	else:
		card.add_theme_stylebox_override("panel", _flat(
			Color(0.06, 0.07, 0.12, 1.0), Color(0.15, 0.18, 0.25, 0.35), 10, 1))

		var lock := TextureRect.new()
		lock.texture      = preload("res://image/lock_chain_x.png")
		lock.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
		lock.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		lock.size         = Vector2(48, 48)
		lock.position     = Vector2((CW - 48) * 0.5, 68)
		lock.modulate     = Color(1, 1, 1, 0.70)
		lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(lock)

		var locked_lbl := Label.new()
		locked_lbl.text = "ยังไม่ค้นพบ"
		locked_lbl.size = Vector2(CW, 22)
		locked_lbl.position = Vector2(0, 128)
		locked_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		locked_lbl.add_theme_font_size_override("font_size", 11)
		locked_lbl.add_theme_color_override("font_color", Color(0.45, 0.5, 0.65, 0.65))
		locked_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(locked_lbl)

	return card

# ── Element detail overlay ────────────────────────────────────────
func _build_detail_overlay() -> void:
	_detail_overlay = Control.new()
	_detail_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_detail_overlay.visible = false
	add_child(_detail_overlay)

	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.7)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed:
			_detail_overlay.visible = false
	)
	_detail_overlay.add_child(dim)

func _open_element_detail(elem: Dictionary) -> void:
	# Clear old card
	for c in _detail_overlay.get_children():
		if c is Panel:
			c.queue_free()

	var col: Color = elem["color"]
	const CW := 480.0; const CH := 420.0
	var card := Panel.new()
	card.size = Vector2(CW, CH)
	card.position = Vector2((1152 - CW) * 0.5, (648 - CH) * 0.5)
	card.clip_contents = true
	card.add_theme_stylebox_override("panel", _flat(
		Color(0.06, 0.08, 0.16, 1.0),
		Color(col.r, col.g, col.b, 0.7), 12, 2
	))
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	_detail_overlay.add_child(card)

	const IW := 440.0  # inner width

	# Symbol large
	var sym := Label.new()
	sym.text = elem["symbol"]
	sym.position = Vector2(20, 14)
	sym.size = Vector2(100, 64)
	sym.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sym.add_theme_font_size_override("font_size", 48)
	sym.add_theme_color_override("font_color", Color(col.r, col.g, col.b, 0.85))
	sym.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(sym)

	if elem["number"] > 0:
		var num := Label.new()
		num.text = "No. %d" % elem["number"]
		num.position = Vector2(24, 78)
		num.size = Vector2(80, 14)
		num.add_theme_font_size_override("font_size", 10)
		num.add_theme_color_override("font_color", Color(col.r, col.g, col.b, 0.5))
		num.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(num)

	# Name
	var name_lbl := Label.new()
	name_lbl.text = elem["name_th"]
	name_lbl.position = Vector2(130, 16)
	name_lbl.size = Vector2(IW - 110, 30)
	name_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_lbl.add_theme_font_size_override("font_size", 22)
	name_lbl.add_theme_color_override("font_color", C_TEXT)
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(name_lbl)

	var eng := Label.new()
	eng.text = elem["name_en"] + "  ·  " + elem["type"]
	eng.position = Vector2(130, 48)
	eng.size = Vector2(IW - 110, 20)
	eng.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	eng.add_theme_font_size_override("font_size", 12)
	eng.add_theme_color_override("font_color", C_SUB)
	eng.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(eng)

	# Divider
	var div := ColorRect.new()
	div.color = Color(col.r, col.g, col.b, 0.2)
	div.size = Vector2(IW, 1)
	div.position = Vector2(20, 100)
	div.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(div)

	# Real-world desc
	var real_title := Label.new()
	real_title.text = "ข้อมูลจริง"
	real_title.position = Vector2(20, 110)
	real_title.size = Vector2(IW, 16)
	real_title.add_theme_font_size_override("font_size", 11)
	real_title.add_theme_color_override("font_color", C_GOLD)
	real_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(real_title)

	# Clip wrapper so autowrap text can't bleed into sections below
	var desc_clip := Panel.new()
	desc_clip.position = Vector2(20, 128)
	desc_clip.size = Vector2(IW, 116)
	desc_clip.clip_contents = true
	desc_clip.add_theme_stylebox_override("panel", _flat(Color(0, 0, 0, 0)))
	desc_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(desc_clip)

	var real_desc := Label.new()
	real_desc.text = elem["real_desc"]
	real_desc.position = Vector2(0, 0)
	real_desc.size = Vector2(IW, 116)
	real_desc.add_theme_font_size_override("font_size", 11)
	real_desc.add_theme_color_override("font_color", Color(0.8, 0.87, 1.0, 0.85))
	real_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	real_desc.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	real_desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	desc_clip.add_child(real_desc)

	# Divider 2
	var div2 := ColorRect.new()
	div2.color = Color(col.r, col.g, col.b, 0.12)
	div2.size = Vector2(IW, 1)
	div2.position = Vector2(20, 250)
	div2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(div2)

	# How to get
	var how_title := Label.new()
	how_title.text = "วิธีได้รับ"
	how_title.position = Vector2(20, 258)
	how_title.size = Vector2(IW, 16)
	how_title.add_theme_font_size_override("font_size", 11)
	how_title.add_theme_color_override("font_color", C_GOLD)
	how_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(how_title)

	var how_clip := Panel.new()
	how_clip.position = Vector2(20, 276)
	how_clip.size = Vector2(IW, 20)
	how_clip.clip_contents = true
	how_clip.add_theme_stylebox_override("panel", _flat(Color(0, 0, 0, 0)))
	how_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(how_clip)

	var how := Label.new()
	how.text = elem["how_to_get"]
	how.position = Vector2(0, 0)
	how.size = Vector2(IW, 20)
	how.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	how.add_theme_font_size_override("font_size", 11)
	how.add_theme_color_override("font_color", Color(0.8, 0.87, 1.0, 0.85))
	how.mouse_filter = Control.MOUSE_FILTER_IGNORE
	how_clip.add_child(how)

	# Divider 3
	var div3 := ColorRect.new()
	div3.color = Color(col.r, col.g, col.b, 0.12)
	div3.size = Vector2(IW, 1)
	div3.position = Vector2(20, 302)
	div3.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(div3)

	# Recipes / effects
	var rec_title := Label.new()
	rec_title.text = "ใช้ทำ / ผลในเกม"
	rec_title.position = Vector2(20, 310)
	rec_title.size = Vector2(IW, 16)
	rec_title.add_theme_font_size_override("font_size", 11)
	rec_title.add_theme_color_override("font_color", C_GOLD)
	rec_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(rec_title)

	var rec_clip := Panel.new()
	rec_clip.position = Vector2(20, 328)
	rec_clip.size = Vector2(IW, CH - 328 - 12)
	rec_clip.clip_contents = true
	rec_clip.add_theme_stylebox_override("panel", _flat(Color(0, 0, 0, 0)))
	rec_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(rec_clip)

	var ry := 0.0
	for r in elem["recipes"]:
		var rl := Label.new()
		rl.text = "• " + r
		rl.position = Vector2(0, ry)
		rl.size = Vector2(IW, 18)
		rl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		rl.add_theme_font_size_override("font_size", 11)
		rl.add_theme_color_override("font_color", Color(0.4, 0.9, 0.65, 0.9))
		rl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rec_clip.add_child(rl)
		ry += 20

	# Close button
	var close_btn := Button.new()
	close_btn.text = "✕"
	close_btn.size = Vector2(32, 32)
	close_btn.position = Vector2(CW - 44, 10)
	close_btn.add_theme_font_size_override("font_size", 14)
	close_btn.add_theme_color_override("font_color", C_SUB)
	close_btn.add_theme_stylebox_override("normal",  _flat(Color(0,0,0,0), Color(0,0,0,0)))
	close_btn.add_theme_stylebox_override("hover",   _flat(Color(1,1,1,0.08), Color(0,0,0,0)))
	close_btn.add_theme_stylebox_override("focus",   _flat(Color(0,0,0,0), Color(0,0,0,0)))
	close_btn.pressed.connect(func(): _detail_overlay.visible = false)
	card.add_child(close_btn)

	_detail_overlay.visible = true

## Detail popup for a discovered "compounds tab" entry — compounds made from
## elements not yet unlocked for battle (Cu, Zn, P, Si), so unlike the
## elements-tab cards there's no in-game "recipes/effect" section; shown
## instead is the compound's real-world use, which the card grid itself
## never had room to display.
func _open_compound_detail(compound: Dictionary) -> void:
	for c in _detail_overlay.get_children():
		if c is Panel:
			c.queue_free()

	const CW := 480.0; const CH := 360.0
	var col := Color(0.35, 0.60, 1.0)
	var card := Panel.new()
	card.size = Vector2(CW, CH)
	card.position = Vector2((1152 - CW) * 0.5, (648 - CH) * 0.5)
	card.clip_contents = true
	card.add_theme_stylebox_override("panel", _flat(
		Color(0.06, 0.08, 0.16, 1.0), Color(col.r, col.g, col.b, 0.7), 12, 2))
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	_detail_overlay.add_child(card)

	const IW := 440.0

	var fml := Label.new()
	fml.text = str(compound.get("formula", ""))
	fml.position = Vector2(20, 14)
	fml.size = Vector2(100, 64)
	fml.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	fml.add_theme_font_size_override("font_size", 40)
	fml.add_theme_color_override("font_color", Color(0.48, 0.84, 1, 0.92))
	fml.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(fml)

	var name_lbl := Label.new()
	name_lbl.text = str(compound.get("name", ""))
	name_lbl.position = Vector2(130, 16)
	name_lbl.size = Vector2(IW - 110, 30)
	name_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_lbl.add_theme_font_size_override("font_size", 22)
	name_lbl.add_theme_color_override("font_color", C_TEXT)
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(name_lbl)

	var sub := Label.new()
	sub.text = "%s · %s" % [str(compound.get("type", "")), str(compound.get("state", ""))]
	sub.position = Vector2(130, 48)
	sub.size = Vector2(IW - 110, 20)
	sub.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	sub.add_theme_font_size_override("font_size", 12)
	sub.add_theme_color_override("font_color", C_SUB)
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(sub)

	var div := ColorRect.new()
	div.color = Color(col.r, col.g, col.b, 0.2)
	div.size = Vector2(IW, 1)
	div.position = Vector2(20, 100)
	div.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(div)

	var real_title := Label.new()
	real_title.text = "ข้อมูลจริง"
	real_title.position = Vector2(20, 110)
	real_title.size = Vector2(IW, 16)
	real_title.add_theme_font_size_override("font_size", 11)
	real_title.add_theme_color_override("font_color", C_GOLD)
	real_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(real_title)

	_clipped_desc(card, str(compound.get("description", "")),
		20, 128, IW, 90, 11, Color(0.8, 0.87, 1.0, 0.85))

	var div2 := ColorRect.new()
	div2.color = Color(col.r, col.g, col.b, 0.12)
	div2.size = Vector2(IW, 1)
	div2.position = Vector2(20, 226)
	div2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(div2)

	var use_title := Label.new()
	use_title.text = "การใช้งานจริง"
	use_title.position = Vector2(20, 234)
	use_title.size = Vector2(IW, 16)
	use_title.add_theme_font_size_override("font_size", 11)
	use_title.add_theme_color_override("font_color", C_GOLD)
	use_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(use_title)

	_clipped_desc(card, str(compound.get("real_use", "")),
		20, 252, IW, 60, 11, Color(0.8, 0.87, 1.0, 0.85))

	var rarity_lbl := Label.new()
	rarity_lbl.text = "★".repeat(clampi(int(compound.get("rarity", 1)), 1, 5))
	rarity_lbl.position = Vector2(20, CH - 44)
	rarity_lbl.size = Vector2(IW, 22)
	rarity_lbl.add_theme_font_size_override("font_size", 14)
	rarity_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3, 0.9))
	rarity_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(rarity_lbl)

	var close_btn := Button.new()
	close_btn.text = "✕"
	close_btn.size = Vector2(32, 32)
	close_btn.position = Vector2(CW - 44, 10)
	close_btn.add_theme_font_size_override("font_size", 14)
	close_btn.add_theme_color_override("font_color", C_SUB)
	close_btn.add_theme_stylebox_override("normal",  _flat(Color(0,0,0,0), Color(0,0,0,0)))
	close_btn.add_theme_stylebox_override("hover",   _flat(Color(1,1,1,0.08), Color(0,0,0,0)))
	close_btn.add_theme_stylebox_override("focus",   _flat(Color(0,0,0,0), Color(0,0,0,0)))
	close_btn.pressed.connect(func(): _detail_overlay.visible = false)
	card.add_child(close_btn)

	_detail_overlay.visible = true

# ── Helpers ───────────────────────────────────────────────────────
func _section_label(txt: String) -> Control:
	var lbl := Label.new()
	lbl.text = txt
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", C_SUB)
	var wrap := MarginContainer.new()
	wrap.add_theme_constant_override("margin_left", 24)
	wrap.add_theme_constant_override("margin_top", 14)
	wrap.add_theme_constant_override("margin_bottom", 4)
	wrap.add_child(lbl)
	return wrap

func _make_back_btn(pos: Vector2, sz: Vector2, callback: Callable) -> Control:
	var btn := Panel.new()
	btn.position = pos
	btn.z_index = 20
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.0, 0.05, 0.15, 0.55)
	sb.border_color = Color(0.45, 0.72, 1.0, 0.90)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(22)
	btn.add_theme_stylebox_override("panel", sb)
	btn.size        = Vector2(42, 45)
	btn.pivot_offset = Vector2(21, 22)
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	var icon := TextureRect.new()
	icon.texture      = preload("res://image/back.png")
	icon.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(icon)
	btn.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			var tw := btn.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
			tw.tween_property(btn, "scale", Vector2(0.78, 0.78), 0.08)
			tw.tween_property(btn, "scale", Vector2(1.0,  1.0),  0.22)
			tw.tween_callback(callback)
	)
	btn.mouse_entered.connect(func():
		var tw := btn.create_tween().set_ease(Tween.EASE_OUT)
		tw.tween_property(btn, "modulate", Color(1.15, 1.15, 1.2, 1.0), 0.10)
	)
	btn.mouse_exited.connect(func():
		var tw := btn.create_tween().set_ease(Tween.EASE_OUT)
		tw.tween_property(btn, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.12)
	)
	return btn

func _go_back() -> void:
	SceneTransition.fade_to(SC_MAIN)
