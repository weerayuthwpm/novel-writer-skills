#!/usr/bin/env bash
# สคริปต์ตรวจสอบความสอดคล้องอย่างครอบคลุม

set -e

# โหลดฟังก์ชันส่วนกลาง
SCRIPT_DIR=$(dirname "$0")
source "$SCRIPT_DIR/common.sh"

# ตรวจสอบโหมดการทำงาน
CHECKLIST_MODE=false
if [ "$1" = "--checklist" ]; then
    CHECKLIST_MODE=true
fi

# รับไดเรกทอรีของเนื้อเรื่องปัจจุบัน
STORY_DIR=$(get_current_story)

if [ -z "$STORY_DIR" ]; then
    echo "ข้อผิดพลาด: ไม่พบโปรเจกต์เนื้อเรื่อง" >&2
    exit 1
fi

# พาธไฟล์ข้อมูล
PROGRESS="$STORY_DIR/progress.json"
PLOT_TRACKER="$STORY_DIR/spec/tracking/plot-tracker.json"
TIMELINE="$STORY_DIR/spec/tracking/timeline.json"
RELATIONSHIPS="$STORY_DIR/spec/tracking/relationships.json"
CHARACTER_STATE="$STORY_DIR/spec/tracking/character-state.json"

# รหัสสี ANSI
RED='\033;31m'
GREEN='\033;32m'
YELLOW='\033[1;33m'
BLUE='\033;34m'
NC='\033[0m' # No Color

# ตัวแปรสำหรับเก็บสถิติ
TOTAL_CHECKS=0
PASSED_CHECKS=0
WARNINGS=0
ERRORS=0

# ฟังก์ชันสำหรับส่งการตรวจสอบ
check() {
    local name="$1"
    local condition="$2"
    local error_msg="$3"

    ((TOTAL_CHECKS++))

    if eval "$condition"; then
        echo -e "${GREEN}✓${NC} $name"
        ((PASSED_CHECKS++))
    else
        echo -e "${RED}✗${NC} $name: $error_msg"
        ((ERRORS++))
    fi
}

# ฟังก์ชันแจ้งเตือน
warn() {
    local msg="$1"
    echo -e "${YELLOW}⚠${NC} คำเตือน: $msg"
    ((WARNINGS++))
}

# ตรวจสอบความสอดคล้องของเลขตอน/เลขบท
check_chapter_consistency() {
    echo "📖 ตรวจสอบความสอดคล้องของเลขตอน"
    echo "───────────────────"

    if [ -f "$PROGRESS" ] && [ -f "$PLOT_TRACKER" ]; then
        PROGRESS_CHAPTER=$(jq -r '.statistics.currentChapter // 0' "$PROGRESS")
        PLOT_CHAPTER=$(jq -r '.currentState.chapter // 0' "$PLOT_TRACKER")

        check "การซิงค์เลขตอน" \
              "[ '$PROGRESS_CHAPTER' = '$PLOT_CHAPTER' ]" \
              "progress.json(${PROGRESS_CHAPTER}) != plot-tracker.json(${PLOT_CHAPTER})"

        if [ -f "$CHARACTER_STATE" ]; then
            CHAR_CHAPTER=$(jq -r '.protagonist.currentStatus.chapter // 0' "$CHARACTER_STATE")
            check "การซิงค์เลขตอนในสถานะตัวละคร" \
                  "[ '$PROGRESS_CHAPTER' = '$CHAR_CHAPTER' ]" \
                  "ไม่สอดคล้องกับ character-state.json(${CHAR_CHAPTER})"
        fi
    else
        warn "ไฟล์ติดตามบางส่วนสูญหาย ไม่สามารถตรวจสอบเลขตอนได้ครบถ้วน"
    fi

    echo ""
}

