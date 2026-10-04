#!/usr/bin/env python3
"""Gera assets/termo/ a partir do fserb/pt-br (licença MIT).

Uso (só quando for preciso refazer as listas):
    python3 tool/build_termo_words.py

Baixa os arquivos do commit fixo abaixo e grava:
    assets/termo/validas.txt     NORMAL;EXIBIÇÃO, todas as tentativas aceitas
    assets/termo/respostas.txt   NORMAL, as palavras que podem ser sorteadas
    assets/termo/LICENSE-fserb-pt-br.txt

As respostas são as palavras de 5 letras mais frequentes (pontuação ICF) do
léxico, sem verbos flexionados, entre as REVISADAS primeiras, que foram lidas
uma a uma; o que não serve como resposta para a família está em EXCLUIR.
"""
import os
import re
import sys
import unicodedata
import urllib.parse
import urllib.request
from pathlib import Path

COMMIT = '93ba2a6f3b2f85262fba72df09d448c6bb2fa50a'
BASE = f'https://raw.githubusercontent.com/fserb/pt-br/{COMMIT}/'
OUT = Path(__file__).resolve().parent.parent / 'assets' / 'termo'
# Para testar sem rede: FSERB_DIR=/caminho/com/os/arquivos
LOCAL = os.environ.get('FSERB_DIR')
REVISADAS = 1300

# Nomes próprios, estrangeirismos, palavrões, contrações e palavras raras ou
# impróprias para crianças, entre as REVISADAS candidatas mais frequentes.
EXCLUIR = set('''
neste desta nesta disso jesus nesse maria dessa nessa delas china daqui light
bruno goiás facto nisso japão porno black login micro braga vasco invés recém
sousa chico flash merda aonde índia césar autos nunes jeans vosso moura mouse
piauí chile porra infra drive celso egito bunda laser ultra abreu suíça marte
júlio tesão marta seios diogo motel joana color laura mauro green multi penha
meter jóias síria queen caput corsa gozar skate fusca stand blues weber amaro
crack adobe angra malta henry diana milão major bauru roque judeu hélio modem
spray amapá guiné couto simão slide pênis short nobel nisto anais timão ibope
judas macau cache cover clean bacon staff lúcio siena break jeová corno lauro
combo sushi fezes trans donde macro blush bosta magno sedan foder madre nylon
grill veiga hobby rally front paper pixel close lobby remix dante romeu timor
duche round dunga swing tietê cotia souto blitz máfia elena crato vênus coach
xerox fraga ávila tarso rugby match diodo gávea capão sigma cairo toner congo
chica anglo hasta sugar mafra orgia reiki logos bangu nudez praxe aquém mercê
lobão sacra orixá aedes apolo oxalá seara viado karma tecto cozer vulgo drink
quota edema táxis baião liceu bessa apart strip túlio dogma cerne araxá caicó
betão lorde quiçá fetal hidro relax quina coque pampa casta still durão rouge
varão logar xeque cosmo alter mixer gibis bolão hacer focal horto látex áurea
babel bicha vilar romão guria timer derby lítio loiça tetra ferry dorso botox
ibero error áries tatuí buggy tróia coxim labor carte caída rolim gnome novel
tetas ítalo serva hiato antão cusco célio hindu laico limbo tesla recta cólon
nitro povão guará sêmen curry rente cabal abade guaçu rotor furor jumbo grado
train malte urano reich coifa trial xangô acolá pagão areal tarja beato corja
óscar átrio óvulo input babar rabão blast cisão modal devir modus senda ósseo
tenor âmago chope guião égide veado vanda marra bocal dotar gueto alana bamba
xisto penny retos papal mento rapel páreo islão logon rifle creta tanga twist
chili ethos maçom carma graal catch drops sheik lycra kraft avaré batel sunga
cariz sarro coupé basal rasto reger sacro ganga óbice leone aruba sarja mouro
cagar epóxi untar mango neuro cisto honor haras jango débil parma lomba canas
algoz ninfa blend suede crush goela curió corso jataí sachê axial ceres tirso
basco tutti ímpio tecno horda rebel copel édipo
negra negro índio burro besta perua esses
'''.split())


def fetch(name):
    if LOCAL:
        return (Path(LOCAL) / name).read_text(encoding='utf-8')
    with urllib.request.urlopen(BASE + urllib.parse.quote(name)) as r:
        return r.read().decode('utf-8')


def norm(word):
    decomposed = unicodedata.normalize('NFD', word.upper())
    return ''.join(c for c in decomposed if unicodedata.category(c) != 'Mn')


def is_five(n):
    return re.fullmatch('[A-Z]{5}', n) is not None


def main():
    lexico = [w.strip() for w in fetch('lexico').splitlines() if w.strip()]
    conj = [w.strip() for w in fetch('conjugações').splitlines() if w.strip()]
    icf = {}
    for line in fetch('icf').splitlines():
        word, _, score = line.rpartition(',')
        try:
            icf[word] = float(score)
        except ValueError:
            pass

    # Léxico primeiro: a forma com acento dele vence a das conjugações.
    validas = {}
    for w in lexico + conj:
        n = norm(w)
        if is_five(n):
            validas.setdefault(n, unicodedata.normalize('NFC', w.upper()))

    # O léxico nem sempre traz plurais e femininos (tem CASAS, não tem GATOS).
    # Como tentativa (nunca como resposta), aceita também:
    #   palavra de 4 letras terminada em vogal + S   (GATO → GATOS)
    #   palavra de 5 letras terminada em O → A       (OUTRO → OUTRA)
    for w in lexico:
        n = norm(w)
        shown = unicodedata.normalize('NFC', w.upper())
        if re.fullmatch('[A-Z]{3}[AEO]', n):
            validas.setdefault(n + 'S', shown + 'S')
        elif is_five(n) and n.endswith('O'):
            validas.setdefault(n[:-1] + 'A', shown[:-1] + 'A')

    flexionadas = {norm(w) for w in conj}
    excluir = {norm(w) for w in EXCLUIR}
    candidatas = []
    for w in lexico:
        n = norm(w)
        if not is_five(n) or w not in icf:
            continue
        # Verbo flexionado não vira resposta; infinitivo pode.
        if n in flexionadas and not re.search('(AR|ER|IR)$', n):
            continue
        candidatas.append((icf[w], n))
    candidatas.sort()

    vistas, respostas = set(), []
    for _, n in candidatas:
        if n in vistas:
            continue
        vistas.add(n)
        if len(vistas) > REVISADAS:
            break
        if n not in excluir:
            respostas.append(n)

    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / 'validas.txt').write_text(
        ''.join(f'{n};{validas[n]}\n' for n in sorted(validas)), encoding='utf-8')
    (OUT / 'respostas.txt').write_text(
        ''.join(f'{n}\n' for n in sorted(respostas)), encoding='utf-8')
    (OUT / 'LICENSE-fserb-pt-br.txt').write_text(fetch('LICENSE'), encoding='utf-8')
    print(f'válidas: {len(validas)}  respostas: {len(respostas)}', file=sys.stderr)


if __name__ == '__main__':
    main()
