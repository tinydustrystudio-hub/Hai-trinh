# Nhật ký hiệu năng

Điền sau mỗi lần thử bằng cảnh thử 60 địch (kế hoạch tháng 1, mục 7).

**Cách mở cảnh thử 60 địch**

- Bản web: mở link GitHub Pages kèm `?stress` ở cuối, ví dụ `…/index.html?stress`. Bảng đo tự mở.
- Bản web, trận thường có bảng đo: thêm `?debug`; chạm nút "Đo" ở cạnh trái.
- Giữ nước ở mức cao (không tự hạ khi khung hình thấp), để chụp ảnh hay so sánh: thêm `?hq`, ví dụ `?debug&hq`.
- APK (bản debug): bảng đo luôn có, chạm nút "Đo" ở cạnh trái, rồi "Sinh 60 địch".
- Máy tính: `godot -- --stress`.
- Cảnh thử cũng ghi một dòng `PERF fps=… draw_calls=…` ra console mỗi 2 giây (console trình duyệt, hoặc `adb logcat`).

**Ngân sách** (mục 7): Android thử từ 30 khung/giây với 60 địch; web 60 khung/giây trên laptop văn phòng;
không quá 150 lệnh vẽ; không quá 150.000 tam giác; vào trận không quá 3 giây; bản web không quá 40 MB.

| Ngày | Bản | Thiết bị | Số địch | Khung/giây | Lệnh vẽ | Ghi chú |
| --- | --- | --- | --- | --- | --- | --- |
| 30/10/2026 | bước 6 | Máy ảo CI, Chromium headless, không có GPU (SwiftShader, vẽ bằng CPU), 4 nhân Xeon 2,8 GHz; 1280×720 | 0 | 9 | – | Cảnh trống, nước cao. Máy ảo không có GPU nên chính cảnh trống đã dưới 30 |
| 30/10/2026 | bước 6 | như trên, 1280×720 | 60 | 5–6 | 95–106 | Nước tự hạ xuống thấp sau 5 giây; 42.000 tam giác lúc nước cao, 19.000 lúc nước thấp; vào trận 1,7 giây |
| 30/10/2026 | bước 6 | như trên, 640×360 | 60 | 13–14 | 102–106 | Giảm độ phân giải thì tăng gấp đôi: nút thắt là phần vẽ bằng CPU |
| 30/10/2026 | bước 6 | Máy ảo, Godot 4.5 gốc (không vẽ), đo riêng logic trận | 60 | – | – | Một nhịp trận với 60 địch mất 0,44 ms; phần logic không phải nút thắt |
| 30/10/2026 | bước 3 làm lại (GDD 8.6) | Máy ảo, Chromium headless, SwiftShader; 1280×720 | 0 | 5,5 (nước thấp) / 4 (nước cao, `?hq`) | 53 | Bản đồ trống: pháo đài, 4 đảo vệ tinh, nước bản 2, bọt, glow; 46.700 tam giác; vào trận 2,2 giây |
| 30/10/2026 | bước 3 làm lại | như trên, 960×540 | 0 | 8,8 / 5,3 | 53 | |
| 30/10/2026 | bước 3 làm lại | như trên, 640×360 | 0 | 14,5 / 7,8 | 53 | |
| 30/10/2026 | bước 3 làm lại | như trên, 1280×720, `?stress&hq` | 60 | 2 | 109 | 51.600 tam giác; vệt bọt và bóng tròn của 60 tàu thêm đúng 2 lệnh vẽ |
| 30/10/2026 | đối chứng | Máy ảo, dự án Godot 4.5 trống (chỉ có camera) | 0 | 40–50 ở 1280×720; 60 ở 960×540 | – | Trần của máy ảo khi không vẽ gì |
| 30/10/2026 | đối chứng | Máy ảo, dự án Godot trống + một mặt phẳng phủ màn hình, shader tối giản (một màu, unshaded) | 0 | 16 ở 1280×720; 24 ở 960×540 | – | Chỉ một lớp phủ kín màn hình đã dưới 30: máy ảo không thể đạt 60 khung/giây với bất kỳ mặt biển nào |
| 31/10/2026 | sau bước 3 (sửa thêm), APK | Điện thoại Android của đạo diễn | 59 | 39 | 112 | Nước cao; 52.500 tam giác; mỗi khung 25,6 ms (xử lý 19,3 ms). **Vào trận 3,5 giây, vượt ngân sách 3 giây** — nhiều khả năng do sinh 3 texture nhiễu cho nước lúc khởi động; cần sửa riêng |
| 31/10/2026 | góp ý 3 | Máy ảo, Chromium headless, SwiftShader; 1280×720, `?stress&hq`; đo xen kẽ với bản `main` trước góp ý 3 | 60 | 2–3 (main: 2–3) | 108–112 (main: 122–123) | Nước 192×192 ô, 6 lớp sóng: 93.400–94.100 tam giác (main 54.300), vẫn dưới ngân sách 150.000. Ít lệnh vẽ hơn vì luồng ẩn khi không báo động. Mỗi khung xử lý 425–630 ms (main 340–680 ms): máy ảo dao động quá lớn để thấy khác biệt. Vào trận 2,6–3,3 giây (main 2,4–2,6 giây): có thể chậm thêm khoảng 0,5 giây; cần đo lại trên điện thoại |
|  |  | Laptop văn phòng, Chrome |  |  |  | Chờ đạo diễn đo |

Dung lượng bản web: 37 MB (`build/web`), trong đó `index.wasm` của Godot đã chiếm 36 MB.
