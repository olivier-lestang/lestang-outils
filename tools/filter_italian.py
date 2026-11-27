#!/usr/bin/env python3
"""Remplace les glossaires anglais Wiktionary (CC BY-SA) des verbes
italiens du générateur Wiktionary par les sens de dictionnaires du domaine
public (« Nòvo dizionàrio universale » de Petrocchi, 1887/1912 ; « Dizionario
della lingua italiana » de la Crusca, éd. Costa-Cardinali, 1819) et retire
les verbes définis par aucun des deux.

Usage : python3 filter_italian.py raw.json petrocchi_verbes.json \
           crusca_verbes.json brut2.json
"""
import json
import re
import sys
import unicodedata

MAX_SENS = 3     # sens conservés par verbe
MAX_CAR = 280    # caractères par sens
COUPE = re.compile(r'\s(?:Lat\.|Gr\.)\s')          # citations étymologiques
COUPE2 = re.compile(r'\s§\s')                        # sous-sens
CITATION = re.compile(r'\s(?:Lat|Gr)\.[^.]{0,40}\.')


def canon(v: str) -> str:
    v = unicodedata.normalize('NFD', v)
    v = ''.join(c for c in v if unicodedata.category(c) != 'Mn')
    v = v.lower()
    v = re.sub(r'([a-z])\1+', r'\1', v)   # consonnes/voyelles doublées
    return v


def nettoie_sens(s: str) -> str:
    s = COUPE.split(s)[0]
    s = COUPE2.split(s)[0]
    return s.strip(' ;.,')[:MAX_CAR].strip(' ;.,')


def main():
    src, pet_src, cru_src, dst = sys.argv[1:5]
    brut = json.load(open(src, encoding='utf-8'))
    pet = json.load(open(pet_src, encoding='utf-8'))
    cru = json.load(open(cru_src, encoding='utf-8'))

    petc, cruc = {}, {}
    for k, sens in pet.items():
        petc.setdefault(canon(k), []).extend(sens)
    for k, sens in cru.items():
        cruc.setdefault(canon(k), []).extend(sens)

    tokens = [t for t in re.split(r'[,\n]', brut['IT_VERBS_STR']) if t]
    defs = [e for e in brut['IT_DEFS_STR'].split('\x02') if e]
    wikt = set(brut['IT_VSRC_STR'].split('\n')) - {''}

    rempl, retires, rempl_crusca = 0, 0, 0
    nv_tokens, nv_defs = [], []
    for t in tokens:
        v = t.split(':')[0]
        if v not in wikt:
            nv_tokens.append(t)  # verbes maison : intouchables
        elif canon(v) in petc:
            sens = [nettoie_sens(s) for s in petc[canon(v)]]
            sens = [s for s in sens if len(s) > 3][:MAX_SENS]
            nv_defs.append(v + '\x01' + '\x03'.join(
                'Petrocchi 1887\x04' + s for s in sens))
            nv_tokens.append(t)
            rempl += 1
        elif canon(v) in cruc:
            sens = [nettoie_sens(s) for s in cruc[canon(v)]]
            sens = [s for s in sens if len(s) > 3][:MAX_SENS]
            nv_defs.append(v + '\x01' + '\x03'.join(
                'Crusca 1819\x04' + s for s in sens))
            nv_tokens.append(t)
            rempl_crusca += 1
        else:
            retires += 1

    garde = set(t.split(':')[0] for t in nv_tokens)
    for e in defs:
        v = e.split('\x01', 1)[0]
        if v in garde and v not in wikt:
            nv_defs.append(e)

    brut['IT_VERBS_STR'] = '\n'.join(nv_tokens)
    brut['IT_DEFS_STR'] = '\x02'.join(nv_defs)
    brut['IT_VSRC_STR'] = '\n'.join(
        v for v in brut['IT_VSRC_STR'].split('\n')
        if v and v in garde)
    json.dump(brut, open(dst, 'w', encoding='utf-8'), ensure_ascii=False)

    print('verbes IT :', len(nv_tokens))
    print('définitions Petrocchi :', rempl, '| Crusca :', rempl_crusca)
    print('verbes retirés :', retires)
    dd = set(e.split('\x01', 1)[0] for e in nv_defs)
    vv = set(t.split(':')[0] for t in nv_tokens)
    print('sans définition :', len(vv - dd))
    print('OK')


if __name__ == '__main__':
    main()
