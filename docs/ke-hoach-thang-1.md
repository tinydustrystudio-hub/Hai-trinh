# Kế hoạch kỹ thuật tháng 1 – Lõi chơi Hải Trình

Oct 30, 2026 · @David

## 1. Mục tiêu và phạm vi tháng 1

Tháng 1 (11/2026) làm lõi chơi: một màn chơi được trên điện thoại và trên web, đủ để 5–10 người chơi thử thấy vui, và đo được hiệu năng với 60 địch. Mọi số liệu cân bằng lấy từ GDD (Phần 3 và 4, mức Trung bình của Hồi I); tài liệu này chỉ nói cách làm.

| Có trong tháng 1 | Chưa làm trong tháng 1 |
| --- | --- |
| Một bản đồ trận: Bến Bắc của Mũi Neo dựng bằng khối thô, nước, camera, thao tác chạm | Đảo Chính, bản đồ thế giới, menu |
| Súng Máy và Lô Cốt Keo, cấp 1–5, chưa có nhánh | Nhánh cấp 5; Tên Lửa, Phòng Không, Chống Ngầm |
| 3 loại địch mặt biển: Xuồng Cướp, Ca Nô Cảm Tử, Cua Giáp Gai | Địch dưới nước và trên không |
| Thép, Độ Nổi, 5 đợt, thắng và thua, tạm dừng, tua nhanh ×2 | Sao, 3 mức độ, Xu |
| Thanh Quá tải, MEGA cơ bản, làm mát | Kiểu MEGA riêng và các lõi |
| Hình khối thô tô theo màu phe; vài tiếng tạm | Model thật, âm thanh hoàn chỉnh |
| Bảng đo hiệu năng, cảnh thử 60 địch | Quảng cáo, đo lường người chơi |

Ba loại địch được chọn để thử đủ ba kiểu áp lực: đàn đông (Xuồng Cướp), tốc độ (Ca Nô Cảm Tử) và giáp dày (Cua Giáp Gai). Riêng Lô Cốt Keo đi cùng MEGA là đủ để thử cách chơi "bẫy keo" ở mục 3.12 của GDD.

**Mốc cuối tháng**

- Link web và bản APK mới nhất chạy được trên trình duyệt và trên điện thoại.
- Chơi trọn 5 đợt ở Bến Bắc; thắng và thua đều hoạt động đúng.
- 60 địch cùng lúc chạy từ 30 khung hình/giây trên máy Android thử, và 60 khung hình/giây trên trình duyệt của một laptop văn phòng.
- 5–10 người chơi thử; ghi lại câu trả lời cho hai câu hỏi "có vui không" và "chỗ nào khó hiểu".

## 2. Thiết lập dự án và quy ước code

**Cài đặt trong project.godot**

| Mục | Giá trị | Vì sao |
| --- | --- | --- |
| Phiên bản | Godot 4.5 stable, GDScript | Theo brief |
| Renderer | `rendering/renderer/rendering_method` = `gl_compatibility`, bản mobile cũng vậy | Chạy được trên web và Android tầm trung |
| Hướng màn hình | `display/window/handheld/orientation` = Landscape | Game chơi ngang |
| Độ phân giải gốc | 1920×1080; stretch mode `canvas_items`, aspect `expand` | Mở rộng hai bên cho máy 19,5:9 (GDD mục 7.1) |
| Chạm và chuột | Bật `emulate_mouse_from_touch` và `emulate_touch_from_mouse` | Thử được bằng chuột trên trình duyệt máy tính |
| Khung hình | `application/run/max_fps` = 60 | Đỡ nóng máy và hao pin |
| Nén texture | Bật cả S3TC/BPTC (trình duyệt máy tính) và ETC2/ASTC (Android) | Một bộ tài nguyên dùng cho cả hai nền tảng |
| Bản web | Tắt Thread Support khi xuất | Chạy trên GitHub Pages và cổng game mà không cần header đặc biệt |
| Bản Android | Chỉ arm64-v8a; không cần gradle build ở tháng 1 | APK nhỏ, CI đơn giản |
| Vật lý | Không dùng thân vật lý cho đạn và địch | Tính khoảng cách trực tiếp, rẻ hơn nhiều |

**Quy ước code**

