#!/usr/bin/env bash
# จัดการและตรวจสอบความถูกต้องของเส้นเวลา (Timeline) ในเนื้อเรื่อง

set -e

# โหลดฟังก์ชันส่วนกลาง
SCRIPT_DIR=$(dirname "$0")
source "$SCRIPT_DIR/common.sh"

# ตรวจสอบว่าเป็นโหมด Checklist หรือไม่
CHECKLIST_MODE=false
COMMAND="${1:-show}"
if [ "$COMMAND" = "--checklist" ]; then
    CHECKLIST_MODE=true
    COMMAND="check"
fi

# รับไดเรกทอรีของเนื้อเรื่องปัจจุบัน
STORY_DIR=$(get_current_story)

if [ -z "$STORY_DIR" ]; then
    echo "ข้อผิดพลาด: ไม่พบโปรเจกต์เนื้อเรื่อง" >&2
    exit 1
fi

# พาธไฟล์ข้อมูล
TIMELINE="$STORY_DIR/spec/tracking/timeline.json"
PROGRESS="$STORY_DIR/progress.json"

# ตัวแปรอาร์กิวเมนต์ที่สอง (ผ่านการประมวลผลโหมด Checklist ด้านบนแล้ว)
PARAM2="${2:-}"

# เริ่มต้นสร้างไฟล์เส้นเวลาหากยังไม่มี
init_timeline() {
    if [ ! -f "$TIMELINE" ]; then
        echo "⚠️  ไม่พบไฟล์เส้นเวลา กำลังสร้าง..." >&2
        mkdir -p "$STORY_DIR/spec/tracking"

        if [ -f "$SCRIPT_DIR/../../templates/tracking/timeline.json" ]; then
            cp "$SCRIPT_DIR/../../templates/tracking/timeline.json" "$TIMELINE"
            echo "✅ สร้างไฟล์เส้นเวลาเรียบร้อยแล้ว"
        else
            echo "ข้อผิดพลาด: ไม่พบไฟล์เทมเพลต" >&2
            exit 1
        fi
    fi
}

# แสดงข้อมูลเส้นเวลา
show_timeline() {
    echo "📅 เส้นเวลาของเนื้อเรื่อง (Story Timeline)"
    echo "━━━━━━━━━━━━━━━━━━━━"

    if [ -f "$TIMELINE" ]; then
        local current_time=$(jq -r '.storyTime.current // "ยังไม่ได้กำหนด"' "$TIMELINE")
        local global_era=$(jq -r '.storyTime.era // "ไม่ระบุยุคสมัย"' "$TIMELINE")
        echo "⏳ เวลาปัจจุบันในเนื้อเรื่อง: $current_time ($global_era)"
        echo ""

        local event_count=$(jq '.events | length' "$TIMELINE")
        if [ "$event_count" -eq 0 ]; then
            echo "ยังไม่มีการบันทึกเหตุการณ์ลงในเส้นเวลา"
            return
        fi

        echo "📌 รายการเหตุการณ์สำคัญ (${event_count} รายการ):"
        # เรียงลำดับเหตุการณ์ตามตอนและแสดงผล
        jq -r '.events | sort_by(.chapter) | .[] | 
            "  [ตอนที่ " + (.chapter | tostring) + "] " + .timeNode + ": " + .description' "$TIMELINE"
    else
        echo "ไม่พบข้อมูลเส้นเวลา"
    fi
}

# เพิ่มเหตุการณ์ใหม่เข้าไปในเส้นเวลา
add_event() {
    local chapter="$1"
    local time_node="$2"
    local desc="$3"

    if [ -z "$chapter" ] || [ -z "$time_node" ] || [ -z "$desc" ]; then
        echo "วิธีใช้: $0 add [เลขตอน] [จุดเวลา] [คำอธิบายเหตุการณ์]" >&2
        exit 1
    fi

    local temp_file=$(mktemp)
    
    # เพิ่มออบเจกต์เหตุการณ์ใหม่เข้าไปในอาร์เรย์ JSON
    jq --arg ch "$chapter" --arg tn "$time_node" --arg ds "$desc" \
       '.events += [{"chapter": ($ch | tonumber), "timeNode": $tn, "description": $ds}]' \
       "$TIMELINE" > "$temp_file"
    
    mv "$temp_file" "$TIMELINE"
    echo "✅ เพิ่มเหตุการณ์ในตอนที่ $chapter ลงเส้นเวลาสำเร็จ"
}

