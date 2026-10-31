"""Rebuild the station-level CSV from local PDFs and documented user supplements.

No OCR estimates and no substituted results for missing polling stations.
Run skripta_izbori_2026.R afterward to rebuild the area dataset and PNG.
"""
from pathlib import Path
import csv, json, re, hashlib
ROOT=Path(__file__).resolve().parent.parent
WORK=ROOT/'obrada_2026'
mapping=json.loads((WORK/'mapping.json').read_text(encoding='utf-8'))
records={}
for line in (WORK/'transkripcija.txt').read_text(encoding='utf-8').splitlines():
    if not line.strip() or line.startswith('#'): continue
    head,values=line.split('|')
    key,*nums=head.split()
    nums=[None if x=='NA' else int(x) for x in nums]
    votes={int(k):int(v) for k,v in re.findall(r'(\d+):(\d+)',values)}
    assert sum(votes.values())==nums[4],(key,'list sum',sum(votes.values()),nums[4])
    assert nums[2]==nums[3]+nums[4],(key,'ballot balance')
    assert key not in records
    records[key]=dict(zip(['num_registered_voters','num_voted','num_ballots_in_box','num_invalid_ballots','num_valid_ballots'],nums))
    records[key].update({f'votes_list_{i:02d}':votes.get(i,0) for i in range(1,19)})

for supplement in json.loads((WORK/'user_overrides.json').read_text(encoding='utf-8')):
    assert supplement['field']=='num_registered_voters'
    assert supplement['unique_id'] in records
    assert isinstance(supplement['value'],int) and supplement['value']>0
    records[supplement['unique_id']][supplement['field']]=supplement['value']

pdfs=list((ROOT/'zapisnici_primedbe_ispravke').glob('*.pdf'))
def pdf_key(p):
    n=int(re.search(r'\d+',p.name)[0])
    return ('SE' if 'СЕВОЈНО' in p.name else 'UZ')+f'-{n:02d}'
