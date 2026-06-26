#!/bin/bash

echo "🚀 กำลังเริ่มต้นระบบติดตามเนื้อเรื่อง (Tracking System)..."

# ตรวจสอบเงื่อนไขก่อนหน้า (Prerequisites Check)
story_exists=false
outline_exists=false

# ค้นหาไฟล์ specification.md (ข้อกำหนดเฉพาะ)
if ls stories/*/specification.md 1> /dev/null 2>&1; then
    story_exists=true
    story_file=$(ls stories/*/specification.md | head -1)
fi

# ค้นหาไฟล์ outline.md (โครงเรื่อง)
if ls stories/*/outline.md 1> /dev/null 2>&1; then
    outline_exists=true
    outline_file=$(ls stories/*/outline.md | head -1)
fi

if [ "$story_exists" = false ] || [ "$outline_exists" = false ]; then
    echo "❌ กรุณาดำเนินการตามคำสั่ง /specify และ /plan ให้เสร็จสิ้นก่อน"
    echo "   ไฟล์ที่ขาดหายไป: ${story_exists:+}${story_exists:-specification.md} ${outline_exists:+}${outline_exists:-outline.md}"
    exit 1
fi

# สร้างไดเรกทอรีสำหรับระบบติดตาม
mkdir -p spec/tracking

# รับชื่อเรื่องนิยาย
story_dir=$(dirname "$story_file")
story_name=$(basename "$story_dir")

echo "📖 กำลังตั้งค่าระบบติดตามสำหรับเรื่อง《${story_name}》..."

# 1. เริ่มต้นสร้างไฟล์ plot-tracker.json (ระบบติดตามโครงเรื่อง)
if [ ! -f "spec/tracking/plot-tracker.json" ]; then
    echo "📝 กำลังสร้าง plot-tracker.json..."
    cat > spec/tracking/plot-tracker.json <<EOF
{
  "novel": "${story_name}",
  "lastUpdated": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "currentState": {
    "chapter": 0,
    "volume": 1,
    "mainPlotStage": "ขั้นเตรียมการ",
    "location": "รอกำหนด",
    "timepoint": "ก่อนเริ่มเรื่อง"
  },
  "plotlines": {
    "main": {
      "name": "เส้นเรื่องหลัก",
      "description": "รอการดึงข้อมูลจากโครงเรื่อง",
      "status": "รอดำเนินการ",
      "currentNode": "จุดเริ่มต้น",
      "completedNodes": [],
      "upcomingNodes": [],
      "plannedClimax": {
        "chapter": null,
        "description": "รอการวางแผน"
      }
    },
    "subplots": []
  },
  "foreshadowing": [],
  "conflicts": {
    "active": [],
    "resolved": [],
    "upcoming": []
  },
  "checkpoints": {
    "volumeEnd": [],
    "majorEvents": []
  },
  "notes": {
    "plotHoles": [],
    "inconsistencies": [],
    "reminders": ["กรุณาอัปเดตข้อมูลการติดตามตามเนื้อเรื่องจริงที่เกิดขึ้น"]
  }
}
EOF
fi

# 2. เริ่มต้นสร้างไฟล์ timeline.json (ระบบจัดการลำดับเวลา)
if [ ! -f "spec/tracking/timeline.json" ]; then
    echo "⏰ กำลังสร้าง timeline.json..."
    cat > spec/tracking/timeline.json <<EOF
{
  "novel": "${story_name}",
  "lastUpdated": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "storyTimeUnit": "วัน",
  "realWorldReference": null,
  "timeline": [
    {
      "chapter": 0,
      "storyTime": "วันที่ 0",
      "description": "ก่อนเริ่มเรื่อง",
      "events": ["รอการเพิ่มข้อมูล"],
      "location": "รอกำหนด"
    }
  ],
  "parallelEvents": [],
  "timeSpan": {
    "start": "วันที่ 0",
    "current": "วันที่ 0",
    "elapsed": "0 วัน"
  }
}
EOF
fi

# 3. เริ่มต้นสร้างไฟล์ relationships.json (เครือข่ายความสัมพันธ์)
if [ ! -f "spec/tracking/relationships.json" ]; then
    echo "👥 กำลังสร้าง relationships.json..."
    cat > spec/tracking/relationships.json <<EOF
{
  "novel": "${story_name}",
  "lastUpdated": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "characters": {
    "ตัวละครเอก": {
      "name": "รอกำหนด",
      "relationships": {
        "allies": [],
        "enemies": [],
        "romantic": [],
        "neutral": []
      }
    }
  },
  "factions": {},
  "relationshipChanges": [],
  "currentTensions": []
}
EOF
fi

# 4. เริ่มต้นสร้างไฟล์ character-state.json (สถานะตัวละคร)
if [ ! -f "spec/tracking/character-state.json" ]; then
    echo "📍 กำลังสร้าง character-state.json..."
    cat > spec/tracking/character-state.json <<EOF
{
  "novel": "${story_name}",
  "lastUpdated": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "characters": {
    "ตัวละครเอก": {
      "name": "รอกำหนด",
      "status": "ปกติ/สุขภาพดี",
      "location": "รอกำหนด",
      "possessions": [],
      "skills": [],
      "lastSeen": {
        "chapter": 0,
        "description": "ยังไม่ปรากฏตัว"
      },
      "development": {
        "physical": 0,
        "mental": 0,
        "emotional": 0,
        "power": 0
      }
    }
  },
  "groupPositions": {},
  "importantItems": {}
}
EOF
fi

echo ""
echo "✅ เริ่มต้นระบบติดตามเนื้อเรื่องเสร็จสมบูรณ์!"
echo ""
echo "📊 ไฟล์การติดตามต่อไปนี้ถูกสร้างขึ้นเรียบร้อยแล้ว:"
echo "   • spec/tracking/plot-tracker.json - ติดตามพล็อตและโครงเรื่อง"
echo "   • spec/tracking/timeline.json - การจัดการเส้นเวลา (Timeline)"
echo "   • spec/tracking/relationships.json - เครือข่ายความสัมพันธ์ของตัวละคร"
echo "   • spec/tracking/character-state.json - สถานะและพัฒนาการของตัวละคร"
echo ""
echo "💡 ขั้นตอนถัดไป:"
echo "   1. ใช้คำสั่ง /write เพื่อเริ่มเขียนงาน (ระบบจะอัปเดตข้อมูลการติดตามให้โดยอัตโนมัติ)"
echo "   2. ใช้คำสั่ง /track เป็นประจำเพื่อเปิดดูรายงานสรุปในภาพรวม"
echo "   3. ใช้คำสั่งต่างๆ เช่น /plot-check เพื่อตรวจสอบความสอดคล้องของเนื้อหา"
echo ""
echo "📝 หมายเหตุ: ไฟล์ติดตามข้างต้นได้รับการใส่โครงสร้างพื้นฐานไว้แล้ว และจะอัปเดตโดยอัตโนมัติในระหว่างกระบวนการเขียนงาน"
