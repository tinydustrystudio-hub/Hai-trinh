# Mũi Neo – Concept Art Pack (Liên Minh Mũi Neo)

Chuẩn mỹ thuật cho căn cứ Mũi Neo. Nguồn: `docs/gdd.md` mục 5.3, 5.4, 8.2, 8.6; `docs/ke-hoach-thang-1.md`; code dựng đảo hiện có (chỉ để đối chiếu, không sửa). Chỉ là tài liệu concept: chưa có model, không đổi bản đồ trận.

## A. Visual identity

- **Phong cách:** 3D stylized semi-realistic. Khối đơn giản, vật liệu có chiều sâu, đọc rõ trên điện thoại. Công nghệ hàng hải tương lai, không fantasy. Công trình dân sự, cứu hộ, nghiên cứu; không vũ khí.
- **Ánh sáng:** nắng ấm từ phía trên trái, ánh trời lạnh bù. Mọi ánh sáng phát ra từ nguồn nhìn thấy được (đèn, kính, lõi), không có quầng sáng vô cớ.
- **Camera:** nghiêng khoảng 55°. Hình bóng phải rõ khi nhìn từ trên xuống và khi thu nhỏ.
- **Vật liệu:** thép sơn, composite, kính, cao su. Gỉ nhẹ ở chân sát mặt nước; không bóng loáng như đồ chơi.

| Tên | Hex | Vai trò |
| --- | --- | --- |
| Sea Blue | #1F5F8B | Thân phao, mái, mảng lớn |
| Ivory | #EDE6D6 | Sàn, tường, đê chắn sóng |
| Rescue Orange | #FF7A1A | Chỉ nhấn: viền, sọc, phao, mốc cần chạm |
| Dark Graphite | #3A4048 | Khung, cơ khí, bóng đổ vật liệu |

- **Tỉ lệ:** khoảng 55% Ivory, 25% Sea Blue, 12% Graphite, tối đa 8% cam. Phát sáng chỉ có vàng ấm (đèn) và lam nhạt (thủy âm, lõi); mỗi công trình tối đa một màu phát sáng.
- **Dấu hiệu phe:** pháo đài lục giác nhiều vành, hải đăng, sọc cam, phao cứu hộ. Phe khác đổi hình khối, vật liệu, bảng màu (xem GDD 8.6) nhưng giữ cùng quy tắc A–H.
- **Cấm:** chữ, số, logo, watermark trong hình; sao chép tài sản của game hoặc phim khác.

## B. Cấu trúc Đảo Chính

Nhìn một giây nhận ra: lục giác trắng ngà, viền cam, tháp hải đăng ở giữa, các mỏm bến tỏa ra như bánh lái.

| Lớp | Nội dung |
| --- | --- |
| Dưới nước | Khung nổi và cụm phao chịu lực hình lục giác, gờ sẫm sát mặt nước, dây xích neo động |
| Tầng 0 (sàn) | Sàn ivory, lối đi lát tấm, đường nối các module |
| Vành ngoài | Đê chắn sóng thấp, sọc cam mặt ngoài, pháo đài góc ở 6 đỉnh, khe đê mở ra 6 mỏm bến; cần cẩu, cọc neo, phao cam |
| Vành trong | Tầng hai lục giác xoay 30°, viền cam; khối công trình xếp vòng quanh |
| Trung tâm | Trung Tâm Chỉ Huy kết hợp hải đăng, điểm cao nhất của đảo |

