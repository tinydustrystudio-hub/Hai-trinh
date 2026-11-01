"""Trạm Năng Lượng Dòng Triều (BLD_TIDAL_POWER), 5 cấp: tua-bin gió-nước ở vành trong (60° và 240°), khối pin, ống cáp quanh mép sàn.
Cấp 1 một tua-bin; cấp 2 khối pin và ống cáp cam quanh mép đảo; cấp 3 tua-bin thứ hai; cấp 4 pin thứ hai và dải điện lam sáng;
cấp 5 vòng tụ phát sáng quanh chân hai tua-bin. Toạ độ cục bộ đảo chính (tâm ở gốc, bán kính 14)."""
import math

import kit

R = 14.0
DECK = 0.8
RING_Y = 2.05
IVORY = (0.88, 0.85, 0.77)
ORANGE = (1.0, 0.45, 0.1)
STEEL = (0.32, 0.36, 0.4)
DARK = (0.12, 0.13, 0.15)
GLASS = (0.55, 0.8, 0.92)
GLOW = (0.5, 0.9, 1.0)
S = R * 0.075


def turbine(m, degrees, battery, glow_ring):
    """Một tua-bin ở bán kính 6,1 theo góc `degrees`: đế bát giác, cột thon, đầu máy, ba cánh quay hướng ra ngoài; tuỳ chọn khối pin và vòng tụ."""
    f = kit.Frame(6.1 * math.cos(math.radians(degrees)), 6.1 * math.sin(math.radians(degrees)), degrees)
    c = f.p(0, 0, 0)
    m.prism((c[0], 0, c[2]), S * 1.15, RING_Y, RING_Y + S * 0.6, 10, STEEL, top_color=IVORY)
    m.lathe([(S * 0.32, RING_Y + S * 0.6), (S * 0.24, RING_Y + S * 3.0), (S * 0.18, RING_Y + S * 5.0)], 10, IVORY, center=(c[0], c[2]), cap_top=False, cap_bottom=False)
    m.ellipsoid(f.p(0, RING_Y + S * 5.0, 0), (S * 0.55, S * 0.4, S * 0.7), 10, 5, IVORY)
    hub = f.p(S * 0.7, RING_Y + S * 5.0, 0)
    m.ellipsoid(hub, (S * 0.25, S * 0.25, S * 0.25), 8, 4, ORANGE)
    for i in range(3):
        t = math.tau * i / 3 + 0.4
        dv, dy = math.cos(t), math.sin(t)
        # Cánh: hình thoi dài toả ra từ moay-ơ trong mặt phẳng vuông góc với hướng ra ngoài.
        tip_v, tip_y = dv * S * 3.0, RING_Y + S * 5.0 + dy * S * 3.0
        mid_v, mid_y = dv * S * 1.2, RING_Y + S * 5.0 + dy * S * 1.2
        w = S * 0.3
        f.hull(m, [(S * 0.8, RING_Y + S * 5.0, 0.0), (S * 0.8 + 0.04, mid_y, mid_v + w * dy), (S * 0.8 + 0.04, mid_y, mid_v - w * dy),
                   (S * 0.8 + 0.02, tip_y, tip_v)], IVORY, top_color=(0.95, 0.93, 0.86))
        f.hull(m, [(S * 0.8 + 0.01, tip_y - dy * S * 0.5, tip_v - dv * S * 0.5), (S * 0.8 + 0.05, tip_y - dy * S * 0.5 + w * dv * 0.3, tip_v - dv * S * 0.5 + w * dy),
                   (S * 0.8 + 0.05, tip_y - dy * S * 0.5 - w * dv * 0.3, tip_v - dv * S * 0.5 - w * dy), (S * 0.8 + 0.03, tip_y, tip_v)], ORANGE)
    if battery:
        # Khối pin cạnh tua-bin, vạch sáng lam.
        f.box(m, -S * 0.4, RING_Y + S * 0.7, S * 1.9, (S * 1.4, S * 1.4, S * 1.2), STEEL, top_color=(0.45, 0.5, 0.55))
        f.box(m, -S * 0.4, RING_Y + S * 1.45, S * 1.9, (S * 1.0, 0.08, S * 0.8), GLOW, chamfer=0.0)
    if glow_ring:
        m.ring((c[0], 0, c[2]), S * 1.15, S * 1.32, RING_Y + S * 0.6, RING_Y + S * 0.82, 10, GLOW)


def cables(m, level):
    """Ống cáp cam chạy thành sáu cung quanh mép sàn; cấp 4 thêm dải sáng lam bên cạnh."""
    if level < 2:
        return
    radius = R * 0.9
    for k in range(6):
        a0, a1 = math.radians(60 * k + 8), math.radians(60 * k + 22)
        p0 = (math.cos(a0) * radius, math.sin(a0) * radius)
        p1 = (math.cos(a1) * radius, math.sin(a1) * radius)
        mid = ((p0[0] + p1[0]) / 2, (p0[1] + p1[1]) / 2)
        length = math.hypot(p1[0] - p0[0], p1[1] - p0[1])
        yaw = math.atan2(-(p1[1] - p0[1]), p1[0] - p0[0])
        m.box((mid[0], DECK + 0.12, mid[1]), (length, 0.24, 0.35), ORANGE, yaw=yaw, chamfer=0.0)
        if level >= 4:
            m.box((mid[0], DECK + 0.27, mid[1]), (length, 0.06, 0.18), GLOW, yaw=yaw, chamfer=0.0)


def build_level(level):
    m = kit.Model("bld_tidal_power_l%d" % level)
    turbine(m, 60, battery=level >= 2, glow_ring=level >= 5)
    if level >= 3:
        turbine(m, 240, battery=level >= 4, glow_ring=level >= 5)
    cables(m, level)
    return m.finish()


def build():
    return {"bld_tidal_power_l%d" % level: [build_level(level)] for level in range(1, 6)}
