#!/usr/bin/env bash
# ระบบตรวจสอบความเป็นธรรมชาติของงานเขียน (ออฟไลน์): ความหนาแน่นของคำเชื่อม/คำพูดกลวง, สถิติความยาวประโยค, ความหนาแน่นของคำนามธรรม

set -e

SCRIPT_DIR=$(dirname "$0")
source "$SCRIPT_DIR/common.sh"

PROJECT_ROOT=$(get_project_root)

FILE_PATH="$1"
if [ -z "$FILE_PATH" ] || [ ! -f "$FILE_PATH" ]; then
  echo "วิธีใช้: scripts/bash/text-audit.sh <ชื่อไฟล์>"
  exit 1
fi

# เลือกการตั้งค่า: จัดลำดับความสำคัญของโครงการ spec/knowledge ก่อน หากไม่มีให้ใช้ .specify/templates/knowledge
CFG_PROJECT="$PROJECT_ROOT/spec/knowledge/audit-config.json"
CFG_TEMPLATE="$PROJECT_ROOT/.specify/templates/knowledge/audit-config.json"
if [ -f "$CFG_PROJECT" ]; then
  CFG="$CFG_PROJECT"
elif [ -f "$CFG_TEMPLATE" ]; then
  CFG="$CFG_TEMPLATE"
else
  CFG=""
fi

python3 - "$FILE_PATH" "$CFG" << 'PY'
import json, re, sys, os, math

path = sys.argv[1]
cfg_path = sys.argv[2] if len(sys.argv) > 2 else ''

text = open(path, 'r', encoding='utf-8', errors='ignore').read()

# ค่าคอนฟิกเริ่มต้นสำห รับการตรวจจับกลุ่มคำ (คำแปลภาษาไทยถูกจัดเตรียมไว้สำหรับใช้เทียบเคียงในโค้ด) default_cfg = {
"connector_phrases": ["First","Second","Again","Then","However","In conclusion","To some extent","As is known","At present","As"], # คำเชื่อม: ก่อนอื่น, ถัดมา, อีกครั้ง, จากนั้น, อย่างไรก็ตาม, สรุปก็คือ, กล่าวโดยสรุป, ในระดับหนึ่ง, เป็นที่รู้กันดี, ในปัจจุบัน, ตามที่/ด้วยการที่

"empty_phrases": ["widely concerned", "aroused heated discussion", "far-reaching impact", "of great significance", "effectively improved", "has certain guiding significance", "worthy of our consideration"], # คำพูดกลวง/คำสำเร็จรูป: ได้รับความสนใจอย่างกว้างขวาง, เป็นที่ถกเถียงอย่างร้อนแรง, มีผลกระทบอันลึกซึ้ง, มีความหมายอันสำคัญยิ่ง, ยกระดับได้อย่างมีประสิทธิภาพ, มีคุณค่าในการชี้นำในระดับหนึ่ง, ควรค่าแก่การขบคิด 
"cliche_pairs": [], 
"sentence_length": {"max_run_long":4, "max_run_short":5, "short_threshold":12, "long_threshold":35}, # ความยาวประโยค: เกณฑ์ประโยคสั้นอยู่ที่ 12, ประโยคยาวอยู่ที่ 35 อักขระ 
"abstract_nouns": ["value","meaning","cognition","system","model","path","methodology","trend"], # คำนามธรรม: คุณค่า, ความหมาย, การรับรู้, ระบบ/กลไก, รูปแบบ/โมเดล, เส้นทาง/แนวทาง, ระเบียบวิธี, แนวโน้ม 
"min_concrete_details": 3
}

cfg = default_cfg
if cfg_path and os.path.exists(cfg_path):
  try:
    with open(cfg_path, 'r', encoding='utf-8') as f:
      loaded = json.load(f)
      cfg.update(loaded)
  except Exception:
    pass

def count_occurrences(text, phrases):
  res = {}
  for p in phrases:
    if not p: continue
    res[p] = len(re.findall(re.escape(p), text))
  return res

def split_sentences(t):
  parts = re.split(r'[。！？!?\n]+', t)
  return [s.strip() for s in parts if s.strip()]

def sentence_lengths(sents):
  lens = [len(s) for s in sents]
  if not lens:
    return lens, 0, 0
  avg = sum(lens)/len(lens)
  var = sum((x-avg)**2 for x in lens)/len(lens)
  return lens, avg, math.sqrt(var)

