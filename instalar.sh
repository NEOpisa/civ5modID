#!/bin/sh
set -e
AQUI="$(dirname "$(readlink -f "$0")")"
export NVG_TMP="${NVG_TMP:-${TMPDIR:-/tmp}}"
GERAR="$(python3 "$AQUI/ferramentas/gerar.py")"
echo "$GERAR" | tail -1
python3 "$AQUI/ferramentas/telas.py" >/dev/null
python3 "$AQUI/ferramentas/empacotar.py" >/dev/null
DLC="$(python3 "$AQUI/ferramentas/dlc.py")"
echo "$DLC" | grep AVISO && exit 1
PACOTE="$AQUI/saida/EraDasIdeologias"
rm -rf "$PACOTE"
mkdir -p "$PACOTE"
cp -r "$AQUI/saida/dlc/eradasideologias" "$PACOTE/"
cp "$AQUI/instaladores/instalar-linux.sh" "$AQUI/instaladores/instalar-windows.ps1" "$AQUI/instaladores/instalar-windows.bat" "$PACOTE/"
cp "$AQUI/EraDasIdeologias/LEIA-ME.md" "$PACOTE/"
if grep -rqi "ctrl\|editor do mundo" "$PACOTE/LEIA-ME.md" "$PACOTE/eradasideologias/eradasideologias.civ5pkg"; then
	echo "pacote vazando o segredo"
	exit 1
fi
rm -f "$HOME/Downloads/EraDasIdeologias-Civ5.zip" "$HOME/Downloads/EraDasIdeologias-DLC.zip"
(cd "$AQUI/saida" && python3 -c "import shutil; shutil.make_archive('$HOME/Downloads/EraDasIdeologias-DLC', 'zip', '.', 'EraDasIdeologias')")
for so in Windows Linux; do
	Z="$AQUI/saida/zip-$so/EraDasIdeologias-$so"
	rm -rf "$AQUI/saida/zip-$so"
	mkdir -p "$Z"
	cp -r "$PACOTE/eradasideologias" "$PACOTE/LEIA-ME.md" "$Z/"
	if [ "$so" = Windows ]; then cp "$PACOTE/instalar-windows.bat" "$PACOTE/instalar-windows.ps1" "$Z/"; else cp "$PACOTE/instalar-linux.sh" "$Z/"; fi
	(cd "$AQUI/saida/zip-$so" && python3 -c "import shutil; shutil.make_archive('$AQUI/saida/EraDasIdeologias-$so', 'zip', '.', 'EraDasIdeologias-$so')")
done
sh "$PACOTE/instalar-linux.sh"
echo "Zip para os amigos: $HOME/Downloads/EraDasIdeologias-DLC.zip"
