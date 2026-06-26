#!/usr/bin/env bash
# ระบบจัดการความสัมพันธ์ของตัวละคร (Bash)

set -e

SCRIPT_DIR=$(dirname "$0")
source "$SCRIPT_DIR/common.sh"

PROJECT_ROOT=$(get_project_root)
STORY_DIR=$(get_current_story)

# ค้นหาและกำหนดพาธไฟล์ความสัมพันธ์ (relationships.json)
REL_FILE=""
if [ -n "$STORY_DIR" ] && [ -f "$STORY_DIR/spec/tracking/relationships.json" ]; then
  REL_FILE="$STORY_DIR/spec/tracking/relationships.json"
elif [ -f "$PROJECT_ROOT/spec/tracking/relationships.json" ]; then
  REL_FILE="$PROJECT_ROOT/spec/tracking/relationships.json"
else
  # พยายามเริ่มต้นสร้างไฟล์ใหม่จากเทมเพลตต้นแบบ (Templates)
  mkdir -p "$PROJECT_ROOT/spec/tracking"
  if [ -f "$PROJECT_ROOT/.specify/templates/tracking/relationships.json" ]; then
    cp "$PROJECT_ROOT/.specify/templates/tracking/relationships.json" "$PROJECT_ROOT/spec/tracking/relationships.json"
    REL_FILE="$PROJECT_ROOT/spec/tracking/relationships.json"
  elif [ -f "$SCRIPT_DIR/../../templates/tracking/relationships.json" ]; then
    cp "$SCRIPT_DIR/../../templates/tracking/relationships.json" "$PROJECT_ROOT/spec/tracking/relationships.json"
    REL_FILE="$PROJECT_ROOT/spec/tracking/relationships.json"
  else
    echo "❌ ไม่พบไฟล์ relationships.json และไม่สามารถสร้างจากเทมเพลตได้" >&2
    exit 1
  fi
fi

CMD=${1:-show}
shift || true

