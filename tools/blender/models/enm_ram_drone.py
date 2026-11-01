"""Ca Nô Cảm Tử (ENM_RAM_DRONE): thân hẹp dài như mũi tên, ba thùng thuốc nổ đỏ chất ở mũi, động cơ đuôi, ăng-ten đèn đỏ cao.
Dài 0,7 ô = 2,8 đơn vị, mũi hướng −z, gốc ở mực nước. Màu gốc lấy từ data/enemies/ram_drone.tres."""
import kit

BODY = (0.12, 0.12, 0.13)
LIGHT = (0.26, 0.26, 0.29)
DARK = (0.05, 0.05, 0.06)
BELOW = (0.2, 0.06, 0.05)
ACCENT = (0.95, 0.2, 0.15)
WARN = (1.0, 0.85, 0.2)
NAME = "enm_ram_drone"


def section(z, width, keel, rise):
    pts = []
    for s in (-1.0, 1.0):
        pts += [(s * keel, -0.12), (s * width, 0.1), (s * width * 0.9, 0.34 + rise)]
    return (z, pts)


def build():
    m = kit.Model(NAME)
    stations = [
        section(1.4, 0.42, 0.28, 0.0), section(0.6, 0.48, 0.3, 0.0), section(-0.3, 0.42, 0.22, 0.02),
        section(-1.0, 0.26, 0.12, 0.06), section(-1.42, 0.04, 0.02, 0.1),
    ]
    m.loft([(z, [p for p in pts if p[1] < 0.2]) for z, pts in stations], BELOW)
    m.loft([(z, [(x, max(y, 0.1)) for x, y in pts if y > 0.05]) for z, pts in stations], BODY, top_color=LIGHT)
    # Sọc cảnh báo vàng đen dọc hai mạn.
    for side in (-1.0, 1.0):
        for k in range(5):
            z = 1.1 - k * 0.42
            m.box((side * 0.47, 0.22, z), (0.05, 0.12, 0.22), WARN, chamfer=0.0)
    # Bục mũi mang ba thùng thuốc nổ đỏ (đứng, xếp tam giác), đai đen, nắp sáng.
    m.hull([(-0.36, 0.34, -0.1), (0.36, 0.34, -0.1), (-0.3, 0.46, -0.1), (0.3, 0.46, -0.1),
            (-0.2, 0.34, -1.05), (0.2, 0.34, -1.05), (-0.16, 0.46, -1.05), (0.16, 0.46, -1.05)], DARK)
    for x, z in ((-0.17, -0.38), (0.17, -0.38), (0.0, -0.82)):
        m.lathe([(0.0, 0.46), (0.17, 0.46), (0.19, 0.55), (0.19, 0.9), (0.15, 0.96), (0.0, 0.98)], 8, ACCENT, top_color=(1.0, 0.5, 0.4), center=(x, z))
        m.lathe([(0.19, 0.6), (0.2, 0.6), (0.2, 0.68), (0.19, 0.68)], 8, DARK, center=(x, z), cap_bottom=False, cap_top=False)
        m.lathe([(0.19, 0.78), (0.2, 0.78), (0.2, 0.84), (0.19, 0.84)], 8, DARK, center=(x, z), cap_bottom=False, cap_top=False)
    # Cầu chì dẫn nổ: ống nhỏ nối ba thùng.
    m.box((0.0, 1.0, -0.6), (0.06, 0.06, 0.5), WARN, chamfer=0.0)
    # Buồng điều khiển nhỏ phía sau, động cơ đuôi và chân vịt.
    m.hull([(-0.22, 0.34, 0.95), (0.22, 0.34, 0.95), (-0.2, 0.68, 0.9), (0.2, 0.68, 0.9),
            (-0.26, 0.34, 0.4), (0.26, 0.34, 0.4), (-0.22, 0.52, 0.45), (0.22, 0.52, 0.45)], LIGHT, top_color=(0.4, 0.4, 0.44))
    m.hull([(-0.18, 0.2, 1.4), (0.18, 0.2, 1.4), (-0.15, 0.62, 1.5), (0.15, 0.62, 1.5),
            (-0.15, 0.2, 1.7), (0.15, 0.2, 1.7), (-0.12, 0.62, 1.66), (0.12, 0.62, 1.66)], DARK)
    m.box((0.0, -0.15, 1.66), (0.06, 0.5, 0.06), DARK, chamfer=0.0)
    m.box((0.0, -0.4, 1.66), (0.55, 0.06, 0.1), LIGHT, chamfer=0.0)
    # Ăng-ten mảnh cao, đế, đèn đỏ.
    m.lathe([(0.0, 0.66), (0.08, 0.66), (0.05, 0.8), (0.0, 0.8)], 8, DARK, center=(0.0, 0.7))
    m.box((0.0, 1.5, 0.7), (0.05, 1.3, 0.05), DARK, chamfer=0.0)
    m.ellipsoid((0.0, 2.2, 0.7), (0.13, 0.13, 0.13), 8, 4, ACCENT, top_color=(1.0, 0.65, 0.55))
    return [m.finish()]
