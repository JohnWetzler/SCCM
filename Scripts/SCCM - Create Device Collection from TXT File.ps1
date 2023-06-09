#Powershell script to Create collection in root with a list a computers in a text file.
# I adopted this technique to help with manual cleanup but this script can be used for multiple other purposes of creating custom collections.
# In addition, the script does create a log file validating if a CI is not found or the device is already added to the collection.
# Author - Vikram Bedi
# vikram.bedi.it@gmail.com


$collectiondir = "D:\Collections\"
md $collectopmdir 
    $collectionname = "SCCM_Removal_Collection"
    #Add new collection based on the file name
    try {
        New-CMDeviceCollection -Name $collectionname -LimitingCollectionName "All Systems"
        }
    catch {
        "Error creating collection - collection may already exist: $collectionname" | Out-File "$collectiondir\$collectionname`_invalid.log" -Append
        }

    #Read list of computers from the text file
    $computers = Get-Content "C:\users\User\desktop\SCCM_Removal.txt"
    foreach($computer in $computers) {
        try {
            Add-CMDeviceCollectionDirectMembershipRule  -CollectionName $collectionname -ResourceId $(get-cmdevice -Name $computer).ResourceID
            }
        catch {
            "Invalid client or direct membership rule may already exist: $computer" | Out-File "$collectiondir\$collectionname`_invalid.log" -Append
            }
    }
