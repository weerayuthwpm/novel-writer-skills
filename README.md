# ทักษะการเขียนนิยาย - เครื่องมือเขียนนิยายเฉพาะสำหรับ Claude Code

[![npm version](https://badge.fury.io/js/novel-writer-skills.svg)](https://www.npmjs.com/package/novel-writer-skills)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

> 🚀 ผู้ช่วยเขียนนิยายอัจฉริยะด้วย AI ที่ออกแบบมาเฉพาะสำหรับ Claude Code
>
> ผสานรวม Slash Commands และ Agent Skills อย่างลึกซึ้ง มอบประสบการณ์การเขียนที่ดีที่สุด

## ✨ คุณสมบัติหลัก

- 📚 **Slash Commands** - คำสั่ง Slash ของ Claude Code รองรับระเบียบวิธีเจ็ดขั้นตอนอย่างครบถ้วน
- 🤖 **Agent Skills** - ฐานความรู้และระบบตรวจสอบอัจฉริยะที่ AI เปิดใช้งานโดยอัตโนมัติ
- 🎯 **ฐานความรู้ประเภทเรื่อง** - ให้หลักปฏิบัติในการเขียนแนวโรแมนซ์ ลึกลับ แฟนตาซี และอื่นๆ โดยอัตโนมัติ
- 🔍 **ระบบตรวจสอบคุณภาพอัจฉริยะ** - ตรวจสอบความสม่ำเสมอ จังหวะ และมุมมองอย่างอัตโนมัติ
- 📝 **เสริมเทคนิคการเขียน** - ใช้เทคนิคเฉพาะทางด้านบทสนทนา ฉาก และตัวละครโดยอัตโนมัติ
- 🔌 **ระบบปลั๊กอิน** - ฟังก์ชันเสริมที่ขยายได้ เช่น เสียงสมจริง การแปล ฯลฯ

## 🚀 เริ่มต้นใช้งานอย่างรวดเร็ว

### 1. ติดตั้ง

```bash
npm install -g novel-writer-skills
```

### 2. เริ่มต้นโปรเจกต์

```bash
# การใช้งานพื้นฐาน
novelwrite init my-novel

# เริ่มต้นในไดเรกทอรีปัจจุบัน
novelwrite init --here

# ติดตั้งปลั๊กอินล่วงหน้า
novelwrite init my-novel --plugins authentic-voice
```

### 3. เริ่มเขียนใน Claude Code

เปิดโปรเจกต์ใน Claude Code และใช้คำสั่ง Slash:

```text
/constitution    # 1. สร้างรัฐธรรมนูญการเขียน
/specify         # 2. กำหนดข้อกำหนดของเรื่อง
/clarify         # 3. ชี้แจงการตัดสินใจสำคัญ
/plan            # 4. วางแผนการเขียน
/tasks           # 5. แบ่งรายการงาน
/write           # 6. เขียนโดยใช้ AI ช่วย
/analyze         # 7. วิเคราะห์ตรวจสอบคุณภาพ
```

## 🎨 Agent Skills เปิดใช้งานอัตโนมัติ

### ฐานความรู้ประเภทเรื่อง (Genre Knowledge)

เมื่อคุณกล่าวถึงประเภทเรื่องเฉพาะ ฐานความรู้ที่เกี่ยวข้องจะเปิดใช้งานโดยอัตโนมัติ:

- 💕 **Romance** - หลักปฏิบัติและจังหวะอารมณ์ของนวนิยายโรแมนซ์
- 🔍 **Mystery** - เทคนิคการสืบสวนสอบสวนและการจัดการเบาะแส
- 🐉 **Fantasy** - หลักการสร้างโลกแฟนตาซีและการสร้างจักรวาล

### เทคนิคการเขียน (Writing Techniques)

ใช้แนวทางปฏิบัติที่ดีที่สุดโดยอัตโนมัติระหว่างการเขียน:

- 💬 **บทสนทนา** - ความเป็นธรรมชาติของบทสนทนาและน้ำเสียงของตัวละคร
- 🎬 **โครงสร้างฉาก** - การสร้างฉากและการควบคุมจังหวะ
- 👤 **เส้นทางตัวละคร** - เส้นทางการพัฒนาตัวละครและตรรกะการเติบโต

### การตรวจสอบคุณภาพ (Quality Assurance)

ตรวจสอบเบื้องหลังโดยอัตโนมัติ แจ้งเตือนปัญหาอย่างเชิงรุก:

- ✅ **ตัวตรวจสอบความสม่ำเสมอ** - ตรวจสอบความสม่ำเสมอ (ตัวละคร โลกของเรื่อง ไทม์ไลน์)
- 🧭 **คู่มือขั้นตอนการทำงาน** - แนะนำให้ใช้ระเบียบวิธีเจ็ดขั้นตอน

## 📚 Slash Commands

### ระเบียบวิธีเจ็ดขั้นตอน

| คำสั่ง | ฟังก์ชัน | ผลลัพธ์ |
|------|------|------|
| `/constitution` | สร้างรัฐธรรมนูญการเขียน | `.specify/memory/constitution.md` |
| `/specify` | กำหนดข้อกำหนดของเรื่อง | `stories/[name]/specification.md` |
| `/clarify` | ชี้แจงประเด็นที่ไม่ชัดเจน (5 คำถาม) | อัปเดต specification.md |
| `/plan` | วางแผนการเขียน | `stories/[name]/creative-plan.md` |
| `/tasks` | แบ่งรายการงาน | `stories/[name]/tasks.md` |
| `/write` | ดำเนินการเขียนบท | `stories/[name]/content/chapter-XX.md` |
| `/analyze` | วิเคราะห์ตรวจสอบคุณภาพ | รายงานการวิเคราะห์ (2 โหมด: โครงสร้าง/เนื้อหา) |

### การติดตามและการตรวจสอบ

| คำสั่ง | ฟังก์ชัน |
|------|------|
| `/track-init` | เริ่มต้นระบบติดตาม |
| `/track` | อัปเดตการติดตามแบบครบวงจร |
| `/plot-check` | ตรวจสอบความสม่ำเสมอของโครงเรื่อง |
| `/timeline` | จัดการไทม์ไลน์ |
| `/relations` | ติดตามความสัมพันธ์ของตัวละคร |
| `/world-check` | ตรวจสอบความถูกต้องของโลกของเรื่อง |

## 🔌 ระบบปลั๊กอิน

### ติดตั้งปลั๊กอิน

```bash
# แสดงรายการปลั๊กอินที่พร้อมใช้งาน
novelwrite plugin:list

# ติดตั้งปลั๊กอิน
novelwrite plugin:add authentic-voice

# ถอดปลั๊กอิน
novelwrite plugin:remove authentic-voice
```

### ปลั๊กอินอย่างเป็นทางการ

- **authentic-voice** - ปลั๊กอินเขียนด้วยเสียงมนุษย์สมจริง ช่วยเพิ่มความคิดสร้างสรรค์และคุณภาพชีวิต
- กำลังพัฒนาปลั๊กอินเพิ่มเติม...

## 📖 โครงสร้างโปรเจกต์

```text
my-novel/
├── .claude/
│   ├── commands/       # Slash Commands
│   └── skills/         # Agent Skills
│
├── .specify/           # การกำหนดค่า Spec Kit
│   ├── memory/
│   │   └── constitution.md
│   └── templates/
│       ├── scripts/    # เครื่องมือสคริปต์บรรทัดคำสั่ง
│       │   ├── bash/
│       │   └── powershell/
│       ├── commands/
│       ├── knowledge/
│       └── ...
│
├── stories/
│   └── 001-my-story/
│       ├── specification.md
│       ├── creative-plan.md
│       ├── tasks.md
│       └── content/
│           ├── chapter-01.md
│           └── ...
│
├── spec/
│   ├── tracking/       # ข้อมูลการติดตาม
│   │   ├── plot-tracker.json
│   │   ├── timeline.json
│   │   ├── character-state.json
│   │   └── relationships.json
│   │
│   └── knowledge/      # ฐานความรู้
│       ├── characters/
│       ├── worldbuilding/
│       └── references/
│
└── README.md
```

## 🆚 ความสัมพันธ์กับ novel-writer

| คุณสมบัติ | novel-writer | novel-writer-skills |
|------|-------------|-------------------|
| **แพลตฟอร์มที่รองรับ** | เครื่องมือ AI 13 ชนิด (Claude, Cursor, Gemini ฯลฯ) | เฉพาะ Claude Code |
| **ระเบียบวิธีหลัก** | ✅ ระเบียบวิธีเจ็ดขั้นตอน | ✅ ระเบียบวิธีเจ็ดขั้นตอน |
| **Slash Commands** | ✅ คำสั่งข้ามแพลตฟอร์ม | ✅ คำสั่งที่ปรับให้เหมาะกับ Claude |
| **Agent Skills** | ❌ ไม่รองรับ | ✅ ผสานรวมอย่างลึกซึ้ง |
| **การตรวจสอบอัจฉริยะ** | ⚠️ ดำเนินการด้วยตนเอง | ✅ ตรวจสอบอัตโนมัติ |
| **ฐานความรู้ประเภทเรื่อง** | ⚠️ ต้องค้นหาด้วยตนเอง | ✅ เปิดใช้งานอัตโนมัติ |
| **สถานการณ์การใช้งาน** | ต้องการรองรับหลายแพลตฟอร์ม | ต้องการประสบการณ์ที่ดีที่สุด (Claude Code) |

**คำแนะนำในการเลือก**:

- หากคุณใช้เครื่องมือ AI หลายตัว → เลือก **novel-writer**
- หากคุณเน้นใช้ Claude Code → เลือก **novel-writer-skills**

## 🛠️ คำสั่ง CLI

### การจัดการโปรเจกต์

```bash
# เริ่มต้นโปรเจกต์
novelwrite init <project-name>

# ตรวจสอบสภาพแวดล้อม
novelwrite check

# อัปเกรดโปรเจกต์
novelwrite upgrade
```

### การจัดการปลั๊กอิน

```bash
# แสดงรายการปลั๊กอินที่ติดตั้ง
novelwrite plugin:list

# ติดตั้งปลั๊กอิน
novelwrite plugin:add <plugin-name>

# ถอดปลั๊กอิน
novelwrite plugin:remove <plugin-name>
```

## 🔧 สคริปต์บรรทัดคำสั่ง (ตัวเลือก)

นอกเหนือจาก Slash Commands ใน Claude Code แล้ว โปรเจกต์ยังมีเครื่องมือสคริปต์บรรทัดคำสั่ง:

### ตำแหน่งสคริปต์

หลังจากเริ่มต้นโปรเจกต์ สคริปต์จะอยู่ที่: `.specify/templates/scripts/`

```text
.specify/templates/scripts/
├── bash/          # สคริปต์สำหรับ macOS/Linux
└── powershell/    # สคริปต์สำหรับ Windows
```

### สถานการณ์การใช้งาน

- ✅ **ใช้แทนบรรทัดคำสั่ง** - ดำเนินการตามระเบียบวิธีเจ็ดขั้นตอนในเทอร์มินัลโดยตรง
- ✅ **เวิร์กโฟลว์อัตโนมัติ** - ผสานรวมกับ CI/CD หรือสคริปต์ประมวลผลแบบแบตช์
- ✅ **การดำเนินการแบบแบตช์** - จัดการหลายเรื่องหรือตรวจสอบแบบแบตช์
- ✅ **ใช้งานแบบอิสระ** - ในสถานการณ์ที่ไม่ต้องพึ่งพา Claude Code

### ตัวอย่างอย่างรวดเร็ว

**macOS/Linux:**

```bash
# สร้างรัฐธรรมนูญ
bash .specify/templates/scripts/bash/constitution.sh

# กำหนดข้อกำหนด
bash .specify/templates/scripts/bash/specify-story.sh

# ติดตามความคืบหน้า
bash .specify/templates/scripts/bash/track-progress.sh
```

**Windows:**

```powershell
# สร้างรัฐธรรมนูญ
.\.specify\templates\scripts\powershell\constitution.ps1

# กำหนดข้อกำหนด
.\.specify\templates\scripts\powershell\specify-story.ps1

# ติดตามความคืบหน้า
.\.specify\templates\scripts\powershell\track-progress.ps1
```

### สคริปต์ที่พร้อมใช้งาน

Slash Commands ทุกคำสั่งมีเวอร์ชันสคริปต์ที่สอดคล้องกัน:

| สคริปต์ | ฟังก์ชัน | คำสั่งที่สอดคล้อง |
|-----|------|---------|
| `constitution` | สร้างรัฐธรรมนูญการเขียน | `/constitution` |
| `specify-story` | กำหนดข้อกำหนดของเรื่อง | `/specify` |
| `plan-story` | วางแผนการเขียน | `/plan` |
| `track-progress` | ติดตามความคืบหน้า | `/track` |
| `check-consistency` | ตรวจสอบความสม่ำเสมอ | - |
| และอีกมากมาย... | ดูได้ที่ `.specify/templates/scripts/README.md` | - |

📖 **เอกสารรายละเอียด**: [scripts/README.md](templates/scripts/README.md)

### เมื่อใดควรใช้สคริปต์ vs Slash Commands

| สถานการณ์ | วิธีที่แนะนำ |
|-----|---------|
| การเขียนประจำวัน ต้องการความช่วยเหลือจาก AI | ✅ Slash Commands (แนะนำเป็นอันดับแรก) |
| การประมวลผลแบบแบตช์ ระบบอัตโนมัติ | ✅ สคริปต์บรรทัดคำสั่ง |
| การผสานรวม CI/CD | ✅ สคริปต์บรรทัดคำสั่ง |
| การตรวจสอบและยืนยันอย่างรวดเร็ว | ✅ สคริปต์บรรทัดคำสั่ง |

## 📚 เอกสาร

- [คู่มือเริ่มต้น](docs/getting-started.md) - บทช่วยสอนการติดตั้งและการใช้งานโดยละเอียด
- [คำอธิบายคำสั่ง](docs/commands.md) - คำอธิบายครบถ้วนของทุกคำสั่ง
- [คู่มือ Skills](docs/skills-guide.md) - หลักการทำงานของ Agent Skills
- [ชุดเครื่องมือสคริปต์](templates/scripts/README.md) - คู่มือการใช้สคริปต์บรรทัดคำสั่ง
- [การพัฒนาปลั๊กอิน](docs/plugin-development.md) - วิธีพัฒนาปลั๊กอินของคุณเอง

## 🤝 การมีส่วนร่วม

ยินดีต้อนรับ Issue และ Pull Request!

ที่อยู่โปรเจกต์: [https://github.com/wordflowlab/novel-writer-skills](https://github.com/wordflowlab/novel-writer-skills)

## 📄 ใบอนุญาต

MIT License

## 🙏 คำขอบคุณ

โปรเจกต์นี้มีพื้นฐานมาจากระเบียบวิธีของ [novel-writer](https://github.com/wordflowlab/novel-writer) และปรับให้เหมาะสมสำหรับ Claude Code อย่างลึกซึ้ง

---

**Novel Writer Skills** - ให้ Claude Code เป็นคู่หูสร้างสรรค์ที่ดีที่สุดของคุณ! ✨📚
