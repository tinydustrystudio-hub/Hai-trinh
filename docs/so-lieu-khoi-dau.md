# Số liệu khởi đầu cần cân bằng lại

Các số dưới đây chưa có trong GDD hoặc chỉ được ghi là "khởi đầu" trong kế hoạch tháng 1. Chúng đang được dùng
trong `data/*.tres` để chơi thử; khi cân bằng (bước 12) hoặc sau buổi chơi thử thì sửa ở file dữ liệu và cập nhật bảng này.

| Số | Giá trị | Nằm ở | Nguồn |
| --- | --- | --- | --- |
| Tốc độ Xuồng Cướp / Ca Nô Cảm Tử / Cua Giáp Gai | 0,8 / 1,5 / 0,4 ô/giây | `data/enemies/*.tres` | Kế hoạch mục 5.1, số mới cần ghi vào GDD |
| Độ Nổi mất khi lọt | 1 / 3 / 2 | `data/enemies/*.tres` | Kế hoạch mục 5.1, số mới |
| Độ Nổi khởi đầu | 20 | `data/maps/north_dock_layout.tres` | Kế hoạch mục 5.1 |
| Thời gian chuẩn bị trước đợt 1 | 10 giây | `data/waves/north_dock_waves.tres` | Chưa có trong GDD; đặt tạm |
| Thời gian nghỉ giữa hai đợt | 8 giây | `data/waves/north_dock_waves.tres` | Lấy theo chế độ vô tận (GDD mục 6.1) |
| Khoảng cách giữa hai con, độ trễ từng nhóm ở đợt 2–5 | 0,4–2 giây; 0–14 giây | `data/waves/north_dock_waves.tres` | Kế hoạch chỉ ghi đợt 1 (1,5 giây); còn lại đặt tạm |
| Chia địch cho từng luồng ở đợt 3–5 | xem file đợt | `data/waves/north_dock_waves.tres` | Kế hoạch chỉ ghi luồng nào có địch |
| 5 đợt ở Bến Bắc | cả bảng | `data/waves/north_dock_waves.tres` | Kế hoạch mục 5.1, "bản đầu" |
