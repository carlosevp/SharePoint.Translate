# SharePoint.Translate
This is still being tested and its considered beta. Use and improve as much as you would like and at your own risk.

## What is it
This simple module allows you to automatically translate SharePoint pages to multiple languages at a time.
You will need a API Key from MS Translate, which is free for up to 2MM characters a month.
Go here and grab your free API key: https://azure.microsoft.com/en-us/services/cognitive-services/translator/

## Inspiration and references
Idea was inspired by this post:
https://michalsacewicz.com/automatically-translate-news-on-multilingual-sharepoint-sites/

And PowerShell translation function was found in Reddit - I didnt want to reinvent the wheel.

Had to go with PowerShell because in my case there are Conditional Access Policies requiring MFA to talk to SharePoint.

## Pre-requisites
User running the script must have Site Owners permission to be able to create the new pages.
PnP.PowerShell module must be installed.
``` Install-Module PnP.PowerShell ``` 

## How to Use
Pretty easy - after you created your initial page and choose to generate all translations (which just stages a new file without translation)
you can use this script to automatically create all required translated files. 

More details on that:
https://support.microsoft.com/en-us/office/create-multilingual-communication-sites-pages-and-news-2bb7d610-5453-41c6-a0e8-6f40b3ed750c

Example:
```powershell

$global:apikey='12345 API Key you got from Azure Cognitive Services'

$Languages=@('fr';'es';'it';'de','pt-br','nl','fi','pl','sv','vi','zh-chs')

New-SharePointTranslation -$SharePointSite 'https://cyz.sharepoint.com/sites/MySite' -Languages $Languages -$PageToTranslate 'MyPage.aspx'
```

Post Validation:
Open each translated page for a quick validation that it looks OK. Common issues are usually related to special text formatting (Bold, Italic, Links, etc). 
Once validated, under Page Details, select the language to allow for proper indexing and save.

