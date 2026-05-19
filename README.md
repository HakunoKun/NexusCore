# PhoneBox / scrcpy Toolkit

ชุดนี้เป็นเครื่องมือบน Windows สำหรับจัดการและ mirror หน้าจอ Android ด้วย `scrcpy` และ `adb` พร้อมสคริปต์เสริมสำหรับตรวจสอบ/อัปเดต dashboard ของ Pocket WiFi หรืออุปกรณ์ Android ที่คุณมีสิทธิ์ดูแล

> ใช้งานกับอุปกรณ์ของตัวเองหรืออุปกรณ์ที่ได้รับอนุญาตเท่านั้น

## โครงสร้างไฟล์

```text
.
├── PhoneBox.bat                 # launcher สำหรับเปิด PhoneBox.ps1
├── PhoneBox.ps1                 # เมนูหลักสำหรับหาอุปกรณ์และเปิด scrcpy
├── PocketRecon.bat              # launcher สำหรับเปิด PocketRecon.ps1
├── PocketRecon.ps1              # ชุดตรวจสอบ ADB/Network และ deploy dashboard
├── Fix-Dashboard.bat            # อัปเดต api.sh ไปยัง dashboard บนอุปกรณ์
├── PocketServer/
│   ├── busybox-arm
│   └── pocket_www/
│       ├── index.html
│       └── cgi-bin/api.sh
├── Logs_and_Dumps/              # ไฟล์ log/dump ที่เก็บไว้จากอุปกรณ์
└── scrcpy-win64-v4.0/
    ├── scrcpy.exe
    └── adb.exe
```

## สิ่งที่ต้องมี

- Windows 10/11
- เปิด USB debugging บนอุปกรณ์ Android
- กดยอมรับ RSA debugging prompt บนอุปกรณ์เมื่อเสียบ USB
- ถ้าจะใช้ WiFi/ADB TCP ให้คอมพิวเตอร์กับอุปกรณ์อยู่ใน network ที่เข้าถึงกันได้

ตรวจสอบ ADB:

```bat
.\scrcpy-win64-v4.0\adb.exe devices -l
```

ตรวจสอบ scrcpy:

```bat
.\scrcpy-win64-v4.0\scrcpy.exe --version
```

## วิธีใช้งานเร็ว

### 1. เปิด PhoneBox

ดับเบิลคลิก `PhoneBox.bat` หรือเปิดจาก terminal:

```bat
.\PhoneBox.bat
```

เมนูจะสแกนอุปกรณ์ผ่าน USB, ADB-over-WiFi และ ARP scan จากนั้นเลือกอุปกรณ์แล้วกด Enter เพื่อเปิด `scrcpy`

โหมดที่ใช้:

- USB: คุณภาพสูงกว่า, เปิด `--turn-screen-off`, เหมาะกับการต่อสาย
- WiFi: ลด bitrate/fps เพื่อให้เสถียรกว่า, เหมาะกับอุปกรณ์ Pocket WiFi หรือ network ช้า
- Manual IP: ใส่ IP เองเมื่อสแกนไม่เจอ

### 2. ใช้ PocketRecon

```bat
.\PocketRecon.bat
```

เมนูหลักมีงานสำคัญ:

- Network Scan: ping, scan port, probe HTTP endpoint
- ADB Connect: ต่อ ADB และอ่าน device fingerprint
- APN Fix: ลองตั้งค่า APN ผ่าน ADB
- Server Deploy: push dashboard ไปที่ `/data/local/tmp/www` และเปิด port `9000`
- Full Device Dump: ดึง log, property, package list และ endpoint บางส่วน

ค่า target ปัจจุบันอยู่ใน `PocketRecon.ps1`:

```powershell
$target = "192.168.100.66"
```

ถ้าอุปกรณ์อยู่คนละ IP ให้แก้ค่านี้ก่อนรัน module network/dashboard

### 3. อัปเดต Dashboard อย่างเดียว

ใช้เมื่อ deploy server ไว้แล้วและต้องการอัปเดต `api.sh`:

```bat
.\Fix-Dashboard.bat
```

หลังรันสำเร็จ เปิด:

```text
http://192.168.100.1:9000
```

ถ้า IP ของอุปกรณ์ไม่ใช่ `192.168.100.1` ให้เปิดด้วย IP จริงของอุปกรณ์แทน

## Debug / สิ่งที่แก้แล้ว

- แยก `PhoneBox.ps1` และ `PocketRecon.ps1` ออกจาก launcher `.bat` เพื่อไม่ให้ `cmd.exe` อ่านโค้ด PowerShell เป็น batch command
- แก้ launcher ของ `PhoneBox.bat` และ `PocketRecon.bat` ให้เป็นตัวเปิด `.ps1` แบบสั้นและแน่นอน
- เพิ่ม `chcp 65001` และตั้ง `InputEncoding/OutputEncoding` เป็น UTF-8 เพื่อลดปัญหาตัวอักษรไทย/กรอบ UI เพี้ยน
- แก้ `PhoneBox.bat` ตอนใช้อุปกรณ์ `ADB_NET` ให้ส่ง serial เต็ม เช่น `192.168.1.23:5555` เข้า `scrcpy -s`
- แก้ `PocketRecon.bat` ให้หา `PocketServer` ด้วย absolute path จากโฟลเดอร์สคริปต์
- แก้ `PocketRecon.bat` ตอนรวมคำสั่ง APN ให้จัดการบรรทัดแบบ Windows CRLF ได้ถูกต้อง
- แก้ `Fix-Dashboard.bat` ให้ใช้ path จาก `%~dp0` จึงรันได้แม้เปิดจากโฟลเดอร์อื่น

## Troubleshooting

ถ้า `adb devices` ไม่เจออุปกรณ์:

```bat
.\scrcpy-win64-v4.0\adb.exe kill-server
.\scrcpy-win64-v4.0\adb.exe start-server
.\scrcpy-win64-v4.0\adb.exe devices -l
```

ถ้าขึ้น `unauthorized` ให้ปลดล็อกจออุปกรณ์แล้วกด Allow USB debugging

ถ้า WiFi mode ต่อไม่ได้:

```bat
.\scrcpy-win64-v4.0\adb.exe -s SERIAL tcpip 5555
.\scrcpy-win64-v4.0\adb.exe connect DEVICE_IP:5555
```

เปลี่ยน `SERIAL` และ `DEVICE_IP` ให้ตรงกับอุปกรณ์จริง

ถ้า dashboard เปิดไม่ได้:

- เช็กว่า module `Server Deploy` รันสำเร็จ
- เช็กว่า port `9000` เปิดบน IP ของอุปกรณ์
- รัน `Fix-Dashboard.bat` เพื่อ push `api.sh` ใหม่

## สถานะที่ตรวจในเครื่องนี้

- `scrcpy`: v4.0
- `adb`: 1.0.41 / 37.0.0
- พบอุปกรณ์ ADB 1 เครื่อง: `V2205`
