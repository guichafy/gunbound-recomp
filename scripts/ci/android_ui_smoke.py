#!/usr/bin/env python3
"""Exercise exact APK bytes through adb on a dedicated disposable emulator.

No run-as, exported argument bridge, normal-device cleanup, or private profile
access. UI transitions are checked by OCR on captured rendered frames. Missing
OCR labels fail closed; screenshots/logs remain for review. adb input cannot
prove multitouch, audio or physical ARM64 acceptance.
"""
from __future__ import annotations
import argparse
import csv
import io
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import time
import sys
import struct
import xml.etree.ElementTree as ET

sys.path.insert(0,str(Path(__file__).resolve().parent))
from android_package import ERRORS, diagnostic_report

OPTIONS_POPUP_PATTERN = r'(?s)(?=.*(?:Configuration|SFX|Sound|Aiming|Scroll))(?=.*\bOK\b)'
CAMERA_ON_PATTERN = r'CAMERA\s+ON|C[ÂA]MERA\s+ATIVA'
SAVE_PATTERN = r'Save changes|Salvar altera[çc][õo]es'
RESUME_PATTERN = r'Resume|Retomar|Continuar|Continue'
CONTROL_OCR_CACHE = {}

def ocr_output(args):
    # Software GL shares the runner CPUs. Tesseract's four OpenMP workers
    # otherwise compete with the emulator and can make a small UI read stall.
    return subprocess.check_output(args,text=True,stderr=subprocess.DEVNULL,timeout=30,
                                   env=os.environ|{'OMP_THREAD_LIMIT':'1'})


class CaptureTimeout(ValueError):
    pass


def native_targets(path: Path,pattern: str):
    from android_native_ui import LABELS,targets
    if pattern==OPTIONS_POPUP_PATTERN:pattern=r'OK'
    if not any(re.fullmatch(pattern,label,re.I) for label in LABELS):return []
    from PIL import Image
    with Image.open(path) as pixels:return targets(pixels,pattern)


def bright_button_targets(path: Path,pattern: str):
    if pattern not in (RESUME_PATTERN,SAVE_PATTERN):return []
    from PIL import Image,ImageOps
    from android_native_ui import bright_panels
    found=[]
    with Image.open(path) as pixels:
        for index,region in enumerate(bright_panels(pixels)):
            x,y,w,h=[region[key] for key in ('left','top','width','height')]
            image=ImageOps.grayscale(pixels.crop((x,y,x+w,y+h))).resize((w*3,h*3),Image.Resampling.BICUBIC)
            image=ImageOps.expand(image.point(lambda value:255 if value>80 else 0),border=12,fill=255)
            crop=path.with_stem(path.stem+'-contrast'+str(index));image.save(crop)
            tsv=ocr_output([os.environ.get('GUNBOUND_OCR','tesseract'),str(crop),'stdout','--psm','7','tsv'])
            crop.with_suffix('.tsv').write_text(tsv)
            try:target=text_target(tsv,pattern)
            except ValueError as error:
                if 'missing' not in str(error):raise
                continue
            target['left']-=12;target['top']-=12
            target=unscale_target(target,3)
            target['left']+=x;target['top']+=y
            found.append(target)
    return found


def control_targets(path: Path,pattern: str,include_camera_state=False):
    if not any(label in pattern.upper() for label in ('CAMERA','PAUSE','WEAPON')):return []
    from PIL import Image,ImageOps
    from android_native_ui import control_regions
    found=[]
    with Image.open(path) as pixels:
        for index,region in enumerate(control_regions(pixels)):
            x,y,w,h=[region[key] for key in ('left','top','width','height')]
            margin=max(2,round(min(w,h)*.06));x+=margin;y+=margin;w-=margin*2;h-=margin*2
            image=ImageOps.grayscale(pixels.crop((x,y,x+w,y+h))).resize((w*4,h*4),Image.Resampling.BICUBIC)
            image=ImageOps.expand(ImageOps.invert(image.point(lambda value:255 if value>140 else 0)),border=20,fill=255)
            crop=path.with_stem(path.stem+'-control'+str(index));image.save(crop)
            key=hashlib.sha256(image.tobytes()+str(image.size).encode()).hexdigest()
            if key not in CONTROL_OCR_CACHE:
                CONTROL_OCR_CACHE[key]=ocr_output([os.environ.get('GUNBOUND_OCR','tesseract'),str(crop),'stdout','--psm','6','tsv'])
                if len(CONTROL_OCR_CACHE)>128:del CONTROL_OCR_CACHE[next(iter(CONTROL_OCR_CACHE))]
            tsv=CONTROL_OCR_CACHE[key];crop.with_suffix('.tsv').write_text(tsv)
            try:
                if 'CAMERA' in pattern.upper():
                    try:target=text_target(tsv,CAMERA_ON_PATTERN)
                    except ValueError as error:
                        if 'missing' not in str(error):raise
                        target=text_target(tsv,pattern)
                else:target=text_target(tsv,pattern)
                matches=re.search if include_camera_state else re.fullmatch
                if not matches(pattern,target['text'],re.I):continue
            except ValueError as error:
                if 'missing' not in str(error):raise
                continue
            target['left']-=20;target['top']-=20;target=unscale_target(target,4)
            target['left']+=x;target['top']+=y;found.append(target)
    return found


