# Nettoyage des residus OCR ( deuxieme serie, 68 sens revus en contexte )
# et des templates wiki casses du it. Wiktionary ( {Term|...}} -> etiquette
# textuelle ). Usage : clean_ocr2.py workshop.db [--ecrire]
# SPDX-License-Identifier : MIT
import sqlite3, sys, re

# --- 1. residus OCR : remplacements mot a mot, revus en contexte ---
OCR_FIX = [
    # allemand ( Sanders 1876, OCR maison )
    ('Sanders 1876', 'am Sc<luß', 'am Schluß'),
    ('Sanders 1876', 'klesen, f. kle>en, Anm. Kleße, f',
     'klesen, f. kleßen, Anm. Kleße, f'),
    ('Sanders 1876', 'zähneble>kend', 'zähnebleckend'),
    ('Sanders 1876', 'das ju>ende', 'das juckende'),
    ('Sanders 1876', 'erstre>en', 'erstrecken'),
    ('Sanders 1876', 's<hwächen', 'schwächen'),
    ('Sanders 1876', 'gesc<hwäc<t', 'geschwächt'),
    ('Sanders 1876', 'be- oder verde>en', 'be- oder verdecken'),
    ('Sanders 1876', 's<hwach und ungesund', 'schwach und ungesund'),
    ('Sanders 1876', 'Pie>d-Böller', 'Piek-Böller'),
    ('Sanders 1876', 'drücend biegen', 'drückend biegen'),
    ('Sanders 1876', 'vgl. du>en', 'vgl. ducken'),
    # italien ( Petrocchi 1887, OCR archive.org )
    ('Petrocchi 1887', 'St>atter con forza.', 'Sbattere con forza.'),
    ('Petrocchi 1887', '{ini.." Rampognaci, ^^.r rampogne.',
     'Rampognare, v. rampogne.'),
    ('Petrocchi 1887', "{Il popolo non l'adopra molto, ma non lo fugge).",
     "(Il popolo non l'adopra molto, ma non lo fugge)."),
    ('Petrocchi 1887', 'Maneggiare, Trattai<e un affare.',
     'Maneggiare, Trattare un affare.'),
    ('Petrocchi 1887', "[S'umilia Y>e>v S'umilia\\.", "S'umilia, v. S'umilia."),
    ('Petrocchi 1887',
     "usata solo in pochi tempi {attuavo attuassi, raro attuo; più attui) "
     "dai filojofi e in mat( rie d'amministrazione.",
     "usata solo in pochi tempi (attuavo attuassi, raro attuo; più attui) "
     "dai filosofi e in materie d'amministrazione."),
    ('Petrocchi 1887', 'lett., di coltello 2}ere.', 'lett., di coltello.'),
    ('Petrocchi 1887', 'nef;li scritti', 'negli scritti'),
    ('Petrocchi 1887', "'Riemi>ive, Saldar con piombo.",
     'Riempitive, Saldar con piombo.'),
    ('Petrocchi 1887', 'gasta,rne meglio', 'gustarne meglio'),
    # polonais ( Slownik warszawski 1900, OCR degrades )
    ('Słownik warszawski 1900', 'ywal I. ^podpowiadać, podszeptywać.',
     'podpowiadać, podszeptywać.'),
    ('Słownik warszawski 1900', 'f komu = (/a<f rewanż.',
     'komu = odgrać rewanż.'),
    ('Słownik warszawski 1900',
     'Egzmitować wyrzucać z posiadłości, z mie<kania na mocy wyroku s idowego.',
     'Egzmitować wyrzucać z posiadłości, z mieszkania na mocy wyroku sądowego.'),
    ('Słownik warszawski 1900', "czego w {'() = 7iairi>ychać, nalkać, nawhijać.",
     'czego w coś = napychać, nabijać, nawijać.'),
    ('Słownik warszawski 1900',
     'ś., al ś., tNadprzykrzać Ś.,.\'Naprzykrzać komu {nied.) = sprawiać '
     'j>rzykrość swoim natręctwem.',
     'Naprzykrzać komu (nied.) = sprawiać przykrość swoim natręctwem.'),
    ('Słownik warszawski 1900',
     'ił I. j>rzyniewalać, zmuszać, przymuszać, musić, przynaglać.',
     'przyniewalać, zmuszać, przymuszać, musić, przynaglać.'),
    ('Słownik warszawski 1900',
     '\\io^o = polatać komuid>ra}iie ze wszystkich stron.',
     'kogo = polatać, obiegać ze wszystkich stron.'),
    ('Słownik warszawski 1900', 'odstrychn<ić ś.', 'odstrzygnąć ś.'),
    ('Słownik warszawski 1900', 'rzucić napowrót, oddać, rzuciwi<zij.',
     'rzucić napowrót, oddać.'),
    ('Słownik warszawski 1900', 'loróció, za:wrócić, cofnąć.',
     'obrócić, zawrócić, cofnąć.'),
    ('Słownik warszawski 1900',
     'oznaczyć czemu Icres, ograniczyć, nst(dić granice;.yirowadzić, '
     'zredul:ować co do peuuiych rozmiarów, uj(ić w granice.',
     'oznaczyć czemu kres, ograniczyć, ująć w granice.'),
    ('Słownik warszawski 1900',
     'nj(ić powabem, złudzić, zająć, j)rzynQcić, olśnić, i<knsić, '
     'poci(i(jiiąć ku.tobie ponętą.',
     'omamić powabem, złudzić, zająć, olśnić, pociągnąć ku sobie ponętą.'),
    ('Słownik warszawski 1900',
     'co = zrobić porządek koło czego, obrządzić; wyporz<idzić, '
     'p)rzyprowadzić do porządku, wyszykować, narządzić, wyrychtować.',
     'co = zrobić porządek koło czego, obrządzić; wyporządzić, przyprowadzić '
     'do porządku, wyszykować, narządzić, wyrychtować.'),
    ('Słownik warszawski 1900', 'siiiijdc, owintić, oshi!ii(^, otoczyć; ojrrziiść.',
     'snuć, owinąć, otoczyć.'),
    ('Słownik warszawski 1900',
     'osIji- <)n<ić,?cskórać, odnieść co, dostąpić czego.',
     'odnieść co, dostąpić czego.'),
    ('Słownik warszawski 1900', 'fO. o</łt>sić, opowiedzieć.',
     'ogłosić, opowiedzieć.'),
    ('Słownik warszawski 1900',
     'spędzić jiewien czas na baiowaiiiii, pobawić ś., j>ohnlać.',
     'spędzić pewien czas na balowaniu, pobawić ś.'),
    ('Słownik warszawski 1900',
     'dejmie, djąl, {.paduieść, unieść, wznieść, dźwignąć.',
     'podnieść, unieść, wznieść, dźwignąć.'),
    ('Słownik warszawski 1900',
     'fP. })odsadzić, podstawić, skierować, zwi-ócić, wymierzyć, '
     'wycelować pod co.',
     'podsadzić, podstawić, skierować, zwrócić, wymierzyć, wycelować pod co.'),
    ('Słownik warszawski 1900',
     'kpić wciąż, kpić potrosze, p>dkpiioać, podrwiwać, przekpiwać, przedrwiwać.',
     'kpić wciąż, kpić po trochu, podokpiwać, podrwiwać, przekpiwać, przedrwiwać.'),
    ('Słownik warszawski 1900', 'IV.\\ })ójść piecliotą, pomaszerować.',
     'pójść piechotą, pomaszerować.'),
    ('Słownik warszawski 1900', 'karty tasujiir poinicxz<ii\\ przcnticsziir.',
     'karty tasując pomieszać, przetasować.'),
    ('Słownik warszawski 1900',
     'tłopió jedno po drugim, poroztapiać, j>orozpu:i:,czać.',
     'topiąc jedno po drugim, poroztapiać, porozpuszczać.'),
    ('Słownik warszawski 1900',
     'przerżnąć, }>rzekoj)ać, przeryć pługiem, rozorać przez środek.',
     'przerżnąć, przekopać, przeryć pługiem, rozorać przez środek.'),
    ('Słownik warszawski 1900',
     'ał platnąwszy rozdzielić; rozćwiertov:ać, rozciąć, rozchlastać, '
     'rozpróć, rozwalić, przepołowić.',
     'rozpłaciwszy rozdzielić; rozćwiartować, rozciąć, rozchlastać, '
     'rozwalić, przepołowić.'),
    ('Słownik warszawski 1900', '[Sce!ić|, Scalkować, nied.',
     'scalować, nied.'),
    ('Słownik warszawski 1900', 'wykonywać sekwestr, z<tjmowar mienie na skarb.',
     'wykonywać sekwestr, zajmować mienie na skarb.'),
    ('Słownik warszawski 1900', '\\. Jabrykuj<ic zrobić; skonstruować.',
     'fabrykując zrobić; skonstruować.'),
    ('Słownik warszawski 1900', 'owaJ złożyć w całość z<i pomoc({ klnsi//jfc(tcjt.',
     'klasując złożyć w całość z pomocą klasyfikacji.'),
    ('Słownik warszawski 1900', 'zmiarkować, spo<trzec ś.',
     'zmiarkować, spostrzec ś.'),
    ('Słownik warszawski 1900',
     '(o państwie) ubezpieczyć papiery iiu\'dic:ne na dochoduch jiaństwowych.',
     '(o państwie) ubezpieczyć papiery na dochodach państwowych.'),
    ('Słownik warszawski 1900', 'płyn -kłócąc zmieszać; wzrusiyć, zm<tcić, zbełtać.',
     'płyn skłócąc zmieszać; wzruszyć, zmącić, zbełtać.'),
    ('Słownik warszawski 1900',
     'ii I. ulec strucie, /><iiiieśr stratę, znstiić /)o:liiiiriimi/in kngo, cziffo.',
     'ulec stracie, ponieść stratę.'),
    ('Słownik warszawski 1900',
     'eje, al st>npieć, obumrzeć, zmartwieć, zgrzybieć; zmurszeć, spróchnieć, '
     'stracić żywotność.',
     'stępieć, obumrzeć, zmartwieć, zgrzybieć; zmurszeć, spróchnieć, '
     'stracić żywotność.'),
    ('Słownik warszawski 1900', '\\}.\\ zrobić, uczynić.', 'zrobić, uczynić.'),
    ('Słownik warszawski 1900',
     'W. na kogo, na kark czy} = nasiąlć go, przypiąć ś.',
     'na kogo, na kark czyj = nasiąść go, przypiąć ś.'),
    ('Słownik warszawski 1900',
     '^ogo =^ badając wysłuchać; wyegzamino>cać, zbadać na wszelkie sposoby, '
     'icypytać, wymacać, nied.',
     'kogo = badając wysłuchać; wyegzaminować, zbadać na wszelkie sposoby, '
     'wypytać, wymacać, nied.'),
    ('Słownik warszawski 1900', 'v}ybić w drukami, wytłoczyć.',
     'wybić w drukarni, wytłoczyć.'),
    ('Słownik warszawski 1900',
     'Wypromowować kogo =proł7iując wynieść, wyprowadzić na icyżs:e '
     'litnnoluii^ko, wyprotegować, wyforytować; wykierować, pokierować, '
     'wykształcić.',
     'kogo = promując wynieść, wyprowadzić, wyprotegować, wyforytować; '
     'wykierować, pokierować, wykształcić.'),
    ('Słownik warszawski 1900', 'odz<iaczyć', 'odznaczyć'),
    ('Słownik warszawski 1900',
     'Zadawalać uczynić zadość woli czyjej, zrobić toedług woli czyje/, '
     'dogodzić, ukonlentoiuać, sprawić ukontentowanie, satysfakcję, '
     'odpowiedzieć t:zyi)ii wymaganiom, (o rzeczach) przypaść do serca, '
     'trafić do przekonania.',
     'Zadawalać uczynić zadość woli czyjej, zrobić według woli czyjej, '
     'dogodzić, ukontentować, sprawić ukontentowanie, satysfakcję, '
     'odpowiedzieć czyim wymaganiom, (o rzeczach) przypaść do serca, '
     'trafić do przekonania.'),
    ('Słownik warszawski 1900',
     'komu kogo = sprzedać na zupełną własność, sprzedawszy zatracić, '
     'zagubić} wydać za pieniądze.',
     'komu kogo = sprzedać na zupełną własność, sprzedawszy zatracić, '
     'zagubić, wydać za pieniądze.'),
    ('Słownik warszawski 1900',
     'Zaścielać ścieląc założyć, zakryć, z<ii\'{ć, zupełnie; wysłać; '
     'Z, łoże kobiercem, pokój.',
     'Zaścielać ścieląc założyć, zakryć, zasłać; wysłać łóżko kobiercem, '
     'pokój.'),
    ('Słownik warszawski 1900',
     'owat, poduszczyć do niesubordynacji, pobudzić do buntu, zrewoltować, '
     'zrev:oluc jonizować.',
     'buntować, poduszczyć do niesubordynacji, pobudzić do buntu, zrewoltować, '
     'zrewolucjonizować.'),
    ('Słownik warszawski 1900', 'ładując na<iromadzić do kupy, spakować.',
     'ładując nagromadzić do kupy, spakować.'),
    # anglais ( glossaire angl. Wiktionary, ligature ae codee en a<eum/ )
    ('Webster 1913', 're<eum/xamination of for decision.',
     'reëxamination or for decision.'),
    ('Webster 1913', 'for re<eum/xamination or review.',
     'for reëxamination or review.'),
    ('Webster 1913', 'an a<eum/rocurve, or the like.',
     'an aerocurve, or the like.'),
]

