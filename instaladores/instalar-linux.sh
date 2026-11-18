#!/bin/sh
AQUI="$(dirname "$(readlink -f "$0")")"
ORIGEM="$AQUI/eradasideologias"
PASTA="eradasideologias"
JOGO_NOME="Sid Meier's Civilization V"
REMOVER=0
[ "$1" = "--remover" ] || [ "$1" = "remover" ] && REMOVER=1

if ps -eo comm,args | grep -i "[C]iv5XP\|[C]ivilizationV" | grep -vq "grep\|instalar"; then
	echo "Feche o Civilization V antes de continuar."
	exit 1
fi

if [ "$REMOVER" = 0 ] && [ ! -f "$ORIGEM/$PASTA.civ5pkg" ]; then
	echo "A pasta '$PASTA' precisa estar ao lado deste script."
	exit 1
fi

bibliotecas() {
	for raiz in "$HOME/.local/share/Steam" "$HOME/.steam/steam" "$HOME/.steam/root" \
		"$HOME/.var/app/com.valvesoftware.Steam/.local/share/Steam" "$HOME/snap/steam/common/.local/share/Steam"; do
		[ -d "$raiz/steamapps" ] || continue
		echo "$raiz"
		vdf="$raiz/steamapps/libraryfolders.vdf"
		[ -f "$vdf" ] && sed -n 's/^[[:space:]]*"path"[[:space:]]*"\(.*\)"[[:space:]]*$/\1/p' "$vdf"
	done | while read -r b; do readlink -f "$b"; done | sort -u
}

limpar_dados() {
	dados="$1"
	[ -d "$dados" ] || return 0
	if [ -d "$dados/MODS" ]; then
		find "$dados/MODS" -maxdepth 1 -iname "era das ideologias*" -exec rm -rf {} +
	fi
	if [ -d "$dados/cache" ]; then
		find "$dados/cache" -maxdepth 1 -name "*.db" -delete
	fi
}

aplicar() {
	destino="$1"
	dados="$2"
	rm -rf "$destino"
	if [ "$REMOVER" = 1 ]; then
		echo "Removido de: $destino"
	else
		cp -r "$ORIGEM" "$destino"
		echo "Instalado em: $destino"
	fi
	limpar_dados "$dados"
}

ACHOU=0
LISTA="$(mktemp)"
bibliotecas > "$LISTA"
while IFS= read -r lib; do
	jogo="$lib/steamapps/common/$JOGO_NOME"
	[ -d "$jogo" ] || continue
	if [ -d "$jogo/steamassets/assets/dlc" ]; then
		ACHOU=1
		aplicar "$jogo/steamassets/assets/dlc/$PASTA" "$HOME/.local/share/Aspyr/Sid Meier's Civilization 5"
	fi
	for dlc in "$jogo/Assets/DLC" "$jogo/assets/dlc"; do
		if [ -d "$dlc" ]; then
			ACHOU=1
			aplicar "$dlc/$PASTA" "$lib/steamapps/compatdata/8930/pfx/drive_c/users/steamuser/Documents/My Games/Sid Meier's Civilization 5"
			break
		fi
	done
done < "$LISTA"
rm -f "$LISTA"

if [ "$ACHOU" = 0 ]; then
	echo "Civilization V não encontrado nas bibliotecas da Steam."
	exit 1
fi
[ "$REMOVER" = 1 ] || echo "Pronto. Jogue pelo Multijogador normal (sem o menu MODS)."