def enhanced_ocr(path: Path,tsv=False):
    from PIL import Image,ImageOps
    enhanced=path.with_stem(path.stem+'-ocr3x')
    with Image.open(path) as pixels:
        ImageOps.grayscale(pixels).resize((pixels.width*3,pixels.height*3),Image.Resampling.BICUBIC).save(enhanced)
    args=[os.environ.get('GUNBOUND_OCR','tesseract'),str(enhanced),'stdout','--psm','11']
    if tsv:args.append('tsv')
    result=ocr_output(args)
    enhanced.with_suffix('.tsv' if tsv else '.txt').write_text(result)
    return result


def unscale_target(target: dict,scale: int):
    left=target['left']//scale;top=target['top']//scale
    right=(target['left']+target['width']+scale-1)//scale
    bottom=(target['top']+target['height']+scale-1)//scale
    return target|dict(left=left,top=top,width=right-left,height=bottom-top)


def legacy_package_uid(dump: str,app: str) -> str:
    # Android7 dumpsys package uses a per-package block; never accept a UID
    # from a neighbouring package or the later shared-user sections.
    blocks=re.findall(r'(?ms)^  Package \['+re.escape(app)+r'\] \([^\r\n]+\):\r?\n(.*?)(?=^(?:\S| {1,2}\S)|\Z)',dump)
    matches=re.findall(r'(?m)^\s+userId=(\d+)\s*$',blocks[0]) if len(blocks)==1 else []
    if len(matches)!=1:raise ValueError('Cannot resolve exact Android7 application UID')
    return matches[0]


def legacy_uid_logs(logs: str,uid: str) -> str:
    # AOSP Android7 threadtime+uid is date,time,UID,PID,TID,priority,tag.
    # Native account UIDs can be names; application UIDs are numeric.
    result=[]
    for line in logs.splitlines():
        if not line.strip() or line.startswith('---------'):continue
        match=re.match(r'^\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d+\s+(\S+)\s+\d+\s+\d+\s+[VDIWEFS]\s',line)
        if not match:raise ValueError('Android7 logcat is missing the expected UID column')
        if match[1]==uid:result.append(line)
    return '\n'.join(result)+'\n' if result else ''


def validate_emulator(serial: str, qemu: str, avd: str):
    if not re.fullmatch(r'emulator-\d+',serial) or qemu.strip()!='1' or not (avd.strip().startswith('gunbound-ci-') or avd.strip() == 'gunbound_android_v1'):
        raise ValueError('Only a dedicated Gunbound test emulator may be modified')


def point(x: float,y: float,size: tuple[int,int],canvas=(1280,800)) -> tuple[int,int]:
    width,height=size
    scale=min(width/canvas[0],height/canvas[1])
    return round((width-canvas[0]*scale)/2+x*scale),round((height-canvas[1]*scale)/2+y*scale)


def png_size(payload: bytes) -> tuple[int,int]:
    if len(payload)<24 or payload[:8]!=b'\x89PNG\r\n\x1a\n' or payload[12:16]!=b'IHDR':
        raise ValueError('Invalid Android screenshot PNG')
    width,height=struct.unpack('>II',payload[16:24])
    if not width or not height:
        raise ValueError('Empty Android screenshot')
    return width,height


def parse_tsv(payload: str) -> list[dict]:
    reader=csv.DictReader(io.StringIO(payload),delimiter='\t')
    required={'level','page_num','block_num','par_num','line_num','word_num','left','top','width','height','conf','text'}
    if not reader.fieldnames or not required.issubset(reader.fieldnames):
        raise ValueError('Invalid OCR TSV header')
    words=[]
    for row in reader:
        try:
            if int(row['level'])!=5 or not row['text'].strip() or float(row['conf'])<0:
                continue
            item={key:int(row[key]) for key in ('left','top','width','height')}
            item.update(text=row['text'].strip(),line=tuple(row[key] for key in ('page_num','block_num','par_num','line_num')))
            if min(item['left'],item['top'])<0 or min(item['width'],item['height'])<=0:
                raise ValueError('Invalid OCR TSV rectangle')
            words.append(item)
        except (KeyError,TypeError,ValueError) as error:
            raise ValueError('Invalid OCR TSV row') from error
    return words


