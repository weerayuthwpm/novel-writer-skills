#!/bin/bash

# สคริปต์จัดการรัฐธรรมนูญแห่งการสร้างสรรค์นิยาย
# สำหรับใช้ร่วมกับคำสั่ง /constitution

set -e

# โหลดฟังก์ชันสากล (Common Functions)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# รับอาร์กิวเมนต์คำสั่ง (ค่าเริ่มต้นคือ check)
COMMAND="${1:-check}"

# รับไดเรกทอรีรากของโปรเจกต์ (Project Root)
PROJECT_ROOT=$(get_project_root)
cd "$PROJECT_ROOT"

# กำหนดพาธไฟล์รัฐธรรมนูญ (Constitution File Path)
CONSTITUTION_FILE=".specify/memory/constitution.md"

case "$COMMAND" in
    check)
        # ตรวจสอบว่ามีไฟล์รัฐธรรมนูญอยู่แล้วหรือไม่
        if [ -f "$CONSTITUTION_FILE" ]; then
            echo "✅ พบไฟล์รัฐธรรมนูญเรียบร้อยแล้วที่：$CONSTITUTION_FILE"
            # ดึงข้อมูลเวอร์ชัน
            VERSION=$(grep -E "^- เวอร์ชั่น：" "$CONSTITUTION_FILE" 2>/dev/null | cut -d'：' -f2 | tr -d ' ' || echo "ไม่ระบุ")
            UPDATED=$(grep -E "^- การแก้ไขครั้งสุดท้าย：" "$CONSTITUTION_FILE" 2>/dev/null | cut -d'：' -f2 | tr -d ' ' || echo "ไม่ระบุ")
            echo "  เวอร์ชัน：$VERSION"
            echo "  แก้ไขล่าสุด：$UPDATED"
            exit 0
        else
            echo "❌ ยังไม่ได้สร้างไฟล์รัฐธรรมนูญ"
            echo "  ข้อเสนอแนะ：กรุณารันคำสั่ง /constitution เพื่อสร้างรัฐธรรมนูญแห่งการสร้างสรรค์"
            exit 1
        fi
        ;;

    init)
        # เริ่มต้นสร้างไฟล์รัฐธรรมนูญ (Initialization)
        mkdir -p "$(dirname "$CONSTITUTION_FILE")"

        if [ -f "$CONSTITUTION_FILE" ]; then
            echo "พบไฟล์รัฐธรรมนูญอยู่แล้ว เตรียมดำเนินการอัปเดต"
        else
            echo "เตรียมดำเนินการสร้างไฟล์รัฐธรรมนูญฉบับใหม่"
        fi
        ;;

    validate)
        # ตรวจสอบความถูกต้องของรูปแบบไฟล์รัฐธรรมนูญ
        if [ ! -f "$CONSTITUTION_FILE" ]; then
            echo "ข้อผิดพลาด：ไม่พบไฟล์รัฐธรรมนูญ"
            exit 1
        fi

        echo "กำลังตรวจสอบความถูกต้องของไฟล์รัฐธรรมนูญ..."

        # ตรวจสอบหัวข้อที่จำเป็นต้องมี (Required Sections)
        REQUIRED_SECTIONS=("ค่านิยมหลัก" "มาตรฐานคุณภาพ" "สไตล์การสร้างสรรค์" "ข้อกำหนดเนื้อหา" "ข้อตกลงร่วมกับผู้อ่าน")
        MISSING_SECTIONS=()

        for section in "${REQUIRED_SECTIONS[@]}"; do
            if ! grep -q "## .* $section" "$CONSTITUTION_FILE"; then
                MISSING_SECTIONS+=("$section")
            fi
        done

        if [ ${#MISSING_SECTIONS[@]} -gt 0 ]; then
            echo "⚠️ ขาดหัวข้อหลักดังต่อไปนี้："
            for section in "${MISSING_SECTIONS[@]}"; do
                echo "  - $section"
            done
        else
            echo "✅ มีหัวข้อหลักที่จำเป็นครบถ้วน"
        fi

        # ตรวจสอบข้อมูลเวอร์ชัน
        if grep -q "^- 版本：" "$CONSTITUTION_FILE"; then
            echo "✅ ข้อมูลเวอร์ชันครบถ้วน"
        else
            echo "⚠️ ขาดข้อมูลเวอร์ชัน"
        fi
        ;;

    export)
        # ส่งออกสรุปสาระสำคัญของรัฐธรรมนูญ
        if [ ! -f "$CONSTITUTION_FILE" ]; then
            echo "ข้อผิดพลาด：ไม่พบไฟล์รัฐธรรมนูญ"
            exit 1
        fi

        echo "# สรุปสาระสำคัญของรัฐธรรมนูญแห่งการสร้างสรรค์"
        echo ""

        # ดึงข้อมูลหลักการสำคัญ
        echo "## หลักการสำคัญ"
        grep -A 1 "^### โดยหลักการแล้ว" "$CONSTITUTION_FILE" | grep "^**คำแถลง**" | cut -d'：' -f2- || echo "（ไม่พบการประกาศหลักการ）"

        echo ""
        echo "## เกณฑ์มาตรฐานคุณภาพขั้นต่ำ"
        grep -A 1 "^### มาตรฐาน" "$CONSTITUTION_FILE" | grep "^**จำเป็นต้อง**" | cut -d'：' -f2- || echo "（ไม่พบมาตรฐานคุณภาพ）"

        echo ""
        echo "ตรวจสอบรายละเอียดเพิ่มเติมได้ที่：$CONSTITUTION_FILE"
        ;;

    *)
        echo "คำสั่งไม่ถูกต้อง：$COMMAND"
        echo "คำสั่งที่รองรับได้แก่：check, init, validate, export"
        exit 1
        ;;
esac
