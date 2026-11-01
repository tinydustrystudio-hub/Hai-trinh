# Danh sách tài nguyên tạm (dành cho họa sĩ và nhà âm thanh)

Mọi thứ nhìn thấy và nghe thấy trong bản hiện tại là **đồ tạm dựng bằng code** (khối hộp, hình trụ, sóng bằng shader, tiếng tổng hợp). Tài liệu này liệt kê từng món, nó đang nằm ở đâu trong dự án và cần thay bằng gì, để họa sĩ làm đúng thứ và lập trình viên gắn vào mà không phải sửa lại logic.

Hình dáng, màu và tên gọi lấy từ `docs/art-direction/mui-neo-concept-pack.md` (bộ concept Mũi Neo); mọi tên asset đề nghị ở đây bám mục G của bộ concept. Luật chơi và số liệu không phụ thuộc vào đồ họa: thay đồ họa xong thì không phải cân bằng lại.

## 1. Quy ước chung

| Mục | Quy ước |
| --- | --- |
| Đơn vị | 1 ô = 4 đơn vị Godot. Mặt nước ở y = 0 |
| Màn hình | 1920×1080 ngang, camera cố định nghiêng 55°, có thu phóng và kéo |
| Định dạng mô hình | glTF 2.0 (`.glb`), trục Y hướng lên, tỉ lệ 1 đơn vị = 1 đơn vị Godot, gốc ở mực nước (trừ khi ghi khác) |
| Vật liệu | Dùng chung vật liệu, ưu tiên một atlas màu cho cả bộ để gộp lệnh vẽ; không dùng shader riêng cho mô hình (trừ khi trao đổi trước) |
| Ngân sách toàn cảnh | Tối đa 150 lệnh vẽ, 150.000 tam giác, 60 địch cùng lúc, tối đa 2 hiệu ứng MEGA đầy đủ cùng lúc. Hiện cảnh 60 địch dùng khoảng 52.000 đến 94.000 tam giác nên còn dư chỗ, nhưng điện thoại là ràng buộc chính |
| Dung lượng | Bản web không quá 40 MB (hiện 37 MB, riêng engine đã 36 MB), nên toàn bộ ảnh, mô hình và âm thanh cộng lại cần gọn dưới vài MB |
| Bảng màu | Xanh biển `#1F5F8B`, trắng ngà `#EDE6D6`, cam cứu hộ `#FF7A1A`, xám than `#3A4048`, vàng tiền; xem `ui/ui_style.gd` và `battle/map/alliance_fortress.gd` |
| Chữ | Mọi chữ qua bảng dịch `assets/translations/strings.csv` (tiếng Việt và tiếng Anh); họa sĩ không đưa chữ vào ảnh |

Mức ưu tiên: **A** phải thay trước khi phát hành, **B** nên thay, **C** giữ được nếu hết thời gian.

## 2. Mô hình 3D

Tất cả đang dựng bằng `MeshKit` (hộp, lăng trụ, vành, nón) tô bằng màu đỉnh, không có UV hay texture.

### 2.1 Đảo chính (Mũi Neo, lục giác)

| Tài nguyên | Hiện ở | Cần thay bằng | Ưu tiên |
| --- | --- | --- | --- |
| Thân đảo lục giác: phao nổi, sàn, đê chắn sóng, 6 tháp góc, 6 mỏm bến mang 6 bệ, 2 cần cẩu, phao cam | `battle/map/alliance_fortress.gd` (`build_fortress`) | `ENV_FORTRESS_HEX.glb`: bán kính 14 đơn vị (khoảng 3,5 ô), bệ lô cốt đặt đúng 6 vị trí trong `data/maps/north_dock_layout.tres` (`pad_positions`) | A |
| Trung Tâm Chỉ Huy kiêm hải đăng | `_tower` cùng file | `BLD_COMMAND_HUB.glb`, cao nhất đảo (khoảng 0,8 bán kính); phòng đèn là mesh riêng để phát sáng (`build_lamp`) | A |
| Tường Chắn Sóng, 5 cấp | `_base_and_wall` | `BLD_WAVE_SHIELD_L1..L5.glb`: bao cả vành ngoài, cao và dày dần, cấp 3 có chân chắn sóng, cấp 4 có đèn và tháp góc cao, cấp 5 có hàng kính | A |
| Xưởng Sửa Chữa, 5 cấp | `battle/map/fortress_buildings.gd` | `BLD_REPAIR_WORKS_L1..L5.glb` (băng chuyền, mái vòm, tay máy) | A |
| Trạm Năng Lượng Dòng Triều, 5 cấp | `alliance_fortress.gd` (`_turbine`, `_battery`, `_tidal_lines`) | `BLD_TIDAL_POWER_L1..L5.glb` (tua-bin, pin, ống cáp, vòng tụ sáng lam) | A |
| Xưởng Tàu, 5 cấp | `fortress_buildings.gd` (`_shipyard`) | `BLD_SHIPYARD_L1..L5.glb` (ụ nổi chữ U, cầu cẩu, thân tàu, hai ụ ở cấp 5) | A |
| Ra-đa, kho container, bể nước (vành trong) | `_radar`, `_containers`, `_tanks` | `BLD_SEA_RADAR`, `BLD_CARGO`, `PRP_WATER_TANK` (chưa nâng cấp được trong bản này) | B |
| Đèn đường, cọc neo, phao cam | `fortress_buildings.gd`, `_pier`, `_buoy` | `PRP_LAMP_POST`, `PRP_BOLLARD`, `PRP_BUOY` (dùng lại nhiều nơi, nên là mô hình nhỏ dùng chung) | B |

