#!/usr/bin/env python3
# Nettoyage du bruit des defs Sanders du lot 42 (version 1.5.62 -> 1.5.63)
import sqlite3, sys

DB = '/home/user/w/lot42/outils/workshop.db'
ECRIRE = '--ecrire' in sys.argv

# (verbe, [rangs a supprimer])
SUPPR = {
 'arbeiten': [7],
 'aufgeben': [5, 6],
 'backen': [4],
 'beeinflussen': [4],
 'beizen': [6],
 'bestätigen': [6],
 'beten': [6, 8, 10],
 'betteln': [6],
 'beulen': [4],
 'beuteln': [4],
 'bischen': [4, 5],
 'bitten': [4, 6, 7],
 'blassen': [4],
 'bräteln': [4],
 'bäumen': [4, 5],
 'bündeln': [5],
 'bürgen': [4, 5, 6],
 'dampfen': [9],
 'denken': [5],
 'dingen': [5],
 'diskutieren': [5, 6, 7, 8],
 'drücken': [5, 7, 10],
 'dämmen': [8],
 'ehren': [8],
 'eichen': [3, 4],
 'erben': [4],
 'erzen': [5, 6, 7],
 'fesseln': [4],
 'fischen': [4, 5, 6, 7, 8, 9],
 'flammen': [4],
 'fletschen': [2, 3],
 'gaffen': [6, 7, 8, 9],
 'gießen': [8],
 'glauben': [6, 7, 8, 9],
 'glücken': [4, 5, 6, 7, 8],
 'gründen': [6, 8],
 'grünen': [5],
 'gönnen': [4],
 'haaren': [3, 4, 5, 6],
 'halten': [5, 6, 7, 8, 9, 10],
 'handeln': [8],
 'hellen': [4, 5, 6],
 'hören': [5],
 'hüllen': [5, 6],
 'kirren': [4],
 'klauen': [4, 5],
 'klemmen': [4, 5],
 'knebeln': [5, 6],
 'kranken': [6, 7, 8, 9],
 'kreisen': [5, 6],
 'kribbeln': [5, 6, 7, 8, 9],
 'krächzen': [],
 'kreischen': [7],
 'kugeln': [4, 5, 6, 7, 8],
 'kennen': [5],
 'keilen': [5],
 'küren': [5],
 'lecken': [6],
 'löffeln': [6],
 'längen': [5],
 'mähen': [4],
 'mehren': [5],
 'mögen': [5, 6, 7, 8],
 'narren': [4],
 'nebeln': [6],
 'nähen': [4, 5, 6],
 'nässen': [5],
 'ordnen': [5, 6, 7],
 'pichen': [2],
 'piepen': [3, 4, 5, 6],
 'pinkeln': [5, 6],
 'pressen': [4],
 'prallen': [4],
 'prellen': [5],
 'prügeln': [6],
 'quälen': [5, 6, 7, 8, 9],
 'regeln': [6],
 'reisen': [5],
 'reuen': [4, 6, 7],
 'riechen': [5],
 'rucken': [4],
 'rühren': [4, 5, 6],
 'salzen': [4],
 'sammeln': [5],
 'schallen': [5],
 'schiffen': [4, 5],
 'schluchzen': [4],
 'schmerzen': [4, 5, 6, 7, 8, 9],
 'schnallen': [5, 6],
 'schneiden': [5],
 'schneien': [5, 6],
 'schonen': [4, 6, 7, 8],
 'schrammen': [4, 5, 6],
 'schulen': [4],
 'schweben': [4, 5, 6],
 'schälen': [4, 5, 6],
 'schäumen': [5],
 'schöpfen': [4, 5, 7],
 'sehen': [7, 8],
 'sohlen': [4, 5, 6, 7, 8],
 'speisen': [4, 5, 6, 7],
 'spielen': [5, 6],
 'spinnen': [6],
 'sprechen': [5],
 'spülen': [7, 8],
 'stammen': [7],
 'staunen': [4, 5, 6, 7, 8],
 'stellen': [5, 6, 7, 8, 9],
 'stiefeln': [4],
 'stopfen': [4],
 'streifen': [5, 6],
 'studieren': [5],
 'toben': [7],
 'trommeln': [5, 6, 7],
 'tropfen': [4, 5],
 'tönen': [4, 5],
 'unken': [4],
 'verlangen': [4, 5, 6, 7],
 'verpönen': [5, 6, 7],
 'vögeln': [4, 5, 6, 7, 8],
 'wagen': [4],
 'wanken': [4, 5],
 'waschen': [5],
 'wellen': [4, 5, 6, 7, 8, 9],
 'werfen': [5, 7],
 'winken': [4],
 'wissen': [5, 6, 7, 8, 9],
 'wogen': [4],
 'wählen': [5, 6],
 'wünschen': [4, 5],
 'zahlen': [5, 6, 7, 8, 9, 10],
 'zapfen': [4],
 'zeichnen': [7, 8, 9],
 'zerren': [4, 5],
 'zetteln': [7],
 'zeugen': [4, 5, 6],
 'ziehen': [5, 6, 7, 8],
 'zweifeln': [4],
 'zücken': [6],
 'zürnen': [4],
 'häufeln': [5],
 'kasteien': [4, 5],
 'kappen': [5, 6, 7],
 'kargen': [5],
 'lächeln': [4],
 'löcken': [5, 6, 7, 8],
}

