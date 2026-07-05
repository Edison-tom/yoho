#!/usr/bin/env python3
"""Generate all 15 Yoho UI screens in 3D hyper-realistic glass style."""
import os, math

OUT = "/Volumes/file/Codex/Yoho/macOS端/design/svgs_3d"
os.makedirs(OUT, exist_ok=True)

W, H = 280, 400  # slightly larger canvas
R = 20

# ===== Design System =====
BG_START = "#0a0a1a"
BG_END = "#141430"
GLASS = "rgba(255,255,255,0.06)"
GLASS_BORDER = "rgba(255,255,255,0.08)"
GLASS_HIGHLIGHT = "rgba(255,255,255,0.03)"
CARD_BG = "rgba(255,255,255,0.04)"
CARD_BORDER = "rgba(255,255,255,0.06)"
TEXT_PRIMARY = "#f1f5f9"
TEXT_SECONDARY = "#94a3b8"
TEXT_MUTED = "#64748b"
ACCENT_GREEN = "#10b981"
ACCENT_GREEN_GLOW = "#34d399"
ACCENT_BLUE = "#3b82f6"
ACCENT_BLUE_GLOW = "#60a5fa"
ACCENT_AMBER = "#f59e0b"
ACCENT_ROSE = "#ec4899"
ACCENT_ROSE_GLOW = "#f472b6"
ACCENT_PURPLE = "#8b5cf6"

# Shared defs for all screens
SHARED_DEFS = f'''<defs>
    <!-- Background gradient -->
    <linearGradient id="bgGrad" x1="0%" y1="0%" x2="100%" y2="100%">
        <stop offset="0%" stop-color="{BG_START}"/>
        <stop offset="50%" stop-color="#111138"/>
        <stop offset="100%" stop-color="{BG_END}"/>
    </linearGradient>
    <!-- Glass surface gradient -->
    <linearGradient id="glassGrad" x1="0%" y1="0%" x2="0%" y2="100%">
        <stop offset="0%" stop-color="rgba(255,255,255,0.10)"/>
        <stop offset="100%" stop-color="rgba(255,255,255,0.03)"/>
    </linearGradient>
    <!-- Card gradient -->
    <linearGradient id="cardGrad" x1="0%" y1="0%" x2="0%" y2="100%">
        <stop offset="0%" stop-color="rgba(255,255,255,0.08)"/>
        <stop offset="100%" stop-color="rgba(255,255,255,0.02)"/>
    </linearGradient>
    <!-- Accent green gradient -->
    <linearGradient id="greenGrad" x1="0%" y1="0%" x2="100%" y2="100%">
        <stop offset="0%" stop-color="#10b981"/>
        <stop offset="100%" stop-color="#059669"/>
    </linearGradient>
    <!-- Accent blue gradient -->
    <linearGradient id="blueGrad" x1="0%" y1="0%" x2="100%" y2="100%">
        <stop offset="0%" stop-color="#3b82f6"/>
        <stop offset="100%" stop-color="#2563eb"/>
    </linearGradient>
    <!-- Accent amber gradient -->
    <linearGradient id="amberGrad" x1="0%" y1="0%" x2="100%" y2="100%">
        <stop offset="0%" stop-color="#f59e0b"/>
        <stop offset="100%" stop-color="#d97706"/>
    </linearGradient>
    <!-- Accent rose gradient -->
    <linearGradient id="roseGrad" x1="0%" y1="0%" x2="100%" y2="100%">
        <stop offset="0%" stop-color="#ec4899"/>
        <stop offset="100%" stop-color="#db2777"/>
    </linearGradient>
    <!-- Deep shadow -->
    <filter id="shadowDeep" x="-20%" y="-20%" width="140%" height="140%">
        <feDropShadow dx="0" dy="8" stdDeviation="16" flood-color="#000" flood-opacity="0.4"/>
    </filter>
    <!-- Medium shadow -->
    <filter id="shadowMed" x="-20%" y="-20%" width="140%" height="140%">
        <feDropShadow dx="0" dy="4" stdDeviation="8" flood-color="#000" flood-opacity="0.3"/>
    </filter>
    <!-- Button shadow -->
    <filter id="shadowBtn" x="-20%" y="-20%" width="140%" height="140%">
        <feDropShadow dx="0" dy="2" stdDiviation="4" flood-color="#000" flood-opacity="0.25"/>
    </filter>
    <!-- Glow filter -->
    <filter id="glow" x="-50%" y="-50%" width="200%" height="200%">
        <feGaussianBlur stdDeviation="3" result="blur"/>
        <feComposite in="SourceGraphic" in2="blur" operator="over"/>
    </filter>
    <!-- Glass reflection -->
    <linearGradient id="glassReflect" x1="0%" y1="0%" x2="0%" y2="100%">
        <stop offset="0%" stop-color="rgba(255,255,255,0.15)"/>
        <stop offset="40%" stop-color="rgba(255,255,255,0.0)"/>
        <stop offset="100%" stop-color="rgba(255,255,255,0.02)"/>
    </linearGradient>
</defs>'''