- **Vị trí cố định theo GDD 5.3:** 1 Trung Tâm giữa; 8 ô công trình quanh trung tâm; 12 ô trang trí nhỏ; bệ lô cốt ở rìa; một số vị trí mô-đun trống ở vành ngoài để mở rộng.
- **Gán 8 ô quanh trung tâm (đề xuất, GDD chưa gán chi tiết):** Khiên Chắn Sóng ở rìa hướng biển; Xưởng Sửa Chữa và Xưởng Tàu gần bến; Trạm Năng Lượng ở rìa nước; Radar ở điểm cao; Sân Bay ở dải bằng phía đông; Trạm Cộng Hưởng ở mỏm; Viện Giếng Sâu sau Trung Tâm.
- **Chiều cao:** sàn thấp nhất, đê chắn sóng +1 đơn vị, tầng hai +1,3, các khối công trình +1,5 đến 3, tháp chỉ huy cao nhất (khoảng 0,8 bán kính đảo). Mỗi tầng phải thấy rõ khi nhìn 55°.
- **Kết nối module:** cầu nối tấm thép có lan can dây, khớp nối cao su vàng cam, ống cáp chạy dọc mép.
- **Đối chiếu code (tham khảo):** pháo đài bán kính 14 đơn vị (khoảng 3,5 ô), 6 mỏm bến mang 6 bệ, 4 đảo vệ tinh. Concept thể hiện bản đầy đủ; bản đồ trận giữ nguyên.

## C. Chín công trình hỗ trợ

Cấp 1 / 3 / 5 theo GDD 5.3 và 8.2. Phần đổi khi nâng cấp ghi sau mũi tên.

| ID | Vai trò | Hình bóng | Vật liệu, màu | Cấp 1 → 3 → 5 | Phân kỳ |
| --- | --- | --- | --- | --- | --- |
| BLD_COMMAND_HUB | Chỉ huy, hải đăng | Tháp tròn thon, mũ đèn | Ivory, Sea Blue, kính, viền cam | Tháp thấp, cột cờ → thêm tầng kính quan sát → tháp cao, vòng đèn hải đăng quay | MVP |
| BLD_WAVE_SHIELD | Giảm sóng | Hàng trụ nghiêng, thấp | Graphite, ivory, cao su đen | Một trụ → ba trụ, màng sóng mờ → hàng trụ bao kín mặt trước | MVP |
| BLD_REPAIR_WORKS | Sửa chữa, vật liệu | Hộp dài có cẩu chữ L | Thép sơn Sea Blue, Graphite | Lán thép, cẩu nhỏ → thêm băng chuyền → mái vòm, cánh tay robot | MVP |
| BLD_TIDAL_POWER | Điện dòng triều | Cột turbine trên phao | Composite ivory, Graphite, tụ lam nhạt | Một turbine → hai turbine, khối pin → cụm turbine, tụ phát sáng | MVP |
| BLD_SHIPYARD | Đóng và bảo trì tàu | Ụ nổi chữ U, cầu cẩu | Thép Sea Blue, ivory, Graphite | Ụ nổi, cẩu → thêm thân tàu đang đóng → hai ụ, tàu tuần tra neo sẵn | MVP |
| BLD_SEA_RADAR | Quan sát, liên lạc | Đĩa tròn trên cột | Ivory, Graphite, kính | Đĩa radar quay → thêm chảo vệ tinh → tháp radar pha, hai chảo | Sau |
| BLD_DRONE_FIELD | Drone khảo sát dân dụng | Dải phẳng, nhà chứa | Ivory, Sea Blue, vạch cam | Bãi đáp → đường băng ngắn → đường băng, nhà chứa, tháp điều phối | Sau |
| BLD_TIDE_RESONANCE | Nghiên cứu thủy âm | Cột mảnh, vòng đồng tâm | Graphite, kính, vòng phát lam | Một cột thủy âm → vòng phát đồng tâm → tháp vòng phát sáng lam | Sau |
| BLD_DEEP_WELL_LAB | Nghiên cứu Giếng Sâu | Cụm tròn thấp, mái kính | Ivory, Graphite, kính, lõi lam | Phòng thí nghiệm nhỏ → buồng cách ly → tổ hợp có lõi phát sáng giữa | Sau |

- **MVP (5 công trình):** Trung Tâm, Khiên, Xưởng Sửa Chữa, Trạm Năng Lượng, Xưởng Tàu (GDD 8.2).
- **Hoạt ảnh nhẹ:** đèn quay; sóng vỡ; tia hàn; cánh quạt; cẩu di chuyển; đĩa quay; drone; vòng sóng; lõi nhấp nháy. Chỉ concept hình tĩnh ở bước này.
- **Cấm:** vũ khí, phương tiện tấn công, hệ thống chiến đấu.

## D. Đảo vệ tinh và 5 tiện ích