- GDScript có kiểu tĩnh ở mọi biến, tham số và giá trị trả về.
- Tên file `snake_case`; lớp dùng lại có `class_name` dạng `PascalCase`.
- Gom theo tính năng: scene và script của cùng một thứ nằm cạnh nhau.
- Số liệu cân bằng nằm trong file `.tres` ở thư mục `data/`, không viết cứng trong code.
- Tín hiệu đặt tên theo việc đã xảy ra: `enemy_killed`, `overload_ready`.
- Trong vòng lặp trận không cấp phát mới mỗi khung hình; địch và hiệu ứng dùng pool.
- Mọi thứ đặt được bằng dữ liệu (vị trí bệ, luồng địch, giới hạn camera), để không phải mở trình biên tập Godot mới chỉnh được.
- Chữ hiển thị đi qua `tr()` và một bảng dịch CSV (tiếng Việt, tiếng Anh), không gõ cứng chữ trong scene.

**File CLAUDE.md đặt ở gốc repo** (Claude Code đọc file này mỗi khi làm việc trong repo):

```markdown
# Hải Trình – quy ước dự án

- Godot 4.5, GDScript có kiểu tĩnh, renderer GL Compatibility, màn hình ngang 1920×1080.
- Thiết kế: GDD Hải Trình. Việc của tháng: Kế hoạch kỹ thuật tháng 1.
- Số liệu cân bằng lấy từ GDD và ghi vào data/*.tres; không viết cứng trong code.
- Gom theo tính năng: battle/, towers/, enemies/, fx/, ui/; lớp dữ liệu ở core/data/.
- Người duyệt không có trình biên tập Godot: mọi thứ phải dựng được bằng code hoặc dữ liệu; giữ file .tscn đơn giản.
- Hiệu năng: tối đa 60 địch; không dùng thân vật lý cho đạn và địch; dùng pool; vẽ đạn bằng MultiMesh; tối đa 2 hiệu ứng MEGA đầy đủ cùng lúc.
- Giao diện: nút tối thiểu 120 px ở độ phân giải gốc; hành động chính ở góc dưới bên phải.
- Chữ hiển thị qua tr() và bảng dịch CSV.
- Mỗi việc là một nhánh và một PR; logic số phải có test GUT; CI phải xanh rồi mới gộp.
```

Nút 120 px ở độ phân giải gốc tương đương khoảng 48dp trên điện thoại 6,5 inch, đúng luật ở mục 7.1 của GDD.

## 3. Cấu trúc thư mục

Gom theo tính năng: mỗi thư mục chứa cả scene lẫn script của tính năng đó. Riêng số liệu cân bằng nằm chung ở `data/` để chỉnh nhanh mà không phải lục code.

