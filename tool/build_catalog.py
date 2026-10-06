"""Build original authored rows; no external definitions/examples are imported."""
import json,re,hashlib,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
LEVELS=['a1','a2','b1','b2','c1']
through=sys.argv[1] if len(sys.argv)>1 else 'c1'
catalog=json.loads((ROOT/'assets/vocabulary/catalog-v1.json').read_text(encoding='utf-8'))
if catalog.get('contentRevision', 1) >= 2:
    raise SystemExit('Airy catalogue is authoritative. Use: python tool/expand_airy_catalog.py c1')
concepts=[c for c in catalog['concepts'] if c['id'].startswith('cafe.')]
packs=[]
for level in LEVELS:
    ids=[c['id'] for c in concepts if c['cefrLevel']==level]
    for index,(a,b) in enumerate([(0,12),(8,20)]):
        packs.append(dict(id=f'cafe.{level}.{index+1}',title=['В кафе: заказать и ответить','В кафе: обслуживание и оплата'][index],categoryId='food',cefrLevel=level,conceptIds=ids[a:b]))
for level in LEVELS[:LEVELS.index(through)+1]:
    category=title=pack_id=None;ids=[];pack_number=0
    lines=(ROOT/f'tool/content/{level}.txt').read_text(encoding='utf-8').splitlines()
    def finish():
        if pack_id:
            assert 12<=len(ids)<=20,(pack_id,len(ids))
            packs.append(dict(id=pack_id,title=title,categoryId=category,cefrLevel=level,conceptIds=list(ids)))
    for line in lines+['@END']:
        if not line.strip() or line.startswith('#'):continue
        if line.startswith('@'):
            finish()
            if line=='@END':break
            category,title=line[1:].split('|');pack_number+=1;pack_id=f'personal.{level}.{category}.{pack_number}';ids=[];continue
        parts=line.split('|');assert len(parts) in(3,5),(level,line)
        en,ru,kind=parts[:3]
        slug=re.sub('[^a-z0-9]+','-',en.lower()).strip('-')
        ident='lex.'+slug+'.'+hashlib.sha256((en.lower()+'|'+ru.lower()).encode()).hexdigest()[:8]
        assert not any(c['id']==ident for c in concepts),('Repeated meaning; reuse ID instead',en)
        if len(parts)==5:exen,exru=parts[3:]
        elif kind in('v','pv'):exen=f'I want to {en}.';exru=f'Я хочу {ru}.'
        elif kind=='n':exen=f'There is {"an" if en[0] in "aeiou" else "a"} {en} here.';exru=f'Здесь есть {ru}.'
        elif kind=='u':exen=f'There is {en} here.';exru=f'Здесь есть {ru}.'
        elif kind=='l':exen=f'There are {en} here.';exru=f'Здесь есть {ru}.'
        elif kind=='p':exen=f'In this conversation: “{en[0].upper()+en[1:]}”.';exru=f'В этом разговоре: «{ru[0].upper()+ru[1:]}».'
        else:raise ValueError(('Adjectives/adverbs need an original contextual example',line))
        c=dict(id=ident,lemma=en,english=en,russian=ru,senseKey=f'{slug}.{category}',matchLabelEn=en,matchLabelRu=ru,exampleEn=exen,exampleRu=exru,cefrLevel=level,partOfSpeech={'n':'noun','u':'noun','l':'noun','v':'verb','a':'adjective','d':'adverb','p':'phrase','pv':'phrasalVerb'}[kind],categoryTags=[category],situationTags=[pack_id],acceptedVariants=[en],curriculumPriority='core' if level in('a1','a2') else 'useful',provenance=dict(source='Original personal curriculum; Oxford/British Council selection references',url='https://www.oxfordlearnersdictionaries.com/about/wordlists/oxford3000-5000',checked='Original sense/translation/example; editorial CEFR, not independent meaning verification',date='2026-10-01',cefrEvidenceScope='editorial',reviewStatus='editorial'))
        concepts.append(c);ids.append(ident)
catalog.update(concepts=concepts,packs=packs)
target=ROOT/'assets/vocabulary/catalog-v1.json';target.write_text(json.dumps(catalog,ensure_ascii=False,indent=2),encoding='utf-8')
errors=[]
for p in packs:
    words=[next(c for c in concepts if c['id']==i) for i in p['conceptIds']]
    for key in ['matchLabelEn','matchLabelRu']:
        if len({c[key].lower() for c in words})!=len(words):errors.append('Ambiguous '+p['id'])
for c in concepts:
    if len(c['matchLabelEn'])>48 or len(c['matchLabelRu'])>48:errors.append('Long label '+c['id'])
assert not errors,errors
report=['# Catalog coverage — '+through.upper(),'','Original bilingual material. Schema validation is not expert language review.','Exact CEFR of each sense remains editorial unless separately recorded.','', '| Level | Unique concepts | Packs | Categories | Meaning verified |','|---|---:|---:|---:|---:|']
for l in LEVELS:
    selected=[c for c in concepts if c['cefrLevel']==l];ps=[p for p in packs if p['cefrLevel']==l]
    report.append(f'| {l.upper()} | {len(selected)} | {len(ps)} | {len({p["categoryId"] for p in ps})} | {sum(c["provenance"]["cefrEvidenceScope"]=="meaning" for c in selected)} |')
report+=['','## Categories', '| Level | Category | Packs | Unique concepts |','|---|---|---:|---:|']
for l in LEVELS:
    for cat in catalog['categories']:
        ps=[p for p in packs if p['cefrLevel']==l and p['categoryId']==cat['id']]
        if ps:report.append(f'| {l.upper()} | {cat["title"]} | {len(ps)} | {len({i for p in ps for i in p["conceptIds"]})} |')
(ROOT/f'docs/coverage-{through}.md').write_text('\n'.join(report)+'\n',encoding='utf-8')
print(f'{len(concepts)} unique concepts, {len(packs)} packs, structure/labels valid. Meaning-level verification: 0; editorial levels explicit.')
