#!/bin/bash

# สคริปต์สนับสนุนการแจกแจงรายละเอียดและข้อสรุปของโครงเรื่อง
# สำหรับใช้ร่วมกับคำสั่ง /clarify ทำหน้าที่สแกนและส่งคืนพาธของเรื่องปัจจุบัน

set -e

# โหลดฟังก์ชันสากล (Common Functions)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# กำหนดค่าเริ่มต้นสำหรับการรับอาร์กิวเมนต์
JSON_MODE=false
PATHS_ONLY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --json)
            JSON_MODE=true
            shift
            ;;
        --paths-only)
            PATHS_ONLY=true
            shift
            ;;
        *)
            shift
            ;;
    esac
done

# รับไดเรกทอรีรากของโปรเจกต์ (Project Root)
PROJECT_ROOT=$(get_project_root)
cd "$PROJECT_ROOT"

# ค้นหาไดเรกทอรีเก็บเรื่องราว (Stories Directory)
STORIES_DIR="stories"
if [ ! -d "$STORIES_DIR" ]; then
    if [ "$JSON_MODE" = true ]; then
        echo '{"error": "No stories directory found"}'
    else
        echo "ข้อผิดพลาด: ไม่พบไดเรกทอรี stories กรุณารันคำสั่ง /story เพื่อสร้างโครงเรื่องก่อน"
    fi
    exit 1
fi

# ดึงไดเรกทอรีของเนื้อเรื่องล่าสุด (ปัจจุบันสมมติว่ามีเรื่องเดียว และสามารถพัฒนาต่อยอดได้)
STORY_DIR=$(find "$STORIES_DIR" -maxdepth 1 -type d ! -name "stories" | sort -r | head -n 1)

if [ -z "$STORY_DIR" ]; then
    if [ "$JSON_MODE" = true ]; then
        echo '{"error": "No story found"}'
    else
        echo "ข้อผิดพลาด: ไม่พบเนื้อเรื่อง กรุณารันคำสั่ง /story เพื่อสร้างโครงเรื่องก่อน"
    fi
    exit 1
fi

# แยกชื่อเรื่องออกมาจากชื่อไดเรกทอรี
STORY_NAME=$(basename "$STORY_DIR")

# ค้นหาไฟล์เนื้อเรื่อง (ฟอร์แมตใหม่ใช้ specification.md)
STORY_FILE="$STORY_DIR/specification.md"
if [ ! -f "$STORY_FILE" ]; then
    if [ "$JSON_MODE" = true ]; then
        echo '{"error": "Story file not found (specification.md required)"}'
    else
        echo "ข้อผิดพลาด: ไม่พบไฟล์เนื้อเรื่อง specification.md"
    fi
    exit 1
fi

# ตรวจสอบว่าเคยมีการบันทึกการแจกแจงรายละเอียด (Clarification) ไว้แล้วหรือไม่
CLARIFICATION_EXISTS=false
if grep -q "## 澄清记录" "$STORY_FILE" 2>/dev/null; then
    CLARIFICATION_EXISTS=true
fi

# นับจำนวนครั้งของเซสชันการแจกแจงรายละเอียดที่มีอยู่
CLARIFICATION_COUNT=0
if [ "$CLARIFICATION_EXISTS" = true ]; then
    CLARIFICATION_COUNT=$(grep -c "### 澄清会话" "$STORY_FILE" 2>/dev/null || echo "0")
fi

# ส่งออกข้อมูลในรูปแบบ JSON หากมีการร้องขอ
if [ "$JSON_MODE" = true ]; then
    if [ "$PATHS_ONLY" = true ]; then
        # เอาต์พุตแบบย่อสำหรับใช้เป็นเทมเพลตคำสั่ง (Command Template)
        cat <<EOF
{
    "STORY_PATH": "$STORY_FILE",
    "STORY_NAME": "$STORY_NAME",
    "STORY_DIR": "$STORY_DIR"
}
EOF
    else
        # เอาต์พุตแบบเต็มรูปแบบสำหรับการวิเคราะห์ข้อมูล
        cat <<EOF
{
    "STORY_PATH": "$STORY_FILE",
    "STORY_NAME": "$STORY_NAME",
    "STORY_DIR": "$STORY_DIR",
    "CLARIFICATION_EXISTS": $CLARIFICATION_EXISTS,
    "CLARIFICATION_COUNT": $CLARIFICATION_COUNT,
    "PROJECT_ROOT": "$PROJECT_ROOT"
}
EOF
    fi
else
    # การแสดงรายงานแบบข้อความปกติ
    echo "พบเนื้อเรื่อง: $STORY_NAME"
    echo "พาธไฟล์: $STORY_FILE"
    if [ "$CLARIFICATION_EXISTS" = true ]; then
        echo "เซสชันการแจกแจงรายละเอียดที่มีอยู่: $CLARIFICATION_COUNT ครั้ง"
    else
        echo "ยังไม่เคยดำเนินการแจกแจงรายละเอียดและข้อสรุป"
    fi
fi