def svg_tag(content, w=W, h=H):
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">\n{SHARED_DEFS}\n{content}\n</svg>'

def bg_rect():
    return f'<rect width="{W}" height="{H}" fill="url(#bgGrad)" rx="0"/>'

def glass_panel(x, y, w, h, rx=R, extra=""):
    return f'''<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{rx}" fill="url(#glassGrad)" stroke="{GLASS_BORDER}" stroke-width="0.5" filter="url(#shadowDeep)"/>
    <rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{rx}" fill="url(#glassReflect)" />{extra}'''

def card(x, y, w, h, rx=12, acc=""):
    return f'''<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{rx}" fill="url(#cardGrad)" stroke="{CARD_BORDER}" stroke-width="0.5" filter="url(#shadowMed)"/>{acc}'''

def btn_3d(x, y, w, h, rx=10, color=ACCENT_GREEN, label="", icon=""):
    y_off = 2
    return f'''<rect x="{x}" y="{y+y_off}" width="{w}" height="{h}" rx="{rx}" fill="{color}" opacity="0.15" filter="url(#shadowBtn)"/>
    <rect x="{x}" y="{y}" width="{w}" height="{h-1}" rx="{rx}" fill="{color}" opacity="0.25" stroke="{color}" stroke-width="0.5" stroke-opacity="0.3"/>
    <rect x="{x}" y="{y}" width="{w}" height="{h/2}" rx="{rx}" fill="rgba(255,255,255,0.08)"/>
    <text x="{x+w/2}" y="{y+h/2+4}" font-family="Inter,Noto Sans SC,sans-serif" font-size="{h*0.36}" font-weight="600" fill="{color}" text-anchor="middle">{icon} {label}</text>'''

def text_label(x, y, txt, size=11, color=TEXT_SECONDARY, weight="500", anchor="start"):
    return f'<text x="{x}" y="{y}" font-family="Inter,Noto Sans SC,sans-serif" font-size="{size}" font-weight="{weight}" fill="{color}" text-anchor="{anchor}">{txt}</text>'

def title_bar(title, x=16, y=32):
    return f'<text x="{x}" y="{y}" font-family="Inter,Noto Sans SC,sans-serif" font-size="15" font-weight="700" fill="{TEXT_PRIMARY}">{title}</text>'

def progress_bar(x, y, w, h, pct, color=ACCENT_GREEN):
    fill_w = max(4, w * pct / 100)
    return f'''<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{h/2}" fill="rgba(255,255,255,0.06)"/>
    <rect x="{x}" y="{y}" width="{fill_w}" height="{h}" rx="{h/2}" fill="{color}" opacity="0.8"/>
    <rect x="{x}" y="{y}" width="{fill_w}" height="{h/2}" rx="{h/2}" fill="rgba(255,255,255,0.12)"/>'''

def pill(x, y, w, h, label, color=ACCENT_GREEN, active=False):
    op = "0.25" if active else "0.08"
    txt_op = color if active else TEXT_MUTED
    return f'''<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{h/2}" fill="{color}" opacity="{op}" stroke="{color}" stroke-width="0.5" stroke-opacity="0.2"/>
    <text x="{x+w/2}" y="{y+h/2+4}" font-family="Inter,Noto Sans SC,sans-serif" font-size="10" font-weight="500" fill="{txt_op}" text-anchor="middle">{label}</text>'''


