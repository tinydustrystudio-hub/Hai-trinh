# Hướng dẫn tạo mô hình 3D cho Hải Trình (Blender và nền tảng AI)

Ba đường để có mô hình, dùng song song được. Mô hình nào cũng đi qua cùng một bước chuẩn hoá để vào game đúng cỡ, đúng trục, gọn tam giác.

| Đường | Ai làm | Hợp với | Ưu | Nhược |
| --- | --- | --- | --- | --- |
| A. Kịch bản Blender của Claude | Claude chạy `tools/blender/build_models.py` | Địch, lô cốt, công trình hình khối rõ | Nhanh, chính xác kích thước, màu đỉnh sẵn, tệp rất nhẹ | Hình khối vát cạnh, thiếu nét tay họa sĩ |
| B. Bạn chạy kịch bản trong Blender | Bạn | Muốn chỉnh tiếp mô hình của A | Sửa hình bằng tay trong Blender | Cần cài Blender |
| C. AI tạo 3D từ ảnh hoặc chữ | Bạn tạo, gửi cho Claude chuẩn hoá | Món cần nhiều chi tiết, hữu cơ (cua, tàu trùm, đá, cảnh trí) | Đẹp, đa dạng, ít công | Nhiều tam giác, chất lượng không ổn định, phải kiểm tra bản quyền |

Gợi ý chia việc: **A cho các món hình học cứng và phải đúng quy ước (lô cốt xoay được, công trình theo cấp 1 đến 5)**, **C cho nhân vật hữu cơ và vật trang trí** (Cua Giáp Gai, đá, san hô, tàu trùm).

## 1. Đường B: chạy kịch bản trong Blender của bạn

1. Mở Blender (4.x trở lên), tab Scripting.
2. Mở `tools/blender/kit.py` rồi `tools/blender/models/enm_raider_skiff.py`, chạy từng tệp; hoặc từ dòng lệnh Blender: `blender -b -P tools/blender/build_models.py`.
3. Tạo xong, Blender hiện mô hình; chỉnh tiếp rồi xuất File → Export → glTF 2.0 (`.glb`), bật *Vertex Colors*, giữ trục Y lên.
4. Gửi tệp cho Claude (mục 4).

Không cần Blender cũng chạy được: `python3 -m venv venv && venv/bin/pip install -r tools/blender/requirements.txt`, rồi `venv/bin/python tools/blender/build_models.py`.

## 2. Đường C: nền tảng AI tạo 3D

**Lưu ý trước khi dùng:** hạn mức miễn phí, giấy phép và điều khoản của các dịch vụ này đổi thường xuyên và Claude **không kiểm tra được trực tiếp** từ đây. Tên dưới đây là những dịch vụ tôi biết đến; hãy đọc lại trang giá và điều khoản của từng cái lúc dùng. **Trước khi dùng cho game phát hành, kiểm tra rõ: bản miễn phí có cho dùng thương mại không, ai sở hữu đầu ra, có bắt ghi công không.** Nếu bản miễn phí chỉ cho dùng cá nhân thì chỉ dùng làm bản thử.

| Dịch vụ | Cách dùng | Ghi chú |
| --- | --- | --- |
| Hunyuan3D (Tencent) | Ảnh sang 3D, có bản web và mã nguồn mở | Chất lượng khá, có thể chạy bản mở trên máy hoặc Hugging Face Space |
| TRELLIS (Microsoft) | Ảnh sang 3D, mã nguồn mở | Chạy được qua Hugging Face Space; kiểm tra giấy phép của bản mô hình bạn dùng |
| Stable Fast 3D / SPAR3D (Stability AI) | Ảnh sang 3D, rất nhanh | Có Space miễn phí; giấy phép thường có điều kiện về doanh thu |
| Tripo | Chữ hoặc ảnh sang 3D, giao diện web dễ dùng | Gói miễn phí giới hạn lượt mỗi tháng; xem điều khoản dùng thương mại |
| Meshy | Chữ hoặc ảnh sang 3D, có công cụ làm mịn và đổi tỉ lệ | Gói miễn phí giới hạn lượt và thường kèm điều kiện dùng đầu ra |

Cách cho kết quả tốt hơn: **tạo ảnh concept trước, rồi dùng chế độ ảnh sang 3D** (ổn định hơn chữ sang 3D). Ảnh concept có thể lấy từ các prompt trong `docs/art-direction/mui-neo-concept-pack.md` (mục F) hoặc từ prompt ở mục 3 dưới đây, tạo bằng bất kỳ công cụ ảnh nào bạn có.

## 3. Prompt mẫu (tiếng Anh, dán nguyên)

Mẫu chung, thêm mô tả riêng từng món vào chỗ `[…]`:

> Low-poly stylized game asset, single object centered on a plain white background, three-quarter top-down view, clean flat colors with a few bold accent colors, chunky readable silhouette, no ground, no water, no text, no shadow, symmetrical, [DESCRIPTION].

