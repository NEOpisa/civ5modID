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
MARCA='NVG|eradasideologias|"#N#"'
VERIFICAR=0

achar() {
	r="$(cd "$1" 2>/dev/null && find -L . -ipath "./$2" 2>/dev/null | head -1)"
	[ -n "$r" ] && echo "$1/${r#./}"
}

do_mod() {
	grep -qE "$MARCA" "$1" 2>/dev/null
}

limpar_xp2() {
	xp2="$1"
	bak="$xp2/nvg_original"
	for f in $TROCADOS; do
		alvo="$(achar "$xp2" "$f")"
		orig="$bak/$(basename "$f").orig"
		[ -n "$alvo" ] && ! do_mod "$alvo" && continue
		if [ -f "$orig" ] && ! do_mod "$orig"; then
			[ -z "$alvo" ] && pai="$(achar "$xp2" "$(dirname "$f")")" && [ -n "$pai" ] && alvo="$pai/$(basename "$f")"
			[ -n "$alvo" ] && cp "$orig" "$alvo" && continue
		fi
		[ -n "$alvo" ] && rm -f "$alvo"
	done
	pkg="$(find -L "$xp2" -maxdepth 1 -iname expansion2.civ5pkg | head -1)"
	[ -n "$pkg" ] && grep -q "<!-- NVG -->" "$pkg" && sed -i '/<!-- NVG -->/d' "$pkg"
	rm -rf "$bak"
	find -L "$xp2" -mindepth 2 -type d -iname nvg -prune -exec rm -rf {} + 2>/dev/null
	find -L "$xp2" -type f \( -iname "*.lua" -o -iname "*.xml" \) -exec grep -lE "$MARCA" {} + 2>/dev/null | while IFS= read -r x; do
		rm -f "$x"
	done
	for d in ui/ingame/popups ui/ingame/worldview ui/ingame ui gameplay/xml gameplay; do
		rmdir "$xp2/$d" 2>/dev/null
	done
}

aplicar() {
	dlc="$1"
	dados="$2"
	find -L "$dlc" -maxdepth 1 -iname "$PASTA" -exec rm -rf {} + 2>/dev/null
	pkg="$(find -L "$dlc" -mindepth 2 -maxdepth 2 -iname expansion2.civ5pkg | head -1)"
	if [ -n "$pkg" ]; then
		xp2="$(dirname "$pkg")"
	else
		xp2="$(find -L "$dlc" -maxdepth 1 -iname expansion2 | head -1)"
	fi
	[ -n "$xp2" ] && limpar_xp2 "$xp2"
	limpar_dados "$dados"
	falta=""
	[ -n "$pkg" ] || falta=" expansion2.civ5pkg"
	for f in $TROCADOS; do
		[ -n "$xp2" ] && [ -n "$(achar "$xp2" "$f")" ] || falta="$falta $f"
	done
	gp="$( [ -n "$xp2" ] && achar "$xp2" gameplay/xml)"
	[ -n "$gp" ] || falta="$falta gameplay/xml"
	if [ "$REMOVER" = 1 ]; then
		[ -n "$xp2" ] && echo "Removido de: $xp2"
		[ -n "$pkg" ] && [ -n "$falta" ] && VERIFICAR=1
		return 0
	fi
	if [ -n "$falta" ]; then
		FALTAS="$FALTAS
${xp2:-$dlc}:$falta"
		return 2
	fi
	bak="$xp2/nvg_original"
	mkdir -p "$bak" "$gp/nvg"
	for f in $TROCADOS; do
		cp "$(achar "$xp2" "$f")" "$bak/$(basename "$f").orig"
	done
	ui="$(dirname "$(achar "$xp2" ui/ingame/ingame.xml)")"
	mkdir -p "$ui/nvg"
	cp "$ORIGEM/gameplay/xml/nvg_dados.xml" "$ORIGEM/gameplay/xml/text/en_us/nvg_textos.xml" "$gp/nvg/"
	for f in $TROCADOS; do
		cp "$ORIGEM/ui/$(basename "$f")" "$(achar "$xp2" "$f")"
	done
	for f in "$ORIGEM"/ui/*; do
		case "$(basename "$f")" in
			socialpolicypopup.lua|socialpolicypopup.xml|diplocorner.lua|ingame.xml) ;;
			*) cp "$f" "$ui/nvg/" ;;
		esac
	done
	sed -i 's#^\([[:space:]]*\)<!-- Directories -->#\1<GameData>nvg_dados.xml</GameData><!-- NVG -->\n\1<TextData>nvg_textos.xml</TextData><!-- NVG -->\n&#' "$pkg"
	if [ "$(grep -c "<!-- NVG -->" "$pkg")" != 2 ]; then
		echo "Não consegui alterar $pkg"
		limpar_xp2 "$xp2"
		return 1
	fi
	echo "Instalado no Brave New World: $xp2"
	OK=1
}

ACHOU=0
ERRO=0
OK=0
FALTAS=""
LISTA="$(mktemp)"
bibliotecas > "$LISTA"
while IFS= read -r lib; do
	jogo="$lib/steamapps/common/$JOGO_NOME"
	[ -d "$jogo" ] || continue
	if [ -d "$jogo/steamassets/assets/dlc" ]; then
		ACHOU=1
		aplicar "$jogo/steamassets/assets/dlc" "$HOME/.local/share/Aspyr/Sid Meier's Civilization 5"
		[ $? = 1 ] && ERRO=1
	fi
	dlc="$(find -L "$jogo" -mindepth 2 -maxdepth 2 -ipath "$jogo/assets/dlc" ! -path "$jogo/steamassets/*" 2>/dev/null | head -1)"
	if [ -n "$dlc" ]; then
		ACHOU=1
		aplicar "$dlc" "$lib/steamapps/compatdata/8930/pfx/drive_c/users/steamuser/Documents/My Games/Sid Meier's Civilization 5"
		[ $? = 1 ] && ERRO=1
	fi
done < "$LISTA"
rm -f "$LISTA"

if [ "$ACHOU" = 0 ]; then
	echo "Civilization V não encontrado nas bibliotecas da Steam."
	exit 1
fi
if [ "$REMOVER" = 0 ] && [ "$OK" = 0 ]; then
	echo "Não achei o Brave New World completo em nenhuma pasta do jogo:$FALTAS"
	VERIFICAR=1
fi
if [ "$VERIFICAR" = 1 ]; then
	echo "Arquivos originais do jogo precisam voltar: na Steam, Civilization V > Propriedades > Arquivos instalados > Verificar integridade dos arquivos."
	[ "$REMOVER" = 1 ] || echo "Quando a verificação terminar, rode este instalador de novo."
	exit 1
fi
[ "$ERRO" = 1 ] && exit 1
[ "$REMOVER" = 1 ] || echo "Pronto. Jogue pelo Multijogador normal (sem o menu MODS)."