# ===== Screen 1: MainWindow =====
def main_window():
    content = f'''{bg_rect()}
    {glass_panel(12, 12, W-24, H-24)}
    {title_bar("Yoho", 28, 38)}
    <text x="{W/2}" y="110" font-family="Inter,Noto Sans SC,sans-serif" font-size="52" font-weight="400" fill="{TEXT_PRIMARY}" text-anchor="middle">🐱</text>
    <text x="{W/2}" y="138" font-family="Inter,Noto Sans SC,sans-serif" font-size="15" font-weight="700" fill="{TEXT_PRIMARY}" text-anchor="middle">小 Yo</text>
    <text x="{W/2}" y="160" font-family="Inter,Noto Sans SC,sans-serif" font-size="11" font-weight="400" fill="{TEXT_SECONDARY}" text-anchor="middle">今日陪我 2h 啦～</text>
    {card(24, 176, W-48, 70)}
    {text_label(40, 198, "今日目标", 11, TEXT_SECONDARY)}
    {progress_bar(40, 212, W-72, 6, 60)}
    <text x="40" y="234" font-family="Inter,Noto Sans SC,sans-serif" font-size="10" font-weight="500" fill="{ACCENT_GREEN}">🚀 完成 3/5</text>
    <text x="{W-44}" y="234" font-family="Inter,Noto Sans SC,sans-serif" font-size="10" font-weight="600" fill="{ACCENT_GREEN}" text-anchor="end">60%</text>
    {btn_3d(28, 264, 52, 44, 10, ACCENT_GREEN, "喂食", "🍪")}
    {btn_3d(92, 264, 52, 44, 10, ACCENT_BLUE, "玩耍", "🎾")}
    {btn_3d(156, 264, 52, 44, 10, ACCENT_AMBER, "树木", "🌲")}
    {btn_3d(28, 320, 200, 44, 12, ACCENT_PURPLE, "团队模式", "👥")}
'''
    return svg_tag(content)

# ===== Screen 2: PetView =====
def pet_view():
    content = f'''{bg_rect()}
    {glass_panel(12, 12, W-24, H-24)}
    {title_bar("🐱 小 Yo", 28, 38)}
    <text x="{W/2}" y="130" font-family="Inter,Noto Sans SC,sans-serif" font-size="64" font-weight="400" fill="{TEXT_PRIMARY}" text-anchor="middle">🐱</text>
    {card(24, 170, W-48, 80)}
    {text_label(40, 192, "心情", 11, TEXT_SECONDARY)}
    {progress_bar(40, 206, W-72, 6, 78, ACCENT_GREEN)}
    <text x="40" y="228" font-family="Inter,Noto Sans SC,sans-serif" font-size="10" fill="{TEXT_SECONDARY}">😊 开心 78%</text>
    {text_label(40, 244, "精力", 10, TEXT_MUTED)}
    {progress_bar(40, 252, W-72, 4, 45, ACCENT_BLUE)}
    {card(24, 268, W-48, 56)}
    {text_label(40, 292, "今日互动", 11, TEXT_SECONDARY)}
    <text x="{W-40}" y="292" font-family="Inter,Noto Sans SC,sans-serif" font-size="12" font-weight="700" fill="{ACCENT_GREEN}" text-anchor="end">12 次</text>
    {text_label(40, 310, "喂食 5  玩耍 4  抚摸 3", 9, TEXT_MUTED)}
'''
    return svg_tag(content)