def text_target(payload: str, pattern: str) -> dict:
    lines={}
    for word in parse_tsv(payload):
        lines.setdefault(word['line'],[]).append(word)
    targets={}
    spans=[]
    for words in lines.values():
        words.sort(key=lambda word:word['left'])
        for start in range(len(words)):
            for end in range(start+1,min(start+9,len(words))+1):
                span=words[start:end]
                text=' '.join(word['text'] for word in span)
                left=min(word['left'] for word in span);top=min(word['top'] for word in span)
                right=max(word['left']+word['width'] for word in span)
                bottom=max(word['top']+word['height'] for word in span)
                box=(left,top,right-left,bottom-top)
                candidate=dict(left=left,top=top,width=right-left,height=bottom-top,text=text)
                spans.append(candidate)
                if re.fullmatch(pattern,text,re.I):targets[box]=candidate
    # A 48dp button can wrap its label (CAMERA / ON). Join only close,
    # vertically stacked text with substantial horizontal overlap. A distant
    # ON or another button must never manufacture the requested state.
    for first in spans:
        for second in spans:
            gap=second['top']-first['top']-first['height']
            overlap=min(first['left']+first['width'],second['left']+second['width'])-max(first['left'],second['left'])
            if not (0<=gap<=max(first['height'],second['height'])*1.25 and overlap>=min(first['width'],second['width'])*0.7):continue
            text=first['text']+' '+second['text']
            if not re.fullmatch(pattern,text,re.I):continue
            left=min(first['left'],second['left']);top=first['top']
            right=max(first['left']+first['width'],second['left']+second['width'])
            bottom=second['top']+second['height']
            targets[(left,top,right-left,bottom-top)]=dict(left=left,top=top,width=right-left,height=bottom-top,text=text)
    if len(targets)!=1:
        raise ValueError(f'OCR target {pattern!r} is '+('missing' if not targets else 'ambiguous'))
    return next(iter(targets.values()))


def system_tip_visible(text: str) -> bool:
    return bool(re.search(r'Viewing\s+full\s+screen',text,re.I)
                and re.search(r'To\s+exit,?\s+swipe\s+down\s+from\s+the\s+top\s+of\s+your\s+screen',text,re.I))


def system_tip_target(xml: str) -> dict | None:
    nodes=[n for n in ET.fromstring(xml).iter('node') if n.get('package')=='com.android.systemui']
    if not any(n.get('text')=='Viewing full screen' for n in nodes):return None
    buttons=[n for n in nodes if n.get('text')=='Got it' and n.get('clickable')=='true' and n.get('enabled')=='true']
    if len(buttons)!=1:raise ValueError('System onboarding button missing or ambiguous')
    match=re.fullmatch(r'\[(\d+),(\d+)\]\[(\d+),(\d+)\]',buttons[0].get('bounds',''))
    if not match:raise ValueError('Invalid system onboarding bounds')
    left,top,right,bottom=map(int,match.groups())
    if right<=left or bottom<=top:raise ValueError('Invalid system onboarding bounds')
    return dict(left=left,top=top,width=right-left,height=bottom-top,text='Got it')


def keyboard_visible(dump: str) -> bool:
    # InputMethodService may retain mIsInputViewShown=true after its window is
    # hidden. Prefer the active InputMethodManager/UserState mInputShown flag.
    states=re.findall(r'\bmInputShown\s*=\s*(true|false)\b',dump,re.I)
    if not states:
        states=re.findall(r'\b(?:mIsInputViewShown|isInputViewShown|inputShown)\s*=\s*(true|false)\b',dump,re.I)
    states={state.lower() for state in states}
    if len(states)!=1:
        raise ValueError('Cannot determine unambiguous Android IME visibility')
    return states=={'true'}


