#!/bin/bash

# สคริปต์ย่อยสลายและแยกงานเขียน
# สำหรับใช้ร่วมกับคำสั่ง /tasks

set -e

# โหลดฟังก์ชันสากล (Common Functions)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# รับอาร์กิวเมนต์คำสั่ง
STORY_NAME=""
if [ $# -gt 0 ]; then
    STORY_NAME="$1"
fi

# รับไดเรกทอรีรากของโปรเจกต์ (Project Root)
PROJECT_ROOT=$(get_project_root)
cd "$PROJECT_ROOT"

# ตรวจสอบเพื่อระบุชื่อเรื่องนิยาย
if [ -z "$STORY_NAME" ]; then
    STORY_NAME=$(get_active_story)
fi

STORY_DIR="stories/$STORY_NAME"
SPEC_FILE="$STORY_DIR/specification.md"
PLAN_FILE="$STORY_DIR/creative-plan.md"
TASKS_FILE="$STORY_DIR/tasks.md"

echo "การย่อยสลายงานเขียน (Task Decomposition)"
echo "====================================="
echo "เรื่อง：$STORY_NAME"
echo ""

# ตรวจสอบเอกสารก่อนหน้า (Prerequisites Check)
missing=()

if [ ! -f ".specify/memory/constitution.md" ]; then
    missing+=("ไฟล์รัฐธรรมนูญ (Constitution)")
fi

if [ ! -f "$SPEC_FILE" ]; then
    missing+=("文件规格 ไฟล์ข้อกำหนดเฉพาะ (Specification)")
fi

if [ ! -f "$PLAN_FILE" ]; then
    missing+=("文件计划 ไฟล์แผนงานสร้างสรรค์ (Creative Plan)")
fi

if [ ${#missing[@]} -gt 0 ]; then
    echo "⚠️ ขาดเอกสารก่อนหน้าดังต่อไปนี้："
    for doc in "${missing[@]}"; do
        echo "  - $doc"
    done
    echo ""
    echo "กรุณาดำเนินการขั้นตอนต่อไปนี้ให้เสร็จสิ้นก่อน："
    if [ ! -f ".specify/memory/constitution.md" ]; then
        echo "  1. /constitution - สร้างรัฐธรรมนูญแห่งการสร้างสรรค์"
    fi
    if [ ! -f "$SPEC_FILE" ]; then
        echo "  2. /specify       - กำหนดข้อกำหนดเฉพาะของเรื่อง"
    fi
    if [ ! -f "$PLAN_FILE" ]; then
        echo "  3. /plan          - จัดทำแผนงานสร้างสรรค์"
    fi
    exit 1
fi

# ตรวจสอบไฟล์รายการงาน (Tasks File)
if [ -f "$TASKS_FILE" ]; then
    echo ""
    echo "📋 พบไฟล์รายการงานอยู่แล้ว ระบบจะดำเนินการอัปเดตงานที่มีอยู่"

    # แสดงผลสถิติจำนวนงาน
    total_tasks=$(grep -c "^- \[" "$TASKS_FILE" 2>/dev/null || echo "0")
    completed_tasks=$(grep -c "^- \[x\]" "$TASKS_FILE" 2>/dev/null || echo "0")
    echo "  งานทั้งหมด：$total_tasks งาน"
    echo "  เสร็จสิ้นแล้ว：$completed_tasks งาน"
else
    echo ""
    echo "📝 กำลังสร้างรายการงานเขียน (Task Checklist) ฉบับใหม่"
fi

echo ""
echo "พาธไฟล์รายการงาน：$TASKS_FILE"
echo ""
echo "ระบบพร้อมแล้ว สามารถเริ่มต้นย่อยสลายงานเขียนได้"
echo ""
echo "การย่อยสลายงานเขียนจะครอบคลุมถึง："
echo "  - งานเขียนในแต่ละบท (อิงตามแผนงาน)"
echo "  - การปรับปรุงและพัฒนาแฟ้มประวัติตัวละคร"
echo "  - การเพิ่มเติมข้อมูลเอกสารการตั้งค่าโลก (เวิลด์เซ็ตติง)"
echo "  - จุดตรวจสอบตรวจสอบคุณภาพเนื้อหา (Quality Gates)"
echo "  - งานตรวจสอบความถูกต้องและการปรับปรุงแก้ไข"