# ===== Screen 3: PetAnimationView =====
def pet_animation_view():
    content = f'''{bg_rect()}
    {glass_panel(12, 12, W-24, H-24)}
    {title_bar("🎬 宠物动画", 28, 38)}
    <text x="{W/2}" y="140" font-family="Inter,Noto Sans SC,sans-serif" font-size="56" font-weight="400" fill="{TEXT_PRIMARY}" text-anchor="middle">🐱✨</text>
    {card(24, 180, W-48, 60)}
    {text_label(40, 204, "当前动画", 11, TEXT_SECONDARY)}
    <text x="40" y="224" font-family="Inter,Noto Sans SC,sans-serif" font-size="14" font-weight="700" fill="{ACCENT_GREEN}">🎬 开心跳跃</text>
    {pill(40, 256, 56, 28, "待机")}
    {pill(104, 256, 56, 28, "开心", ACCENT_GREEN, True)}
    {pill(168, 256, 56, 28, "睡觉")}
    {pill(40, 294, 56, 28, "进食")}
    {pill(104, 294, 56, 28, "玩耍")}
    {pill(168, 294, 56, 28, "疲劳")}
'''
    return svg_tag(content)

# ===== Screen 4: TreeView =====
def tree_view():
    content = f'''{bg_rect()}
    {glass_panel(12, 12, W-24, H-24)}
    {title_bar("🌲 我的树", 28, 38)}
    <text x="{W/2}" y="130" font-family="Inter,Noto Sans SC,sans-serif" font-size="64" font-weight="400" fill="{TEXT_PRIMARY}" text-anchor="middle">🌳</text>
    {card(24, 170, W-48, 80)}
    {text_label(40, 194, "成长进度", 11, TEXT_SECONDARY)}
    {progress_bar(40, 210, W-72, 8, 72, ACCENT_GREEN)}
    <text x="40" y="234" font-family="Inter,Noto Sans SC,sans-serif" font-size="10" fill="{TEXT_SECONDARY}">小树苗 → 大树 🌱 72%</text>
    {text_label(40, 250, "今日浇水 3 次 · 施肥 1 次", 9, TEXT_MUTED)}
    {card(24, 268, W-48, 56)}
    {text_label(40, 292, "树种", 10, TEXT_SECONDARY)}
    <text x="40" y="310" font-family="Inter,Noto Sans SC,sans-serif" font-size="13" fill="{ACCENT_GREEN}">🌲 松树 · Lv.4</text>
'''
    return svg_tag(content)

# ===== Screen 5: TreeSwitcherView =====
def tree_switcher_view():
    content = f'''{bg_rect()}
    {glass_panel(12, 12, W-24, H-24)}
    {title_bar("🌲 我的树木", 28, 38)}
    {card(24, 56, W-48, 50)}
    <text x="40" y="78" font-family="Inter,Noto Sans SC,sans-serif" font-size="13" font-weight="600" fill="{TEXT_PRIMARY}">🌲 松树</text>
    <text x="{W-40}" y="78" font-family="Inter,Noto Sans SC,sans-serif" font-size="10" fill="{ACCENT_GREEN}" text-anchor="end">使用中</text>
    <text x="40" y="96" font-family="Inter,Noto Sans SC,sans-serif" font-size="9" fill="{TEXT_MUTED}">已陪伴 30 天 · Lv.4</text>
    {card(24, 116, W-48, 50)}
    <text x="40" y="138" font-family="Inter,Noto Sans SC,sans-serif" font-size="13" font-weight="600" fill="{TEXT_SECONDARY}">🌸 樱花树</text>
    {progress_bar(40, 152, W-72, 3, 45, ACCENT_ROSE)}
    {card(24, 176, W-48, 50)}
    <text x="40" y="198" font-family="Inter,Noto Sans SC,sans-serif" font-size="13" font-weight="600" fill="{TEXT_SECONDARY}">🌴 棕榈树</text>
    {progress_bar(40, 212, W-72, 3, 20, ACCENT_AMBER)}
    {card(24, 236, W-48, 50)}
    <text x="40" y="258" font-family="Inter,Noto Sans SC,sans-serif" font-size="13" font-weight="600" fill="{TEXT_SECONDARY}">🍎 苹果树</text>
    {progress_bar(40, 272, W-72, 3, 85, ACCENT_GREEN)}
'''
    return svg_tag(content)

