#!/bin/bash

# สคริปต์ตรวจสอบสถานะการเขียน
# สำหรับใช้ร่วมกับคำสั่ง /write

set -e

# โหลดฟังก์ชันสากล (Common Functions)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# ตรวจสอบว่าอยู่ในโหมด Checklist หรือไม่
CHECKLIST_MODE=false
if [ "$1" = "--checklist" ]; then
    CHECKLIST_MODE=true
fi

# รับไดเรกทอรีรากของโปรเจกต์ (Project Root)
PROJECT_ROOT=$(get_project_root)
cd "$PROJECT_ROOT"

# รับชื่อเรื่องปัจจุบัน
STORY_NAME=$(get_active_story)
STORY_DIR="stories/$STORY_NAME"

# 1. ตรวจสอบเอกสารระเบียบวิธี (Methodology Docs)
check_methodology_docs() {
    local missing=()

    [ ! -f ".specify/memory/constitution.md" ] && missing+=("รัฐธรรมนูญ (Constitution)")
    [ ! -f "$STORY_DIR/specification.md" ] && missing+=("ข้อกำหนดเฉพาะ (Specification)")
    [ ! -f "$STORY_DIR/creative-plan.md" ] && missing+=("แผนงาน (Creative Plan)")
    [ ! -f "$STORY_DIR/tasks.md" ] && missing+=("งานที่ต้องทำ (Tasks)")

    if [ ${#missing[@]} -gt 0 ]; then
        echo "⚠️ ขาดเอกสารเกณฑ์มาตรฐาน (Baseline Docs) ดังต่อไปนี้:"
        for doc in "${missing[@]}"; do
            echo "  - $doc"
        done
        echo ""
        echo "แนะนำให้ดำเนินการตามระเบียบวิธี 7 ขั้นตอน (7-Step Methodology) เพื่อสร้างเอกสารก่อนหน้าให้เสร็จสิ้น:"
        echo "1. /constitution  - สร้างรัฐธรรมนูญแห่งการสร้างสรรค์"
        echo "2. /specify       - กำหนดข้อกำหนดเฉพาะของเรื่อง"
        echo "3. /clarify       - แจกแจงการตัดสินใจที่สำคัญ"
        echo "4. /plan          - จัดทำแผนงานสร้างสรรค์"
        echo "5. /tasks         - สร้างรายการงานที่ต้องทำ"
        return 1
    fi

    echo "✅ เอกสารระเบียบวิธีครบถ้วนสมบูรณ์"
    return 0
}

# 2. ตรวจสอบงานที่รอดำเนินการ (Pending Tasks)
check_pending_tasks() {
    local tasks_file="$STORY_DIR/tasks.md"

    if [ ! -f "$tasks_file" ]; then
        echo "❌ ไม่พบไฟล์รายการงาน (tasks.md)"
        return 1
    fi

    # สรุปสถิติสถานะงาน
    local pending=$(grep -c "^- \[ \]" "$tasks_file" 2>/dev/null || echo 0)
    local in_progress=$(grep -c "^- \[~\]" "$tasks_file" 2>/dev/null || echo 0)
    local completed=$(grep -c "^- \[x\]" "$tasks_file" 2>/dev/null || echo 0)

    echo ""
    echo "สถานะงาน (Task Status):"
    echo "  รอดำเนินการ: $pending"
    echo "  กำลังทำ: $in_progress"
    echo "  เสร็จสิ้นแล้ว: $completed"

    if [ $pending -eq 0 ] && [ $in_progress -eq 0 ]; then
        echo ""
        echo "🎉 งานทั้งหมดเสร็จสมบูรณ์แล้ว!"
        echo "แนะนำให้รันคำสั่ง /analyze เพื่อทำการตรวจสอบและยืนยันในภาพรวม"
        return 0
    fi

    # แสดงงานชิ้นถัดไปที่ต้องเขียน
    echo ""
    echo "งานเขียนชิ้นถัดไป:"
    grep "^- \[ \]" "$tasks_file" | head -n 1 || echo "（ไม่มีงานที่ค้างอยู่）"
}

# 3. ตรวจสอบเนื้อหาที่เขียนเสร็จแล้ว (Completed Content)
check_completed_content() {
    local content_dir="$STORY_DIR/content"
    local validation_rules="spec/tracking/validation-rules.json"
    local min_words=2000
    local max_words=4000

    # อ่านกฎการตรวจสอบความถูกต้อง (ถ้ามีอยู่จริง)
    if [ -f "$validation_rules" ]; then
        if command -v jq >/dev/null 2>&1; then
            min_words=$(jq -r '.rules.chapterMinWords // 2000' "$validation_rules")
            max_words=$(jq -r '.rules.chapterMaxWords // 4000' "$validation_rules")
        fi
    fi

    if [ -d "$content_dir" ]; then
        local chapter_count=$(ls "$content_dir"/*.md 2>/dev/null | wc -l)
        if [ $chapter_count -gt 0 ]; then
            echo ""
            echo "บทที่เขียนเสร็จแล้ว: $chapter_count บท"
            echo "เกณฑ์จำนวนคำ: ${min_words}-${max_words} คำ"
            echo ""
            echo "งานเขียนล่าสุด:"
            for file in $(ls -t "$content_dir"/*.md 2>/dev/null | head -n 3); do
                local filename=$(basename "$file")
                local words=$(count_thai_words "$file")
                local status="✅"

                if [ "$words" -lt "$min_words" ]; then
                    status="⚠️ จำนวนคำไม่ถึงเกณฑ์"
                elif [ "$words" -gt "$max_words" ]; then
                    status="⚠️ จำนวนคำเกินเกณฑ์"
                fi

                echo "  - $filename: $words คำ $status"
            done
        fi
    else
        echo ""
        echo "ยังไม่ได้เริ่มต้นเขียนเนื้อหา"
    fi
}

# ฟังก์ชันสร้างเอาต์พุตในรูปแบบ รายการตรวจสอบ (Checklist Markdown)
output_checklist() {
    local has_constitution=false
    local has_specification=false
    local has_plan=false
    local has_tasks=false
    local pending=0
    local in_progress=0
    local completed=0
    local chapter_count=0
    local bad_chapters=0
    local min_words=2000
    local max_words=4000

    # ตรวจสอบการมีอยู่ของเอกสาร
    [ -f ".specify/memory/constitution.md" ] && has_constitution=true
    [ -f "$STORY_DIR/specification.md" ] && has_specification=true
    [ -f "$STORY_DIR/creative-plan.md" ] && has_plan=true
    [ -f "$STORY_DIR/tasks.md" ] && has_tasks=true

    # สรุปสถิติจำนวนงาน
    if [ "$has_tasks" = true ]; then
        pending=$(grep -c "^- \[ \]" "$STORY_DIR/tasks.md" 2>/dev/null || echo 0)
        in_progress=$(grep -c "^- \[~\]" "$STORY_DIR/tasks.md" 2>/dev/null || echo 0)
        completed=$(grep -c "^- \[x\]" "$STORY_DIR/tasks.md" 2>/dev/null || echo 0)
    fi

    # อ่านกฎการตรวจสอบความถูกต้อง
    local validation_rules="$STORY_DIR/spec/tracking/validation-rules.json"
    if [ -f "$validation_rules" ] && command -v jq >/dev/null 2>&1; then
        min_words=$(jq -r '.rules.chapterMinWords // 2000' "$validation_rules")
        max_words=$(jq -r '.rules.chapterMaxWords // 4000' "$validation_rules")
    fi

    # ตรวจสอบเนื้อหาแต่ละบท
    local content_dir="$STORY_DIR/content"
    if [ -d "$content_dir" ]; then
        chapter_count=$(ls "$content_dir"/*.md 2>/dev/null | wc -l | tr -d ' ')

        # นับจำนวนบทที่ไม่ผ่านเกณฑ์จำนวนคำ
        for file in "$content_dir"/*.md; do
            [ -f "$file" ] || continue
            local words=$(count_chinese_words "$file")
            if [ "$words" -lt "$min_words" ] || [ "$words" -gt "$max_words" ]; then
                bad_chapters=$((bad_chapters + 1))
            fi
        done
    fi

    # คำนวณงานทั้งหมดและอัตราการความสำเร็จ
    local total_tasks=$((pending + in_progress + completed))
    local completion_rate=0
    if [ $total_tasks -gt 0 ]; then
        completion_rate=$((completed * 100 / total_tasks))
    fi

    # พิมพ์ Checklist ด้วยคำสั่ง cat
    cat <<EOF
# รายการตรวจสอบสถานะการเขียน (Writing State Checklist)

**เวลาที่ตรวจสอบ**: $(date '+%Y-%m-%d %H:%M:%S')
**เรื่องปัจจุบัน**: $STORY_NAME
**มาตรฐานจำนวนคำ**: ${min_words}-${max_words} คำ

---

## ความสมบูรณ์ของเอกสาร

- [$([ "$has_constitution" = true ] && echo "x" || echo " ")] CHK001 constitution.md มีอยู่จริง
- [$([ "$has_specification" = true ] && echo "x" || echo " ")] CHK002 specification.md มีอยู่จริง
- [$([ "$has_plan" = true ] && echo "x" || echo " ")] CHK003 creative-plan.md มีอยู่จริง
- [$([ "$has_tasks" = true ] && echo "x" || echo " ")] CHK004 tasks.md 有存在 มีอยู่จริง

## ความคืบหน้าของงาน

EOF

    if [ "$has_tasks" = true ]; then
        echo "- [$([ $in_progress -gt 0 ] && echo "x" || echo " ")] CHK005 มีงานที่กำลังทำอยู่ ($in_progress งาน)"
        echo "- [x] CHK006 จำนวนงานที่รอดำเนินการ ($pending งาน)"
        echo "- [$([ $completed -gt 0 ] && echo "x" || echo " ")] CHK007 ความคืบหน้างานที่เสร็จสิ้น ($completed/$total_tasks = $completion_rate%)"
    else
        echo "- [ ] CHK005 มีงานที่กำลังทำอยู่ (ไม่พบไฟล์ tasks.md)"
        echo "- [ ] CHK006 จำนวนงานที่รอดำเนินการ (ไม่พบไฟล์ tasks.md)"
        echo "- [ ] CHK007 ความคืบหน้างานที่เสร็จสิ้น (ไม่พบไฟล์ tasks.md)"
    fi

    cat <<EOF

## คุณภาพเนื้อหา

- [$([ $chapter_count -gt 0 ] && echo "x" || echo " ")] CHK008 จำนวนบทที่เขียนเสร็จแล้ว ($chapter_count บท)
EOF

    if [ $chapter_count -gt 0 ]; then
        echo "- [$([ $bad_chapters -eq 0 ] && echo "x" || echo "!")] CHK009 จำนวนคำถูกต้องตามมาตรฐาน ($([ $bad_chapters -eq 0 ] && echo "ผ่านทุกบท" || echo "ไม่ผ่านเกณฑ์ $bad_chapters บท")）"
    else
        echo "- [ ] CHK009 จำนวนคำถูกต้องตามมาตรฐาน (ยังไม่ได้เริ่มเขียนเนื้อหา)"
    fi

    cat <<EOF

---

## สิ่งที่ต้องทำต่อไป (Action Items)

EOF

    local has_actions=false

    # ตรวจสอบเอกสารที่ขาดหายไป
    if [ "$has_constitution" = false ] || [ "$has_specification" = false ] || [ "$has_plan" = false ] || [ "$has_tasks" = false ]; then
        echo "- [ ] จัดทำเอกสารระเบียบวิธีให้สมบูรณ์ (โดยรันคำสั่งที่เกี่ยวข้อง: /constitution, /specify, /plan, /tasks)"
        has_actions=true
    fi

    # ตรวจสอบงานที่ค้าง
    if [ $pending -gt 0 ] || [ $in_progress -gt 0 ]; then
        if [ $in_progress -gt 0 ]; then
            echo "- [ ] ทำงานที่ค้างอยู่ต่อไป (เหลืออีก $in_progress งาน)"
        else
            echo "- [ ] เริ่มต้นงานเขียนชิ้นถัดไปที่รอดำเนินการ (ทั้งหมด $pending งาน)"
        fi
        has_actions=true
    fi

    # ตรวจสอบคุณภาพบทความ
    if [ $bad_chapters -gt 0 ]; then
        echo "- [ ] แก้ไขปรับปรุงจำนวนคำในบทที่ไม่ผ่านเกณฑ์มาตรฐาน ($bad_chapters บท)"
        has_actions=true
    fi

    # ข้อเสนอแนะเมื่อเสร็จสิ้นงานทั้งหมด
    if [ $pending -eq 0 ] && [ $in_progress -eq 0 ] && [ $completed -gt 0 ]; then
        echo "- [ ] รันคำสั่ง /analyze เพื่อตรวจสอบความถูกต้องอย่างครอบคลุม"
        has_actions=true
    fi

    if [ "$has_actions" = false ]; then
        echo "*สถานะการเขียนอยู่ในเกณฑ์ดีเยี่ยม ไม่จำเป็นต้องดำเนินการใดๆ เป็นพิเศษ*"
    fi

    cat <<EOF

---

**เครื่องมือตรวจสอบ**: check-writing-state.sh
**เวอร์ชัน**: 1.1 (รองรับการแสดงผลแบบ checklist)
EOF
}

# กระบวนการหลัก (Main Flow)
main() {
    # หากอยู่ในโหมด Checklist ให้แสดงผลลัพธ์แล้วจบการทำงานทันที
    if [ "$CHECKLIST_MODE" = true ]; then
        output_checklist
        exit 0
    fi

    # โหมดการแสดงรายงานแบบละเอียดดั้งเดิม
    echo "ตรวจสอบสถานะการเขียน"
    echo "=================="
    echo "เรื่องปัจจุบัน: $STORY_NAME"
    echo ""

    if ! check_methodology_docs; then
        exit 1
    fi

    check_pending_tasks
    check_completed_content

    echo ""
    echo "ทุกอย่างพร้อมแล้ว สามารถเริ่มต้นเขียนงานได้"
}

main
