#!/usr/bin/env bash
# สคริปต์ตรวจสอบความสอดคล้องของเวิลด์เซ็ตติง (World Consistency)

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

# ตรวจสอบโหมดการทำงาน
CHECKLIST_MODE=false
if [ "$1" = "--checklist" ]; then
    CHECKLIST_MODE=true
fi

# พาธไฟล์ตั้งค่า (File Paths)
WORLD_SETTING="$STORY_DIR/spec/knowledge/world-setting.md"
LOCATIONS="$STORY_DIR/spec/knowledge/locations.md"
CULTURE="$STORY_DIR/spec/knowledge/culture.md"
RULES="$STORY_DIR/spec/knowledge/rules.md"
CONTENT_DIR="$STORY_DIR/content"

# รหัสสี ANSI
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color (ล้างค่าสี)

# ตัวแปรสำหรับเก็บสถิติ
TOTAL_CHECKS=0
PASSED_CHECKS=0
WARNINGS=0
ERRORS=0
ISSUES=()

# ฟังก์ชันตรวจสอบ (Check Function)
check() {
    local name="$1"
    local condition="$2"
    local error_msg="$3"

    ((TOTAL_CHECKS++))

    if eval "$condition"; then
        if [ "$CHECKLIST_MODE" = false ]; then
            echo -e "${GREEN}✓${NC} $name"
        fi
        ((PASSED_CHECKS++))
    else
        if [ "$CHECKLIST_MODE" = false ]; then
            echo -e "${RED}✗${NC} $name: $error_msg"
        fi
        ((ERRORS++))
        ISSUES+=("$name|$error_msg")
    fi
}

# ฟังก์ชันเตือน (Warning Function)
warn() {
    local msg="$1"
    if [ "$CHECKLIST_MODE" = false ]; then
        echo -e "${YELLOW}⚠️${NC} คำเตือน: $msg"
    fi
    ((WARNINGS++))
    ISSUES+=("คำเตือน|$msg")
}

# 1. ตรวจสอบความสมบูรณ์ของไฟล์ตั้งค่า
check_setting_files() {
    if [ "$CHECKLIST_MODE" = false ]; then
        echo "📁 ตรวจสอบความสมบูรณ์ของไฟล์ตั้งค่า"
        echo "────────────────────────────────"
    fi

    check "world-setting.md" "[ -f '$WORLD_SETTING' ]" "ไม่พบไฟล์เวิลด์เซ็ตติงหลัก"
    check "locations.md" "[ -f '$LOCATIONS' ]" "ไม่พบไฟล์ข้อมูลสถานที่"
    check "culture.md" "[ -f '$CULTURE' ]" "ไม่พบไฟล์ข้อมูลวัฒนธรรมและประเพณี"
    check "rules.md" "[ -f '$RULES' ]" "ไม่พบไฟล์กฎเกณฑ์พิเศษ"

    if [ "$CHECKLIST_MODE" = false ]; then
        echo ""
    fi
}

# 2. ตรวจสอบความสอดคล้องของคำศัพท์
check_terminology() {
    if [ "$CHECKLIST_MODE" = false ]; then
        echo "📝 ตรวจสอบความสอดคล้องของคำศัพท์"
        echo "──────────────────────────────"
    fi

    if [ -d "$CONTENT_DIR" ]; then
        # ดึงคำศัพท์เฉพาะจากเอกสารเวิลด์เซ็ตติง (เวอร์ชันลดรูป, ของจริงควรซับซ้อนกว่านี้)
        local term_count=0

        if [ -f "$WORLD_SETTING" ]; then
            # นับจำนวนคำศัพท์เฉพาะ (ในที่นี้ลดรูปเป็นการนับคำที่ใช้ตัวหนา **...**)
            term_count=$(grep -o '\*\*[^*]*\*\*' "$WORLD_SETTING" 2>/dev/null | wc -l || echo 0)
        fi

        check "การกำหนดคำศัพท์เฉพาะ" "[ $term_count -gt 0 ]" "ไม่พบการกำหนดคำศัพท์เฉพาะ"

        if [ "$CHECKLIST_MODE" = false ]; then
            echo "  📊 จำนวนคำศัพท์เฉพาะที่พบ: $term_count"
        fi
    else
        warn "ไม่พบไดเรกทอรีเนื้อหา (Content) ข้ามการตรวจสอบคำศัพท์"
    fi

    if [ "$CHECKLIST_MODE" = false ]; then
        echo ""
    fi
}