# ===== Screen 6: InteractionMenu =====
def interaction_menu():
    content = f'''{bg_rect()}
    {glass_panel(12, 12, W-24, H-24)}
    {title_bar("🎯 互动", 28, 38)}
    {btn_3d(28, 64, 200, 48, 12, ACCENT_GREEN, "喂食", "🍪")}
    {btn_3d(28, 124, 200, 48, 12, ACCENT_BLUE, "玩耍", "🎾")}
    {btn_3d(28, 184, 200, 48, 12, ACCENT_AMBER, "抚摸", "🤚")}
    {btn_3d(28, 244, 200, 48, 12, ACCENT_PURPLE, "训练", "🎓")}
    {btn_3d(28, 304, 200, 48, 12, ACCENT_ROSE, "装扮", "👗")}
'''
    return svg_tag(content)

# ===== Screen 7: OnboardingView =====
def onboarding_view():
    content = f'''{bg_rect()}
    {glass_panel(12, 12, W-24, H-24)}
    <text x="{W/2}" y="80" font-family="Inter,Noto Sans SC,sans-serif" font-size="22" font-weight="700" fill="{TEXT_PRIMARY}" text-anchor="middle">欢迎来到 Yoho 🎉</text>
    <text x="{W/2}" y="110" font-family="Inter,Noto Sans SC,sans-serif" font-size="52" font-weight="400" fill="{TEXT_PRIMARY}" text-anchor="middle">🐱</text>
    <text x="{W/2}" y="148" font-family="Inter,Noto Sans SC,sans-serif" font-size="12" fill="{TEXT_SECONDARY}" text-anchor="middle">你的专属桌面宠物</text>
    {card(24, 170, W-48, 80)}
    <text x="40" y="194" font-family="Inter,Noto Sans SC,sans-serif" font-size="11" fill="{TEXT_SECONDARY}">🌟 陪伴工作，提升效率</text>
    <text x="40" y="216" font-family="Inter,Noto Sans SC,sans-serif" font-size="11" fill="{TEXT_SECONDARY}">🌲 种树养成，见证成长</text>
    <text x="40" y="238" font-family="Inter,Noto Sans SC,sans-serif" font-size="11" fill="{TEXT_SECONDARY}">👥 团队模式，一起努力</text>
    {btn_3d(48, 278, 160, 48, 14, ACCENT_GREEN, "开始旅程", "🚀")}
'''
    return svg_tag(content)

# ===== Screen 8: SettingsView =====
def settings_view():
    content = f'''{bg_rect()}
    {glass_panel(12, 12, W-24, H-24)}
    {title_bar("⚙️ 设置", 28, 38)}
    {card(24, 60, W-48, 44)}
    <text x="40" y="82" font-family="Inter,Noto Sans SC,sans-serif" font-size="12" fill="{TEXT_PRIMARY}">透明度</text>
    {progress_bar(40, 94, W-72, 4, 75, ACCENT_BLUE)}
    {card(24, 114, W-48, 44)}
    <text x="40" y="136" font-family="Inter,Noto Sans SC,sans-serif" font-size="12" fill="{TEXT_PRIMARY}">宠物大小</text>
    {progress_bar(40, 148, W-72, 4, 50, ACCENT_BLUE)}
    {card(24, 168, W-48, 44)}
    <text x="40" y="190" font-family="Inter,Noto Sans SC,sans-serif" font-size="12" fill="{TEXT_PRIMARY}">提醒间隔</text>
    <text x="{W-40}" y="190" font-family="Inter,Noto Sans SC,sans-serif" font-size="12" fill="{ACCENT_GREEN}" text-anchor="end">30 分钟</text>
    {card(24, 222, W-48, 44)}
    <text x="40" y="244" font-family="Inter,Noto Sans SC,sans-serif" font-size="12" fill="{TEXT_PRIMARY}">模式</text>
    <text x="{W-40}" y="244" font-family="Inter,Noto Sans SC,sans-serif" font-size="12" fill="{TEXT_SECONDARY}" text-anchor="end">老铁模式</text>
    {card(24, 276, W-48, 44)}
    <text x="40" y="298" font-family="Inter,Noto Sans SC,sans-serif" font-size="12" fill="{TEXT_PRIMARY}">通知</text>
    <text x="{W-40}" y="298" font-family="Inter,Noto Sans SC,sans-serif" font-size="12" fill="{ACCENT_GREEN}" text-anchor="end">已开启</text>
'''
    return svg_tag(content)

