---
name: track-init
description: เริ่มต้นระบบติดตาม ตั้งค่าข้อมูลการติดตามจากโครงเรื่องหลัก
allowed-tools: Read(//stories/**/specification.md), Read(stories/**/specification.md), Read(//stories/**/outline.md), Read(stories/**/outline.md), Read(//stories/**/creative-plan.md), Read(stories/**/creative-plan.md), Write(//spec/tracking/**), Write(spec/tracking/**), Bash(find:*), Bash(grep:*), Bash(wc:*), Bash(*)
model: claude-sonnet-4-5-20250929
scripts:
  sh: .specify/scripts/bash/init-tracking.sh
  ps: .specify/scripts/powershell/init-tracking.ps1
---

# เริ่มต้นระบบติดตาม

สร้างไฟล์ข้อมูลการติดตามทั้งหมด โดยอิงจากโครงเรื่องหลักและแผนการแบ่งบทที่ได้สร้างไว้

## ช่วงเวลาที่ใช้

หลังจากทำ `/story` และ `/outline` เสร็จเรียบร้อย ก่อนเริ่มเขียน ให้รันคำสั่งนี้

## ขั้นตอนการเริ่มต้น

1. **อ่านข้อมูลพื้นฐาน**
   - อ่าน `stories/*/story.md` เพื่อรับการตั้งค่าเรื่องราว
   - อ่าน `stories/*/outline.md` เพื่อรับแผนการแบ่งบท
   - อ่าน `.specify/config.json` เพื่อรับวิธีการเขียน

2. **เริ่มต้นไฟล์ติดตาม**

   **สำคัญ**: อ่านสเปกการจัดการเส้นเรื่องจากบทที่ 5 ของ `specification.md` เป็นหลัก เพื่อนำมาเติมลงในไฟล์ติดตาม

   สร้างหรืออัปเดต `spec/tracking/plot-tracker.json`:
   - อ่านนิยามเส้นเรื่องทั้งหมดจาก `specification.md หัวข้อ 5.1`
   - อ่านจุดบรรจบทั้งหมดจาก `specification.md หัวข้อ 5.3`
   - อ่านปมทั้งหมดจาก `specification.md หัวข้อ 5.4`
   - อ่านการกระจายเส้นเรื่องในแต่ละช่วงบทจาก `creative-plan.md`
   - ตั้งค่าสถานะปัจจุบัน (สมมติว่ายังไม่ได้เริ่มเขียน)

   **โครงสร้าง plot-tracker.json**:
   ```json
   {
     "novel": "[อ่านชื่อเรื่องจาก specification.md]",
     "lastUpdated": "[ปปปป-ดด-วว]",
     "currentState": {
       "chapter": 0,
       "volume": 1,
       "mainPlotStage": "[ระยะเริ่มต้น]"
     },
     "plotlines": {
       "main": {
         "name": "[ชื่อเส้นเรื่องหลัก]",
         "status": "active",
         "currentNode": "[จุดเริ่มต้น]",
         "completedNodes": [],
         "upcomingNodes": "[อ่านจากจุดบรรจบและแผนการแบ่งบท]"
       },
       "subplots": [
         {
           "id": "[อ่านจาก 5.1 เช่น PL-01]",
           "name": "[ชื่อเส้นเรื่อง]",
           "type": "[เส้นหลัก/เส้นรอง/สนับสนุนเส้นหลัก]",
           "priority": "[P0/P1/P2]",
           "status": "[active/dormant]",
           "plannedStart": "[บทเริ่มต้น]",
           "plannedEnd": "[บทสิ้นสุด]",
           "currentNode": "[โหนดปัจจุบัน]",
           "completedNodes": [],
           "upcomingNodes": "[อ่านจากตารางจุดบรรจบ]",
           "intersectionsWith": "[อ่านจากตารางจุดบรรจบ 5.3 ว่าเกี่ยวข้องกับเส้นเรื่องใดบ้าง]",
           "activeChapters": "[อ่านจากการวางแผนจังหวะ 5.2]"
         }
       ]
     },
     "foreshadowing": [
       {
         "id": "[อ่านจาก 5.4 เช่น F-001]",
         "content": "[เนื้อหาปม]",
         "planted": {"chapter": null, "description": "[คำอธิบายการวาง]"},
         "hints": [],
         "plannedReveal": {"chapter": "[บทที่เฉลย]", "description": "[วิธีเฉลย]"},
         "status": "planned",
         "importance": "[high/medium/low]",
         "relatedPlotlines": "[รายการรหัสเส้นเรื่องที่เกี่ยวข้อง]"
       }
     ],
     "intersections": [
       {
         "id": "[อ่านจาก 5.3 เช่น X-001]",
         "chapter": "[บทที่บรรจบ]",
         "plotlines": "[รายการรหัสเส้นเรื่องที่เกี่ยวข้อง]",
         "content": "[เนื้อหาการบรรจบ]",
         "status": "upcoming",
         "impact": "[ผลที่คาดหวัง]"
       }
     ]
   }
   ```

   สร้างหรืออัปเดต `spec/tracking/timeline.json`:
   - กำหนดจุดเวลาจากแผนการแบ่งบท
   - ทำเครื่องหมายเหตุการณ์สำคัญทางเวลา

   สร้างหรืออัปเดต `spec/tracking/relationships.json`:
   - ดึงความสัมพันธ์เริ่มต้นจากการตั้งค่าตัวละคร
   - กำหนดการจัดกลุ่มฝ่าย

   สร้างหรืออัปเดต `spec/tracking/character-state.json`:
   - เริ่มต้นสถานะของตัวละคร
   - กำหนดตำแหน่งเริ่มต้น

3. **สร้างรายงานการเริ่มต้น**
   แสดงผลการเริ่มต้น ยืนยันว่าระบบติดตามพร้อมใช้งาน

## การเชื่อมโยงอัจฉริยะ

- ตั้งค่าจุดตรวจสอบโดยอัตโนมัติตามวิธีการเขียน
- การเดินทางของฮีโร่: จุดติดตาม 12 ขั้น
- โครงสร้างสามองก์: จุดเปลี่ยนของสามองก์
- โครงสร้างเจ็ดจุด: จุดสำคัญ 7 จุด

หลังจากระบบติดตามเริ่มต้นแล้ว การเขียนในขั้นตอนถัดไปจะอัปเดตข้อมูลเหล่านี้โดยอัตโนมัติ
