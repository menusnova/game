extends Node

const ELEMENTS: Array[Dictionary] = [
	{"symbol": "H",  "name": "Hydrogen",   "color": Color(0.40, 0.70, 1.00), "unlocked": true,  "desc": "ธาตุเบาที่สุดในจักรวาล เชื้อเพลิงดาวฤกษ์ พบ 75% ของมวลสสารทั้งหมด"},
	{"symbol": "O",  "name": "Oxygen",     "color": Color(0.90, 0.30, 0.20), "unlocked": true,  "desc": "ก๊าซที่จำเป็นต่อการหายใจและการเผาไหม้ ครอบคลุม 21% ของบรรยากาศโลก"},
	{"symbol": "Na", "name": "Sodium",     "color": Color(1.00, 0.80, 0.15), "unlocked": true,  "desc": "โลหะอ่อนสีเงิน ทำปฏิกิริยารุนแรงกับน้ำ สำคัญต่อระบบประสาทของสิ่งมีชีวิต"},
	{"symbol": "Cl", "name": "Chlorine",   "color": Color(0.50, 0.90, 0.20), "unlocked": true,  "desc": "ก๊าซสีเขียวอมเหลืองมีพิษ ใช้ฆ่าเชื้อในน้ำประปาและสระว่ายน้ำ"},
	{"symbol": "C",  "name": "Carbon",     "color": Color(0.55, 0.55, 0.60), "unlocked": true,  "desc": "รากฐานของสารอินทรีย์ทั้งหมด พบได้ทั้งในรูปเพชรและถ่านหิน"},
	{"symbol": "Fe", "name": "Iron",       "color": Color(0.70, 0.45, 0.20), "unlocked": true,  "desc": "โลหะที่ใช้มากที่สุดในโลก แกนโลกประกอบด้วยเหล็กเป็นหลัก"},
	{"symbol": "N",  "name": "Nitrogen",   "color": Color(0.35, 0.50, 0.95), "unlocked": true,  "desc": "ก๊าซที่มากที่สุดในบรรยากาศ (78%) สำคัญต่อการสร้างโปรตีนและ DNA"},
	{"symbol": "S",  "name": "Sulfur",     "color": Color(1.00, 0.85, 0.10), "unlocked": true,  "desc": "ของแข็งสีเหลือง กลิ่นฉุน พบในภูเขาไฟ ใช้ผลิตกรดซัลฟิวริก"},
	{"symbol": "Ca", "name": "Calcium",    "color": Color(0.80, 0.75, 0.65), "unlocked": true,  "desc": "โลหะที่พบมากที่สุดในร่างกายมนุษย์ สร้างกระดูกและฟัน"},
	{"symbol": "Mg", "name": "Magnesium",  "color": Color(0.60, 0.85, 0.60), "unlocked": true,  "desc": "โลหะเบาที่ติดไฟได้ สำคัญต่อคลอโรฟิลล์และการสังเคราะห์แสง"},
	{"symbol": "K",  "name": "Potassium",  "color": Color(0.75, 0.30, 0.70), "unlocked": true,  "desc": "แร่ธาตุที่ควบคุมความดันโลหิตและการทำงานของกล้ามเนื้อหัวใจ"},
	{"symbol": "Cu", "name": "Copper",     "color": Color(0.20, 0.65, 0.40), "unlocked": false, "desc": "โลหะนำไฟฟ้าดีเยี่ยม มนุษย์ใช้มากว่า 10,000 ปี สีแดง-ส้มเป็นเอกลักษณ์"},
	{"symbol": "Zn", "name": "Zinc",       "color": Color(0.55, 0.70, 0.75), "unlocked": false, "desc": "โลหะสีขาวอมฟ้า ป้องกันสนิม สำคัญต่อระบบภูมิคุ้มกันของร่างกาย"},
	{"symbol": "P",  "name": "Phosphorus", "color": Color(0.90, 0.50, 0.15), "unlocked": false, "desc": "ธาตุสำคัญใน DNA และ ATP แหล่งพลังงานของเซลล์สิ่งมีชีวิตทุกชนิด"},
	{"symbol": "Si", "name": "Silicon",    "color": Color(0.45, 0.55, 0.65), "unlocked": false, "desc": "กึ่งตัวนำพื้นฐานของยุคดิจิทัล ทรายแก้วและชิปคอมพิวเตอร์ล้วนมาจาก Si"},
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
		"name": "Water", "formula": "H₂O", "tier": 1,
		"type": "Inorganic", "state": "Liquid",
		"description": "โมเลกุลพื้นฐานของสิ่งมีชีวิต ครอบคลุม 71% ของพื้นผิวโลก",
		"real_use": "ดื่มกิน เกษตรกรรม อุตสาหกรรม", "rarity": 1,
	},
	"salt": {
		"name": "Salt", "formula": "NaCl", "tier": 1,
		"type": "Ionic Compound", "state": "Solid",
		"description": "เกลือแกงหรือโซเดียมคลอไรด์ สารประกอบไอออนิกที่พบทั่วไปในธรรมชาติ",
		"real_use": "ปรุงอาหาร ถนอมอาหาร อุตสาหกรรมเคมี", "rarity": 1,
	},
	"rust": {
		"name": "Rust", "formula": "Fe₂O₃", "tier": 1,
		"type": "Metal Oxide", "state": "Solid",
		"description": "ออกไซด์ของเหล็กที่เกิดจากปฏิกิริยาออกซิเดชันเมื่อสัมผัสอากาศและความชื้น",
		"real_use": "สีผสมเม็ดสี วัสดุก่อสร้าง", "rarity": 1,
	},
	"hydrochloric_acid": {
		"name": "Hydrochloric Acid", "formula": "HCl", "tier": 1,
		"type": "Strong Acid", "state": "Liquid",
		"description": "กรดเกลือ สารละลายกรดแก่ที่สำคัญในอุตสาหกรรม มีฤทธิ์กัดกร่อนสูง",
		"real_use": "ทำความสะอาดโลหะ ผลิตสารเคมี อาหาร", "rarity": 2,
	},
	"carbon_dioxide": {
		"name": "Carbon Dioxide", "formula": "CO₂", "tier": 1,
		"type": "Inorganic Gas", "state": "Gas",
		"description": "แก๊สที่เกิดจากการหายใจและการเผาไหม้ ส่วนสำคัญของวัฏจักรคาร์บอน",
		"real_use": "เครื่องดื่มอัดลม ถังดับเพลิง ปุ๋ย", "rarity": 1,
	},
	"nitric_oxide": {
		"name": "Nitric Oxide", "formula": "NO", "tier": 2,
		"type": "Inorganic Gas", "state": "Gas",
		"description": "สารสื่อนำประสาทและสารควบคุมหลอดเลือด ค้นพบในบรรยากาศโลก",
		"real_use": "การแพทย์ ผลิตกรดไนตริก", "rarity": 3,
	},
	"sulfur_dioxide": {
		"name": "Sulfur Dioxide", "formula": "SO₂", "tier": 1,
		"type": "Inorganic Gas", "state": "Gas",
		"description": "แก๊สที่เกิดจากการเผาไหม้กำมะถัน มีกลิ่นฉุน พบในภูเขาไฟ",
		"real_use": "ถนอมอาหาร ฟอกขาว ผลิตกรดซัลฟิวริก", "rarity": 2,
	},
	"iron_sulfide": {
		"name": "Iron Sulfide", "formula": "FeS", "tier": 1,
		"type": "Mineral", "state": "Solid",
		"description": "แร่ธาตุที่พบในธรรมชาติ หรือที่รู้จักในชื่อ 'ทองของคนโง่' (Fool's Gold)",
		"real_use": "ผลิตกำมะถัน วัสดุกึ่งตัวนำ", "rarity": 2,
	},
	"calcium_oxide": {
		"name": "Calcium Oxide", "formula": "CaO", "tier": 1,
		"type": "Metal Oxide", "state": "Solid",
		"description": "ปูนขาว วัสดุก่อสร้างที่มนุษย์ใช้มานานกว่า 5,000 ปี",
		"real_use": "ก่อสร้าง บำบัดน้ำ เกษตรกรรม", "rarity": 1,
	},
	"magnesium_oxide": {
		"name": "Magnesium Oxide", "formula": "MgO", "tier": 1,
		"type": "Metal Oxide", "state": "Solid",
		"description": "ออกไซด์ของแมกนีเซียม ทนความร้อนได้สูงมาก จุดหลอมเหลว 2,852°C",
		"real_use": "วัสดุทนไฟ ยารักษาโรค ปุ๋ย", "rarity": 2,
	},
	"zinc_oxide": {
		"name": "Zinc Oxide", "formula": "ZnO", "tier": 1,
		"type": "Metal Oxide", "state": "Solid",
		"description": "ผงสีขาวที่ใช้ในเครื่องสำอางและการแพทย์ ดูดซับรังสี UV ได้ดี",
		"real_use": "ครีมกันแดด ยาทาผิว สี", "rarity": 2,
	},
	"copper_oxide": {
		"name": "Copper Oxide", "formula": "CuO", "tier": 2,
		"type": "Metal Oxide", "state": "Solid",
		"description": "ออกไซด์ของทองแดง ผงสีดำ ใช้ในเซรามิกเพื่อให้สีเขียว-น้ำเงิน",
		"real_use": "เซรามิก แก้ว ตัวเร่งปฏิกิริยา", "rarity": 3,
	},
	"sodium_hydride": {
		"name": "Sodium Hydride", "formula": "NaH", "tier": 2,
		"type": "Metal Hydride", "state": "Solid",
		"description": "สารประกอบโลหะไฮไดรด์ที่มีฤทธิ์แรง ทำปฏิกิริยากับน้ำรุนแรงมาก",
		"real_use": "สังเคราะห์สารอินทรีย์ ตัวรีดิวซ์", "rarity": 3,
	},
	"potassium_oxide": {
		"name": "Potassium Oxide", "formula": "K₂O", "tier": 2,
		"type": "Metal Oxide", "state": "Solid",
		"description": "ออกไซด์ของโพแทสเซียม ทำปฏิกิริยากับน้ำได้ด่างโพแทสเซียมไฮดรอกไซด์",
		"real_use": "ปุ๋ย แก้ว", "rarity": 3,
	},
	"silicon_dioxide": {
		"name": "Silicon Dioxide", "formula": "SiO₂", "tier": 1,
		"type": "Mineral", "state": "Solid",
		"description": "ซิลิกาหรือทรายแก้ว วัสดุพื้นฐานของโลก พบมากที่สุดในเปลือกโลก",
		"real_use": "แก้ว เซรามิก เซมิคอนดักเตอร์", "rarity": 1,
	},
	"methane": {
		"name": "Methane", "formula": "CH₄", "tier": 1,
		"type": "Organic Gas", "state": "Gas",
		"description": "ก๊าซธรรมชาติ สารอินทรีย์ที่ง่ายที่สุด เกิดจากการย่อยสลายของสิ่งมีชีวิต",
		"real_use": "เชื้อเพลิง ผลิตไฮโดรเจน", "rarity": 2,
	},
	"hydrogen_sulfide": {
		"name": "Hydrogen Sulfide", "formula": "H₂S", "tier": 1,
		"type": "Inorganic Gas", "state": "Gas",
		"description": "แก๊สกลิ่นไข่เน่า มีพิษสูง พบในภูเขาไฟและบ่อน้ำมัน",
		"real_use": "ผลิตกำมะถัน วิเคราะห์แร่", "rarity": 2,
	},
	"calcium_hydride": {
		"name": "Calcium Hydride", "formula": "CaH₂", "tier": 2,
		"type": "Metal Hydride", "state": "Solid",
		"description": "สารผลึกสีขาว ดูดความชื้นได้ดี ทำปฏิกิริยากับน้ำปล่อยก๊าซ H₂",
		"real_use": "ผลิตไฮโดรเจน ดูดความชื้น", "rarity": 3,
	},
	"sodium_nitride": {
		"name": "Sodium Nitride", "formula": "Na₃N", "tier": 2,
		"type": "Ionic Compound", "state": "Solid",
		"description": "สารประกอบที่ไม่เสถียร สลายตัวได้ง่าย หายากในธรรมชาติ",
		"real_use": "วิจัยเคมี", "rarity": 4,
	},
	"calcium_carbide": {
		"name": "Calcium Carbide", "formula": "CaC₂", "tier": 2,
		"type": "Carbide", "state": "Solid",
		"description": "สารประกอบคาร์ไบด์ ทำปฏิกิริยากับน้ำให้แก๊สอะเซทิลีน (C₂H₂)",
		"real_use": "ผลิตอะเซทิลีน เชื่อมโลหะ", "rarity": 3,
	},
}

