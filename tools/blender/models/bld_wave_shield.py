"""Tường Chắn Sóng (BLD_WAVE_SHIELD), 5 cấp: tường bao quanh cả vành đảo chính, có khe ở sáu mỏm bến và sáu tháp góc.
Toạ độ cục bộ của đảo chính (tâm ở gốc, bán kính 14, mặt sàn y = 0,8). Cao và dày dần mỗi cấp:
cấp 2 thêm sọc cam thứ hai, cấp 3 chân chắn sóng và mép hất sóng, cấp 4 đèn trên tường và mái tháp góc, cấp 5 hàng kính và đèn hiệu."""
import math

import kit

R = 14.0
DECK_Y = 0.8
PIER_GAP = 3.4 + 0.6
IVORY = (0.88, 0.85, 0.77)
IVORY_TOP = (0.94, 0.91, 0.84)
SEA_BLUE = (0.13, 0.36, 0.6)
ORANGE = (1.0, 0.45, 0.1)
STEEL = (0.32, 0.36, 0.4)
DARK = (0.12, 0.13, 0.15)
GLASS = (0.55, 0.78, 0.9)
LAMP = (1.0, 0.82, 0.45)


def wall_height(level):
    return 1.1 + 0.3 * (level - 1)


def wall_thickness(level):
    return R * 0.07 * (1.0 + 0.15 * (level - 1))


def build_level(level):
    m = kit.Model("bld_wave_shield_l%d" % level)
    height = wall_height(level)
    thick = wall_thickness(level)
    inset = R - thick * 0.6
    for k in range(6):
        a0, a1 = math.radians(60 * k), math.radians(60 * (k + 1))
        v0 = (math.cos(a0) * inset, math.sin(a0) * inset)
        v1 = (math.cos(a1) * inset, math.sin(a1) * inset)
        dx, dz = v1[0] - v0[0], v1[1] - v0[1]
        edge = math.hypot(dx, dz)
        ax, az = dx / edge, dz / edge
        seg = (edge - PIER_GAP) / 2
        yaw = math.atan2(-az, ax)
        outward = (math.cos(math.radians(30 + 60 * k)), math.sin(math.radians(30 + 60 * k)))
        for side in (0, 1):
            start = v0 if side == 0 else (v1[0] - ax * seg, v1[1] - az * seg)
            mx, mz = start[0] + ax * seg * 0.5, start[1] + az * seg * 0.5
            _segment(m, level, mx, mz, seg, thick, height, yaw, outward, ax, az)
        _bastion(m, level, v0, 60 * k)
    return m.finish()


