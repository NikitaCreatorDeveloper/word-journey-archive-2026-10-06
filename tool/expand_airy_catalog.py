"""Deterministic authored batches. Keeps every legacy concept/pack identity.

Run with a1/a2/b1/b2/c1; each invocation materialises all completed levels.
No online content, automatic CEFR reclassification, or generated examples.
"""
import collections, hashlib, itertools, json, re, statistics, sys
from pathlib import Path
sys.stdout.reconfigure(encoding='utf-8')
ROOT = Path(__file__).resolve().parents[1]
LEVELS = ['a1', 'a2', 'b1', 'b2', 'c1']
through = sys.argv[1] if len(sys.argv) > 1 else 'c1'
completed = LEVELS[:LEVELS.index(through) + 1]
output = ROOT/'assets/vocabulary/catalog-v1.json'
published = json.loads(output.read_text(encoding='utf-8')) if output.exists() else {}
protect_published = set(published.get('sizedLevels', [])) == set(LEVELS)
if protect_published and completed != LEVELS:
    raise ValueError('Cannot regress a published complete batch. Regenerate with c1; add new situations without deleting published IDs.')
baseline = ROOT / 'tool/content/airy/baseline-catalog-v1.json'
j = json.loads(baseline.read_text(encoding='utf-8'))
original_ids = {c['id'] for c in j['concepts']}
by_id = {c['id']: c for c in j['concepts']}
by_meaning = {(c['english'].lower(), c['russian'].lower(), c['partOfSpeech']): c for c in j['concepts']}
warnings = []

def add(en, ru, pos, exen, exru, level, category, situation):
    key = (en.lower(), ru.lower(), pos)
    # New translations/POS must not silently fork the same historical meaning.
    # Existing cross-pack uses belong in explicit reuse lists, not authored rows.
    if any(c['english'].lower() == en.lower() and c['id'] in original_ids for c in j['concepts']) and key not in by_meaning:
        raise ValueError(f'Review possible legacy sense/alias before adding {en}')
    if key in by_meaning:
        c = by_meaning[key]
        if c['cefrLevel'] != level:
            raise ValueError(f'Cannot regrade {en}: existing {c["cefrLevel"]}, requested {level}')
        if category not in c['categoryTags']: c['categoryTags'].append(category)
        return c['id']
    slug = re.sub('[^a-z0-9]+', '-', en.lower()).strip('-')
    ident = 'airy.' + slug + '.' + hashlib.sha256(('|'.join(key)).encode()).hexdigest()[:10]
    c = dict(id=ident, lemma=en, english=en, russian=ru, senseKey=slug+'.'+category,
             cefrLevel=level, partOfSpeech=pos, matchLabelEn=en, matchLabelRu=ru,
             exampleEn=exen, exampleRu=exru,
             acceptedVariants=[en] + {'yoghurt': ['yogurt'], 'colour': ['color'], 'organise': ['organize'], 'savoury': ['savory']}.get(en, []),
             categoryTags=[category], situationTags=[situation],
             curriculumPriority='core' if level in ['a1','a2'] else 'useful',
             provenance=dict(source='Original authored Airy curriculum; reference principles only',
               url='https://www.oxfordlearnersdictionaries.com/about/wordlists/oxford3000-5000',
               checked='Author-written meaning, translation and context. No independent CEFR sense verification.',
               date='2026-10-01', cefrEvidenceScope='editorial', reviewStatus='authored'))
    assert all([en.strip(), ru.strip(), pos, exen.strip(), exru.strip()]), ident
    assert pos in ['noun','verb','adjective','adverb','phrase','phrasalVerb','interjection'], ident
    assert len(en) <= 48 and len(ru) <= 48, (ident,en,ru)
    by_id[ident] = c; by_meaning[key] = c; j['concepts'].append(c)
    return ident

for level in completed:
    category = None; extras = collections.defaultdict(list)
    for line in (ROOT/f'tool/content/airy/{level}.tsv').read_text(encoding='utf-8-sig').splitlines():
        if not line.strip() or line.startswith('#'): continue
        if line.startswith('@'): category = line[1:]; continue
        fields = line.split('|'); assert len(fields) == 5, line
        extras[category].append(add(*fields, level, category, f'airy.{level}.{category}.extension'))
    assert len(extras) == 12 and all(len(v) == 8 for v in extras.values()), (level,extras)
    for p in j['packs']:
        if p['cefrLevel'] != level: continue
        p['conceptIds'] = list(dict.fromkeys(p['conceptIds'] + extras[p['categoryId']]))
        assert 20 <= len(p['conceptIds']) <= 30, p['id']

# Six distinct A1 situations, individually authored membership lists.
food_source = ROOT/'tool/content/airy/a1-situations.json'
if food_source.exists() and 'a1' in completed:
    for p in json.loads(food_source.read_text(encoding='utf-8')):
        category = p['categoryId']
        ids = []
        for en in p['reuse']:
            matches = [c for c in j['concepts'] if c['english'] == en and c['cefrLevel'] == 'a1']
            assert len(matches) == 1, ('Unclear reference',en)
            c = matches[0]; ids.append(c['id'])
            if category not in c['categoryTags']: c['categoryTags'].append(category)
        for row in p['new']:
            ids.append(add(*row, 'a1', category, p['id']))
        assert len(ids) == len(set(ids)) == 20, p['id']
        j['packs'].append(dict(id=p['id'], title=p['title'], goal=p['goal'], categoryId=category, cefrLevel='a1', conceptIds=ids))

