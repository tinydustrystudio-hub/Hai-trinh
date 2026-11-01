# Kế hoạch hoàn thiện đồ họa, giao diện và menu

Người duyệt chốt ngày 31/10/2026: làm đẹp đồ họa, giao diện, menu **trước**; các số cân bằng (máu, đạn, số địch, giá) chỉnh sau, nên dùng số khởi đầu trong `data/*.tres` và ghi vào `docs/so-lieu-khoi-dau.md`. Phạm vi menu: cốt lõi và căn cứ. Đồ họa: hình khối lô cốt và địch, đảo chính và công trình, giao diện, ánh sáng và hậu kỳ.

Nguyên tắc: mọi thứ dựng bằng code hoặc dữ liệu (không cần Godot editor); tuân thủ `CLAUDE.md` và `docs/art-direction/mui-neo-concept-pack.md`; mỗi giai đoạn một nhánh và một PR; có test GUT cho phần logic; chữ qua `tr()` và CSV.

| GĐ | Việc | Xong khi |
| --- | --- | --- |
| P1 (xong) | **Nền giao diện:** bộ kiểu dùng chung theo Liên Minh Mũi Neo (khung, nút, chữ, biểu tượng vẽ bằng code), chuyển cảnh mờ dần, âm bấm nút | HUD, vòng chọn, thẻ nhánh, tạm dừng, kết quả cùng một phong cách; nút ≥ 120 px |
| P2 (xong) | **Luồng menu cốt lõi:** màn tiêu đề, cài đặt (âm thanh, nhạc, rung, chất lượng nước, thời tiết, ngôn ngữ), chuẩn bị trận, kết quả làm lại, hướng dẫn vài bước đầu; lưu cài đặt xuống máy | Mở game → tiêu đề → chuẩn bị → trận → kết quả → quay lại, không cần bảng debug |
| P3 | **Hình khối lô cốt và địch:** làm lại Súng Máy, Keo, Tia Sáng, ba loại địch theo concept pack; vệt đạn, nổ, MEGA rõ hình bóng khi thu nhỏ | Ảnh chụp từ camera trận nhận ra từng loại từ xa; vẫn ≤ 60 địch, dùng pool và MultiMesh |
| P4 | **Đảo chính và công trình:** các công trình MVP (Tường Chắn Sóng, Xưởng Sửa Chữa, Năng Lượng, Xưởng Tàu) thêm lên pháo đài theo cấp 1, 3, 5; 4 tiện ích đảo vệ tinh; đạo cụ môi trường thấp gần luồng | Pháo đài đủ tầng, vành, công trình; đạo cụ không che luồng |
| P5 | **Căn cứ (Đảo Chính):** màn căn cứ 3D, cửa sổ nâng cấp công trình, đặt và di chuyển đảo vệ tinh theo quy tắc mới | Đặt đảo miễn phí, di chuyển tốn phí, tối thiểu 4 đảo; số Xu và phí là số đặt tạm |
| P6 | **Ánh sáng và hậu kỳ:** bình minh, hoàng hôn theo bản đồ, chỉnh màu, glow, bóng; hạ chất lượng gọn trên máy yếu | Ảnh đẹp ở cả hai mức nước; không tụt dưới ngân sách khung hình đã đo |
| P7 | **Đo lại hiệu năng và thời gian vào trận** (đang hơn 3 giây): lưu sẵn texture nhiễu, đo trên điện thoại | Đạt ngân sách ở `docs/nhat-ky-hieu-nang.md` |

**Quyết định về tiền (người duyệt, 31/10): gộp Thép và Xu thành một loại tiền duy nhất, "Tiền Vàng".**

