# ชุดเครื่องมือสคริปต์ (Script Toolkit)

ไดเรกทอรีนี้ประกอบด้วยเครื่องมือสคริปต์แบบ Command Line สำหรับ Novel Writer Skills เพื่อใช้เป็นทางเลือกแทน Claude Code Slash Commands

## 📂 โครงสร้างไดเรกทอรี

```text
scripts/
├── bash/          # สคริปต์สำหรับ macOS/Linux[cite: 8]
├── powershell/    # สคริปต์สำหรับ Windows[cite: 8]
└── README.md      # เอกสารฉบับนี้[cite: 8]

```

## 🔄 คำชี้แจงการปรับใช้สำหรับ novel-writer-skills

สคริปต์เหล่านี้ได้รับการพอร์ตมาจาก [novel-writer](https://www.google.com/search?q=https://github.com/wordflowlab/novel-writer) และปรับปรุงให้เข้ากับโครงสร้างโปรเจกต์ของ novel-writer-skills แล้ว:

### ความแตกต่างของเส้นทางไฟล์ (Path)

| ไฟล์ | novel-writer | novel-writer-skills |
| --- | --- | --- |
| ไฟล์รัฐธรรมนูญ | `memory/constitution.md` | `.specify/memory/constitution.md`<br> |
| ข้อกำหนดเรื่องราว | `stories/*/specification.md` | `stories/*/specification.md` ✅

 |
| ข้อมูลการติดตาม | `spec/tracking/*.json` | `spec/tracking/*.json` ✅

 |

**สคริปต์ทั้งหมดได้รับการปรับเปลี่ยนเส้นทางไฟล์ใหม่โดยอัตโนมัติแล้ว** ไม่จำเป็นต้องแก้ไขด้วยตนเอง!

## 🎯 บริบทที่เหมาะสมในการใช้งาน

แม้ว่า Novel Writer Skills จะถูกออกแบบมาสำหรับ Claude Code เป็นหลัก แต่สคริปต์เหล่านี้ช่วยให้คุณสามารถ:

* **ทางเลือกแบบ Command Line** - ดำเนินการต่างๆ ได้โดยตรงจากเทอร์มินัลของคุณ ✅


* **เวิร์กโฟลว์อัตโนมัติ** - รวมเข้ากับระบบ CI/CD หรือสคริปต์อัตโนมัติอื่นๆ ได้ ✅


* **การประมวลผลแบบกลุ่ม (Batch)** - จัดการเรื่องราวหลายๆ เรื่องหรือทำการตรวจสอบพร้อมกันเป็นชุดได้ ✅


* **เครื่องมือแบบสแตนด์อโลน** - ฟังก์ชันการทำงานที่เป็นอิสระ ไม่จำเป็นต้องพึ่งพา Claude Code ✅



## 🚀 การเริ่มต้นใช้งานอย่างรวดเร็ว

### สำหรับผู้ใช้ macOS/Linux

```bash
# เข้าสู่ไดเรกทอรีรากของโปรเจกต์
cd my-novel

# เรียกใช้สคริปต์ (ตัวอย่าง: การสร้างรัฐธรรมนูญ)
bash .specify/templates/scripts/bash/constitution.sh

# หรือเพิ่มเข้าไปใน PATH
export PATH="$PATH:$(pwd)/.specify/templates/scripts/bash"
constitution.sh

```

### สำหรับผู้ใช้ Windows

```powershell
# เข้าสู่ไดเรกทอรีรากของโปรเจกต์
cd my-novel

# เรียกใช้สคริปต์ (ตัวอย่าง: การสร้างรัฐธรรมนูญ)
.\.specify\templates\scripts\powershell\constitution.ps1

# 或者添加到环境变量
$env:PATH += ";$(Get-Location)\.specify\templates\scripts\powershell"
constitution.ps1

```

## 📚 สคริปต์หลัก

### ระเบียบวิธี 7 ขั้นตอน (Seven-Step Methodology)

| สคริปต์ | ฟังก์ชันการทำงาน | คำสั่งที่สอดคล้องกัน |
| --- | --- | --- |
| `constitution.sh/ps1` | สร้างรัฐธรรมนูญการเขียน | `/constitution`<br> |
| `specify-story.sh/ps1` | กำหนดข้อกำหนดของเรื่องราว | `/specify`<br> |
| `clarify-story.sh/ps1` | เคลียร์จุดที่ยังคลุมเครือ | `/clarify`<br> |
| `plan-story.sh/ps1` | วางแผนการเขียน | `/plan`<br> |
| `generate-tasks.sh/ps1` | สร้างรายการงาน (Task List) | `/tasks`<br> |
| `analyze-story.sh/ps1` | วิเคราะห์ตรวจสอบคุณภาพ | `/analyze`<br> |

### การติดตามและการตรวจสอบ

| สคริปต์ | ฟังก์ชันการทำงาน | คำสั่งที่สอดคล้องกัน |
| --- | --- | --- |
| `init-tracking.sh/ps1` | เริ่มต้นระบบติดตามข้อมูล | `/track-init`<br> |
| `track-progress.sh/ps1` | อัปเดตการติดตามภาพรวม | `/track`<br> |
| `check-plot.sh/ps1` | ตรวจสอบความสอดคล้องของพล็อต | `/plot-check`<br> |
| `check-timeline.sh/ps1` | จัดการและตรวจสอบเส้นเวลา (Timeline) | `/timeline`<br> |
| `manage-relations.sh/ps1` | ติดตามความสัมพันธ์ของตัวละคร | `/relations`<br> |
| `check-world.sh/ps1` | ตรวจสอบความถูกต้องของโลกทัศน์ | `/world-check`<br> |
| `check-consistency.sh/ps1` | ตรวจสอบความสอดคล้องทั่วไป | -

 |
| `check-writing-state.sh/ps1` | ตรวจสอบสถานะการเขียน | -

 |

### สคริปต์เครื่องมือเสริม

| สคริปต์ | ฟังก์ชันการทำงาน |
| --- | --- |
| `common.sh/ps1` | คลังฟังก์ชันส่วนกลาง (ถูกเรียกใช้โดยสคริปต์อื่น)

 |
| `text-audit.sh/ps1` | เครื่องมือตรวจสอบและชำระข้อความ

 |
| `test-word-count.sh` | ตรวจสอบจำนวนคำ (มีเฉพาะเวอร์ชั่น bash)

 |

## 🔧 คลังฟังก์ชันส่วนกลาง (Common Function Library)

ไฟล์ `common.sh` และ `common.ps1` มีฟังก์ชันส่วนกลางที่พร้อมใช้งานดังนี้:

### ฟังก์ชันบน Bash

```bash
get_project_root()    # ดึงค่าไดเรกทอรีรากของโปรเจกต์
get_current_story()   # ดึงค่าไดเรกทอรีของเรื่องราวปัจจุบัน
get_active_story()    # ดึงชื่อเรื่องราวที่กำลังดำเนินการอยู่
create_numbered_dir() # สร้างไดเรกทอรีแบบใส่รหัสตัวเลขกำกับ

```

### ฟังก์ชันบน PowerShell

```powershell
Get-ProjectRoot       # ดึงค่าไดเรกทอรีรากของโปรเจกต์
Get-CurrentStoryDir   # ดึงค่าไดเรกทอรีของเรื่องราวปัจจุบัน
Get-ActiveStory       # ดึงชื่อเรื่องราวที่กำลังดำเนินการอยู่

```

## ⚠️ ข้อควรระวัง

1. **การระบุไดเรกทอรีรากของโปรเจกต์** - สคริปต์จะค้นหาตำแหน่งโปรเจกต์ผ่านการตรวจหาไฟล์ `.specify/config.json`

2. **สิทธิ์ในการรันสคริปต์** - สำหรับผู้ใช้ Linux/macOS โปรดตรวจสอบให้แน่ใจว่าสคริปต์ได้รับสิทธิ์ในการรันแล้ว:


```bash
chmod +x .specify/templates/scripts/bash/*.sh

```




3. **ความแตกต่างจาก Slash Commands**:

* Slash Commands ใช้ภายใน Claude Code และมีความสามารถในการโต้ตอบกับ AI


* สคริปต์เหมาะสำหรับการทำงานอัตโนมัติและการประมวลผลแบบกลุ่ม โดยจะไม่มีการโต้ตอบกับ AI


* แนะนำให้ใช้ Slash Commands เป็นหลักเพื่อประสบการณ์การใช้งานที่ดีที่สุด



## 🆚 เมื่อไหร่ควรใช้สคริปต์ vs Slash Commands

| บริบทการใช้งาน | แนวทางที่แนะนำ |
| --- | --- |
| การเขียนงานประจำวัน, ต้องการให้ AI ช่วยเหลือ | ✅ Slash Commands

 |
| การประมวลผลเป็นชุด, การทำงานอัตโนมัติ | ✅ สคริปต์

 |
| การผสานรวมเข้ากับระบบ CI/CD | ✅ สคริปต์

 |
| การเรียนรู้และทำความเข้าใจเวิร์กโฟลว์ | ✅ สคริปต์ (สามารถเปิดดูซอร์สโค้ดได้)

 |
| การตรวจสอบและยืนยันผลอย่างรวดเร็ว | ✅ สคริปต์

 |

## 📖 ตัวอย่าง: เวิร์กโฟลว์แบบครบวงจร

```bash
# 1. สร้างรัฐธรรมนูญการเขียน
bash constitution.sh

# 2. กำหนดข้อกำหนดของเรื่องราว
bash specify-story.sh

# 3. เคลียร์จุดคลุมเครือ (ขั้นตอนนี้มักต้องอาศัยผู้เขียนร่วมพิจารณา)
bash clarify-story.sh

# 4. วางแผนการเขียน
bash plan-story.sh

# 5. สร้างรายการงานที่ต้องทำ
bash generate-tasks.sh

# 6. เริ่มต้นระบบติดตามข้อมูล
bash init-tracking.sh

# 7. ติดตามความคืบหน้าเป็นระยะในระหว่างการเขียน
bash track-progress.sh

# 8. วิเคราะห์สรุปผลขั้นสุดท้าย
bash analyze-story.sh

```

## 🔗 เอกสารที่เกี่ยวข้อง

* [เอกสารหลักของ Novel Writer Skills](https://www.google.com/search?q=../../README.md)

* [รายละเอียดคำสั่งเพิ่มเติม](https://www.google.com/search?q=../../docs/commands.md)

* [คู่มือการเริ่มต้นใช้งาน](https://www.google.com/search?q=../../docs/getting-started.md)


## 💡 ทิปส์เล็กๆ น้อยๆ

สคริปต์เหล่านี้ได้รับการพอร์ตมาจากโปรเจกต์ [novel-writer](https://www.google.com/search?q=https://github.com/wordflowlab/novel-writer) และได้รับการปรับแต่งเพื่อให้เข้ากับโครงสร้างของ Novel Writer Skills แล้ว

หากคุณจำเป็นต้องสลับการทำงานไปมาระหว่างเครื่องมือ AI หลายตัว คุณสามารถพิจารณาเลือกใช้เวอร์ชั่นเต็มได้ที่ [novel-writer](https://www.google.com/search?q=https://github.com/wordflowlab/novel-writer)

---

**Happy Writing!** ✨📚
