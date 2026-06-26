#!/bin/bash

# สคริปต์ตรวจสอบและวิเคราะห์เนื้อเรื่อง
# สำหรับใช้กับคำสั่ง /analyze

set -e

# โหลดฟังก์ชันส่วนกลาง (Source common functions)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# แยกแยะอาร์กิวเมนต์ (Parse arguments)
STORY_NAME="$1"
ANALYSIS_TYPE="${2:-full}"  # full (เต็มรูปแบบ), compliance (ความสอดคล้อง), quality (คุณภาพ), progress (ความคืบหน้า)

# รับพาธรากของโปรเจกต์ (Get project root)
PROJECT_ROOT=$(get_project_root)
cd "$PROJECT_ROOT"

# กำหนดพาธของเนื้อเรื่อง
if [ -z "$STORY_NAME" ]; then
    STORY_NAME=$(get_active_story)
fi

STORY_DIR="stories/$STORY_NAME"

# ตรวจสอบไฟล์เอกสารอ้างอิงที่จำเป็น
check_story_files() {
    local missing_files=()

    # ตรวจสอบเอกสารเกณฑ์มาตรฐาน
    [ ! -f ".specify/memory/constitution.md" ] && missing_files+=("เอกสารรัฐธรรมนูญ/กฎหลัก (constitution)")
    [ ! -f "$STORY_DIR/specification.md" ] && missing_files+=("เอกสารข้อกำหนด (specification)")
    [ ! -f "$STORY_DIR/creative-plan.md" ] && missing_files+=("เอกสารแผนงานสร้างสรรค์ (creative-plan)")

    if [ ${#missing_files[@]} -gt 0 ]; then
        echo "⚠️ ขาดเอกสารเกณฑ์มาตรฐานดังต่อไปนี้:"
        for file in "${missing_files[@]}"; do
            echo "  - $file"
        done
        return 1
    fi

    return 0
}

# สถิติเนื้อหา
analyze_content() {
    local content_dir="$STORY_DIR/content"
    local total_words=0
    local chapter_count=0

    if [ -d "$content_dir" ]; then
        echo "สถิติเนื้อหา:"
        echo ""
        for file in "$content_dir"/*.md; do
            if [ -f "$file" ]; then
                ((chapter_count++))
                # นับจำนวนคำภาษาจีนอย่างแม่นยำ
                local words=$(count_chinese_words "$file")
                ((total_words += words))
                local filename=$(basename "$file")
                echo "  $filename: $words คำ"
            fi
        done
        echo ""
        echo "  จำนวนคำทั้งหมด: $total_words"
        echo "  จำนวนตอน/บท: $chapter_count"
        if [ $chapter_count -gt 0 ]; then
            echo "  ความยาวเฉลี่ยต่อตอน: $((total_words / chapter_count)) คำ"
        fi
    else
        echo "สถิติเนื้อหา:"
        echo "  ยังไม่ได้เริ่มเขียน"
    fi
}

# ตรวจสอบความคืบหน้าของงาน
check_task_completion() {
    local tasks_file="$STORY_DIR/tasks.md"
    if [ ! -f "$tasks_file" ]; then
        echo "ไม่พบไฟล์รายการงาน (tasks.md)"
        return
    fi

    local total_tasks=$(grep -c "^- \[" "$tasks_file" 2>/dev/null || echo 0)
    local completed_tasks=$(grep -c "^- \[x\]" "$tasks_file" 2>/dev/null || echo 0)
    local in_progress=$(grep -c "^- \[~\]" "$tasks_file" 2>/dev/null || echo 0)
    local pending=$((total_tasks - completed_tasks - in_progress))

    echo "ความคืบหน้าของงาน:"
    echo "  งานทั้งหมด: $total_tasks"
    echo "  เสร็จสิ้นแล้ว: $completed_tasks"
    echo "  กำลังดำเนินการ: $in_progress"
    echo "  ยังไม่ได้รับทำ: $pending"

    if [ $total_tasks -gt 0 ]; then
        local completion_rate=$((completed_tasks * 100 / total_tasks))
        echo "  อัตราความสำเร็จ: $completion_rate%"
    fi
}

# ตรวจสอบความสอดคล้องกับข้อกำหนด
check_specification_compliance() {
    local spec_file="$STORY_DIR/specification.md"

    echo "การตรวจสอบความสอดคล้องกับข้อกำหนด:"

    # ตรวจสอบความต้องการระดับ P0 (ฉบับย่อ)
    local p0_count=$(grep -c "^### 必须包含（P0）" "$spec_file" 2>/dev/null || echo 0)
    if [ $p0_count -gt 0 ]; then
        echo "  ความต้องการ P0: ตรวจพบแล้ว จำเป็นต้องใช้คนตรวจสอบ (Manual Verify)"
    fi

    # ตรวจสอบว่ายังคงมีเครื่องหมาย [ต้องการคำชี้แจง] หลงเหลืออยู่หรือไม่
    local unclear=$(grep -c "\[需要澄清\]" "$spec_file" 2>/dev/null || echo 0)
    if [ $unclear -gt 0 ]; then
        echo "  ⚠️ ยังมีอีก $unclear จุดที่ต้องการคำชี้แจง"
    else
        echo "  ✅ การตัดสินใจทั้งหมดได้รับการชี้แจงเรียบร้อยแล้ว"
    fi
}

# กระบวนการวิเคราะห์หลัก
main() {
    echo "รายงานการวิเคราะห์เนื้อเรื่อง"
    echo "============"
    echo "เนื้อเรื่อง: $STORY_NAME"
    echo "เวลาที่วิเคราะห์: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""

    # ตรวจสอบเอกสารเกณฑ์มาตรฐาน
    if ! check_story_files; then
        echo ""
        echo "❌ ไม่สามารถดำเนินการวิเคราะห์แบบเต็มรูปแบบได้ กรุณากรอกเอกสารเกณฑ์มาตรฐานให้ครบถ้วนก่อน"
        exit 1
    fi

    echo "✅ เอกสารเกณฑ์มาตรฐานครบถ้วน"
    echo ""

    # ดำเนินการตามประเภทการวิเคราะห์ที่กำหนด
    case "$ANALYSIS_TYPE" in
        full)
            analyze_content
            echo ""
            check_task_completion
            echo ""
            check_specification_compliance
            ;;
        quality)
            analyze_content
            ;;
        progress)
            check_task_completion
            ;;
        compliance)
            check_specification_compliance
            ;;
        *)
            echo "ไม่รู้จักประเภทการวิเคราะห์: $ANALYSIS_TYPE"
            exit 1
            ;;
    esac

    echo ""
    echo "วิเคราะห์เสร็จสิ้น รายงานโดยละเอียดได้รับการบันทึกไว้ที่: $STORY_DIR/analysis-report.md"
}

main
