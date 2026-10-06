from pathlib import Path
import math, json
root=Path(__file__).resolve().parents[1]; assets=root/'assets'; scenes={}
def path(points,fill,stroke=None,width=1,gradient=None):
    return dict(points=points,fill=fill,stroke=stroke,width=width,gradient=gradient)
def poly(points,fill,**kw): return path([('M',*points[0])]+[('L',*p) for p in points[1:]]+[('Z',)],fill,**kw)
def circle(x,y,r,fill,**kw):
    k=r*.5522848
    return path([('M',x+r,y),('C',x+r,y+k,x+k,y+r,x,y+r),('C',x-k,y+r,x-r,y+k,x-r,y),('C',x-r,y-k,x-k,y-r,x,y-r),('C',x+k,y-r,x+r,y-k,x+r,y),('Z',)],fill,**kw)
def rect(x,y,w,h,r,fill,**kw):
    return path([('M',x+r,y),('L',x+w-r,y),('Q',x+w,y,x+w,y+r),('L',x+w,y+h-r),('Q',x+w,y+h,x+w-r,y+h),('L',x+r,y+h),('Q',x,y+h,x,y+h-r),('L',x,y+r),('Q',x,y,x+r,y),('Z',)],fill,**kw)
def star(x,y,r,fill,points=4,inner=.28,**kw):
    return poly([(x+(r if i%2==0 else r*inner)*math.cos(-math.pi/2+i*math.pi/points),y+(r if i%2==0 else r*inner)*math.sin(-math.pi/2+i*math.pi/points)) for i in range(points*2)],fill,**kw)
violet=['#B9A5FF','#7661E5']; indigo=['#6369D2','#303D80']; mint=['#B0FFE1','#3FA898']
land=[circle(315,72,70,'#8C69E51A'),circle(315,72,48,'#BFA0FF24'),circle(315,72,30,'#D8BCFF',gradient=['#F4DFFF','#A28DEA']),poly([(0,195),(122,93),(245,187),(350,126),(400,164),(400,280),(0,280)],'#383B8A',gradient=['#7470CB','#252B67']),poly([(0,225),(170,148),(274,210),(400,176),(400,280),(0,280)],'#272B63',gradient=['#4D4989','#171D43']),path([('M',215,194),('C',254,193,267,205,235,215),('C',174,233,289,235,257,280),('L',333,280),('C',351,236,225,225,263,215),('C',294,198,252,188,215,194),('Z',)],'#7773BF',gradient=['#8982DA','#35385F']),poly([(0,266),(82,212),(159,258),(187,280),(0,280)],'#151F43'),poly([(300,280),(333,239),(362,257),(400,236),(400,280)],'#172445')]
for x,y in [(36,57),(126,42),(229,54),(361,126),(166,104),(262,22)]: land.append(star(x,y,2.6,'#C3BDFFAA'))
for x,y in [(359,214),(377,227),(347,242)]:
    land += [path([('M',x,y-27),('C',x-14,y-18,x-12,y+4,x,y+11),('C',x+13,y,x+11,y-15,x,y-27),('Z',)],'#18265B'),path([('M',x,y-6),('L',x,y+35)],None,stroke='#36457B',width=2)]
scenes['illustrations/continue_landscape']=(400,280,land)
plant=land[:3]+[poly([(0,229),(95,176),(192,235),(290,199),(400,245),(400,280),(0,280)],'#343567'),path([('M',306,280),('C',311,217,309,161,334,102)],None,stroke='#A596EC',width=3)]
for x,y,side in [(310,242,-1),(314,219,1),(315,192,-1),(322,166,1),(328,139,-1)]:
    plant.append(path([('M',x,y),('C',x+side*38,y-8,x+side*52,y-43,x+side*42,y-63),('C',x+side*10,y-49,x+side*4,y-30,x,y),('Z',)],'#51469B',gradient=['#7461C7','#2F316C']))
    plant.append(path([('M',x,y),('Q',x+side*21,y-30,x+side*42,y-63)],None,stroke='#8E7AD9',width=1))