# ฟังก์ชันพิมพ์หัวข้อรายงาน
print_header() {
  echo "👥 ระบบจัดการความสัมพันธ์ของตัวละคร"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# 1. คำสั่งแสดงข้อมูลความสัมพันธ์ (show)
cmd_show() {
  print_header
  if ! jq empty "$REL_FILE" >/dev/null 2>&1; then
    echo "❌ ไฟล์ relationships.json มีรูปแบบ (Format) ไม่ถูกต้อง" >&2; exit 1
  fi

  echo "พาธไฟล์ปัจจุบัน：$REL_FILE"
  echo ""
  
  # ดึงข้อมูลตัวละครเอกหรือตัวละครแรกในฐานข้อมูล
  local main_char=$(jq -r '.characters | keys[0] // ""' "$REL_FILE")
  if [ -z "$main_char" ] || [ "$main_char" = "null" ]; then
    echo "ไม่พบข้อมูลบันทึกตัวละคร"
    exit 0
  fi
  echo "ตัวละครเอก：$main_char"
  
  # รองรับโครงสร้างข้อมูลทั้งแบบ nested relationships และแบบ direct category keys
  jq -r --arg name "$main_char" '
    .characters[$name] as $c | 
    ($c.relationships // $c) as $r |
    [
      {k:"romantic", v:($r.romantic // [])},
      {k:"allies", v:($r.allies // [])},
      {k:"mentors", v:($r.mentors // [])},
      {k:"enemies", v:($r.enemies // [])},
      {k:"family", v:($r.family // [])},
      {k:"neutral", v:($r.neutral // [])}
    ] | .[] | select((.v|length)>0) |
    "├─ " + (if .k=="romantic" then "💕 ความรัก/เสน่หา" elseif .k=="allies" then "🤝 พันธมิตร/盟友" elseif .k=="mentors" then "📚 อาจารย์/导师" elseif .k=="enemies" then "⚔️ ศัตรู/敌对" elseif .k=="family" then "👪 ครอบครัว" else "・ ความสัมพันธ์" end) + "：" + (.v | join("、"))
  ' "$REL_FILE"

  # แสดงข้อมูลการเปลี่ยนแปลงล่าสุด
  echo ""
  if jq -e '.history' "$REL_FILE" >/dev/null 2>&1; then
    local recent=$(jq -r '.history[-1] // empty' "$REL_FILE")
    if [ -n "$recent" ]; then
      echo "การเปลี่ยนแปลงล่าสุด："
      jq -r '.history[-1].changes[]? | "- " + (.characters|join(" ↔ ")) + "：" + (.relation // .type // "เกิดการเปลี่ยนแปลง")' "$REL_FILE"
    fi
  elif jq -e '.relationshipChanges' "$REL_FILE" >/dev/null 2>&1; then
    echo "การเปลี่ยนแปลงล่าสุด："
    jq -r '.relationshipChanges[-5:][]? | "- " + (.type // "เกิดการเปลี่ยนแปลง") + ": " + (.characters|join(" ↔ "))' "$REL_FILE" 2>/dev/null || true
  fi
}

# 2. คำสั่งอัปเดตข้อมูลความสัมพันธ์ (update)
cmd_update() {
  local a="$1"; local rel="$2"; local b="$3"; shift 3 || true
  local chapter=""; local note=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --chapter) chapter="$2"; shift 2;;
      --note) note="$2"; shift 2;;
      *) shift;;
    esac
  done
  if [ -z "$a" ] || [ -z "$rel" ] || [ -z "$b" ]; then
    echo "วิธีใช้: manage-relations.sh update <ตัวละครA> <allies|enemies|romantic|neutral|family|mentors> <ตัวละครB> [--chapter เลขบท] [--note คำอธิบาย]" >&2
    exit 1
  fi

  # ตรวจสอบและสร้างโหนดตัวละครหากยังไม่มีในระบบ
  for name in "$a" "$b"; do
    if ! jq --arg n "$name" '(.characters[$n] // null) != null' "$REL_FILE" | grep -q true; then
      tmp=$(mktemp)
      jq --arg n "$name" '.characters[$n] = (.characters[$n] // {name:$n, relationships:{allies:[],enemies:[],romantic:[],family:[],mentors:[],neutral:[]}})' "$REL_FILE" > "$tmp"
      mv "$tmp" "$REL_FILE"
    fi
  done

  # บันทึกความสัมพันธ์ลงในไฟล์
  tmp=$(mktemp)
  jq --arg a "$a" --arg b "$b" --arg rel "$rel" '
    .characters[$a].relationships[$rel] = ((.characters[$a].relationships[$rel] // []) + [$b] | unique) |
    .lastUpdated = now | todate
  ' "$REL_FILE" > "$tmp"
  mv "$tmp" "$REL_FILE"

  # บันทึกประวัติ (ให้ความสำคัญกับคีย์ history ก่อน หากไม่มีให้ใช้ relationshipChanges)
  local now=$(date -Iseconds)
  if jq -e '.history' "$REL_FILE" >/dev/null 2>&1; then
    tmp=$(mktemp)
    jq --arg ch "${chapter:-null}" --arg a "$a" --arg b "$b" --arg rel "$rel" --arg note "$note" --arg t "$now" '
      .history += [{
        chapter: ( ($ch|tonumber) // null ),
        date: $t,
        changes: [{ type: "update", characters: [$a,$b], relation: $rel, note: ($note // "") }]
      }]
    ' "$REL_FILE" > "$tmp" && mv "$tmp" "$REL_FILE"
  else
    tmp=$(mktemp)
    jq --arg a "$a" --arg b "$b" --arg rel "$rel" '.relationshipChanges += [{type:"update", characters:[$a,$b], relation:$rel}]' "$REL_FILE" > "$tmp" && mv "$tmp" "$REL_FILE"
  fi

  echo "✅ อัปเดตความสัมพันธ์เสร็จสิ้น：$a [$rel] $b"
}

# 3. คำสั่งเปิดดูประวัติการเปลี่ยนแปลงความสัมพันธ์ (history)
cmd_history() {
  print_header
  if jq -e '.history' "$REL_FILE" >/dev/null 2>&1; then
    jq -r '.history[] | "บทที่ " + ((.chapter // 0|tostring)) + "：" + (.changes | map((.characters|join(" ↔ "))+" → "+(.relation // .type)) | join("；"))' "$REL_FILE"
  elif jq -e '.relationshipChanges' "$REL_FILE" >/dev/null 2>&1; then
    jq -r '.relationshipChanges[] | (.date // "") + " " + (.type // "") + ": " + (.characters|join(" ↔ ")) + " → " + (.relation // "")' "$REL_FILE"
  else
    echo "ยังไม่มีข้อมูลบันทึกประวัติ"
  fi
}

# 4. คำสั่งตรวจสอบข้อมูลความสัมพันธ์ (check)
cmd_check() {
  print_header
  local issues=0
  
  # ตรวจสอบว่าชื่อตัวละครที่ถูกอ้างอิงในความสัมพันธ์ มีชื่ออยู่ในโหนด characters หลักแล้วหรือยัง
  missing=$(jq -r '
    .characters as $c |
    [
      .characters | to_entries[] | .value.relationships // empty |
      to_entries[] | .value[]
    ] | flatten | unique | map(select(has(.) | not))
  ' "$REL_FILE" 2>/dev/null || true)
  if [ -n "$missing" ]; then
    echo "⚠️  พบการอ้างอิงถึงตัวละครที่ยังไม่ได้เปิดแฟ้มประวัติหลัก (characters) แนะนำให้เพิ่มข้อมูล："
    echo "$missing"
    issues=1
  fi
  if [ "$issues" -eq 0 ]; then
    echo "✅ ตรวจสอบผ่านเรียบร้อย ข้อมูลความสัมพันธ์ถูกต้องครบถ้วน"
  fi
}

# ส่วนควบคุมหลักตามอาร์กิวเมนต์ที่รับเข้ามา (Main Switch Case)
case "$CMD" in
  show) cmd_show ;;
  update) cmd_update "$@" ;;
  history) cmd_history ;;
  check) cmd_check ;;
  *) echo "วิธีใช้: $0 [show|update|history|check]" >&2; exit 1;;
esac
