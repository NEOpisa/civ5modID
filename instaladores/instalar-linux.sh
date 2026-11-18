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

TROCADOS="ui/ingame/popups/socialpolicypopup.lua ui/ingame/popups/socialpolicypopup.xml ui/ingame/worldview/diplocorner.lua ui/ingame/ingame.xml"

caminho() {
	achado="$(find "$1" -ipath "$1/$2" 2>/dev/null | head -1)"
	[ -n "$achado" ] && echo "$achado" || echo "$1/$2"
}

aplicar() {
	dlc="$1"
	dados="$2"
	rm -rf "$dlc/$PASTA"
	xp2="$(find "$dlc" -maxdepth 1 -iname expansion2 | head -1)"
	if [ -z "$xp2" ]; then
		echo "Brave New World não encontrado em: $dlc"
		limpar_dados "$dados"
		return 0
	fi
	pkg="$(find "$xp2" -maxdepth 1 -iname expansion2.civ5pkg | head -1)"
	bak="$xp2/nvg_original"
	if [ -d "$bak" ]; then
		for f in $TROCADOS; do
			[ -f "$bak/$(basename "$f").orig" ] && cp "$bak/$(basename "$f").orig" "$(caminho "$xp2" "$f")"
		done
		cp "$bak/expansion2.civ5pkg.orig" "$pkg"
	fi
	rm -rf "$(caminho "$xp2" gameplay/xml)/nvg" "$(caminho "$xp2" ui/ingame)/nvg" "$bak"
	if [ "$REMOVER" = 1 ]; then
		echo "Removido de: $xp2"
		limpar_dados "$dados"
		return 0
	fi
	mkdir -p "$bak"
	cp "$pkg" "$bak/expansion2.civ5pkg.orig"
	for f in $TROCADOS; do
		cp "$(caminho "$xp2" "$f")" "$bak/$(basename "$f").orig"
	done
	gp="$(caminho "$xp2" gameplay/xml)/nvg"
	ui="$(caminho "$xp2" ui/ingame)"
	mkdir -p "$gp" "$ui/nvg"
	cp "$ORIGEM/gameplay/xml/nvg_dados.xml" "$ORIGEM/gameplay/xml/text/en_us/nvg_textos.xml" "$gp/"
	cp "$ORIGEM/ui/socialpolicypopup.lua" "$ORIGEM/ui/socialpolicypopup.xml" "$(caminho "$xp2" ui/ingame/popups)/"
	cp "$ORIGEM/ui/diplocorner.lua" "$(caminho "$xp2" ui/ingame/worldview)/"
	cp "$ORIGEM/ui/ingame.xml" "$ui/"
	for f in "$ORIGEM"/ui/*; do
		case "$(basename "$f")" in
			socialpolicypopup.lua|socialpolicypopup.xml|diplocorner.lua|ingame.xml) ;;
			*) cp "$f" "$ui/nvg/" ;;
		esac
	done
	sed -i 's#^\([[:space:]]*\)<!-- Directories -->#\1<GameData>nvg_dados.xml</GameData><!-- NVG -->\n\1<TextData>nvg_textos.xml</TextData><!-- NVG -->\n&#' "$pkg"
	if [ "$(grep -c "<!-- NVG -->" "$pkg")" != 2 ]; then
		echo "Não consegui alterar $pkg"
		cp "$bak/expansion2.civ5pkg.orig" "$pkg"
		exit 1
	fi
	echo "Instalado no Brave New World: $xp2"
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
		aplicar "$jogo/steamassets/assets/dlc" "$HOME/.local/share/Aspyr/Sid Meier's Civilization 5"
	fi
	for dlc in "$jogo/Assets/DLC" "$jogo/assets/dlc"; do
		if [ -d "$dlc" ]; then
			ACHOU=1
			aplicar "$dlc" "$lib/steamapps/compatdata/8930/pfx/drive_c/users/steamuser/Documents/My Games/Sid Meier's Civilization 5"
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
