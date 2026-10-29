#!/usr/bin/env python3
"""Skillwright (working title) mocks, v0.2: monochrome minimal. Japanese + English.
All names/content fictional (やまぶき工房 / Teapot Labs, tea-timer-skill).
Run: python3 design/build2.py && python3 <SKILL>/scripts/export_png.py design/mocks2"""
import math
from pathlib import Path
from xml.sax.saxutils import escape

OUT = Path(__file__).resolve().parent / "mocks"
OUT.mkdir(exist_ok=True)
for f in OUT.glob("*"):
    f.unlink()
SANS = "-apple-system, 'SF Pro Text', 'Hiragino Sans', 'Noto Sans JP', 'Noto Sans CJK JP', sans-serif"
DISP = "-apple-system, 'SF Pro Display', 'Hiragino Sans', 'Noto Sans JP', 'Noto Sans CJK JP', sans-serif"
MONO = "'SF Mono', Menlo, 'Noto Sans Mono CJK JP', 'Noto Sans CJK JP', monospace"

LIGHT = dict(mode="light", bg="#F3F3F3", card="#FFFFFF", text="#0A0A0A", sec="#6B6B6B", hair="#ECECEC",
             pill="#0A0A0A", pill_ink="#FFFFFF", btn="#FFFFFF", btn_line="#E6E6E6", warn="#B45309", err="#C2001F",
             okc="#0A0A0A", kb="#D1D3D9", key="#FFFFFF", sheet="#FFFFFF", fill="#F3F3F3", tint="#F6F6F6",
             add="#EDEDED", dele="#F6F6F6", skel="#ECECEC", desk="#E9E9E9")
DARK = dict(mode="dark", bg="#000000", card="#141414", text="#F5F5F5", sec="#9A9A9A", hair="#262626",
            pill="#F5F5F5", pill_ink="#0A0A0A", btn="#1C1C1C", btn_line="#2C2C2C", warn="#FFB224", err="#FF4245",
            okc="#9A9A9A", kb="#1A1A1A", key="#3A3A3A", sheet="#161616", fill="#232323", tint="#1B1B1B",
            add="#262626", dele="#1C1C1C", skel="#262626", desk="#0E0E0E")


# ------------------------------------------------------------------ primitives
def T(x, y, s, size, fill, weight=400, anchor="start", bg=None, font=SANS, ls=None):
    b = f' data-bg="{bg}"' if bg else ""
    l = f' letter-spacing="{ls}"' if ls is not None else ""
    return (f'<text x="{x:.1f}" y="{y:.1f}" font-family="{font}" font-size="{size}" font-weight="{weight}" '
            f'fill="{fill}" text-anchor="{anchor}"{b}{l}>{escape(s)}</text>')


def mix(fg, bg, a):
    f = [int(fg[i:i + 2], 16) for i in (1, 3, 5)]
    g = [int(bg[i:i + 2], 16) for i in (1, 3, 5)]
    return "#" + "".join(f"{round(x * a + y * (1 - a)):02X}" for x, y in zip(f, g))


def tw(s, size, mono=False):
    w = 0
    for ch in s:
        if ord(ch) > 0x2E80:
            w += size
        elif mono:
            w += size * 0.5
        elif ch in "il.,:;'| ":
            w += size * 0.3
        elif ch.isupper() or ch in "mwMW":
            w += size * 0.68
        else:
            w += size * 0.54
    return w


def ico(kind, cx, cy, c, sw=1.7, s=1.0):
    g = (f'<g transform="translate({cx:.1f},{cy:.1f}) scale({s})" fill="none" stroke="{c}" stroke-width="{sw}" '
         f'stroke-linecap="round" stroke-linejoin="round">')
    d = {"back": '<path d="M4 -8l-8 8 8 8"/>', "plus": '<path d="M0 -8v16M-8 0h16"/>',
         "eye": '<path d="M-10 0c4-6 16-6 20 0c-4 6-16 6-20 0z"/><circle r="2.8"/>',
         "pencil": '<path d="M-7 7l2-6 9-9 4 4-9 9z"/><path d="M2 -6l4 4"/>',
         "folder": '<path d="M-9 -6.5h6l2 2.5h10v10.5h-18z"/>',
         "doc": '<path d="M-6.5 -9h8l5 5v13h-13z"/><path d="M1.5 -9v5h5"/>',
         "box": '<path d="M-9 -4l9-5 9 5v10l-9 5-9-5z"/><path d="M-9 -4l9 5 9-5M0 1v10"/>',
         "phone": '<rect x="-6" y="-10" width="12" height="20" rx="3"/>',
         "tablet": '<rect x="-9" y="-11" width="18" height="22" rx="3"/>',
         "cloud": '<path d="M-8 6h15a5 5 0 0 0 0-10a7 7 0 0 0-13-1a5 5 0 0 0-2 11z"/>',
         "trash": '<path d="M-8 -6h16M-3 -6v-3h6v3M-6 -6l1 15h10l1-15"/>',
         "link": '<path d="M-2 4l-3 3a4 4 0 0 1-6-6l3-3M2 -4l3-3a4 4 0 0 1 6 6l-3 3M-3 3l6-6"/>',
         "search": '<circle cx="-2" cy="-2" r="6.5"/><path d="M3 3l5 5"/>', "up": '<path d="M0 6v-12M-5 -1l5-5 5 5"/>',
         "chev": '<path d="M-3 -6l6 6-6 6"/>', "undo": '<path d="M-7 -2h9a5 5 0 0 1 0 10h-4M-3 -6l-4 4 4 4"/>',
         "x": '<path d="M-6 -6l12 12M6 -6l-12 12"/>', "check": '<path d="M-7 1l5 5 10-11"/>',
         "sidebar": '<rect x="-11" y="-9" width="22" height="18" rx="3"/><path d="M-4 -9v18"/>',
         "layers": '<path d="M0 -9l10 5-10 5-10-5z"/><path d="M-10 1l10 5 10-5M-10 6l10 5 10-5"/>',
         "spark": '<path d="M0 -9c1 5 4 8 9 9c-5 1-8 4-9 9c-1-5-4-8-9-9c5-1 8-4 9-9z"/>',
         "share": '<path d="M0 -10v13M-5 -5l5-5 5 5M-8 -1v10h16v-10"/>',
         "scissors": '<circle cx="-5" cy="6" r="3"/><circle cx="5" cy="6" r="3"/><path d="M-3 4l9-13M3 4l-9-13"/>'}
    if kind == "dots":
        return "".join(f'<circle cx="{cx+dx:.1f}" cy="{cy:.1f}" r="2" fill="{c}"/>' for dx in (-6, 0, 6))
    return g + d[kind] + "</g>"


def warn_tri(cx, cy, c, ink, r=6.5):
    return (f'<path d="M{cx:.1f} {cy-r:.1f}l{r} {r*1.75:.1f}h-{2*r}z" fill="{c}" stroke="{c}" stroke-width="2" stroke-linejoin="round"/>'
            f'<path d="M{cx:.1f} {cy-2.5:.1f}v3.2" stroke="{ink}" stroke-width="1.7" stroke-linecap="round"/>'
            f'<circle cx="{cx:.1f}" cy="{cy+4:.1f}" r="1" fill="{ink}"/>')


def ok_dot(cx, cy, c, ink, r=6.5):
    return (f'<circle cx="{cx:.1f}" cy="{cy:.1f}" r="{r}" fill="{c}"/><path d="M{cx-2.8:.1f} {cy:.1f}l2 2 3.8-4.2" '
            f'fill="none" stroke="{ink}" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"/>')


class Screen:
    def __init__(self, c, w=402, h=874, bg=None):
        self.c, self.w, self.h = c, w, h
        self.bg = bg or c["bg"]
        self.b = []

    def add(self, *parts):
        self.b.extend(parts)

    def svg(self):
        return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{self.w}" height="{self.h}" viewBox="0 0 {self.w} {self.h}" '
                f'data-bg="{self.bg}"><rect width="100%" height="100%" fill="{self.bg}"/>{"".join(self.b)}</svg>\n')


def status(c, w):
    return (T(54, 37, "9:41", 17, c["text"], 600, "middle") +
            f'<rect x="{w-62}" y="25" width="26" height="13" rx="4" fill="none" stroke="{c["text"]}" stroke-opacity="0.4"/>'
            f'<rect x="{w-60}" y="27" width="20" height="9" rx="2" fill="{c["text"]}"/>')


def home(c, w, h):
    return f'<rect x="{w/2-70}" y="{h-13}" width="140" height="5" rx="2.5" fill="{c["text"]}"/>'


def cbtn(c, cx, cy, inner, r=20):
    return f'<circle cx="{cx:.1f}" cy="{cy:.1f}" r="{r}" fill="{c["btn"]}" stroke="{c["btn_line"]}"/>' + inner


def btn_icon(c, cx, cy, kind):
    if kind == "dots":
        return cbtn(c, cx, cy, ico("dots", cx, cy, c["text"]))
    return cbtn(c, cx, cy, ico(kind, cx, cy, c["text"], 1.8, 0.9))


def nav(c, w, title, sub=None, left="back", right=None, x0=0):
    p = []
    mid = x0 + w / 2
    if sub:
        p.append(T(mid, 80, title, 16, c["text"], 600, "middle", font=MONO if "." in title else SANS))
        p.append(T(mid, 99, sub, 12, c["sec"], 400, "middle"))
    else:
        p.append(T(mid, 89, title, 16, c["text"], 600, "middle", font=MONO if "." in title else SANS))
    if left:
        p.append(btn_icon(c, x0 + 36, 84, left))
    if right:
        p.append(btn_icon(c, x0 + w - 36, 84, right))
    return "".join(p)


def card(c, x, y, w, h, fill=None, r=30):
    return f'<rect x="{x:.1f}" y="{y:.1f}" width="{w:.1f}" height="{h:.1f}" rx="{r}" fill="{fill or c["card"]}"/>'


def pill(c, x, y, w, label, h=52, inverse=False):
    if inverse:
        return (f'<rect x="{x:.1f}" y="{y:.1f}" width="{w:.1f}" height="{h}" rx="{h/2}" fill="none" stroke="{c["text"]}" stroke-width="1.5"/>'
                + T(x + w / 2, y + h / 2 + 6, label, 16, c["text"], 600, "middle"))
    return (f'<rect x="{x:.1f}" y="{y:.1f}" width="{w:.1f}" height="{h}" rx="{h/2}" fill="{c["pill"]}"/>'
            + T(x + w / 2, y + h / 2 + 6, label, 16, c["pill_ink"], 600, "middle", bg=c["pill"]))


def caption(c, x, y, s, bg=None):
    if any(ord(ch) > 0x2E80 for ch in s) or not s.isupper():
        return T(x, y, s, 13, c["sec"], 600, bg=bg)
    return T(x, y, s, 11, c["sec"], 600, bg=bg, font=MONO, ls=1.4)


def hair(c, x, y, w):
    return f'<rect x="{x:.1f}" y="{y:.1f}" width="{w:.1f}" height="1" fill="{c["hair"]}"/>'


def chev(c, x, y):
    return ico("chev", x, y, c["sec"], 1.6, 0.8)


def toggle(c, x, y, on=True):
    if on:
        return (f'<rect x="{x}" y="{y}" width="51" height="31" rx="15.5" fill="{c["text"]}"/>'
                f'<circle cx="{x+35.5}" cy="{y+15.5}" r="13.5" fill="{c["card"]}"/>')
    return (f'<rect x="{x}" y="{y}" width="51" height="31" rx="15.5" fill="{'#DCDCDC' if c['mode'] == 'light' else '#3A3A3A'}"/>'
            f'<circle cx="{x+15.5}" cy="{y+15.5}" r="13.5" fill="#FFFFFF"/>')


TABS = {"ja": ["ファイル", "最近", "設定"], "en": ["Files", "Recents", "Settings"]}


