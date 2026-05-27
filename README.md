# 📱 PhoneBox / NexusCore

**Smart Wireless Device Manager** - ชุดเครื่องมือ Windows สำหรับจัดการและ mirror หน้าจอ Android ด้วย `scrcpy` และ `adb`

> ⚠️ **Legal Notice**: ใช้งานกับอุปกรณ์ของตัวเองหรืออุปกรณ์ที่ได้รับอนุญาตเท่านั้น

---

## 🎯 คุณสมบัติหลัก

- **USB + WiFi Mirroring**: ตรวจหาและ mirror อุปกรณ์ Android ผ่านทั้ง USB และ WiFi โดยอัตโนมัติ
- **Smart Device Scanner**: สแกนอุปกรณ์ผ่าน ADB-USB, ADB-over-WiFi, และ ARP scanning
- **Adaptive Network Quality**: ปรับคุณภาพ (resolution/bitrate/fps) ตามความเสถียรของ WiFi โดยอัตโนมัติ
- **Beautiful CLI UI**: เมนูสไตล์ TUI ที่ใช้งานง่ายด้วยลูกศร และ Enter
- **USB to WiFi Setup**: เสริมความสามารถให้อุปกรณ์ USB สามารถ mirror ผ่าน WiFi ได้ (TCP/IP port 5555)
- **Automatic Reconnection**: ลองเชื่อมต่อใหม่โดยอัตโนมัติหากการเชื่อมต่อหลุด

---

## 📋 ข้อกำหนดเบื้องต้น

### Software & Hardware
- **Windows 10/11** (PowerShell 5.0+)
- **Android Device** ที่รองรับ ADB
- **USB Cable** (สำหรับการ debug ครั้งแรก) หรือ **WiFi Network** ที่เชื่อมต่อกัน

### Device Setup
1. **เปิด Developer Mode**
   - ไปที่ `Settings` → `About Phone` → แตะ `Build Number` 7 ครั้ง

2. **เปิด USB Debugging**
   - ไปที่ `Settings` → `Developer Options` → เปิด `USB Debugging`

3. **อนุมัติ RSA Fingerprint**
   - เสียบ USB และยอมรับ RSA prompt บนอุปกรณ์

### Verify Setup
```powershell
.\scrcpy-win64-v4.0\adb.exe devices -l      # ตรวจสอบว่า device ปรากฏ
.\scrcpy-win64-v4.0\scrcpy.exe --version   # ตรวจสอบ scrcpy
```

---

## 📁 โครงสร้างไฟล์

```
NexusCore/
├── PhoneBox.bat                    # Launcher เปิด PhoneBox.ps1
├── PhoneBox.ps1                    # Main application (38 KB, PowerShell)
├── scrcpy-win64-v4.0/
│   ├── scrcpy.exe                  # Screen mirroring executable
│   ├── adb.exe                     # Android Debug Bridge
│   └── ...                         # Runtime dependencies
├── README.md                       # This file
├── LICENSE.txt                     # MIT License
└── screen.png                      # Screenshot

Languages: PowerShell 98.7% | Other 1.3%
```

---

## 🚀 วิธีใช้งาน

### 1️⃣ เปิด PhoneBox

**ตัวเลือก A: ดับเบิลคลิก**
```
PhoneBox.bat
```

**ตัวเลือก B: Terminal**
```powershell
.\PhoneBox.bat
```

PhoneBox จะ:
- สแกนอุปกรณ์ที่เชื่อมต่อผ่าน USB, ADB-over-WiFi, และ ARP table
- แสดงรายชื่ออุปกรณ์พร้อมสถานะ (USB/WiFi) และข้อมูล IP
- รอการเลือกจากผู้ใช้

### 2️⃣ เลือกอุปกรณ์

ใช้ **↑↓ ลูกศร** เพื่อนำทาง และกด **ENTER** เพื่อเชื่อมต่อ

```
  ↑↓  Navigate    ENTER  Connect      ESC  Exit

  ╭──────────────── DETECTED DEVICES ─────────────────────╮
  │                                                        │
  │   1. [USB] Samsung Galaxy A12 | WiFi: 192.168.1.5   │
  │ ► 2. [WiFi] Google Pixel 6 | 192.168.1.10           │
  │   3. [WiFi] Android Device | 192.168.1.15           │
  │                                                        │
  ├──────────────── QUICK  ACTIONS ──────────────────────┤
  │      A.  Enter IP Manually                            │
  │      B.  Rescan Network                               │
  ╰────────────────────────────────────────────────────────╯
```