- **Nền chung (SAT_BASE):** phao tròn đường kính khoảng 1,5 ô, thân Sea Blue, mặt ivory, viền cam; một bệ ở giữa; neo động, xích hoặc dây neo; một phao cam; mép bọt trắng. Có cầu hoặc dây kết nối về Đảo Chính (tùy chọn).
- **Đọc được khi thu nhỏ:** mỗi tiện ích có hình bóng và màu nhấn riêng, không trùng nhau nhìn từ trên xuống.

| ID | Tiện ích | Hình bóng (nhìn từ trên) | Chi tiết, màu | Mở từ |
| --- | --- | --- | --- | --- |
| SAT_RADAR_OUTPOST | Trạm Ra-đa Tiền Tiêu | Đĩa tròn nghiêng có cột | Ivory, Graphite, kính | Hồi I |
| SAT_STEEL_DEPOT | Kho Thép | Hai khối container xếp chữ nhật | Sea Blue, ivory, sọc cam | Hồi I |
| SAT_BUOY_STATION | Trạm Phao Cứu Hộ | Vòng phao tròn lớn trên đài | Cam là chính (duy nhất), ivory | Hồi I |
| SAT_TRADE_DOCK | Bến Thương Hội | Cầu tàu chữ T, quầy hàng | Ivory, đồng nhạt, phao trắng | Hồi II |
| SAT_SIGNAL_BEACON | Đài tín hiệu cứu hộ | Tháp thon có chóp đèn | Ivory, Graphite, đèn vàng ấm | Hồi III |

## E. Đạo cụ môi trường

| ID | Món | Ghi chú |
| --- | --- | --- |
| PRP_BUOY | Phao cứu hộ | Cam, dây buộc; dùng lại nhiều nơi |
| PRP_LAMP_POST | Cột đèn | Graphite, đèn vàng ấm |
| PRP_BOLLARD | Cọc neo | Graphite, vòng cam |
| PRP_ROPE_COIL | Dây neo cuộn | Dây ivory, cuộn tròn |
| PRP_CRATE_CONTAINER | Thùng hàng, container | Sea Blue, ivory; 2–3 kích cỡ |
| PRP_WATER_TANK | Thùng chứa nước | Trụ tròn, ivory |
| PRP_SIGN_POST | Cọc biển báo | Không chữ; dùng ký hiệu hình học |
| PRP_ROCK_CORAL | Đá và san hô | Thấp, màu lạnh |
| PRP_SEAWEED | Rong biển | Mảng xanh trầm, đung đưa nhẹ |
| PRP_SUNKEN_RUINS | Mái nhà, trụ cầu thành phố chìm | Phủ rêu, nhô khỏi mặt nước |
| PRP_OLD_ANTENNA | Cột ăng-ten cũ | Gỉ, nghiêng |
| PRP_DOCK_PIECE | Mảnh bến nổi | Tấm gỗ và phao rời |

- **Gần luồng di chuyển:** thấp, ít tương phản, màu gần nước, không che địch, bệ hay đảo. Đạo cụ cao và nhiều màu chỉ đặt xa luồng.

## F. Bộ prompt (sao chép trực tiếp)

**Quy ước:** Mẫu riêng lẻ = `Single object, centered, three-quarter top view, soft even lighting, isolated on a plain neutral background.` Hậu tố chung = `Stylized semi-realistic 3D game asset, optimized low-to-mid poly design, clean readable silhouette, physically plausible materials, no text, no logo, no watermark.` Mỗi prompt dưới đây: [mẫu] + [nội dung] + [hậu tố]. Bảng màu: sea blue #1F5F8B, ivory #EDE6D6, rescue orange #FF7A1A, dark graphite #3A4048.

**F1. Đảo Chính (tổng thể)**
```
Hexagonal multi-tier floating fortress island, concentric rings of buildings, central command tower fused with a lighthouse, low ivory breakwater with orange stripes, six pier spurs, corner bastions, floating pontoon frame and buoy system under the waterline, harbor cranes, mooring bollards, orange rescue buoys, connecting walkways, sea blue, ivory, rescue orange and dark graphite palette, steel, composite, glass and rubber, warm sun from the upper left, deep blue sea around it, camera tilted about 55 degrees, overview showing tier heights. Stylized semi-realistic 3D game asset, optimized low-to-mid poly design, clean readable silhouette, physically plausible materials, no text, no logo, no watermark.
```