def tab_bar(c, w, h, lang="ja", active=0):
    ty, bw = h - 92, w - 40 - 68
    p = [f'<rect x="20" y="{ty}" width="{bw}" height="58" rx="29" fill="{c["btn"]}" stroke="{c["btn_line"]}"/>']
    for i, lab in enumerate(TABS[lang]):
        cx = 20 + bw * (i + 0.5) / 3
        col = c["text"] if i == active else c["sec"]
        if i == 0:
            p.append(f'<path d="M{cx-10:.1f} {ty+13}h7l2 3h11v11h-20z" fill="{col}"/>')
        elif i == 1:
            p.append(f'<circle cx="{cx:.1f}" cy="{ty+20}" r="9" fill="{col}"/><path d="M{cx:.1f} {ty+15}v5l4 3" stroke="{c["btn"]}" stroke-width="2" fill="none" stroke-linecap="round"/>')
        else:
            p.append("".join(f'<rect x="{cx-2.3:.1f}" y="{ty+9}" width="4.6" height="5.5" rx="1" fill="{col}" transform="rotate({a} {cx:.1f} {ty+20})"/>' for a in range(0, 360, 45))
                     + f'<circle cx="{cx:.1f}" cy="{ty+20}" r="7.8" fill="{col}"/><circle cx="{cx:.1f}" cy="{ty+20}" r="3.2" fill="{c["btn"]}"/>')
        p.append(T(cx, ty + 46, lab, 11, col, 600, "middle", bg=c["btn"]))
    p.append(f'<circle cx="{w-49}" cy="{ty+29}" r="29" fill="{c["btn"]}" stroke="{c["btn_line"]}"/>' + ico("search", w - 49, ty + 29, c["text"]))
    return "".join(p)


def keyboard(c, w, h, y0):
    p = [f'<rect x="0" y="{y0}" width="{w}" height="{h-y0}" fill="{c["kb"]}"/>']
    keys = ["#", "**", "-", "[ ]", "`", "→", "U"]
    for i, k in enumerate(keys):
        cx = w * (i + 0.5) / len(keys)
        if k == "U":
            p.append(ico("undo", cx, y0 + 22, c["text"]))
        else:
            p.append(T(cx, y0 + 28, k, 15, c["text"], 500, "middle", bg=c["kb"], font=MONO))
        if i:
            p.append(f'<rect x="{w*i/len(keys):.1f}" y="{y0+12}" width="1" height="20" fill="{c["sec"]}" fill-opacity="0.35"/>')
    y0 += 44
    for r, row in enumerate(["qwertyuiop", "asdfghjkl", "zxcvbnm"]):
        n, kw = len(row), 34
        gap = (w - 10 * kw) / 11
        sx = (w - n * kw - (n - 1) * gap) / 2
        for i, ch in enumerate(row):
            kx = sx + i * (kw + gap)
            ky = y0 + 6 + r * 54
            p.append(f'<rect x="{kx:.1f}" y="{ky}" width="{kw}" height="42" rx="8" fill="{c["key"]}"/>')
            p.append(T(kx + kw / 2, ky + 28, ch, 19, c["text"], 400, "middle", bg=c["key"]))
    p.append(f'<rect x="{w/2-100}" y="{y0+168}" width="200" height="42" rx="8" fill="{c["key"]}"/>')
    p.append(T(w / 2, y0 + 195, "空白" if True else "space", 15, c["text"], 400, "middle", bg=c["key"]))
    return "".join(p)


def dimmer(c, w, h):
    return f'<rect width="{w}" height="{h}" fill="#000000" fill-opacity="{0.18 if c["mode"]=="light" else 0.5}"/>'


def sheet_full(c, w, h, title, left="x", right="check", right_on=True, sy=56):
    p = [dimmer(c, w, h), f'<path d="M0 {sy+38}a38 38 0 0 1 38 -38h{w-76}a38 38 0 0 1 38 38v{h-sy-38}h-{w}z" fill="{c["sheet"]}"/>']
    cy = sy + 46
    p.append(f'<circle cx="44" cy="{cy}" r="20" fill="{c["fill"]}"/>' + ico(left, 44, cy, c["text"], 1.8, 0.85))
    p.append(T(w / 2, cy + 6, title, 16, c["text"], 600, "middle", bg=c["sheet"]))
    if right:
        f = c["pill"] if right_on else c["fill"]
        ink = c["pill_ink"] if right_on else c["sec"]
        p.append(f'<circle cx="{w-44}" cy="{cy}" r="20" fill="{f}"/>' + ico(right, w - 44, cy, ink, 2, 0.8))
    return "".join(p)


# ------------------------------------------------------------------ data
L = {
    "ja": dict(owner="やまぶき工房", files_cap="FILES", pass_word="決まりに合格", warn1="注意 1", pending2="未反映 2",
               changed="変更", publish2="2件の変更を反映", done="完了", unpublished="未反映",
               lint_line="12行目：リンク先がありません", lint_title="検査結果", spec_line="Agent Skills 仕様＋Claude Code",
               broken="リンク先がありません", broken_sub="references/brewing.md・12行目", make_file="ファイルを作る",
               evidence="根拠を見る", r1="name の形式", r1v="9文字", r2="name とフォルダ名", r2v="一致",
               r3="description の長さ", r4="本文の行数",
               trig_title="呼ばれ方テスト", trig_cap="依頼文", trig_q="緑茶をおいしく淹れるには？",
               trig_res="呼ばれそう", trig_sub="description のこの語が効いています", trig_words=["お茶", "種類ごと", "抽出時間"],
               trig_hist="試した依頼", hist=[("ほうじ茶は何度で淹れる？", True), ("コーヒー豆の挽き方", False), ("紅茶の蒸らし時間", True)],
               trig_note="iPhone 内蔵の AI による目安です。実際の動きとは違うことがあります。", trig_claude="Claude で確かめる（自分の鍵）",
               trig_btn="試す", maybe="呼ばれそう", nope="呼ばれない", excluded="除外中 1件（WR-01）", rulever="ルール 2026.10.30",
               view_title="AI からの見え方", v1="いつも読まれる", v1s="name と description", v2="呼ばれたら読む", v2s="SKILL.md の本文・13行",
               v3="必要なときだけ", v3s="references/ と scripts/", missing="見つかりません", total="合計", tokens="トークン（目安）"),
    "en": dict(owner="Teapot Labs", files_cap="FILES", pass_word="rules passed", warn1="1 warning", pending2="2 unpublished",
               changed="Edited", publish2="Publish 2 changes", done="Done", unpublished="Unpublished",
               lint_line="Line 12: link target not found", lint_title="Check results", spec_line="Agent Skills spec + Claude Code",
               broken="Link target not found", broken_sub="references/brewing.md · line 12", make_file="Create file",
               evidence="See source", r1="name format", r1v="9 chars", r2="name matches folder", r2v="Yes",
               r3="description length", r4="Body length",
               trig_title="Trigger Test", trig_cap="REQUEST", trig_q="How do I brew green tea well?",
               trig_res="Likely", trig_sub="These words in the description matched", trig_words=["tea", "brewing time", "each type"],
               trig_hist="TRIED", hist=[("What temperature for hojicha?", True), ("How to grind coffee beans", False), ("Steeping time for black tea", True)],
               trig_note="An estimate by the on-device model. Real agents may differ.", trig_claude="Check with Claude (your key)",
               trig_btn="Test", maybe="Likely", nope="Unlikely", excluded="1 rule skipped (WR-01)", rulever="Rules 2026.10.30",
               view_title="What the AI Sees", v1="Always loaded", v1s="name and description", v2="Loaded when triggered", v2s="SKILL.md body · 13 lines",
               v3="Only when needed", v3s="references/ and scripts/", missing="not found", total="Total", tokens="tokens (est.)"),
}
FILES = [("folder", "references", "1", None, None), ("folder", "scripts", "2", None, None),
         ("doc", "SKILL.md", None, True, "warn"), ("doc", "AGENTS.md", None, False, "ok"),
         ("doc", "README.md", None, True, "ok")]
LINES = {"ja": [("---", "mk"), ("name: tea-timer", "kv"), ("description: お茶の種類", "kv"), ("  ごとに抽出時間を案内", "v"),
                ("---", "mk"), ("", ""), ("# お茶タイマー", "h"), ("", ""), ("## 使い方", "h"), ("1. 茶葉の種類を聞く", "t"),
                ("2. 下の表で時間を決める", "cur"), ("詳しくは[抽出の表](refe", "bad")],
         "en": [("---", "mk"), ("name: tea-timer", "kv"), ("description: Guides", "kv"), ("  brewing time for each tea", "v"),
                ("---", "mk"), ("", ""), ("# Tea Timer", "h"), ("", ""), ("## Steps", "h"), ("1. Ask which tea", "t"),
                ("2. Pick a time from the table", "cur"), ("See [the table](refer", "bad")]}


def file_list(c, x, y, w, lang, rh=62, sel=None, chevs=True):
    p = [card(c, x, y, w, rh * len(FILES) + 16)]
    for i, (k, n, cnt, edited, lint) in enumerate(FILES):
        ry = y + 8 + i * rh
        rb = c["card"]
        if sel and n == sel:
            rb = c["tint"]
            p.append(f'<rect x="{x+8}" y="{ry+4}" width="{w-16}" height="{rh-8}" rx="18" fill="{rb}"/>')
        p.append(ico(k, x + 30, ry + rh / 2, c["text"], 1.6))
        p.append(T(x + 54, ry + rh / 2 + 6, n + ("/" if k == "folder" else ""), 16, c["text"], 500, bg=rb, font=MONO))
        if k == "folder":
            p.append(T(x + w - 34, ry + rh / 2 + 5, cnt, 14, c["sec"], 400, "end", bg=rb, font=MONO))
            if chevs:
                p.append(chev(c, x + w - 22, ry + rh / 2))
        else:
            ix = x + w - 24
            if lint == "warn":
                p.append(warn_tri(ix, ry + rh / 2, c["warn"], rb, 6))
            else:
                p.append(ok_dot(ix, ry + rh / 2, c["okc"], rb, 6))
            if edited:
                p.append(T(ix - 16, ry + rh / 2 + 5, L[lang]["changed"], 13, c["sec"], 400, "end", bg=rb))
        if i < len(FILES) - 1:
            p.append(hair(c, x + 54, ry + rh - 0.5, w - 70))
    return "".join(p)


def hero(c, x, y, lang, bg):
    t = L[lang]
    p = [T(x, y, "6/7", 72, c["text"], 500, font=DISP, ls=-3)]
    p.append(T(x + 2, y + 32, t["pass_word"], 15, c["sec"], 400, bg=bg))
    rx = x + 250
    p.append(warn_tri(rx, y - 10, c["warn"], bg, 6))
    p.append(T(rx + 12, y - 5, t["warn1"], 15, c["text"], 600, bg=bg))
    p.append(T(rx - 6, y + 17, t["pending2"], 15, c["sec"], 400, bg=bg))
    return "".join(p)


def editor_card(c, x, y, w, h, lang, show=12, status_line=True, lines=None):
    t = L[lang]
    p = [card(c, x, y, w, h)]
    ly = y + 38
    lx = x + 46
    for i, (s, role) in enumerate((lines or LINES[lang])[:show]):
        p.append(T(x + 36, ly, str(i + 1), 11, c["sec"], 400, "end", bg=c["card"], font=MONO))
        if role == "kv":
            k, v = s.split(": ", 1)
            p.append(T(lx, ly, k + ":", 15, c["sec"], 400, bg=c["card"], font=MONO))
            p.append(T(lx + (len(k) + 2) * 7.6, ly, v, 15, c["text"], 400, bg=c["card"]))
        elif role == "v":
            p.append(T(lx + 16, ly, s.strip(), 15, c["text"], 400, bg=c["card"]))
        elif role == "mk":
            p.append(T(lx, ly, s, 15, c["sec"], 400, bg=c["card"], font=MONO))
        elif role == "h":
            mk, tt = s.split(" ", 1)
            p.append(T(lx, ly, mk, 15, c["sec"], 400, bg=c["card"], font=MONO))
            p.append(T(lx + len(mk) * 7.6 + 8, ly, tt, 15, c["text"], 700, bg=c["card"]))
        elif role in ("t", "cur"):
            n, tt = s.split(" ", 1)
            p.append(T(lx, ly, n, 15, c["sec"], 400, bg=c["card"], font=MONO))
            p.append(T(lx + 22, ly, tt, 15, c["text"], 400, bg=c["card"]))
            if role == "cur":
                p.append(f'<rect x="{lx+22+tw(tt,15)+3:.1f}" y="{ly-14}" width="2" height="18" fill="{c["text"]}"/>')
        elif role == "bad":
            pre, rest = s.split("[", 1)
            p.append(f'<circle cx="{x+12}" cy="{ly-5}" r="3" fill="{c["warn"]}"/>')
            p.append(T(lx, ly, pre, 15, c["text"], 400, bg=c["card"]))
            bx = lx + tw(pre, 15) + 2
            p.append(T(bx, ly, "[" + rest, 15, c["text"], 400, bg=c["card"]))
            wv = min(tw("[" + rest, 15), x + w - bx - 16)
            p.append(f'<path d="M{bx:.1f} {ly+5}' + "".join("q1.6 2.4 3.2 0t3.2 0" for _ in range(int(wv / 6.4))) +
                     f'" fill="none" stroke="{c["warn"]}" stroke-width="1.3"/>')
        ly += 24
    if status_line:
        sy = y + h - 26
        p.append(warn_tri(x + 24, sy - 4, c["warn"], c["card"], 5.5))
        p.append(T(x + 36, sy + 1, t["lint_line"], 12, c["sec"], 400, bg=c["card"]))
    return "".join(p)