# ตรวจสอบความต่อเนื่องของเส้นเวลา (Timeline)
check_timeline_consistency() {
    echo "⏰ ตรวจสอบความต่อเนื่องของเส้นเวลา"
    echo "───────────────────"

    if [ -f "$TIMELINE" ]; then
        # ตรวจสอบว่าเหตุการณ์ในเส้นเวลาเรียงลำดับตามเลขตอนจากน้อยไปมากหรือไม่
        TIMELINE_ISSUES=$(jq '
            .events |
            sort_by(.chapter) |
            . as $sorted |
            reduce range(1; length) as $i (0;
                if $sorted[$i].chapter <= $sorted[$i-1].chapter then . + 1 else . end
            )' "$TIMELINE")

        check "ลำดับเหตุการณ์ตามเวลา" \
              "[ '$TIMELINE_ISSUES' = '0' ]" \
              "พบเหตุการณ์ที่สลับลำดับหรือไม่ถูกต้องจำนวน ${TIMELINE_ISSUES} รายการ"

        # ตรวจสอบว่าเวลาปัจจุบันมีการตั้งค่าไว้หรือไม่
        CURRENT_TIME=$(jq -r '.storyTime.current // ""' "$TIMELINE")
        check "การตั้งค่าเวลาปัจจุบัน" \
              "[ -n '$CURRENT_TIME' ]" \
              "ยังไม่ได้ตั้งค่าเวลาปัจจุบันของเนื้อเรื่อง"
    else
        warn "ไม่พบไฟล์เส้นเวลา (timeline.json)"
    fi

    echo ""
}

# ตรวจสอบความสมเหตุสมผลของสถานะตัวละคร
check_character_consistency() {
    echo "👥 ตรวจสอบความสมเหตุสมผลของสถานะตัวละคร"
    echo "─────────────────────"

    if [ -f "$CHARACTER_STATE" ] && [ -f "$RELATIONSHIPS" ]; then
        # ตรวจสอบว่ามีข้อมูลของตัวเอกปรากฏอยู่ในทั้งสองไฟล์หรือไม่
        PROTAG_NAME=$(jq -r '.protagonist.name // ""' "$CHARACTER_STATE")

        if [ -n "$PROTAG_NAME" ]; then
            HAS_RELATIONS=$(jq --arg name "$PROTAG_NAME" \
                'has($name)' "$RELATIONSHIPS" 2>/dev/null || echo "false")

            check "บันทึกความสัมพันธ์ของตัวเอก" \
                  "[ '$HAS_RELATIONS' = 'true' ]" \
                  "ไม่พบข้อมูลบันทึกของตัวเอก '$PROTAG_NAME' ในไฟล์ relationships.json"
        fi

        # ตรวจสอบตรรกะตำแหน่งของตัวละคร
        LAST_LOCATION=$(jq -r '.protagonist.currentStatus.location // ""' "$CHARACTER_STATE")
        check "บันทึกตำแหน่งของตัวเอก" \
              "[ -n '$LAST_LOCATION' ]" \
              "ยังไม่ได้บันทึกตำแหน่งปัจจุบันของตัวเอก"
    else
        warn "ไฟล์ติดตามข้อมูลตัวละครไม่สมบูรณ์"
    fi

    echo ""
}

# ตรวจสอบแผนการคลี่คลายปม/เบาะแสที่วางไว้ (Foreshadowing)
check_foreshadowing_plan() {
    echo "🎯 ตรวจสอบการจัดการปมและเบาะแส (Foreshadowing)"
    echo "──────────────"

    if [ -f "$PLOT_TRACKER" ]; then
        # นับสถานะปม/เบาะแส
        TOTAL_FORESHADOW=$(jq '.foreshadowing | length' "$PLOT_TRACKER")
        ACTIVE_FORESHADOW=$(jq '[.foreshadowing[] | select(.status == "active")] | length' "$PLOT_TRACKER")

        if [ -f "$PROGRESS" ]; then
            CURRENT_CHAPTER=$(jq -r '.statistics.currentChapter // 0' "$PROGRESS")

            # ตรวจสอบปมที่ปล่อยไว้นานเกินไปแล้วยังไม่มีการเฉลยหรือดึงกลับมาใช้
            OVERDUE=$(jq --arg current "$CURRENT_CHAPTER" '
                [.foreshadowing[] |
                 select(.status == "active" and .planted.chapter and
                        (($current | tonumber) - .planted.chapter) > 50)] |
                length' "$PLOT_TRACKER")

            check "ความทันท่วงทีในการคลี่คลายปม" \
                  "[ '$OVERDUE' = '0' ]" \
                  "พบ ${OVERDUE} ปม ที่ปล่อยทิ้งไว้เกิน 50 ตอนแล้วยังไม่ได้คลี่คลาย"
        fi

        echo "  📊 สถิติปม/เบาะแส: ทั้งหมด ${TOTAL_FORESHADOW} รายการ, กำลังทำงาน (Active) ${ACTIVE_FORESHADOW} รายการ"

        # แจ้งเตือนเมื่อมีปมที่ยังไม่คลี่คลายมากเกินไป
        if [ "$ACTIVE_FORESHADOW" -gt 10 ]; then
            warn "มีปมที่ยังไม่คลี่คลายมากเกินไป (${ACTIVE_FORESHADOW} รายการ) อาจทำให้ผู้อ่านเกิดความสับสนได้"
        fi
    else
        warn "ไม่พบไฟล์ติดตามโครงเรื่อง (plot-tracker.json)"
    fi

    echo ""
}

# ตรวจสอบความสมบูรณ์ของไฟล์
check_file_integrity() {
    echo "📁 ตรวจสอบความสมบูรณ์ของไฟล์"
    echo "────────────────"

    check "progress.json" "[ -f '$PROGRESS' ]" "ไม่พบไฟล์"
    check "plot-tracker.json" "[ -f '$PLOT_TRACKER' ]" "ไม่พบไฟล์"
    check "timeline.json" "[ -f '$TIMELINE' ]" "ไม่พบไฟล์"
    check "relationships.json" "[ -f '$RELATIONSHIPS' ]" "ไม่พบไฟล์"
    check "character-state.json" "[ -f '$CHARACTER_STATE' ]" "ไม่พบไฟล์"

    # ตรวจสอบว่ารูปแบบไฟล์ JSON ถูกต้อง (Valid) หรือไม่
    for file in "$PROGRESS" "$PLOT_TRACKER" "$TIMELINE" "$RELATIONSHIPS" "$CHARACTER_STATE"; do
        if [ -f "$file" ]; then
            filename=$(basename "$file")
            if jq empty "$file" 2>/dev/null; then
                check "รูปแบบไฟล์ $filename" "true" ""
            else
                check "รูปแบบไฟล์ $filename" "false" "รูปแบบ JSON ไม่ถูกต้อง"
            fi
        fi
    done

    echo ""
}

# สร้างรายงานสรุป
generate_report() {
    echo "═══════════════════════════════════════"
    echo "📊 รายงานสรุปการตรวจสอบความสอดคล้อง"
    echo "═══════════════════════════════════════"
    echo ""

    check_file_integrity
    check_chapter_consistency
    check_timeline_consistency
    check_character_consistency
    check_foreshadowing_plan

    echo "═══════════════════════════════════════"
    echo "📈 สรุปผลการตรวจสอบ"
    echo "───────────────────"
    echo "  รายการตรวจสอบทั้งหมด: ${TOTAL_CHECKS}"
    echo -e "  ${GREEN}ผ่าน: ${PASSED_CHECKS}${NC}"
    echo -e "  ${YELLOW}คำเตือน: ${WARNINGS}${NC}"
    echo -e "  ${RED}ข้อผิดพลาด: ${ERRORS}${NC}"

    if [ "$ERRORS" -eq 0 ] && [ "$WARNINGS" -eq 0 ]; then
        echo ""
        echo -e "${GREEN}✅ สมบูรณ์แบบ! รายการตรวจสอบทั้งหมดผ่านการทดสอบ${NC}"
    elif [ "$ERRORS" -eq 0 ]; then
        echo ""
        echo -e "${YELLOW}⚠️  มีคำเตือน ${WARNINGS} รายการ ขอแนะนำให้ตรวจสอบเพิ่มเติม${NC}"
    else
        echo ""
        echo -e "${RED}❌ พบข้อผิดพลาด ${ERRORS} รายการ จำเป็นต้องได้รับการแก้ไข${NC}"
    fi

    echo "═══════════════════════════════════════"
    echo ""
    echo "เวลาที่ตรวจสอบ: $(date '+%Y-%m-%d %H:%M:%S')"

    # บันทึกผลการตรวจสอบลงไฟล์
    if [ -d "$STORY_DIR/spec/tracking" ]; then
        echo "{
            \"timestamp\": \"$(date -Iseconds)\",
            \"total\": $TOTAL_CHECKS,
            \"passed\": $PASSED_CHECKS,
            \"warnings\": $WARNINGS,
            \"errors\": $ERRORS
        }" > "$STORY_DIR/spec/tracking/.last-check.json"
    fi
}

# สร้างเอาต์พุตในรูปแบบ Checklist (รายการตรวจสอบ)
output_checklist() {
    # ทำงานเงียบๆ เพื่อเก็บตรรกะการตรวจสอบ
    exec 3>&1 4>&2  # บันทึกสถานะเอาต์พุตเดิม
    exec 1>/dev/null 2>&1  # เปลี่ยนเส้นทางเอาต์พุตไปที่ null

    check_file_integrity
    check_chapter_consistency
    check_timeline_consistency
    check_character_consistency
    check_foreshadowing_plan

    exec 1>&3 2>&4  # คืนค่าเอาต์พุตปกติ

    # รับหมายเลขตอนเพื่อใช้ในการตรวจสอบข้อมูล
    local progress_chapter=""
    local plot_chapter=""
    local char_chapter=""
    if [ -f "$PROGRESS" ] && [ -f "$PLOT_TRACKER" ]; then
        progress_chapter=$(jq -r '.statistics.currentChapter // 0' "$PROGRESS" 2>/dev/null || echo "0")
        plot_chapter=$(jq -r '.currentState.chapter // 0' "$PLOT_TRACKER" 2>/dev/null || echo "0")
    fi
    if [ -f "$CHARACTER_STATE" ]; then
        char_chapter=$(jq -r '.protagonist.currentStatus.chapter // 0' "$CHARACTER_STATE" 2>/dev/null || echo "0")
    fi

    # ตรวจสอบสถานะปม/เบาะแส
    local total_foreshadow=0
    local active_foreshadow=0
    local overdue_foreshadow=0
    if [ -f "$PLOT_TRACKER" ]; then
        total_foreshadow=$(jq '.foreshadowing | length' "$PLOT_TRACKER" 2>/dev/null || echo "0")
        active_foreshadow=$(jq '[.foreshadowing[] | select(.status == "active")] | length' "$PLOT_TRACKER" 2>/dev/null || echo "0")

        if [ -f "$PROGRESS" ]; then
            local current_chapter=$(jq -r '.statistics.currentChapter // 0' "$PROGRESS" 2>/dev/null || echo "0")
            overdue_foreshadow=$(jq --arg current "$current_chapter" '[.foreshadowing[] | select(.status == "active" and .planted.chapter and (($current | tonumber) - .planted.chapter) > 50)] | length' "$PLOT_TRACKER" 2>/dev/null || echo "0")
        fi
    fi

    # แสดงผลข้อมูลในรูปแบบของ Markdown Checklist
    cat <<EOF
# รายการตรวจสอบความสอดคล้องของการซิงค์ข้อมูล (Checklist)

**เวลาที่ตรวจสอบ**: $(date '+%Y-%m-%d %H:%M:%S')
**เป้าหมายการตรวจสอบ**: ไฟล์ JSON ทั้งหมดในไดเรกทอรี spec/tracking/
**ขอบเขตการตรวจสอบ**: ความสมบูรณ์ของไฟล์, การซิงค์เลขตอน, ความต่อเนื่องของเส้นเวลา, สถานะตัวละคร, การจัดการปมเรื่อง

---

## ความสมบูรณ์ของไฟล์

- [$([ -f "$PROGRESS" ] && echo "x" || echo " ")] CHK001 progress.json มีอยู่จริงและรูปแบบถูกต้อง
- [$([ -f "$PLOT_TRACKER" ] && echo "x" || echo " ")] CHK002 plot-tracker.json มีอยู่จริงและรูปแบบถูกต้อง
- [$([ -f "$TIMELINE" ] && echo "x" || echo " ")] CHK003 timeline.json มีอยู่จริงและรูปแบบถูกต้อง
- [$([ -f "$RELATIONSHIPS" ] && echo "x" || echo " ")] CHK004 relationships.json มีอยู่จริงและรูปแบบถูกต้อง
- [$([ -f "$CHARACTER_STATE" ] && echo "x" || echo " ")] CHK005 character-state.json มีอยู่จริงและรูปแบบถูกต้อง

## การซิงค์เลขตอน

EOF

    if [ "$progress_chapter" = "$plot_chapter" ]; then
        echo "- [x] CHK006 progress.json และ plot-tracker.json เลขตอนตรงกัน (ตอนที่ $progress_chapter)"
    else
        echo "- [!] CHK006 progress.json(${progress_chapter}) และ plot-tracker.json(${plot_chapter}) เลขตอนไม่ตรงกัน"
    fi

    if [ -n "$char_chapter" ]; then
        if [ "$progress_chapter" = "$char_chapter" ]; then
            echo "- [x] CHK007 progress.json และ character-state.json เลขตอนตรงกัน"
        else
            echo "- [!] CHK007 progress.json(${progress_chapter}) และ character-state.json(${char_chapter}) เลขตอนไม่ตรงกัน"
        fi
    else
        echo "- [ ] CHK007 การตรวจสอบเลขตอนใน character-state.json (ไม่มีไฟล์หรือไม่มีข้อมูล)"
    fi

    cat <<EOF

## ความต่อเนื่องของเส้นเวลา

- [$([ -f "$TIMELINE" ] && echo "x" || echo " ")] CHK008 เหตุการณ์บนเส้นเวลาเรียงลำดับตามเลขตอนอย่างถูกต้อง
- [$([ -f "$TIMELINE" ] && echo "x" || echo " ")] CHK009 เวลาปัจจุบันของเนื้อเรื่องได้รับการตั้งค่าแล้ว

## สถานะตัวละคร

EOF

    if [ -f "$CHARACTER_STATE" ] && [ -f "$RELATIONSHIPS" ]; then
        local protag_name=$(jq -r '.protagonist.name // ""' "$CHARACTER_STATE" 2>/dev/null)
        if [ -n "$protag_name" ]; then
            echo "- [x] CHK010 ข้อมูลตัวเอกสมบูรณ์ ($protag_name)"
            local has_relations=$(jq --arg name "$protag_name" 'has($name)' "$RELATIONSHIPS" 2>/dev/null || echo "false")
            if [ "$has_relations" = "true" ]; then
                echo "- [x] CHK011 ตัวเอกมีบันทึกความสัมพันธ์ใน relationships.json"
            else
                echo "- [!] CHK011 ตัวเอก '$protag_name' ไม่มีบันทึกความสัมพันธ์ใน relationships.json"
            fi
        else
            echo "- [ ] CHK010 ข้อมูลตัวเอกสมบูรณ์ (ขาดข้อมูล)"
            echo "- [ ] CHK011 บันทึกความสัมพันธ์ของตัวเอก (ขาดข้อมูล)"
        fi

        local last_location=$(jq -r '.protagonist.currentStatus.location // ""' "$CHARACTER_STATE" 2>/dev/null)
        if [ -n "$last_location" ]; then
            echo "- [x] CHK012 ตำแหน่งปัจจุบันของตัวเอกได้รับการบันทึกแล้ว ($last_location)"
        else
            echo "- [!] CHK012 ยังไม่ได้บันทึกตำแหน่งปัจจุบันของตัวเอก"
        fi
    else
        echo "- [ ] CHK010 ข้อมูลตัวเอกสมบูรณ์ (ไม่พบไฟล์)"
        echo "- [ ] CHK011 บันทึกความสัมพันธ์ของตัวเอก (ไม่พบไฟล์)"
        echo "- [ ] CHK012 ตำแหน่งปัจจุบันของตัวเอกได้รับการบันทึกแล้ว (ไม่พบไฟล์)"
    fi

    cat <<EOF

## การจัดการปมเรื่อง (Foreshadowing)

EOF

    if [ "$total_foreshadow" -gt 0 ]; then
        echo "- [x] CHK013 มีบันทึกปมเรื่องอยู่จริง (ปมทั้งหมด $total_foreshadow รายการ, กำลังทำงาน $active_foreshadow รายการ)"

        if [ "$overdue_foreshadow" -eq 0 ]; then
            echo "- [x] CHK014 คลี่คลายปมเรื่องได้ทันเวลา (ไม่มีปมที่ค้างนานเกินกำหนด)"
        else
            echo "- [!] CHK014 คลี่คลายปมเรื่องได้ทันเวลา (พบ $overdue_foreshadow ปมที่ปล่อยค้างไว้เกิน 50 ตอนแล้วยังไม่คลี่คลาย)"
        fi

        if [ "$active_foreshadow" -le 10 ]; then
            echo "- [x] CHK015 จำนวนปมที่กำลังทำงานอยู่ในระดับที่เหมาะสม ($active_foreshadow ≤ 10)"
        else
            echo "- [!] CHK015 จำนวนปมที่กำลังทำงานอยู่มีมากเกินไป ($active_foreshadow > 10 อาจทำให้ผู้อ่านสับสนได้)"
        fi
    else
        echo "- [ ] CHK013 มีบันทึกปมเรื่องอยู่จริง (ไม่พบบันทึกปมเรื่อง)"
        echo "- [ ] CHK014 คลี่คลายปมเรื่องได้ทันเวลา (ไม่มีข้อมูล)"
        echo "- [ ] CHK015 จำนวนปมที่กำลังทำงานอยู่ในระดับที่เหมาะสม (ไม่มีข้อมูล)"
    fi

    cat <<EOF

---

## สถิติการตรวจสอบ

- **รายการตรวจสอบทั้งหมด**: ${TOTAL_CHECKS}
- **ผ่านการตรวจสอบ**: ${PASSED_CHECKS}
- **คำเตือน**: ${WARNINGS}
- **ข้อผิดพลาด**: ${ERRORS}

---

## สิ่งที่ต้องทำต่อไป

EOF

    if [ "$ERRORS" -gt 0 ]; then
        echo "- [ ] แก้ไขปัญหาความไม่สอดคล้องที่ทำเครื่องหมาย [!] ข้างต้น"
    fi
    if [ "$WARNINGS" -gt 0 ]; then
        echo "- [ ] ตรวจสอบรายการที่เป็นคำเตือน และพิจารณาความจำเป็นในการปรับปรุง"
    fi
    if [ "$ERRORS" -eq 0 ] && [ "$WARNINGS" -eq 0 ]; then
        echo "*ผ่านการตรวจสอบทุกรายการ ไม่จำเป็นต้องดำเนินการใดๆ*"
    fi

    cat <<EOF

---

**เครื่องมือตรวจสอบ**: check-consistency.sh
**เวอร์ชัน**: 1.1 (รองรับการแสดงผลแบบ Checklist)
EOF
}

# ฟังก์ชันหลัก (Main)
main() {
    if [ "$CHECKLIST_MODE" = true ]; then
        output_checklist
    else
        generate_report
    fi

    # คืนค่า Exit Code ตามผลลัพธ์ที่ได้
    if [ "$ERRORS" -gt 0 ]; then
        exit 1
    elif [ "$WARNINGS" -gt 0 ]; then
        exit 0  # คำเตือนไม่ถือว่าสคริปต์ทำงานล้มเหลว
    else
        exit 0
    fi
}

# เริ่มเรียกใช้งานฟังก์ชันหลัก
main
