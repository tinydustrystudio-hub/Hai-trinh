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
| Khoảng cách giữa hai con, độ trễ từng nhóm ở đợt 2–5 | 0,2–1 giây (Cua cách 3 giây); 0–14 giây | `data/waves/north_dock_waves.tres` | Kế hoạch chỉ ghi đợt 1; góp ý 3 gấp đôi số địch nên khoảng cách còn một nửa (đợt 1: 0,75 giây) |
| Chia địch cho từng luồng ở đợt 3–5 | xem file đợt | `data/waves/north_dock_waves.tres` | Kế hoạch chỉ ghi luồng nào có địch |
| Chia đợt 5 cho 4 luồng (mỗi luồng 6 Xuồng Cướp; Ca Nô ở Đông, Tây; Cua ở Bắc, Nam) | xem file đợt | `data/waves/north_dock_waves.tres` | GDD mục 8.6 chỉ ghi đợt 5 dùng cả 4 luồng |
| Chiều dài luồng: cả 4 luồng khoảng 126–128 đơn vị (31–32 ô) | xem file bản đồ | `data/maps/north_dock_layout.tres` | Góp ý 3 của đạo diễn (31/10): bốn phía cân bằng như nhau, bản đồ rộng hơn để đường đi dài hơn |
| Đảo vệ tinh theo màn Hồi I (đề xuất, người duyệt xem): cấp sẵn / tối đa = 4/8, 4/8, 4/9, 5/9, 5/10, 5/10, 6/11, 6/12 cho 8 nhiệm vụ | `satellite_free_count`, `satellite_max_count` trong `data/maps/*.tres` | Người duyệt chốt 31/10: số đảo tùy màn, màn 1 là 4/8; các màn sau là đề xuất theo độ khó, chờ xem |
| Giá mua đảo vệ tinh (vật phẩm, mua một lần là có mãi): đảo mua thêm thứ nhất (đảo thứ 5 của màn 1) 250 Tiền Vàng, mỗi đảo sau +50 (250, 300, 350, 400) | `data/economy.tres` (`island_buy_base`, `island_buy_step`) | Người duyệt chốt 31/10 |
| Xê dịch của địch: biên độ ±1,2 đơn vị, bước sóng 24–44 | `data/combat_rules.tres` | Góp ý 5; số đặt tạm |
| Nâng cấp công trình Đảo Chính: lên cấp 2 / 3 / 4 / 5 = 200 / 320 / 510 / 820 Tiền Vàng (tổng 1.850); công thức 200 × 1,6^(cấp − 2), làm tròn tới 10, nhân hệ số riêng từng công trình (mặc định 1,0) | `data/economy.tres` (`building_base_cost`, `building_growth`) | Người duyệt chọn dùng số tạm (31/10); GDD chưa có giá |
| Tầm bắn mọi lô cốt: số gốc GDD × 1,25 | `data/towers/*.tres`, `TowerData.RANGE_BONUS` | Người duyệt chốt 1/11 |
| Thời tiết: độ mấp mô mặt nước ×1 / ×2,6 / ×3,6 (gấp đôi bản đầu, người duyệt 1/11); độ cao sóng ×1 / ×4,5 / ×10 (đỉnh bão khoảng 1,5; lặng dần quanh đảo 9 đơn vị); tốc độ sóng ×1 / ×0,85 / ×0,55; đảo dập dìu ×1 / ×1,4 / ×2,4; gió quay 0 / 0,15 / 0,35 rad, chu kỳ 40 giây | `data/weather/*.tres` | Người duyệt 1/11: bão sóng to, đảo dập dìu nhiều, tốc độ chậm; số đặt tạm |
| Phí dùng đảo tự đặt trong một màn: thứ 1 là 200 Tiền Vàng, mỗi đảo sau +50 (200, 250, 300…); đảo cấp sẵn miễn phí; đảo đã mua tồn tại mãi | `data/economy.tres` (`island_use_base`, `island_use_step`) | Người duyệt chốt 31/10 |
| Phí dời đảo vệ tinh: 1/2 giá xây lô cốt rẻ nhất (hiện 30 Tiền Vàng) | `data/economy.tres` (`island_move_ratio`), tính từ `data/towers/*.tres` | Người duyệt chốt 31/10 |
| Giãn cách địch: khoảng trống tối thiểu 0,5 thân; +0,25 thân mỗi lần máu gấp đôi 60 | `data/combat_rules.tres` | Góp ý 4 (mục 14); số 0,25 đặt tạm. Làm đàn dày sẽ xếp hàng ở đầu luồng nên nhịp địch tới chậm hơn bản gấp đôi số địch trước đó, cần cân bằng lại |
| Dập dìu của đảo: độ cao ×0,6, độ nghiêng ×0,5 theo sóng, tối đa 1,5°, hệ số theo cỡ đảo = 4 ÷ bán kính | xem `battle/map/island.gd` | Góp ý 4 (mục 15); số đặt tạm |
| Sóng: độ cao tối đa 0,34; tốc độ mỗi lớp ×0,65–1,35; đợt sóng lớn đổi biên độ ±30–60% | xem `battle/ocean/ocean.gd` | Góp ý 4 (mục 11); số đặt tạm |
| Đảo vệ tinh: mỗi luồng một đảo, cách tâm đảo chính khoảng 43–46 đơn vị | xem file bản đồ | `data/maps/north_dock_layout.tres` | Góp ý 3; GDD mục 8.6 chỉ ghi 4 đảo vệ tinh |
| Lô Cốt Keo: phun mỗi 0,5 giây (tốc bắn 2) | 2 lần/giây | `data/towers/glue_sprayer.tres` | Kế hoạch mục 5.2 |
| Lô Cốt Keo cấp 2–4: thời gian chậm 2 giây; sát thương cấp 2 = 2, cấp 4 = 4 mỗi giây | xem file | `data/towers/glue_sprayer.tres` | GDD mục 3.4 chỉ ghi ở cấp 1 và 3; lấy theo cấp liền trước |
| Vũng keo tồn tại bằng thời gian chậm (2 giây) | 2 giây | `towers/glue_sprayer.gd` (theo `slow_duration`) | Đặt tạm |
| Quét Ngang (Mưa Đạn): hình quạt 90°, tầm bằng tầm lô cốt, sát thương bằng một phát | 90°; ×1 | `data/towers/machine_gun.tres` | GDD mục 3.3 chỉ ghi "quét một hình quạt, trúng mọi địch phía trước" |
| Hồ Keo: sát thương 4 mỗi giây, thời gian chậm 2 giây | 4; 2 giây | `data/towers/glue_sprayer.tres` | GDD mục 3.4 không ghi; lấy theo cấp 4 |
| Keo Ăn Mòn: thời gian chậm 2 giây | 2 giây | `data/towers/glue_sprayer.tres` | GDD không ghi; lấy theo cấp 4 |
| Trận chậm còn 30% khi chọn nhánh | 0,3 | `battle/battle.gd` (`BRANCH_CHOICE_SPEED`) | GDD mục 7.10 (luật giao diện, không phải số cân bằng) |
| 5 đợt ở Bến Bắc | cả bảng | `data/waves/north_dock_waves.tres` | Kế hoạch mục 5.1, "bản đầu", rồi gấp đôi số địch theo góp ý 3 |