# ------------------------------------------------------------------ iPhone screens
W, H = 402, 874


def s01(c, empty=False):
    s = Screen(c)
    s.add(status(c, W), nav(c, W, "ファイル", left=None, right="plus"))
    if empty:
        s.add(ico("doc", W / 2, 320, c["text"], 1.4, 2.6))
        s.add(T(W / 2, 400, "まだファイルがありません", 22, c["text"], 700, "middle"))
        s.add(T(W / 2, 430, "ひな形から作るか、GitHub のリポを開きます。", 15, c["sec"], 400, "middle"))
        s.add(pill(c, 40, 470, W - 80, "新規作成"), pill(c, 40, 534, W - 80, "GitHub と連携", inverse=True))
    else:
        y = 140
        s.add(caption(c, 24, y, "GitHub"))
        y += 12
        rows = [("tea-timer-skill", "main・未反映 2"), ("kettle-notes", "main・最新")]
        s.add(card(c, 16, y, W - 32, 3 * 62 + 16))
        for i, (n, sub) in enumerate(rows):
            ry = y + 8 + i * 62
            s.add(ico("box", 46, ry + 31, c["text"], 1.6), T(70, ry + 27, n, 16, c["text"], 500, bg=c["card"], font=MONO),
                  T(70, ry + 47, sub, 13, c["sec"], 400, bg=c["card"]), chev(c, W - 38, ry + 31), hair(c, 70, ry + 61.5, W - 102))
        ry = y + 8 + 2 * 62
        s.add(ico("plus", 46, ry + 31, c["text"], 1.6, 0.9), T(70, ry + 37, "GitHub のリポを追加", 16, c["text"], 500, bg=c["card"]))
        y += 3 * 62 + 16 + 34
        s.add(caption(c, 24, y, "この iPhone"))
        y += 12
        rows2 = [("phone", "このiPhone", "メモ・3件"), ("cloud", "iCloud Drive", "Skillwright・12件"), ("folder", "ほかの場所を開く…", None)]
        s.add(card(c, 16, y, W - 32, 3 * 62 + 16))
        for i, (k, n, sub) in enumerate(rows2):
            ry = y + 8 + i * 62
            s.add(ico(k, 46, ry + 31, c["text"], 1.6))
            if sub:
                s.add(T(70, ry + 27, n, 16, c["text"], 500, bg=c["card"]), T(70, ry + 47, sub, 13, c["sec"], 400, bg=c["card"]))
            else:
                s.add(T(70, ry + 37, n, 16, c["text"], 500, bg=c["card"]))
            s.add(chev(c, W - 38, ry + 31))
            if i < 2:
                s.add(hair(c, 70, ry + 61.5, W - 102))
        y += 3 * 62 + 16 + 16
        s.add(card(c, 16, y, W - 32, 56), ico("trash", 46, y + 28, c["text"], 1.6), T(70, y + 34, "ゴミ箱", 16, c["text"], 500, bg=c["card"]), chev(c, W - 38, y + 28))
    s.add(tab_bar(c, W, H), home(c, W, H))
    return s.svg()


def s02(c, lang="ja", mode=None):
    if mode == "free":
        base = s02(c, lang)
        bx, by = W / 2 + tw(L[lang]["publish2"], 16) / 2 + 10, 252 + 62 * 5 + 32 + 15
        badge = (f'<rect x="{bx:.1f}" y="{by}" width="34" height="22" rx="11" fill="none" stroke="{c["pill_ink"]}" stroke-width="1.2"/>'
                 + T(bx + 17, by + 15.5, "Pro", 11, c["pill_ink"], 700, "middle", bg=c["pill"]))
        return base.replace("</svg>", badge + "</svg>")
    t = L[lang]
    s = Screen(c)
    s.add(status(c, W), nav(c, W, "tea-timer-skill", "main", "back", "plus"))
    if mode == "loading":
        s.add(T(24, 150, "GitHub から読み込み中（3/8 件）", 15, c["text"], 500))
        s.add(f'<rect x="24" y="164" width="{W-150}" height="4" rx="2" fill="{c["skel"]}"/><rect x="24" y="164" width="{(W-150)*3/8:.1f}" height="4" rx="2" fill="{c["text"]}"/>')
        s.add(T(W - 24, 170, "キャンセル", 15, c["text"], 600, "end"))
        s.add(card(c, 16, 196, W - 32, 5 * 62 + 16))
        for i in range(5):
            ry = 204 + i * 62
            s.add(f'<rect x="34" y="{ry+21}" width="22" height="22" rx="6" fill="{c["skel"]}"/><rect x="70" y="{ry+24}" width="{160-i*14}" height="14" rx="7" fill="{c["skel"]}"/>')
        s.add(tab_bar(c, W, H, lang), home(c, W, H))
        return s.svg()
    if mode == "ax5":
        s.add(T(24, 196, "6/7", 96, c["text"], 500, font=DISP, ls=-3))
        s.add(T(24, 268, "合格", 49, c["sec"], 400))
        s.add(warn_tri(40, 316, c["warn"], c["bg"], 14), T(64, 334, "注意 1", 49, c["text"], 600))
        s.add(T(24, 394, "未反映 2", 49, c["sec"], 400))
        s.add(card(c, 16, 416, W - 32, 168))
        s.add(T(36, 478, "SKILL.md", 49, c["text"], 500, bg=c["card"], font=MONO))
        s.add(warn_tri(52, 538, c["warn"], c["card"], 14), T(76, 556, "変更", 49, c["sec"], 400, bg=c["card"]))
        s.add(f'<rect x="16" y="600" width="{W-32}" height="96" rx="48" fill="{c["pill"]}"/>',
              T(W / 2, 640, "2件の変更を", 28, c["pill_ink"], 600, "middle", bg=c["pill"]),
              T(W / 2, 676, "反映", 28, c["pill_ink"], 600, "middle", bg=c["pill"]))
        s.add(tab_bar(c, W, H, lang), home(c, W, H))
        return s.svg()
    s.add(hero(c, 24, 196, lang, c["bg"]))
    s.add(file_list(c, 16, 252, W - 32, lang))
    s.add(pill(c, 16, 252 + 62 * 5 + 32, W - 32, t["publish2"]))
    s.add(tab_bar(c, W, H, lang), home(c, W, H))
    return s.svg()


def s03(c, lang="ja"):
    t = L[lang]
    s = Screen(c)
    s.add(status(c, W), nav(c, W, "SKILL.md", t["unpublished"], "back", "dots"))
    s.add(editor_card(c, 16, 120, W - 32, 372, lang))
    s.add(pill(c, 16, 506, W - 32, t["done"], 48))
    s.add(keyboard(c, W, H, H - 290).replace("空白", "空白" if lang == "ja" else "space"))
    s.add(home(c, W, H))
    return s.svg()


def s04(c):
    s = Screen(c)
    s.add(status(c, W), nav(c, W, "SKILL.md", "プレビュー", "back", "pencil"))
    s.add(card(c, 16, 120, W - 32, 640))
    y = 150
    s.add(f'<rect x="32" y="{y}" width="{W-64}" height="80" rx="16" fill="{c["tint"]}"/>')
    s.add(T(48, y + 32, "name", 13, c["sec"], 400, bg=c["tint"], font=MONO), T(150, y + 32, "tea-timer", 15, c["text"], 500, bg=c["tint"], font=MONO))
    s.add(T(48, y + 60, "description", 13, c["sec"], 400, bg=c["tint"], font=MONO), T(150, y + 60, "お茶の種類ごとに抽出時間…", 15, c["text"], 400, bg=c["tint"]))
    y = 280
    s.add(T(36, y, "お茶タイマー", 26, c["text"], 700, bg=c["card"]))
    s.add(T(36, y + 44, "使い方", 20, c["text"], 700, bg=c["card"]))
    s.add(T(36, y + 80, "1.  茶葉の種類を聞く", 16, c["text"], 400, bg=c["card"]), T(36, y + 108, "2.  下の表で時間を決める", 16, c["text"], 400, bg=c["card"]))
    ty = y + 132
    s.add(f'<rect x="36" y="{ty}" width="{W-72}" height="150" rx="12" fill="none" stroke="{c["hair"]}" stroke-width="1.5"/>')
    cols = [52, 170, 260]
    for cx, hd in zip(cols, ["種類", "温度", "時間"]):
        s.add(T(cx, ty + 26, hd, 13, c["sec"], 600, bg=c["card"]))
    for r, row in enumerate([("紅茶", "95℃", "3分"), ("緑茶", "70℃", "1分"), ("ほうじ茶", "90℃", "30秒")]):
        ry = ty + 38 + r * 37
        s.add(hair(c, 36, ry, W - 72))
        for cx, v in zip(cols, row):
            s.add(T(cx, ry + 25, v, 15, c["text"], 400, bg=c["card"], font=MONO if v[0].isdigit() else SANS))
    cy = ty + 186
    s.add(T(36, cy, "詳しくは", 16, c["text"], 400, bg=c["card"]), T(102, cy, "抽出の表", 16, c["text"], 600, bg=c["card"]),
          f'<rect x="102" y="{cy+4}" width="64" height="1.5" fill="{c["text"]}"/>', T(170, cy, "を読む。", 16, c["text"], 400, bg=c["card"]))
    s.add(home(c, W, H))
    return s.svg()


def s05(c, lang="ja"):
    t = L[lang]
    s = Screen(c)
    s.add(status(c, W), nav(c, W, "SKILL.md", t["unpublished"], "back", "dots"), editor_card(c, 16, 120, W - 32, 372, lang))
    s.add(dimmer(c, W, H))
    sy, sh = 330, c["sheet"]
    s.add(f'<rect x="8" y="{sy}" width="{W-16}" height="{H-sy-8}" rx="40" fill="{sh}"/>',
          f'<rect x="{W/2-18}" y="{sy+8}" width="36" height="5" rx="2.5" fill="{c["sec"]}" fill-opacity="0.5"/>',
          T(W / 2, sy + 52, t["lint_title"], 16, c["text"], 600, "middle", bg=sh),
          f'<circle cx="44" cy="{sy+46}" r="20" fill="{c["fill"]}"/>' + ico("x", 44, sy + 46, c["text"], 1.8, 0.8),
          f'<circle cx="{W-44}" cy="{sy+46}" r="20" fill="{c["fill"]}"/>' + ico("share", W - 44, sy + 46, c["text"], 1.7, 0.85))
    s.add(T(28, sy + 124, "6/7", 52, c["text"], 500, bg=sh, font=DISP, ls=-2))
    s.add(T(126, sy + 108, t["warn1"], 17, c["text"], 600, bg=sh), T(126, sy + 128, t["spec_line"], 13, c["sec"], 400, bg=sh))
    y = sy + 150
    s.add(hair(c, 20, y, W - 40))
    y += 16
    s.add(warn_tri(36, y + 14, c["warn"], sh, 6), T(54, y + 19, t["broken"], 16, c["text"], 600, bg=sh),
          T(54, y + 41, t["broken_sub"], 12, c["sec"], 400, bg=sh, font=MONO))
    bw = tw(t["make_file"], 16) + 40
    s.add(pill(c, 54, y + 56, bw, t["make_file"], 40, inverse=True))
    ex = 54 + bw + 18
    s.add(T(ex, y + 82, t["evidence"], 14, c["text"], 500, bg=sh), f'<rect x="{ex}" y="{y+86}" width="{tw(t["evidence"],14):.1f}" height="1" fill="{c["text"]}"/>')
    rows = [(t["r1"], t["r1v"]), (t["r2"], t["r2v"]), (t["r3"], "28/1024"), (t["r4"], "13/500")]
    y += 116
    for i, (k, v) in enumerate(rows):
        ry = y + i * 44
        s.add(ok_dot(36, ry + 16, c["okc"], sh, 6), T(54, ry + 21, k, 15, c["text"], 400, bg=sh), T(W - 32, ry + 21, v, 13, c["sec"], 400, "end", bg=sh, font=MONO))
    ey = y + 4 * 44 + 8
    s.add(hair(c, 20, ey, W - 40), T(28, ey + 28, t["excluded"], 14, c["text"], 400, bg=sh), chev(c, W - 34, ey + 23))
    return s.svg()


