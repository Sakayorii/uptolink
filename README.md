# Hướng Dẫn Deploy Và Chạy SkibidiTask Trên VPS Mới

## 1. Yêu Cầu Hệ Thống
- Cài đặt **Node.js** (phiên bản >= 18).
- Cài đặt **PostgreSQL** (khuyến nghị phiên bản 15 hoặc 16).
- Mở Terminal (PowerShell hoặc CMD) để chạy lệnh.

---

## 2. Phục Hồi Cơ Sở Dữ Liệu (Database)
File dữ liệu cũ của bạn đã được backup tại `database_backup.sql`. Để nạp lại dữ liệu vào VPS mới:

1. Mở `pgAdmin` hoặc công cụ dòng lệnh (psql) của PostgreSQL.
2. Tạo một Database mới tên là `skibiditask`.
3. Phục hồi (Restore) từ file `database_backup.sql` vào Database vừa tạo.
*(Nếu dùng lệnh: `psql -U postgres -d skibiditask -f database_backup.sql`)*

---

## 3. Chạy Các Server
Dự án được chia thành 4 thư mục riêng biệt: `api`, `web`, `admin`, và `bot`. Mở 4 cửa sổ Terminal riêng lẻ và cd vào từng thư mục.

### A. API Server (Backend)
```bash
cd api
npm install
npx prisma generate
npm run start
```
*Port mặc định: 9998*

### B. Web Server (Frontend cho User)
```bash
cd web
npm install
npm run start
```
*Port mặc định: 9999*

### C. Admin Server (Frontend cho Admin)
```bash
cd admin
npm install
npm run start
```
*Port mặc định: 9997*

### D. Discord Bot
```bash
cd bot
npm install
npx prisma generate
npm run start
```

---

## 4. Hướng Dẫn Chạy Cloudflare Tunnels (Dành cho từng Folder)
Mỗi folder (`admin`, `api`, `web`) đã được tích hợp sẵn file `cloudflared.exe` và cấu hình riêng (`config.yml`). 
Vì mỗi config đã trỏ đến một `credentials file (.json)` khác nhau, bạn không cần phải truyền thêm tham số UUID, chỉ cần đứng tại thư mục đó và gõ lệnh run.

Mở thêm 3 cửa sổ Terminal (dành cho 3 tunnel):

**Tunnel 1: Dành cho API**
```bash
cd api
cloudflared.exe tunnel run
```

**Tunnel 2: Dành cho Web User**
```bash
cd web
cloudflared.exe tunnel run
```

**Tunnel 3: Dành cho Admin Panel**
```bash
cd admin
cloudflared.exe tunnel run
```

*Lưu ý: Nếu bạn muốn chạy tunnel dưới dạng dịch vụ ngầm (Background Service) trên Windows để không phải treo cửa sổ Terminal, hãy chạy lệnh:*
`cloudflared.exe service install`
*Tuy nhiên, việc cài đặt service yêu cầu chạy PowerShell dưới quyền Administrator.*

---

## Lưu ý quan trọng về Bảo Mật
- Không chia sẻ các file `.env` hoặc các file `.json` chứa thông tin Cloudflare Tunnels.
- Trên VPS mới, nhớ đổi lại thông tin đăng nhập PostgreSQL trong các file `.env` nếu password có thay đổi.