```
hai-trinh/
├── project.godot
├── export_presets.cfg          # cấu hình xuất Web và Android (không chứa mật khẩu)
├── CLAUDE.md                   # quy ước cho Claude Code (mục 2)
├── docs/                       # GDD và kế hoạch này, dạng Markdown (mục 8)
├── .gitattributes              # Git LFS cho .glb .png .ogg .ttf
├── .github/workflows/
│   ├── web.yml                 # xuất bản web → GitHub Pages
│   └── android.yml             # xuất APK → bản phát hành "nightly"
├── addons/
│   └── gut/                    # Godot Unit Test, chạy test trong CI
├── assets/
│   ├── fonts/                  # font có đủ dấu tiếng Việt
│   ├── textures/               # noise, bọt nước, vòng bệ
│   ├── audio/                  # vài tiếng tạm
│   └── translations/
│       └── strings.csv         # bảng chữ Việt – Anh
├── data/                       # số liệu cân bằng, chỉnh không cần đụng code
│   ├── towers/
│   │   ├── machine_gun.tres
│   │   └── glue_sprayer.tres
│   ├── enemies/
│   │   ├── raider_skiff.tres
│   │   ├── ram_drone.tres
│   │   └── spiked_crab.tres
│   ├── waves/
│   │   └── north_dock_waves.tres
│   └── maps/
│       └── north_dock_layout.tres
├── core/
│   ├── events.gd               # autoload: bus tín hiệu chung
│   ├── settings.gd             # autoload: chất lượng, tốc độ, âm lượng
│   └── data/                   # lớp Resource mô tả dữ liệu
│       ├── tower_data.gd
│       ├── tower_level.gd
│       ├── enemy_data.gd
│       ├── wave_data.gd
│       └── map_layout.gd
├── main/
│   ├── boot.tscn
│   └── boot.gd
├── battle/
│   ├── battle.tscn
│   ├── battle.gd
│   ├── battle_camera.gd
│   ├── touch_input.gd
│   ├── wave_spawner.gd
│   ├── economy.gd
│   ├── buoyancy.gd
│   ├── ocean/
│   │   ├── ocean.tscn
│   │   └── water.gdshader
│   └── map/
│       ├── island.tscn
│       ├── tower_pad.tscn
│       ├── tower_pad.gd
│       └── lane.gd
├── towers/
│   ├── tower.tscn
│   ├── tower.gd
│   ├── targeting.gd
│   ├── overload.gd
│   ├── machine_gun.gd
│   └── glue_sprayer.gd
├── enemies/
│   ├── enemy.tscn
│   ├── enemy.gd
│   ├── enemy_pool.gd
│   └── status_effects.gd
├── fx/
│   ├── bullet_renderer.gd
│   ├── glue_puddle.tscn
│   └── mega_burst.tscn
├── ui/
│   ├── hud.tscn / hud.gd
│   ├── build_ring.tscn / build_ring.gd
│   ├── upgrade_ring.tscn / upgrade_ring.gd
│   ├── mega_tray.tscn / mega_tray.gd
│   ├── pause_menu.tscn / pause_menu.gd
│   ├── result_panel.tscn / result_panel.gd
│   └── debug_overlay.tscn / debug_overlay.gd
├── test_scenes/
│   └── stress_test.tscn        # sinh liên tục tới 60 địch để đo hiệu năng
└── tests/
    ├── test_economy.gd
    ├── test_damage.gd
    ├── test_slow.gd
    └── test_overload.gd
```

Tên file và thư mục dùng tiếng Anh không dấu để tránh lỗi đường dẫn trên mọi nền tảng; chữ người chơi thấy nằm trong `strings.csv`.

## 4. Các scene

Tháng 1 chỉ có một scene trận lớn. Mọi thứ khác là scene nhỏ dùng lại nhiều lần: một scene lô cốt chung và một scene địch chung, mỗi cái đổi hành vi theo file dữ liệu.

| Scene | Nút gốc | Gồm những gì | Ghi chú |
| --- | --- | --- | --- |
| `main/boot.tscn` | Node | Nạp cài đặt, rồi chuyển sang trận | Tháng 1 vào thẳng trận, chưa có menu |
| `battle/battle.tscn` | Node3D | Nước, đảo, luồng địch, camera, các hệ thống trận, pool địch, lô cốt, vẽ đạn, HUD (cây ở dưới) | Scene trung tâm của tháng 1 |
| `battle/ocean/ocean.tscn` | MeshInstance3D | Mặt phẳng chia ô dùng `water.gdshader` | Hai mức chất lượng: 128×128 ô với 3 lớp sóng, 64×64 ô với 2 lớp |
| `battle/map/island.tscn` | Node3D | Khối thô của Bến Bắc Mũi Neo | Thay bằng model thật ở tháng 3–4 |
| `battle/map/tower_pad.tscn` | Node3D | Vòng bệ và hiệu ứng sáng khi chọn được | Vị trí lấy từ `MapLayout` |
| `towers/tower.tscn` | Node3D | Thân, đầu nòng xoay, thanh Quá tải nổi trên đầu | Một scene cho cả hai lô cốt; script con đổi cách bắn |
| `enemies/enemy.tscn` | Node3D | Thân, thanh máu nhỏ, `StatusEffects` | Một scene cho cả ba loại địch; khác nhau bằng `EnemyData` |
| `fx/glue_puddle.tscn` | MeshInstance3D | Mặt phẳng nhỏ trên nước có texture keo | Dùng pool |
| `fx/mega_burst.tscn` | Node3D | Vòng sáng cam bung ra 0,5 giây | Tối đa 2 cái đầy đủ cùng lúc |
| `ui/hud.tscn` | Control | Độ Nổi, đợt, Thép, Tạm dừng, ×2, báo đợt, khay MEGA | Theo mục 7.10 của GDD |
| `ui/build_ring.tscn`, `ui/upgrade_ring.tscn` | Control | Vòng chọn mở quanh ngón tay | Nút tối thiểu 120 px |
| `ui/mega_tray.tscn` | Control | Tối đa 4 nút MEGA | Góc dưới bên phải |
| `ui/pause_menu.tscn`, `ui/result_panel.tscn` | Control | Tạm dừng; màn thắng và thua đơn giản |  |
| `ui/debug_overlay.tscn` | CanvasLayer | FPS, mili giây mỗi khung, số địch, số lệnh vẽ; nút sinh 60 địch; nút đổi chất lượng nước | Chỉ có trong bản debug |
| `test_scenes/stress_test.tscn` | Node3D | Trận Bến Bắc cộng một bộ sinh địch liên tục tới 60 con | Dùng để đo hiệu năng |