def s06(c, error=False):
    s = Screen(c)
    s.add(status(c, W), sheet_full(c, W, H, "変更を反映", right_on=not error))
    y = 150
    s.add(card(c, 20, y, W - 40, 52, fill=c["fill"], r=18), T(38, y + 32, "反映先", 16, c["text"], 400, bg=c["fill"]),
          T(W - 58, y + 32, "main", 15, c["text"], 500, "end", bg=c["fill"], font=MONO),
          f'<path d="M{W-48} {y+22}l4 4 4-4M{W-48} {y+31}l4 4 4-4" fill="none" stroke="{c["sec"]}" stroke-width="1.6" stroke-linecap="round"/>')
    y += 74
    s.add(caption(c, 28, y, "変更（2）", c["sheet"]))
    y += 10
    s.add(card(c, 20, y, W - 40, 232, fill=c["fill"], r=18))
    s.add(T(38, y + 30, "SKILL.md", 15, c["text"], 600, bg=c["fill"], font=MONO), T(W - 38, y + 30, "+2 −1", 13, c["sec"], 400, "end", bg=c["fill"], font=MONO))
    diff = [("−", "dele", "description: お茶の時間を案内"), ("+", "add", "description: お茶の種類ごとに"), ("+", "add", "  抽出時間を案内する。"), (" ", None, "---")]
    dy = y + 44
    for mk, kind, line in diff:
        bg = c["card"] if kind else c["fill"]
        if kind:
            s.add(f'<rect x="30" y="{dy}" width="{W-60}" height="26" rx="6" fill="{bg}"/>')
        s.add(T(40, dy + 18, mk, 13, c["text"], 700, bg=bg, font=MONO), T(58, dy + 18, line, 13, c["text"] if kind != "dele" else c["sec"], 400, bg=bg, font=MONO))
        if kind == "dele":
            s.add(f'<rect x="58" y="{dy+13}" width="{tw(line,13,True):.1f}" height="1" fill="{c["sec"]}"/>')
        dy += 30
    s.add(hair(c, 38, dy + 6, W - 76), T(38, dy + 40, "README.md", 15, c["text"], 600, bg=c["fill"], font=MONO), T(W - 38, dy + 40, "+4 −0", 13, c["sec"], 400, "end", bg=c["fill"], font=MONO))
    y += 252
    s.add(T(28, y, "説明（必須）", 13, c["sec"], 600, bg=c["sheet"]))
    y += 10
    s.add(card(c, 20, y, W - 40, 76, fill=c["fill"], r=18), T(38, y + 32, "description を詳しくした", 16, c["text"], 400, bg=c["fill"]),
          T(W - 38, y + 62, "13 文字", 12, c["sec"], 400, "end", bg=c["fill"]))
    y += 100
    s.add(T(28, y, "GitHub の main に1つの変更として記録されます。", 13, c["sec"], 400, bg=c["sheet"]))
    if error:
        s.add(f'<rect width="{W}" height="{H}" fill="#000000" fill-opacity="0.35"/>')
        ab = c["sheet"] if c["mode"] == "light" else "#222222"
        ax, ay, aw = 30, H / 2 - 150, W - 60
        s.add(f'<rect x="{ax}" y="{ay}" width="{aw}" height="296" rx="34" fill="{ab}"/>',
              T(ax + 26, ay + 46, "反映できませんでした", 20, c["text"], 700, bg=ab),
              T(ax + 26, ay + 80, "GitHub で SKILL.md が先に", 15, c["text"], 400, bg=ab),
              T(ax + 26, ay + 102, "更新されています。手元の変更は", 15, c["text"], 400, bg=ab),
              T(ax + 26, ay + 124, "そのまま残っています。", 15, c["text"], 400, bg=ab),
              pill(c, ax + 18, ay + 156, aw - 36, "違いを見て合わせる", 50))
        gb = c["fill"]
        s.add(f'<rect x="{ax+18}" y="{ay+218}" width="{aw-36}" height="50" rx="25" fill="{gb}"/>', T(W / 2, ay + 249, "キャンセル", 16, c["text"], 600, "middle", bg=gb))
    s.add(home(c, W, H))
    return s.svg()


def s07(c):
    s = Screen(c)
    s.add(status(c, W), sheet_full(c, W, H, "新規作成"))
    y = 158
    s.add(caption(c, 28, y, "ひな形", c["sheet"]))
    y += 10
    items = [("SKILL.md", "Agent Skill（決まりに合う形）", True), ("CLAUDE.md", "Claude Code への指示", False),
             ("AGENTS.md", "いろいろなエージェントへの指示", False), ("README.md", "人が読む説明", False), ("空のファイル", "md だけ", False)]
    s.add(card(c, 20, y, W - 40, 5 * 62 + 12, fill=c["fill"], r=22))
    for i, (n, sub, on) in enumerate(items):
        ry = y + 6 + i * 62
        rb = c["fill"]
        if on:
            rb = c["card"]
            s.add(f'<rect x="26" y="{ry+3}" width="{W-52}" height="56" rx="16" fill="{rb}"/>')
        s.add(ico("doc", 50, ry + 31, c["text"], 1.6), T(74, ry + 28, n, 15, c["text"], 600 if on else 500, bg=rb, font=MONO if "." in n else SANS),
              T(74, ry + 48, sub, 12, c["sec"], 400, bg=rb))
        if on:
            s.add(ico("check", W - 52, ry + 31, c["text"], 2.2, 0.9))
    y += 5 * 62 + 12 + 30
    s.add(T(28, y, "スキルの名前（フォルダ名にもなります）", 13, c["sec"], 600, bg=c["sheet"]))
    y += 10
    s.add(card(c, 20, y, W - 40, 52, fill=c["fill"], r=18), T(38, y + 33, "kettle-guide", 16, c["text"], 500, bg=c["fill"], font=MONO),
          ok_dot(W - 46, y + 26, c["okc"], c["fill"], 7))
    y += 72
    s.add(T(28, y, "小文字・数字・ハイフンだけ。決まりに合っています。", 13, c["sec"], 400, bg=c["sheet"]))
    y += 24
    s.add(card(c, 20, y, W - 40, 52, fill=c["fill"], r=18), T(38, y + 32, "保存先", 16, c["text"], 400, bg=c["fill"]),
          T(W - 56, y + 32, "tea-timer-skill", 14, c["sec"], 400, "end", bg=c["fill"], font=MONO), chev(c, W - 42, y + 26))
    s.add(home(c, W, H))
    return s.svg()


def s08(c):
    s = Screen(c)
    s.add(status(c, W), nav(c, W, "", None, "back", None))
    s.add(ico("link", W / 2, 260, c["text"], 1.4, 3.4))
    s.add(T(W / 2, 360, "GitHub と連携します", 26, c["text"], 700, "middle"))
    lines = ["リポの md をそのまま開いて、", "検査してから反映できます。", "", "触れるリポは、次に開く GitHub の", "画面で選べます。パスワードは", "このアプリに保存しません。"]
    y = 402
    for ln in lines:
        if ln:
            s.add(T(W / 2, y, ln, 16, c["text"], 400, "middle"))
        y += 27 if ln else 14
    s.add(pill(c, 20, H - 132, W - 40, "続ける"), home(c, W, H))
    return s.svg()


def s09(c):
    s = Screen(c)
    s.add(status(c, W), sheet_full(c, W, H, "", right=None))
    s.add(T(28, 196, "GitHub への反映は", 28, c["text"], 700, bg=c["sheet"]), T(28, 232, "Pro の機能です", 28, c["text"], 700, bg=c["sheet"]))
    s.add(T(28, 268, "編集と検査は、これまでどおり無料です。", 15, c["sec"], 400, bg=c["sheet"]))
    s.add(card(c, 20, 300, W - 40, 236, fill=c["fill"], r=26))
    s.add(T(40, 340, "Skillwright Pro", 20, c["text"], 700, bg=c["fill"]), T(40, 366, "買い切り（定期的な支払いはありません）", 13, c["sec"], 400, bg=c["fill"]))
    for i, f in enumerate(["GitHub への反映", "ブランチの選択", "競合したときの合わせ込み"]):
        s.add(ok_dot(48, 400 + i * 30, c["okc"], c["fill"], 7), T(64, 405 + i * 30, f, 16, c["text"], 400, bg=c["fill"]))
    s.add(T(40, 512, "¥1,500（税込・仮）", 22, c["text"], 600, bg=c["fill"]))
    s.add(pill(c, 20, H - 226, W - 40, "¥1,500 で購入"))
    s.add(T(W / 2, H - 140, "購入を復元", 16, c["text"], 500, "middle", bg=c["sheet"]),
          T(W / 2 - 14, H - 100, "利用規約", 14, c["text"], 500, "end", bg=c["sheet"]),
          T(W / 2 + 14, H - 100, "プライバシーポリシー", 14, c["text"], 500, "start", bg=c["sheet"]), home(c, W, H))
    return s.svg()


def s10(c, scrolled=False):
    s = Screen(c)
    s.add(status(c, W), nav(c, W, "設定", left=None))
    if scrolled:
        groups = [("GitHub", [("yamabuki-dev", "chev"), ("反映するときの名前とメール", "chev"), ("連携を解除", "red")]),
                  ("Pro", [("Skillwright Pro", "購入済み"), ("購入を復元", "chev")]),
                  ("", [("このアプリについて", "chev")])]
    else:
        groups = [("エディタ", [("行番号を表示", "on"), ("補助キーの並び", "chev"), ("自動保存", "on")]),
                  ("検査", [("決まりの組み合わせ", "仕様＋Claude Code"), ("文章量の目安を表示", "on"), ("内蔵 AI を使う", "on"), ("検査ルールの版", "2026.10.30・最新")]),
                  ("Claude", [("Claude の鍵", "末尾 •••• 7Qx2")]),
                  ("GitHub", [("yamabuki-dev", "chev"), ("反映するときの名前とメール", "chev"), ("連携を解除", "red")])]
    y = 132
    for g, rows in groups:
        s.add(caption(c, 24, y, g))
        y += 10
        rh = 44
        s.add(card(c, 16, y, W - 32, rh * len(rows), r=24))
        for i, (n, kind) in enumerate(rows):
            ry = y + i * rh
            col = c["err"] if kind == "red" else c["text"]
            s.add(T(34, ry + 28, n, 16, col, 400, bg=c["card"], font=MONO if n.endswith("dev") else SANS))
            if kind == "on":
                s.add(toggle(c, W - 82, ry + 6.5, True))
            elif kind == "chev":
                s.add(chev(c, W - 38, ry + 22))
            elif kind == "購入済み":
                s.add(T(W - 34, ry + 28, kind, 14, c["sec"], 400, "end", bg=c["card"]))
            elif kind != "red":
                s.add(T(W - 52, ry + 28, kind, 14, c["sec"], 400, "end", bg=c["card"]), chev(c, W - 38, ry + 22))
            if i < len(rows) - 1:
                s.add(hair(c, 34, ry + rh - 0.5, W - 68))
        y += rh * len(rows) + 26
    s.add(tab_bar(c, W, H, active=2), home(c, W, H))
    return s.svg()