- Tiền Vàng dùng cho mọi chi phí: xây, nâng cấp, bán lô cốt trong trận; nâng cấp công trình, mua và dời đảo vệ tinh ở căn cứ.
- Tiền kiếm được trong trận (hạ địch, thưởng đợt) và thưởng cuối trận cộng vào ví dùng ở căn cứ; số vàng đầu trận lấy từ cấu hình của bản đồ.
- Thay đổi theo từng giai đoạn: P1 đổi chữ "Thép" thành "Tiền Vàng" ở HUD, vòng chọn, thẻ nhánh, tạm dừng và kèm biểu tượng đồng vàng; P5 làm ví chung giữa trận và căn cứ. Các số giá hiện có (70, 60, 90…) giữ nguyên làm số khởi đầu.
- GDD cần viết lại mục 3.1, 5.4 và 5.6 (và các bảng giá Thép, Xu) khi làm P5; trước đó `docs/so-lieu-khoi-dau.md` ghi mọi giá là Tiền Vàng. Tên trong code (`steel`) đổi dần ở P1, không đổi hành vi.

**Để dành, làm sau khi chơi thử:** số máu, sát thương, tốc độ, số địch và giá; cân bằng 5 đợt; nhánh cấp 5 của Lô Cốt Tia Sáng.

**Đã chốt (người duyệt, 31/10): phí dời đảo vệ tinh = 1/2 giá xây lô cốt rẻ nhất.** Tính theo công thức từ dữ liệu lô cốt (giá cấp 1 thấp nhất trong các lô cốt đã mở), không viết cứng: hiện Lô Cốt Keo 60 nên phí dời là 30 Tiền Vàng, đổi giá lô cốt thì phí đổi theo. Làm tròn xuống, tối thiểu 1. Đảo là vật phẩm, mua một lần là có mãi; đảo cấp sẵn của màn dùng miễn phí, đảo tự đặt tốn 200 cho đảo thứ nhất, +50 cho mỗi đảo tiếp theo.

**Đã chốt (31/10): giá mua đảo vệ tinh:** đảo mua thêm thứ nhất 250 Tiền Vàng, mỗi đảo sau +50; mua bằng Tiền Vàng.

**Giá nâng cấp công trình (người duyệt chọn dùng số tạm, 31/10):** lên cấp 2 / 3 / 4 / 5 tốn 200 / 320 / 510 / 820 Tiền Vàng (công thức 200 × 1,6^(cấp − 2)); chỉnh sau khi chơi thử. Không còn điều gì cần chốt trước P5.

## Ghi chú P2 (luồng menu đã làm)

- Boot điều phối: Tiêu đề → Chuẩn bị trận → Trận → Về menu; Cài đặt mở từ Tiêu đề. `?play` vào thẳng trận (thử nhanh), `?stress` vào cảnh thử 60 địch.
- Cài đặt (âm thanh, nhạc, rung, chất lượng nước, ngôn ngữ, hướng dẫn) lưu ở `user://settings.cfg`; không ghi khi chạy không màn hình.
- Hướng dẫn bốn bước ở trận đầu (chạm bệ, chọn và xác nhận lô cốt, đèn đỏ báo hướng, chạm lô cốt nhấp nháy để kích MEGA); bấm Bỏ qua hoặc xong là không hiện lại, bật lại trong Cài đặt.
- Chưa có: màn Căn cứ (P5), chọn màn (chỉ một bản đồ), nhạc ở màn tiêu đề.

**P4 đã làm (1/11):** Tường Chắn Sóng (1/3/5 trụ, dây chắn, màng sóng), Xưởng Sửa Chữa (cấp 3 băng chuyền, cấp 5 mái vòm và tay máy), Xưởng Tàu (ụ nổi chữ U, cấp 3 thân tàu, cấp 5 hai ụ), 12 đèn đường ở lối vào; bốn tiện ích đảo vệ tinh (ra-đa, kho container, trạm phao cam, tháp truyền tin) cùng đèn và cuộn dây neo. Cấp công trình lấy từ `MapLayout.building_levels` (số tạm, P5 lưu cấp thật), tiện ích từ `satellite_utilities`. Đạo cụ chỉ đặt trên sàn đảo (không đặt giữa biển để khỏi xuyên sóng và che luồng); đạo cụ ngoài biển để lại P6 nếu cần.

