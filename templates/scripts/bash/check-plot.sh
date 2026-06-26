#!/usr/bin/env bash
# ตรวจสอบความสอดคล้องและความต่อเนื่องของการดำเนินเนื้อเรื่อง

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
PLOT_TRACKER="$STORY_DIR/spec/tracking/plot-tracker.json"
OUTLINE="$STORY_DIR/outline.md"
PROGRESS="$STORY_DIR/progress.json"

# ตรวจสอบไฟล์ที่จำเป็น
check_required_files() {
    local missing=false

    if [ ! -f "$PLOT_TRACKER" ]; then
        echo "⚠️  ไม่พบไฟล์ติดตามเนื้อเรื่อง กำลังสร้าง..." >&2
        mkdir -p "$STORY_DIR/spec/tracking"
        # คัดลอกเทมเพลต
        if [ -f "$SCRIPT_DIR/../../templates/tracking/plot-tracker.json" ]; then
            cp "$SCRIPT_DIR/../../templates/tracking/plot-tracker.json" "$PLOT_TRACKER"
        else
            echo "ข้อผิดพลาด: ไม่พบไฟล์เทมเพลต" >&2
            exit 1
        fi
    fi

    if [ ! -f "$OUTLINE" ]; then
        echo "ข้อผิดพลาด: ไม่พบโครงเรื่องรายตอน (outline.md)" >&2
        echo "กรุณาใช้คำสั่ง /outline เพื่อสร้างโครงเรื่องก่อน" >&2
        exit 1
    fi
}

# ดึงข้อมูลความคืบหน้าปัจจุบัน
get_current_progress() {
    if [ -f "$PROGRESS" ]; then
        CURRENT_CHAPTER=$(jq -r '.statistics.currentChapter // 1' "$PROGRESS")
        CURRENT_VOLUME=$(jq -r '.statistics.currentVolume // 1' "$PROGRESS")
    else
        CURRENT_CHAPTER=$(jq -r '.currentState.chapter // 1' "$PLOT_TRACKER")
        CURRENT_VOLUME=$(jq -r '.currentState.volume // 1' "$PLOT_TRACKER")
    fi
}

# วิเคราะห์การจัดวางและการดำเนินเนื้อเรื่อง
analyze_plot_alignment() {
    echo "📊 รายงานการตรวจสอบการดำเนินเนื้อเรื่อง"
    echo "━━━━━━━━━━━━━━━━━━━━"

    # ความคืบหน้าปัจจุบัน
    echo "📍 ความคืบหน้าปัจจุบัน: ตอนที่ ${CURRENT_CHAPTER} (เล่มที่ ${CURRENT_VOLUME})"

    # อ่านข้อมูลติดตามเนื้อเรื่อง
    if [ -f "$PLOT_TRACKER" ]; then
        MAIN_PLOT=$(jq -r '.plotlines.main.currentNode // "ยังไม่ได้กำหนด"' "$PLOT_TRACKER")
        PLOT_STATUS=$(jq -r '.plotlines.main.status // "unknown"' "$PLOT_TRACKER")
        echo "📖 ความคืบหน้าเส้นเรื่องหลัก: $MAIN_PLOT [$PLOT_STATUS]"

        # โหนดเหตุการณ์ที่เสร็จสิ้นแล้ว
        COMPLETED_COUNT=$(jq '.plotlines.main.completedNodes | length' "$PLOT_TRACKER")
        echo ""
        echo "✅ โหนดเหตุการณ์ที่เสร็จสิ้น: ${COMPLETED_COUNT} รายการ"
        jq -r '.plotlines.main.completedNodes[]? | "  • " + .' "$PLOT_TRACKER" 2>/dev/null || true

        # โหนดเหตุการณ์ที่กำลังจะเกิดขึ้น
        UPCOMING_COUNT=$(jq '.plotlines.main.upcomingNodes | length' "$PLOT_TRACKER")
        if [ "$UPCOMING_COUNT" -gt 0 ]; then
            echo ""
            echo "→ โหนดเหตุการณ์ถัดไป:"
            jq -r '.plotlines.main.upcomingNodes[0:3][]? | "  • " + .' "$PLOT_TRACKER" 2>/dev/null || true
        fi
    fi
}