Mô tả cho từng món (bảng màu của game: xanh biển `#1F5F8B`, trắng ngà `#EDE6D6`, cam `#FF7A1A`, xám than `#3A4048`):

| Món | `[DESCRIPTION]` |
| --- | --- |
| Xuồng Cướp | small pirate skiff, sleek narrow hull with a pointed bow with yellow teeth marks, dark gunmetal iron plates along the sides, small cabin at the back, outboard motor, black flag on a mast. Bow pointing to the left |
| Ca Nô Cảm Tử | very narrow fast kamikaze speedboat shaped like an arrow, three red explosive barrels stacked at the bow, tall antenna with a red blinking light at the back |
| Cua Giáp Gai | armored crab warship, wide flat shell dark purple with glowing cyan spikes along the back, six legs, two large pincers raised at the front, two stalk eyes |
| Súng Máy | compact four-barrel rotary machine gun turret on a hexagonal ivory base, orange stripe on the top, ammo box on the side, black barrels pointing forward |
| Lô Cốt Keo | glue sprayer turret, large round sea-green tank with an orange band, pressure pipe leading to a wide flared nozzle pointing forward, small pressure gauge on top |
| Lô Cốt Tia Sáng | light beam cannon turret, long converging tube with three orange focusing rings, glowing blue lens at the front, two vertical orange heat fins |

Hướng mô hình: ghi rõ "bow/front pointing to the left" (hoặc nòng/mũi hướng bên trái) trong prompt, vì chúng ta sẽ nhận biết hướng mũi khi chuẩn hoá (mục 5).

**Lô cốt có đầu nòng xoay:** mô hình một khối không xoay riêng đầu nòng được. Với lô cốt hãy tạo **hai mô hình riêng: đế và đầu nòng** (hai lần tạo), hoặc để Claude dựng đầu nòng bằng kịch bản (đường A).

## 4. Gửi tệp cho Claude

- Định dạng: `.glb` (ưu tiên), hoặc `.obj` kèm ảnh texture, hoặc `.fbx`. Tên tệp gợi ý: `enm_raider_skiff.glb`, `enm_ram_drone.glb`, `enm_spiked_crab.glb`, `twr_machine_gun_base.glb`… (tiền tố `enm_` cho địch dùng đúng tên id trong `data/enemies/`).
- Đưa vào cuộc trò chuyện (đính kèm), hoặc đặt vào thư mục `art-incoming/` trong repo rồi báo.
- Kèm một dòng: mô hình hướng mũi/nòng về phía nào (trái, phải, về phía người xem…), món gì, và nguồn (dịch vụ nào, đã kiểm tra giấy phép chưa). Claude sẽ ghi nguồn và giấy phép vào `docs/nguon-tai-nguyen.md` để không sót.

## 5. Claude chuẩn hoá (bạn không phải làm)

`tools/blender/prepare_model.py` làm các việc: gộp mesh, **xoay mũi về −Z**, **co đúng chiều dài** (đơn vị Godot, 1 ô = 4), căn giữa và đặt đáy ở mực nước, **giảm tam giác** theo ngân sách, **nướng màu texture vào màu đỉnh** (game dùng một vật liệu màu đỉnh chung nên 60 địch vẫn một lệnh vẽ), xuất `.glb` vào `assets/models/`.

```bash
venv/bin/python tools/blender/prepare_model.py INPUT.glb enm_spiked_crab --length 4.8 --forward -x --max-tris 600
```

| Món | Tên tệp ra | `--length` (đơn vị) | `--max-tris` |
| --- | --- | --- | --- |
| Xuồng Cướp | `enm_raider_skiff` | 3,2 | 600 |
| Ca Nô Cảm Tử | `enm_ram_drone` | 2,8 | 600 |
| Cua Giáp Gai | `enm_spiked_crab` | 4,8 | 600 |

`--forward` là hướng mũi của mô hình gốc: `-z`, `+z`, `-x` hoặc `+x` (mô hình "mũi về bên trái" thường là `-x`). Nếu đoán sai hướng thì ảnh chụp thử sẽ cho thấy, chỉ cần đổi lại.

Giới hạn: màu nướng từ texture sang màu đỉnh bị mờ, mất chi tiết nhỏ (hoa văn, chữ). Mô hình phụ thuộc nhiều vào texture chi tiết sẽ nhìn "phẳng" hơn bản gốc; khi đó nên tô lại màu bằng tay trong Blender. Giữ nguyên texture (`--keep-texture`) chỉ dùng cho vài món lớn, vì mỗi vật liệu riêng tốn thêm lệnh vẽ.

## 6. Danh sách kiểm sau khi nhận

1. Nạp vào Godot, chụp ảnh cạnh bản tạm ở góc nhìn của game và nhìn từ xa (thu nhỏ hết cỡ): còn phân biệt được ba loại địch bằng hình bóng không.
2. Đúng hướng mũi, đúng cỡ, đáy ở mực nước.
3. Số tam giác trong ngân sách; chạy cảnh thử 60 địch (`?stress`) xem khung hình.
4. Giấy phép và nguồn đã ghi lại.
