#!/usr/bin/env python3
"""Extract original Thor's Hammer header/footer and legacy fallback atlases.

No generated art or gameplay changes. Sources remain unmodified. Native*
exports keep source dimensions/pivots; older repacks remain compatible fallback.
Every operation is recorded; the port retains a shorter world viewport.
"""
import argparse
import hashlib
import json
import struct
from pathlib import Path

from PIL import Image

import gunbound_xfs as xfs
from decode_gunbound_img import frames

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets/xfs/hud'
ARCHIVE_SHA = 'a52f9f468bb1c6d772bfa0431ec436b0c515a7cebc490c6970e55c7dffb20f08'


def sha(data):
    return hashlib.sha256(data).hexdigest()


def build(archive, output=OUT):
    if sha(archive.read_bytes()) != ARCHIVE_SHA:
        raise ValueError('graphics.xfs differs from the pinned Thor\'s Hammer build')
    toc = {row['name']: row for row in xfs.read_toc(archive)}
    decoded = {}
    entries = {}
    files = {}
    operations = []

    def source(name, index=0):
        if name not in decoded:
            raw = xfs.read_entry(archive, toc[name])
            if name.endswith('.xtf'):
                width, height, kind = struct.unpack_from('<IIB', raw)
                if kind != 1 or len(raw) != 9 + width * height * 2:
                    raise ValueError('Unsupported XTF format: ' + name)
                image = Image.new('RGBA', (width, height))
                image.putdata([xfs._argb4444(value) for value, in struct.iter_unpack('<H', raw[9:])])
                decoded[name] = [(image, (0, 0))]
            else:
                decoded[name] = frames(raw)
                # Native HUD dispatch (4eb922..4eb937): type1 uses RLE;
                # type0 submits complete RGB565 scanlines via4ebaf0/4eba80.
                # Black is opaque here. Keep the shared sprite decoder's
                # historical color-key default unchanged for other consumers.
                offset = 8
                for image, _ in decoded[name]:
                    header = struct.unpack_from('<HH9i', raw, offset)
                    if name == 'play_back.img' and header[0] & 255 == 0:
                        image.putalpha(255)
                    offset += 40 + header[-1]
            entries[name] = {'entry_sha256': sha(raw), 'frames': len(decoded[name]),
                             'sizes': [list(im.size) for im, _ in decoded[name]],
                             'pivots': [list(pivot) for _, pivot in decoded[name]]}
        return decoded[name][index][0]

    def layer(canvas, name, frame, dest, crop=None, mode='stretch', rotate=0, rgba_copy=False):
        image = source(name, frame)
        if crop is not None:
            if crop[0] < 0 or crop[1] < 0 or crop[2] > image.width or crop[3] > image.height:
                raise ValueError((name, frame, crop, image.size))
            image = image.crop(crop)
        if rotate:
            image = image.rotate(rotate, expand=True)
        x, y, w, h = dest
        if mode == 'fit':
            factor = min(w / image.width, h / image.height)
            size = (max(1, round(image.width * factor)), max(1, round(image.height * factor)))
            image = image.resize(size, Image.Resampling.NEAREST)
            x += (w - size[0]) // 2
            y += (h - size[1]) // 2
        else:
            image = image.resize((w, h), Image.Resampling.NEAREST)
        if rgba_copy:
            canvas.paste(image,(x,y))
        else:
            canvas.alpha_composite(image, (x, y))
        operations.append({'entry': name, 'frame': frame, 'crop': crop, 'destination': list(dest),
                           'mode': mode, 'rotate': rotate, 'rgba_copy':rgba_copy})

    def save(name, size, draw):
        nonlocal operations
        operations = []
        canvas = Image.new('RGBA', size)
        draw(canvas)
        path = output / (Path(name).stem + '.png')
        output.mkdir(parents=True, exist_ok=True)
        if not path.exists() or Image.open(path).convert('RGBA').tobytes() != canvas.tobytes():
            canvas.save(path)
        # Godot's alpha-border repair rewrites RGB on transparent pixels.
        # Preserve exact decoded RGBA and any existing UID/import settings.
        config = path.with_suffix('.png.import')
        if config.exists():
            text = config.read_text().replace('process/fix_alpha_border=true', 'process/fix_alpha_border=false')
            config.write_text(text)
        else:
            config.write_text('[remap]\nimporter="texture"\ntype="CompressedTexture2D"\n\n[params]\ncompress/mode=0\nmipmaps/generate=false\nprocess/fix_alpha_border=false\n')
        files[name] = {'file': 'res://assets/xfs/hud/' + path.name, 'size': list(size),
                       'sha256': sha(path.read_bytes()), 'rgba_sha256': sha(canvas.tobytes()),
                       'composition': 'adapted to preserved UI slots', 'operations': operations}

    # Blue native interface skin. Empty native panels supply the background;
    # the native charge frame, item tray and white readout are moved to the
    # existing port slots, without moving their input rectangles.
    def action(canvas):
        layer(canvas, 'play_back.img', 1, (0, 0, 800, 85), (170, 4, 230, 40))
        layer(canvas, 'play_back.img', 0, (170, 0, 98, 34), (140, 0, 320, 40))
        layer(canvas, 'play_back.img', 0, (273, 0, 241, 38), (500, 0, 756, 40))
        layer(canvas, 'play_back.img', 0, (518, 0, 127, 34), (140, 0, 320, 40))
        layer(canvas, 'play_back.img', 1, (238, 46, 406, 27), (238, 0, 654, 43))
        layer(canvas, 'play_back.img', 6, (238, 74, 406, 11), (66, 0, 485, 26))
    save('ActionBar.png', (800, 85), action)
    for name, frame, size in [('StrenghtMetter.png', 2, (400, 19)), ('MovementMetter.png', 8, (400, 9)),
                              ('ShotStrenghtSelector.png', 3, (19, 23)), ('PreviousShootingStrenghtPointer.png', 4, (9, 6))]:
        save(name, size, lambda c, f=frame, s=size: layer(c, 'play_back.img', f, (0, 0, *s), mode='fit' if f in (3, 4) else 'stretch'))
    def shot_buttons(canvas):
        for shot, entry in enumerate(['b_play_weapon1.img', 'b_play_weapon2.img', 'b_play_weapon3.img']):
            for state, frame in enumerate(range(5)):
                layer(canvas, entry, frame, ((shot * 5 + state) * 37, 0, 37, 37), mode='fit')
    save('ShotSelector.png', (555, 37), shot_buttons)
    for name, entry in [('Options.png', 'b_play_option.img'), ('SkipTurn.png', 'b_play_skip.img')]:
        save(name, (240, 23), lambda c, e=entry: [layer(c, e, i, (i * 60, 0, 60, 23), mode='fit') for i in range(4)])

    # Decimal strips from the original numberfont IMG. Slots retain the old
    # advances, including unused minus slots; no missing symbol is invented.
    fonts = [('FontCurrentAngle.png', 142, (15, 15), 193, False),
             ('FontPreviousAngle.png', 183, (10, 8), 193, False),
             ('FontGold.png', 227, (15, 15), 193, False),
             ('FontDelay.png', 279, (8, 9), 193, False),
             ('FontDamage.png', 173, (14, 19), 172, True),
             ('FontCrosshairAngle.png', 204, (10, 12), 172, False),
             ('FontWindCompass.png', 248, (13, 19), None, False),
             ('FontBlueTurnCounter.png', 152, (13, 17), None, False),
             ('FontRedTurnCounter.png', 173, (13, 17), None, False)]
    for name, base, cell, minus, minus_first in fonts:
        count = 11 if minus is not None or name == 'FontCrosshairAngle.png' else (8 if 'TurnCounter' in name else 10)
        def numbers(canvas, b=base, s=cell, m=minus, mf=minus_first, n=count):
            for i in range(n):
                frame = m if (mf and i == 0) or (not mf and i == 10) else b + i - (1 if mf else 0)
                layer(canvas, 'numberfont.img', frame, (i * s[0], 0, *s), mode='fit')
        save(name, (cell[0] * count, cell[1] * (2 if name == 'FontCrosshairAngle.png' else 1)), numbers)
    save('FontTurnTimer.png', (330, 164), lambda c: [layer(c, 'numberfont.img', 75+i, ((i % 5)*66, (i//5)*82, 66, 82), mode='fit') for i in range(10)])

    # Seven native weather categories only. Extra categories retain the
    # documented 1x legacy fallback in HudArt; native categories never use it.
    save('WeatherIcons.png', (330, 44), lambda c: [layer(c, 'playmode.img', frame, (i*22, row*22, 22, 22), mode='fit') for i,frame in enumerate([165,166,167,168,169,170,171]) for row in range(2)])
    save('CrosshairFrame.png', (83, 83), lambda c: layer(c, 'playinterface1.xtf', 0, (0, 0, 83, 83), (166,166,250,250), mode='fit'))
    save('CrosshairPointer.png', (5, 27), lambda c: layer(c, 'playinterface1.xtf', 0, (0, 0, 5, 27), (62,156,101,164), mode='fit', rotate=90))

    # Native configuration shell: retain its header, borders and blank panel;
    # built-in labels are covered by another empty patch from the same frame,
    # because the existing options/control coordinates remain unchanged.
    def options(canvas):
        layer(canvas, 'play_option.img', 0, (0,0,323,328))
        layer(canvas, 'play_option.img', 0, (13,33,297,268), (42,343,236,348))
    save('OptionsBackground.png', (323,328), options)
    save('OptionsRadioButton.png', (23,12), lambda c: (layer(c,'play_option.img',0,(0,0,12,12),(21,69,33,81)), layer(c,'play_option.img',1,(12,0,11,12))))
    save('OptionsBarFrame.bmp', (147,5), lambda c: layer(c,'play_option.img',0,(0,0,147,5),(37,125,238,130)))
    save('OptionsBar.png', (145,3), lambda c: layer(c,'play_option.img',0,(0,0,145,3),(37,126,238,129)))
    save('OptionsBarIntensityPointer.png', (9,6), lambda c: layer(c,'play_back.img',3,(0,0,9,6),mode='fit'))
    # The check mark exists in the configuration header. There is no matching
    # 20x25 four-state accept icon; repeat the native mark without inventing faces.
    save('PopupAccept.png', (80,25), lambda c: [layer(c,'play_option.img',0,(i*20,0,20,25),(8,4,39,32),mode='fit') for i in range(4)])
    # REQ-27/48 correction: unscaled native bands, independent of the old
    # recomposition above (retained only as compatibility fallback).
    # Frame0 has pivot(-20,-12) and a loading spinner below the visible band.
    save('NativeHeader.png', (800,40), lambda c: layer(c,'play_back.img',0,(0,0,800,40),(20,12,820,52)))
    native_frames = [('NativeFooter.png',1),('NativeStrength.png',2),
                     ('NativeSelector.png',3),('NativePreviousPower.png',4),
                     ('NativeMoveFrame.png',5),('NativeMoveExpanded.png',6),('NativeMovement.png',7),
                     ('NativeMoveFill.png',8),('NativeSlice.png',9),('NativeDrag.png',11),
                     ('NativeGoldPanel.png',178),('NativeLifePanel.png',172),('NativeJewelPanel.png',179)]
    for name, frame in native_frames:
        w,h = source('play_back.img',frame).size
        save(name,(w,h),lambda c,f=frame,w=w,h=h:layer(c,'play_back.img',f,(0,0,w,h)))
    for name,entry in [('NativeOptions.png','b_play_option.img'),('NativeSkip.png','b_play_skip.img'),
                       ('NativeShot1.png','b_play_weapon1.img'),('NativeShot2.png','b_play_weapon2.img'),('NativeShot3.png','b_play_weapon3.img')]:
        w,h=source(entry).size
        count=len(decoded[entry])
        save(name,(w*count,h),lambda c,e=entry,w=w,h=h,n=count:[layer(c,e,i,(i*w,0,w,h)) for i in range(n)])
    save('NativeWeather.png',(217,27),lambda c:[layer(c,'play_back.img',f,(i*31,0,31,27)) for i,f in enumerate([85,45,65,25,105,125,145])])
    # The live header consumer uses resource500 = numfont, not numberfont.
    # Preserve per-frame IMG pivots (notably the narrow digit1).
    for name,base,cell in [('NativeGoldDigits.png',135,(19,24)),('NativeAngleDigits.png',179,(8,10))]:
        def native_digits(c,b=base,cell=cell):
            for digit in range(10):
                source('numfont.img',b+digit)
                image,pivot=decoded['numfont.img'][b+digit]
                dest=(digit*cell[0]+pivot[0],pivot[1],image.width,image.height)
                layer(c,'numfont.img',b+digit,dest)
        save(name,(cell[0]*10,cell[1]),native_digits)
    save('NativeAngleMinus.png',(5,2),lambda c:layer(c,'numfont.img',178,(0,0,5,2)))
    # Original action clock and wind source, confirmed in406990/4caed0.
    for name,base,cell in [('NativeTimerDigits.png',146,(28,45)),('NativeTimerFraction.png',157,(17,28)),('NativeWindDigits.png',167,(10,17))]:
        def native_fields(c,b=base,cell=cell):
            for digit in range(10):
                source('numfont.img',b+digit)
                im,pv=decoded['numfont.img'][b+digit]
                layer(c,'numfont.img',b+digit,(digit*cell[0]+pv[0],pv[1],im.width,im.height))
        save(name,(cell[0]*10,cell[1]),native_fields)
    for name,frame in [('NativeTimerDot.png',156),('NativeWindLabel.png',177)]:
        w,h=source('numfont.img',frame).size
        save(name,(w,h),lambda c,f=frame,w=w,h=h:layer(c,'numfont.img',f,(0,0,w,h)))
    save('NativeWindTexture.png',(256,256),lambda c:layer(c,'moon.xtf',0,(0,0,256,256),rgba_copy=True))
    files['NativeGoldPanel.png']['purpose']='Solo/training Gold header; no fictitious team scores'
    files['NativeLifePanel.png']['purpose']='Score life counter; extracted, inactive in Solo'
    files['NativeJewelPanel.png']['purpose']='Jewel team score; extracted, inactive in Solo'
    gaps = ['CompassBackground.png','CompassForeground.png','CompassWhiteArrow.png','CompassYellowArrow.png','CompassRedArrow.png',
            'HealthBarFrame.png','TurnCounterBalloon.png','SelectedPlayerTurnBG.png','WeatherFrame.png','Crosshair*Ally.png','Crosshair*Enemy.png']
    catalog = {'version':1, 'archive_sha256':ARCHIVE_SHA, 'archive':'TestClient/graphics.xfs',
               'repository':'https://github.com/jglim/gunbound-launcher', 'commit':'2bc43c490ba727d6fce1a5b47ed9dc577d0f9cc1',
               'scope':'native two-band HUD; old repacks retained as compatibility fallback; rules preserved',
               'pixel_contract':'play_back RGB565 type0 is opaque, including black; other resources retain their own decoder contract',
               'resampling':'NEAREST; fit preserves aspect, stretch only panels and meter fills',
               'entries':entries,'files':files,'gaps':gaps,
               'weather_gaps':['weakness','mirror','random'],
               'limits':['Accept repeats the native configuration header check mark',
                         'Weather inactive row repeats native art; no grayscale art invented']}
    (output/'catalog.json').write_text(json.dumps(catalog,indent=2)+'\n')
    print(f'HUD: {len(files)} atlases from {len(entries)} client entries, {len(gaps)} declared fallback families')
    return catalog

if __name__ == '__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--graphics',type=Path,default=ROOT/'.tools/gunbound-client/graphics.xfs')
    build(parser.parse_args().graphics)
