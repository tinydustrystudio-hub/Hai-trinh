"""Xuồng Cướp (ENM_RAIDER_SKIFF): xuồng hở thân thon, mũi nhọn có răng vàng, mạn ốp sắt, buồng lái và cờ phía sau.
Dài 0,8 ô = 3,2 đơn vị, mũi hướng −z, gốc ở mực nước. Màu lấy từ data/enemies/raider_skiff.tres."""
import kit

BODY = (0.18, 0.19, 0.21)
LIGHT = (0.32, 0.34, 0.37)
DARK = (0.08, 0.08, 0.1)
ACCENT = (1.0, 0.78, 0.1)
RUST = (0.38, 0.22, 0.16)
NAME = "enm_raider_skiff"


def build():
    m = kit.Model(NAME)
    # Thân thuyền thon: đuôi vuông, mũi nhọn nhô cao.
    m.hull([
        (-0.62, -0.1, 1.6), (0.62, -0.1, 1.6), (-0.7, 0.42, 1.6), (0.7, 0.42, 1.6),
        (-0.55, -0.1, 0.2), (0.55, -0.1, 0.2), (-0.78, 0.42, 0.2), (0.78, 0.42, 0.2),
        (-0.3, 0.45, -1.15), (0.3, 0.45, -1.15), (-0.1, 0.0, -1.55), (0.1, 0.0, -1.55),
        (0.0, 0.6, -1.7),
    ], BODY, top_color=LIGHT)
    # Mạn ốp tấm sắt hai bên.
    for side in (-1.0, 1.0):
        m.hull([
            (side * 0.78, 0.42, 1.55), (side * 0.66, 0.42, 1.55), (side * 0.78, 0.7, 1.5), (side * 0.66, 0.7, 1.5),
            (side * 0.8, 0.42, 0.1), (side * 0.68, 0.42, 0.1), (side * 0.8, 0.68, 0.1), (side * 0.68, 0.68, 0.1),
            (side * 0.34, 0.45, -1.1), (side * 0.26, 0.45, -1.1), (side * 0.34, 0.66, -1.1), (side * 0.26, 0.66, -1.1),
        ], RUST, top_color=LIGHT)
    # Răng vàng ở mũi.
    m.hull([(-0.16, 0.5, -1.45), (0.16, 0.5, -1.45), (-0.12, 0.7, -1.6), (0.12, 0.7, -1.6), (0.0, 0.78, -1.78)], ACCENT)
    for x in (-0.3, 0.3):
        m.box((x, 0.5, -1.05), (0.12, 0.2, 0.3), ACCENT)
    # Buồng lái phía sau, cửa sổ tối.
    m.box((0.0, 0.8, 0.95), (0.9, 0.7, 0.85), LIGHT, top_color=(0.45, 0.47, 0.5))
    m.box((0.0, 0.92, 0.5), (0.7, 0.22, 0.06), DARK)
    # Thùng, bao tải trên boong.
    m.box((-0.35, 0.58, -0.2), (0.4, 0.3, 0.4), RUST, top_color=(0.5, 0.32, 0.2))
    m.box((0.3, 0.55, -0.45), (0.34, 0.25, 0.34), BODY, top_color=LIGHT)
    # Động cơ gắn đuôi.
    m.box((0.0, 0.3, 1.78), (0.3, 0.55, 0.22), DARK)
    # Cột, cờ đen có biểu tượng vàng.
    m.box((0.0, 1.55, 1.1), (0.07, 1.4, 0.07), DARK)
    m.box((0.0, 1.9, 0.82), (0.04, 0.5, 0.55), DARK)
    m.box((0.0, 1.92, 0.78), (0.05, 0.16, 0.16), ACCENT)
    return [m.finish()]
