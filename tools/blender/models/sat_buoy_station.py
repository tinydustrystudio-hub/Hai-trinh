"""Trạm Phao Cứu Hộ (SAT_BUOY_STATION): đài tròn ngà, phao cứu hộ cam trắng dựng đứng trên giá, cột đèn và cờ hiệu, hộp cứu sinh.
Toạ độ cục bộ: gốc ở mặt đảo tại chỗ đặt tiện ích, +x hướng ra ngoài, y lên."""
import math

import kit

IVORY = (0.88, 0.85, 0.77)
ORANGE = (1.0, 0.45, 0.1)
WHITE = (0.95, 0.95, 0.93)
DARK = (0.12, 0.13, 0.15)
STEEL = (0.32, 0.36, 0.4)
LAMP = (1.0, 0.82, 0.45)


def build():
    m = kit.Model("sat_buoy_station")
    # Đài tròn hai bậc có vành cam.
    m.lathe([(0.0, 0.0), (1.0, 0.0), (1.0, 0.3), (0.9, 0.42), (0.0, 0.42)], 14, IVORY, top_color=(0.95, 0.93, 0.86))
    m.lathe([(0.99, 0.12), (1.03, 0.12), (1.03, 0.22), (0.99, 0.22)], 14, ORANGE, cap_bottom=False, cap_top=False)
    # Giá chữ A đỡ phao, phao cứu hộ dựng đứng hướng ra ngoài (mặt phẳng vòng vuông góc trục x), sọc cam trắng xen kẽ.
    for z in (-0.5, 0.5):
        m.box((0.0, 0.85, z), (0.1, 0.9, 0.1), STEEL, chamfer=0.0)
    m.box((0.0, 0.5, 0.0), (0.1, 0.1, 1.1), STEEL, chamfer=0.0)
    centre = (0.12, 1.2, 0.0)
    for i in range(8):
        a0, a1 = math.tau * i / 8, math.tau * (i + 1) / 8
        m.torus(centre, 0.55, 0.19, (0.0, 1.0, 0.0), (0.0, 0.0, 1.0), ORANGE if i % 2 == 0 else WHITE, arc=(a0, a1), sections=16, tube_sides=8)
    # Dây phao và móc.
    m.box((0.12, 1.2, 0.0), (0.02, 0.02, 1.0), DARK, chamfer=0.0)
    # Cột đèn hiệu có cờ.
    m.box((-0.55, 1.1, -0.45), (0.08, 1.4, 0.08), DARK, chamfer=0.0)
    m.ellipsoid((-0.55, 1.88, -0.45), (0.15, 0.12, 0.15), 8, 4, LAMP)
    m.hull([(-0.55, 1.7, -0.42), (-0.55, 1.5, -0.42), (-0.55, 1.7, -0.05), (-0.55, 1.55, -0.1)], ORANGE)
    # Hộp cứu sinh cam có chữ thập trắng.
    m.box((-0.5, 0.65, 0.5), (0.55, 0.4, 0.4), ORANGE, top_color=(1.0, 0.6, 0.3))
    m.box((-0.2, 0.68, 0.5), (0.02, 0.22, 0.06), WHITE, chamfer=0.0)
    m.box((-0.2, 0.68, 0.5), (0.02, 0.06, 0.22), WHITE, chamfer=0.0)
    return [m.finish()]
