"""Cua Giáp Gai (ENM_SPIKED_CRAB): mai rộng dẹt màu tím sẫm, hàng gai phát sáng lam ngọc, ba chân mỗi bên, hai càng to giơ ra
phía trước (mũi −z), hai mắt trên cuống. Dài 1,2 ô = 4,8 đơn vị, rộng khoảng 5,6. Màu gốc: data/enemies/spiked_crab.tres."""
import math

import kit

SHELL = (0.4, 0.22, 0.28)
SHELL_TOP = (0.52, 0.3, 0.36)
SHELL_DARK = (0.24, 0.12, 0.17)
LEG = (0.3, 0.16, 0.22)
CYAN = (0.3, 1.0, 0.95)
CYAN_DIM = (0.15, 0.6, 0.62)
BELLY = (0.62, 0.42, 0.4)
EYE = (0.95, 0.95, 0.9)
NAME = "enm_spiked_crab"


def spike(m, x, y, z, height, radius, lean_z=0.0):
    """Gai nón phát sáng lam ngọc, đế tối."""
    m.lathe([(0.0, y), (radius * 1.15, y), (radius * 0.75, y + height * 0.35), (radius * 0.3, y + height * 0.8), (0.0, y + height)], 6, CYAN,
            top_color=(0.7, 1.0, 1.0), center=(x, z))
    m.lathe([(0.0, y - 0.05), (radius * 1.4, y - 0.05), (radius * 1.2, y + 0.06), (0.0, y + 0.08)], 6, SHELL_DARK, center=(x, z))


def leg(m, side, z, spread):
    """Chân hai khúc: đùi nhô ra và lên, cẳng gập xuống chạm nước."""
    hip = (side * 1.5, 0.5, z)
    knee = (side * (2.35 + spread * 0.2), 0.95, z + spread * 0.25)
    foot = (side * (3.0 + spread * 0.3), -0.1, z + spread * 0.55)
    for (a, b, w) in ((hip, knee, 0.2), (knee, foot, 0.15)):
        m.hull([(a[0], a[1] - w, a[2] - w), (a[0], a[1] + w, a[2] - w), (a[0], a[1] - w, a[2] + w), (a[0], a[1] + w, a[2] + w),
                (b[0], b[1] - w * 0.7, b[2] - w * 0.7), (b[0], b[1] + w * 0.7, b[2] - w * 0.7),
                (b[0], b[1] - w * 0.7, b[2] + w * 0.7), (b[0], b[1] + w * 0.7, b[2] + w * 0.7)], LEG, top_color=(0.4, 0.22, 0.3))
    m.ellipsoid(knee, (0.24, 0.24, 0.24), 6, 3, CYAN_DIM)