const REACTIONS3: Dictionary = {
	"C+H+O":   "acetic_acid",
	"Fe+O+S":  "iron_sulfate",
	"C+Ca+O":  "calcium_carbonate_pure",
	"Cu+O+S":  "copper_sulfate",
	"H+N+O":   "nitric_acid",
	"H+O+S":   "sulfuric_acid",
	"K+N+O":   "potassium_nitrate",
	"C+Na+O":  "sodium_carbonate",
	"Cu+Fe+S": "chalcopyrite",
}

const COMPOUNDS3: Dictionary = {
	"acetic_acid": {
		"name": "Acetic Acid", "formula": "CH₃COOH", "tier": 2,
		"type": "Organic Acid", "state": "Liquid",
		"description": "กรดอินทรีย์ที่พบในน้ำส้มสายชู มีกลิ่นฉุน ใช้แพร่หลายในอาหารและอุตสาหกรรม",
		"real_use": "น้ำส้มสายชู ตัวทำละลาย ผลิตพลาสติก", "rarity": 4,
	},
	"iron_sulfate": {
		"name": "Iron(II) Sulfate", "formula": "FeSO₄", "tier": 2,
		"type": "Inorganic Salt", "state": "Solid",
		"description": "เกลือเหล็กสีเขียว ละลายน้ำได้ดี ใช้รักษาโรคโลหิตจาง",
		"real_use": "ปุ๋ย ยารักษาโลหิตจาง หมึกเขียน", "rarity": 4,
	},
	"calcium_carbonate_pure": {
		"name": "Calcium Carbonate (Pure)", "formula": "CaCO₃★", "tier": 2,
		"type": "Mineral Compound", "state": "Solid",
		"description": "แคลเซียมคาร์บอเนตบริสุทธิ์ สังเคราะห์จาก 3 ธาตุ มีคุณภาพสูงกว่าปกติมาก",
		"real_use": "ยาลดกรด แก้วคุณภาพสูง ปูนซีเมนต์พิเศษ", "rarity": 4,
	},
	"copper_sulfate": {
		"name": "Copper(II) Sulfate", "formula": "CuSO₄", "tier": 2,
		"type": "Inorganic Salt", "state": "Solid",
		"description": "คริสตัลสีน้ำเงินสดใส ใช้กันแพร่หลายในเกษตรและอุตสาหกรรมไฟฟ้า",
		"real_use": "ยาฆ่าเชื้อรา ชุบโลหะไฟฟ้า วิเคราะห์โปรตีน", "rarity": 4,
	},
	"nitric_acid": {
		"name": "Nitric Acid", "formula": "HNO₃", "tier": 2,
		"type": "Strong Acid", "state": "Liquid",
		"description": "กรดแก่กัดกร่อนรุนแรง ทำปฏิกิริยากับโลหะหลายชนิด สีเหลืองจากการสลายตัว",
		"real_use": "ผลิตปุ๋ยไนโตรเจน วัตถุระเบิด ชุบโลหะ", "rarity": 4,
	},
	"sulfuric_acid": {
		"name": "Sulfuric Acid", "formula": "H₂SO₄", "tier": 3,
		"type": "Strong Acid", "state": "Liquid",
		"description": "กรดแก่ที่สำคัญที่สุดในอุตสาหกรรม ดูดความชื้นสูง ทำปฏิกิริยารุนแรงกับสารอินทรีย์",
		"real_use": "ผลิตปุ๋ย แบตเตอรี่กรด การกลั่นน้ำมัน", "rarity": 5,
	},
	"potassium_nitrate": {
		"name": "Potassium Nitrate", "formula": "KNO₃", "tier": 3,
		"type": "Inorganic Salt", "state": "Solid",
		"description": "ดินประสิว ส่วนผสมหลักของดินปืน สารออกซิไดเซอร์ทรงพลัง เผาไหม้ได้เองในอากาศ",
		"real_use": "ดินปืน ดอกไม้ไฟ ปุ๋ย ถนอมอาหาร", "rarity": 5,
	},
	"sodium_carbonate": {
		"name": "Sodium Carbonate", "formula": "Na₂CO₃", "tier": 3,
		"type": "Inorganic Salt", "state": "Solid",
		"description": "โซดาแอช แอลคาไลน์แก่ ใช้ในอุตสาหกรรมแก้วและสิ่งทอมาหลายศตวรรษ",
		"real_use": "ผลิตแก้ว สบู่ กระดาษ ฟอกผ้า", "rarity": 5,
	},
	"chalcopyrite": {
		"name": "Chalcopyrite", "formula": "CuFeS₂", "tier": 3,
		"type": "Mineral Ore", "state": "Solid",
		"description": "แร่ทองแดงที่สำคัญที่สุดในโลก ประกายทองแดง-เหลือง พบใน hydrothermal veins",
		"real_use": "แหล่งทองแดงหลักของโลก วัสดุนำไฟฟ้า", "rarity": 5,
	},
}

func get_reaction(sym1: String, sym2: String) -> String:
	return REACTIONS.get(_reaction_key(sym1, sym2), "")

func get_reaction3(sym1: String, sym2: String, sym3: String) -> String:
	return REACTIONS3.get(_reaction_key3(sym1, sym2, sym3), "")

func get_compound(key: String) -> Dictionary:
	var c: Dictionary = COMPOUNDS.get(key, {})
	if c.is_empty():
		c = COMPOUNDS3.get(key, {})
	return c

func get_total_compounds() -> int:
	return COMPOUNDS.size() + COMPOUNDS3.size()

func _reaction_key(a: String, b: String) -> String:
	var arr: Array[String] = [a, b]
	arr.sort()
	return "+".join(arr)

func _reaction_key3(a: String, b: String, c: String) -> String:
	var arr: Array[String] = [a, b, c]
	arr.sort()
	return "+".join(arr)