def s11(c):
    """Frontmatter form: description as two fields + two limits shown together."""
    s = Screen(c)
    s.add(status(c, W), sheet_full(c, W, H, "項目"))
    y = 160
    s.add(T(28, y, "name", 13, c["sec"], 600, bg=c["sheet"], font=MONO))
    y += 10
    s.add(card(c, 20, y, W - 40, 50, fill=c["fill"], r=16), T(36, y + 32, "tea-timer", 16, c["text"], 500, bg=c["fill"], font=MONO),
          ok_dot(W - 44, y + 25, c["okc"], c["fill"], 7))
    y += 74
    s.add(T(28, y, "何をするか", 13, c["sec"], 600, bg=c["sheet"]))
    y += 10
    s.add(card(c, 20, y, W - 40, 50, fill=c["fill"], r=16), T(36, y + 32, "お茶の種類ごとに抽出時間を案内する", 15, c["text"], 400, bg=c["fill"]))
    y += 74
    s.add(T(28, y, "いつ使うか", 13, c["sec"], 600, bg=c["sheet"]))
    y += 10
    s.add(card(c, 20, y, W - 40, 50, fill=c["fill"], r=16), T(36, y + 32, "お茶の淹れ方や時間を聞かれたとき", 15, c["text"], 400, bg=c["fill"]),
          f'<rect x="{36+tw("お茶の淹れ方や時間を聞かれたとき",15)+2:.1f}" y="{y+16}" width="2" height="20" fill="{c["text"]}"/>')
    y += 74
    s.add(caption(c, 28, y, "つないだ説明", c["sheet"]))
    y += 10
    s.add(card(c, 20, y, W - 40, 150, fill=c["tint"], r=18))
    s.add(T(36, y + 30, "お茶の種類ごとに抽出時間を案内する。お茶の", 14, c["text"], 400, bg=c["tint"]),
          T(36, y + 52, "淹れ方や時間を聞かれたときに使う。", 14, c["text"], 400, bg=c["tint"]))
    for i, (lab, n, mx) in enumerate([("仕様の上限", 34, 1024), ("Claude Code の一覧", 34, 1536)]):
        by = y + 84 + i * 30
        s.add(T(36, by, lab, 12, c["sec"], 400, bg=c["tint"]), T(W - 36, by, f"{n} / {mx}", 12, c["text"], 500, "end", bg=c["tint"], font=MONO),
              f'<rect x="36" y="{by+7}" width="{W-72}" height="4" rx="2" fill="{c["hair"]}"/>',
              f'<rect x="36" y="{by+7}" width="{(W-72)*n/mx:.1f}" height="4" rx="2" fill="{c["text"]}"/>')
    y += 172
    s.add(card(c, 20, y, W - 40, 52, fill=c["fill"], r=16), T(36, y + 32, "claude.ai に上げる", 16, c["text"], 400, bg=c["fill"]), toggle(c, W - 82, y + 10.5, True))
    y += 70
    s.add(T(28, y, "大事な使い道を前に置くと、一覧で切れても伝わります。", 12, c["sec"], 400, bg=c["sheet"]))
    s.add(home(c, W, H))
    return s.svg()


def s17(c, lang="ja", kb=False):
    t = L[lang]
    s = Screen(c)
    s.add(status(c, W), nav(c, W, t["trig_title"], "tea-timer", "back", None))
    y = 124
    s.add(card(c, 16, y, W - 32, 112))
    s.add(caption(c, 36, y + 30, t["trig_cap"], c["card"]))
    s.add(T(36, y + 62, t["trig_q"], 17, c["text"], 500, bg=c["card"]))
    s.add(f'<rect x="{36+tw(t["trig_q"],17)+3:.1f}" y="{y+46}" width="2" height="21" fill="{c["text"]}"/>')
    s.add(T(36, y + 92, "tea-timer", 12, c["sec"], 400, bg=c["card"], font=MONO))
    y += 140
    # verdict
    s.add(T(24, y + 52, t["trig_res"], 48, c["text"], 600, font=DISP, ls=-1.5))
    for i in range(5):
        s.add(f'<rect x="{24+i*30}" y="{y+70}" width="24" height="8" rx="4" fill="{c["text"] if i < 4 else c["hair"]}"/>')
    s.add(T(184, y + 79, "4 / 5", 13, c["sec"], 500, font=MONO))
    y += 104
    s.add(T(24, y, t["trig_sub"], 13, c["sec"], 400))
    x = 24
    for wd in t["trig_words"]:
        ww = tw(wd, 14) + 24
        s.add(f'<rect x="{x:.1f}" y="{y+12}" width="{ww:.1f}" height="30" rx="15" fill="{c["card"]}" stroke="{c["btn_line"]}"/>',
              T(x + ww / 2, y + 32, wd, 14, c["text"], 600, "middle", bg=c["card"]))
        x += ww + 8
    if kb:
        s.add(keyboard(c, W, H, H - 290).replace("空白", "空白" if lang == "ja" else "space"))
        s.add(pill(c, 16, H - 290 - 8 - 52, W - 32, t["trig_btn"]), home(c, W, H))
        return s.svg()
    y += 72
    s.add(caption(c, 24, y, t["trig_hist"]))
    y += 10
    s.add(card(c, 16, y, W - 32, 3 * 50 + 8))
    for i, (q, ok) in enumerate(t["hist"]):
        ry = y + 4 + i * 50
        if ok:
            s.add(ok_dot(38, ry + 25, c["okc"], c["card"], 6))
        else:
            s.add(f'<circle cx="38" cy="{ry+25}" r="6" fill="none" stroke="{c["sec"]}" stroke-width="1.5"/>')
        s.add(T(54, ry + 30, q, 15, c["text"], 400, bg=c["card"]), T(W - 34, ry + 30, t["maybe"] if ok else t["nope"], 12, c["sec"], 400, "end", bg=c["card"]))
        if i < 2:
            s.add(hair(c, 54, ry + 49.5, W - 86))
    y += 3 * 50 + 22
    s.add(T(24, y, t["trig_note"], 11, c["sec"], 400))
    y += 22
    s.add(card(c, 16, y, W - 32, 48, r=24), ico("spark", 40, y + 24, c["text"], 1.5, 0.8), T(60, y + 30, t["trig_claude"], 15, c["text"], 500, bg=c["card"]), chev(c, W - 38, y + 24))
    s.add(pill(c, 16, H - 102, W - 32, t["trig_btn"]), home(c, W, H))
    return s.svg()


def s18(c):
    s = Screen(c)
    s.add(status(c, W), nav(c, W, "切り出し", "SKILL.md", "back", None))
    s.add(T(24, 168, "3,900", 56, c["text"], 500, font=DISP, ls=-2), T(184, 168, "→ 2,660", 28, c["sec"], 500, font=DISP))
    s.add(T(26, 196, "本文のトークン（目安）。5,000 以下がおすすめ", 13, c["sec"], 400))
    y = 222
    secs = [("## 使い方", 420, False), ("## 抽出の表", 1240, True), ("## 例外のとき", 610, False), ("## よくある質問", 980, False), ("## 変更履歴", 650, False)]
    s.add(card(c, 16, y, W - 32, len(secs) * 58 + 12))
    for i, (h, n, on) in enumerate(secs):
        ry = y + 6 + i * 58
        rb = c["card"]
        if on:
            rb = c["tint"]
            s.add(f'<rect x="22" y="{ry+3}" width="{W-44}" height="52" rx="16" fill="{rb}"/>')
            s.add(ico("check", 44, ry + 29, c["text"], 2.2, 0.8))
        else:
            s.add(f'<circle cx="44" cy="{ry+29}" r="8" fill="none" stroke="{c["sec"]}" stroke-width="1.5"/>')
        s.add(T(64, ry + 26, h, 15, c["text"], 600 if on else 400, bg=rb), T(W - 34, ry + 26, f"{n:,}", 13, c["sec"], 400, "end", bg=rb, font=MONO))
        s.add(f'<rect x="64" y="{ry+36}" width="{(W-130)*n/1240:.1f}" height="4" rx="2" fill="{c["text"] if on else c["sec"]}"/>')
    y += len(secs) * 58 + 12 + 28
    s.add(T(24, y, "移す先", 13, c["sec"], 600))
    y += 10
    s.add(card(c, 16, y, W - 32, 52, r=18), T(34, y + 33, "references/brewing-table.md", 15, c["text"], 500, bg=c["card"], font=MONO))
    y += 70
    s.add(T(24, y, "元の場所には「詳しくは brewing-table.md を読む」", 13, c["sec"], 400), T(24, y + 20, "という1行のリンクが入ります。", 13, c["sec"], 400))
    s.add(pill(c, 16, H - 102, W - 32, "切り出す"), home(c, W, H))
    return s.svg()


def s19(c, lang="ja"):
    t = L[lang]
    s = Screen(c)
    s.add(status(c, W), nav(c, W, t["view_title"], "tea-timer", "back", None))
    layers = [("1", t["v1"], t["v1s"], 62, None), ("2", t["v2"], t["v2s"], 120, None), ("3", t["v3"], t["v3s"], 0, "warn")]
    y = 128
    for i, (n, ttl, sub, tok, flag) in enumerate(layers):
        h = 150 if i < 2 else 176
        s.add(card(c, 16 + i * 6, y, W - 32 - i * 12, h))
        x = 36 + i * 6
        s.add(T(x, y + 54, n, 44, c["text"], 500, bg=c["card"], font=DISP))
        s.add(T(x + 44, y + 34, ttl, 16, c["text"], 600, bg=c["card"]), T(x + 44, y + 56, sub, 13, c["sec"], 400, bg=c["card"]))
        if i == 0:
            s.add(f'<rect x="{x}" y="{y+76}" width="{W-104}" height="52" rx="12" fill="{c["tint"]}"/>',
                  T(x + 14, y + 98, "name: tea-timer", 12, c["text"], 400, bg=c["tint"], font=MONO),
                  T(x + 14, y + 118, "description: お茶の種類ごと…" if lang == "ja" else "description: Guides brewing…", 12, c["text"], 400, bg=c["tint"], font=MONO))
            s.add(T(W - 40, y + 34, f"~{tok}", 13, c["sec"], 500, "end", bg=c["card"], font=MONO))
        elif i == 1:
            for k in range(5):
                s.add(f'<rect x="{x}" y="{y+80+k*12}" width="{(W-110)*(0.9-0.12*k):.1f}" height="5" rx="2.5" fill="{c["hair"] if c["mode"]=="light" else "#333333"}"/>')
            s.add(T(W - 46, y + 34, f"~{tok}", 13, c["sec"], 500, "end", bg=c["card"], font=MONO))
        else:
            rows = [("references/brewing.md", False), ("scripts/steep.py", True)]
            for k, (fn, ok) in enumerate(rows):
                ry = y + 84 + k * 46
                s.add(ico("doc", x + 10, ry, c["text"], 1.5, 0.8), T(x + 28, ry + 5, fn, 13, c["text"], 500, bg=c["card"], font=MONO))
                if ok:
                    s.add(ok_dot(W - 54, ry, c["okc"], c["card"], 6))
                else:
                    s.add(warn_tri(W - 54, ry, c["warn"], c["card"], 6))
                    s.add(T(x + 28, ry + 23, t["missing"], 12, c["warn"] if c["mode"] == "dark" else c["sec"], 400, bg=c["card"]))
        y += h + 14
    s.add(T(24, y + 22, f'{t["total"]}  ~182 {t["tokens"]}', 13, c["sec"], 500, font=MONO))
    s.add(home(c, W, H))
    return s.svg()


