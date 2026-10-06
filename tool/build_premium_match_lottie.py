"""Original Midnight Indigo energy artwork. Run from project root with Python.
Only combo/victory are generated; correct and milestone stay byte-identical.
Ordinary 2D paths, fills, strokes and eased transform keyframes; no external art.
"""
from pathlib import Path
import json, math

GOLD='#FFD38A'; PALE='#FFF1CD'; AMBER='#EDB95E'; LAVENDER='#B6A3FF'; VIOLET='#7864DC'
def color(c): return [int(c[i:i+2],16)/255 for i in (1,3,5)]+[1]
def fixed(v): return {'a':0,'k':v}
def keys(*frames):
 return {'a':1,'k':[{'t':t,'s':v if isinstance(v,list) else [v],
  'i':{'x':[.65],'y':[1]},'o':{'x':[.18],'y':[.7]}} for t,v in frames]}
def path(points):
 return {'ty':'sh','nm':'Original vector','ks':fixed({'v':points,'i':[[0,0] for _ in points],
  'o':[[0,0] for _ in points],'c':True})}
def fill(c): return {'ty':'fl','nm':'Facet fill','c':fixed(color(c)),'o':fixed(100),'r':1}
def stroke(c,w): return {'ty':'st','nm':'Thin energy stroke','c':fixed(color(c)),
 'o':fixed(100),'w':fixed(w),'lc':2,'lj':2,'ml':4}
def star(r,waist): return path([[r,0],[waist,waist],[0,r],[-waist,waist],
 [-r,0],[-waist,-waist],[0,-r],[waist,-waist]])
def group(name, shapes, p=None,s=None,o=None,r=None):
 return {'ty':'gr','nm':name,'it':[*shapes,{'ty':'tr','p':p or fixed([0,0]),
  'a':fixed([0,0]),'s':s or fixed([100,100]),'o':o or fixed(100),
  'r':r or fixed(0),'sk':fixed(0),'sa':fixed(0)}]}
def layer(name,shapes,end,center,opacity=None,scale=None):
 return {'ty':4,'nm':name,'sr':1,'ip':0,'op':end,'st':0,'bm':0,
 'ks':{'a':fixed([0,0,0]),'p':fixed([center,center,0]),
 's':scale or fixed([100,100,100]),'r':fixed(0),'o':opacity or fixed(100)},'shapes':shapes}
def ring(radius): return {'ty':'el','nm':'Energy ring','p':fixed([0,0]),'s':fixed([radius*2,radius*2]),'d':1}
def save(name,size,end,layers):
 for i,l in enumerate(layers): l['ind']=i+1
 doc={'v':'5.7.4','nm':f'Word Journey · Original premium {name}','fr':30,
  'ip':0,'op':end,'w':size,'h':size,'ddd':0,'assets':[],'layers':layers,
  'markers':[{'tm':0,'cm':'Original programmatic vectors; no manual editor required','dr':0}]}
 dest=Path('assets/lottie'); dest.mkdir(parents=True,exist_ok=True)
 p=dest/f'{name}.json'; p.write_text(json.dumps(doc,separators=(',',':')),encoding='utf8')
 print(name,size,'30 FPS',end,'frames',round(end/30,2),'s',p.stat().st_size,'bytes')
def combo():
 n=18; bolt=[[-45,9],[25,-118],[11,-10],[48,-20],[-24,116],[-5,-1]]
 scale=keys((0,[85,85,100]),(3,[106,106,100]),(7,[100,100,100]),(13,[100,100,100]),(18,[98,98,100]))
 fade=keys((0,0),(3,100),(13,100),(18,0))
 sparks=[]
 for i,(x,y,r) in enumerate([(-83,-60,9),(81,-48,7.5),(92,63,8),(-81,82,6.5)]):
  distance=math.hypot(x,y);dx=round(x/distance*23,2);dy=round(y/distance*23,2)
  sparks.append(group(f'Spark {i+1}',[star(r,r*.19),fill(GOLD if i%2==0 else LAVENDER)],
   p=keys((0,[x,y]),(7,[x,y]),(13,[x+dx*.7,y+dy*.7]),(18,[x+dx,y+dy])),
   s=keys((0,[0,0]),(3,[0,0]),(7,[100,100]),(18,[80,80])),
   o=keys((0,0),(3,0),(7,100),(13,35),(18,0))))
 layers=[layer('particles',sparks,n,180),
  layer('amber-core',[group('Pale gold lightning',[path(bolt),fill(GOLD),stroke(PALE,2.2)]),
   group('Amber facet',[path([[-45,9],[25,-118],[-5,-1],[-24,116]]),fill(AMBER)])],n,180,fade,scale),
  layer('energy-trail',[path(bolt),stroke(LAVENDER,14)],n,180,
   keys((0,0),(3,35),(7,35),(13,15),(18,0)),scale),
  layer('peak-ring',[ring(114),stroke(VIOLET,2)],n,180,
   keys((0,0),(3,45),(7,15),(13,10),(18,0)),
   keys((0,[50,50,100]),(3,[50,50,100]),(7,[110,110,100]),(18,[116,116,100]))) ]
 save('combo',360,n,layers)
def victory():
 n=27; sparks=[]
 for i,deg in enumerate([-150,-105,-62,-18,26,72,147]):
  a=math.radians(deg);x=round(math.cos(a)*94,2);y=round(math.sin(a)*94,2)
  travel=38+(i%3)*10;dx=round(math.cos(a)*travel,2);dy=round(math.sin(a)*travel-12,2)
  sparks.append(group(f'Vector reward particle {i+1}',[star(7.5 if i%2==0 else 6,1.5),fill(GOLD if i%2==0 else LAVENDER)],
   p=keys((0,[x,y]),(11,[x,y]),(20,[x+dx,y+dy]),(27,[x+dx*1.1,y+dy*1.1])),
   s=keys((0,[0,0]),(5,[0,0]),(11,[100,100]),(27,[75,75])),
   o=keys((0,0),(5,0),(11,100),(20,40),(27,0)),
   r=keys((0,0),(11,0),(27,16 if i%2 else -12))))
 shapes=[group('Four point reward star',[star(102,20),fill(GOLD),stroke(LAVENDER,1.5)]),
  group('Light facet',[path([[0,-102],[20,-20],[0,0],[-20,20],[-102,0],[-20,-20]]),fill(PALE)]),
  group('Amber facet',[path([[0,0],[20,-20],[102,0],[20,20],[0,102]]),fill(AMBER)])]
 layers=[layer('particles',sparks,n,210),
  layer('victory-star',shapes,n,210,keys((0,0),(5,100),(20,100),(27,0)),
   keys((0,[40,40,100]),(5,[110,110,100]),(11,[100,100,100]),(20,[100,100,100]),(27,[96,96,100]))),
  layer('peak-ring',[ring(112),stroke(VIOLET,2)],n,210,
   keys((0,0),(5,50),(11,0),(27,0)),
   keys((0,[30,30,100]),(5,[100,100,100]),(11,[145,145,100]),(27,[145,145,100]))) ]
 save('victory',420,n,layers)
if __name__=='__main__': combo(); victory()
