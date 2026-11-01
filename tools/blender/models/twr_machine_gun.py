"""Súng Máy (TWR_MACHINE_GUN): đế lục giác trắng ngà (cột xanh biển) và đầu nòng bốn nòng xoay riêng.
Toạ độ giống TowerMeshes: đế tính từ gốc lô cốt (mặt bệ ở y = 0,7); đầu nòng tính từ trục xoay (cao 1,35 so với gốc),
thân súng quanh y = 0,7, nòng hướng −z, đầu nòng cách trục 1,6 (BARREL_LENGTH)."""
import kit
import tower_base

DARK = (0.12, 0.13, 0.15)
STEEL = (0.32, 0.36, 0.4)
IVORY = (0.88, 0.85, 0.77)
ORANGE = (1.0, 0.45, 0.1)
COLUMN = (0.16, 0.42, 0.66)  # data/towers/machine_gun.tres


def build():
    base = tower_base.build("twr_machine_gun_base", COLUMN)
    m = kit.Model("twr_machine_gun_turret")
    y = 0.7
    # Vỏ súng: khối vát nghiêng về phía nòng, mặt trên ngà, sọc cam.
    m.hull([
        (-0.6, y - 0.3, 0.7), (0.6, y - 0.3, 0.7), (-0.6, y + 0.3, 0.7), (0.6, y + 0.3, 0.7),
        (-0.5, y - 0.3, -0.35), (0.5, y - 0.3, -0.35), (-0.46, y + 0.25, -0.35), (0.46, y + 0.25, -0.35),
    ], (0.16, 0.42, 0.66), top_color=IVORY)
    m.box((0.0, y + 0.33, 0.2), (0.26, 0.05, 0.9), ORANGE)
    # Hộp đạn bên hông và kính ngắm trên nóc.
    m.box((0.74, y - 0.05, 0.35), (0.3, 0.42, 0.55), STEEL, top_color=(0.45, 0.5, 0.55))
    m.box((0.74, y + 0.2, 0.35), (0.34, 0.06, 0.6), ORANGE)
    m.box((-0.34, y + 0.45, 0.4), (0.22, 0.22, 0.4), DARK)
    m.tube((-0.34, y + 0.45), 0.09, 0.09, -0.02, -0.12, 8, (0.45, 0.7, 0.85))
    # Cụm nòng: lõi trung tâm, bốn nòng quanh, hai vòng giữ, vành cam ở miệng.
    m.tube((0.0, y), 0.3, 0.3, -0.35, -0.5, 10, STEEL)
    for dx, dy in ((-0.14, -0.14), (0.14, -0.14), (-0.14, 0.14), (0.14, 0.14)):
        m.tube((dx, y + dy), 0.065, 0.065, -0.5, -1.5, 8, DARK)
    m.tube((0.0, y), 0.075, 0.075, -0.5, -1.45, 8, STEEL)
    m.tube((0.0, y), 0.27, 0.27, -0.72, -0.82, 12, STEEL)
    m.tube((0.0, y), 0.27, 0.27, -1.1, -1.2, 12, STEEL)
    m.tube((0.0, y), 0.27, 0.27, -1.5, -1.6, 12, ORANGE)
    return {"twr_machine_gun_base": [base], "twr_machine_gun_turret": [m.finish()]}