def s20(c):
    s = Screen(c)
    s.add(status(c, W), nav(c, W, "書き出し", "tea-timer", "back", None))
    y = 128
    s.add(caption(c, 24, y, "書き出し先"))
    y += 10
    opts = [("claude.ai 用 ZIP", "Customize › Skills から上げる", True), ("Claude Code", ".claude/skills/tea-timer/", False),
            ("GitHub Copilot", ".github/skills/tea-timer/", False), ("汎用", ".agents/skills/tea-timer/", False)]
    s.add(card(c, 16, y, W - 32, len(opts) * 62 + 12))
    for i, (n, sub, on) in enumerate(opts):
        ry = y + 6 + i * 62
        rb = c["card"]
        if on:
            rb = c["tint"]
            s.add(f'<rect x="22" y="{ry+3}" width="{W-44}" height="56" rx="16" fill="{rb}"/>')
        s.add(T(40, ry + 28, n, 16, c["text"], 600 if on else 500, bg=rb), T(40, ry + 48, sub, 12, c["sec"], 400, bg=rb, font=MONO if sub.startswith(".") else SANS))
        if on:
            s.add(ico("check", W - 46, ry + 31, c["text"], 2.2, 0.9))
        if i < len(opts) - 1 and not on:
            s.add(hair(c, 40, ry + 61.5, W - 72))
    y += len(opts) * 62 + 12 + 30
    s.add(caption(c, 24, y, "書き出す前の確認"))
    y += 10
    checks = [("フォルダ名と name が一致", True), ("仕様にない項目がない", True), ("鍵やトークンが入っていない", True), ("リンク切れ 1件", False)]
    s.add(card(c, 16, y, W - 32, len(checks) * 44 + 12))
    for i, (k, ok) in enumerate(checks):
        ry = y + 6 + i * 44
        s.add(ok_dot(38, ry + 22, c["okc"], c["card"], 6) if ok else warn_tri(38, ry + 22, c["warn"], c["card"], 6),
              T(56, ry + 27, k, 15, c["text"], 400, bg=c["card"]))
    y += len(checks) * 44 + 24
    s.add(T(24, y, "リンク切れがあっても書き出せます。", 13, c["sec"], 400))
    s.add(pill(c, 16, H - 102, W - 32, "ZIP を書き出す"), home(c, W, H))
    return s.svg()


# ------------------------------------------------------------------ iPhone Duo
def side_col(c, w, h, items, tabs=True, folded_tab=False, lang="ja"):
    x = w - 52
    cx = x + 26
    p = [f'<circle cx="{cx}" cy="34" r="16" fill="#000"/>', T(cx, 78, "9:41", 13, c["text"], 600, "middle")]
    y = 116
    for k in items:
        p.append(btn_icon(c, cx, y, k))
        y += 54
    if tabs:
        th = 3 * 58 + 10
        ty = h - 24 - 50 - th
        p.append(f'<circle cx="{cx}" cy="{h-44}" r="21" fill="{c["btn"]}" stroke="{c["btn_line"]}"/>' + ico("search", cx, h - 44, c["text"]))
        p.append(f'<rect x="{cx-23}" y="{ty}" width="46" height="{th}" rx="23" fill="{c["btn"]}" stroke="{c["btn_line"]}"/>')
        for i in range(3):
            ky = ty + 5 + 58 * i + 29
            col = c["text"] if i == 0 else c["sec"]
            if i == 0:
                p.append(f'<path d="M{cx-10} {ky-7}h7l2 3h11v11h-20z" fill="{col}"/>')
            elif i == 1:
                p.append(f'<circle cx="{cx}" cy="{ky}" r="9" fill="{col}"/><path d="M{cx} {ky-5}v5l4 3" stroke="{c["btn"]}" stroke-width="2" fill="none" stroke-linecap="round"/>')
            else:
                p.append("".join(f'<rect x="{cx-2.3}" y="{ky-11}" width="4.6" height="5.5" rx="1" fill="{col}" transform="rotate({a} {cx} {ky})"/>' for a in range(0, 360, 45))
                         + f'<circle cx="{cx}" cy="{ky}" r="7.8" fill="{col}"/><circle cx="{cx}" cy="{ky}" r="3.2" fill="{c["btn"]}"/>')
    if folded_tab:
        p.append(f'<circle cx="{cx}" cy="{h-44}" r="21" fill="{c["btn"]}" stroke="{c["btn_line"]}"/>'
                 f'<path d="M{cx-10} {h-51}h7l2 3h11v11h-20z" fill="{c["text"]}"/>')
    return "".join(p)


def duo_outer_list(c):
    w, h = 466, 678
    s = Screen(c, w, h)
    cw = w - 52
    s.add(side_col(c, w, h, ["back", "plus"]))
    s.add(T(20, 58, "tea-timer-skill", 18, c["text"], 600, font=MONO), T(20, 80, "main", 13, c["sec"], 400))
    s.add(hero(c, 20, 170, "ja", c["bg"]).replace('x="270.0"', 'x="270.0"'))
    s.add(file_list(c, 14, 220, cw - 22, "ja", rh=56))
    s.add(pill(c, 14, 220 + 56 * 5 + 28, cw - 22, "2件の変更を反映", 48))
    return s.svg()


def duo_outer_editor(c):
    w, h = 466, 678
    s = Screen(c, w, h)
    cw = w - 52
    s.add(side_col(c, w, h, ["back", "eye", "dots"], tabs=False, folded_tab=True))
    s.add(T(20, 52, "SKILL.md", 18, c["text"], 600, font=MONO), T(20, 74, "未反映", 13, c["sec"], 400))
    s.add(editor_card(c, 14, 92, cw - 22, 380, "ja"))
    s.add(pill(c, 14, 488, cw - 22, "完了", 48))
    return s.svg()


def duo_inner(c, folded=False):
    w, h = 951, 669
    s = Screen(c, w, h)
    side = 52
    band = 13
    lw = (w / 2 - band - 22) if folded else 340
    dx = (w / 2 + band) if folded else (16 + lw + 20)
    dw = w - side - dx - 10
    s.add(side_col(c, w, h, ["eye", "dots"]))
    s.add(btn_icon(c, 36, 40, "back"), btn_icon(c, 16 + lw - 22, 40, "plus"))
    s.add(T(24, 104, "tea-timer-skill", 18, c["text"], 600, font=MONO), T(24, 124, "main・注意 1・未反映 2", 13, c["sec"], 400))
    s.add('<g data-fold-ok="1">' + file_list(c, 14, 140, lw, "ja", rh=56, sel="SKILL.md", chevs=False) + '</g>')
    s.add(pill(c, 14, 140 + 56 * 5 + 28, lw, "2件の変更を反映", 48))
    s.add(T(dx + 6, 52, "SKILL.md", 18, c["text"], 600, font=MONO), T(dx + 6, 74, "未反映", 13, c["sec"], 400))
    s.add('<g data-fold-ok="1">' + editor_card(c, dx, 92, dw, 380, "ja") + '</g>')
    return s.svg()


# ------------------------------------------------------------------ iPad
def ipad(c, narrow=False):
    w, h = (600, 1032) if narrow else (1376, 1032)
    s = Screen(c, w, h)
    s.add(T(32, 34, "9:41", 15, c["text"], 600))
    if narrow:
        for k, col in enumerate(("#FF5F57", "#FEBC2E", "#28C840")):
            s.add(f'<circle cx="{30+k*20}" cy="80" r="6" fill="{col}"/>')
        s.add(btn_icon(c, 116, 80, "sidebar"), btn_icon(c, w - 40, 80, "plus"), btn_icon(c, w - 88, 80, "search"))
        s.add(T(w / 2, 86, "tea-timer-skill", 16, c["text"], 600, "middle", font=MONO))
        s.add(hero(c, 28, 196, "ja", c["bg"]))
        s.add(file_list(c, 20, 252, w - 40, "ja"))
        s.add(pill(c, 20, 252 + 62 * 5 + 32, w - 40, "2件の変更を反映"))
        return s.svg()
    sw = 290
    s.add(card(c, 12, 52, sw, h - 64, r=28))
    s.add(btn_icon(c, 44, 92, "sidebar"))
    s.add(ico("search", 46, 174, c["text"], 1.5, 0.0) if False else "", T(32, 180, "最近", 16, c["text"], 500, bg=c["card"]))
    s.add(caption(c, 32, 226, "GitHub", c["card"]))
    for i, (n, on) in enumerate([("tea-timer-skill", True), ("kettle-notes", False)]):
        y = 238 + i * 50
        rb = c["tint"] if on else c["card"]
        if on:
            s.add(f'<rect x="22" y="{y}" width="{sw-20}" height="44" rx="14" fill="{rb}"/>')
        s.add(ico("box", 46, y + 22, c["text"], 1.5, 0.85), T(66, y + 28, n, 15, c["text"], 600 if on else 400, bg=rb, font=MONO))
    s.add(caption(c, 32, 370, "この iPad", c["card"]))
    for i, (k, n) in enumerate([("tablet", "この iPad"), ("cloud", "iCloud Drive")]):
        y = 382 + i * 50
        s.add(ico(k, 46, y + 22, c["text"], 1.5, 0.85), T(66, y + 28, n, 15, c["text"], 400, bg=c["card"]))
    s.add(T(32, h - 40, "設定", 16, c["text"], 500, bg=c["card"]))
    lx, lw = sw + 32, 400
    s.add(T(lx + lw / 2, 86, "tea-timer-skill", 16, c["text"], 600, "middle", font=MONO), btn_icon(c, lx + lw - 20, 80, "plus"))
    s.add(hero(c, lx + 8, 196, "ja", c["bg"]).replace(f'x="{lx+8+250:.1f}"', f'x="{lx+8+250:.1f}"'))
    s.add(file_list(c, lx, 252, lw, "ja", sel="SKILL.md", chevs=False))
    s.add(pill(c, lx, 252 + 62 * 5 + 32, lw, "2件の変更を反映"))
    dx = lx + lw + 24
    dw = w - dx - 20
    sx = w - 20 - 220
    s.add(f'<rect x="{sx}" y="58" width="220" height="44" rx="22" fill="{c["btn"]}" stroke="{c["btn_line"]}"/>'
          + ico("search", sx + 24, 80, c["sec"]) + T(sx + 44, 86, "ファイル名で検索", 14, c["sec"], 400, bg=c["btn"]))
    px = sx - 12 - 130
    s.add(f'<rect x="{px}" y="58" width="130" height="44" rx="22" fill="{c["btn"]}" stroke="{c["btn_line"]}"/>'
          + ico("eye", px + 28, 80, c["text"]) + T(px + 44, 86, "プレビュー", 14, c["text"], 500, bg=c["btn"]))
    s.add(btn_icon(c, px - 34, 80, "dots"))
    s.add(T(dx + 6, 150, "SKILL.md", 20, c["text"], 600, font=MONO), T(dx + 6, 174, "未反映", 13, c["sec"], 400))
    s.add(editor_card(c, dx, 196, dw, h - 196 - 24, "ja"))
    return s.svg()


def s06_pr(c, lang="ja"):
    ja = lang == "ja"
    s = Screen(c)
    s.add(status(c, W), sheet_full(c, W, H, "変更を反映" if ja else "Publish Changes", right="check", right_on=True))
    sh = c["sheet"]
    y = 140
    s.add(card(c, 20, y, W - 40, 88, fill=c["fill"], r=18))
    s.add(warn_tri(42, y + 30, c["warn"], c["fill"], 6),
          T(58, y + 35, "main は保護されています" if ja else "main is protected", 15, c["text"], 600, bg=c["fill"]),
          T(38, y + 62, "直接は反映できないので、新しいブランチに置いて" if ja else "Your changes go to a new branch with a", 13, c["sec"], 400, bg=c["fill"]),
          T(38, y + 80, "レビュー依頼（プルリクエスト）を出します。" if ja else "pull request for review.", 13, c["sec"], 400, bg=c["fill"]))
    y += 108
    s.add(caption(c, 28, y, "反映先" if ja else "BRANCH", sh))
    y += 10
    s.add(card(c, 20, y, W - 40, 144, fill=c["fill"], r=18))
    s.add(T(38, y + 32, "新しいブランチ" if ja else "New branch", 15, c["text"], 400, bg=c["fill"]),
          T(W - 38, y + 32, "skillwright/tea-timer-10301042", 13, c["text"], 500, "end", bg=c["fill"], font=MONO),
          hair(c, 38, y + 48, W - 76),
          T(38, y + 78, "合わせる先" if ja else "Merge into", 15, c["text"], 400, bg=c["fill"]),
          T(W - 38, y + 78, "main", 14, c["text"], 500, "end", bg=c["fill"], font=MONO),
          hair(c, 38, y + 96, W - 76),
          T(38, y + 126, "下書きとして出す" if ja else "Open as draft", 15, c["text"], 400, bg=c["fill"]),
          toggle(c, W - 82, y + 105, False))
    y += 168
    s.add(caption(c, 28, y, "変更（2）" if ja else "CHANGES · 2", sh))
    y += 10
    s.add(card(c, 20, y, W - 40, 100, fill=c["fill"], r=18))
    for i, (fn, d) in enumerate([("SKILL.md", "+2 −1"), ("README.md", "+4 −0")]):
        ry = y + 34 + i * 44
        s.add(T(38, ry, fn, 15, c["text"], 500, bg=c["fill"], font=MONO), T(W - 38, ry, d, 13, c["sec"], 400, "end", bg=c["fill"], font=MONO))
        if i == 0:
            s.add(hair(c, 38, ry + 14, W - 76))
    y += 124
    s.add(T(28, y, "題名（必須）" if ja else "Title (required)", 13, c["sec"], 600, bg=sh))
    y += 10
    s.add(card(c, 20, y, W - 40, 52, fill=c["fill"], r=18),
          T(38, y + 32, "description を詳しくした" if ja else "Clarify the description", 16, c["text"], 400, bg=c["fill"]))
    y += 76
    s.add(T(28, y, "右上の ✓ でレビュー依頼を出します。" if ja else "Tap ✓ to open the pull request.", 13, c["sec"], 400, bg=sh))
    s.add(home(c, W, H))
    return s.svg()


