Function AddRandomToGroups 
{   
    [CmdletBinding()]
    
    param
    (
        [Parameter(Mandatory = $false,
            Position = 1,
            HelpMessage = 'Supply a result from get-addomain')]
        [Object[]]$Domain,
        
        [Parameter(Mandatory = $false,
            Position = 2,
            HelpMessage = 'Supply a result from get-aduser -filter *')]
        [Object[]]$UserList,
        
        [Parameter(Mandatory = $false,
            Position = 3,
            HelpMessage = 'Supply a result from Get-ADGroup -Filter { GroupCategory -eq "Security" -and GroupScope -eq "Global"  } -Properties isCriticalSystemObject')]
        [Object[]]$GroupList,
        
        [Parameter(Mandatory = $false,
            Position = 4,
            HelpMessage = 'Supply a result from Get-ADGroup -Filter { GroupScope -eq "domainlocal"  } -Properties isCriticalSystemObject')]
        [Object[]]$LocalGroupList,
        
        [Parameter(Mandatory = $false,
            Position = 5,
            HelpMessage = 'Supply a result from Get-ADComputer -f *')]
        [Object[]]$CompList
    )

    ##BEGIN STUFF
    if(!$PSBoundParameters.ContainsKey('Domain'))
    {
        $dom = Get-ADDomain
        $setDC = $dom.pdcemulator
        $dnsroot = $dom.dnsroot
        $dn = $dom.distinguishedname
    }
    else 
    {
        $setDC = $Domain.pdcemulator
        $dnsroot = $Domain.dnsroot
    }

    if(!$PSBoundParameters.ContainsKey('UserList'))
    {
        $allUsers = Get-ADUser -Filter *
    }
    else 
    {
        $allUsers = $UserList
    }
    
    if(!$PSBoundParameters.ContainsKey('GroupList'))
    {
        $allGroups = Get-ADGroup -Filter { GroupCategory -eq "Security"  } -Properties isCriticalSystemObject,admincount
    }
    else 
    {
        $allGroups = $GroupList
    }
    
    if(!$PSBoundParameters.ContainsKey('LocalGroupList'))
    {
        $allGroupsLocal = Get-ADGroup -Filter { GroupScope -eq "domainlocal"  } -Properties isCriticalSystemObject,admincount
    }
    else 
    {
        $allGroupsLocal = $LocalGroupList
    }
    
    if(!$PSBoundParameters.ContainsKey('CompList'))
    {
        $allcomps = Get-ADComputer -Filter *
    }
    else 
    {
        $allcomps = $CompList
    }
    
    #cd ad:

    # Pick X number of random users
    $UsersInGroupCount = [math]::Round($allusers.count * .8) #need to round to int. need to check this works
    $GroupsInGroupCount = [math]::Round($allGroups.count * .2)
    $CompsInGroupCount = [math]::Round($allcomps.count * .1)
    
    $AddUserstoGroups = Get-Random -count $UsersInGroupCount -InputObject $allUsers
    $allGroupsFiltered = $allGroups | where-object -Property iscriticalsystemobject -ne $true

   
    # Add a large number of users to a large number of non critical groups
    Foreach($user in $AddUserstoGroups)
    {
        #get how many groups
        $num = 1..10 | Get-Random
        $n = 0
        do{
            $randogroup = Get-Random -Count 1 -inputobject $allGroupsFiltered
            
            #add to group
            try
            {
                Add-ADGroupMember -Identity $randogroup -Members $user
            }
            catch{}

            $n++
        }
        while($n -le $num)
    }

    # add a few people to a small number of critical groups
    $allGroupsCrit = $allGroups | Where-Object {$_.admincount -eq '1' -and $_.name -notlike "*Domain Controllers*"} 
    $allGroupsCritRandom = $allGroupsCrit | Get-Random -Count 5

    ForEach($critgroup in $allGroupsCritRandom)
    {
        $num = 2..5 | Get-Random
        try
        {
            Add-ADGroupMember -Identity $($critgroup.name) -Members (Get-Random -count $num -InputObject $allUsers)
        }
        catch{}
    }

    # add a few people to a small number of critical local groups
    $allGroupsLocalNoAdmincount = $allGroupsLocal | Where-Object {$_.admincount -ne '1'}
    $GroupsLocalNoAdmincountRandom = $allGroupsLocalNoAdmincount | Get-Random -Count 13

    ForEach($localgroup in $GroupsLocalNoAdmincountRandom)
    {
        $num = 1..3 | Get-Random
    
        try
        {
            Add-ADGroupMember -Identity $localgroup.name -Members (Get-Random -count $num -InputObject $allUsers) 
        }
        catch{}
    }

    # add groups to groups
    $AddGroupstoGroups = Get-Random -Count $GroupsInGroupCount -InputObject $allGroupsFiltered

    Foreach($group in $AddGroupstoGroups)
    {
        #get how many groups
        $num = 1..2 | Get-Random
        $n = 0
        do
        {
            $randogroup = $allGroupsFiltered | Get-Random
            
            #add to group
            try
            {
                Add-ADGroupMember -Identity $randogroup -Members $group
            }
            catch{}
            $n++
        }
        while($n -le $num)
    }
    
    # add all critical groups to 2-5 other random groups
    ForEach($criticalgroup in $allGroupsCrit)
    {
        #get how many groups
        $num = 1..3 | Get-Random
        $n = 0
        do
        {
            $randogroup = $allGroupsFiltered | Get-Random
            
            #add to group
            try
            {
                Add-ADGroupMember -Identity $randogroup -Members $criticalgroup.name
            }
            catch{}
            $n++
        }
        while($n -le $num)
    }

    $addcompstoGroups = @()
    $addcompstogroups = Get-Random -count $compsInGroupCount -InputObject $allcomps

    ForEach($comp in $addcompstogroups)
    {
        #get how many groups
        $num = 1..5 | Get-Random
        $n = 0
        do
        {
            $randogroup = $allGroupsFiltered | Get-Random
            
            #add to group
            try
            {
                Add-ADGroupMember -Identity $randogroup -Members $comp
            }
            catch{}
            $n++
        }
        while($n -le $num)
    }
}