# ตรวจสอบสถานะปมและเบาะแส (Foreshadowing)
check_foreshadowing() {
    echo ""
    echo "🎯 การติดตามปมเรื่อง (Foreshadowing)"
    echo "───────────"

    if [ -f "$PLOT_TRACKER" ]; then
        # สถิติปมเรื่อง
        TOTAL_FORESHADOW=$(jq '.foreshadowing | length' "$PLOT_TRACKER")
        ACTIVE_FORESHADOW=$(jq '[.foreshadowing[] | select(.status == "active")] | length' "$PLOT_TRACKER")
        RESOLVED_FORESHADOW=$(jq '[.foreshadowing[] | select(.status == "resolved")] | length' "$PLOT_TRACKER")

        echo "สถิติ: ทั้งหมด ${TOTAL_FORESHADOW} รายการ, กำลังทำงาน (Active) ${ACTIVE_FORESHADOW} รายการ, คลี่คลายแล้ว ${RESOLVED_FORESHADOW} รายการ"

        # รายการปมเรื่องที่ยังค้างอยู่
        if [ "$ACTIVE_FORESHADOW" -gt 0 ]; then
            echo ""
            echo "⚠️ ปมเรื่องที่รอการคลี่คลาย:"
            jq -r '.foreshadowing[] | select(.status == "active") |
                "  • " + .content + " (วางปมไว้ในตอนที่ " + (.planted.chapter | tostring) + ")"' \
                "$PLOT_TRACKER" 2>/dev/null || true
        fi

        # ตรวจสอบปมเรื่องที่ค้างนานเกินกำหนด (เกิน 30 ตอน)
        OVERDUE=$(jq --arg current "$CURRENT_CHAPTER" '
            [.foreshadowing[] |
             select(.status == "active" and .planted.chapter and
                    (($current | tonumber) - .planted.chapter) > 30)] |
            length' "$PLOT_TRACKER")

        if [ "$OVERDUE" -gt 0 ]; then
            echo ""
            echo "⚠️ คำเตือน: มี ${OVERDUE} ปม ที่ปล่อยค้างไว้เกิน 30 ตอนแล้วยังไม่ได้คลี่คลาย"
        fi
    fi
}

# ตรวจสอบการพัฒนาของข้อขัดแย้ง/ปมปัญหา (Conflicts)
check_conflicts() {
    echo ""
    echo "⚔️ การติดตามข้อขัดแย้ง/ปมปัญหา"
    echo "───────────"

    if [ -f "$PLOT_TRACKER" ]; then
        ACTIVE_CONFLICTS=$(jq '.conflicts.active | length' "$PLOT_TRACKER")

        if [ "$ACTIVE_CONFLICTS" -gt 0 ]; then
            echo "ข้อขัดแย้งที่กำลังดำเนินอยู่ปัจจุบัน: ${ACTIVE_CONFLICTS} รายการ"
            jq -r '.conflicts.active[] |
                "  • " + .name + " [" + .intensity + "]"' \
                "$PLOT_TRACKER" 2>/dev/null || true
        else
            echo "ไม่มีข้อขัดแย้งที่กำลังดำเนินอยู่ชั่วคราว"
        fi
    fi
}

# สร้างข้อเสนอแนะและคำแนะนำ
generate_suggestions() {
    echo ""
    echo "💡 ข้อเสนอแนะ"
    echo "───────"

    # ให้คำแนะนำโดยอิงจากบท/ตอนปัจจุบัน
    if [ "$CURRENT_CHAPTER" -lt 10 ]; then
        echo "• ช่วง 10 ตอนแรกคือสิ่งสำคัญ ตรวจสอบให้แน่ใจว่ามี 'เบ็ดดักผู้อ่าน' (Hooks) ที่ดึงดูดใจพอ"
    elif [ "$CURRENT_CHAPTER" -lt 30 ]; then
        echo "• กำลังเข้าใกล้จุดไคลแมกซ์ย่อยแรก ตรวจสอบว่าความขัดแย้งมีความเข้มข้นพอหรือยัง"
    elif [ "$((CURRENT_CHAPTER % 60))" -gt 50 ]; then
        echo "• กำลังเข้าสู่ช่วงท้ายเล่ม เตรียมพร้อมสำหรับการตั้งปมปริศนาและจัดวางช่วงไคลแมกซ์ใหญ่"
    fi

    # ให้คำแนะนำโดยอิงจากสถานะปมเรื่อง
    if [ "$ACTIVE_FORESHADOW" -gt 5 ]; then
        echo "• มีปมเรื่องที่ปล่อยค้างไว้ค่อนข้างมาก ควรพิจารณาคลี่คลายปมบางส่วนในตอนถัดๆ ไป"
    fi

    # ให้คำแนะนำโดยอิงจากสถานะข้อขัดแย้ง
    if [ "$ACTIVE_CONFLICTS" -eq 0 ] && [ "$CURRENT_CHAPTER" -gt 5 ]; then
        echo "• ปัจจุบันไม่มีความขัดแย้งหลักที่ดำเนินอยู่ พิจารณาเพิ่มจุดหักเหหรือสร้างความขัดแย้งใหม่"
    fi
}

# สร้างเอาต์พุตในรูปแบบ Checklist (รายการตรวจสอบ)
output_checklist() {
    # ตรวจสอบไฟล์ที่จำเป็น (ทำงานแบบเงียบ)
    check_required_files > /dev/null 2>&1 || true

    # รับข้อมูลความคืบหน้าปัจจุบัน
    get_current_progress

    # รวบรวมข้อมูล
    local main_plot="ยังไม่ได้กำหนด"
    local plot_status="unknown"
    local completed_count=0
    local upcoming_count=0
    local total_foreshadow=0
    local active_foreshadow=0
    local resolved_foreshadow=0
    local overdue_foreshadow=0
    local active_conflicts=0

    if [ -f "$PLOT_TRACKER" ]; then
        main_plot=$(jq -r '.plotlines.main.currentNode // "ยังไม่ได้กำหนด"' "$PLOT_TRACKER")
        plot_status=$(jq -r '.plotlines.main.status // "unknown"' "$PLOT_TRACKER")
        completed_count=$(jq '.plotlines.main.completedNodes | length' "$PLOT_TRACKER")
        upcoming_count=$(jq '.plotlines.main.upcomingNodes | length' "$PLOT_TRACKER")

        total_foreshadow=$(jq '.foreshadowing | length' "$PLOT_TRACKER")
        active_foreshadow=$(jq '[.foreshadowing[] | select(.status == "active")] | length' "$PLOT_TRACKER")
        resolved_foreshadow=$(jq '[.foreshadowing[] | select(.status == "resolved")] | length' "$PLOT_TRACKER")

        overdue_foreshadow=$(jq --arg current "$CURRENT_CHAPTER" '
            [.foreshadowing[] |
             select(.status == "active" and .planted.chapter and
                    (($current | tonumber) - .planted.chapter) > 30)] |
            length' "$PLOT_TRACKER")

        active_conflicts=$(jq '.conflicts.active | length' "$PLOT_TRACKER")
    fi

    # แสดงผลข้อมูลในรูปแบบของ Markdown Checklist
    cat <<EOF
# รายการตรวจสอบการจัดวางพล็อตและเนื้อเรื่อง (Checklist)

**เวลาที่ตรวจสอบ**: $(date '+%Y-%m-%d %H:%M:%S')
**เป้าหมายการตรวจสอบ**: plot-tracker.json, outline.md, progress.json
**ความคืบหน้าปัจจุบัน**: ตอนที่ ${CURRENT_CHAPTER} (เล่มที่ ${CURRENT_VOLUME})

---

## ความสมบูรณ์ของไฟล์

- [$([ -f "$PLOT_TRACKER" ] && echo "x" || echo " ")] CHK001 plot-tracker.json มีอยู่จริง
- [$([ -f "$OUTLINE" ] && echo "x" || echo " ")] CHK002 outline.md มีอยู่จริง
- [$([ -f "$PROGRESS" ] && echo "x" || echo " ")] CHK003 progress.json มีอยู่จริง

## ความคืบหน้าของโครงเรื่อง

- [$([ "$plot_status" != "unknown" ] && echo "x" || echo " ")] CHK004 อัปเดตสถานะเส้นเรื่องหลักแล้ว (ปัจจุบัน: $plot_status)
- [x] CHK005 ความคืบหน้าโหนดพล็อตหลัก: $main_plot
- [$([ $completed_count -gt 0 ] && echo "x" || echo " ")] CHK006 โหนดเนื้อเรื่องที่เสร็จสิ้นแล้ว ($completed_count รายการ)
- [$([ $upcoming_count -gt 0 ] && echo "x" || echo " ")] CHK007 โหนดเนื้อเรื่องถัดไปได้รับการวางแผนแล้ว ($upcoming_count รายการ)

## การจัดการปมเรื่อง (Foreshadowing)

EOF

    if [ $total_foreshadow -gt 0 ]; then
        echo "- [x] CHK008 มีบันทึกปมเรื่องอยู่จริง (รวมทั้งหมด $total_foreshadow รายการ)"
        echo "- [x] CHK009 ติดตามสถานะปมเรื่อง (กำลังทำงาน $active_foreshadow รายการ, คลี่คลายแล้ว $resolved_foreshadow รายการ)"

        if [ $overdue_foreshadow -eq 0 ]; then
            echo "- [x] CHK010 คลี่คลายปมเรื่องได้ทันเวลา (ไม่มีปมที่ค้างนานเกิน 30 ตอน)"
        else
            echo "- [!] CHK010 คลี่คลายปมเรื่องได้ทันเวลา (⚠️ พบ ${overdue_foreshadow} ปม ที่ปล่อยค้างไว้เกิน 30 ตอน)"
        fi

        if [ $active_foreshadow -le 5 ]; then
            echo "- [x] CHK011 จำนวนปมที่กำลังทำงานอยู่ในระดับที่เหมาะสม ($active_foreshadow ≤ 5)"
        elif [ $active_foreshadow -le 10 ]; then
            echo "- [!] CHK011 จำนวนปมที่กำลังทำงานอยู่เริ่มเยอะ ($active_foreshadow รายการ ขอแนะนำให้ทยอยคลี่คลายบ้าง)"
        else
            echo "- [!] CHK011 จำนวนปมที่กำลังทำงานอยู่มีมากเกินไป (⚠️ $active_foreshadow > 10 อาจทำให้ผู้อ่านเกิดความสับสน)"
        fi
    else
        echo "- [ ] CHK008 มีบันทึกปมเรื่องอยู่จริง (ไม่พบบันทึกปมเรื่อง)"
        echo "- [ ] CHK009 ติดตามสถานะปมเรื่อง (ไม่มีข้อมูล)"
        echo "- [ ] CHK010 คลี่คลายปมเรื่องได้ทันเวลา (ไม่มีข้อมูล)"
        echo "- [ ] CHK011 จำนวนปมที่กำลังทำงานอยู่ในระดับที่เหมาะสม (ไม่มีข้อมูล)"
    fi

    cat <<EOF

## การพัฒนาความขัดแย้ง

EOF

    if [ $active_conflicts -gt 0 ]; then
        echo "- [x] CHK012 มีความขัดแย้งที่กำลังดำเนินอยู่ ($active_conflicts รายการ)"
    elif [ $CURRENT_CHAPTER -gt 5 ]; then
        echo "- [!] CHK012 มีความขัดแย้งที่กำลังดำเนินอยู่ (⚠️ ปัจจุบันไม่มีความขัดแย้ง ขอแนะนำให้เพิ่มปมปัญหาหรือเรื่องราวหักเห)"
    else
        echo "- [x] CHK012 มีความขัดแย้งที่กำลังดำเนินอยู่ (เป็นตอนแรกๆ สามารถไม่มีความขัดแย้งหนักๆ ได้)"
    fi

    cat <<EOF

## คำแนะนำด้านจังหวะการเล่าเรื่อง (Pacing)

EOF

    # ให้คำแนะนำในรูปแบบ Checklist ตามตอนปัจจุบัน
    if [ $CURRENT_CHAPTER -lt 10 ]; then
        echo "- [ ] CHK013 ตรวจสอบเบ็ดดักผู้อ่านใน 10 ตอนแรก (มั่นใจว่าดึงดูดใจพอ)"
    elif [ $CURRENT_CHAPTER -lt 30 ]; then
        echo "- [ ] CHK014 เตรียมพร้อมสำหรับจุดไคลแมกซ์ย่อยแรก (ตรวจสอบความเข้มข้นของความขัดแย้ง)"
    elif [ $((CURRENT_CHAPTER % 60)) -gt 50 ]; then
        echo "- [ ] CHK015 จัดวางช่วงท้ายเล่ม (เตรียมพร้อมรับความตื่นเต้นและสร้างปมทิ้งท้ายเล่ม)"
    else
        echo "- [x] CHK016 จังหวะเนื้อเรื่องดำเนินไปตามปกติ (ไม่มีการแจ้งเตือนจุดวิกฤตพิเศษ)"
    fi

    cat <<EOF

---

## สิ่งที่ต้องทำต่อไป (Actions)

EOF

    # สร้างรายการสิ่งที่ต้องทำต่อไปตามสถานการณ์โดยอัตโนมัติ
    local has_actions=false

    if [ $overdue_foreshadow -gt 0 ]; then
        echo "- [ ] ตามเก็บและคลี่คลายปมเรื่องที่ค้างนานเกินกำหนด (${overdue_foreshadow} รายการ)"
        has_actions=true
    fi

    if [ $active_foreshadow -gt 10 ]; then
        echo "- [ ] ลดจำนวนปมเรื่องที่ยังค้างอยู่ลง (ปัจจุบันมี $active_foreshadow รายการ)"
        has_actions=true
    fi

    if [ $active_conflicts -eq 0 ] && [ $CURRENT_CHAPTER -gt 5 ]; then
        echo "- [ ] ใส่ประเด็นความขัดแย้งหรืออุปสรรคใหม่เข้ามาในเนื้อหา"
        has_actions=true
    fi

    if [ $upcoming_count -eq 0 ]; then
        echo "- [ ] วางแผนพล็อตและกำหนดโหนดเนื้อเรื่องถัดไปเพิ่มเติม"
        has_actions=true
    fi

    if [ "$has_actions" = false ]; then
        echo "*สถานการณ์การดำเนินเนื้อเรื่องปัจจุบันปกติดี ไม่จำเป็นต้องดำเนินการใดๆ เป็นพิเศษ*"
    fi

    cat <<EOF

---

**เครื่องมือตรวจสอบ**: check-plot.sh
**เวอร์ชัน**: 1.1 (รองรับการแสดงผลแบบ checklist)
EOF
}

# ฟังก์ชันหลัก (Main)
main() {
    if [ "$CHECKLIST_MODE" = true ]; then
        output_checklist
    else
        echo "🔍 เริ่มต้นตรวจสอบความสอดคล้องของพล็อตเนื้อเรื่อง..."
        echo ""

        # ตรวจสอบไฟล์ที่จำเป็น
        check_required_files

        # รับข้อมูลความคืบหน้าปัจจุบัน
        get_current_progress

        # เริ่มต้นทำกระบวนการตรวจสอบต่างๆ
        analyze_plot_alignment
        check_foreshadowing
        check_conflicts
        generate_suggestions

        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━"
        echo "✅ ตรวจสอบเสร็จสิ้นเรียบร้อย"
    fi

    # อัปเดตเวลาการตรวจสอบล่าสุดกลับเข้าไปในไฟล์ JSON
    if [ -f "$PLOT_TRACKER" ]; then
        TEMP_FILE=$(mktemp)
        jq --arg date "$(date -Iseconds)" '.lastUpdated = $date' "$PLOT_TRACKER" > "$TEMP_FILE"
        mv "$TEMP_FILE" "$PLOT_TRACKER"
    fi
}

# เริ่มเรียกใช้งานฟังก์ชันหลัก
main
