# Kế hoạch hoàn thiện đồ họa, giao diện và menu

Người duyệt chốt ngày 31/10/2026: làm đẹp đồ họa, giao diện, menu **trước**; các số cân bằng (máu, đạn, số địch, giá) chỉnh sau, nên dùng số khởi đầu trong `data/*.tres` và ghi vào `docs/so-lieu-khoi-dau.md`. Phạm vi menu: cốt lõi và căn cứ. Đồ họa: hình khối lô cốt và địch, đảo chính và công trình, giao diện, ánh sáng và hậu kỳ.

Nguyên tắc: mọi thứ dựng bằng code hoặc dữ liệu (không cần Godot editor); tuân thủ `CLAUDE.md` và `docs/art-direction/mui-neo-concept-pack.md`; mỗi giai đoạn một nhánh và một PR; có test GUT cho phần logic; chữ qua `tr()` và CSV.

| GĐ | Việc | Xong khi |
| --- | --- | --- |
| P1 (xong) | **Nền giao diện:** bộ kiểu dùng chung theo Liên Minh Mũi Neo (khung, nút, chữ, biểu tượng vẽ bằng code), chuyển cảnh mờ dần, âm bấm nút | HUD, vòng chọn, thẻ nhánh, tạm dừng, kết quả cùng một phong cách; nút ≥ 120 px |
| P2 | **Luồng menu cốt lõi:** màn tiêu đề, cài đặt (âm thanh, nhạc, rung, chất lượng nước, thời tiết, ngôn ngữ), chuẩn bị trận, kết quả làm lại, hướng dẫn vài bước đầu; lưu cài đặt xuống máy | Mở game → tiêu đề → chuẩn bị → trận → kết quả → quay lại, không cần bảng debug |
| P3 | **Hình khối lô cốt và địch:** làm lại Súng Máy, Keo, Tia Sáng, ba loại địch theo concept pack; vệt đạn, nổ, MEGA rõ hình bóng khi thu nhỏ | Ảnh chụp từ camera trận nhận ra từng loại từ xa; vẫn ≤ 60 địch, dùng pool và MultiMesh |
| P4 | **Đảo chính và công trình:** các công trình MVP (Khiên, Xưởng Sửa Chữa, Năng Lượng, Xưởng Tàu) thêm lên pháo đài theo cấp 1, 3, 5; 4 tiện ích đảo vệ tinh; đạo cụ môi trường thấp gần luồng | Pháo đài đủ tầng, vành, công trình; đạo cụ không che luồng |
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
