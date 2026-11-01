"""Giàn khoan dầu khí cũ (PLT_OLD_OIL_RIG): sàn vuông trên bốn chân trụ, tháp khoan, ống đuốc, cần cẩu, bãi đáp trực thăng, nhà ở.
Toạ độ cục bộ: gốc ở mặt nước giữa giàn, y lên. Mặt sàn ở y = DECK; vùng giữa sàn (bán kính 2,2) để trống cho bệ lô cốt."""
import math

import kit

DECK = 2.2
RUST = (0.52, 0.27, 0.15)
RUST_DARK = (0.3, 0.17, 0.11)
MUSTARD = (0.86, 0.63, 0.16)
GREY = (0.38, 0.4, 0.42)
IVORY = (0.84, 0.8, 0.7)
DARK = (0.12, 0.13, 0.15)
ORANGE = (1.0, 0.45, 0.1)
GREEN = (0.17, 0.33, 0.27)
SEA = (0.16, 0.4, 0.62)


def beam(m, a, b, thick, color):
    """Thanh nghiêng từ điểm a tới điểm b (vỏ lồi hai đầu vuông)."""
    t = thick / 2
    pts = []
    for p in (a, b):
        for dx in (-t, t):
            for dz in (-t, t):
                pts.append((p[0] + dx, p[1], p[2] + dz))
    m.hull(pts, color)