**Cây nút của battle.tscn**

```
Battle (Node3D) — battle.gd
├── Ocean (MeshInstance3D) — water.gdshader
├── Island (Node3D)                 # khối thô, dựng từ MapLayout
│   └── TowerPad × 8–12
├── Lanes (Node3D)
│   └── Lane × 3 (Path3D) — lane.gd
├── BattleCamera (Camera3D) — battle_camera.gd
├── Sun (DirectionalLight3D)        # tắt bóng đổ động
├── Systems (Node)
│   ├── WaveSpawner — wave_spawner.gd
│   ├── Economy — economy.gd
│   ├── Buoyancy — buoyancy.gd
│   └── TouchInput — touch_input.gd
├── EnemyPool (Node3D) — enemy_pool.gd   # giữ sẵn 80 Enemy
├── Towers (Node3D)                      # Tower được thêm khi xây
├── BulletRenderer (MultiMeshInstance3D) — bullet_renderer.gd
└── HUD (CanvasLayer) — hud.tscn
    ├── BuildRing, UpgradeRing, MegaTray
    ├── PauseMenu, ResultPanel
    └── DebugOverlay                     # chỉ bản debug
```

**Vòng đời một trận** (do `battle.gd` điều khiển)

&#91;embedded content: vòng đời một trận · 5 trạng thái, 1 câu hỏi\]

Tạm dừng và tua nhanh ×2 chỉ đổi `Engine.time_scale`, không đổi trạng thái trận. Từ tháng 5, cửa sổ Cứu Đảo chen vào giữa "Độ Nổi về 0" và "Thua".

## 5. Các script và dữ liệu

### 5.1 Lớp dữ liệu (thư mục core/data/)

| Lớp | Trường chính | File dữ liệu tháng 1 |
| --- | --- | --- |
| `TowerLevel` | giá Thép, sát thương, tốc bắn, tầm (ô), thêm cho từng loại (mức chậm, bán kính vùng keo) | Nằm trong file của lô cốt |
| `TowerData` | id, khóa tên trong bảng dịch, tầng đánh được, danh sách 5 `TowerLevel`, thời gian nạp Quá tải, thời gian MEGA, hệ số MEGA (3), thời gian làm mát, sức bắn khi làm mát (0,2), màu | `machine_gun.tres`, `glue_sprayer.tres` |
| `EnemyData` | id, khóa tên, máu, tốc độ (ô/giây), giáp (tỉ lệ giảm sát thương), tầng, Độ Nổi mất khi lọt, Thép khi bị hạ, kích thước, màu | `raider_skiff.tres`, `ram_drone.tres`, `spiked_crab.tres` |
| `WaveData` | danh sách đợt; mỗi đợt có các nhóm (loại địch, số lượng, khoảng cách giữa hai con, luồng, độ trễ) và thời gian nghỉ | `north_dock_waves.tres` |
| `MapLayout` | vị trí các bệ, điểm của từng luồng, giới hạn camera, Thép khởi đầu, Độ Nổi khởi đầu | `north_dock_layout.tres` |

Quy ước khoảng cách: 1 ô (đơn vị tầm trong GDD) = 4 đơn vị Godot, bằng khoảng cách giữa hai bệ liền nhau.

**Số liệu khởi đầu cho 3 loại địch.** Máu, giáp và Thép lấy từ mục 3.1 của GDD. Tốc độ và Độ Nổi mất khi lọt là số mới, cần ghi bổ sung vào GDD sau khi chơi thử.

