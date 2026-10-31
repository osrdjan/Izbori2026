# Obrada izbornih zapisnika za 25.10.2026.

Obrađeni su materijali iz foldera `zapisnici_primedbe_ispravke` i mapiranje iz `uzice_izbori_2026_mapiranje_birackih_mesta.xlsx`. Korisnik je 31.10.2026. u ovoj prepisci dopunio broj upisanih birača za užičko BM 5: **387**. Dopuna je zabeležena u `obrada_2026/user_overrides.json`. Nisu korišćeni rezultati prethodnih izbora niti podaci sa interneta za dopunjavanje praznina.

## Izlazni fajlovi

- `election_dataset_2026_biracka_mesta.csv`: 89 redova prema mapiranju, po jedan za svako biračko mesto. Rezultati postoje za svih 89 mesta. Sadrži svih 18 lista, upisane birače, izašle, listiće u kutiji, važeće i nevažeće listiće, izvore, ispravke, napomene i računske kontrole.
- `election_dataset_2026.csv`: zbirni dataset za 35 područja, sa kolonama kompatibilnim sa prethodnim datasetom i dodatnim kolonama za obuhvat i pojedinačne liste.
- `skripta_izbori_2026.R`: čita dataset po biračkim mestima, proverava računske veze, pravi zbirni dataset i PNG.
- `election_plot_2026.png`: dijagram, 4200 × 3450 piksela, 300 dpi.

## Pravila računanja

1. Po izričitom izboru korisnika, `num_votes_rulling` je zbir lista 1 i 2: „АЛЕКСАНДАР ВУЧИЋ – УЈЕДИЊЕНА СРБИЈА“ i „ИВИЦА ДАЧИЋ – ФАКТОР СТАБИЛНОСТИ!“.
2. `num_voted` predstavlja broj izašlih iz tačke 11.1, uključujući i birače koji nisu predali važeći listić. To nije zbir glasova lista. `num_valid_ballots` je zasebna kolona.
3. Prvi procenat je zbir glasova lista 1 i 2 podeljen zbirom upisanih birača iz tačke 4. Drugi je isti broj glasova podeljen zbirom izašlih iz tačke 11.1. Procenti se računaju iz zbirova, ne kao prosek procenata biračkih mesta. U numeričkim kolonama su razmere 0–1, a na slici su zaokružene na ceo procenat.
4. Zadržano je staro ime kolone `num_votes_opposition` radi kompatibilnosti. Ona ovde znači sve važeće glasove za preostalih 16 lista, bez tvrdnje da su sve te liste opozicione. Isti broj je u jasnije nazvanoj koloni `num_votes_other_lists`.
5. Mesta su povezana po `unique_id`, odnosno po opštini i broju biračkog mesta. Užičko i sevojničko BM sa istim brojem su različiti redovi.
6. Užička BM 53 i 54 prebačena su iz „Росуље“ u „Пора“, prema korisnikovom zahtevu i napomeni da su objekti na Pori. Izvorna oblast i napomena ostaju u detaljnom datasetu. Druga mapiranja su preuzeta bez izmene.
7. Kose crte i prazna polja u kolonama glasova za liste tumačeni su kao bez glasova kada to odgovara kompletnom zapisu i zbiru važećih listića. Prazno polje sa brojem upisanih birača nije pretvoreno u nulu.

## Obuhvat i dopune

Naknadno dostavljeni zapisnici za UZ-66 i SE-05 uključeni su 31.10.2026. Sada su obuhvaćena **sva 89 biračka mesta**, odnosno svih 35 područja. Царина obuhvata 6 od 6 BM, a Севојно 5 od 5 BM. Oznake nepotpunosti uklonjene su sa dijagrama.

| Mesto | Izvor rezultata, strana 1 | Upisani | Izašli | Važeći | Nevažeći | Lista 1 | Lista 2 |
|---|---|---:|---:|---:|---:|---:|---:|
| UZ-66, Царина | `@ПА 66_80932a0360dc53d13061657faa272793.pdf` | 1.060 | 843 | 835 | 8 | 306 | 5 |
| SE-05, Севојно | `@ПА 5 СЕВОЈНО_c8890c359b46ab4db9f86c9314c6c4bf.pdf` | 761 | 619 | 619 | 0 | 259 | 15 |

Kod SE-05 crta u polju nevažećih listića označava nulu; broj važećih i zbir glasova svih lista su 619. Ranije dostavljeni RG-11 o posmatračima ostaje evidentiran kao prilog.