class Device:
    def __init__(self,adb,serial,output):
        if not re.fullmatch(r'emulator-\d+',serial):
            raise ValueError('Only emulator-* serials may be queried')
        self.adb=adb;self.serial=serial;self.output=output
        self.run('wait-for-device')
        output.mkdir(parents=True,exist_ok=True)
        validate_emulator(serial,self.run('shell','getprop','ro.kernel.qemu'),self.run('emu','avd','name').splitlines()[0])
        self.size=png_size(self.run('exec-out','screencap','-p',raw=True))
        self.observations=[]
        self.log_pid=None
        self.actions_attempted=[]

    def run(self,*args,raw=False):
        try:
            return subprocess.check_output([self.adb,'-s',self.serial,*args],timeout=120,text=not raw,stderr=subprocess.STDOUT)
        except subprocess.CalledProcessError as error:
            output=error.output or ''
            if isinstance(output,bytes):
                output=output.decode('utf-8',errors='replace')
            # Never retry input: a failed transport may still have delivered
            # the event, and a second Back could navigate twice.
            raise RuntimeError(f'adb {self.serial} failed ({error.returncode}):\n{output[-4000:]}') from None

    def tap(self,x,y,canvas=(1280,800)):
        if self.size[0]<self.size[1]:
            raise ValueError('Cannot tap Android UI before landscape render')
        x,y=point(x,y,self.size,canvas)
        self.run('shell','input','tap',str(x),str(y))

    def capture(self,label,pattern=None,timeout=30,absent=None):
        deadline=time.monotonic()+timeout
        path=self.output/(label+'.png')
        while True:
            screenshot=self.run('exec-out','screencap','-p',raw=True)
            self.size=png_size(screenshot)
            path.write_bytes(screenshot)
            text=ocr_output([os.environ.get('GUNBOUND_OCR','tesseract'),str(path),'stdout','--psm','11'])
            (self.output/(label+'.txt')).write_text(text)
            if pattern and not re.search(pattern,text,re.I):
                native=native_targets(path,pattern)
                if native:
                    (self.output/(label+'-native.json')).write_text(json.dumps(native,indent=2)+'\n')
                    text+='\n'+'\n'.join(target['text'] for target in native)
            if absent:
                text+='\n'+'\n'.join(target['text'] for target in native_targets(path,absent))
            if pattern==RESUME_PATTERN and not re.search(pattern,text,re.I):
                text+='\n[contrast OCR]\n'+'\n'.join(target['text'] for target in bright_button_targets(path,pattern))
            controls=[]
            if pattern and ('CAMERA' in pattern.upper() or not re.search(pattern,text,re.I)):
                controls=control_targets(path,pattern,include_camera_state=True)
                if controls:text+='\n[control OCR]\n'+'\n'.join(target['text'] for target in controls)
            camera_observed=any(re.fullmatch(r'CAMERA(?:\s+ON)?|C[ÂA]MERA(?:\s+ATIVA)?',item['text'],re.I) for item in controls)
            needs_absence_ocr=absent and absent!=r'CREATE|SETTINGS' and not (absent==CAMERA_ON_PATTERN and camera_observed)
            if (pattern and not re.search(pattern,text,re.I)) or needs_absence_ocr or (pattern and 'CAMERA' in pattern and not camera_observed):
                enhanced=enhanced_ocr(path)
                if enhanced.strip():text+='\n[enhanced OCR]\n'+enhanced
            if self.size[0]>=self.size[1] and (pattern is None or re.search(pattern,text,re.I)) and (absent is None or not re.search(absent,text,re.I)):
                self.observations.append(dict(screen=label,ocr_pattern=pattern,ocr_absent=absent,screenshot=path.name))
                return text
            if time.monotonic()>deadline:
                raise CaptureTimeout(f'Android UI expected {label}: {pattern}, absent: {absent}; OCR: {text[:300]}')
            time.sleep(1)

    def read_tsv(self,label='target'):
        path=self.output/(label+'.png')
        screenshot=self.run('exec-out','screencap','-p',raw=True)
        self.size=png_size(screenshot);path.write_bytes(screenshot)
        if self.size[0]<self.size[1]:
            raise ValueError('Cannot locate Android UI before landscape render')
        tsv=ocr_output([os.environ.get('GUNBOUND_OCR','tesseract'),str(path),'stdout','--psm','11','tsv'])
        (self.output/(label+'.tsv')).write_text(tsv)
        return tsv

    def locate_text(self,pattern,label='target'):
        try:
            target=text_target(self.read_tsv(label),pattern)
        except ValueError as error:
            if 'missing' not in str(error):raise
            found=native_targets(self.output/(label+'.png'),pattern)
            if len(found)>1:raise ValueError('Native raster target ambiguous') from error
            if found:
                target=found[0]
                (self.output/(label+'-native.json')).write_text(json.dumps(target,indent=2)+'\n')
            else:
                try:target=unscale_target(text_target(enhanced_ocr(self.output/(label+'.png'),tsv=True),pattern),3)
                except ValueError as error:
                    if 'missing' not in str(error):raise
                    found=bright_button_targets(self.output/(label+'.png'),pattern)
                    if not found:found=control_targets(self.output/(label+'.png'),pattern)
                    if not found:raise
                    if len(found)>1:raise ValueError('Contrast OCR target ambiguous') from error
                    target=found[0]
        if min(target['left'],target['top'])<0 or target['left']+target['width']>self.size[0] or target['top']+target['height']>self.size[1]:
            raise ValueError('OCR rectangle exceeds rendered screenshot')
        return target

    def wait_text(self,pattern,label,timeout=15):
        deadline=time.monotonic()+timeout
        while True:
            try:
                return self.locate_text(pattern,label)
            except ValueError as error:
                if 'missing' not in str(error) or time.monotonic()>=deadline:
                    raise
                time.sleep(0.25)

    def wait_keyboard(self,shown: bool,timeout=15):
        deadline=time.monotonic()+timeout
        while True:
            try:
                dump=self.run('shell','dumpsys','input_method')
            except RuntimeError:
                # Gboard's service dump can fail transiently while attaching.
                # Repeat only this read, never the preceding tap or Back.
                if time.monotonic()>=deadline:
                    raise
                time.sleep(0.25)
                continue
            ready=keyboard_visible(dump)==shown
            if shown:
                ready=ready and not re.search(r'mServedConnecting\s*=\s*true|mServedInputConnection\s*=\s*null',dump)
                served=re.search(r'(?m)^\s*mServedView=([^\n]+)',dump)
                if served:
                    ready=ready and 'GodotEditText' in served[1]
            if ready:
                break
            if time.monotonic()>=deadline:
                if hasattr(self,'output'):
                    (self.output/('keyboard-'+('open' if shown else 'close')+'-timeout.txt')).write_text(dump)
                raise ValueError('Android IME did not '+('open with Godot input focus' if shown else 'close'))
            time.sleep(0.25)
        # Allow focus/layout signals from the observed native IME transition
        # to reach the engine before editing or locating the Save control.
        time.sleep(0.25)

    def tap_text(self,pattern,label='tap-target',hold_ms=0,wait_timeout=0):
        target=self.wait_text(pattern,label,wait_timeout) if wait_timeout else self.locate_text(pattern,label)
        x=round(target['left']+target['width']/2);y=round(target['top']+target['height']/2)
        if hold_ms:
            self.run('shell','input','swipe',str(x),str(y),str(x),str(y),str(hold_ms))
        else:
            self.run('shell','input','tap',str(x),str(y))
        self.actions_attempted.append(dict(action='hold-text' if hold_ms else 'tap-text',pattern=pattern,
                                           target=target,hold_ms=hold_ms))
        return target

    def tap_below_label(self,pattern,label='field-target'):
        target=self.locate_text(pattern,label)
        # Settings fields sit directly below their visible label. Derive the
        # offset from rendered font height, not a full-window fit or notch guess.
        x=round(target['left']+target['width']/2);y=round(target['top']+target['height']*2.5)
        self.run('shell','input','tap',str(x),str(y))
        self.actions_attempted.append(dict(action='tap-below-label',pattern=pattern,target=target))

    def resume_options(self,label):
        self.tap_text(r'OK',label=label)
        # A following Back must see the running screen. Otherwise an old
        # popup frame can be mistaken for the pause requested by that Back.
        self.capture(label+'-closed',r'CAMERA|C[ÂA]MERA',absent=r'\bOK\b')

    def system_tip_target(self):
        path='/data/local/tmp/gunbound-ci-window.xml'
        self.run('shell','rm','-f',path)
        try:
            self.run('shell','uiautomator','dump','--compressed',path)
            xml=self.run('shell','cat',path)
            (self.output/'system-window.xml').write_text(xml)
            return system_tip_target(xml)
        finally:
            self.run('shell','rm','-f',path)

    def dismiss_system_tips(self,label='system-fullscreen-tip'):
        target=self.system_tip_target()
        text=self.capture(label+'-probe')
        if target is None and not system_tip_visible(text):
            return
        # Only Android's exact immersive-mode onboarding signature permits
        # dismissal. Never click generic OK or a game dialog opportunistically.
        if target is not None:
            if target['left']+target['width']>self.size[0] or target['top']+target['height']>self.size[1]:
                raise ValueError('System onboarding target exceeds screenshot')
            self.run('shell','input','tap',str(round(target['left']+target['width']/2)),str(round(target['top']+target['height']/2)))
        else:
            self.tap_text(r'Got it|Entendi',label=label+'-dismiss')
        deadline=time.monotonic()+5
        while True:
            after=self.capture(label+'-after')
            if (self.system_tip_target() is None if target is not None else not system_tip_visible(after)):
                break
            if time.monotonic()>=deadline:
                raise ValueError('Android full-screen onboarding did not dismiss')
            time.sleep(0.25)
        self.actions_attempted.append(dict(action='dismiss-system-fullscreen-onboarding',
                                           signature='Viewing full screen / To exit swipe down from the top'))

    def attempt_player_charge(self,label):
        deadline=time.monotonic()+25
        while time.monotonic()<deadline:
            words=parse_tsv(self.read_tsv(label+'-timer'))
            # HudArt.draw_timer emits only during PLAYER/AIM. Wind digits are
            # centered; restrict the numeric timer oracle to the upper right.
            timers=[word for word in words if word['left']>self.size[0]*0.7
                    and word['top']<self.size[1]*0.35
                    and re.fullmatch(r'\d{1,2}[.,:]\d{1,2}',word['text'])]
            if timers:
                target=self.locate_text(r'PASS|PASSAR',label+'-charge-anchor')
                x=round(target['left']+target['width']+target['height']*2)
                y=round(target['top']+target['height']/2)
                if x>=self.size[0]:
                    raise ValueError('Charge anchor exceeds rendered screen')
                self.run('shell','input','swipe',str(x),str(y),str(x),str(y),'3500')
                self.actions_attempted.append(dict(action='charge-hold',duration_ms=3500,
                                                   player_turn_evidence='visible-native-timer',timer=timers[0],
                                                   anchor=target,shot_outcome='not-proven'))
                self.capture(label+'-after-charge',r'CAMERA|C[ÂA]MERA|PAUSE|PAUSA')
                return
            time.sleep(1)
        self.actions_attempted.append(dict(action='charge-hold',outcome='not-attempted',
                                           reason='player-turn-timer-not-observed',shot_outcome='not-proven'))

    def pan_camera(self,label):
        for attempt in range(1,4):
            text=self.capture(label+'-camera-state-before-pan',r'CAMERA|C[ÂA]MERA')
            if not re.search(CAMERA_ON_PATTERN,text,re.I):
                self.tap_text(r'CAMERA|C[ÂA]MERA',label=label+'-camera-on')
            self.capture(label+'-camera-active',CAMERA_ON_PATTERN)
            width,height=self.size
            self.run('shell','input','swipe',str(round(width*.55)),str(round(height*.45)),
                     str(round(width*.4)),str(round(height*.45)),'600')
            try:
                self.capture(label+'-camera-after-pan',CAMERA_ON_PATTERN,timeout=3)
            except CaptureTimeout:
                if attempt==3:raise
                # Reobserve the toggle after a turn reset. Never retry a failed
                # transport command, and still require ON after the final pan.
                continue
            self.actions_attempted.append(dict(action='camera-pan',duration_ms=600,attempts=attempt,
                                               outcome='gesture-delivered-camera-mode-visible',world_displacement='not-proven'))
            return

    def disable_camera(self,label):
        taps=0
        for attempt in range(1,4):
            # Turn transitions reset this toggle. A screenshot read and the tap
            # are not atomic: act again only on a newly recognized ON label.
            text=self.capture(label+'-camera-state',r'CAMERA|C[ÂA]MERA')
            if not re.search(CAMERA_ON_PATTERN,text,re.I):
                self.actions_attempted.append(dict(action='camera-off',attempts=taps,outcome='visible-off'))
                return
            try:
                self.tap_text(CAMERA_ON_PATTERN,label=label+'-camera-off-'+str(attempt))
            except ValueError as error:
                if 'missing' not in str(error):raise
                # It may have reset between the two reads. Observe again;
                # never invent coordinates for a label that disappeared.
                continue
            taps+=1
            try:
                self.capture(label+'-camera-disabled',r'CAMERA|C[ÂA]MERA',timeout=3,absent=CAMERA_ON_PATTERN)
                self.actions_attempted.append(dict(action='camera-off',attempts=taps,outcome='visible-off'))
                return
            except CaptureTimeout:
                if attempt==3:raise
        raise CaptureTimeout('Camera state could not be confirmed after bounded observations')

    def launch(self,app,reset=True):
        if reset:
            self.run('shell','am','force-stop',app)
        # Resolve the exported launch activity; never inject engine arguments.
        activity=self.run('shell','cmd','package','resolve-activity','--brief',app).strip().splitlines()[-1]
        if '/' not in activity:
            raise ValueError('Android launch activity not found')
        self.run('shell','am','start','-W','-n',activity)
        self.log_pid=self.run('shell','pidof',app).strip()

    def logs(self,app):
        pid=self.run('shell','pidof',app).strip()
        if not re.fullmatch(r'\d+',pid):
            raise ValueError('Android application exited unexpectedly')
        logs=Device.application_logs(self,app)
        (self.output/'logcat.txt').write_text(logs)
        if ERRORS.search(logs):
            raise ValueError('Android runtime error; see logcat')
        return logs

    def application_logs(self,app):
        sdk=self.run('shell','getprop','ro.build.version.sdk').strip()
        if not sdk.isdigit():raise ValueError('Cannot resolve Android API for log observation')
        if int(sdk)<26:
            if self.run('shell','am','get-current-user').strip()!='0':
                raise ValueError('Android7 smoke requires the dedicated default-user AVD')
            uid=legacy_package_uid(self.run('shell','dumpsys','package',app),app)
            return legacy_uid_logs(self.run('logcat','-d','-v','threadtime','-v','uid'),uid)
        uid_output=self.run('shell','cmd','package','list','packages','-U',app)
        matches=re.findall(r'^package:'+re.escape(app)+r'\s+uid:(\d+)\s*$',uid_output,re.M)
        if len(matches)!=1:
            raise ValueError('Cannot resolve final application UID')
        # logcat was cleared once after install. UID scope retains failures
        # from earlier processes when persistence/lifecycle relaunches the app.
        return self.run('logcat','-d','--uid='+matches[0])