| Địch | Máu | Tốc độ | Giáp | Thép khi hạ | Độ Nổi mất khi lọt |
| --- | --- | --- | --- | --- | --- |
| Xuồng Cướp | 60 | 0,8 ô/giây | 10% | 5 | 1 |
| Ca Nô Cảm Tử | 60 | 1,5 ô/giây | 10% | 5 | 3 |
| Cua Giáp Gai | 800 | 0,4 ô/giây | 50% | 40 | 2 |

Thang tốc độ đề xuất cho GDD: bậc 1 = 0,4; bậc 2 = 0,6; bậc 3 = 0,8; bậc 4 = 1,1; bậc 5 = 1,5 ô/giây. Độ Nổi khởi đầu: 20.

**5 đợt ở Bến Bắc** (bản đầu, sẽ cân bằng lại khi chơi thử)

| Đợt | Địch | Luồng |
| --- | --- | --- |
| 1 | 6 Xuồng Cướp, cách nhau 1,5 giây | Bắc |
| 2 | 8 Xuồng Cướp và 3 Ca Nô Cảm Tử | Bắc, Đông |
| 3 | 10 Xuồng Cướp và 1 Cua Giáp Gai | Cả 3 luồng |
| 4 | 8 Xuồng Cướp và 6 Ca Nô Cảm Tử đi thành cụm | Đông, Tây |
| 5 | 12 Xuồng Cướp, 6 Ca Nô Cảm Tử và 2 Cua Giáp Gai | Cả 3 luồng |

### 5.2 Script

| Script | Lớp | Việc chính |
| --- | --- | --- |
| `core/events.gd` | Events (autoload) | Bus tín hiệu chung; các hệ thống không gọi thẳng nhau |
| `core/settings.gd` | Settings (autoload) | Chất lượng nước, tốc độ mặc định, âm lượng |
| `main/boot.gd` | – | Nạp cài đặt, chuyển sang `battle.tscn` |
| `battle/battle.gd` | BattleController | Nạp `MapLayout` và `WaveData`, dựng bệ và luồng, chạy vòng đời trận ở mục 4, tạm dừng và ×2 bằng `Engine.time_scale` |
| `battle/wave_spawner.gd` | WaveSpawner | Sinh địch theo nhóm và theo giờ; báo đợt sắp tới cho HUD |
| `battle/economy.gd` | Economy | Thép: khởi đầu, thưởng khi hạ địch, +20 đầu đợt, trừ khi xây và nâng, hoàn 70% khi bán |
| `battle/buoyancy.gd` | Buoyancy | Độ Nổi; về 0 thì thua; đảo nghiêng nhẹ theo mức còn lại |
| `battle/battle_camera.gd` | BattleCamera | Góc nghiêng cố định 55°, kéo một ngón để trượt trong giới hạn, có quán tính nhẹ |
| `battle/touch_input.gd` | TouchInput | Phân biệt chạm và kéo (ngưỡng 12 px); chiếu tia xuống mặt nước để tìm bệ, lô cốt hoặc địch gần nhất, không cần vật lý |
| `battle/map/lane.gd` | Lane | Dựng `Curve3D` từ điểm trong `MapLayout`; trả vị trí theo quãng đường đã đi |
| `battle/map/tower_pad.gd` | TowerPad | Trạng thái trống hoặc có lô cốt; sáng lên khi chọn được |
| `towers/tower.gd` | Tower | Đọc `TowerData`; giữ cấp hiện tại; tìm mục tiêu; bắn; nâng cấp; bán |
| `towers/targeting.gd` | Targeting | Chọn địch đúng tầng, trong tầm, đi xa nhất trên luồng; tìm lại 5 lần mỗi giây, không phải mỗi khung hình |
| `towers/overload.gd` | Overload | Máy trạng thái Nạp → Sẵn sàng → MEGA → Làm mát; trả hệ số sát thương hiện tại |
| `towers/machine_gun.gd` | (kế thừa Tower) | Bắn tức thì; gửi vệt đạn cho `BulletRenderer` |
| `towers/glue_sprayer.gd` | (kế thừa Tower) | Phun keo theo vùng mỗi 0,5 giây; gắn hiệu ứng chậm; đặt vũng keo |
| `enemies/enemy.gd` | Enemy | Đi theo luồng bằng quãng đường; nhận sát thương sau giáp; lắc theo sóng; báo bị hạ hoặc lọt |
| `enemies/status_effects.gd` | StatusEffects | Cộng dồn làm chậm, trần 70% (trùm 40%), tự hết hạn |
| `enemies/enemy_pool.gd` | EnemyPool | Tạo sẵn 80 địch; lấy ra và trả lại; giữ danh sách địch đang hoạt động cho lô cốt tra cứu |
| `fx/bullet_renderer.gd` | BulletRenderer | Vẽ mọi vệt đạn bằng một `MultiMeshInstance3D` |
| `ui/*.gd` | – | Mỗi màn giao diện một script; chỉ nghe tín hiệu từ Events và gọi lệnh qua BattleController |

