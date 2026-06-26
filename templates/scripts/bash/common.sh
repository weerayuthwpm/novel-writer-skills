#!/usr/bin/env bash
# คลังฟังก์ชันสากล (Common Function Library)

# ฟังก์ชันรับไดเรกทอรีรากของโปรเจกต์ (Project Root)
get_project_root() {
    if [ -f ".specify/config.json" ]; then
        pwd
    else
        # ค้นหาขึ้นไปด้านบนเรื่อยๆ เพื่อหาไดเรกทอรีที่บรรจุโฟลเดอร์ .specify
        current=$(pwd)
        while [ "$current" != "/" ]; do
            if [ -f "$current/.specify/config.json" ]; then
                echo "$current"
                return 0
            fi
            current=$(dirname "$current")
        done
        echo "ข้อผิดพลาด: ไม่พบไดเรกทอรีรากของโปรเจกต์นิยาย" >&2
        exit 1
    fi
}

# ฟังก์ชันรับไดเรกทอรีของโปรเจกต์เนื้อเรื่องปัจจุบัน (Current Story Directory)
get_current_story() {
    PROJECT_ROOT=$(get_project_root)
    STORIES_DIR="$PROJECT_ROOT/stories"

    # ค้นหาไดเรกทอรีเนื้อเรื่องที่อัปเดตล่าสุด
    if [ -d "$STORIES_DIR" ]; then
        latest=$(ls -t "$STORIES_DIR" 2>/dev/null | head -1)
        if [ -n "$latest" ]; then
            echo "$STORIES_DIR/$latest"
        fi
    fi
}

# ฟังก์ชันรับชื่อเรื่องปัจจุบันที่กำลังเปิดทำงาน (ส่งคืนเฉพาะชื่อ ไม่ส่งคืนพาธ)
get_active_story() {
    story_dir=$(get_current_story)
    if [ -n "$story_dir" ]; then
        basename "$story_dir"
    else
        # หากยังไม่มีการสร้างเนื้อเรื่อง ให้ส่งคืนชื่อเริ่มต้นตามวันที่ปัจจุบัน
        echo "story-$(date +%Y%m%d)"
    fi
}

# ฟังก์ชันสร้างไดเรกทอรีแบบรันหมายเลขลำดับ (Numbered Directory)
create_numbered_dir() {
    base_dir="$1"
    prefix="$2"

    mkdir -p "$base_dir"

    # ค้นหาหมายเลขลำดับที่สูงที่สุดที่มีอยู่ปัจจุบัน
    highest=0
    for dir in "$base_dir"/*; do
        [ -d "$dir" ] || continue
        dirname=$(basename "$dir")
        number=$(echo "$dirname" | grep -o '^[0-9]\+' || echo "0")
        number=$((10#$number))
        if [ "$number" -gt "$highest" ]; then
            highest=$number
        fi
    done

    # ส่งคืนหมายเลขลำดับถัดไป (ในรูปแบบเลข 3 หลัก เช่น 001, 002)
    next=$((highest + 1))
    printf "%03d" "$next"
}

# ฟังก์ชันส่งออกข้อมูล JSON (สำหรับใช้สื่อสารกับผู้ช่วย AI)
output_json() {
    echo "$1"
}

# ฟังก์ชันตรวจสอบและรับประกันว่าไฟล์ต้องมีอยู่จริง (หากไม่มีให้สร้างหรือคัดลอกมา)
ensure_file() {
    file="$1"
    template="$2"

    if [ ! -f "$file" ]; then
        if [ -f "$template" ]; then
            cp "$template" "$file"
        else
            touch "$file"
        fi
    fi
}

# ฟังก์ชันนับจำนวนคำภาษาจีนอย่างแม่นยำ
# ทำการคัดกรองเครื่องหมาย Markdown, ช่องว่าง และการเว้นบรรทัดออก เพื่อนับเฉพาะเนื้อหาจริงเท่านั้น
count_chinese_words() {
    local file="$1"

    if [ ! -f "$file" ]; then
        echo "0"
        return
    fi

    # ลบเครื่องหมายและรูปแบบสัญลักษณ์ของ Markdown ออก จากนั้นทำการนับตัวอักษรที่เหลือ
    # 1. ลบบล็อกโค้ด (Code Blocks ```)
    # 2. ลบเครื่องหมายหัวข้อหลัก/ย่อย (#)
    # 3. ลบเครื่องหมายเน้นข้อความตัวหนา (** และ __)
    # 4. ลบเครื่องหมายตัวเอียง (*)
    # 5. ลบเครื่องหมายขีดล่าง (_)
    # 6. ลบวงเล็บเหลี่ยมของลิงก์ ([ ])
    # 7. ลบ URL ในวงเล็บ (http...)
    # 8. ลบสัญลักษณ์บล็อกคำพูดโควต (>)
    # 9. ลบเครื่องหมายรายการสัญลักษณ์ (- *)
    # 10. ลบเครื่องหมายรายการแบบตัวเลข (1., 2.)
    # 11. ลบช่องว่าง เว้นบรรทัด และแท็บ (Whitespace) ทั้งหมด
    # 12. ลบเครื่องหมายวรรคตอน (Punctuation) ทั้งหมด
    # 13. แยกนับจำนวนตัวอักษรที่เหลือจริงทั้งหมด
    local word_count=$(cat "$file" | \
        sed '/^```/,/^```/d' | \
        sed 's/^#\+[[:space:]]*//' | \
        sed 's/\*\*//g' | \
        sed 's/__//g' | \
        sed 's/\*//g' | \
        sed 's/_//g' | \
        sed 's/\[//g' | \
        sed 's/\]//g' | \
        sed 's/(http[^)]*)//g' | \
        sed 's/^>[[:space:]]*//' | \
        sed 's/^[[:space:]]*[-*][[:space:]]*//' | \
        sed 's/^[[:space:]]*[0-9]\+\.[[:space:]]*//' | \
        tr -d '[:space:]' | \
        tr -d '[:punct:]' | \
        grep -o . | \
        wc -l | \
        tr -d ' ')

    echo "$word_count"
}

# ฟังก์ชันแสดงข้อมูลสถิติจำนวนคำที่เป็นมิตรต่อผู้ใช้งาน
# อาร์กิวเมนต์: พาธไฟล์, จำนวนคำขั้นต่ำ (ไม่บังคับ), จำนวนคำสูงสุด (ไม่บังคับ)
show_word_count_info() {
    local file="$1"
    local min_words="${2:-0}"
    local max_words="${3:-999999}"
    local actual_words=$(count_chinese_words "$file")

    echo "จำนวนคำ：$actual_words"

    if [ "$min_words" -gt 0 ]; then
        if [ "$actual_words" -lt "$min_words" ]; then
            echo "⚠️ จำนวนคำยังไม่ถึงเกณฑ์ขั้นต่ำที่กำหนด（ขั้นต่ำ: ${min_words} คำ）"
        elif [ "$actual_words" -gt "$max_words" ]; then
            echo "⚠️ จำนวนคำเกินกว่าขีดจำกัดสูงสุดที่กำหนด（สูงสุด: ${max_words} คำ）"
        else
            echo "✅ จำนวนคำถูกต้องตรงตามมาตรฐาน（${min_words}-${max_words} คำ）"
        fi
    fi
}