goals = {
 'daily':'Описать жильё, бытовые дела и повседневные планы.',
 'people':'Поддержать разговор и понятно передать отношение к человеку.',
 'shopping':'Выбрать товар, уточнить условия покупки и обсудить расходы.',
 'city':'Объяснить маршрут и обсудить транспорт и городскую среду.',
 'trips':'Уточнить детали поездки и объяснить возникшую ситуацию.',
 'work':'Объяснить задание, договориться о работе и обсудить учёбу.',
 'tech':'Описать работу устройства или приложения и уточнить неполадку.',
 'nature':'Обсудить погоду, прогулку и изменения окружающей среды.',
 'health':'Описать самочувствие и ощущения; только языковая практика.',
 'culture':'Обсудить досуг, впечатления и особенности произведения.',
 'thought':'Сформулировать выбор, причину или аргумент в разговоре.',
 'food':'Заказать еду и напитки, описать вкус и уточнить просьбу.',
}
for p in j['packs']:
    if not p.get('goal'): p['goal'] = goals[p['categoryId']]
    words = [by_id[i] for i in p['conceptIds']]
    assert all(c['cefrLevel'] == p['cefrLevel'] for c in words), p['id']
    for field in ['matchLabelEn','matchLabelRu']:
        labels = [c[field].strip().lower() for c in words]
        assert len(labels) == len(set(labels)), ('Ambiguous',p['id'],field)
assert original_ids <= set(by_id)
if protect_published:
    assert {c['id'] for c in published['concepts']} <= set(by_id), 'Would drop a published concept ID; use an explicit stable-ID editorial migration.'
    assert {p['id'] for p in published['packs']} <= {p['id'] for p in j['packs']}, 'Would drop a published pack ID.'
j['contentRevision'] = 2
j['sizedLevels'] = completed
(ROOT/'assets/vocabulary/catalog-v1.json').write_text(json.dumps(j, ensure_ascii=False, indent=2), encoding='utf-8')

matrix = []; overlaps = []
for cat in j['categories']:
    for level in LEVELS:
        ps = [p for p in j['packs'] if p['categoryId'] == cat['id'] and p['cefrLevel'] == level]
        sizes = [len(p['conceptIds']) for p in ps]
        ids = set(itertools.chain.from_iterable(p['conceptIds'] for p in ps))
        matrix.append(dict(category=cat['id'],level=level,packs=len(ps),minimum=min(sizes),median=statistics.median(sizes),maximum=max(sizes),unique=len(ids),memberships=sum(sizes),missing=max(0,10-len(ps))))
        for a,b in itertools.combinations(ps,2):
            aa,bb=set(a['conceptIds']),set(b['conceptIds']); score=len(aa&bb)/len(aa|bb)
            if score >= .55: overlaps.append(dict(first=a['id'],second=b['id'],jaccard=round(score,3),shared=len(aa&bb)))
memberships=sum(len(p['conceptIds']) for p in j['packs'])
summary=dict(concepts=len(j['concepts']),packs=len(j['packs']),memberships=memberships,
             reusedMembershipFraction=1-len(j['concepts'])/memberships,completedLevels=completed,
             missingPacks=sum(row['missing'] for row in matrix),matrix=matrix,suspiciousOverlap=overlaps,
             provenance=dict(collections.Counter(c['provenance']['reviewStatus'] for c in j['concepts'])))
(ROOT/'docs/catalog-coverage.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2),encoding='utf-8')
report=['# Реальное покрытие каталога','', f'Партия до {through.upper()}. {summary["concepts"]} уникальных понятий, {summary["packs"]} наборов, {memberships} включений.',
        f'Повторно используемых включений: {summary["reusedMembershipFraction"]:.1%}. Это ссылки с общей историей, не новые понятия.',
        f'До 600 наборов не хватает {summary["missingPacks"]}. Полностью доведённые до 20–30 уровни: {", ".join(completed)}.',
        '', '| Категория | CEFR | Наборов | min / median / max | Уникальных | Включений | До 10 |','|---|---|---:|---|---:|---:|---:|']
for row in matrix: report.append(f'| {row["category"]} | {row["level"].upper()} | {row["packs"]} | {row["minimum"]} / {row["median"]:g} / {row["maximum"]} | {row["unique"]} | {row["memberships"]} | {row["missing"]} |')
report += ['', '## Языковая проверка', 'CEFR конкретных значений: редакторская оценка; независимая сплошная проверка отсутствует.',
           'Новое содержание имеет статус authored. Старые статусы сохранены; две старые Oxford-проверки относятся только к лемме.',
           'Схема, размеры, уникальность ответов и ссылки проверены отдельно от лингвистической экспертизы.',
           '', '## Сходство наборов', 'Автоматический порог для проверки: Jaccard ≥ 0.55 внутри category×level.',
           *[f'- {x["first"]} ↔ {x["second"]}: {x["jaccard"]}, общих {x["shared"]}.' for x in overlaps]]
if not overlaps: report.append('Пар выше порога нет. Это не доказывает практическую разницу целей; цели проверяются редакторски.')
(ROOT/'docs/catalog-coverage.md').write_text('\n'.join(report)+'\n',encoding='utf-8')
print(f'{through.upper()}: {len(j["concepts"])} concepts; {len(j["packs"])} packs; {memberships} memberships; missing {summary["missingPacks"]}; overlap flags {len(overlaps)}')