# ===== Screen 9: MiniGoalView =====
def mini_goal_view():
    content = f'''{bg_rect()}
    {glass_panel(12, 12, W-24, H-24)}
    {title_bar("📋 今日小目标", 28, 38)}
    {card(24, 56, W-48, 36)}
    <text x="40" y="78" font-family="Inter,Noto Sans SC,sans-serif" font-size="11" fill="{ACCENT_GREEN}">✓ 专注 25 分钟</text>
    {card(24, 100, W-48, 36)}
    <text x="40" y="122" font-family="Inter,Noto Sans SC,sans-serif" font-size="11" fill="{ACCENT_GREEN}">✓ 起身走动</text>
    {card(24, 144, W-48, 36)}
    <text x="40" y="166" font-family="Inter,Noto Sans SC,sans-serif" font-size="11" fill="{TEXT_SECONDARY}">○ 喝水 3 杯</text>
    {card(24, 188, W-48, 36)}
    <text x="40" y="210" font-family="Inter,Noto Sans SC,sans-serif" font-size="11" fill="{TEXT_SECONDARY}">○ 完成番茄钟 x4</text>
    {card(24, 232, W-48, 36)}
    <text x="40" y="254" font-family="Inter,Noto Sans SC,sans-serif" font-size="11" fill="{TEXT_SECONDARY}">○ 整理桌面</text>
    {btn_3d(48, 294, 160, 44, 12, ACCENT_GREEN, "添加新目标", "+")}
'''
    return svg_tag(content)

# ===== Screen 10: MemoryCapsuleView =====
def memory_capsule_view():
    content = f'''{bg_rect()}
    {glass_panel(12, 12, W-24, H-24)}
    {title_bar("💊 记忆胶囊", 28, 38)}
    {card(24, 60, W-48, 56)}
    <text x="40" y="82" font-family="Inter,Noto Sans SC,sans-serif" font-size="12" font-weight="600" fill="{TEXT_PRIMARY}">7 天前</text>
    <text x="40" y="100" font-family="Inter,Noto Sans SC,sans-serif" font-size="10" fill="{TEXT_SECONDARY}">小 Yo 第一次升级到 Lv.2</text>
    {card(24, 126, W-48, 56)}
    <text x="40" y="148" font-family="Inter,Noto Sans SC,sans-serif" font-size="12" font-weight="600" fill="{TEXT_PRIMARY}">14 天前</text>
    <text x="40" y="166" font-family="Inter,Noto Sans SC,sans-serif" font-size="10" fill="{TEXT_SECONDARY}">连续 7 天打卡成功 🏆</text>
    {card(24, 192, W-48, 56)}
    <text x="40" y="214" font-family="Inter,Noto Sans SC,sans-serif" font-size="12" font-weight="600" fill="{TEXT_PRIMARY}">30 天前</text>
    <text x="40" y="232" font-family="Inter,Noto Sans SC,sans-serif" font-size="10" fill="{TEXT_SECONDARY}">种下第一棵树 🌱</text>
    {btn_3d(48, 280, 160, 40, 10, ACCENT_PURPLE, "查看全部", "📖")}
'''
    return svg_tag(content)