def diagnostic(device: Device,apk: Path,app: str,token: str,version: str):
    device.run('install','-r',str(apk))
    device.run('logcat','-c')
    device.launch(app)
    deadline=time.monotonic()+900
    while time.monotonic()<deadline:
        # Diagnostic exits itself; read scoped tag/UID logs even after exit.
        logs=device.application_logs(app)
        (device.output/'diagnostic-logcat.txt').write_text(logs)
        if ERRORS.search(logs):
            raise ValueError('Android diagnostic runtime error')
        if 'ANDROID DIAGNOSTIC: PASS' in logs:
            # Drain shutdown/render diagnostics too: a PASS printed before a
            # deferred GL failure cannot make the diagnostic successful.
            time.sleep(2)
            logs=device.application_logs(app)
            (device.output/'diagnostic-logcat.txt').write_text(logs)
            return diagnostic_report(logs,token,version)
        time.sleep(2)
    raise TimeoutError('Android diagnostic did not produce a fresh PASS')


def final_ui(device: Device,apk: Path,app: str):
    # Test candidates have deliberately ephemeral signing keys. Clear ONLY the
    # fixed .ci sandbox before switching from diagnostic to final-like bytes.
    # Distribution install -r keeps its persistent-key update contract.
    if app=='com.chafy.gunboundrecomp.ci' and ('package:'+app) in device.run('shell','pm','list','packages',app).splitlines():
        device.run('uninstall',app)
    device.run('install','-r',str(apk))
    device.run('logcat','-c')
    device.launch(app)
    device.dismiss_system_tips()
    device.capture('lobby',r'CREATE|SETTINGS')
    # Real touch into shop; Back must return to lobby.
    device.tap_text(r'AVATAR',label='open-shop');device.capture('shop',r'GOLD|CASH|AVATAR|SHOP',absent=r'CREATE|SETTINGS')
    device.dismiss_system_tips('shop-system-tip')
    device.run('shell','input','keyevent','KEYCODE_BACK');device.capture('lobby-after-shop',r'CREATE|SETTINGS')
    device.tap_text(r'SETTINGS|CONFIGURA[CÇ][ÕO]ES',label='open-settings');device.capture('settings',r'Nickname|Apelido|Preferences|Prefer')
    device.tap_below_label(r'Nickname|Apelido',label='nickname-field')
    device.wait_keyboard(True)
    device.run('shell','input','keyevent','KEYCODE_MOVE_END')
    for _ in range(20):
        device.run('shell','input','keyevent','KEYCODE_DEL')
    # Delete in both directions: Android/Godot key mapping or cursor position
    # cannot leave the original suffix behind. Both keycodes exist on API24.
    for _ in range(20):
        device.run('shell','input','keyevent','KEYCODE_FORWARD_DEL')
    nickname='Android42'
    device.run('shell','input','text',nickname)
    device.run('shell','input','keyevent','KEYCODE_BACK')
    device.wait_keyboard(False)
    nickname_pattern=r'\b'+re.escape(nickname)+r'\b'
    device.tap_text(SAVE_PATTERN,label='save-profile',wait_timeout=15);device.capture('profile-saved',nickname_pattern)
    device.launch(app);device.dismiss_system_tips('profile-relaunch-tip');device.capture('profile-persisted',nickname_pattern)
    for mode in ('solo','jewel'):
        device.tap_text(r'CREATE',label=mode+'-open-room');device.capture(mode+'-room',r'START')
        if mode=='jewel':
            device.tap_text(r'SOLO',label='select-jewel');device.capture('jewel-selected',r'JEWEL')
        device.tap_text(r'START',label=mode+'-start')
        device.capture(mode+'-battle',r'CAMERA|PAUSE|PAUSA|ANGLE|[0-9]+\s*%',timeout=60)
        device.pan_camera(mode)
        device.disable_camera(mode)
        # Require exact OFF label after toggling; substring CAMERA also appears
        # in CAMERA ON, so an ordinary capture regex alone is insufficient.
        device.capture(mode+'-camera-off-confirmed',r'CAMERA|C[ÂA]MERA',absent=CAMERA_ON_PATTERN)
        device.attempt_player_charge(mode)
        device.tap_text(r'PAUSE|PAUSA',label=mode+'-touch-pause')
        device.capture(mode+'-touch-pause-visible',OPTIONS_POPUP_PATTERN)
        device.resume_options(mode+'-touch-resume')
        device.run('shell','input','keyevent','KEYCODE_BACK')
        device.capture(mode+'-pause',OPTIONS_POPUP_PATTERN)
        device.run('shell','input','keyevent','KEYCODE_HOME')
        device.launch(app,reset=False)
        device.dismiss_system_tips(mode+'-resume-tip')
        device.capture(mode+'-resume',r'Resume|Retomar|Continuar|Continue')
        device.tap_text(r'Resume|Retomar|Continuar|Continue',label=mode+'-confirm-foreground')
        device.capture(mode+'-foreground-confirmed',OPTIONS_POPUP_PATTERN,absent=r'\bResume\b|\bRetomar\b|\bContinuar\b|\bContinue\b')
        device.resume_options(mode+'-foreground-unpause')
        device.logs(app)
        # Force-stop discards live battle as specified, preserving saved profile.
        device.run('shell','am','force-stop',app);device.launch(app)
        device.dismiss_system_tips(mode+'-restart-tip')
        device.capture(mode+'-restart',nickname_pattern)
    device.logs(app)
    return dict(launch='passed',lobby='passed',shop='passed',solo='passed',jewel='passed',
                persistence='passed',back='passed',home='passed',touch='single-finger-adb',
                camera_mode='verified-on-and-off',camera_pan='gesture-attempted-world-displacement-not-proven',
                charge='see-actions-attempted-shot-not-proven',actions_attempted=device.actions_attempted,
                multitouch='not-tested',audio='not-tested',arm64='manual_gate_required')


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--apk',type=Path,required=True)
    parser.add_argument('--app-id',required=True)
    parser.add_argument('--serial',default='emulator-5554')
    parser.add_argument('--adb',default=os.environ.get('ADB','adb'))
    parser.add_argument('--output',type=Path,required=True)
    parser.add_argument('--diagnostic',action='store_true')
    parser.add_argument('--token')
    parser.add_argument('--version',required=True)
    args=parser.parse_args()
    report_path=args.output/'report.json'
    report_path.unlink(missing_ok=True)
    device=Device(args.adb,args.serial,args.output)
    digest=hashlib.file_digest(args.apk.open('rb'),'sha256').hexdigest()
    try:
        report=diagnostic(device,args.apk,args.app_id,args.token,args.version) if args.diagnostic else final_ui(device,args.apk,args.app_id)
    except Exception:
        if device.log_pid and re.fullmatch(r'\d+',device.log_pid):
            (args.output/'failure-logcat.txt').write_text(device.run('logcat','-d','--pid='+device.log_pid))
        raise
    result=dict(schema=1,apk_sha256=digest,version=args.version,app_id=args.app_id,
                executed_abi=device.run('shell','getprop','ro.product.cpu.abi').strip(),
                kind='diagnostic' if args.diagnostic else 'final-ui',status='passed',results=report,
                observations=device.observations)
    report_path.write_text(json.dumps(result,indent=2)+'\n')


if __name__=='__main__':
    main()
