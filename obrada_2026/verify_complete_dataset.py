from pathlib import Path
import json
import numpy as np
import pandas as pd
from PIL import Image

root=Path(__file__).resolve().parent.parent
snapshot=root/'obrada_2026/pre_dopune_dva_zapisnika.json'
# Historical snapshots are optional local files, excluded from the repository.
before=json.loads(snapshot.read_text(encoding='utf-8')) if snapshot.exists() else {}
stations=pd.read_csv(root/'election_dataset_2026_biracka_mesta.csv')
areas=pd.read_csv(root/'election_dataset_2026.csv')
assert len(stations)==89 and stations.unique_id.is_unique
assert stations.has_results.eq(1).all()
assert not stations.num_registered_voters.isna().any()
assert areas.results_complete.all() and areas.registered_voters_complete_for_available_results.all()
assert areas.missing_polling_station_ids.isna().all()
assert areas.missing_registered_voter_ids.isna().all()

for name,frame,key,allowed in [
    ('election_dataset_2026_biracka_mesta.csv',stations,'unique_id',{'UZ-66','SE-05'}),
    ('election_dataset_2026.csv',areas,'voting_area',{'Царина','Севојно'}),
]:
    if name not in before:
        continue
    old=pd.DataFrame(before[name]).replace('NA',np.nan).replace('',np.nan).set_index(key)
    new=frame.set_index(key)
    keep=sorted(set(new.index)-allowed)
    # Normalize CSV representations before comparing the unaffected records.
    for col in new:
        a=old.loc[keep,col]
        b=new.loc[keep,col]
        if pd.api.types.is_bool_dtype(b):
            assert a.str.upper().equals(b.astype(str).str.upper()),(name,col)
        elif pd.api.types.is_numeric_dtype(b):
            assert np.allclose(pd.to_numeric(a),b,equal_nan=True),(name,col)
        else:
            assert a.fillna('').astype(str).equals(b.fillna('').astype(str)),(name,col)

cols=['num_votes_rulling','num_votes_other_lists','num_voted','num_valid_ballots',
      'num_invalid_ballots','num_ballots_in_box','num_registered_voters']+[f'votes_list_{i:02d}' for i in range(1,19)]
expected=stations.groupby('voting_area')[cols].sum().sort_index()
actual=areas.set_index('voting_area')[cols].sort_index()
pd.testing.assert_frame_equal(expected,actual,check_dtype=False)
assert np.allclose(areas.percentage_won_by_rulling_of_num_registered,areas.num_votes_rulling/areas.num_registered_voters)
assert np.allclose(areas.percentage_won_by_rulling_of_voted,areas.num_votes_rulling/areas.num_voted)
s=stations.set_index('unique_id')
assert list(s.loc['UZ-66',['num_registered_voters','num_voted','num_invalid_ballots','num_valid_ballots','votes_list_01','votes_list_02']])==[1060,843,8,835,306,5]
assert list(s.loc['SE-05',['num_registered_voters','num_voted','num_invalid_ballots','num_valid_ballots','votes_list_01','votes_list_02']])==[761,619,0,619,259,15]
assert s.loc['UZ-05','num_registered_voters']==387
assert list(s.loc[['UZ-53','UZ-54'],'voting_area'])==['Пора','Пора']
assert stations.num_votes_rulling.sum()==17328
assert stations.num_voted.sum()==48205
assert stations.num_ballots_in_box.sum()==48198
assert stations.num_valid_ballots.sum()==47762
assert stations.num_invalid_ballots.sum()==436
print('Independent checks passed: 89/89 results, all aggregates and ratios, and source values.')
if before:
    print('Historical comparison passed: unchanged records outside UZ-66/SE-05 and their areas.')
print(areas.loc[areas.voting_area.isin(['Царина','Севојно']),['voting_area','num_votes_rulling','num_registered_voters','num_voted','combined_label']].to_string(index=False))
im=Image.open(root/'election_plot_2026.png')
assert im.size==(4200,3450)
im.thumbnail((1500,1500))
im.save(root/'obrada_2026/final_preview.png')