def s21(c):
    s = Screen(c)
    s.add(status(c, W), nav(c, W, "版の履歴", "SKILL.md", "back", None))
    y = 128
    s.add(caption(c, 24, y, "今日"))
    y += 10
    rows = [("10:42", "いまの版", None, True), ("10:31", "+3 −1", None, False), ("09:58", "+12 −0", "反映した版", False)]
    s.add(card(c, 16, y, W - 32, len(rows) * 56 + 8))
    for i, (tm, sub, tag, cur) in enumerate(rows):
        ry = y + 4 + i * 56
        rb = c["card"]
        if i == 1:
            rb = c["tint"]
            s.add(f'<rect x="22" y="{ry+2}" width="{W-44}" height="52" rx="16" fill="{rb}"/>')
        if i == 1:
            s.add(ico("check", 40, ry + 28, c["text"], 2.2, 0.8))
        s.add(T(60, ry + 34, tm, 17, c["text"], 600 if i == 1 else 400, bg=rb, font=MONO),
              T(124, ry + 34, sub, 14, c["sec"], 400, bg=rb, font=SANS if cur else MONO))
        if tag:
            tx = W - 38 - tw(tag, 13)
            s.add(f'<circle cx="{tx-14:.1f}" cy="{ry+29}" r="7.5" fill="none" stroke="{c["sec"]}" stroke-width="1.4"/>'
                  f'<path d="M{tx-14:.1f} {ry+33}v-8M{tx-17.5:.1f} {ry+28.5}l3.5-3.5 3.5 3.5" fill="none" stroke="{c["sec"]}" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round"/>',
                  T(W - 38, ry + 34, tag, 13, c["sec"], 400, "end", bg=rb))
        if i < len(rows) - 1 and i != 0:
            s.add(hair(c, 38, ry + 55.5, W - 76))
    y += len(rows) * 56 + 8 + 30
    s.add(caption(c, 24, y, "10:31 の版に戻すと"))
    y += 10
    s.add(card(c, 16, y, W - 32, 196))
    diff = [("−", "dele", "description: お茶の種類ごとに"), ("−", "dele", "  抽出時間を案内する。"), ("+", "add", "description: お茶の種類"), (" ", None, "---"), ("−", "dele", "## 例外のとき")]
    dy = y + 16
    for mk, kind, line in diff:
        bg = c["fill"] if kind else c["card"]
        if kind:
            s.add(f'<rect x="28" y="{dy}" width="{W-56}" height="28" rx="6" fill="{bg}"/>')
        s.add(T(40, dy + 19, mk, 13, c["text"], 700, bg=bg, font=MONO), T(58, dy + 19, line, 13, c["text"] if kind != "dele" else c["sec"], 400, bg=bg, font=MONO))
        if kind == "dele":
            s.add(f'<rect x="58" y="{dy+14}" width="{tw(line,13,True):.1f}" height="1" fill="{c["sec"]}"/>')
        dy += 34
    y += 196 + 20
    s.add(T(24, y, "戻す前に、いまの版も控えます。戻しても反映はしません。", 13, c["sec"], 400))
    s.add(pill(c, 16, H - 102, W - 32, "10:31 の版に戻す"), home(c, W, H))
    return s.svg()


def s22(c, new=False):
    s = Screen(c)
    # host app (fictional notes) behind, dimmed
    s.add(status(c, W), T(24, 120, "メモ", 34, c["text"], 700), card(c, 16, 140, W - 32, 220, r=24))
    for i in range(6):
        s.add(f'<rect x="36" y="{166+i*30}" width="{(W-72)*(0.95-0.1*(i%3)):.1f}" height="10" rx="5" fill="{c["skel"]}"/>')
    sy = 210
    s.add(dimmer(c, W, H), f'<path d="M0 {sy+38}a38 38 0 0 1 38 -38h{W-76}a38 38 0 0 1 38 38v{H-sy-38}h-{W}z" fill="{c["sheet"]}"/>')
    sh = c["sheet"]
    cy = sy + 46
    s.add(f'<circle cx="44" cy="{cy}" r="20" fill="{c["fill"]}"/>' + ico("x", 44, cy, c["text"], 1.8, 0.85),
          T(W / 2, cy + 6, "Skillwright に取り込む", 16, c["text"], 600, "middle", bg=sh),
          f'<circle cx="{W-44}" cy="{cy}" r="20" fill="{c["pill"]}"/>' + ico("check", W - 44, cy, c["pill_ink"], 2, 0.8))
    y = sy + 96
    s.add(card(c, 20, y, W - 40, 104, fill=c["fill"], r=18))
    lines = ["## 失敗したとき", "- お湯が熱すぎたら、30秒待ってから", "  もう一度淹れる"]
    for i, ln in enumerate(lines):
        s.add(T(38, y + 30 + i * 24, ln, 14, c["text"] if i else c["text"], 600 if i == 0 else 400, bg=c["fill"], font=MONO if ln.startswith("#") else SANS))
    y += 128
    # segmented
    sw = (W - 40) / 2
    s.add(f'<rect x="20" y="{y}" width="{W-40}" height="40" rx="20" fill="{c["fill"]}"/>',
          f'<rect x="{(23 if new else 20+sw+3):.1f}" y="{y+3}" width="{sw-6:.1f}" height="34" rx="17" fill="{c["card"]}" stroke="{c["btn_line"]}"/>',
          T(20 + sw / 2, y + 26, "新しいファイル", 14, c["text"] if new else c["sec"], 600 if new else 500, "middle", bg=c["card"] if new else c["fill"]),
          T(20 + sw * 1.5, y + 26, "今あるファイルに追記", 14, c["sec"] if new else c["text"], 500 if new else 600, "middle", bg=c["fill"] if new else c["card"]))
    y += 62
    s.add(card(c, 20, y, W - 40, 104, fill=c["fill"], r=18))
    if new:
        s.add(T(38, y + 32, "保存先", 15, c["text"], 400, bg=c["fill"]), T(W - 56, y + 32, "tea-timer-skill/references", 13, c["text"], 500, "end", bg=c["fill"], font=MONO), chev(c, W - 42, y + 27),
              hair(c, 38, y + 52, W - 76),
              T(38, y + 84, "ファイル名", 15, c["text"], 400, bg=c["fill"]), T(W - 42, y + 84, "failures.md", 14, c["text"], 500, "end", bg=c["fill"], font=MONO))
    else:
      s.add(T(38, y + 32, "追記するファイル", 15, c["text"], 400, bg=c["fill"]), T(W - 56, y + 32, "SKILL.md", 14, c["text"], 500, "end", bg=c["fill"], font=MONO), chev(c, W - 42, y + 27),
          hair(c, 38, y + 52, W - 76),
          T(38, y + 84, "入れる位置", 15, c["text"], 400, bg=c["fill"]), T(W - 56, y + 84, "## 使い方 の後", 14, c["text"], 500, "end", bg=c["fill"]), chev(c, W - 42, y + 79))
    y += 126
    s.add(T(28, y, "次に Skillwright を開いたときに検査します。", 13, c["sec"], 400, bg=sh))
    s.add(home(c, W, H))
    return s.svg()


def seg2(c, x, y, w, a, b, first, bg):
    sw = w / 2
    on_x = x + 3 if first else x + sw + 3
    out = [f'<rect x="{x}" y="{y}" width="{w}" height="40" rx="20" fill="{c["fill"] if bg != c["fill"] else c["card"]}"/>',
           f'<rect x="{on_x:.1f}" y="{y+3}" width="{sw-6:.1f}" height="34" rx="17" fill="{c["pill"]}"/>']
    segbg = c["fill"] if bg != c["fill"] else c["card"]
    out.append(T(x + sw / 2, y + 26, a, 14, c["pill_ink"] if first else c["text"], 600, "middle", bg=c["pill"] if first else segbg))
    out.append(T(x + sw * 1.5, y + 26, b, 14, c["text"] if first else c["pill_ink"], 600, "middle", bg=segbg if first else c["pill"]))
    return "".join(out)


def score_card(x, y, w, lang):
    """Shareable 1200x630 card preview, always drawn in its own light theme."""
    k = LIGHT
    h = w * 630 / 1200
    sc = w / 370
    ja = lang == "ja"
    o = [f'<rect x="{x}" y="{y}" width="{w}" height="{h:.1f}" rx="18" fill="#FFFFFF" stroke="#E2E2E2"/>']
    o.append(T(x + 20 * sc, y + 30 * sc, "tea-timer", 13, "#0A0A0A", 600, bg="#FFFFFF", font=MONO))
    o.append(T(x + 20 * sc, y + 46 * sc, "SKILL.md", 11, "#6B6B6B", 400, bg="#FFFFFF", font=MONO))
    o.append(T(x + 18 * sc, y + 118 * sc, "6/7", 56, "#0A0A0A", 500, bg="#FFFFFF", font=DISP, ls=-2))
    o.append(T(x + 20 * sc, y + 146 * sc, "決まりに合格" if ja else "rules passed", 12, "#6B6B6B", 400, bg="#FFFFFF"))
    bx = x + 160 * sc
    labs = [("起動時" if ja else "Always", 62, 0.18), ("呼ばれたとき" if ja else "Triggered", 120, 0.36), ("必要なとき" if ja else "On demand", 240, 0.7)]
    for i, (lab, tok, f) in enumerate(labs):
        by = y + (70 + i * 30) * sc
        o.append(T(bx, by, lab, 11, "#6B6B6B", 400, bg="#FFFFFF"))
        o.append(f'<rect x="{bx:.1f}" y="{by+6:.1f}" width="{190*sc:.1f}" height="5" rx="2.5" fill="#ECECEC"/>')
        o.append(f'<rect x="{bx:.1f}" y="{by+6:.1f}" width="{190*sc*f:.1f}" height="5" rx="2.5" fill="#0A0A0A"/>')
        o.append(T(x + w - 18 * sc, by, (f"約{tok}" if ja else f"~{tok}"), 11, "#0A0A0A", 500, "end", bg="#FFFFFF", font=SANS if ja else MONO))
    o.append(T(x + w - 18 * sc, y + h - 14 * sc, "Skillwright", 11, "#0A0A0A", 700, "end", bg="#FFFFFF"))
    o.append(T(x + 20 * sc, y + h - 14 * sc, "決まり 2026.10.30" if ja else "rules 2026.10.30", 11, "#6B6B6B", 400, bg="#FFFFFF", font=SANS if ja else MONO))
    return "".join(o), h


