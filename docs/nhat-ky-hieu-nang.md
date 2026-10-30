# Nhật ký hiệu năng

Điền sau mỗi lần thử bằng cảnh thử 60 địch (kế hoạch tháng 1, mục 7).

**Cách mở cảnh thử 60 địch**

- Bản web: mở link GitHub Pages kèm `?stress` ở cuối, ví dụ `…/index.html?stress`. Bảng đo tự mở.
- Bản web, trận thường có bảng đo: thêm `?debug`; chạm nút "Đo" ở cạnh trái.
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
|  |  | Android thử |  |  |  | Chờ đạo diễn đo |
|  |  | Laptop văn phòng, Chrome |  |  |  | Chờ đạo diễn đo |

Dung lượng bản web: 37 MB (`build/web`), trong đó `index.wasm` của Godot đã chiếm 36 MB.