def runs(lens, short_th, long_th):
  run_short = 0; run_long = 0
  max_run_short = 0; max_run_long = 0
  marks = []
  for i, L in enumerate(lens):
    if L <= short_th:
      run_short += 1; max_run_short = max(max_run_short, run_short); run_long = 0
    elif L >= long_th:
      run_long += 1; max_run_long = max(max_run_long, run_long); run_short = 0
    else:
      run_short = 0; run_long = 0
  return max_run_short, max_run_long

def abstract_density(sent, abstract_words):
  cnt = sum(len(re.findall(re.escape(w), sent)) for w in abstract_words)
  return cnt

connectors = count_occurrences(text, cfg["connector_phrases"])
empties = count_occurrences(text, cfg["empty_phrases"])
sents = split_sentences(text)
lens, avg, std = sentence_lengths(sents)
mx_run_short, mx_run_long = runs(lens, cfg["sentence_length"]["short_threshold"], cfg["sentence_length"]["long_threshold"])

abstract_scores = [(i, abstract_density(s, cfg["abstract_nouns"])) for i, s in enumerate(sents)]
abstract_scores.sort(key=lambda x: x[1], reverse=True)
abstract_top = [ (i, sents[i]) for i,score in abstract_scores[:5] if score>=2 ]

total_chars = len(text)
def ratio(count):
  return (count / max(1,total_chars)) * 1000

print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("📊 รายงานการตรวจสอบความเป็นธรรมชาติของงานเขียน (ออฟไลน์)")
print(f"ไฟล์: {os.path.basename(path)}  จำนวนอักขระ: {total_chars}")
print("")
print("ความหนาแน่นของคำเชื่อม (จำนวนครั้งที่พบต่อ 1,000 อักขระ)")
total_conn = sum(connectors.values())
print(f"  รวมทั้งสิ้น: {total_conn}  | สัดส่วน: {ratio(total_conn):.2f}")
for k,v in sorted(connectors.items(), key=lambda x: -x[1])[:10]:
  if v>0: print(f"  - {k}: {v}")

print("")
print("จำนวนคำพูดกลวง / สํานวนสำเร็จรูปที่พบ")
total_emp = sum(empties.values())
print(f"  รวมทั้งสิ้น: {total_emp}  | สัดส่วน: {ratio(total_emp):.2f}")
for k,v in sorted(empties.items(), key=lambda x: -x[1])[:10]:
  if v>0: print(f"  - {k}: {v}")

print("")
print("สถิติความยาวประโยค")
print(f"  จำนวนประโยค: {len(lens)}  | ค่าเฉลี่ย: {avg:.1f}  | ส่วนเบี่ยงเบนมาตรฐาน: {std:.1f}")
print(f"  จำนวนประโยคสั้นที่ต่อเนื่องกันสูงสุด: {mx_run_short} (เกณฑ์ควบคุม {cfg['sentence_length']['max_run_short']})")
print(f"  จำนวนประโยคยาวที่ต่อเนื่องกันสูงสุด: {mx_run_long} (เกณฑ์ควบคุม {cfg['sentence_length']['max_run_long']})")

print("")
print("สภาวะนามธรรมล้น (ตัวอย่างประโยคที่พบคำนามธรรม ≥2 คำ)")
if abstract_top:
  for idx, s in abstract_top:
    snippet = s[:80] + ("…" if len(s)>80 else "")
    print(f"  - ประโยคที่ {idx+1}: {snippet}")
else:
  print("  ไม่พบประโยคที่มีคำนามธรรมหนาแน่นเกินไป")

print("")
print("คำแนะนำสำหรับการปรับปรุง")
print("  - ควรใช้การบรรยายการกระทำที่เป็นรูปธรรม วัตถุสิ่งของ หรือกลิ่นอายทดแทนคำพูดที่กลวงและคำนามธรรม")
print("  - ตัดแบ่งประโยคที่ยาวต่อเนื่องเป็นพืด และควบรวมประโยคสั้นที่มากเกินไปเพื่อให้จังหวะจะโคนมีระดับสูงต่ำสลับกัน")
print("  - ตรวจสอบคำเชื่อมซ้ำซ้อนเพื่อตัดออก หรือปรับเปลี่ยนให้เกิดการเปลี่ยนผ่านเนื้อหาที่เป็นธรรมชาติมากขึ้น")
print("  - ก่อนเริ่มเขียนงาน ให้กำหนดรายละเอียดและองค์ประกอบการดำเนินชีวิตจริงล่วงหน้า 3 จุดเพื่อใช้เป็นหลักยึดเนื้อเรื่อง")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
PY