### 5.3 Tín hiệu trong Events

| Tín hiệu | Ai phát | Ai nghe |
| --- | --- | --- |
| `enemy_killed(enemy, reward)` | Enemy | Economy, HUD |
| `enemy_leaked(enemy, damage)` | Enemy | Buoyancy |
| `steel_changed(value)`, `buoyancy_changed(value, max)` | Economy, Buoyancy | HUD |
| `wave_started(index, total)`, `wave_cleared(index)` | WaveSpawner | BattleController, Economy, HUD |
| `tower_built`, `tower_upgraded`, `tower_sold` | Tower | Economy, HUD |
| `overload_ready(tower)`, `mega_started(tower)`, `mega_ended(tower)` | Overload | MegaTray, hiệu ứng |
| `battle_ended(won)` | BattleController | ResultPanel |

### 5.4 Công thức

- **Sát thương nhận** = sát thương lô cốt × hệ số MEGA × (1 − giáp). Hệ số MEGA bằng 3 khi đang MEGA, 0,2 khi đang làm mát, 1 lúc bình thường.
- **Thanh Quá tải của Súng Máy:** mỗi phát trúng cộng 1 ÷ (14 × tốc bắn), nên đầy sau đúng 14 giây bắn liên tục (mục 3.2 của GDD).
- **Thanh Quá tải của Lô Cốt Keo:** mỗi giây cộng (số địch đang bị chậm, tối đa 3, chia 3) ÷ 12.
- **Làm chậm:** tốc độ = tốc độ gốc × (1 − tổng mức chậm); tổng tối đa 0,7, với trùm tối đa 0,4.
- **Thép:** cộng thưởng khi hạ địch, cộng 20 đầu mỗi đợt; bán lô cốt hoàn 70% tổng Thép đã bỏ vào nó.

Các công thức này đều có test GUT trong `tests/`, chạy trong CI mỗi lần đẩy code.

## 6. CI và bản thử trên web, Android

CI là việc làm đầu tiên. Không có trình biên tập Godot trên máy, nên cách duy nhất để nhìn thấy game là bản do CI xuất ra. Mỗi lần đẩy code lên GitHub, CI tự kiểm tra rồi xuất hai bản: một trang web để mở bằng trình duyệt, một file APK để cài lên điện thoại.

| Bước | Lệnh hoặc hành động | Kết quả |
| --- | --- | --- |
| 1. Lấy Godot | Tải Godot 4.5 headless và export templates từ trang phát hành chính thức, giữ cố định phiên bản | Mọi bản dựng dùng đúng một phiên bản Godot |
| 2. Nhập tài nguyên | `godot --headless --import` | Tài nguyên được nhập trước khi chạy test và xuất bản |
| 3. Chạy test | `godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit` | Test hỏng thì dừng, không xuất bản |
| 4. Xuất web | `godot --headless --export-release "Web" build/web/index.html`, rồi đẩy lên GitHub Pages | Một link cố định luôn chạy bản mới nhất của nhánh main |
| 5. Xuất Android | Cài JDK 17 và Android SDK, tạo keystore debug, rồi `godot --headless --export-debug "Android" build/hai-trinh.apk`; đính file vào bản phát hành "nightly" trên GitHub | File APK tải được ngay trên điện thoại |

**Luật cho CI**