def _segment(m, level, mx, mz, seg, thick, height, yaw, outward, ax, az):
    ox, oz = outward
    # Thân tường thu nhỏ nhẹ lên đỉnh: vỏ lồi với mặt trên hẹp hơn.
    def at(u, y, w):
        # u dọc tường, w ngang tường (dương là hướng ra ngoài)
        return (mx + ax * u + ox * w, DECK_Y + y, mz + az * u + oz * w)
    h, hl, ht = height, seg / 2, thick / 2
    pts = [at(-hl, 0, -ht), at(hl, 0, -ht), at(-hl, 0, ht), at(hl, 0, ht),
           at(-hl, h, -ht * 0.8), at(hl, h, -ht * 0.8), at(-hl, h, ht * 0.8), at(hl, h, ht * 0.8)]
    m.hull(pts, IVORY, top_color=IVORY_TOP)
    # Dải chân tường xám thép.
    m.hull([at(-hl, 0, -ht * 1.02), at(hl, 0, -ht * 1.02), at(-hl, 0, ht * 1.02), at(hl, 0, ht * 1.02),
            at(-hl, 0.3, -ht), at(hl, 0.3, -ht), at(-hl, 0.3, ht), at(hl, 0.3, ht)], STEEL)
    # Sọc cam mặt ngoài; cấp 2 trở lên thêm sọc gần đỉnh.
    m.hull([at(-hl * 0.98, 0.5, ht), at(hl * 0.98, 0.5, ht), at(-hl * 0.98, 0.5, ht + 0.06), at(hl * 0.98, 0.5, ht + 0.06),
            at(-hl * 0.98, 0.78, ht), at(hl * 0.98, 0.78, ht), at(-hl * 0.98, 0.78, ht + 0.06), at(hl * 0.98, 0.78, ht + 0.06)], ORANGE)
    if level >= 2:
        y = height - 0.35
        m.hull([at(-hl * 0.98, y, ht * 0.85), at(hl * 0.98, y, ht * 0.85), at(-hl * 0.98, y, ht * 0.85 + 0.06), at(hl * 0.98, y, ht * 0.85 + 0.06),
                at(-hl * 0.98, y + 0.18, ht * 0.8), at(hl * 0.98, y + 0.18, ht * 0.8), at(-hl * 0.98, y + 0.18, ht * 0.8 + 0.06), at(hl * 0.98, y + 0.18, ht * 0.8 + 0.06)], ORANGE)
    # Khe thoát nước nhỏ (rãnh tối) làm nhịp cho mặt tường.
    for frac in (-0.5, 0.0, 0.5):
        u = hl * frac
        m.box(at(u, 0.22, ht + 0.02), (0.22, 0.14, 0.05), DARK, yaw=yaw, chamfer=0.0)
    if level >= 3:
        # Chân chắn sóng nhô ra ngoài (xám thép, vát) và mép hất sóng gần đỉnh tường.
        m.hull([at(-hl, 0, ht), at(hl, 0, ht), at(-hl, 0, ht + 0.85), at(hl, 0, ht + 0.85),
                at(-hl, 0.5, ht), at(hl, 0.5, ht), at(-hl, 0.3, ht + 0.85), at(hl, 0.3, ht + 0.85)], STEEL, top_color=(0.45, 0.5, 0.55))
        m.hull([at(-hl, height - 0.15, ht * 0.8), at(hl, height - 0.15, ht * 0.8), at(-hl, height - 0.15, ht + 0.4), at(hl, height - 0.15, ht + 0.4),
                at(-hl, height + 0.1, ht * 0.8), at(hl, height + 0.1, ht * 0.8), at(-hl, height + 0.25, ht + 0.35), at(hl, height + 0.25, ht + 0.35)], IVORY_TOP)
    if level >= 4:
        # Đèn trên tường: trụ đen, đầu đèn sáng.
        m.box(at(0.0, height + 0.35, 0.0), (0.3, 0.7, 0.3), DARK, yaw=yaw, chamfer=0.0)
        m.ellipsoid(at(0.0, height + 0.88, 0.0), (0.24, 0.16, 0.24), 8, 4, LAMP)
    if level >= 5:
        # Hàng kính chắn gió trên đỉnh tường, khung cam.
        m.hull([at(-hl * 0.96, height, -ht * 0.4), at(hl * 0.96, height, -ht * 0.4), at(-hl * 0.96, height, ht * 0.4), at(hl * 0.96, height, ht * 0.4),
                at(-hl * 0.96, height + 0.8, -ht * 0.3), at(hl * 0.96, height + 0.8, -ht * 0.3), at(-hl * 0.96, height + 0.8, ht * 0.3), at(hl * 0.96, height + 0.8, ht * 0.3)], GLASS)
        m.hull([at(-hl * 0.97, height + 0.78, -ht * 0.4), at(hl * 0.97, height + 0.78, -ht * 0.4), at(-hl * 0.97, height + 0.78, ht * 0.4), at(hl * 0.97, height + 0.78, ht * 0.4),
                at(-hl * 0.97, height + 0.9, -ht * 0.4), at(hl * 0.97, height + 0.9, -ht * 0.4), at(-hl * 0.97, height + 0.9, ht * 0.4), at(hl * 0.97, height + 0.9, ht * 0.4)], ORANGE)


def _bastion(m, level, v0, degrees):
    """Tháp góc lục giác thu dần lên đỉnh; cao thêm theo cấp, mái nón từ cấp 4, đèn hiệu cấp 5."""
    top = DECK_Y + 1.6 + 0.35 * (level - 1)
    r0 = R * 0.1
    yaw = math.radians(degrees)
    c = (v0[0], 0.0, v0[1])
    m.prism(c, r0, DECK_Y - 0.4, top, 6, IVORY, top_radius=r0 * 0.9, top_color=SEA_BLUE, yaw=yaw)
    m.ring(c, r0 * 0.88, r0 * 1.04, top - 0.35, top - 0.05, 6, ORANGE, yaw=yaw)
    # Ô cửa sổ tối quanh thân tháp.
    for i in range(6):
        a = yaw + math.tau * (i + 0.5) / 6
        m.box((v0[0] + math.cos(a) * r0 * 0.88, DECK_Y + 0.9, v0[1] + math.sin(a) * r0 * 0.88), (0.22, 0.4, 0.06), DARK, yaw=-a, chamfer=0.0)
    if level >= 4:
        m.lathe([(r0 * 1.0, top), (r0 * 0.8, top + 0.35), (r0 * 0.4, top + 0.75), (0.0, top + 0.95)], 6, SEA_BLUE, center=v0, yaw=yaw, cap_bottom=False)
    if level >= 5:
        m.ellipsoid((v0[0], top + 1.1, v0[1]), (0.2, 0.2, 0.2), 8, 4, LAMP)


def build():
    return {"bld_wave_shield_l%d" % level: [build_level(level)] for level in range(1, 6)}
