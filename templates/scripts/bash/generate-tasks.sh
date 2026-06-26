#!/usr/bin/env bash
# สคริปต์สร้างรายการงานเขียน

set -e

# โหลดฟังก์ชันสากล (Common Functions)
SCRIPT_DIR=$(dirname "$0")
source "$SCRIPT_DIR/common.sh"

# รับไดเรกทอรีของโปรเจกต์เนื้อเรื่องปัจจุบัน
STORY_DIR=$(get_current_story)

if [ -z "$STORY_DIR" ]; then
    echo "ข้อผิดพลาด: ไม่พบโปรเจกต์เนื้อเรื่อง" >&2
    exit 1
fi

# ตรวจสอบเงื่อนไขก่อนหน้า (Prerequisites Check)
if [ ! -f "$STORY_DIR/specification.md" ]; then
    echo "ข้อผิดพลาด: ไม่พบข้อกำหนดเฉพาะของเรื่อง (Specification) กรุณาใช้คำสั่ง /specify ก่อน" >&2
    exit 1
fi

if [ ! -f "$STORY_DIR/outline.md" ]; then
    echo "ข้อผิดพลาด: ไม่พบการวางแผนบทเรียน/โครงเรื่อง (Outline) กรุณาใช้คำสั่ง /outline ก่อน" >&2
    exit 1
fi

# รับวันที่และเวลาปัจจุบัน
CURRENT_DATE=$(date '+%Y-%m-%d')
CURRENT_DATETIME=$(date '+%Y-%m-%d %H:%M:%S')

# สร้างไฟล์รายการงาน (Tasks File) พร้อมใส่ข้อมูลพื้นฐานเริ่มต้น
TASKS_FILE="$STORY_DIR/tasks.md"
cat > "$TASKS_FILE" << EOF
# รายการงานเขียน (Writing Task Checklist)

## ภาพรวมงาน (Overview)
- **วันที่สร้าง**：${CURRENT_DATE}
- **อัปเดตล่าสุด**：${CURRENT_DATE}
- **สถานะงาน**：รอดำเนินการสร้าง (Pending)

---
EOF

# สร้างไฟล์ติดตามความคืบหน้า (Progress Tracking File)
PROGRESS_FILE="$STORY_DIR/progress.json"
if [ ! -f "$PROGRESS_FILE" ]; then
    cat > "$PROGRESS_FILE" << EOF
{
  "created_at": "${CURRENT_DATETIME}",
  "updated_at": "${CURRENT_DATETIME}",
  "total_chapters": 0,
  "completed": 0,
  "in_progress": 0,
  "word_count": 0
}
EOF
fi

# แสดงผลลัพธ์การทำงานออกทางหน้าจอ
echo "TASKS_FILE: $TASKS_FILE"
echo "PROGRESS_FILE: $PROGRESS_FILE"
echo "CURRENT_DATE: $CURRENT_DATE"
echo "STATUS: ready"
