cls
########################################
#									   #
# NetApp Script Get Chargeback Numbers #
# Author: svenm                        #
########################################

# Global Settings

#Export Filenamen - ToDO: Umbauen mit Datums Anhang
$ExpFileQuota = "NTAPquota.csv"
$ExpLuns = "NTAPluns.csv"

#Cluster to connect-to - Set to "daenuscsmgt" at SAG
$Cluster="dot9sim"


#Mit Cluster verbinden - Credential manuell
Connect-NcController $Cluster

#Alle Quotas auslesen - leider werden hier keine Qtrees mitgegeben
$quotaInfo = Get-NcQuota -Type tree | Select-Object Volume,QuotaTarget,Qtree,DiskLimit
#Im quotaReport stehen die qtrees aber keine Limits
$quotaReport = Get-NcQuotaReport | Select-Object Volume,QuotaTarget,Qtree
#Alle Cifs-Shares auslesen
$cifsShareInfo = Get-NcCifsShare | Select-Object ShareName, Path, Comment

#Zusammenbau Report aus Quota, QuotaRePort und CIFS-shares
$myCol = @()
$i= 0
foreach($entryQR in $quotaReport){
$i++
	Write-Host
	Write-Host Processing Entry $i   
	Write-Host 
	$fullReport = "" | Select-Object Volume,QuotaTarget,Qtree,DiskLimit,CifsShare,ShareDescription

	$fullReport.Volume = $entryQR.Volume
	$fullReport.QuotaTarget = $entryQR.QuotaTarget
	$fullReport.Qtree = $entryQR.Qtree
	
    #Im Get-NcQuotaReport haben wir alle Angaben ausser DiskLimit. DiskLimit steht in Get-NcQuota
	$DiskLimitbyQuotaTarget =  $quotainfo | Select-Object QuotaTarget,DiskLimit |	where {$_.QuotaTarget -eq $entryQR.QuotaTarget}
	$fullReport.DiskLimit = $DiskLimitbyQuotaTarget.DiskLimit

	#Zu jedem QuotaTarget die zugehörigen CIFS Shares und Comments
	#PfadNamen des Cifs-Shares bauen, da Quotatarget noch ein "/vol" davor hat
	$pathName = "/" + $entryQR.QuotaTarget.TrimStart("/vol")
	$ShareInfosByPath = $cifsShareInfo | Select-Object ShareName, Path, Comment | where {$_.Path -eq $pathName}
	$fullReport.CifsShare = $ShareInfosByPath.ShareName
	
$myCol += $fullReport
	}
#Write-Host Writing CSV  
$myCol | Export-Csv -NoTypeInformation -Delimiter ";"  $ExpFileQuota