for x,y in [(36,54),(179,80),(255,28)]: plant.append(star(x,y,3,'#C9BDFF'))
scenes['illustrations/review_plant']=(400,280,plant)
box=[circle(160,126,95,'#7661E510'),circle(160,126,61,'#7661E515'),poly([(34,226),(98,194),(164,218),(233,186),(320,233),(320,260),(0,260)],'#43416A33'),poly([(96,128),(160,155),(160,218),(96,187)],'#6552AE',gradient=['#8E76EA','#473C83']),poly([(160,155),(224,128),(224,187),(160,218)],'#58468D',gradient=['#8470CB','#343262']),poly([(96,128),(160,102),(224,128),(160,155)],'#433664',stroke='#CAB2FF',width=1.2),poly([(96,128),(77,157),(141,182),(160,155)],'#9B87EB',gradient=['#B8A7FC','#7661C1']),poly([(160,155),(182,181),(245,152),(224,128)],'#8D7AE1',gradient=['#C0AAFF','#7464BA']),poly([(96,128),(116,94),(160,102),(160,155)],'#6D5FB8',stroke='#C6ABFF',width=1),poly([(160,102),(203,95),(224,128),(160,155)],'#806FCD',stroke='#C6ABFF',width=1)]
for x,y,r in [(72,103,5),(243,89,6),(263,156,3),(127,69,3)]: box.append(star(x,y,r,'#C5B9FF'))
scenes['illustrations/empty_review_box']=(320,260,box)
icons={
'daily': [('M',12,28),('L',32,10),('L',52,28),('L',47,28),('L',47,51),('L',37,51),('L',37,35),('L',27,35),('L',27,51),('L',17,51),('L',17,28),('Z',)],
'communication': [('M',9,50),('C',9,27,34,27,34,50),('Z',),('M',32,36),('C',44,27,55,33,55,50),('L',39,50),('Z',)],
'food': [('M',14,13),('L',14,29),('Q',14,34,20,34),('L',20,51),('L',24,51),('L',24,34),('Q',30,34,30,29),('L',30,13),('L',26,13),('L',26,27),('L',24,27),('L',24,13),('L',20,13),('L',20,27),('L',18,27),('L',18,13),('Z',),('M',43,13),('C',32,17,32,32,41,34),('L',41,51),('L',46,51),('L',46,13),('Z',)],
'shopping': [('M',12,23),('L',52,23),('L',48,51),('L',16,51),('Z',)],
'city': [('M',10,52),('L',10,26),('L',22,26),('L',22,12),('L',42,12),('L',42,31),('L',54,31),('L',54,52),('Z',)],
'travel': [('M',30,10),('L',35,10),('L',37,29),('L',53,38),('L',53,43),('L',37,37),('L',36,49),('L',43,53),('L',43,56),('L',32,52),('L',21,56),('L',21,53),('L',28,49),('L',27,37),('L',11,43),('L',11,38),('L',28,29),('Z',)],
'work_study': [('M',13,17),('Q',23,13,32,20),('Q',42,13,51,17),('L',51,48),('Q',42,44,32,51),('Q',23,44,13,48),('Z',)],
'technology': [('M',11,14),('L',53,14),('L',53,43),('L',35,43),('L',35,49),('L',44,49),('L',44,53),('L',20,53),('L',20,49),('L',29,49),('L',29,43),('L',11,43),('Z',)],
'nature': [('M',16,48),('C',11,25,22,14,50,12),('C',51,39,38,50,16,48),('Z',)],
'health': [('M',25,13),('L',39,13),('L',39,25),('L',51,25),('L',51,39),('L',39,39),('L',39,51),('L',25,51),('L',25,39),('L',13,39),('L',13,25),('L',25,25),('Z',)],
'leisure': [('M',14,17),('L',14,41),('C',0,39,1,57,15,52),('Q',21,50,21,44),('L',21,23),('L',46,17),('L',46,35),('C',32,33,33,51,47,46),('Q',53,44,53,38),('L',53,9),('Z',)],
'thoughts': [('M',16,41),('C',8,31,13,12,32,12),('C',50,12,56,30,47,40),('L',42,46),('L',22,46),('Z',)]}
for i,(name,shape) in enumerate(icons.items()):
    layers=[rect(1,1,62,62,17,'#5441AC',gradient=violet if i%3 else indigo),rect(1,1,62,62,17,None,stroke='#A896E3',width=.8),path(shape,'#E9E5FF',gradient=['#FFFFFF','#C2BAFF'])]
    if name=='communication': layers += [circle(21,20,9,'#F0EFFF'),circle(43,23,7,'#D3CBFF')]
    if name=='shopping': layers.append(path([('M',22,24),('L',22,20),('C',22,7,42,7,42,20),('L',42,24)],None,stroke='#E2DAFF',width=3))
    if name=='city':
        for x,y in [(28,22),(36,22),(28,31),(36,31),(28,41),(36,41)]: layers.append(rect(x,y,3,4,.5,'#655BC1'))
    if name=='technology': layers.append(rect(16,19,32,18,1,'#49477D'))
    if name=='nature': layers.append(path([('M',17,48),('L',40,23)],None,stroke='#7365BA',width=2.3))
    if name=='work_study': layers.append(path([('M',32,20),('L',32,51)],None,stroke='#6C5BC2',width=1.8))
    if name=='thoughts': layers += [rect(23,50,18,3,1,'#E2DAFF'),rect(27,55,10,3,1,'#C2BAFF')]
    scenes['category_icons/'+name]=(64,64,layers)