# ===== Screen 11: TeamFlowView =====
def team_flow_view():
    content = f'''{bg_rect()}
    {glass_panel(12, 12, W-24, H-24)}
    {title_bar("👥 创建队伍", 28, 38)}
    {card(24, 60, W-48, 44)}
    <text x="40" y="82" font-family="Inter,Noto Sans SC,sans-serif" font-size="12" fill="{TEXT_PRIMARY}">队伍名称</text>
    <text x="{W-40}" y="82" font-family="Inter,Noto Sans SC,sans-serif" font-size="12" fill="{TEXT_SECONDARY}" text-anchor="end">追光小队</text>
    {card(24, 114, W-48, 44)}
    <text x="40" y="136" font-family="Inter,Noto Sans SC,sans-serif" font-size="12" fill="{TEXT_PRIMARY}">模式</text>
    <text x="{W-40}" y="136" font-family="Inter,Noto Sans SC,sans-serif" font-size="12" fill="{ACCENT_GREEN}" text-anchor="end">老铁模式</text>
    {card(24, 168, W-48, 44)}
    <text x="40" y="190" font-family="Inter,Noto Sans SC,sans-serif" font-size="12" fill="{TEXT_PRIMARY}">目标</text>
    <text x="{W-40}" y="190" font-family="Inter,Noto Sans SC,sans-serif" font-size="12" fill="{TEXT_SECONDARY}" text-anchor="end">每天专注 4h</text>
    {card(24, 222, W-48, 44)}
    <text x="40" y="244" font-family="Inter,Noto Sans SC,sans-serif" font-size="12" fill="{TEXT_PRIMARY}">成员</text>
    <text x="{W-40}" y="244" font-family="Inter,Noto Sans SC,sans-serif" font-size="12" fill="{ACCENT_BLUE}" text-anchor="end">3 人</text>
    {btn_3d(48, 300, 160, 44, 12, ACCENT_BLUE, "创建队伍", "🚀")}
'''
    return svg_tag(content)

# ===== Screen 12: ForestArchiveView =====
def forest_archive_view():
    content = f'''{bg_rect()}
    {glass_panel(12, 12, W-24, H-24)}
    {title_bar("🌲 森林档案", 28, 38)}
    {card(24, 56, W-48, 56)}
    <text x="40" y="78" font-family="Inter,Noto Sans SC,sans-serif" font-size="13" font-weight="600" fill="{TEXT_PRIMARY}">🌲 第一片森林</text>
    <text x="40" y="98" font-family="Inter,Noto Sans SC,sans-serif" font-size="9" fill="{TEXT_SECONDARY}">3 棵树 · 创建于 2024</text>
    {card(24, 122, W-48, 56)}
    <text x="40" y="144" font-family="Inter,Noto Sans SC,sans-serif" font-size="13" font-weight="600" fill="{TEXT_PRIMARY}">🏆 成就森林</text>
    <text x="40" y="164" font-family="Inter,Noto Sans SC,sans-serif" font-size="9" fill="{TEXT_SECONDARY}">5 棵树 · 全成就解锁</text>
    {card(24, 188, W-48, 56)}
    <text x="40" y="210" font-family="Inter,Noto Sans SC,sans-serif" font-size="13" font-weight="600" fill="{TEXT_PRIMARY}">💕 情侣森林</text>
    <text x="40" y="230" font-family="Inter,Noto Sans SC,sans-serif" font-size="9" fill="{TEXT_SECONDARY}">2 棵树 · 共同成长中</text>
'''
    return svg_tag(content)

# ===== Screen 13: CookieFertilizerHUD =====
def cookie_fertilizer_hud():
    content = f'''{bg_rect()}
    {glass_panel(12, 12, W-24, H-24)}
    {title_bar("🍪 饼干肥料", 28, 38)}
    <text x="{W/2}" y="100" font-family="Inter,Noto Sans SC,sans-serif" font-size="48" font-weight="400" fill="{TEXT_PRIMARY}" text-anchor="middle">🍪</text>
    {card(24, 130, W-48, 60)}
    {text_label(40, 152, "当前库存", 11, TEXT_SECONDARY)}
    <text x="40" y="176" font-family="Inter,Noto Sans SC,sans-serif" font-size="20" font-weight="700" fill="{ACCENT_GREEN}">24 个</text>
    {card(24, 204, W-48, 60)}
    {text_label(40, 226, "效果", 11, TEXT_SECONDARY)}
    <text x="40" y="250" font-family="Inter,Noto Sans SC,sans-serif" font-size="12" fill="{TEXT_PRIMARY}">🌱 树木成长 +25% 持续 30min</text>
    {btn_3d(48, 290, 160, 48, 12, ACCENT_GREEN, "使用肥料", "✨")}
'''
    return svg_tag(content)