RE_TERM = re.compile(r'\{(?:Term|Glossa)\|([^{}]*?)\}\}')
RE_EST = re.compile(r'\{Est\}\}')
RE_FIG = re.compile(r'\{Fig\}\}')
RE_NODEF = re.compile(r'\{Nodef\|[^{}]*\}\}')
TYPO_TERM = {
    'religine': 'religione',
    'gotografia': 'fotografia',
    'anrivo': 'antico',
    'me': 'medicina',
}
RE_DESPACE = re.compile(r'  +')

def nettoie_it(t):
    def rep(m):
        lab = m.group(1).strip()
        lab = re.sub(r'\|(?:it)?$', '', lab).strip()
        lab = TYPO_TERM.get(lab, lab)
        if not lab:
            return ''
        return '(%s) ' % lab
    t = RE_TERM.sub(rep, t)
    t = RE_EST.sub('(esteso) ', t)
    t = RE_FIG.sub('(figurato) ', t)
    t = RE_NODEF.sub('senza definizione', t)
    t = RE_DESPACE.sub(' ', t).strip()
    return t

def main():
    ecrire = '--ecrire' in sys.argv
    db = sqlite3.connect([a for a in sys.argv[1:] if not a.startswith('--')][0])
    total = 0
    # 1. residus OCR
    for source in ('Sanders 1876', 'Petrocchi 1887',
                   'Słownik warszawski 1900', 'Webster 1913'):
        if source == 'Webster 1913':
            # en realite 3 sens du glossaire angl. Wiktionary ( ligature
            # 'ae' codee en 'a<eum/' par l'extraction kaikki )
            cond = ("langue='en' AND id_source=1 AND texte LIKE '%<eum%'")
        else:
            cond = 'etiquette=%s' % repr(source)
        rows = dict(db.execute(
            'SELECT rowid, texte FROM defs WHERE ' + cond))
        n = 0
        for src, old, new in OCR_FIX:
            if src != source:
                continue
            hits = [rid for rid, t in rows.items() if old in t]
            if len(hits) != 1:
                print('!! %-22s %r : %d occurrence(s)' % (source, old[:40], len(hits)))
                continue
            rid = hits[0]
            rows[rid] = rows[rid].replace(old, new)
            n += 1
            if ecrire:
                db.execute('UPDATE defs SET texte=? WHERE rowid=?',
                           (rows[rid], rid))
        print('%-22s : %d sens corriges' % (source, n))
        total += n
    # 2. templates it. Wiktionary
    n = 0
    for rid, t in db.execute(
            "SELECT rowid, texte FROM defs WHERE langue='it' "
            "AND etiquette='it. Wiktionary'"):
        if '{' in t:
            new = nettoie_it(t)
            if new != t:
                n += 1
                if ecrire:
                    db.execute('UPDATE defs SET texte=? WHERE rowid=?',
                               (new, rid))
    print('%-22s : %d gloses normalisees ( templates )' % ('it. Wiktionary', n))
    total += n
    if ecrire:
        db.commit()
    # controle : plus aucun template ni residu
    rest = db.execute(
        "SELECT count(*) FROM defs WHERE langue='it' AND etiquette='it. Wiktionary' "
        "AND texte LIKE '%{%'").fetchone()[0]
    print('it. Wiktionary restant avec accolades :', rest)
    print('total : %d, mode : %s' % (total, 'ECRITURE' if ecrire else 'lecture seule'))
    db.close()

if __name__ == '__main__':
    main()