# สร้างเอาต์พุตในรูปแบบ Checklist (รายการตรวจสอบ)
output_checklist() {
    # ตรวจสอบความสมบูรณ์ของไฟล์เบื้องต้น
    local file_exists=false
    [ -f "$TIMELINE" ] && file_exists=true

    local current_time=""
    local event_count=0
    local has_issues=0
    local parallel_count=0

    if [ "$file_exists" = true ]; then
        current_time=$(jq -r '.storyTime.current // ""' "$TIMELINE")
        event_count=$(jq '.events | length' "$TIMELINE")
        parallel_count=$(jq '[.events[] | select(.isParallel == true)] | length' "$TIMELINE" 2>/dev/null || echo 0)

        # ตรวจสอบว่ามีเหตุการณ์ที่สลับลำดับเลขตอน (ลำดับเวลาไม่ถูกต้อง) หรือไม่
        has_issues=$(jq '
            .events | 
            sort_by(.chapter) | 
            . as $sorted |
            reduce range(1; length) as $i (0;
                if $sorted[$i].chapter < $sorted[$i-1].chapter then . + 1 else . end
            )' "$TIMELINE" 2>/dev/null || echo 0)
    fi

    # แสดงผลข้อมูลในรูปแบบของ Markdown Checklist
    cat <<EOF
# รายการตรวจสอบโครงสร้างและลำดับเวลา (Checklist)

**เวลาที่ตรวจสอบ**: $(date '+%Y-%m-%d %H:%M:%S')
**เป้าหมายการตรวจสอบ**: timeline.json
**ขอบเขตการตรวจสอบ**: ตรวจสอบความถูกต้องต่อเนื่องของเส้นเวลาและเหตุการณ์คู่ขนาน

---

## ความสมบูรณ์ของไฟล์

- [$([ "$file_exists" = true ] && echo "x" || echo " ")] CHK001 มีไฟล์ timeline.json อยู่ในระบบ
- [$([ "$file_exists" = true ] && jq empty "$TIMELINE" 2>/dev/null && echo "x" || echo " ")] CHK002 รูปแบบโครงสร้างไฟล์ JSON ถูกต้อง

## สถานะเส้นเวลาปัจจุบัน

- [$([ -n "$current_time" ] && echo "x" || echo " ")] CHK003 กำหนดเวลาปัจจุบันของเนื้อเรื่องแล้ว (ปัจจุบัน: ${current_time:-ยังไม่ได้กำหนด})
- [$([ "$event_count" -gt 0 ] && echo "x" || echo " ")] CHK004 มีการบันทึกข้อมูลเหตุการณ์ลงบนเส้นเวลา (บันทึกแล้ว $event_count รายการ)
- [$([ "$has_issues" -eq 0 ] && [ "$event_count" -gt 0 ] && echo "x" || echo " ")] CHK005 เหตุการณ์บนเส้นเวลาเรียงลำดับตามเลขตอนอย่างถูกต้อง$([ "$has_issues" -gt 0 ] && echo " (⚠️ พบจุดที่สลับลำดับลำดับ $has_issues รายการ)" || echo "")

## เหตุการณ์คู่ขนาน (Parallel Events)

EOF

    if [ "$parallel_count" -gt 0 ]; then
        echo "- [x] CHK006 พบบันทึกจุดเวลาของเหตุการณ์คู่ขนานเรียบร้อยแล้ว ($parallel_count รายการ)"
    else
        echo "- [ ] CHK006 บันทึกจุดเวลาของเหตุการณ์คู่ขนาน (ยังไม่มีการบันทึก)"
    fi

    cat <<EOF

---

## สิ่งที่ต้องทำต่อไป (Actions)

EOF

    local has_actions=false

    if [ "$event_count" -eq 0 ]; then
        echo "- [ ] เริ่มต้นบันทึกเหตุการณ์สำคัญลงในระบบเส้นเวลา"
        has_actions=true
    fi

    if [ -z "$current_time" ]; then
        echo "- [ ] ตั้งค่าและระบุเวลาปัจจุบันของเนื้อเรื่องให้ชัดเจน"
        has_actions=true
    fi

    if [ "$has_issues" -gt 0 ]; then
        echo "- [ ] แก้ไขลำดับและตรวจสอบความสลับซับซ้อนของเหตุการณ์ที่มีปัญหาเรียงลำดับผิดจำนวน $has_issues รายการ"
        has_actions=true
    fi

    if [ "$has_actions" = false ]; then
        echo "*บันทึกข้อมูลเส้นเวลาเสร็จสมบูรณ์และถูกต้องดี ไม่จำเป็นต้องดำเนินการใดๆ เป็นพิเศษ*"
    fi

    cat <<EOF

---

**เครื่องมือตรวจสอบ**: check-timeline.sh
**เวอร์ชัน**: 1.1 (รองรับการแสดงผลแบบ checklist)
EOF
}

# 主函数 - ฟังก์ชันหลัก
main() {
    if [ "$CHECKLIST_MODE" = true ]; then
        output_checklist
        exit 0
    fi

    init_timeline

    case "$COMMAND" in
        show)
            show_timeline
            ;;
        add)
            add_event "$PARAM2" "$3" "$4"
            ;;
        check)
            output_checklist
            ;;
        *)
            echo "คำสั่งที่รองรับ: $0 {show|add|check}" >&2
            exit 1
            ;;
    esac
}

# เริ่มเรียกใช้งานฟังก์ชันหลัก
main