def claw(m, side):
    """Càng: cánh tay, cổ tay, hai ngàm (trên và dưới) khép hình kìm."""
    shoulder = (side * 1.4, 0.55, -1.0)
    elbow = (side * 2.2, 0.8, -1.55)
    wrist = (side * 2.45, 0.75, -2.35)
    for (a, b, w) in ((shoulder, elbow, 0.25), (elbow, wrist, 0.22)):
        m.hull([(a[0] - w, a[1] - w, a[2]), (a[0] + w, a[1] - w, a[2]), (a[0] - w, a[1] + w, a[2]), (a[0] + w, a[1] + w, a[2]),
                (b[0] - w * 0.9, b[1] - w * 0.9, b[2]), (b[0] + w * 0.9, b[1] - w * 0.9, b[2]),
                (b[0] - w * 0.9, b[1] + w * 0.9, b[2]), (b[0] + w * 0.9, b[1] + w * 0.9, b[2])], SHELL, top_color=SHELL_TOP)
    m.ellipsoid(elbow, (0.3, 0.3, 0.3), 6, 3, CYAN_DIM)
    # Bàn càng phình, ngàm trên cong vào trong, ngàm dưới thẳng.
    palm = (side * 2.45, 0.78, -2.5)
    m.ellipsoid(palm, (0.42, 0.34, 0.5), 8, 4, SHELL, top_color=SHELL_TOP)
    inner = -side
    m.hull([(palm[0] - 0.22, palm[1] + 0.12, palm[2] - 0.2), (palm[0] + 0.22, palm[1] + 0.12, palm[2] - 0.2),
            (palm[0] - 0.2, palm[1] + 0.38, palm[2] - 0.2), (palm[0] + 0.2, palm[1] + 0.38, palm[2] - 0.2),
            (palm[0] + inner * 0.28 - 0.06, palm[1] + 0.2, palm[2] - 1.05), (palm[0] + inner * 0.28 + 0.06, palm[1] + 0.2, palm[2] - 1.05),
            (palm[0] + inner * 0.3, palm[1] + 0.3, palm[2] - 1.15)], SHELL_DARK, top_color=SHELL_TOP)
    m.hull([(palm[0] - 0.22, palm[1] - 0.18, palm[2] - 0.2), (palm[0] + 0.22, palm[1] - 0.18, palm[2] - 0.2),
            (palm[0] - 0.2, palm[1] + 0.02, palm[2] - 0.2), (palm[0] + 0.2, palm[1] + 0.02, palm[2] - 0.2),
            (palm[0] + inner * 0.2 - 0.05, palm[1] - 0.02, palm[2] - 1.0), (palm[0] + inner * 0.2 + 0.05, palm[1] - 0.02, palm[2] - 1.0)], SHELL_DARK)
    # Đầu ngàm phát sáng.
    m.ellipsoid((palm[0] + inner * 0.3, palm[1] + 0.26, palm[2] - 1.12), (0.1, 0.1, 0.12), 5, 3, CYAN)


def build():
    m = kit.Model(NAME)
    # Mai: elip dẹt, nắp mai nhô cao ở giữa; bụng sáng màu bên dưới.
    m.ellipsoid((0.0, 0.2, 0.0), (1.95, 0.3, 1.55), 14, 4, BELLY)
    m.lathe([(0.0, 0.2), (0.95, 0.3), (1.0, 0.6), (0.82, 0.88), (0.5, 1.0), (0.0, 1.04)], 14, SHELL, top_color=SHELL_TOP, center=(0.0, 0.0), scale=(1.9, 1.5))
    m.lathe([(0.9, 0.55), (1.0, 0.62), (1.0, 0.72), (0.9, 0.78)], 14, SHELL_DARK, center=(0.0, 0.0), scale=(1.9, 1.5), cap_bottom=False, cap_top=False)
    # Hàng gai lưng phát sáng, to dần về giữa, và gai bên mai.
    for k, z in enumerate((-0.8, -0.4, 0.0, 0.4, 0.8)):
        spike(m, 0.0, 1.0 - abs(z) * 0.05, z, 0.62 - abs(z) * 0.22, 0.17)
    for side in (-1.0, 1.0):
        for z in (-0.5, 0.5):
            spike(m, side * (1.15 - abs(z) * 0.1), 0.9, z, 0.42, 0.12)
    # Vân sáng lam trên mai.
    for side in (-1.0, 1.0):
        m.box((side * 0.55, 1.03, -0.2), (0.07, 0.04, 1.2), CYAN_DIM, chamfer=0.0)
    # Ba chân mỗi bên, hai càng, hai mắt trên cuống.
    for side in (-1.0, 1.0):
        for z, spread in ((-0.6, -0.6), (0.2, 0.0), (0.95, 0.6)):
            leg(m, side, z, spread)
        claw(m, side)
        m.box((side * 0.3, 1.0, -1.35), (0.1, 0.4, 0.1), SHELL_DARK, chamfer=0.0)
        m.ellipsoid((side * 0.3, 1.28, -1.4), (0.16, 0.16, 0.16), 6, 3, EYE)
        m.ellipsoid((side * 0.3, 1.3, -1.52), (0.07, 0.07, 0.05), 5, 3, (0.05, 0.05, 0.08))
    return [m.finish()]
