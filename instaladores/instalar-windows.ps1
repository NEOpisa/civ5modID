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

$destino = Join-Path $jogo "Assets\DLC\$pasta"
if (Test-Path $destino) { Remove-Item $destino -Recurse -Force }
if ($remover) {
	Write-Host "Removido de: $destino"
} else {
	Copy-Item $origem $destino -Recurse
	Write-Host "Instalado em: $destino"
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
