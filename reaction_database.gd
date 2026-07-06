extends Node

const ELEMENTS: Array[Dictionary] = [
	{"symbol": "H",  "name": "Hydrogen",   "color": Color(0.40, 0.70, 1.00), "unlocked": true},
	{"symbol": "O",  "name": "Oxygen",     "color": Color(0.90, 0.30, 0.20), "unlocked": true},
	{"symbol": "Na", "name": "Sodium",     "color": Color(1.00, 0.80, 0.15), "unlocked": true},
	{"symbol": "Cl", "name": "Chlorine",   "color": Color(0.50, 0.90, 0.20), "unlocked": true},
	{"symbol": "C",  "name": "Carbon",     "color": Color(0.55, 0.55, 0.60), "unlocked": true},
	{"symbol": "Fe", "name": "Iron",       "color": Color(0.70, 0.45, 0.20), "unlocked": true},
	{"symbol": "N",  "name": "Nitrogen",   "color": Color(0.35, 0.50, 0.95), "unlocked": true},
	{"symbol": "S",  "name": "Sulfur",     "color": Color(1.00, 0.85, 0.10), "unlocked": true},
	{"symbol": "Ca", "name": "Calcium",    "color": Color(0.80, 0.75, 0.65), "unlocked": true},
	{"symbol": "Mg", "name": "Magnesium",  "color": Color(0.60, 0.85, 0.60), "unlocked": true},
	{"symbol": "K",  "name": "Potassium",  "color": Color(0.75, 0.30, 0.70), "unlocked": true},
	{"symbol": "Cu", "name": "Copper",     "color": Color(0.20, 0.65, 0.40), "unlocked": false},
	{"symbol": "Zn", "name": "Zinc",       "color": Color(0.55, 0.70, 0.75), "unlocked": false},
	{"symbol": "P",  "name": "Phosphorus", "color": Color(0.90, 0.50, 0.15), "unlocked": false},
	{"symbol": "Si", "name": "Silicon",    "color": Color(0.45, 0.55, 0.65), "unlocked": false},
]

# Keys are sorted alphabetically: "A+B" where A < B lexicographically
const REACTIONS: Dictionary = {
	"H+O":   "water",
	"Cl+Na": "salt",
	"Fe+O":  "rust",
	"Cl+H":  "hydrochloric_acid",
	"C+O":   "carbon_dioxide",
	"N+O":   "nitric_oxide",
	"O+S":   "sulfur_dioxide",
	"Fe+S":  "iron_sulfide",
	"Ca+O":  "calcium_oxide",
	"Mg+O":  "magnesium_oxide",
	"O+Zn":  "zinc_oxide",
	"Cu+O":  "copper_oxide",
	"H+Na":  "sodium_hydride",
	"K+O":   "potassium_oxide",
	"O+Si":  "silicon_dioxide",
	"C+H":   "methane",
	"H+S":   "hydrogen_sulfide",
	"Ca+H":  "calcium_hydride",
	"N+Na":  "sodium_nitride",
	"C+Ca":  "calcium_carbide",
}

