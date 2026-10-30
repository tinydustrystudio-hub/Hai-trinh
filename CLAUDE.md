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