**F2. Từng công trình** (thêm mẫu riêng lẻ ở đầu, hậu tố ở cuối; viết cấp 1, 3, 5 cạnh nhau trên một tờ)
```
BLD_COMMAND_HUB: three levels side by side, command tower with a flag mast, then a glass observation deck added, then a tall tower crowned with a rotating lighthouse light ring, sea blue and ivory with orange trim
BLD_WAVE_SHIELD: three levels side by side, one wave-damper pylon, then three pylons with a faint translucent wave barrier, then a row of pylons shielding the island front, graphite, ivory and black rubber
BLD_REPAIR_WORKS: three levels side by side, steel shed workshop with a small crane, then a conveyor belt for materials, then a domed workshop with robotic arms, sea blue painted steel
BLD_TIDAL_POWER: three levels side by side, a single tidal turbine on a pontoon, then two turbines and a battery block, then a turbine cluster with softly glowing pale blue capacitors
BLD_SHIPYARD: three levels side by side, floating dry dock with a gantry crane, then a hull under construction in the dock, then two docks with a civilian patrol boat moored
BLD_SEA_RADAR: three levels side by side, a rotating radar dish on a mast, then an added satellite dish, then a phased-array radar tower with two dishes
BLD_DRONE_FIELD: three levels side by side, a drone landing pad, then a short runway, then a runway with a hangar and a control tower, civilian survey drones only
BLD_TIDE_RESONANCE: three levels side by side, one hydrophone mast, then concentric transmitter rings, then a tower of glowing pale blue rings, research instrument
BLD_DEEP_WELL_LAB: three levels side by side, a small laboratory, then a sealed containment chamber, then a research complex with a softly glowing blue core in the middle
```

**F3. Đảo vệ tinh (tổng thể)**
```
Set of small round floating satellite islands, about 1.5 cells wide, reinforced pontoon base, ivory deck with orange edge, one central utility pad, dynamic anchor chain and mooring rope, one orange buoy, white foam at the edge, readable silhouette from far away, top-down camera tilted 55 degrees, sea blue, ivory, rescue orange, dark graphite. Stylized semi-realistic 3D game asset, optimized low-to-mid poly design, clean readable silhouette, physically plausible materials, no text, no logo, no watermark.
```
Mẫu tiện ích (thêm vào giữa mẫu và hậu tố; thay {UTILITY}):
```
Satellite island base with {UTILITY} on the central pad, distinct silhouette from above, anchor chain and orange buoy
```
- SAT_RADAR_OUTPOST: `a tilted radar dish on a short mast`
- SAT_STEEL_DEPOT: `two stacked blue and ivory shipping containers with an orange stripe`
- SAT_BUOY_STATION: `a large orange rescue life-buoy ring on a raised platform`
- SAT_TRADE_DOCK: `a T-shaped jetty with a small market counter and round white buoys, pale bronze trim`
- SAT_SIGNAL_BEACON: `a slender signal tower with a warm yellow lamp cap`

**F4. Đạo cụ môi trường**
```
Set of reusable harbor and environment props, orange rescue buoy, lamp post, mooring bollard, rope coil, crates and shipping container, cylindrical water tank, sign post without symbols, rocks and coral, seaweed patches, sunken city rooftop and broken bridge pillar covered with algae, old rusted antenna mast, floating dock piece, muted colors, low contrast, low silhouette, grid layout, flat neutral background. Stylized semi-realistic 3D game asset, optimized low-to-mid poly design, clean readable silhouette, physically plausible materials, no text, no logo, no watermark.
```

**F5. Negative prompt chung**
```
text, letters, numbers, logo, watermark, signature, weapons, guns, cannons, missiles, military vehicles, fantasy, magic, neon colors, excessive glow, bloom, photorealistic photo, noisy textures, blurry, cluttered background, characters, people, flags with symbols, copyright characters, multiple unrelated styles
```