const COMPOUNDS: Dictionary = {
	"water": {
		"name": "Water", "formula": "H₂O",
		"type": "Inorganic", "state": "Liquid",
		"description": "โมเลกุลพื้นฐานของสิ่งมีชีวิต ครอบคลุม 71% ของพื้นผิวโลก",
		"real_use": "ดื่มกิน เกษตรกรรม อุตสาหกรรม", "rarity": 1,
	},
	"salt": {
		"name": "Salt", "formula": "NaCl",
		"type": "Ionic Compound", "state": "Solid",
		"description": "เกลือแกงหรือโซเดียมคลอไรด์ สารประกอบไอออนิกที่พบทั่วไปในธรรมชาติ",
		"real_use": "ปรุงอาหาร ถนอมอาหาร อุตสาหกรรมเคมี", "rarity": 1,
	},
	"rust": {
		"name": "Rust", "formula": "Fe₂O₃",
		"type": "Metal Oxide", "state": "Solid",
		"description": "ออกไซด์ของเหล็กที่เกิดจากปฏิกิริยาออกซิเดชันเมื่อสัมผัสอากาศและความชื้น",
		"real_use": "สีผสมเม็ดสี วัสดุก่อสร้าง", "rarity": 1,
	},
	"hydrochloric_acid": {
		"name": "Hydrochloric Acid", "formula": "HCl",
		"type": "Strong Acid", "state": "Liquid",
		"description": "กรดเกลือ สารละลายกรดแก่ที่สำคัญในอุตสาหกรรม มีฤทธิ์กัดกร่อนสูง",
		"real_use": "ทำความสะอาดโลหะ ผลิตสารเคมี อาหาร", "rarity": 2,
	},
	"carbon_dioxide": {
		"name": "Carbon Dioxide", "formula": "CO₂",
		"type": "Inorganic Gas", "state": "Gas",
		"description": "แก๊สที่เกิดจากการหายใจและการเผาไหม้ ส่วนสำคัญของวัฏจักรคาร์บอน",
		"real_use": "เครื่องดื่มอัดลม ถังดับเพลิง ปุ๋ย", "rarity": 1,
	},
	"nitric_oxide": {
		"name": "Nitric Oxide", "formula": "NO",
		"type": "Inorganic Gas", "state": "Gas",
		"description": "สารสื่อนำประสาทและสารควบคุมหลอดเลือด ค้นพบในบรรยากาศโลก",
		"real_use": "การแพทย์ ผลิตกรดไนตริก", "rarity": 3,
	},
	"sulfur_dioxide": {
		"name": "Sulfur Dioxide", "formula": "SO₂",
		"type": "Inorganic Gas", "state": "Gas",
		"description": "แก๊สที่เกิดจากการเผาไหม้กำมะถัน มีกลิ่นฉุน พบในภูเขาไฟ",
		"real_use": "ถนอมอาหาร ฟอกขาว ผลิตกรดซัลฟิวริก", "rarity": 2,
	},
	"iron_sulfide": {
		"name": "Iron Sulfide", "formula": "FeS",
		"type": "Mineral", "state": "Solid",
		"description": "แร่ธาตุที่พบในธรรมชาติ หรือที่รู้จักในชื่อ 'ทองของคนโง่' (Fool's Gold)",
		"real_use": "ผลิตกำมะถัน วัสดุกึ่งตัวนำ", "rarity": 2,
	},
	"calcium_oxide": {
		"name": "Calcium Oxide", "formula": "CaO",
		"type": "Metal Oxide", "state": "Solid",
		"description": "ปูนขาว วัสดุก่อสร้างที่มนุษย์ใช้มานานกว่า 5,000 ปี",
		"real_use": "ก่อสร้าง บำบัดน้ำ เกษตรกรรม", "rarity": 1,
	},
	"magnesium_oxide": {
		"name": "Magnesium Oxide", "formula": "MgO",
		"type": "Metal Oxide", "state": "Solid",
		"description": "ออกไซด์ของแมกนีเซียม ทนความร้อนได้สูงมาก จุดหลอมเหลว 2,852°C",
		"real_use": "วัสดุทนไฟ ยารักษาโรค ปุ๋ย", "rarity": 2,
	},
	"zinc_oxide": {
		"name": "Zinc Oxide", "formula": "ZnO",
		"type": "Metal Oxide", "state": "Solid",
		"description": "ผงสีขาวที่ใช้ในเครื่องสำอางและการแพทย์ ดูดซับรังสี UV ได้ดี",
		"real_use": "ครีมกันแดด ยาทาผิว สี", "rarity": 2,
	},
	"copper_oxide": {
		"name": "Copper Oxide", "formula": "CuO",
		"type": "Metal Oxide", "state": "Solid",
		"description": "ออกไซด์ของทองแดง ผงสีดำ ใช้ในเซรามิกเพื่อให้สีเขียว-น้ำเงิน",
		"real_use": "เซรามิก แก้ว ตัวเร่งปฏิกิริยา", "rarity": 3,
	},
	"sodium_hydride": {
		"name": "Sodium Hydride", "formula": "NaH",
		"type": "Metal Hydride", "state": "Solid",
		"description": "สารประกอบโลหะไฮไดรด์ที่มีฤทธิ์แรง ทำปฏิกิริยากับน้ำรุนแรงมาก",
		"real_use": "สังเคราะห์สารอินทรีย์ ตัวรีดิวซ์", "rarity": 3,
	},
	"potassium_oxide": {
		"name": "Potassium Oxide", "formula": "K₂O",
		"type": "Metal Oxide", "state": "Solid",
		"description": "ออกไซด์ของโพแทสเซียม ทำปฏิกิริยากับน้ำได้ด่างโพแทสเซียมไฮดรอกไซด์",
		"real_use": "ปุ๋ย แก้ว", "rarity": 3,
	},
	"silicon_dioxide": {
		"name": "Silicon Dioxide", "formula": "SiO₂",
		"type": "Mineral", "state": "Solid",
		"description": "ซิลิกาหรือทรายแก้ว วัสดุพื้นฐานของโลก พบมากที่สุดในเปลือกโลก",
		"real_use": "แก้ว เซรามิก เซมิคอนดักเตอร์", "rarity": 1,
	},
	"methane": {
		"name": "Methane", "formula": "CH₄",
		"type": "Organic Gas", "state": "Gas",
		"description": "ก๊าซธรรมชาติ สารอินทรีย์ที่ง่ายที่สุด เกิดจากการย่อยสลายของสิ่งมีชีวิต",
		"real_use": "เชื้อเพลิง ผลิตไฮโดรเจน", "rarity": 2,
	},
	"hydrogen_sulfide": {
		"name": "Hydrogen Sulfide", "formula": "H₂S",
		"type": "Inorganic Gas", "state": "Gas",
		"description": "แก๊สกลิ่นไข่เน่า มีพิษสูง พบในภูเขาไฟและบ่อน้ำมัน",
		"real_use": "ผลิตกำมะถัน วิเคราะห์แร่", "rarity": 2,
	},
	"calcium_hydride": {
		"name": "Calcium Hydride", "formula": "CaH₂",
		"type": "Metal Hydride", "state": "Solid",
		"description": "สารผลึกสีขาว ดูดความชื้นได้ดี ทำปฏิกิริยากับน้ำปล่อยก๊าซ H₂",
		"real_use": "ผลิตไฮโดรเจน ดูดความชื้น", "rarity": 3,
	},
	"sodium_nitride": {
		"name": "Sodium Nitride", "formula": "Na₃N",
		"type": "Ionic Compound", "state": "Solid",
		"description": "สารประกอบที่ไม่เสถียร สลายตัวได้ง่าย หายากในธรรมชาติ",
		"real_use": "วิจัยเคมี", "rarity": 4,
	},
	"calcium_carbide": {
		"name": "Calcium Carbide", "formula": "CaC₂",
		"type": "Carbide", "state": "Solid",
		"description": "สารประกอบคาร์ไบด์ ทำปฏิกิริยากับน้ำให้แก๊สอะเซทิลีน (C₂H₂)",
		"real_use": "ผลิตอะเซทิลีน เชื่อมโลหะ", "rarity": 3,
	},
}

func get_reaction(sym1: String, sym2: String) -> String:
	return REACTIONS.get(_reaction_key(sym1, sym2), "")

func get_compound(key: String) -> Dictionary:
	return COMPOUNDS.get(key, {})

func _reaction_key(a: String, b: String) -> String:
	var arr := [a, b]
	arr.sort()
	return "+".join(arr)