main={pdf_key(p):p.name for p in pdfs if re.match(r'@ПА \d+( СЕВОЈНО)?_',p.name)}
assert set(main)==set(records)
assert len(records)==89
notes={
    'UZ-02':'Број изашлих поновљен и у заглављу тачке 11; преузета је тачка 11.1: 273.',
    'UZ-05':'У тачки 4 изворног PDF-а број регистрованих бирача није уписан. Корисник је 31.10.2026. у овој преписци допунио податак: 387 уписаних бирача. Извор допуне: obrada_2026/user_overrides.json.',
    'UZ-08':'У тачки 11.2 број 129 је прецртан и уписано је 130; употребљено је 130.',
    'UZ-40':'Достављена је примедба о условима на бирачком месту и раду одбора. Она не садржи нове бројчане резултате; преузети су резултати из записника.',
    'UZ-46':'Тачка 11.1 је руком преправљена са 665 на 663 уз напомену о нејасним потписима; употребљено је 663. У кутији је 665 листића. Разлика је сачувана.',
    'UZ-49':'У тачки 11.5 код листе 10 број 2 је прецртан и означено је без гласова; употребљено је 0. Остале руком унете исправке сачуване су према видљивом коначном упису.',
    'UZ-53':'Тачка 11.1: 1093 изашлих, тачка 11.2: 1091 листић. Разлика је сачувана. Подручје промењено из Росуље у Пора по захтеву корисника.',
    'UZ-54':'Подручје промењено из Росуље у Пора по захтеву корисника.',
    'UZ-55':'У тачки 11.5 код листе 4 прецртано 4, уписано 1; употребљено је 1.',
    'UZ-58':'Тачка 11.1: 921 изашлих, тачка 11.2: 919 листића. За листу 3 употребљен је коначан рукописни упис 587.',
    'UZ-63':'Достављена је примедба о фотографисању и цепању листића. Она не садржи нове бројчане резултате; преузети су резултати из записника.',
    'UZ-66':'Резултати допуњени 31.10.2026. из накнадно достављеног записника РГ-2: @ПА 66_80932a0360dc53d13061657faa272793.pdf, страна 1.',
    'UZ-71':'Достављена је примедба о печаћењу кутије и обустави гласања. Она не садржи нове бројчане резултате; преузети су резултати из записника.',
    'UZ-72':'Достављена је примедба о фотографисању гласачких листића. Она не садржи нове бројчане резултате; преузети су резултати из записника.',
    'UZ-75':'Примењено решење РГ-7/НП2026-2 од 26.10.2026: листа 1 има 177 уместо 176 гласова.',
    'UZ-77':'Употребљене видљиве преправке: 1023 изашлих, 1020 листића у кутији, 7 неважећих, 1013 важећих; гласови према коначним уписима.',
    'UZ-80':'Примењено решење РГ-7/НП2026-2 од 26.10.2026: листа 4 има 1 уместо 4 гласа.',
    'UZ-82':'Тачка 11.1: 1062 изашлих, тачка 11.2: 1060 листића. Разлика је сачувана.',
    'SE-03':'Достављен је и РГ-11 (посматрачи); бројчани резултати преузети су из РГ-2.',
    'SE-04':'Достављена је и примедба на поступак гласања. Она не садржи нове бројчане резултате; преузети су резултати из записника.',
    'SE-05':'Резултати допуњени 31.10.2026. из накнадно достављеног записника РГ-2: @ПА 5 СЕВОЈНО_c8890c359b46ab4db9f86c9314c6c4bf.pdf, страна 1. Црта код неважећих листића означава 0; свих 619 листића су важећи. Раније достављени РГ-11 сачуван је као прилог.',
}
fields=['num_registered_voters','num_voted','num_ballots_in_box','num_invalid_ballots','num_valid_ballots']+[f'votes_list_{i:02d}' for i in range(1,19)]
output=[]
for m in mapping:
    key=m['unique_id'];data=records.get(key)
    extra=[p.name for p in pdfs if pdf_key(p)==key and p.name!=main.get(key)]
    area='Пора' if 'објекат је на пори' in (m['mapping_note'] or '').lower() else m['voting_area']
    row={k:m[k] for k in ['unique_id','municipality','polling_station_no','polling_station_name','polling_station_address']}
    row.update(election_date='2026-10-25',voting_area=area,voting_area_original=m['voting_area'],mapping_note=m['mapping_note'] or '',mapping_override=int(area!=m['voting_area']),has_results=int(data is not None))
    row.update({f:data[f] if data else None for f in fields})
    row.update(num_votes_rulling=data['votes_list_01']+data['votes_list_02'] if data else None)
    row.update(num_votes_other_lists=data['num_valid_ballots']-row['num_votes_rulling'] if data else None)
    row.update(original_votes_list_01=176 if key=='UZ-75' else (data['votes_list_01'] if data else None),original_votes_list_04=4 if key=='UZ-80' else (data['votes_list_04'] if data else None))
    row.update(source_pdf=main.get(key,''),source_pages='1' if data else '',additional_pdfs='; '.join(extra),correction_applied=int(key in ['UZ-75','UZ-80']),data_note=notes.get(key,''))
    row.update(list_votes_minus_valid=sum(data[f'votes_list_{i:02d}'] for i in range(1,19))-data['num_valid_ballots'] if data else None,ballots_minus_valid_invalid=data['num_ballots_in_box']-data['num_valid_ballots']-data['num_invalid_ballots'] if data else None,turnout_minus_ballots=data['num_voted']-data['num_ballots_in_box'] if data else None)
    output.append(row)
assert len(output)==89
assert all(r['has_results'] for r in output)
assert [r['unique_id'] for r in output if r['mapping_override']]==['UZ-53','UZ-54']
assert len({r['voting_area'] for r in output})==35
dest=ROOT/'election_dataset_2026_biracka_mesta.csv'
with dest.open('w',encoding='utf-8-sig',newline='') as f:
    w=csv.DictWriter(f,fieldnames=list(output[0]));w.writeheader();w.writerows({k:'NA' if v is None else v for k,v in r.items()} for r in output)
manifest=[dict(filename=p.name,sha256=hashlib.sha256(p.read_bytes()).hexdigest(),bytes=p.stat().st_size) for p in pdfs]
(WORK/'source_manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
main_paths=[str(Path('zapisnici_primedbe_ispravke')/main[r['unique_id']]) for r in output]
(WORK/'main_files.json').write_text(json.dumps(main_paths,ensure_ascii=False),encoding='utf-8')
print('Saved',dest.name,len(output),'stations,',sum(r['has_results'] for r in output),'with results, 35 areas')
print('Totals on available stations:',{f:sum(r[f] for r in output if r[f] is not None) for f in ['num_votes_rulling','num_voted','num_valid_ballots','num_invalid_ballots']})
print('Turnout/ballot differences:',[(r['unique_id'],r['turnout_minus_ballots']) for r in output if r['turnout_minus_ballots'] not in [None,0]])