ranks=['start','spark','impulse','rhythm','focus','flow','resonance','spectrum','synthesis','horizon','lexicon']
for index,name in enumerate(ranks):
    points=5 if index<3 else 6 if index<7 else 8
    outline=[(100+(65 if i%2==0 else (43 if points==5 else 58))*math.cos(-math.pi/2+i*math.pi/points),90+(65 if i%2==0 else (43 if points==5 else 58))*math.sin(-math.pi/2+i*math.pi/points)) for i in range(points*2)]
    inner=[(100+(49 if i%2==0 else (33 if points==5 else 43))*math.cos(-math.pi/2+i*math.pi/points),90+(49 if i%2==0 else (33 if points==5 else 43))*math.sin(-math.pi/2+i*math.pi/points)) for i in range(points*2)]
    accents=['#D3B8FF','#FFDA86','#BCD7FF','#B6B4FF','#98ECD6','#9BC9FF','#C6B8FF','#ECA7EB','#AFEBE6','#B4C3FF','#FFE2A6']
    layers=[circle(100,93,80,'#AE85FF12'),poly([(64,128),(85,128),(91,188),(69,173)],'#8470DC',gradient=['#CCADFF','#6645B5']),poly([(85,128),(106,128),(112,190),(91,188)],'#B195FC',gradient=violet),poly([(106,128),(127,128),(131,173),(112,190)],'#7351C0',gradient=indigo)]
    if index>=1:
        for side in [-1,1]:
            for j in range(5):
                x=100+side*(57+j*3); y=143-j*15
                layers.append(path([('M',x,y),('Q',x+side*26,y-8,x+side*12,y-27),('Q',x-side*1,y-17,x,y),('Z',)],accents[index],gradient=[accents[index],'#806147']))
    layers += [poly(outline,accents[index],gradient=[accents[index],'#8D6BA1' if index!=1 else '#AE753D'],stroke='#F4DEFF',width=1.5),poly(inner,'#252A59',gradient=['#333B6D','#111B3A'],stroke=accents[index],width=1.8)]
    for j in range(len(outline)):
        next_j=(j+1)%len(outline)
        facet=accents[index] if j%3==0 else ('#FFF1CF' if index==1 else '#E6DCFF') if j%3==1 else ('#9E682E' if index==1 else '#6155A4')
        layers.insert(len(layers)-1, poly([outline[j],outline[next_j],inner[next_j],inner[j]],facet))
    if index in [0,1]: layers.append(star(100,89,24,'#F2E8FF',points=4))
    elif index==2: layers.append(poly([(107,64),(83,92),(99,92),(92,115),(117,84),(101,84)],'#F2E8FF'))
    elif index==3:
        for x,h in [(82,18),(94,30),(106,42)]: layers.append(rect(x,110-h,6,h,2,'#F2E8FF'))
    elif index==4: layers += [circle(100,90,24,None,stroke='#D6FFF0',width=2),circle(100,90,11,None,stroke='#D6FFF0',width=3),circle(100,90,3,'#D6FFF0')]
    elif index==5: layers.append(path([('M',78,78),('C',95,60,104,108,122,87),('M',78,95),('C',95,77,104,125,122,104)],None,stroke='#D8EEFF',width=4))
    elif index==6:
        for r in [9,17,25]: layers.append(circle(100,90,r,None,stroke='#ECE6FF',width=2))
    elif index==7:
        for j in range(5): layers.append(poly([(78+j*7,108),(91+j*3,72),(97+j*3,72),(84+j*7,108)],['#B7A2FF','#BAE2FF','#97E5DF','#EDBBFA','#FFDFA3'][j]))
    elif index==8: layers += [circle(90,90,18,None,stroke='#D4FFF7',width=3),circle(110,90,18,None,stroke='#D4FFF7',width=3)]
    elif index==9: layers += [path([('M',76,99),('Q',100,60,124,99)],None,stroke='#E0E7FF',width=3),path([('M',74,104),('L',126,104)],None,stroke='#E0E7FF',width=3)]
    else: layers += [path([('M',77,73),('Q',90,70,100,77),('Q',113,70,123,73),('L',123,106),('Q',112,103,100,111),('Q',88,103,77,106),('Z',),('M',100,77),('L',100,111)],None,stroke='#FFF1CB',width=3)]
    for x,y in [(31,39),(167,43),(157,167)]: layers.append(star(x,y,4,accents[index]))
    scenes['ranks/rank_'+name]=(200,200,layers)