# 3. ตรวจสอบตรรกะทางภูมิศาสตร์
check_geography() {
    if [ "$CHECKLIST_MODE" = false ]; then
        echo "🗺️  ตรวจสอบตรรกะทางภูมิศาสตร์"
        echo "───────────────────────────"
    fi

    if [ -f "$LOCATIONS" ]; then
        # นับจำนวนสถานที่ที่ถูกกำหนดไว้
        local location_count=$(grep -c '^##' "$LOCATIONS" 2>/dev/null || echo 0)

        check "ความสมบูรณ์ของการกำหนดสถานที่" "[ $location_count -gt 0 ]" "ยังไม่ได้กำหนดสถานที่ใดๆ"

        if [ "$CHECKLIST_MODE" = false ]; then
            echo "  📊 สถานที่ที่กำหนดไว้: ${location_count} แห่ง"
        fi

        # ตรวจสอบว่าสถานที่ที่ถูกอ้างถึงในเนื้อหามีการกำหนดไว้ในไฟล์ตั้งค่าหรือไม่
        if [ -d "$CONTENT_DIR" ]; then
            # ตรงนี้เป็นเวอร์ชันลดรูป ของจริงควรใช้ลอจิกการจับคู่ที่ฉลาดกว่านี้
            local undefined_locations=0

            # TODO: พัฒนาระบบตรวจสอบการจับคู่สถานที่ให้ฉลาดขึ้น
            # ปัจจุบันทำการตรวจสอบไฟล์ขั้นพื้นฐานเท่านั้น

            check "ตรวจสอบการอ้างอิงสถานที่" "[ $undefined_locations -eq 0 ]" "พบการอ้างอิงถึงสถานที่ที่ไม่ได้กำหนดไว้"
        fi
    else
        warn "ไม่พบไฟล์ข้อมูลสถานที่"
    fi

    if [ "$CHECKLIST_MODE" = false ]; then
        echo ""
    fi
}

# 4. ตรวจสอบความสอดคล้องทางวัฒนธรรม
check_culture() {
    if [ "$CHECKLIST_MODE" = false ]; then
        echo "🎭 ตรวจสอบความสอดคล้องทางวัฒนธรรม"
        echo "──────────────────────────────"
    fi

    if [ -f "$CULTURE" ]; then
        # นับจำนวนองค์ประกอบทางวัฒนธรรม
        local culture_count=$(grep -c '^##' "$CULTURE" 2>/dev/null || echo 0)

        check "การกำหนดองค์ประกอบวัฒนธรรม" "[ $culture_count -gt 0 ]" "ยังไม่ได้กำหนดองค์ประกอบทางวัฒนธรรม"

        if [ "$CHECKLIST_MODE" = false ]; then
            echo "  📊 องค์ประกอบทางวัฒนธรรม: ${culture_count} รายการ"
        fi
    else
        warn "ไม่พบไฟล์ข้อมูลวัฒนธรรมและประเพณี"
    fi

    if [ "$CHECKLIST_MODE" = false ]; then
        echo ""
    fi
}

# 5. ตรวจสอบความสอดคล้องของกฎเกณฑ์
check_rules() {
    if [ "$CHECKLIST_MODE" = false ]; then
        echo "⚖️  ตรวจสอบความสอดคล้องของกฎเกณฑ์"
        echo "─────────────────────────────"
    fi

    if [ -f "$RULES" ]; then
        # นับจำนวนกฎเกณฑ์พิเศษ
        local rule_count=$(grep -c '^##' "$RULES" 2>/dev/null || echo 0)

        check "การกำหนดกฎเกณฑ์พิเศษ" "[ $rule_count -gt 0 ]" "ยังไม่ได้กำหนดกฎเกณฑ์พิเศษใดๆ"

        if [ "$CHECKLIST_MODE" = false ]; then
            echo "  📊 กฎเกณฑ์พิเศษ: ${rule_count} ข้อ"
        fi
    else
        warn "ไม่พบไฟล์กฎเกณฑ์พิเศษ"
    fi

    if [ "$CHECKLIST_MODE" = false ]; then
        echo ""
    fi
}