- Mỗi PR đều chạy bước 1–3 để biết code có lỗi không. Chỉ nhánh main mới đẩy bản web lên GitHub Pages và cập nhật bản "nightly".
- `export_presets.cfg` được đưa vào repo. Godot 4 cất mật khẩu xuất bản ở một file riêng không đưa lên repo, nên file này an toàn để chia sẻ. Mật khẩu keystore để trong GitHub Secrets.
- Đường dẫn Android SDK và keystore debug được trỏ cho Godot ngay trong bước CI (qua cài đặt editor hoặc biến môi trường), không ghi vào repo.
- Model, ảnh, âm thanh đi qua Git LFS; theo dõi dung lượng LFS khi bắt đầu có model thật ở tháng 2.
- Cuối tháng gắn nhãn phiên bản `v0.1` cho bản chơi thử.

**Cách chơi thử**

- **Trên máy tính:** mở link GitHub Pages bằng Chrome hoặc Edge; chuột thay cho ngón tay.
- **Trên điện thoại:** mở cùng link bằng Chrome, hoặc tải APK từ bản "nightly" rồi cho phép cài từ nguồn không xác định.
- Mỗi lần thử, mở bảng debug (mục 7) và ghi lại số liệu vào nhật ký hiệu năng.

## 7. Ngân sách hiệu năng và cách đo

Hiệu năng được đo ngay từ tuần 2, khi chưa có gì đẹp, vì sửa từ sớm rẻ hơn nhiều so với sửa ở tháng 4.

| Mục | Mục tiêu tháng 1 | Đo bằng |
| --- | --- | --- |
| Khung hình trên Android thử | Từ 30 khung/giây ổn định khi có 60 địch; 60 khung/giây lúc bình thường | Bảng debug (`Performance.TIME_FPS`) |
| Khung hình trên web | 60 khung/giây với 60 địch, trên Chrome của một laptop văn phòng | Bảng debug |
| Số lệnh vẽ mỗi khung | Không quá 150 | `RENDER_TOTAL_DRAW_CALLS_IN_FRAME` |
| Tam giác trên màn hình | Không quá 150.000 | `RENDER_TOTAL_PRIMITIVES_IN_FRAME` |
| Thời gian vào trận | Không quá 3 giây | Đồng hồ trong `boot.gd` |
| Dung lượng bản web | Không quá 40 MB | Kích thước thư mục `build/web` |

**Máy thử:** một máy Android tầm trung khoảng 4 GB RAM ra đời 2022–2024 (ví dụ dòng Galaxy A hoặc Redmi Note), và một laptop văn phòng chạy Chrome.

**Cách giữ trong ngân sách**

- Tắt bóng đổ động; dưới mỗi tàu đặt một bóng tròn giả.
- Mỗi phe dùng chung một vật liệu để Godot gộp lệnh vẽ.
- Mọi vệt đạn vẽ bằng một MultiMesh; địch, vũng keo và hiệu ứng MEGA đều dùng pool.
- Nước có hai mức chất lượng, tự hạ xuống mức thấp nếu khung hình dưới 30 liên tục trong 5 giây.
- Hạn chế vật trong suốt chồng nhiều lớp; particle giữ số lượng thấp.
- Lô cốt tìm mục tiêu 5 lần mỗi giây; địch không dùng vật lý.

**Nhật ký hiệu năng** (điền sau mỗi lần thử bằng `stress_test.tscn`)

| Ngày | Bản | Thiết bị | Số địch | Khung/giây | Lệnh vẽ | Ghi chú |
| --- | --- | --- | --- | --- | --- | --- |
|  |  |  |  |  |  |  |
|  |  |  |  |  |  |  |

## 8. Thứ tự làm và cách giao việc cho Claude Code

Mười ba bước trong 4 tuần. Mỗi bước chỉ bắt đầu khi bước trước đã gộp vào main và chạy được trên bản thử.

