"""One-time source/ID-preserving migration, never touches installed user data."""
import json,re
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def write(path,text):
    target=ROOT/path;target.parent.mkdir(parents=True,exist_ok=True);target.write_text(text,encoding='utf-8')
source=(ROOT/'lib/features/world/data/cafe_seed.dart').read_text(encoding='utf-8')
rows=re.findall(r"\(\s*'([^']+)',\s*'([^']+)',\s*'([^']+)',\s*(_n|_v|_a|_p|PartOfSpeech.adverb),?\s*\)",source)
assert len(rows)==100,len(rows)
categories=[('daily','Повседневная жизнь','home'),('people','Люди и общение','people'),('food','Еда и приготовление','food'),('shopping','Покупки и деньги','money'),('city','Город и транспорт','city'),('trips','Поездки','trip'),('work','Работа и учёба','work'),('tech','Технологии и IT','tech'),('nature','Природа и погода','nature'),('health','Здоровье и тело','health'),('culture','Досуг и культура','culture'),('thought','Мысли и аргументы','thought')]
concepts=[];packs=[]
for i,(sense,en,ru,pos) in enumerate(rows):
    level=['a1','a2','b1','b2','c1'][i//20]
    concepts.append(dict(id=f'cafe.{level}.{sense}',lemma=en,english=en,russian=ru,senseKey=sense,matchLabelEn=en,matchLabelRu=ru,exampleEn=f'At the café, we use the expression “{en}”.',exampleRu=f'В кафе мы используем выражение «{ru}».',cefrLevel=level,partOfSpeech={'_n':'noun','_v':'verb','_a':'adjective','_p':'phrase','PartOfSpeech.adverb':'adverb'}[pos],categoryTags=['food'],situationTags=['cafe'],acceptedVariants=[en]+(['cookie'] if sense=='biscuit.food' else []),curriculumPriority='useful',provenance=dict(source='Original Café seed; editorial estimate',url='https://www.oxfordlearnersdictionaries.com/about/wordlists/oxford3000-5000',checked='Selection principles only; exact meaning/CEFR not verified',date='2026-10-01',cefrEvidenceScope='editorial',reviewStatus='editorial')))
for level in ['a1','a2','b1','b2','c1']:
    packs.append(dict(id=f'cafe.{level}',title='Разговор в кафе',categoryId='food',cefrLevel=level,conceptIds=[c['id'] for c in concepts if c['cefrLevel']==level]))
write('assets/vocabulary/catalog-v1.json',json.dumps(dict(schemaVersion=1,categories=[dict(id=i,title=t,symbol=s) for i,t,s in categories],concepts=concepts,packs=packs),ensure_ascii=False,indent=2))
retired=[]
for folder in ['lib/features/world','lib/features/travel','test/features/world','integration_test','test_driver','tool/map_source']:
    for file in (ROOT/folder).rglob('*'):
        if file.is_file():retired.append(file.relative_to(ROOT).as_posix());file.unlink()
for name in ['assets/maps/world_110m.json','tool/build_world_asset.py','lib/features/topics/topics_screen.dart','docs/map-data-source.md']:
    p=ROOT/name
    if p.exists():retired.append(name);p.unlink()
write('retired-files.txt','\n'.join(retired))
pub=(ROOT/'pubspec.yaml').read_text(encoding='utf-8').replace('assets/maps/world_110m.json','assets/vocabulary/catalog-v1.json')
write('pubspec.yaml',pub)
write('README.md','# Word Journey\n\nPersonal offline vocabulary trainer: Categories, Review, Progress.\nTravel/maps/routes have been retired. Match retains one paired-card engine.\nSee docs/personal-trainer-plan.md and docs/personal-trainer-report.md.\nApplication ID: com.wordjourney.app. No publishing or commit before acceptance.\n')
p=ROOT/'test/flutter_test_config.dart'
txt=p.read_text(encoding='utf-8');txt=txt.replace("import 'package:word_journey/features/world/geometry/world_geometry.dart';\n",'');txt=re.sub(r'  setUpAll\(\(\) async \{.*?\n  \}\);\n','',txt,flags=re.S);write(str(p.relative_to(ROOT)),txt)
p=ROOT/'test/features/training/training_flow_test.dart';txt=p.read_text(encoding='utf-8');txt=txt.replace("import 'package:word_journey/app/word_journey_app.dart';\n",'')
txt=txt.replace("  await tester.pumpWidget(const WordJourneyApp());\n  await tester.pumpAndSettle();\n  await tester.tap(find.byType(NavigationDestination).at(1));\n  await tester.pumpAndSettle();\n  await tester.tap(find.text('Тестовая тренировка'));", "  await tester.pumpWidget(MaterialApp(theme: AppTheme.light, darkTheme: AppTheme.dark, home: const TrainingSetupScreen()));")
txt=txt.replace("    await tester.pumpWidget(const WordJourneyApp());\n    await tester.pumpAndSettle();\n    await tester.tap(find.byType(NavigationDestination).at(1));\n    await tester.pumpAndSettle();\n    await tester.tap(find.text('Тестовая тренировка'));", "    await tester.pumpWidget(MaterialApp(theme: AppTheme.light, home: const TrainingSetupScreen()));")
write(str(p.relative_to(ROOT)),txt)
p=ROOT/'test/features/profile/cefr_profile_test.dart';txt=p.read_text(encoding='utf-8');txt=txt.replace("import 'package:word_journey/features/world/data/travel_content.dart';\n",'').replace("import 'package:word_journey/features/world/model/world_content.dart';\n",'')
start=txt.index("  test('Same spelling");end=txt.index('    testWidgets(',start);txt=txt[:start]+"  for (final level in CefrLevel.values) {\n"+txt[end:]
start=txt.index("  test(\n    'Pack concepts");end=txt.index('  for (final brightness',start);txt=txt[:start]+txt[end:];write(str(p.relative_to(ROOT)),txt)
print('Migrated 100 stable Café IDs; retired geography only. Original files are in baseline backup.')