dart="""// Generated from tool/build_indigo_vectors.py. SVG and Canvas share geometry.
import 'package:flutter/material.dart';

class PremiumArt extends StatelessWidget {
  const PremiumArt(this.name, {super.key, this.width = 120, this.height = 120, this.cover = false});
  final String name;
  final double width, height;
  final bool cover;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(child: RepaintBoundary(child: SizedBox(width: width, height: height, child: CustomPaint(painter: VectorArtPainter(name, cover: cover), isComplex: true, willChange: false))));
}
class _VectorLayer {
  _VectorLayer(this.path, this.fill, this.stroke, this.width, this.colors);
  final Path path;
  final Color? fill, stroke;
  final double width;
  final List<Color>? colors;
}
class VectorArtPainter extends CustomPainter {
  const VectorArtPainter(this.name, {this.cover = false});
  final bool cover;
  final String name;
  @override
  void paint(Canvas canvas, Size size) {
    final scene = _scenes[name];
    if (scene == null) return;
    final view = scene.$1;
    final xScale=size.width/view.width, yScale=size.height/view.height;
    final factor = cover ? (xScale > yScale ? xScale : yScale) : (xScale < yScale ? xScale : yScale);
    canvas.save();
    canvas.translate((size.width-view.width*factor)/2, (size.height-view.height*factor)/2);
    canvas.scale(factor);
    for (final layer in scene.$2) {
      if (layer.fill != null) {
        final paint=Paint()..color=layer.fill!;
        if (layer.colors != null) paint.shader=LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:layer.colors!).createShader(layer.path.getBounds());
        canvas.drawPath(layer.path,paint);
      }
      if (layer.stroke != null) canvas.drawPath(layer.path,Paint()..color=layer.stroke!..style=PaintingStyle.stroke..strokeWidth=layer.width..strokeJoin=StrokeJoin.round..strokeCap=StrokeCap.round);
    }
    canvas.restore();
  }
  @override
  bool shouldRepaint(VectorArtPainter old) => old.name != name || old.cover != cover;
}
final _scenes = <String, (Size, List<_VectorLayer>)>{
"""
def color(c):
    if c is None: return 'null'
    return 'Color(0x'+(c[-2:]+c[1:7] if len(c)==9 else 'FF'+c[1:])+')'
for name,(w,h,layers) in scenes.items():
    target=assets/(name+'.svg'); target.parent.mkdir(parents=True,exist_ok=True)
    svg=[f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}">','<defs>']
    for i,layer in enumerate(layers):
        if layer['gradient']: svg.append(f'<linearGradient id="g{i}" x1="0" y1="0" x2="1" y2="1"><stop stop-color="{layer["gradient"][0]}"/><stop offset="1" stop-color="{layer["gradient"][1]}"/></linearGradient>')
    svg.append('</defs>'); dart+=f"  '{name}': (const Size({w},{h}), [\n"
    for i,layer in enumerate(layers):
        cmds=' '.join(p[0]+' '+ ' '.join(f'{v:.3f}' for v in p[1:]) for p in layer['points'])
        fill=layer['fill']; opacity=''
        if fill and len(fill)==9: opacity=f' fill-opacity="{int(fill[-2:],16)/255:.4f}"'; fill=fill[:7]
        if layer['gradient']: fill=f'url(#g{i})'
        svg.append(f'<path d="{cmds}" fill="{fill or "none"}"{opacity} stroke="{layer["stroke"] or "none"}" stroke-width="{layer["width"]}" stroke-linejoin="round" stroke-linecap="round"/>')
        methods={'M':'moveTo','L':'lineTo','Q':'quadraticBezierTo','C':'cubicTo','Z':'close'}
        dpath='Path()'+''.join('..'+methods[p[0]]+'('+','.join(f'{v:.4f}' for v in p[1:])+')' for p in layer['points'])
        gradient='null' if not layer['gradient'] else '['+','.join(color(c) for c in layer['gradient'])+']'
        dart+=f"    _VectorLayer({dpath},{color(layer['fill'])},{color(layer['stroke'])},{layer['width']},{gradient}),\n"
    svg.append('</svg>'); target.write_text('\n'.join(svg),encoding='utf8');dart+='  ]),\n'
dart+='};\n';(root/'lib/app/premium_art.dart').write_text(dart,encoding='utf8')
tool=root/'tool/build_indigo_vectors.py'
source=Path(__file__).read_text(encoding='utf8').replace("root=Path(__file__).resolve().parents[1]; assets=root/'assets'; scenes={}","root=Path(__file__).resolve().parents[1]; assets=root/'assets'; scenes={}")
tool.write_text(source,encoding='utf8')
print('Created original vector assets:',len(scenes),'SVG + matching Canvas paths')