# (verbe, rang, nouveau texte) : sens gardes mais rewrites
EDIT = {
 ('diskutieren', 4): 'erörtern, in wissenschaftlichem Streit erörtern',
 ('lüpfen', 4): 'jäh in die Höhe heben',
 ('erzen', 4): 'zu Erz machen, in Erz verwandeln; veralt.: geerzt = ehern, bronzieren',
 ('reimen', 4): 'Etwas mit einander in Einklang bringen, einen vereinigenden Zusammenhang finden und begreifen; refl.: sich reimen; intr.: s. rainen',
 ('ringeln', 4): 'mit Ringeln versehen; Forstw., Gärtn.: Bäume ringeln (oder ringen), von der Rinde durch Einschnitte Ringel abschälen',
 ('kröpfen', 1): 'Vögel kröpfen, fressen, stopfen (Weidm.); Forstw.: Einen Baum kröpfen, kappen, köpfen',
 ('löcken', 4): 'tr. und refl.: in Locken legen, z. B. die Perücke; oft im Partic.: gelocket = lockig',
}

# sens ajoutes (verbe, rang, texte)
AJOUT = [
 ('kröpfen', 2, 'intr. (haben): weidm.: von Raubvögeln, nam. vom Falken = fressen; von Bäumen: einen Kropf bekommen'),
]

def main():
    c = sqlite3.connect(DB)
    ndel = 0
    nedit = 0
    # verif que tout existe
    for v, rangs in SUPPR.items():
        for rg in rangs:
            r = c.execute("select texte from defs where langue='de' and verbe=? and rang=? and etiquette='Sanders 1876' and date_ajout='2026-11-27'", (v, rg)).fetchone()
            if not r:
                print(f"ABSENT: {v} rang {rg}")
            else:
                ndel += 1
                if ECRIRE:
                    c.execute("delete from defs where langue='de' and verbe=? and rang=? and etiquette='Sanders 1876' and date_ajout='2026-11-27'", (v, rg))
    for (v, rg), t in EDIT.items():
        r = c.execute("select texte from defs where langue='de' and verbe=? and rang=? and etiquette='Sanders 1876'", (v, rg)).fetchone()
        if not r:
            print(f"EDIT ABSENT: {v} rang {rg}")
        else:
            nedit += 1
            if ECRIRE:
                c.execute("update defs set texte=? where langue='de' and verbe=? and rang=? and etiquette='Sanders 1876'", (t, v, rg))
    for v, rg, t in AJOUT:
        if ECRIRE:
            pos = c.execute("select MIN(pos) from defs where langue='de' and verbe=?", (v,)).fetchone()[0]
            c.execute("insert into defs (langue, pos, rang, verbe, etiquette, texte, id_source, date_ajout) values ('de', ?, ?, ?, 'Sanders 1876', ?, 15, '2026-11-27')", (pos, rg, v, t))
    print(f"sens a supprimer: {ndel}, edits: {nedit}")
    # pas de renumerotation : le rang peut avoir des trous (cle unique langue+pos+rang),
    # et le blob est regenere sur l'ordre pos,rang, les trous sont sans effet.
    verbes_touches = set(list(SUPPR.keys()) + [x[0] for x in EDIT] + [a[0] for a in AJOUT])
    for v in sorted(verbes_touches):
        rows = list(c.execute("select rang from defs where langue='de' and verbe=? order by rang", (v,)))
        if ECRIRE and rows:
            gaps = [i for i in range(1, len(rows)+1) if i not in [r[0] for r in rows]]
            print(f"{v}: rangs restants {[r[0] for r in rows]}")
    # verifie: aucun verbe de sans def
    zero = list(c.execute("select distinct v.verbe from verbes v where v.langue='de' and not exists (select 1 from defs d where d.langue='de' and d.verbe=v.verbe)"))
    print("verbes de sans aucune def:", [z[0] for z in zero][:30], len(zero))
    if ECRIRE:
        c.commit()
        n = c.execute("select count(*) from defs").fetchone()[0]
        ns = c.execute("select count(*) from defs where langue='de' and etiquette='Sanders 1876' and date_ajout='2026-11-27'").fetchone()[0]
        print(f"ecrit. defs total {n}, sens Sanders du 27-11: {ns}")

main()