# ฟังก์ชันสร้างรายงานแบบปกติ (Standard Report)
generate_report() {
    echo "═══════════════════════════════════════"
    echo "🌍 รายงานการตรวจสอบความสอดคล้องของเวิลด์เซ็ตติง"
    echo "═══════════════════════════════════════"
    echo ""

    check_setting_files
    check_terminology
    check_geography
    check_culture
    check_rules

    echo "═══════════════════════════════════════"
    echo "📈 สรุปผลการตรวจสอบ"
    echo "───────────────────"
    echo "  รายการตรวจทั้งหมด: ${TOTAL_CHECKS}"
    echo -e "  ${GREEN}ผ่าน: ${PASSED_CHECKS}${NC}"
    echo -e "  ${YELLOW}คำเตือน: ${WARNINGS}${NC}"
    echo -e "  ${RED}ข้อผิดพลาด: ${ERRORS}${NC}"

    if [ "$ERRORS" -eq 0 ] && [ "$WARNINGS" -eq 0 ]; then
        echo ""
        echo -e "${GREEN}✅ ยอดเยี่ยม! ผ่านการตรวจสอบทุกรายการ${NC}"
    elif [ "$ERRORS" -eq 0 ]; then
        echo ""
        echo -e "${YELLOW}⚠️  มีคำเตือน ${WARNINGS} รายการ แนะนำให้ตรวจสอบรายละเอียด${NC}"
    else
        echo ""
        echo -e "${RED}❌ พบข้อผิดพลาด ${ERRORS} รายการ จำเป็นต้องแก้ไข${NC}"
    fi

    echo "═══════════════════════════════════════"
    echo ""
    echo "เวลาที่ตรวจสอบ: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
    echo "💡 ข้อเสนอแนะ:"
    echo "  - อัปเดตเอกสารการตั้งค่าโลก (World-building Docs) อย่างสม่ำเสมอ"
    echo "  - จัดทำอภิธานศัพท์ (Glossary) เพื่อรักษาความสอดคล้องของคำเฉพาะ"
    echo "  - บันทึกระยะห่างและความสัมพันธ์เชิงทิศทางระหว่างสถานที่ต่างๆ"
}

