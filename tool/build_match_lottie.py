"""Original Midnight Indigo vector artwork, deterministic editable Lottie JSON.
No external graphics, text, raster images, expressions, masks or blur effects.
Run with Python from the project root. Generated assets can be edited separately.
"""
from pathlib import Path
import json,math
from build_premium_match_lottie import combo as premium_combo, victory as premium_victory

LAVENDER='#B6A3FF'; VIOLET='#7864DC'; MINT='#58DDC2'; GOLD='#FFD38A'; WHITE='#FFF1CD'
def color(hex):return [int(hex[i:i+2],16)/255 for i in (1,3,5)]+[1]
def static(v):return {'a':0,'k':v}
def animated(*frames):
 return {'a':1,'k':[{'t':t,'s':v if isinstance(v,list) else [v],
  'i':{'x':[.65],'y':[1]},'o':{'x':[.25],'y':[0]}} for t,v in frames]}
def path(points,closed=True,tangents=None):
 return {'ty':'sh','nm':'Editable vector path','ks':static({'v':points,'i':tangents[0] if tangents else [[0,0] for _ in points],
  'o':tangents[1] if tangents else [[0,0] for _ in points],'c':closed})}
def fill(c,opacity=100):return {'ty':'fl','nm':'Core fill','c':static(color(c)),'o':static(opacity),'r':1}
def stroke(c,width,opacity=100):return {'ty':'st','nm':'Energy outline','c':static(color(c)),'o':static(opacity),'w':static(width),'lc':2,'lj':2,'ml':4}
def gradient(c1,c2,start,end):
 return {'ty':'gf','nm':'Amber core gradient','o':static(100),'r':1,'t':1,
  's':static(start),'e':static(end),'g':{'p':2,'k':static([0,*color(c1)[:3],1,*color(c2)[:3]])}}
def trim(end):return {'ty':'tm','nm':'Trace formation','s':static(0),'e':end,'o':static(0),'m':1}
def ellipse(cx,cy,r):return {'ty':'el','nm':'Energy ring','p':static([cx,cy]),'s':static([r*2,r*2]),'d':1}
def star(cx,cy,r,small=None):
 small=small or r*.28
 return path([[cx+r,cy],[cx+small,cy+small],[cx,cy+r],[cx-small,cy+small],
              [cx-r,cy],[cx-small,cy-small],[cx,cy-r],[cx+small,cy-small]])
def transform(p=None,s=None,o=None,r=None,a=None):
 return {'ty':'tr','p':p or static([0,0]),'s':s or static([100,100]),'o':o or static(100),
  'r':r or static(0),'a':static(a or [0,0]),'sk':static(0),'sa':static(0)}
def layer(name,shapes,duration,opacity=None,scale=None,center=None):
 center=center or [0,0,0]
 return {'ty':4,'nm':name,'sr':1,'ip':0,'op':duration,'st':0,'bm':0,
  'ks':{'a':static(center),'p':static(center),'s':scale or static([100,100,100]),
        'r':static(0),'o':opacity or static(100)},'shapes':shapes}
def particles(positions,duration,c=GOLD,up=False):
 groups=[]
 for i,(x,y,r) in enumerate(positions):
  dx=(x-80)*.12;dy=-13 if up else (y-80)*.12
  groups.append({'ty':'gr','nm':f'Spark {i+1}','it':[star(0,0,r),fill(c),
   transform(p=animated((0,[x,y]),(10+i,[x,y]),(duration-1,[x+dx,y+dy])),
    o=animated((0,0),(6+i*2,0),(13+i*2,90),(duration-10,65),(duration-1,0)),
    s=animated((0,[55,55]),(12+i*2,[100,100]),(duration-1,[65,65]))) ]})
 return layer('particles',groups,duration)
def save(name,size,duration,layers):
 for i,l in enumerate(layers):l['ind']=i+1
 document={'v':'5.7.4','nm':f'Word Journey · Midnight Indigo · {name}',
  'fr':60,'ip':0,'op':duration,'w':size,'h':size,'ddd':0,'assets':[],'layers':layers,
  'markers':[{'tm':0,'cm':'Original vectors by Word Journey, editable shapes','dr':0}]}
 target=Path('assets/lottie');target.mkdir(parents=True,exist_ok=True)
 (target/f'{name}.json').write_text(json.dumps(document,separators=(',',':')),encoding='utf8')
 print(name,round(duration/60*1000),'ms',len(layers),'layers',len(json.dumps(document)),'bytes')

def correct():
 n=26;fade=animated((0,0),(3,65),(9,100),(15,100),(25,0))
 check=[[25,41],[35,51],[55,29]]
 check_stroke=stroke(MINT,3.5)
 check_stroke['c']=animated((0,color(LAVENDER)),(10,color(MINT)),(25,color(MINT)))
 layers=[layer('check-core',[path(check,False),check_stroke,trim(animated((0,0),(4,0),(12,100)))],n,fade),
  layer('energy-arc',[ellipse(40,40,25),stroke(LAVENDER,1.2,65),trim(animated((0,0),(7,55),(25,85)))],n,
   animated((0,0),(6,55),(25,0)),animated((0,[85,85,100]),(25,[110,110,100])),[40,40,0]),
  layer('particles',[{'ty':'gr','nm':f'Tiny spark {i+1}','it':[star(x,y,2.2),fill(c),
    transform(o=animated((0,0),(5+i*2,85),(25,0)))]} for i,(x,y,c) in enumerate([(61,23,LAVENDER),(18,36,MINT),(54,62,MINT)])],n)]
 save('correct',80,n,layers)
def combo():
 premium_combo()

def milestone():
 n=27;fade=animated((0,0),(5,90),(12,100),(26,0))
 layers=[layer('accent-star',[star(40,40,14),gradient(WHITE,LAVENDER,[32,29],[46,49])],n,fade,
  animated((0,[80,80,100]),(10,[100,100,100]),(26,[105,105,100])),[40,40,0]),
  layer('energy-ring',[ellipse(40,40,24),stroke(LAVENDER,1.6,85),trim(animated((0,0),(9,90),(26,100)))],n,fade,
  animated((0,[80,80,100]),(26,[112,112,100])),[40,40,0]),
  layer('mint-accent',[ellipse(40,40,27),stroke(MINT,.9,55),trim(animated((0,0),(8,30),(26,50)))],n,fade)]
 save('milestone',80,n,layers)
def victory():
 premium_victory()
if __name__=='__main__':correct();combo();milestone();victory()