def build():
    m = kit.Model("plt_old_oil_rig")
    # Bốn chân trụ lún xuống nước, có đai ngang rỉ sét và vệt hà.
    for sx in (-1, 1):
        for sz in (-1, 1):
            m.prism((sx * 2.7, 0, sz * 2.7), 0.34, -1.2, DECK, 8, RUST_DARK, top_radius=0.3)
            m.prism((sx * 2.7, 0, sz * 2.7), 0.4, -0.15, 0.55, 8, GREY)
            m.prism((sx * 2.7, 0, sz * 2.7), 0.38, 1.2, 1.4, 8, RUST)
    for y in (0.35, 1.3):
        for s in (-1, 1):
            m.box((s * 2.7, y, 0), (0.16, 0.16, 5.4), RUST, chamfer=0.0)
            m.box((0, y, s * 2.7), (5.4, 0.16, 0.16), RUST, chamfer=0.0)
    # Giằng chéo đứng ở bốn mặt.
    for s in (-1, 1):
        beam(m, (-2.7, 0.35, s * 2.7), (2.7, 1.3, s * 2.7), 0.14, RUST_DARK)
        beam(m, (s * 2.7, 0.35, -2.7), (s * 2.7, 1.3, 2.7), 0.14, RUST_DARK)
    # Sàn chính và mép sàn.
    m.box((0, DECK - 0.22, 0), (6.8, 0.44, 6.8), RUST_DARK, top_color=GREY)
    m.box((0, DECK - 0.5, 0), (6.2, 0.2, 6.2), RUST)
    # Lan can vàng quanh sàn, có chừa lối.
    for s in (-1, 1):
        m.box((s * 3.35, DECK + 0.5, 0), (0.08, 0.08, 6.6), MUSTARD, chamfer=0.0)
        m.box((0, DECK + 0.5, s * 3.35), (6.6, 0.08, 0.08), MUSTARD, chamfer=0.0)
        m.box((s * 3.35, DECK + 0.22, 0), (0.06, 0.06, 6.6), MUSTARD, chamfer=0.0)
        m.box((0, DECK + 0.22, s * 3.35), (6.6, 0.06, 0.06), MUSTARD, chamfer=0.0)
    for i in range(-3, 4):
        for s in (-1, 1):
            m.box((s * 3.35, DECK + 0.3, i * 1.0), (0.08, 0.6, 0.08), MUSTARD, chamfer=0.0)
            m.box((i * 1.0, DECK + 0.3, s * 3.35), (0.08, 0.6, 0.08), MUSTARD, chamfer=0.0)
    # Vòng vạch vàng đánh dấu chỗ đặt lô cốt.
    m.ring((0, DECK, 0), 2.0, 2.2, 0.0, 0.05, 24, MUSTARD)
    # Tháp khoan: chóp cụt gỉ sét ở góc sau trái, dải ngang, đỉnh puly.
    m.prism((-2.3, 0, -2.3), 0.95, DECK, DECK + 6.4, 4, RUST, top_radius=0.28, top_color=MUSTARD, yaw=math.pi / 4)
    for y in (DECK + 1.6, DECK + 3.2, DECK + 4.8):
        m.prism((-2.3, 0, -2.3), 0.72 - (y - DECK) * 0.1, y, y + 0.14, 4, MUSTARD, yaw=math.pi / 4)
    m.box((-2.3, DECK + 6.65, -2.3), (0.7, 0.4, 0.7), DARK)
    m.box((-2.3, DECK + 7.1, -2.3), (0.1, 0.5, 0.1), ORANGE, chamfer=0.0)
    # Nhà ở và đài chỉ huy ở bên phải.
    m.box((2.2, DECK + 0.9, -1.3), (1.6, 1.8, 2.0), IVORY, top_color=RUST_DARK)
    m.box((2.2, DECK + 2.1, -1.3), (1.2, 0.8, 1.5), GREY, top_color=RUST_DARK)
    for i in range(3):
        m.box((1.38, DECK + 1.0, -1.9 + i * 0.6), (0.04, 0.36, 0.34), DARK, chamfer=0.0)
    m.box((1.38, DECK + 2.1, -1.3), (0.04, 0.4, 1.2), DARK, chamfer=0.0)
    m.box((2.2, DECK + 2.7, -1.3), (0.06, 0.8, 0.06), ORANGE, chamfer=0.0)
    # Bồn chứa và ống dẫn tới tháp.
    for x in (-0.5, 0.7):
        m.prism((x, 0, -2.6), 0.5, DECK, DECK + 1.1, 12, GREY, top_color=RUST)
        m.prism((x, 0, -2.6), 0.54, DECK + 0.5, DECK + 0.6, 12, MUSTARD)
    m.tube((-1.4, DECK + 0.3), 0.14, 0.14, -2.7, -2.4, 8, GREY)
    m.box((-1.4, DECK + 0.3, -2.6), (1.4, 0.2, 0.2), GREY, chamfer=0.0)
    # Cần cẩu cam ở góc sau phải của mặt trước.
    m.prism((2.6, 0, 2.3), 0.3, DECK, DECK + 1.2, 8, GREY)
    m.box((2.6, DECK + 1.45, 2.3), (0.7, 0.5, 0.7), ORANGE)
    beam(m, (2.6, DECK + 1.5, 2.3), (0.9, DECK + 3.6, 2.9), 0.18, ORANGE)
    m.box((0.9, DECK + 2.7, 2.9), (0.04, 1.8, 0.04), DARK, chamfer=0.0)
    m.box((0.9, DECK + 1.7, 2.9), (0.18, 0.2, 0.18), DARK)
    # Ống đuốc nghiêng ra ngoài với ngọn lửa tắt (đen xỉn, đầu cháy sém).
    beam(m, (-2.9, DECK, 2.7), (-4.1, DECK + 5.0, 4.0), 0.2, GREY)
    m.prism((-4.1, 0, 4.0), 0.22, DECK + 4.9, DECK + 5.3, 8, DARK, top_radius=0.3)
    m.ellipsoid((-4.1, DECK + 5.8, 4.0), (0.14, 0.4, 0.14), 6, 4, ORANGE)
    # Bãi đáp trực thăng nhô ra phía trước: vành tròn xanh có chữ H.
    for dx in (-0.8, 0.8):
        m.box((dx, DECK - 0.15, 3.9), (0.2, 0.2, 1.8), RUST_DARK, chamfer=0.0)
    m.prism((0, 0, 4.9), 1.55, DECK - 0.2, DECK, 16, GREEN, top_color=GREEN)
    m.box((-0.35, DECK + 0.02, 4.9), (0.12, 0.04, 0.9), IVORY, chamfer=0.0)
    m.box((0.35, DECK + 0.02, 4.9), (0.12, 0.04, 0.9), IVORY, chamfer=0.0)
    m.box((0, DECK + 0.02, 4.9), (0.7, 0.04, 0.12), IVORY, chamfer=0.0)
    # Xuồng cứu sinh cam treo bên trái.
    m.ellipsoid((-3.55, DECK - 0.1, -0.6), (0.3, 0.3, 0.8), 8, 5, ORANGE)
    m.box((-3.45, DECK + 0.25, -0.6), (0.06, 0.5, 0.06), DARK, chamfer=0.0)
    # Phao biển báo ở chân tây nam.
    m.prism((3.4, 0, -3.4), 0.18, -0.2, 0.9, 8, SEA, top_radius=0.12)
    return [m.finish()]