### 3️⃣ การเชื่อมต่อ

#### 🔵 USB Connection
- ความคุณภาพสูงสุด: **1920p / 16 Mbps / 60 fps**
- Screen turns **OFF** (ประหยัดแบตเตอรี่)
- ใช้ไฟล์ `scrcpy` ได้เลย

#### 🟢 WiFi Connection
- **Adaptive Quality**: ปรับตามความเสถียรของ WiFi
  - **Excellent** (latency < 15ms): 1280p / 12 Mbps / 60 fps
  - **Good** (< 50ms): 1024p / 8 Mbps / 60 fps
  - **High Latency** (> 50ms): 800p / 4 Mbps / 30 fps
- Screen turns **OFF** (ให้ WiFi chip ทำงาน)
- ทำให้เสถียรกว่า USB สำหรับการใช้งานไร้สาย

#### ⚙️ Manual IP
หากการสแกนหาหาไม่เจออุปกรณ์ เลือก **A. Enter IP Manually** และใส่ IP ด้วยตนเอง

---

## 💡 Device Status Indicators

| Badge | ความหมาย | หมายเหตุ |
|-------|---------|---------|
| `[USB]` | อุปกรณ์เชื่อมต่อผ่าน USB | สามารถเปลี่ยนเป็น WiFi ได้ |
| `[WiFi]` | อุปกรณ์เชื่อมต่อผ่าน WiFi | ADB ผ่านเครือข่าย |
| `[5555:OK]` | Port 5555 เปิด | พร้อม mirror ผ่าน WiFi |
| `[5555:--]` | Port 5555 ปิด | ต้องเปลี่ยนเป็น WiFi ก่อน |

---

## 🔧 Troubleshooting

### ❌ `adb devices` ไม่เจออุปกรณ์

```powershell
# Kill และ restart ADB server
.\scrcpy-win64-v4.0\adb.exe kill-server
.\scrcpy-win64-v4.0\adb.exe start-server
.\scrcpy-win64-v4.0\adb.exe devices -l
```

**เหตุปัญหาทั่วไป:**
- Device ไม่ได้ปลดล็อก
- ยังไม่ได้ยอมรับ RSA prompt
- Driver ADB หรือ USB ไม่เข้ากัน

### ❌ ขึ้น "unauthorized"

```
Authorize USB debugging on the device
```

**วิธีแก้:**
1. ปลดล็อก Android device
2. ดูแถบแจ้งเตือน "Allow USB Debugging"
3. กด **Allow**
4. รัน `adb devices -l` อีกครั้ง

### ❌ WiFi mode เชื่อมต่อไม่ได้

```powershell
# ตั้ง TCP/IP จาก USB ก่อน
.\scrcpy-win64-v4.0\adb.exe -s <SERIAL> tcpip 5555

# ตัวอย่าง:
.\scrcpy-win64-v4.0\adb.exe -s emulator-5554 tcpip 5555
```

จากนั้นเชื่อมต่อผ่าน WiFi:
```powershell
.\scrcpy-win64-v4.0\adb.exe connect <DEVICE_IP>:5555

# ตัวอย่าง:
.\scrcpy-win64-v4.0\adb.exe connect 192.168.1.100:5555
```

### ❌ scrcpy แสดง "Connection refused"

- ตรวจสอบว่า WiFi ใช้งานได้
- ลอง Rescan (กด **B**)
- ลองเชื่อมต่อ USB ก่อน แล้วจึงเปลี่ยนเป็น WiFi

### ❌ Cannot find script directory

ถ้า PhoneBox.bat รันจากโฟลเดอร์อื่น และหาไฟล์ไม่เจอ:
- ให้มั่นใจว่า `PhoneBox.ps1` อยู่เดียวกับ `PhoneBox.bat`
- หรือเปลี่ยน `PHONEBOX_SCRIPT_DIR` ใน `.bat` file

---

## 🎨 Interface Preview

### Main Scanner
```
  ╔══════════════════════════════════════════════════════════════╗
  ║                                                              ║
  ║   ____  _                      ____                         ║
  ║  |  _ \| _ _   ___  _ __   ___| __ )  _____  __             ║
  ║  | |_) | '_ \ / _ \| '_ \ / _ \  _ \ / _ \ \/ /             ║
  ║  |  __/| | | | (_) | | | |  __/ |_) | (_) >  <              ║
  ║  |_|   |_| |_|\___/|_| |_|\___|____/ \___/_/\_\             ║
  ║                                                              ║
  ║       Smart Wireless Device Manager      v4.1               ║
  ╚══════════════════════════════════════════════════════════════╝
  
  ↑↓  Navigate    ENTER  Connect    ESC  Exit
```