Mỗi công trình có 5 cấp hiển thị (cấp 1 đến 5). Nếu họa sĩ chỉ làm 3 bậc hình (cấp 1, 3, 5) thì báo để lập trình dùng chung hình cho cấp 2 và 4. Bản tạm đang đổi hình ở **cả bốn cấp 2, 3, 4, 5**, và đổi trên **toàn đảo** (tường bao cả vành, ống cáp chạy quanh mép), nên bản thật cũng nên đổi diện rộng, không chỉ một góc.

### 2.2 Đảo vệ tinh và tiện ích

| Tài nguyên | Hiện ở | Cần thay bằng | Ưu tiên |
| --- | --- | --- | --- |
| Nền đảo tròn nhỏ có xích neo, phao cam | `alliance_fortress.gd` (`_satellite`) | `SAT_BASE.glb`: bán kính 4 đơn vị (đường kính 2 ô), một bệ ở giữa | A |
| Trạm Ra-đa Tiền Tiêu | `battle/map/satellite_utilities.gd` | `SAT_RADAR_OUTPOST.glb` | A |
| Kho Thép (container) | cùng file | `SAT_STEEL_DEPOT.glb` | A |
| Trạm Phao Cứu Hộ | cùng file | `SAT_BUOY_STATION.glb` (cam là chính) | A |
| Đài Truyền Tin | cùng file | `SAT_COMMS_TOWER.glb` | A |
| Bến Thương Hội (chỉ dùng cho đảo lãnh thổ sau này) | cùng file | `SAT_TRADE_DOCK.glb` | C |
| Đèn đường, cuộn dây neo trên đảo vệ tinh | `build_props` | `PRP_LAMP_POST`, `PRP_ROPE_COIL` | B |

Nhìn từ xa mỗi tiện ích phải phân biệt được bằng hình bóng và màu nhấn, không trùng nhau.

### 2.3 Lô cốt (3 loại) và địch (3 loại)

| Tài nguyên | Hiện ở | Cần thay bằng | Ưu tiên |
| --- | --- | --- | --- |
| Đế lô cốt (dùng chung 3 loại) | `towers/tower_meshes.gd` (`base_mesh`) | `TWR_BASE.glb` | A |
| Súng Máy (bốn nòng) | `turret_mesh`, id `machine_gun` | `TWR_MACHINE_GUN_L1..L5.glb`; **nòng hướng về −Z**, trục xoay ở gốc mô hình, đặt ở độ cao `TURRET_Y` = 1,35 so với mặt bệ; đầu nòng cách trục 1,6 đơn vị (`BARREL_LENGTH`, nơi đạn bay ra); xoay quanh trục Y | A |
| Lô Cốt Keo | id `glue_sprayer` | `TWR_GLUE_SPRAYER_L1..L5.glb`, cùng quy ước trục | A |
| Lô Cốt Tia Sáng | id `light_beam` | `TWR_LIGHT_BEAM_L1..L5.glb`, cùng quy ước trục; tia sáng vẽ riêng nên mô hình chỉ cần thấu kính phát ở đầu | A |
| Xuồng Cướp | `enemies/enemy_meshes.gd`, hull `SKIFF` | `ENM_RAIDER_SKIFF.glb`: dài 0,8 ô, **mũi hướng về −Z**, gốc ở mực nước | A |
| Ca Nô Cảm Tử | hull `RAM` | `ENM_RAM_DRONE.glb`: dài 0,7 ô | A |
| Cua Giáp Gai | hull `CRAB` | `ENM_SPIKED_CRAB.glb`: dài 1,2 ô, rộng hơn thân | A |