# ===== Screen 14: PosterView =====
def poster_view():
    content = f'''{bg_rect()}
    {glass_panel(12, 12, W-24, H-24)}
    <text x="{W/2}" y="60" font-family="Inter,Noto Sans SC,sans-serif" font-size="20" font-weight="700" fill="{ACCENT_GREEN}" text-anchor="middle">🎉 目标达成！</text>
    <text x="{W/2}" y="120" font-family="Inter,Noto Sans SC,sans-serif" font-size="52" font-weight="400" fill="{TEXT_PRIMARY}" text-anchor="middle">🏆</text>
    <text x="{W/2}" y="158" font-family="Inter,Noto Sans SC,sans-serif" font-size="14" font-weight="600" fill="{TEXT_PRIMARY}" text-anchor="middle">连续专注 7 天</text>
    {card(24, 180, W-48, 80)}
    <text x="40" y="204" font-family="Inter,Noto Sans SC,sans-serif" font-size="11" fill="{TEXT_SECONDARY}">总专注时长</text>
    <text x="40" y="226" font-family="Inter,Noto Sans SC,sans-serif" font-size="24" font-weight="800" fill="{ACCENT_GREEN}">28h</text>
    <text x="40" y="246" font-family="Inter,Noto Sans SC,sans-serif" font-size="10" fill="{TEXT_SECONDARY}">🏅 新成就解锁：专注大师</text>
    {btn_3d(48, 280, 160, 44, 12, ACCENT_GREEN, "分享海报", "📤")}
'''
    return svg_tag(content)

# ===== Screen 15: TransitionFlowView =====
def transition_flow_view():
    content = f'''{bg_rect()}
    {glass_panel(12, 12, W-24, H-24)}
    {title_bar("💕 建立情侣关系", 28, 38)}
    <text x="{W/2}" y="100" font-family="Inter,Noto Sans SC,sans-serif" font-size="40" font-weight="400" fill="{TEXT_PRIMARY}" text-anchor="middle">💕</text>
    <text x="{W/2}" y="136" font-family="Inter,Noto Sans SC,sans-serif" font-size="12" fill="{TEXT_SECONDARY}" text-anchor="middle">与你的伴侣一起养成宠物</text>
    {card(24, 160, W-48, 44)}
    <text x="40" y="182" font-family="Inter,Noto Sans SC,sans-serif" font-size="12" fill="{TEXT_PRIMARY}">伴侣 ID</text>
    <text x="{W-40}" y="182" font-family="Inter,Noto Sans SC,sans-serif" font-size="12" fill="{TEXT_MUTED}" text-anchor="end">输入 ID...</text>
    {card(24, 214, W-48, 44)}
    <text x="40" y="236" font-family="Inter,Noto Sans SC,sans-serif" font-size="12" fill="{TEXT_PRIMARY}">共享树木</text>
    <text x="{W-40}" y="236" font-family="Inter,Noto Sans SC,sans-serif" font-size="12" fill="{ACCENT_GREEN}" text-anchor="end">是</text>
    {btn_3d(48, 290, 160, 44, 12, ACCENT_ROSE, "建立关系", "💕")}
'''
    return svg_tag(content)


# ===== Generate All =====
screens = {
    "01_MainWindow": main_window,
    "02_PetView": pet_view,
    "03_PetAnimationView": pet_animation_view,
    "04_TreeView": tree_view,
    "05_TreeSwitcherView": tree_switcher_view,
    "06_InteractionMenu": interaction_menu,
    "07_OnboardingView": onboarding_view,
    "08_SettingsView": settings_view,
    "09_MiniGoalView": mini_goal_view,
    "10_MemoryCapsuleView": memory_capsule_view,
    "11_TeamFlowView": team_flow_view,
    "12_ForestArchiveView": forest_archive_view,
    "13_CookieFertilizerHUD": cookie_fertilizer_hud,
    "14_PosterView": poster_view,
    "15_TransitionFlowView": transition_flow_view,
}

for name, gen_func in screens.items():
    svg = gen_func()
    path = os.path.join(OUT, f"{name}.svg")
    with open(path, "w", encoding="utf-8") as f:
        f.write(svg)
    print(f"✓ {name}.svg")

print(f"\nAll 15 screens generated in {OUT}")
