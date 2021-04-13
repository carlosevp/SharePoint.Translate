Function ConvertTo-AnotherLanguage {
# Copied from this Reddit post and adjusted to work with SharePoint:
# https://www.reddit.com/r/PowerShell/comments/b6n5pr/free_text_translation_using_powershell/
param (
    [Parameter(Mandatory=$false)]
    [String]
    $TargetLanguage = "Spanish", # See list of possible languages in $LanguageHashTable below.

    [Parameter(Mandatory=$false)]
    [String]$apiKey,

    [Parameter(Mandatory=$false)]
    [String]$fromLang = "en",

    [Parameter(Mandatory=$false)] 
    [String]
    $textToConvert = " " # This can either be the text to translate, or the path to a file containing the text to translate
)
# Create a Hashtable containing the full names of languages as keys and the code for that language as values
$LanguageHashTable = @{ 
Afrikaans='af' 
Albanian='sq' 
Arabic='ar' 
Azerbaijani='az' 
Basque='eu' 
Bengali='bn' 
Belarusian='be' 
Bulgarian='bg' 
Catalan='ca' 
'Chinese Simplified'='zh-CN' 
'Chinese Simplified SharePoint'='zh-chs' 
'Chinese Traditional'='zh-TW' 
Croatian='hr' 
Czech='cs' 
Danish='da' 
Dutch='nl' 
English='en' 
Esperanto='eo' 
Estonian='et' 
Filipino='tl' 
Finnish='fi' 
French='fr' 
Galician='gl' 
Georgian='ka' 
German='de' 
Greek='el' 
Gujarati='gu' 
Haitian ='ht' 
Creole='ht' 
Hebrew='iw' 
Hindi='hi' 
Hungarian='hu' 
Icelandic='is' 
Indonesian='id' 
Irish='ga' 
Italian='it' 
Japanese='ja' 
Kannada='kn' 
Korean='ko' 
Latin='la' 
Latvian='lv' 
Lithuanian='lt' 
Macedonian='mk' 
Malay='ms' 
Maltese='mt' 
Norwegian='no' 
Persian='fa' 
Polish='pl' 
Portuguese='pt' 
PortugueseBR='pt-br' 
Romanian='ro' 
Russian='ru' 
Serbian='sr' 
Slovak='sk' 
Slovenian='sl' 
Spanish='es' 
Swahili='sw' 
Swedish='sv' 
Tamil='ta' 
Telugu='te' 
Thai='th' 
Turkish='tr' 
Ukrainian='uk' 
Urdu='ur' 
Vietnamese='vi' 
Welsh='cy' 
Yiddish='yi' 
}
If (!$apiKey) { $apiKey = Get-Secret -Name TranslationAPI -AsPlainText }
# Translation API
$translateBaseURI = "https://api.cognitive.microsofttranslator.com/translate?api-version=3.0"
if (!$fromLang) { $fromLang = "en" }
# Convert from - en = English
# Determine the target language
if ($LanguageHashTable.ContainsKey($TargetLanguage)) {
    $TargetLanguageCode = $LanguageHashTable[$TargetLanguage]
}
elseif ($LanguageHashTable.ContainsValue($TargetLanguage)) {
    $TargetLanguageCode = $TargetLanguage
}
else {
    throw "Unknown target language. Use one of the languages in the `$LanguageHashTable hashtable."
}
# Create a list object to store the finished translation in.

# Adjusts the languages to match SharePoint input  unfortunately they dont match with MS Translate endpoints.
if($TargetLanguage -eq 'zh-cns') {$TargetLanguage='zh-CN'}
if($TargetLanguage -eq 'pt-br') {$TargetLanguage='pt'}

$headers = @{}
$headers.Add("Ocp-Apim-Subscription-Key",$apiKey)
$headers.Add("Content-Type","application/json")
$headers.Add("Ocp-Apim-Subscription-Region","eastus2")
# Conversion URI
$convertURI = "$($translateBaseURI)&from=$($fromLang)&to=$($TargetLanguage)"

if ($textToConvert -eq " ") {
$textToConvert = @"
Translates text even even with special characters like " ' ` $ works without issue, though the API may mangle them a bit. Not sure what the limit of line length is, but it seems like you can get away with quite a bit.
It works fine for multiple lines as well.
You can inject code into this block too using the `$(code) format.
Here's the date as an example $(Get-Date).
Due to this you may want to escape the usual Powershell characters, like $ in certain cases like I did above.
If you're just going to have plain text here change the here-string to single quotes instead and anything goes.
Not sure if the API has a rate limit for how much it'll take, but I tried a whole bunch of lines (40+) with
success so at least shorter texts seems to work fine.
"@
}
#elseif (Test-Path $textToConvert -PathType Leaf) {
#    $textToConvert = Get-Content $textToConvert -Raw
#}

$text = @{'Text' = $($textToConvert)}
$text = $text | ConvertTo-Json
# Convert
$conversionResult = Invoke-RestMethod -Method POST -Uri $convertURI -Headers $headers -Body "[$($text)]"
#write-host -ForegroundColor 'yellow' "'$($textToConvert)' converted to '$($conversionResult.translations[0].text)'
$Translation=$($conversionResult.translations[0].text)
#$Translation=$Translation.replace('?','')   # Test to see if gets better formating when spaces are present.
#$Translation=$Translation.replace('& nbsp;','')
#$Translation=$Translation.replace('&nbsp;','')
return $Translation
}


# Translate function
function Start-Translation{
    param(
    [Parameter(Mandatory=$true)]
    [string]$Text,

    [Parameter(Mandatory=$true)]
    [string]$Language,

    [Parameter(Mandatory=$false)]
    [string]$apiKey,
    
    [Parameter(Mandatory=$false)]
    [string]$fromLang='en'

    )
 
    $baseUri = "https://api.cognitive.microsofttranslator.com/translate?api-version=3.0"
 
    if($Language -eq 'zh-cns') {$Language='zh-CN'}
    if($Language -eq 'pt-br') {$Language='pt'}
    
    $headers = @{}
    $headers.Add("Ocp-Apim-Subscription-Key",$apiKey)
    $headers.Add("Content-Type","application/json")
    $headers.Add("Ocp-Apim-Subscription-Region","eastus2")
    # Conversion URI
    $convertURI = "$($baseURI)&from=$($fromLang)&to=$($Language)&textType=html"
 
    # Create JSON array with 1 object for request body
    $textJson = @{
        "Text" = $text
        } | ConvertTo-Json
 
    $body = "[$textJson]"
 
    # Uri for the request includes language code and text type, which is always html for SharePoint text web parts
    #$uri = "$baseUri&amp;to=$language&amp;textType=html"
 
    # Send request for translation and extract translated text
    $results = Invoke-RestMethod -Method Post -Uri $convertURI -Headers $headers -Body $body
    $translatedText = $results[0].translations[0].text
    return $translatedText
}

Function New-SharePointTranslation{
 <#
        .Synopsis
            Translates a SharePoint Page into multiple languages. Must be SP Site Owner and provide credentials interactively.

        .DESCRIPTION
            Translates a SharePoint Page into multiple languages. Must be SP Site Owner and provide credentials interactively.

        .PARAMETER SharePointSite
            URL for the SharePoint site.
        
        .PARAMETER Languages
            Array of Languages to translate the text to. Source must be in english.

         .PARAMETER PageToTranslate
            Name of the SharePoint Page to be translated.       

        .EXAMPLE
           Translate-SWPage -SharePointSite LearningPathway -Languages @('es','fr') -Page ThisPage.aspx
    #>
    [CmdletBinding()]
    param (
           [Parameter(Mandatory=$false)]
           [string]$SharePointSite,

           [Parameter(Mandatory=$false)]
           [array]$Languages,

           [Parameter(Mandatory=$false)]
           [pscredential]$Credential,

           [Parameter(Mandatory=$false)]
           [string]$PageToTranslate=$PageToTranslate,

           [Parameter(Mandatory=$false)]
           [string]$APIKey

    )



# Lets connect to SharePoint - it will prompt for authentication if no Credential was provided.
# Interactive policies where MFA is required with Conditional Access cant use Credential as parameters.
If (!$Credential) { $Connection=Connect-PNPOnline -Url $SharePointSite -Interactive }
Else {$Connection=Connect-PNPOnline -Url $SharePointSite -Credentials $Credential}

$Page = Get-PnPClientSidePage $PageToTranslate # "$targetLanguage/$pageTitle.aspx"
#$textControls = $Page.Controls | Where-Object {$_.Type.Name -eq "ClientSideText"}
$textControls = $Page.Controls | Where-Object {$_.Type.Name -eq "PageText"}
 
Write-Host "Translating content..." -NoNewline
 foreach ($Language in $Languages) {
    # Create a temporary copy of the translated version of the page
    Try{
    Copy-PnPFile -SourceUrl "SitePages/$($Language)/$($PageToTranslate)" -TargetUrl "SitePages/tmp-$($Language)-$($PageToTranslate)" -Overwrite -Force -ErrorAction Stop
    $NewPage=Get-PnPClientSidePage "tmp-$($Language)-$($PageToTranslate)"
    } Catch {
       # throw "There is no translation file available! Please go back on the Page and create a new Translation for the selected Language: $($PageToTranslate) "
       write-host -BackgroundColor Yellow -ForegroundColor Red "There is no translation file available! Please go back on the Page and create a new Translation for the selected Language: $($Language) "
       Break
    }
    
    # Translate the Title first
    #$translatedTitleText = ConvertTo-AnotherLanguage -TargetLanguage $Language -textToConvert $Page.PageTitle
    $translatedTitleText = Start-Translation -Language $Language -Text $Page.PageTitle -APIKey $APIKey
    $return=Set-PnPPage -Identity $NewPage -Title $translatedTitleText -Name "tmp-$($Language)-$($PageToTranslate)" 

    foreach ($textControl in $textControls){
        #$translatedControlText = Start-Translation -text $textControl.Text -language $targetLanguage
        # Lets clean up some unwanted characters from the text control before translating.
        $textControl.Text=$textControl.Text.replace('&nbsp;','')
        #$translatedControlText = ConvertTo-AnotherLanguage -TargetLanguage $Language -textToConvert $textControl.Text
        $translatedControlText=Start-Translation -Language $Language -Text $textControl.Text -APIKey $APIKey       
       # $NewPage=Get-PnPClientSidePage "$($Language)-$($PageToTranslate)"

        # Translate the Title first
        #$translatedTitleText = ConvertTo-AnotherLanguage -TargetLanguage $Language -textToConvert $Page.PageTitle
        #Set-PnPPage -Identity $NewPage -Title $translatedTitleText -Name "$($Language)-$($PageToTranslate)" 

        #Set-PnPClientSideText -Page $NewPage -InstanceId $textControl.InstanceId -Text $translatedControlText
        $return=Set-PnPPageTextPart -Page $NewPage -InstanceId $textControl.InstanceId -Text $translatedControlText

    }
    # Now that we are done with translation, copy the files a to language folder, and delete temporary file.
    #Pause
    #Copy-PnPFile -SourceUrl "SitePages/$($Language)-$($PageToTranslate)" -TargetUrl "SitePages/$($Language)/$($PageToTranslate)" -Overwrite -Force
    Copy-PnPFile -SourceUrl "SitePages/tmp-$($Language)-$($PageToTranslate)" -TargetUrl "SitePages/$($Language)/$($PageToTranslate)" -Overwrite -Force
    Remove-PnPFile -SiteRelativeUrl  "SitePages/tmp-$($Language)-$($PageToTranslate)" -Force
    
}
Write-Host "Translation completed, please review." 

}