Ngân sách đề xuất (tam giác): mỗi loại địch ≤ 600 (có thể 60 con cùng lúc), mỗi lô cốt ≤ 1.500 cả đế và đầu nòng, đảo chính ≤ 25.000, mỗi đảo vệ tinh ≤ 1.500. Địch nhìn từ rất xa (thu nhỏ hết cỡ) vẫn phải phân biệt được ba loại bằng hình bóng; nên dựng thử ngay trong cảnh thử 60 địch (`?stress`).

## 3. Hiệu ứng hình ảnh (shader và dựng bằng code)

Những cái này làm bằng shader và mesh phát sinh, **không cần họa sĩ vẽ lại ngay**; họa sĩ chỉ cần cho tham chiếu màu và cảm giác để lập trình chỉnh.

| Tài nguyên | Hiện ở | Ghi chú | Ưu tiên |
| --- | --- | --- | --- |
| Mặt nước (sóng, phản chiếu, bọt, mưa gợn) | `battle/ocean/water.gdshader`, `ocean.gd` | Có thể giữ; họa sĩ chỉnh màu qua `data/lighting/*.tres` | C |
| Ba texture nhiễu của nước (2 normal map, 1 nhiễu bọt) | `assets/textures/water_*.png` (dựng bằng `tools/bake_noise.gd`) | Có thể thay bằng texture vẽ tay liền mạch 256×256 hoặc 512×512 | C |
| Bọt quanh đảo, vệt đuôi tàu | `battle/map/foam.gdshader`, `enemies/wake.gdshader` | Giữ | C |
| Dải chỉ đường của địch, đèn hiệu | `battle/map/lane.gdshader`, `beacon*.gdshader` | Giữ, họa sĩ có thể đề nghị kiểu vạch mới | C |
| Vệt đạn, tia sáng, vũng keo, vòng tầm bắn | `fx/bullet_renderer.gd`, `beam_renderer.gd`, `glue_puddle.gdshader`, `range_circle.gdshader` | Nên có thiết kế riêng cho từng cấp lô cốt | B |
| MEGA (hào quang nhấp nháy, nổ) | `fx/mega_beacon.gdshader`, `mega_burst.gdshader` | Mỗi loại lô cốt cần một MEGA riêng khi làm bản thật | B |
| Mưa 3D, sét | `fx/rain_field.gd`, `lightning_overlay.gd` | Giữ | C |
| Ánh sáng bình minh, ban ngày, hoàng hôn; tối viền | `data/lighting/*.tres`, `fx/vignette.gdshader` | Họa sĩ chỉnh số màu trực tiếp trong tệp dữ liệu | B |

## 4. Giao diện

Tất cả vẽ bằng code (hộp bo góc, đường vẽ), không có ảnh.

| Tài nguyên | Hiện ở | Cần thay bằng | Ưu tiên |
| --- | --- | --- | --- |
| Nút nổi khối (chính cam, phụ xám than, khoá xám) | `ui/ui_style.gd` | Bộ nút 9-slice PNG (bình thường, bấm, khoá); kích thước tối thiểu 120 px ở độ phân giải gốc | A |
| Khung bảng, thẻ | `ui/ui_style.gd` (`panel_box`) | Khung 9-slice PNG | A |
| Đồng Tiền Vàng (mỏ neo) | `ui/coin_icon.gd` | `UI_COIN.png` hoặc SVG, hiện ở 48 px, nên có bản 96 px | A |
| Biểu tượng nút xác nhận, huỷ, nâng, bán, tạm dừng, ×2 | `ui/icon_button.gd`, `ui/hud.gd` | Bộ icon đồng bộ, cạnh 128 px, nền trong suốt | A |
| Thanh Độ Nổi, thanh Quá tải | `ui/buoyancy_bar.gd`, `fx/bar.gdshader` | Khung và nền thanh | B |
| Biểu tượng ba lô cốt trong vòng chọn | `ui/build_ring.gd` | Ba icon lô cốt, 128 px | A |
| Nền các menu (biển, hình lục giác mờ) | `ui/screens/menu_backdrop.gd` | Tranh nền hoặc cảnh 3D thật; giữ vùng trống bên trái cho tên game | B |
| Logo và tên game "Hải Trình" | `ui/screens/title_screen.gd` (chữ thường) | Logo PNG hoặc SVG, có bản tiếng Việt và tiếng Anh | A |
| Font chữ | font mặc định của Godot | Font hiển thị tiếng Việt đầy đủ dấu, giấy phép dùng được thương mại, nhúng được; một đậm cho tiêu đề, một thường cho nội dung | A |
| Icon ứng dụng, màn hình chờ | `icon.svg` | Icon Android (adaptive, 432×432) và icon web | A |