### Connection Panel
```
  ╔══════════════════════════════════════════════════════════════╗
  ║              PHONEBOX  CONNECTION  CORE                     ║
  ╠══════════════════════════════════════════════════════════════╣
  ║   Device  :  Samsung Galaxy A12                             ║
  ║   Target  :  192.168.1.5                                    ║
  ║   Connect :  WiFi                                           ║
  ║   Latency :  Good (28ms)                                    ║
  ╠══════════════════════════════════════════════════════════════╣
  ║   Mode    :  Wireless Adaptive Stream                       ║
  ║   Quality :  1024p / 8 Mbps / 60 fps                        ║
  ║   Buffer  :  100ms                                          ║
  ║   Screen  :  OFF  (keeps WiFi chip active)                  ║
  ║   Keyboard:  UHID Hardware Emulation                        ║
  ╚══════════════════════════════════════════════════════════════╝
```

---

## ⚡ scrcpy Arguments Used

```powershell
--stay-awake              # Keep device awake
--keyboard=uhid           # Hardware keyboard emulation
--power-off-on-close      # Turn off screen when closing
--turn-screen-off         # Turn off device screen on connect
--max-size=<size>         # Max resolution
--video-bit-rate=<rate>   # Bitrate (Mbps)
--max-fps=<fps>           # Max frame rate
--video-buffer=<time>     # Buffer in milliseconds
```

---

## 🔐 Security Notes

- **Local Network Only**: PhoneBox ใช้งานเฉพาะ local network (ADB TCP)
- **ADB Authentication**: ต้องเปิด USB Debugging และยอมรับ RSA key บน device
- **No Cloud**: ไม่มีการส่งข้อมูลออก เฉพาะการเชื่อมต่อภายใน network เท่านั้น
- **Device Control**: เต็มการควบคุมหน้าจอ เหมือนเช่นเดียวกับการจัดเก็บบนอุปกรณ์

---

## 📊 ข้อมูลโปรเจค

| Item | Value |
|------|-------|
| **Version** | v4.1 |
| **Language** | PowerShell 98.7% |
| **Main Script** | PhoneBox.ps1 (38 KB) |
| **scrcpy** | v4.0 |
| **adb** | v37.0.0 |
| **License** | MIT (See LICENSE.txt) |

---

## 🤝 การจัดการแบตเตอรี่และอุณหภูมิ

- **Screen OFF**: ลดการใช้พลังงาน & ความร้อนสูงสุด
- **Adaptive Quality**: ปรับให้ WiFi เสถียรกว่า ลดการบัฟเฟอร์
- **USB Mode**: ใช้คุณภาพสูงสุด เหมาะสำหรับงานที่ต้องความแม่นยำ

---

## 📝 Commands Cheat Sheet

```powershell
# เปิด PhoneBox
.\PhoneBox.bat

# สแกนอุปกรณ์ด้วยตนเอง
.\scrcpy-win64-v4.0\adb.exe devices -l

# เชื่อมต่อ WiFi จาก USB
.\scrcpy-win64-v4.0\adb.exe -s <SERIAL> tcpip 5555
.\scrcpy-win64-v4.0\adb.exe connect <IP>:5555

# ตัดการเชื่อมต่อ
.\scrcpy-win64-v4.0\adb.exe disconnect <IP>:5555

# ดู scrcpy ช่วยเหลือ
.\scrcpy-win64-v4.0\scrcpy.exe --help
```

---

## ✨ Recent Updates (v4.1)

- ✅ ปรับปรุง UI banner และ status bar
- ✅ แสดง model name ของอุปกรณ์ (ถ้ามี)
- ✅ ตรวจสอบสถานะ port 5555 โดยอัตโนมัติ
- ✅ Adaptive quality ตามความเสถียรของ WiFi
- ✅ Automatic retry เมื่อการเชื่อมต่อหลุด (3 ครั้ง)
- ✅ ลดปัญหา Unicode/Thai characters

---

## 📧 Support

หากพบปัญหาหรือข้อเสนอแนะ:
1. ตรวจสอบ **Troubleshooting** section ด้านบน
2. ลองรัน `adb kill-server` และ restart
3. ตรวจสอบว่า scrcpy และ adb ใหม่ล่าสุด

---

## 📜 License

MIT License - ดู [LICENSE.txt](LICENSE.txt)

---

**Enjoy your seamless device management! 🎉**