def s23(c, lang="ja", badge=False):
    ja = lang == "ja"
    s = Screen(c)
    s.add(status(c, W), nav(c, W, "共有" if ja else "Share", "tea-timer", "back", None))
    y = 124
    s.add(seg2(c, 16, y, W - 32, "カード" if ja else "Card", "バッジ" if ja else "Badge", not badge, c["bg"]))
    y += 64
    if not badge:
        svg_card, ch = score_card(16, y, W - 32, lang)
        s.add(svg_card)
        y += ch + 24
        s.add(card(c, 16, y, W - 32, 104, r=24))
        s.add(T(34, y + 32, "見た目" if ja else "Appearance", 16, c["text"], 400, bg=c["card"]),
              T(W - 52, y + 32, ("ライト" if ja else "Light"), 14, c["sec"], 400, "end", bg=c["card"]),
              f'<path d="M{W-42} {y+24}l4 -4 4 4M{W-42} {y+31}l4 4 4 -4" fill="none" stroke="{c["sec"]}" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"/>',
              hair(c, 34, y + 52, W - 68),
              T(34, y + 82, "リポ名を出す" if ja else "Show repo name", 16, c["text"], 400, bg=c["card"]), toggle(c, W - 82, y + 62, True))
        y += 128
        s.add(T(24, y, "画像はこの iPhone の中で作ります。どこにも送りません。" if ja else "Made on this iPhone. Nothing is uploaded.", 13, c["sec"], 400))
        s.add(pill(c, 16, H - 102, W - 32, "共有" if ja else "Share"), home(c, W, H))
        return s.svg()
    # badge
    s.add(card(c, 16, y, W - 32, 120, r=24))
    bw1, bw2, bh = 104, 72, 28
    bx = (W - bw1 - bw2) / 2
    by = y + 46
    s.add(f'<rect x="{bx:.1f}" y="{by}" width="{bw1+bw2}" height="{bh}" rx="6" fill="#0A0A0A"/>',
          f'<path d="M{bx+bw1:.1f} {by}h{bw2-6}a6 6 0 0 1 6 6v{bh-12}a6 6 0 0 1 -6 6h-{bw2-6}z" fill="#ECECEC"/>',
          T(bx + bw1 / 2, by + 19, "Skillwright", 13, "#FFFFFF", 600, "middle", bg="#0A0A0A"),
          T(bx + bw1 + bw2 / 2, by + 19, "✓ 6/7", 13, "#0A0A0A", 600, "middle", bg="#ECECEC", font=MONO),
          T(W / 2, y + 102, "GitHub の main・a1b2c3d・10:42 に検査" if ja else "Checked on GitHub main · a1b2c3d · 10:42", 12, c["sec"], 400, "middle", bg=c["card"]))
    y += 144
    s.add(caption(c, 24, y, "README に貼る1行" if ja else "PASTE INTO README"))
    y += 10
    s.add(card(c, 16, y, W - 32, 96, fill=c["card"], r=18))
    snip = ["[![Skillwright](https://skillwright.", "seventh-well.com/badge/teapot-labs/", "tea-timer-skill/tea-timer.svg)](…)"]
    for i, ln in enumerate(snip):
        s.add(T(32, y + 28 + i * 22, ln, 12, c["text"], 400, bg=c["card"], font=MONO))
    y += 112
    s.add(card(c, 16, y, W - 32, 56, r=24), T(34, y + 34, "反映のとき README に入れる" if ja else "Add to README on publish", 16, c["text"], 400, bg=c["card"]), toggle(c, W - 82, y + 12.5, False))
    y += 80
    s.add(T(24, y, "公開リポだけ使えます。数字はサーバーで検査し直します。" if ja else "Public repos only. The server re-checks the score.", 13, c["sec"], 400))
    s.add(pill(c, 16, H - 102, W - 32, "1行をコピー" if ja else "Copy Markdown"), home(c, W, H))
    return s.svg()


def s24(c, lang="ja", done=False):
    ja = lang == "ja"
    s = Screen(c)
    s.add(status(c, W), nav(c, W, "声から作る" if ja else "Speak a Skill", None, "x", None))
    if not done:
        s.add(T(W / 2, 200, "0:42", 64, c["text"], 500, "middle", font=DISP, ls=-2),
              T(W / 2, 232, "録音中・最長 5:00" if ja else "Recording · up to 5:00", 13, c["sec"], 400, "middle"))
        import math as _m
        for i in range(36):
            hgt = 6 + 34 * abs(_m.sin(i * 0.55) * _m.cos(i * 0.17))
            s.add(f'<rect x="{39+i*9:.1f}" y="{290-hgt/2:.1f}" width="4" height="{hgt:.1f}" rx="2" fill="{c["text"] if i < 26 else c["hair"]}"/>')
        y = 334
        s.add(card(c, 16, y, W - 32, 236))
        s.add(caption(c, 36, y + 32, "書き起こし" if ja else "TRANSCRIPT", c["card"]))
        lines = (["お茶の淹れ方を聞かれたときに使うスキル。", "まず茶葉の種類を聞いて、紅茶なら95度で", "3分、緑茶なら70度で1分。熱すぎたら", "30秒待ってから淹れ直すように言う。"]
                 if ja else ["A skill for when someone asks how to", "brew tea. First ask which tea. Black tea", "is 95°C for 3 minutes, green tea 70°C", "for 1 minute. If it is too hot, wait…"])
        for i, ln in enumerate(lines):
            s.add(T(36, y + 70 + i * 28, ln, 16, c["text"] if i < 3 else c["sec"], 400, bg=c["card"]))
        s.add(f'<rect x="{36+tw(lines[-1],16)+3:.1f}" y="{y+70+3*28-16}" width="2" height="20" fill="{c["text"]}"/>')
        lang_lab = "日本語" if ja else "English"
        lw_ = tw(lang_lab, 13)
        s.add(f'<rect x="28" y="{y+194}" width="{lw_+40:.1f}" height="30" rx="15" fill="none" stroke="{c["btn_line"]}"/>',
              T(42, y + 214, lang_lab, 13, c["sec"], 500, bg=c["card"]),
              f'<path d="M{46+lw_:.1f} {y+205}l3 -3 3 3M{46+lw_:.1f} {y+212}l3 3 3 -3" fill="none" stroke="{c["sec"]}" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round"/>',
              T(lw_ + 82, y + 214, "音声は保存しません" if ja else "Audio is not saved", 12, c["sec"], 400, bg=c["card"]))
        cx, cy = W / 2, H - 130
        s.add(f'<circle cx="{cx}" cy="{cy}" r="38" fill="{c["pill"]}"/><rect x="{cx-11}" y="{cy-11}" width="22" height="22" rx="4" fill="{c["pill_ink"]}"/>',
              T(cx, cy + 66, "止めて作る" if ja else "Stop and Build", 14, c["text"], 600, "middle"))
        s.add(home(c, W, H))
        return s.svg()
    y = 132
    s.add(T(24, y + 20, "できました" if ja else "Draft ready", 28, c["text"], 700),
          T(24, y + 46, "内蔵 AI が話した内容を項目に分けました。" if ja else "The on-device model sorted what you said.", 13, c["sec"], 400),
          T(24, y + 64, "確かめてから使ってください。" if ja else "Check it before you use it.", 13, c["sec"], 400))
    rl = LINES[lang][:9] + ([("1. 茶葉の種類を聞く", "t"), ("2. 紅茶は95度で3分、緑茶は70度で1分", "t"), ("3. 熱すぎたら30秒待って淹れ直す", "t")] if ja else
                            [("1. Ask which tea", "t"), ("2. Black 95°C 3 min, green 70°C 1 min", "t"), ("3. Too hot? Wait 30 s, brew again", "t")])
    s.add(editor_card(c, 16, y + 82, W - 32, 364, lang, show=12, status_line=False, lines=rl))
    ry = y + 82 + 364 - 40
    s.add(ok_dot(40, ry + 10, c["okc"], c["card"], 6), T(56, ry + 15, "7/7・決まりに合格" if ja else "7/7 · all rules passed", 13, c["sec"], 400, bg=c["card"]))
    sy_ = y + 82 + 364 + 12
    s.add(card(c, 16, sy_, W - 32, 44, r=22), T(34, sy_ + 28, "保存先" if ja else "Save to", 15, c["text"], 400, bg=c["card"]),
          T(W - 52, sy_ + 28, "teapot-labs/tea-timer-skill", 13, c["sec"], 400, "end", bg=c["card"], font=MONO), chev(c, W - 38, sy_ + 22))
    s.add(T(W / 2, sy_ + 76, "書き起こしを見る" if ja else "View Transcript", 15, c["text"], 500, "middle"),
          f'<rect x="{W/2-tw("書き起こしを見る" if ja else "View Transcript",15)/2:.1f}" y="{sy_+80}" width="{tw("書き起こしを見る" if ja else "View Transcript",15):.1f}" height="1" fill="{c["text"]}"/>')
    s.add(pill(c, 16, H - 166, W - 32, "エディタで開く" if ja else "Open in Editor"),
          pill(c, 16, H - 102, W - 32, "やり直す" if ja else "Start Over", inverse=True), home(c, W, H))
    return s.svg()


files = {}
for nm, c in (("light", LIGHT), ("dark", DARK)):
    files[f"iphone-S-01-{nm}"] = s01(c)
    files[f"iphone-S-01-empty-{nm}"] = s01(c, True)
    files[f"iphone-S-02-{nm}"] = s02(c)
    files[f"iphone-S-02-loading-{nm}"] = s02(c, mode="loading")
    files[f"iphone-S-02-ax5-{nm}"] = s02(c, mode="ax5")
    files[f"iphone-S-03-{nm}"] = s03(c)
    files[f"iphone-S-04-{nm}"] = s04(c)
    files[f"iphone-S-05-{nm}"] = s05(c)
    files[f"iphone-S-06-{nm}"] = s06(c)
    files[f"iphone-S-06-error-{nm}"] = s06(c, True)
    files[f"iphone-S-07-{nm}"] = s07(c)
    files[f"iphone-S-08-{nm}"] = s08(c)
    files[f"iphone-S-09-{nm}"] = s09(c)
    files[f"iphone-S-10-{nm}"] = s10(c)
    files[f"iphone-S-10-scrolled-{nm}"] = s10(c, True)
    files[f"iphone-S-02-free-{nm}"] = s02(c, mode="free")
    files[f"iphone-S-17-keyboard-{nm}"] = s17(c, kb=True)
    files[f"iphone-S-06-pr-{nm}"] = s06_pr(c)
    files[f"iphone-S-06-pr-en-{nm}"] = s06_pr(c, "en")
    files[f"iphone-S-21-{nm}"] = s21(c)
    files[f"iphone-S-22-{nm}"] = s22(c)
    files[f"iphone-S-22-new-{nm}"] = s22(c, True)
    files[f"iphone-S-23-{nm}"] = s23(c)
    files[f"iphone-S-23-en-{nm}"] = s23(c, "en")
    files[f"iphone-S-23-badge-{nm}"] = s23(c, badge=True)
    files[f"iphone-S-24-{nm}"] = s24(c)
    files[f"iphone-S-24-en-{nm}"] = s24(c, "en")
    files[f"iphone-S-24-result-{nm}"] = s24(c, done=True)
    files[f"iphone-S-24-result-en-{nm}"] = s24(c, "en", done=True)
    files[f"iphone-S-11-{nm}"] = s11(c)
    files[f"iphone-S-17-{nm}"] = s17(c)
    files[f"iphone-S-18-{nm}"] = s18(c)
    files[f"iphone-S-19-{nm}"] = s19(c)
    files[f"iphone-S-20-{nm}"] = s20(c)
    for sid, fn in (("S-02", s02), ("S-03", s03), ("S-05", s05), ("S-17", s17), ("S-19", s19)):
        files[f"iphone-{sid}-en-{nm}"] = fn(c, "en")
    files[f"iphone-duo-outer-S-02-{nm}"] = duo_outer_list(c)
    files[f"iphone-duo-outer-S-03-{nm}"] = duo_outer_editor(c)
    files[f"iphone-duo-inner-landscape-S-02-{nm}"] = duo_inner(c)
    files[f"iphone-duo-inner-landscape-S-02-folded-{nm}"] = duo_inner(c, True)
    files[f"ipad-landscape-S-02-{nm}"] = ipad(c)
    files[f"ipad-narrow-S-02-{nm}"] = ipad(c, True)
for n, svgtxt in files.items():
    (OUT / f"{n}.svg").write_text(svgtxt, encoding="utf-8")
print("wrote", len(files))