Giao diện cố định ở bố cục: hành động chính ở góc dưới bên phải, nút phụ ở góc dưới bên trái, mọi nút ≥ 120 px. Họa sĩ không đổi vị trí; chỉ đổi vẻ ngoài.

## 5. Âm thanh

| Tài nguyên | Hiện ở | Cần thay bằng | Ưu tiên |
| --- | --- | --- | --- |
| Tiếng bắn | `fx/sound_board.gd` (`make_shot`, tổng hợp) | `SFX_SHOT_*.ogg` (nên có ba biến thể để đỡ lặp), mono, 44,1 kHz, ≤ 0,4 giây | A |
| Tiếng nổ khi hạ địch | `make_explosion` | `SFX_EXPLOSION_*.ogg`, ≤ 0,8 giây | A |
| Tiếng MEGA | `make_mega` | `SFX_MEGA.ogg`, ≤ 1,5 giây | A |
| Sấm | `make_thunder` | `SFX_THUNDER.ogg`, ≤ 3 giây | B |
| Tiếng bấm nút | `make_click` | `SFX_UI_CLICK.ogg`, ≤ 0,15 giây | A |
| Nhạc nền | `assets/audio/music_theme.ogg` (tạo bằng `tools/make_music.py`) | Nhạc lặp liền mạch, `.ogg`, 1–2 phút, ≤ 1 MB; theo từng hồi nếu có | A |
| Tiếng biển, gió, mưa, tiếng dập dềnh của đảo | chưa có | Có thể thêm ở bản thật: một lớp nền biển lặp, thêm mưa và gió theo thời tiết | B |

Mỗi tiếng bắn, nổ phát nhiều lần mỗi giây nên cần ngắn, không có đuôi vang dài. Tổng dung lượng âm thanh nên dưới 2 MB.

## 6. Cách đưa tài nguyên mới vào

1. Họa sĩ đặt tệp vào `assets/models/`, `assets/ui/` hoặc `assets/audio/` theo tên trong cột "Cần thay bằng", báo lập trình viên.
2. Lập trình viên sửa đúng nơi ở cột "Hiện ở" để nạp tệp thay cho đoạn dựng bằng code. Luật chơi, dữ liệu `.tres`, vị trí bệ và logic trận **giữ nguyên**; đã có test (`tests/`) kiểm tra kích thước mô hình, hướng nòng (−Z), vị trí bệ và ngân sách tam giác của đảo chính; hướng mũi tàu (−Z) chưa có test nên cần kiểm bằng mắt trong cảnh thử.
3. Chạy `godot --headless --import` rồi chạy lại bộ test; mở cảnh thử 60 địch (`?stress`) để đo khung hình trước khi gộp.
4. Chữ mới (tên công trình, mô tả) thêm vào `assets/translations/strings.csv`, import lại và commit các tệp `.translation` đi kèm.

## 7. Những gì giữ được, không cần làm lại

- Cấu trúc dữ liệu: `data/*.tres` (lô cốt, địch, đợt, thời tiết, ánh sáng, bản đồ, công trình), bảng dịch.
- Bảng màu và tỉ lệ (đảo, bệ, ô, tầm bắn), bố cục màn hình và luồng menu.
- Mọi logic và test.

## 8. Mô hình dựng sẵn bằng Blender (thử nghiệm)

Có bộ kịch bản Blender chạy không giao diện trong `tools/blender/` để dựng mô hình tạm đúng kích thước, trục và màu đỉnh, xuất `.glb` vào `assets/models/`. Họa sĩ mở lại bằng Blender (File → Import → glTF 2.0) để chỉnh tiếp, hoặc thay hẳn bằng mô hình riêng cùng tên tệp. Game tự dùng `assets/models/enm_<id địch>.glb` nếu có, không thì dựng bằng code như cũ.

- Cài: `python3 -m venv venv && venv/bin/pip install -r tools/blender/requirements.txt` (module `bpy`, Python 3.13).
- Dựng: `venv/bin/python tools/blender/build_models.py [tên mô hình]`.
- Quy ước và hàm dựng khối: `tools/blender/kit.py` (toạ độ Godot, mũi và nòng hướng −z, màu đỉnh sRGB đã bù cho bộ xuất glTF).
- Tệp `.glb` và `.png` lưu bằng Git LFS (xem `.gitattributes`).
