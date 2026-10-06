"""Original Word Journey feedback and geometric icon; no third-party media."""
from pathlib import Path
import math, struct, wave
from PIL import Image, ImageDraw

root = Path(__file__).resolve().parents[1]
audio = root / 'assets/audio'; audio.mkdir(parents=True, exist_ok=True)
for name, tones, seconds in [('select',[760],.045),('correct',[660,880],.12),('wrong',[220,190],.14),('combo',[660,880,1100],.19),('milestone',[660,990,1320],.28),('finish',[523,659,784,1046],.42)]:
    rate=22050; values=[]
    for i in range(int(seconds*rate)):
        t=i/rate; segment=min(len(tones)-1,int(t/seconds*len(tones)))
        envelope=min(1,t/.006)*max(0,1-t/seconds)**1.7
        value=.25*envelope*(math.sin(2*math.pi*tones[segment]*t)+.12*math.sin(4*math.pi*tones[segment]*t))
        values.append(struct.pack('<h',int(value*32767)))
    with wave.open(str(audio/f'{name}.wav'),'wb') as f:
        f.setnchannels(1); f.setsampwidth(2); f.setframerate(rate); f.writeframes(b''.join(values))

res=root/'android/app/src/main/res'
fg='M33,28 L53,28 Q58,28 58,33 L58,70 Q58,75 53,75 L33,75 Q28,75 28,70 L28,33 Q28,28 33,28 Z M53,33 L75,33 Q80,33 80,38 L80,75 Q80,80 75,80 L53,80 Q48,80 48,75 L48,38 Q48,33 53,33 Z'
spark='M59,43 L48,57 L57,57 L53,69 L68,51 L59,51 Z'
draw=res/'drawable'; draw.mkdir(parents=True,exist_ok=True)
(draw/'ic_launcher_foreground.xml').write_text(f'<vector xmlns:android="http://schemas.android.com/apk/res/android" android:width="108dp" android:height="108dp" android:viewportWidth="108" android:viewportHeight="108"><path android:fillColor="#ABB7FF" android:pathData="M33,28 L53,28 Q58,28 58,33 L58,70 Q58,75 53,75 L33,75 Q28,75 28,70 L28,33 Q28,28 33,28 Z"/><path android:fillColor="#F5FAFF" android:pathData="M53,33 L75,33 Q80,33 80,38 L80,75 Q80,80 75,80 L53,80 Q48,80 48,75 L48,38 Q48,33 53,33 Z"/><path android:fillColor="#3734A0" android:pathData="{spark}"/></vector>',encoding='utf-8')
(draw/'ic_launcher_monochrome.xml').write_text(f'<vector xmlns:android="http://schemas.android.com/apk/res/android" android:width="108dp" android:height="108dp" android:viewportWidth="108" android:viewportHeight="108"><path android:fillColor="#FFFFFF" android:fillType="evenOdd" android:pathData="M33,28 L53,28 Q58,28 58,33 L58,33 L75,33 Q80,33 80,38 L80,75 Q80,80 75,80 L53,80 Q48,80 48,75 L33,75 Q28,75 28,70 L28,33 Q28,28 33,28 Z {spark}"/></vector>',encoding='utf-8')
(draw/'ic_launcher_background.xml').write_text('<shape xmlns:android="http://schemas.android.com/apk/res/android" android:shape="rectangle"><solid android:color="#3734A0"/></shape>',encoding='utf-8')
for version in ['v26','v33']:
    d=res/f'mipmap-anydpi-{version}'; d.mkdir(parents=True,exist_ok=True)
    mono='<monochrome android:drawable="@drawable/ic_launcher_monochrome"/>' if version=='v33' else ''
    xml=f'<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android"><background android:drawable="@drawable/ic_launcher_background"/><foreground android:drawable="@drawable/ic_launcher_foreground"/>{mono}</adaptive-icon>'
    for name in ['ic_launcher','ic_launcher_round']: (d/f'{name}.xml').write_text(xml,encoding='utf-8')
def icon(size,round=False):
    scale=4; im=Image.new('RGBA',(108*scale,108*scale)); p=ImageDraw.Draw(im)
    p.rounded_rectangle((0,0,432,432),radius=216 if round else 94,fill='#3734A0')
    p.rounded_rectangle(tuple(v*scale for v in (28,28,58,75)),radius=20,fill='#ABB7FF')
    p.rounded_rectangle(tuple(v*scale for v in (48,33,80,80)),radius=20,fill='#F5FAFF')
    p.polygon([(x*scale,y*scale) for x,y in [(59,43),(48,57),(57,57),(53,69),(68,51),(59,51)]],fill='#3734A0')
    return im.resize((size,size),Image.Resampling.LANCZOS)
for dpi,size in [('mdpi',48),('hdpi',72),('xhdpi',96),('xxhdpi',144),('xxxhdpi',192)]:
    d=res/f'mipmap-{dpi}'; d.mkdir(exist_ok=True)
    icon(size).save(d/'ic_launcher.png'); icon(size,True).save(d/'ic_launcher_round.png')
brand=root/'assets/brand'; brand.mkdir(parents=True,exist_ok=True)
(brand/'personal-icon.svg').write_text(f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 108 108"><rect width="108" height="108" rx="24" fill="#3734A0"/><rect x="28" y="28" width="30" height="47" rx="5" fill="#ABB7FF"/><rect x="48" y="33" width="32" height="47" rx="5" fill="#F5FAFF"/><path d="{spark}" fill="#3734A0"/></svg>',encoding='utf-8')
icon(432).save(brand/'personal-icon-preview.png')
print('6 original WAVs; adaptive, monochrome, 10 legacy PNGs; SVG source')