| # | Tuần | Việc | Xong khi |
| --- | --- | --- | --- |
| 1 | 1 | Tạo repo: `project.godot` theo mục 2, cây thư mục theo mục 3, `CLAUDE.md`, `.gitattributes`, addon GUT; `boot.tscn` hiện chữ "Hải Trình" | Repo đúng cấu trúc; một test GUT mẫu chạy được |
| 2 | 1 | CI cho web và Android (mục 6) | Mở được link web trên máy tính và cài được APK trên điện thoại, cả hai hiện chữ "Hải Trình". Đây là việc quan trọng nhất của tuần 1 |
| 3 | 1 | Bản đồ khối thô Bến Bắc: nước (shader bản 1), đảo, 10 bệ, 3 luồng dựng từ `MapLayout`; camera 55° kéo trượt | Kéo camera mượt trên điện thoại; nhìn rõ bệ và luồng |
| 4 | 2 | Lớp dữ liệu và file `.tres` cho 3 địch, 5 đợt, bản đồ (mục 5.1) | Test đọc dữ liệu chạy xanh |
| 5 | 2 | Enemy, EnemyPool, đi theo luồng, lọt thì trừ Độ Nổi; WaveSpawner; vòng đời trận; màn thắng và thua đơn giản | Chạy đủ 5 đợt khi chưa có lô cốt, và thua đúng như mong đợi |
| 6 | 2 | Bảng debug và `stress_test.tscn`; đo trên điện thoại và web | Ghi được số liệu 60 địch vào nhật ký. Nếu dưới 30 khung/giây, hạ chất lượng nước và sửa trước khi làm tiếp |
| 7 | 3 | Chạm bệ → vòng chọn → đặt Súng Máy; tìm mục tiêu; bắn tức thì; vệt đạn MultiMesh; giáp; Thép | Hạ được Xuồng Cướp; Thép cộng trừ đúng; test sát thương và Thép chạy xanh |
| 8 | 3 | Lô Cốt Keo: vùng keo, làm chậm có trần, vũng keo | Ca Nô Cảm Tử chậm rõ khi vào vùng keo; test làm chậm chạy xanh |
| 9 | 3 | Vòng nâng cấp cấp 1–5 theo dữ liệu; bán hoàn 70% | Nâng và bán được ngay giữa đợt; chỉ số đổi đúng theo Phần 3 của GDD |
| 10 | 4 | Thanh Quá tải, MEGA, làm mát; khay MEGA ở góc dưới phải; hiệu ứng tạm; giới hạn 2 hiệu ứng đầy đủ | Kích MEGA lúc địch dính keo xóa được cả cụm; test Quá tải chạy xanh |
| 11 | 4 | HUD đầy đủ: Độ Nổi, đợt, Thép, Tạm dừng, ×2, báo đợt sắp tới; chữ đi qua bảng dịch | Mọi nút từ 120 px và nằm đúng góc theo mục 7.1 của GDD |
| 12 | 4 | Cân bằng 5 đợt bằng số liệu Hồi I; vài tiếng tạm (bắn, nổ, MEGA) | Người làm game thắng được ở lần chơi thứ 2–3, không thắng quá dễ |
| 13 | 4 | Bản chơi thử `v0.1` cho 5–10 người; phiếu hỏi 2 câu; đo hiệu năng lần cuối | Đạt đủ mốc cuối tháng ở mục 1 |

**Trước bước 1:** xuất GDD và tài liệu này ra Markdown, đặt vào thư mục `docs/` trong repo (`docs/gdd.md`, `docs/ke-hoach-thang-1.md`). Claude Code đọc file trong repo, không mở được tài liệu trên claude.ai.

**Cách giao việc**

- Mỗi bước là một issue trên GitHub. Claude Code làm trên một nhánh riêng rồi mở PR.
- CI xanh và bản thử chạy được thì gộp vào main, sau đó mới sang bước tiếp theo.
- Bước 2 phải xong trước mọi bước khác. Nếu bước 6 cho thấy hiệu năng không đạt, dừng lại sửa trước khi làm lô cốt.
- Cuối mỗi tuần, đạo diễn chơi bản mới nhất trên điện thoại khoảng 15 phút, điền nhật ký hiệu năng và ghi 3 điều cần sửa cho tuần sau.

**Mẫu lời giao việc cho Claude Code**

```
Đọc CLAUDE.md, docs/gdd.md mục <…> và docs/ke-hoach-thang-1.md, bước <số>.
Làm: <việc của bước>.
Xong khi: <tiêu chí "Xong khi" của bước>.
Logic số thì thêm test GUT. Mở PR, chờ CI xanh, rồi gửi link bản web để tôi thử.
```
