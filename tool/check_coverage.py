#!/usr/bin/env python3
"""Confere a cobertura de testes depois de `flutter test --coverage`.

Falha se algum arquivo de lib/ com código executável ficar abaixo de 90% das
linhas, se algum arquivo de lib/ nem aparecer no relatório, ou se o total
ficar abaixo de 95%.

Uso: python3 tool/check_coverage.py [coverage/lcov.info]
"""

import glob
import sys

PER_FILE = 90.0
TOTAL = 95.0


def read_lcov(path):
    files = {}
    current = None
    with open(path, encoding='utf-8') as lcov:
        for line in lcov:
            line = line.strip()
            if line.startswith('SF:'):
                current = line[3:]
                files[current] = [0, 0]
            elif line.startswith('DA:') and current is not None:
                hits = int(line.split(',')[1])
                files[current][1] += 1
                if hits > 0:
                    files[current][0] += 1
    return files


def main():
    path = sys.argv[1] if len(sys.argv) > 1 else 'coverage/lcov.info'
    files = read_lcov(path)
    failures = []
    for source in sorted(glob.glob('lib/**/*.dart', recursive=True)):
        if source not in files:
            # Arquivos só com enums/constantes não geram linhas no lcov.
            with open(source, encoding='utf-8') as f:
                text = f.read()
            if '{' in text and ('=>' in text or 'return' in text):
                failures.append(f'  sem teste nenhum: {source}')
            continue
        hit, total = files[source]
        if total and 100 * hit / total < PER_FILE:
            failures.append(f'  {100 * hit / total:5.1f}% ({hit}/{total}) {source}')

    hit = sum(h for h, _ in files.values())
    total = sum(t for _, t in files.values())
    overall = 100 * hit / total if total else 0
    print(f'Cobertura total: {overall:.1f}% ({hit}/{total} linhas)')
    if failures:
        print(f'Arquivos abaixo de {PER_FILE:.0f}%:')
        print('\n'.join(failures))
    if overall < TOTAL:
        print(f'Total abaixo de {TOTAL:.0f}%.')
    if failures or overall < TOTAL:
        sys.exit(1)
    print('OK')


if __name__ == '__main__':
    main()
