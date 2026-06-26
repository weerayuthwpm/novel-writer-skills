#!/bin/bash

# สคริปต์วางแผนงานสร้างสรรค์นิยาย
# สำหรับใช้ร่วมกับคำสั่ง /plan

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

# ตรวจสอบและระบุชื่อเรื่องนิยาย
if [ -z "$STORY_NAME" ]; then
    STORY_NAME=$(get_active_story)
fi

STORY_DIR="stories/$STORY_NAME"
SPEC_FILE="$STORY_DIR/specification.md"
CLARIFY_FILE="$STORY_DIR/clarification.md"
PLAN_FILE="$STORY_DIR/creative-plan.md"

echo "การจัดทำแผนงานสร้างสรรค์"
echo "======================"
echo "เรื่อง：$STORY_NAME"
echo ""

# ตรวจสอบเอกสารก่อนหน้า (Prerequisites Check)
missing=()

if [ ! -f ".specify/memory/constitution.md" ]; then
    missing+=("ไฟล์รัฐธรรมนูญ (Constitution)")
fi

if [ ! -f "$SPEC_FILE" ]; then
    missing+=("ไฟล์ข้อกำหนดเฉพาะ (Specification)")
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
        echo "  2. /specify - กำหนดข้อกำหนดเฉพาะของเรื่อง"
    fi
    exit 1
fi

# ตรวจสอบประเด็นที่ยังต้องการความชัดเจนในเนื้อเรื่อง
if [ -f "$SPEC_FILE" ]; then
    unclear_count=$(grep -o '\[ต้องการคำชี้แจงเพิ่มเติม\]' "$SPEC_FILE" | wc -l | tr -d ' ')

    if [ "$unclear_count" -gt 0 ]; then
        echo "⚠️ พบจุดที่ยังไม่ชัดเจนในเอกสารข้อกำหนดจำนวน $unclear_count ตำแหน่ง"
        echo "แนะนำให้รันคำสั่ง /clarify เพื่อตัดสินใจแจกแจงรายละเอียดในประเด็นสำคัญก่อน"
        echo ""
    fi
fi

# ตรวจสอบประวัติบันทึกการแจกแจงรายละเอียดและข้อสรุป
if [ -f "$CLARIFY_FILE" ]; then
    echo "✅ ตรวจสอบประวัติการแจกแจงข้อสรุปแล้ว ระบบจะสร้างแผนงานโดยอิงจากข้อสรุปดังกล่าว"
else
    echo "📝 ไม่พบประวัติบันทึกการแจกแจงข้อสรุป ระบบจะสร้างแผนงานโดยอิงจากข้อกำหนดเฉพาะเวอร์ชันดั้งเดิม"
fi

# ตรวจสอบการมีอยู่ของไฟล์แผนงานสร้างสรรค์
if [ -f "$PLAN_FILE" ]; then
    echo ""
    echo "📋 พบไฟล์แผนงานสร้างสรรค์อยู่แล้ว ระบบจะดำเนินการอัปเดตแผนงานที่มีอยู่"

    # ดึงข้อมูลเวอร์ชันปัจจุบัน
    if grep -q "Version：" "$PLAN_FILE"; then
        version=$(grep "Version：" "$PLAN_FILE" | head -1 | sed 's/.*Version：//')
        echo "  เวอร์ชันปัจจุบัน：$version"
    fi
else
    echo ""
    echo "📝 กำลังสร้างแผนงานสร้างสรรค์นิยายฉบับใหม่"
fi

echo ""
echo "พาธไฟล์แผนงานสร้างสรรค์：$PLAN_FILE"
echo ""
echo "ระบบพร้อมแล้ว สามารถเริ่มต้นจัดทำแผนงานสร้างสรรค์นิยายได้เลย"