## G. Asset ID và đặt tên file

- **Mẫu:** `{nhóm}_{tên}_{biến thể}.{ext}`. Chữ thường hoặc chữ hoa theo bảng; dùng gạch dưới; không dấu, không khoảng trắng.
- **Nhóm:** `ISL` đảo chính, `BLD` công trình, `SAT` đảo vệ tinh, `PRP` đạo cụ, `ENV` môi trường khác.
- **Biến thể:** cấp (`L1`, `L3`, `L5`), mặt (`front`, `top`), phiên bản (`v01`).
- **Ví dụ:** `concept/BLD_SHIPYARD_L3_v01.png` (ảnh concept), `models/BLD_SHIPYARD_L3.glb` (model), `ISL_MUI_NEO_main_v01.png`.
- **Thư mục:** `docs/art-direction/concept/` cho ảnh duyệt; model 3D sẽ theo quy ước của kế hoạch khi tới bước 3D.
- **Phe khác:** thêm tiền tố phe (`BLK_` Hội Muối Đen, `STL_` Thiết Hạm Đoàn…), giữ nguyên các nhóm còn lại.

## H. Checklist duyệt concept trước khi sang 3D

- [ ] Nhận ra đảo trong một giây; hình bóng lục giác và hải đăng rõ.
- [ ] Rõ tầng, chiều cao, đê chắn sóng, kết nối module.
- [ ] Màu đúng bảng; cam chỉ làm nhấn, không quá 8%.
- [ ] Vật liệu rõ (thép sơn, composite, kính, cao su); ánh sáng từ trên trái, có nguồn nhìn thấy.
- [ ] Mỗi công trình khác hình bóng; cấp 1, 3, 5 khác nhau ở bộ phận ghi trong bảng C.
- [ ] 5 tiện ích đảo vệ tinh khác nhau khi nhìn từ trên xuống và khi thu nhỏ.
- [ ] Đạo cụ gần luồng thấp, ít tương phản.
- [ ] Không chữ, số, logo, watermark, vũ khí; không giống tài sản của game hoặc phim khác.
- [ ] Đủ góc nhìn (3/4 trên, trước, trên) cho họa sĩ 3D; ghi rõ phần chưa chắc.
- [ ] Không xung đột với GDD; mọi khác biệt đã ghi ở "Điểm cần duyệt" bên dưới.

## Điểm cần duyệt (khác nhau giữa các tài liệu)

1. **Số bệ lô cốt:** GDD 5.3 ghi 8–12 bệ ở rìa; GDD 8.2 ghi 12 bệ tròn; bản đồ trận hiện có 6 bệ mỏm bến và 4 đảo vệ tinh. Concept theo GDD, chưa quyết số cuối.
2. **Đường kính đảo vệ tinh:** GDD 8.6 ghi khoảng 1,5 ô; GDD 8.2 ghi kích thước 2,5 cho Đảo Gỗ Trôi. Concept dùng 1,5 ô.
3. **Tên tiện ích thứ 5:** GDD 5.4 ghi "Đài Pháo Sáng" (mở Hồi III); yêu cầu này ghi "Đài tín hiệu cứu hộ". Pack dùng tên trong yêu cầu, cần chốt.
4. **Bến Thương Hội:** GDD 5.4 ghi chỉ dùng được trên đảo lãnh thổ, không dùng trên đảo vệ tinh; yêu cầu này xếp là một trong 5 tiện ích đảo vệ tinh.
5. **Hướng sáng:** yêu cầu ghi trên trái; hướng nắng trong dữ liệu bản đồ nghiêng về phía đông bắc. Chưa đổi gì trong code.
6. **Màu code và bảng màu:** màu trong code gần bảng nhưng không trùng hex (Graphite code sáng hơn, #525C66). Cần chốt hex làm chuẩn.
7. **Phân kỳ:** GDD 8.2 nêu 5 công trình MVP, 4 công trình còn lại từ Hồi II. Khớp với yêu cầu này.
8. **Vị trí 8 ô công trình:** GDD 5.3 chỉ ghi chỗ tương đối; bảng gán ở mục B là đề xuất.
