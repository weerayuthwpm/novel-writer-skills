#!/bin/bash

# สคริปต์กำหนดข้อกำหนดเฉพาะของเนื้อเรื่อง
# สำหรับใช้ร่วมกับคำสั่ง /specify

set -e

# โหลดฟังก์ชันสากล (Common Functions)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# กำหนดค่าเริ่มต้นสำหรับการรับอาร์กิวเมนต์
JSON_MODE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --json)
            JSON_MODE=true
            shift
            ;;
        *)
            STORY_NAME="$1"
            shift
            ;;
    esac
done

# รับไดเรกทอรีรากของโปรเจกต์ (Project Root)
PROJECT_ROOT=$(get_project_root)
cd "$PROJECT_ROOT"

# ตรวจสอบเพื่อระบุชื่อเรื่องและพาธของเนื้อเรื่อง
if [ -z "$STORY_NAME" ]; then
    # ค้นหาโปรเจกต์เนื้อเรื่องล่าสุด
    STORIES_DIR="stories"
    if [ -d "$STORIES_DIR" ] && [ "$(ls -A $STORIES_DIR 2>/dev/null)" ]; then
        STORY_DIR=$(find "$STORIES_DIR" -maxdepth 1 -type d ! -name "stories" | sort -r | head -n 1)
        if [ -n "$STORY_DIR" ]; then
            STORY_NAME=$(basename "$STORY_DIR")
        fi
    fi

    # หากยังไม่มีชื่อเรื่อง ให้สร้างชื่อเริ่มต้นตามวันที่ปัจจุบัน
    if [ -z "$STORY_NAME" ]; then
        STORY_NAME="story-$(date +%Y%m%d)"
    fi
fi

# ตั้งค่าพาธไดเรกทอรีและไฟล์ข้อกำหนดเฉพาะ (Specification Path)
STORY_DIR="stories/$STORY_NAME"
SPEC_FILE="$STORY_DIR/specification.md"

# สร้างไดเรกทอรีสำหรับเก็บเนื้อเรื่อง
mkdir -p "$STORY_DIR"

# ตรวจสอบสถานะการมีอยู่ของไฟล์
SPEC_EXISTS=false
STATUS="new"

if [ -f "$SPEC_FILE" ]; then
    SPEC_EXISTS=true
    STATUS="exists"
fi

# ส่งออกข้อมูลในรูปแบบ JSON หากเปิดโหมด --json
if [ "$JSON_MODE" = true ]; then
    cat <<EOF
{
    "STORY_NAME": "$STORY_NAME",
    "STORY_DIR": "$STORY_DIR",
    "SPEC_PATH": "$SPEC_FILE",
    "STATUS": "$STATUS",
    "PROJECT_ROOT": "$PROJECT_ROOT"
}
EOF
else
    # การแสดงรายงานแบบข้อความปกติออกทางหน้าจอ
    echo "เริ่มต้นข้อกำหนดเฉพาะของเนื้อเรื่อง (Story Specification)"
    echo "================================================="
    echo "ชื่อเรื่อง：$STORY_NAME"
    echo "พาธข้อกำหนดเฉพาะ：$SPEC_FILE"

    if [ "$SPEC_EXISTS" = true ]; then
        echo "สถานะ：พบไฟล์ข้อกำหนดเฉพาะแล้ว เตรียมดำเนินการอัปเดต"
    else
        echo "สถานะ：เตรียมดำเนินการสร้างข้อกำหนดเฉพาะฉบับใหม่"
    fi

    # ตรวจสอบการมีอยู่ของรัฐธรรมนูญนิยาย (Constitution)
    if [ -f ".specify/memory/constitution.md" ]; then
        echo ""
        echo "✅ ตรวจพบรัฐธรรมนูญแห่งการสร้างสรรค์ ข้อกำหนดเฉพาะนี้จะปฏิบัติตามหลักการของรัฐธรรมนูญ"
    fi
fi
