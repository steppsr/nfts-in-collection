# ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
#   Name:				NFTsInCollection (NIC)
#   Description:		Create a list of NFT for a specific Collection in your Wallet.
#   Author:				Steve Stepp
#   Created on:			May 27, 2024
#   Latest version:		0.1
# ■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■

$blockchains = @("chia","aba")
Write-Host "--Blockchain Selection--"
$outcount = 1
$loopcount = 1
foreach ($chain in $blockchains) {
	#if ($loopcount % 2 -eq 1) {
	#	$option = [string]$outcount + ": " + [string]$chain + " - "
	#} else {
	#	
	#}
	$option = "$loopcount. " + [string]$chain
	Write-Host $option
	$outcount++
	$loopcount++
}
$choice = Read-Host "Choose blockchain"
$choice = [int]$choice - 1
$blockchain = $blockchains[$choice]
Write-Host "Selected blockchain: $blockchain"
Write-Host ""

# FINGERPRINT SELECTION
Write-Host ""
Write-Host "--Fingerprint Selection--"
$fingers = Invoke-Expression "$blockchain keys show" | Select-String -Pattern "Label: (.*)", "Fingerprint: (.*)" | ForEach-Object { $_.Matches.Groups[1].Value }
$outcount = 1
$loopcount = 1
foreach ($record in $fingers) {
	if ($loopcount % 2 -eq 1) {
		#Write-Host "$number is an odd number."
		$option = [string]$outcount + ": " + [string]$record + " - "
	} else {
		#Write-Host "$number is not an odd number."
		$option += [string]$record
		Write-Host $option
		$outcount++
	}
	$loopcount++
}
$choice = Read-Host "Choose fingerprint to use"
$choice = [int]$choice * 2 - 1
$fingerprint = $fingers[$choice]
Write-Host "Selected fingerprint: $fingerprint" 
Write-Host ""

# PATH SELECTION
Write-Host ""
Write-Host "--Path Selection--"
$input_file = Read-Host "Input file"
$output_file = Read-Host "Output file"

# COLLECTION FILTER
$my_collection = ""
$my_collection = Read-Host "Collection ID to filter on (blank for none)"

$ids = Get-Content -Path "$input_file"

foreach ($nft_id in $ids) {
	$getinfo_object = Invoke-Expression "$blockchain wallet nft get_info -f $fingerprint -ni $nft_id"
	$launcher_coin_id = $getinfo_object | Select-String -Pattern "Launcher coin ID: (.*)" | ForEach-Object { $_.Matches.Groups[1].Value.Trim() }
	$metadata_file = $getinfo_object | Select-String -Pattern "Metadata URIs:" -Context 0,1 | ForEach-Object { $_.Context.PostContext.Trim() }
	
	$jsonString = Invoke-RestMethod -Uri $metadata_file -Method Get
	$nft_name = $jsonString.name
	$collection_name = $jsonString.collection.name

	if($my_collection -eq "") {
		$output += $collection_name + "," + $launcher_coin_id + "," + $nft_id + "," + $nft_name + "`r`n"
		Write-Host $nft_id + " - " + $metadata_file
	} else {
		if($my_collection -eq $collection_name) {
			$output += $collection_name + "," + $launcher_coin_id + "," + $nft_id + "," + $nft_name + "`r`n"
			Write-Host $nft_id + " - " + $metadata_file
		} # else skip
	}
}

$output | Set-Content -Path $output_file -Encoding Utf8