**P5a, P5b đã làm (1/11):** ví Tiền Vàng và cấp công trình lưu máy (`Profile`); màn Căn cứ (nút Căn cứ ở màn Tiêu đề): đảo 3D xem trước đổi theo cấp, bốn công trình kèm nút Nâng cấp ghi giá, ví ở góc trên phải, nút Chuẩn bị trận ở góc dưới phải. Trạm Năng Lượng: cấp 1 một tua-bin, cấp 3 hai tua-bin và khối pin, cấp 5 thêm vòng tụ phát sáng. P5c còn lại: đặt, dời, mua đảo vệ tinh.

**P5c đã làm (1/11, sửa lại sau góp ý):** đảo vệ tinh mua thêm là vật phẩm lưu trong hồ sơ, nằm đậu cạnh đảo chính (`MapLayout.satellite_docks`); màn 1: 4 đảo cấp sẵn cố định ở ô mặc định, mua thêm tối đa 4 (đảo thứ 5 giá 250, mỗi đảo sau +50). Vào trận kéo đảo mua ra **chỗ tuỳ ý trên biển** (không theo ô có sẵn; `MapLayout.island_spot_valid` kiểm tra trong vùng biển, cách đảo chính, không đè luồng, không chồng đảo khác). Đảo được lai dắt như xà lan: tăng tốc từ từ, chạy tối đa `island_tow_speed`, phanh trước đích (`data/economy.tres`), thả rồi vẫn chạy tới nơi mới mở bệ; thả chỗ không hợp lệ thì lai dắt về chỗ đậu. Đảo cấp sẵn do từng màn tự sắp xếp trong `satellite_centers`; mỗi lần kéo hay dời lại tốn 30 Tiền Vàng (½ giá lô cốt rẻ nhất) trừ vào vàng trong trận, thiếu vàng thì đảo về chỗ đậu; đảo đã có lô cốt thì không dời được; chơi lại thì đảo về chỗ đậu. Không còn phí dùng đảo mỗi trận. Màn Căn cứ có trang Đảo vệ tinh: số đảo, phí kéo, Mua đảo, Đặt lại đảo đã mua.

**P6 đã làm (1/11):** ánh sáng theo màn, cố định suốt màn theo cốt truyện (người duyệt, 1/11). `MapLayout.weather_id` (clear, rain, storm) và `lighting_id` (day, dawn, dusk). `data/lighting/*.tres` gồm nắng (màu, độ sáng, hướng thấp cho bóng dài), ánh sáng nền, chỉnh màu, glow, tối viền màn hình và bảng màu biển, trời. Bản đồ Bến Bắc dùng bình minh, trời quang. Thời tiết không đổi trong màn; `?weather=`, `?light=` và hai nút ở bảng debug chỉ để thử. Viền tối tắt ở chất lượng nước thấp cùng glow.

**P7 đã làm (1/11):** ba texture nhiễu của nước dựng sẵn thành PNG (công cụ `tools/bake_noise.gd`), vào trận không còn sinh nhiễu; mục "Vào trận" của bảng debug tính từ lúc dựng trận. Còn chờ số đo trên điện thoại của đạo diễn (xem `docs/nhat-ky-hieu-nang.md`).

**GY12 (1/11):** `docs/danh-sach-tai-nguyen-tam.md` liệt kê mọi tài nguyên tạm cho họa sĩ. Khiên Chắn Sóng đổi tên thành **Tường Chắn Sóng**, nâng cấp đổi cả vành tường quanh đảo (cao, dày, sọc, chân, đèn, kính); Trạm Năng Lượng từ cấp 2 có ống cáp quanh mép đảo. Đảo xem trước ở màn Căn cứ nghiêng được (kéo lên xuống).

**Dời lô cốt (1/11):** vì chỗ đặt lô cốt trên biển hạn chế, mọi lô cốt đều dời được. Chạm lô cốt → nút Dời (kèm giá) → chạm một bệ trống (hiện tầm bắn tại đó) → dấu tích/dấu nhân. Phí dời bằng giá lô cốt rẻ nhất (`tower_move_ratio` trong `data/economy.tres`); lô cốt giữ nguyên cấp, nhánh và thanh Quá tải. Bước kế: nhà giàn cố định trên biển theo từng màn (giàn khoan dầu, nhà giàn quân sự, trạm nghiên cứu).
