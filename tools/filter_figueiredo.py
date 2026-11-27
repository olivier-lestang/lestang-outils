#!/usr/bin/env python3
"""Remplace les définitions Wiktionary (CC BY-SA) du portugais par les sens
du « Novo Diccionario da Lingua Portugueza » de Cândido de Figueiredo
(1913, domaine public) et retire les verbes sans définition.

Usage : python3 filter_figueiredo.py raw.json figueiredo_verbes.json brut2.json
"""
import json
import re
import sys
import unicodedata

NATURE = 'Figueiredo 1913'
MAX_SENS = 4          # sens conservés par verbe
MAX_CAR = 300         # caractères par sens


def canon(v: str) -> str:
    v = unicodedata.normalize('NFD', v.replace('ç', 'c'))
    v = ''.join(c for c in v if unicodedata.category(c) != 'Mn')
    v = v.replace('ph', 'f').replace('th', 't').replace('y', 'i')
    # orthographe de 1913 : « c » épicène (objectar/objectar, acção/ação)
    v = v.replace('ct', 't')
    v = re.sub(r'([bcdfghjklmnpqrstvwz])\1+', r'\1', v)
    return v


def main():
    src, fig_src, dst = sys.argv[1], sys.argv[2], sys.argv[3]
    brut = json.load(open(src, encoding='utf-8'))
    fig = json.load(open(fig_src, encoding='utf-8'))

    # index canon -> sens
    figc: dict = {}
    for k, sens in fig.items():
        figc.setdefault(canon(k), []).extend(sens)

    # état actuel
    tokens = [t for t in re.split(r'[,\n]', brut['PT_VERBS_STR']) if t]
    defs = [e for e in brut['PT_DEFS_STR'].split('\x02') if e]
    wikt = set(brut['PT_VSRC_STR'].split('\n')) - {''}

    rempl, retires = 0, 0
    nv_tokens, nv_defs = [], []
    for t in tokens:
        v = t.split(':')[0]
        if v not in wikt:
            nv_tokens.append(t)  # verbes maison : intouchables
        elif canon(v) in figc:
            sens = [s[:MAX_CAR].strip(' ;.,') for s in figc[canon(v)]]
            sens = [s for s in sens if len(s) > 3][:MAX_SENS]
            if sens:
                nv_et = v + '\x01' + '\x03'.join(
                    NATURE + '\x04' + s for s in sens)
                nv_defs.append(nv_et)
                nv_tokens.append(t)
                rempl += 1
                continue
            retires += 1
        else:
            retires += 1
    # définitions : remplacées déjà ajoutées ; on ne conserve que celles
    # des verbes maison (non wikt) encore présents
    garde = set(t.split(':')[0] for t in nv_tokens)
    for e in defs:
        v = e.split('\x01', 1)[0]
        if v in garde and v not in wikt:
            nv_defs.append(e)

    # reconstruction
    total = len(nv_tokens)
    brute = {k: v for k, v in brut.items()}
    brute['PT_VERBS_STR'] = '\n'.join(nv_tokens)
    brute['PT_DEFS_STR'] = '\x02'.join(nv_defs)
    brute['PT_VSRC_STR'] = '\n'.join(
        v for v in brut['PT_VSRC_STR'].split('\n')
        if v and v in garde)
    json.dump(brute, open(dst, 'w', encoding='utf-8'), ensure_ascii=False)

    print('verbes PT :', total)
    print('définitions remplacées :', rempl)
    print('verbes retirés (absents du Figueiredo) :', retires)
    dd = set(e.split('\x01', 1)[0] for e in nv_defs)
    vv = set(t.split(':')[0] for t in nv_tokens)
    print('sans définition :', len(vv - dd))
    print('OK')


if __name__ == '__main__':
    main()
