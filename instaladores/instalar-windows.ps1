param([string]$acao = "")
$ErrorActionPreference = "Stop"
$pasta = "eradasideologias"
$origem = Join-Path $PSScriptRoot $pasta
$remover = $acao -eq "remover"

if (Get-Process -Name "CivilizationV*" -ErrorAction SilentlyContinue) {
	Write-Host "Feche o Civilization V antes de continuar."
	exit 1
}
if (-not $remover -and -not (Test-Path (Join-Path $origem "$pasta.civ5pkg"))) {
	Write-Host "A pasta '$pasta' precisa estar ao lado deste arquivo."
	exit 1
}

$libs = New-Object System.Collections.Generic.List[string]
foreach ($chave in @("HKCU:\Software\Valve\Steam", "HKLM:\SOFTWARE\WOW6432Node\Valve\Steam", "HKLM:\SOFTWARE\Valve\Steam")) {
	$p = Get-ItemProperty -Path $chave -ErrorAction SilentlyContinue
	foreach ($v in @($p.SteamPath, $p.InstallPath)) {
		if ($v) {
			$raiz = $v -replace "/", "\"
			$libs.Add($raiz)
			$vdf = Join-Path $raiz "steamapps\libraryfolders.vdf"
			if (Test-Path $vdf) {
				foreach ($m in (Select-String -Path $vdf -Pattern '"path"\s+"([^"]+)"')) {
					$libs.Add(($m.Matches[0].Groups[1].Value -replace "\\\\", "\"))
				}
			}
		}
	}
}
$libs.Add("C:\Program Files (x86)\Steam")
$libs.Add("C:\Program Files\Steam")

$jogo = $null
foreach ($l in ($libs | Select-Object -Unique)) {
	$j = Join-Path $l "steamapps\common\Sid Meier's Civilization V"
	if (Test-Path (Join-Path $j "Assets\DLC")) { $jogo = $j; break }
}
if (-not $jogo) {
	Write-Host "Civilization V nao encontrado nas bibliotecas da Steam."
	exit 1
}

$dlc = Join-Path $jogo "Assets\DLC"
$velho = Join-Path $dlc $pasta
if (Test-Path $velho) { Remove-Item $velho -Recurse -Force }
$xp2 = Join-Path $dlc "Expansion2"
$pkg = Join-Path $xp2 "Expansion2.civ5pkg"
$trocados = @("UI\InGame\Popups\SocialPolicyPopup.lua", "UI\InGame\Popups\SocialPolicyPopup.xml", "UI\InGame\WorldView\DiploCorner.lua", "UI\InGame\InGame.xml")
$bak = Join-Path $xp2 "nvg_original"
function DoMod($arq) { (Test-Path $arq) -and (Select-String -Path $arq -Pattern 'NVG|eradasideologias|"#N#"' -Quiet) }
foreach ($f in $trocados) {
	$alvo = Join-Path $xp2 $f
	$o = Join-Path $bak ((Split-Path $f -Leaf) + ".orig")
	if ((Test-Path $alvo) -and -not (DoMod $alvo)) { continue }
	if ((Test-Path $o) -and -not (DoMod $o) -and (Test-Path (Split-Path $alvo -Parent))) { Copy-Item $o $alvo -Force; continue }
	if (Test-Path $alvo) { Remove-Item $alvo -Force }
}
if ((Test-Path $pkg) -and (Select-String -Path $pkg -Pattern '<!-- NVG -->' -Quiet)) {
	$linhas = [IO.File]::ReadAllLines($pkg) | Where-Object { $_ -notmatch '<!-- NVG -->' }
	[IO.File]::WriteAllText($pkg, (($linhas -join "`r`n") + "`r`n"), (New-Object System.Text.UTF8Encoding $false))
}
foreach ($d in @((Join-Path $xp2 "Gameplay\XML\nvg"), (Join-Path $xp2 "UI\InGame\nvg"), $bak)) {
	if (Test-Path $d) { Remove-Item $d -Recurse -Force }
}
if ($remover) {
	Write-Host "Removido de: $xp2"
} else {
	$falta = @()
	if (-not (Test-Path $pkg)) { $falta += "Expansion2.civ5pkg" }
	foreach ($f in $trocados) { if (-not (Test-Path (Join-Path $xp2 $f))) { $falta += $f } }
	if ($falta.Count -gt 0) {
		Write-Host "O Brave New World esta incompleto ou nao instalado em: $xp2"
		Write-Host ("Faltando: " + ($falta -join ", "))
		Write-Host "Na Steam: Civilization V > Propriedades > DLC (marque o Brave New World) e depois Arquivos instalados > Verificar integridade. Depois rode este instalador de novo."
		exit 1
	}
	New-Item -ItemType Directory -Path $bak | Out-Null
	Copy-Item $pkg (Join-Path $bak "Expansion2.civ5pkg.orig")
	foreach ($f in $trocados) { Copy-Item (Join-Path $xp2 $f) (Join-Path $bak ((Split-Path $f -Leaf) + ".orig")) }
	$gp = Join-Path $xp2 "Gameplay\XML\nvg"
	$ui = Join-Path $xp2 "UI\InGame"
	New-Item -ItemType Directory -Path $gp | Out-Null
	New-Item -ItemType Directory -Path (Join-Path $ui "nvg") | Out-Null
	Copy-Item (Join-Path $origem "gameplay\xml\nvg_dados.xml") $gp
	Copy-Item (Join-Path $origem "gameplay\xml\text\en_us\nvg_textos.xml") $gp
	Copy-Item (Join-Path $origem "ui\socialpolicypopup.lua") (Join-Path $ui "Popups\SocialPolicyPopup.lua") -Force
	Copy-Item (Join-Path $origem "ui\socialpolicypopup.xml") (Join-Path $ui "Popups\SocialPolicyPopup.xml") -Force
	Copy-Item (Join-Path $origem "ui\diplocorner.lua") (Join-Path $ui "WorldView\DiploCorner.lua") -Force
	Copy-Item (Join-Path $origem "ui\ingame.xml") (Join-Path $ui "InGame.xml") -Force
	$fixos = @("socialpolicypopup.lua", "socialpolicypopup.xml", "diplocorner.lua", "ingame.xml")
	Get-ChildItem (Join-Path $origem "ui") -File | Where-Object { $fixos -notcontains $_.Name.ToLower() } | ForEach-Object { Copy-Item $_.FullName (Join-Path $ui "nvg") }
	$texto = [IO.File]::ReadAllText($pkg)
	$m = [regex]::Match($texto, '(?m)^([ \t]*)<!-- Directories -->')
	if (-not $m.Success) {
		Write-Host "Nao consegui alterar $pkg"
		exit 1
	}
	$r = $m.Groups[1].Value
	$ins = "$r<GameData>nvg_dados.xml</GameData><!-- NVG -->`r`n$r<TextData>nvg_textos.xml</TextData><!-- NVG -->`r`n"
	[IO.File]::WriteAllText($pkg, $texto.Insert($m.Index, $ins), (New-Object System.Text.UTF8Encoding $false))
	Write-Host "Instalado no Brave New World: $xp2"
}

$docs = [Environment]::GetFolderPath("MyDocuments")
$dados = Join-Path $docs "My Games\Sid Meier's Civilization 5"
$mods = Join-Path $dados "MODS"
if (Test-Path $mods) {
	Get-ChildItem $mods -Directory | Where-Object { $_.Name -like "era das ideologias*" } | Remove-Item -Recurse -Force
}
$cache = Join-Path $dados "cache"
if (Test-Path $cache) { Get-ChildItem $cache -Filter "*.db" | Remove-Item -Force -ErrorAction SilentlyContinue }

if (-not $remover) { Write-Host "Pronto. Jogue pelo Multijogador normal (sem o menu MODS)." }
