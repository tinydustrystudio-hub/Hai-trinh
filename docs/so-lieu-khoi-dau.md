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
| Chia đợt 5 cho 4 luồng (mỗi luồng 3 Xuồng Cướp; Ca Nô ở Đông, Tây; Cua ở Bắc, Nam) | xem file đợt | `data/waves/north_dock_waves.tres` | GDD mục 8.6 chỉ ghi đợt 5 dùng cả 4 luồng |
| Chiều dài luồng: Bắc 63, Nam 62, Đông và Tây khoảng 93 đơn vị (16–24 ô) | xem file bản đồ | `data/maps/north_dock_layout.tres` | Bố cục mới ở GDD mục 8.6; luồng Đông, Tây dài hơn để bắt đầu ngoài mép màn hình điện thoại 19,5:9 |
| Lô Cốt Keo: phun mỗi 0,5 giây (tốc bắn 2) | 2 lần/giây | `data/towers/glue_sprayer.tres` | Kế hoạch mục 5.2 |
| Lô Cốt Keo cấp 2–4: thời gian chậm 2 giây; sát thương cấp 2 = 2, cấp 4 = 4 mỗi giây | xem file | `data/towers/glue_sprayer.tres` | GDD mục 3.4 chỉ ghi ở cấp 1 và 3; lấy theo cấp liền trước |
| Vũng keo tồn tại bằng thời gian chậm (2 giây) | 2 giây | `towers/glue_sprayer.gd` (theo `slow_duration`) | Đặt tạm |
| Quét Ngang (Mưa Đạn): hình quạt 90°, tầm bằng tầm lô cốt, sát thương bằng một phát | 90°; ×1 | `data/towers/machine_gun.tres` | GDD mục 3.3 chỉ ghi "quét một hình quạt, trúng mọi địch phía trước" |
| Hồ Keo: sát thương 4 mỗi giây, thời gian chậm 2 giây | 4; 2 giây | `data/towers/glue_sprayer.tres` | GDD mục 3.4 không ghi; lấy theo cấp 4 |
| Keo Ăn Mòn: thời gian chậm 2 giây | 2 giây | `data/towers/glue_sprayer.tres` | GDD không ghi; lấy theo cấp 4 |
| Trận chậm còn 30% khi chọn nhánh | 0,3 | `battle/battle.gd` (`BRANCH_CHOICE_SPEED`) | GDD mục 7.10 (luật giao diện, không phải số cân bằng) |
| 5 đợt ở Bến Bắc | cả bảng | `data/waves/north_dock_waves.tres` | Kế hoạch mục 5.1, "bản đầu" |