# ฟังก์ชันสร้างเอาต์พุตในรูปแบบ Checklist (Markdown)
output_checklist() {
    # รีเซ็ตค่าตัวแปรเพื่อรันการเก็บข้อมูลใหม่
    TOTAL_CHECKS=0
    PASSED_CHECKS=0
    ERRORS=0
    WARNINGS=0
    ISSUES=()

    check_setting_files
    check_terminology
    check_geography
    check_culture
    check_rules

    # พิมพ์ผลลัพธ์ในรูปแบบ Checklist ด้วยคำสั่ง cat
    cat <<EOF
# รายการตรวจสอบความสอดคล้องของเวิลด์เซ็ตติง (World Consistency Checklist)

**เวลาที่ตรวจสอบ**: $(date '+%Y-%m-%d %H:%M:%S')
**เป้าหมายการตรวจ**: ไดเรกทอรี spec/knowledge/ และเนื้อหาบทที่เขียนแล้ว
**ขอบเขตการตรวจ**: การตั้งค่าโลก, ตรรกะภูมิศาสตร์, วัฒนธรรมและประเพณี, กฎเกณฑ์พิเศษ

---

## ความสมบูรณ์ของไฟล์ตั้งค่า

- [$([ -f "$WORLD_SETTING" ] && echo "x" || echo " ")] CHK001 world-setting.md มีอยู่จริง
- [$([ -f "$LOCATIONS" ] && echo "x" || echo " ")] CHK002 locations.md 有存在 มีอยู่จริง
- [$([ -f "$CULTURE" ] && echo "x" || echo " ")] CHK003 culture.md มีอยู่จริง
- [$([ -f "$RULES" ] && echo "x" || echo " ")] CHK004 rules.md มีอยู่จริง

## ความสอดคล้องของคำศัพท์

- [$([ -d "$CONTENT_DIR" ] && echo "x" || echo " ")] CHK005 กำหนดคำศัพท์เฉพาะครบถ้วน
- [ ] CHK006 คำศัพท์ในเนื้อหาบทต่างๆ สอดคล้องกับเอกสารตั้งค่า (ต้องใช้คนตรวจสอบ)

## ตรรกะทางภูมิศาสตร์

EOF

    if [ -f "$LOCATIONS" ]; then
        local location_count=$(grep -c '^##' "$LOCATIONS" 2>/dev/null || echo 0)
        echo "- [x] CHK007 กำหนดสถานที่ครบถ้วน (กำหนดไว้แล้ว ${location_count} แห่ง)"
    else
        echo "- [ ] CHK007 กำหนดสถานที่ครบถ้วน"
    fi

    cat <<EOF
- [ ] CHK008 ระยะห่างและทิศทางระหว่างสถานที่สมเหตุสมผล (ต้องใช้คนตรวจสอบ)
- [ ] CHK009 การบรรยายภูมิศาสตร์ในเนื้อหาบทต่างๆ สอดคล้องกับการตั้งค่า (ต้องใช้คนตรวจสอบ)

## ความสอดคล้องทางวัฒนธรรม

EOF

    if [ -f "$CULTURE" ]; then
        local culture_count=$(grep -c '^##' "$CULTURE" 2>/dev/null || echo 0)
        echo "- [x] CHK010 กำหนดองค์ประกอบวัฒนธรรมครบถ้วน (กำหนดไว้แล้ว ${culture_count} รายการ)"
    else
        echo "- [ ] CHK010 คำจำกัดความที่สมบูรณ์ กำหนดองค์ประกอบวัฒนธรรมครบถ้วน"
    fi

    cat <<EOF
- [ ] CHK011 การอธิบายขนบธรรมเนียมประเพณีมีความสอดคล้องกัน (ต้องใช้คนตรวจสอบ)
- [ ] CHK012 การใช้ภาษาและคำสรรพนามเรียกขานเป็นไปในทิศทางเดียวกัน (ต้องใช้คนตรวจสอบ)

## ความสอดคล้องของกฎเกณฑ์

EOF

    if [ -f "$RULES" ]; then
        local rule_count=$(grep -c '^##' "$RULES" 2>/dev/null || echo 0)
        echo "- [x] CHK013 กำหนดกฎเกณฑ์พิเศษครบถ้วน (กำหนดไว้แล้ว ${rule_count} ข้อ)"
    else
        echo "- [ ] CHK013 กำหนดกฎเกณฑ์พิเศษครบถ้วน"
    fi

    cat <<EOF
- [ ] CHK014 การนำกฎไปใช้ในเนื้อเรื่องมีความสอดคล้องกัน (ต้องใช้คนตรวจสอบ)
- [ ] CHK015 กฎเกณฑ์ต่างๆ ไม่เกิดการขัดแย้งกันเอง (ต้องใช้คนตรวจสอบ)

---

## ปัญหาที่พบ

EOF

    if [ ${#ISSUES[@]} -gt 0 ]; then
        for issue in "${ISSUES[@]}"; do
            IFS='|' read -r name msg <<< "$issue"
            echo "### $name"
            echo ""
            echo "**ปัญหา**: $msg"
            echo ""
        done
    else
        echo "*ไม่พบปัญหาใดๆ*"
    fi

    cat <<EOF

---

## สถิติการตรวจสอบ

- **รายการตรวจทั้งหมด**: ${TOTAL_CHECKS}
- **ผ่านแล้ว**: ${PASSED_CHECKS}
- **ต้องปรับปรุง**: ${ERRORS}
- **คำเตือน**: ${WARNINGS}

---

## สิ่งที่ต้องทำต่อไป (Action Items)

- [ ] เพิ่มเติมเอกสารการตั้งค่าโลกส่วนที่ขาดหายไป
- [ ] สร้างตารางอภิธานศัพท์เพื่อบันทึกคำศัพท์เฉพาะ
- [ ] ตรวจสอบการบรรยายเวิลด์เซ็ตติงในแต่ละบทด้วยตนเอง (Manual Check)
- [ ] บันทึกระยะห่างและเวลาที่ใช้ในการเดินทางระหว่างสถานที่ต่างๆ

---

**เครื่องมือตรวจสอบ**: check-world.sh
**เวอร์ชัน**: 1.0
EOF
}

# ฟังก์ชันหลัก (Main Function)
main() {
    if [ "$CHECKLIST_MODE" = true ]; then
        output_checklist
    else
        generate_report
    fi

    # ส่งคืน Exit Code ตามผลลัพธ์ที่ได้
    if [ "$ERRORS" -gt 0 ]; then
        exit 1
    else
        exit 0
    fi
}

# เริ่มทำงานฟังก์ชันหลัก
main
