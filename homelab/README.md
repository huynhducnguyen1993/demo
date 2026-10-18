# Homelab D.7 cho T9

Bộ máy chủ tự host cho điểm vận hành T9. Bảy lớp:

1. DNS: AdGuard Home
2. Proxy: Caddy
3. Bảng điều khiển: Homepage
4. Giám sát: Uptime Kuma
5. Nhật ký: Dozzle
6. Dữ liệu: PostgreSQL 16 và Redis 7, chỉ trong mạng nội bộ
7. Tùy chọn: Dockge (`quan-tri`) và RustDesk (`rustdesk`)

Máy chủ cần Docker Engine, Compose v2, cổng 80 và 53 còn trống. Mức máy tham chiếu: 4 nhân, 8 GB RAM.

## Lên stack

```bash
cd homelab
cp .env.example .env
```

Sửa `POSTGRES_PASSWORD` và `REDIS_PASSWORD`. Mật khẩu không chứa khoảng trắng, `$`, `"` hoặc `'`. Nếu máy chủ có IP LAN, đặt `BIND_IP` bằng IP đó và thêm IP vào `HOMEPAGE_ALLOWED_HOSTS`.

```bash
./scripts/len.sh
```

- Trang chủ qua IP máy chủ: `http://<ip-may-chu>/`
- Trình cài DNS lần đầu: `http://<ip-may-chu>:3000/`

Sau khi AdGuard cài xong, giao diện DNS chuyển về `http://dns.t9.lab/`. Thêm các dòng sau vào DNS rewrite của AdGuard, trỏ về IP máy chủ:

```text
dash.t9.lab
status.t9.lab
logs.t9.lab
dns.t9.lab
stacks.t9.lab
```

Đổi `t9.lab` nếu `LAB_DOMAIN` trong `.env` khác giá trị mẫu. File `/etc/hosts` trên máy quản trị dùng được khi chưa trỏ DNS cả mạng.

Trong Uptime Kuma, tạo status page có slug `t9` thì ô giám sát trên Homepage mới có số liệu. Trang chủ vẫn mở khi slug này chưa có.

## Profile

Dockge gắn Docker socket ở chế độ ghi. Chỉ bật trên máy lab:

```bash
./scripts/len.sh --quan-tri
```

Giao diện stack: `http://stacks.t9.lab/`.

RustDesk tự host, phục vụ remote desktop nội bộ:

```bash
docker compose --profile rustdesk up -d
docker compose exec rustdesk-hbbs cat /root/id_ed25519.pub
```

Dán khóa công khai vào ID Server / Key của client RustDesk. Cổng 21115, 21116/tcp, 21116/udp, 21117, 21118, 21119.

Mở PostgreSQL và Redis ra `127.0.0.1` khi cần nối từ ứng dụng trên chính máy chủ:

```bash
docker compose -f compose.yaml -f compose.dev.yaml up -d
```

## Kiểm tra

```bash
./scripts/kiem-tra.sh
docker compose logs -f caddy homepage
docker compose exec postgres pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB"
```

`kiem-tra.sh` luôn kiểm tra cú pháp Compose. Phần gọi HTTP chỉ chạy khi Docker daemon đang chạy và stack đã lên.

## Backup và phục hồi

```bash
./scripts/backup.sh
./scripts/restore.sh backups/postgres-YYYYMMDD-HHMMSS.sql
```

`backup.sh` ghi dump PostgreSQL, file RDB của Redis và cấu hình AdGuard vào `homelab/backups/`. Thư mục này không đưa vào Git. Snapshot đĩa không thay thế các file này.

## Dừng

```bash
docker compose --profile quan-tri --profile rustdesk down
```

Lệnh trên giữ volume. Thêm `-v` chỉ khi cố ý xóa dữ liệu PostgreSQL, Redis, AdGuard và Uptime Kuma.