## Thử cân bằng bằng người chơi giả (31/10/2026)

Chạy bằng `tests/test_balance.gd` và `tests/bots/battle_bot.gd`, trên bản đồ và 5 đợt sau góp ý 3 (luồng dài 31 ô, gấp đôi số địch).
Người chơi giả có chiến thuật (SMART) chuẩn bị trước một đợt, đặt lô cốt theo luồng, thêm Keo cho luồng có Ca Nô hoặc Cua,
nâng Súng Máy giữ các luồng đó lên cấp 3 và kích MEGA khi có từ 3 địch trong tầm. Người chơi qua loa (NAIVE) chỉ đặt Súng Máy theo thứ tự bệ.

| Thử | SMART | NAIVE |
| --- | --- | --- |
| Số GDD hiện tại | Thua ở đợt 4 | Thua ở đợt 2 |
| Thép khởi đầu 300 | Thua ở đợt 4 | Thua ở đợt 2 |
| Thưởng mỗi đợt 40 | Thua ở đợt 4 | Thua ở đợt 2 |
| Thép mỗi tàu ×1,5 | Thua ở đợt 4 | Thua ở đợt 2 |
| Dàn thưa các cụm Ca Nô ở đợt 2, 4, 5 | Thua ở đợt 5 | Thua ở đợt 2 |
| Sát thương Súng Máy ×1,5 | Thua ở đợt 5 | Thua ở đợt 2 |
| Máu Xuồng Cướp và Ca Nô ×0,7 (42) | Thua ở đợt 5 | Thua ở đợt 2 |
| Máu Xuồng Cướp và Ca Nô ×0,5 (30) | **Thắng, còn 5/20 Độ Nổi** | Thua ở đợt 2 |

Nút thắt là sát thương, không phải Thép: Súng Máy không hạ kịp cụm 6 Ca Nô Cảm Tử chạy 1,5 ô/giây.
Đạo diễn chọn giữ số GDD, cân bằng lại sau buổi chơi thử trên điện thoại.