Za UZ-05 (Стрмац & Радуша), prazno polje iz izvornog PDF-a dopunjeno je brojem **387** prema podatku korisnika. Zbir lista 1 i 2 je 124, pa je procenat od upisanih **124 / 387 = 32,04%**, odnosno **32%** na dijagramu. Procenat od izašlih ostaje **124 / 267 = 46,44%**, odnosno **46%**. Sirova transkripcija PDF-a zadržava prvobitni `NA`; skripta primenjuje dokumentovanu dopunu pre generisanja detaljnog dataset-a.

Kolone `results_complete`, `num_polling_stations_expected`, `num_polling_stations_with_results` i `missing_polling_station_ids` u zbirnom datasetu opisuju obuhvat. Za svih 35 područja `results_complete` i `registered_voters_complete_for_available_results` sada imaju vrednost `TRUE`, a liste nedostajućih mesta su prazne.

## Primena ispravki i primedbi

- **UZ-75:** rešenje RG-7/NP2026-2 od 26.10.2026. menja glasove liste 1 sa 176 na **177**. RG-3 opisuje istu grešku. Konačni zbir glasova lista je 651 i odgovara važećim listićima.
- **UZ-80:** rešenje RG-7/NP2026-2 od 26.10.2026. menja glasove liste 4 sa 4 na **1**. RG-3 opisuje istu grešku. Konačni zbir je 598 i odgovara važećim listićima. Glasovi lista 1 i 2 ostaju 223 i 9.
- Sačuvane su vidljive konačne ručne prepravke na samim zapisnicima. Napomene su dodate za BM 8, 46, 49, 55, 58 i 77. Kod BM 49 precrtana dvojka za listu 10 tretirana je kao nula prema konačnoj oznaci.
- Pregledane su posebne primedbe za UZ-40, UZ-63, UZ-71, UZ-72 i SE-04, kao i RG-11 za SE-03 i SE-05. Ti prilozi ne daju zamenske brojčane rezultate. Primedbe same po sebi nisu korišćene za oduzimanje glasova, promenu rezultata ili proglašenje glasanja poništenim. Nazivi priloga sačuvani su u `additional_pdfs`.
- Izvorni brojevi za liste 1 i 4, pre formalnih ispravki za BM 75 i 80, sačuvani su u `original_votes_list_01` i `original_votes_list_04`. Te kolone nisu potpuna transkripcija svih precrtanih rukopisnih vrednosti.

## Provere

Za svih **89** zapisnika, posle navedenih ispravki i dopuna:

- zbir svih 18 lista jednak je broju važećih listića;
- važeći plus nevažeći listići jednaki su broju listića u kutiji;
- zbir podataka po područjima odgovara zbiru podataka po biračkim mestima;
- UZ-53 i UZ-54 pripadaju Pori;
- UZ-66 i SE-05 koriste rezultate iz naknadno dostavljenih zapisnika;
- svih 89 mesta ima rezultate i broj upisanih birača, uz dokumentovanu dopunu korisnika za UZ-05.

Kontrolni zbir za sva mesta: lista 1 **16.575**, lista 2 **753**, njihov zbir **17.328**, sve liste **47.762**, nevažeći listići **436**, listići u kutiji **48.198**, izašli **48.205**.

Razlike između tačaka 11.1 i 11.2 ostavljene su kako su upisane u izvoru:

| Mesto | Izašli | Listići u kutiji | Razlika |
|---|---:|---:|---:|
| UZ-46 | 663 | 665 | -2 |
| UZ-53 | 1.093 | 1.091 | 2 |
| UZ-58 | 921 | 919 | 2 |
| UZ-77 | 1.023 | 1.020 | 3 |
| UZ-82 | 1.062 | 1.060 | 2 |

UZ-46 ima ručnu prepravku broja izašlih sa 665 na 663 i napomenu o potpisima. Ova obrada čuva vidljivi konačni upis i ne donosi zaključak o ispravnosti postupka.

R skripta je izvršena u R 4.3.2 uz pakete `ggplot2`, `ggtext` i `ragg`. PNG je vizuelno pregledan.

## Ponovno generisanje

Iz PowerShell-a:

```powershell
& 'C:\Program Files\R\R-4.3.2\bin\Rscript.exe' 'D:\izbori2026\skripta_izbori_2026.R'
```

R skripta pronalazi ulazni CSV pored sebe, nezavisno od trenutnog radnog foldera. Moguće je i `source('D:/izbori2026/skripta_izbori_2026.R', encoding='UTF-8')` iz R-a. CSV fajlovi koriste zarez kao separator, a tačku kao decimalni separator.

U `obrada_2026` sačuvani su vizuelna transkripcija (`transkripcija.txt`), dopuna korisnika (`user_overrides.json`), kopija mapiranja u JSON-u, skripta koja od njih pravi detaljni CSV i manifest svih izvornih PDF-ova sa SHA-256 otiscima. Originalni PDF-ovi, Excel mapiranje i prethodni dataset, R skripta i dijagram nisu menjani.
