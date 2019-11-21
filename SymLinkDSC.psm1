enum Ensure { 
    Present
    Absent 
}

[DscResource()]
class SymLinkDSC {
    
    #region class properties

    [DscProperty(Key)]
    [string]$Name

    [DscProperty(Mandatory)]
    [String]$Source
    
    [DscProperty(Mandatory)]
    [string]$LinksFolder

    [DscProperty()]
    [Ensure]$Ensure = [Ensure]::Present
    
    [DscProperty(NotConfigurable)]
    [string]$Status    

    [SymLinkDSC] Get () {
        if ($this.Ensure -eq [Ensure]::Present) { 
            $this.Status = if ($this.Test()){
                'Created' 
            } else {
                'NotFound' 
            }
        } else {
            $this.Status = if ($this.Test()){
                'NotFound' 
            } else {
                'Created' 
            }    
    
        }
        return $this
    }
    
    [bool] Test () {
        if ($this.Ensure -eq [Ensure]::Present) { 
            try {
                if (-not (Test-Path -Path $this.Source)){
                    Write-Verbose "$($this.Source) not found"
                    return $false
                }
                            
                if (-not (Test-Path -Path $this.LinksFolder)){
                    Write-Verbose "$($this.LinksFolder) not found"
                    return $false
                }
        
                $executableFile = Join-Path -Path $this.LinksFolder -ChildPath $this.Name
                if (-not (Test-Path  -Path $executableFile)){
                    Write-Verbose "$executableFile not found"
                    return $false
                }

                return $true
            } catch {
                Write-Verbose "Test failed Error:  $_ $($_.ScriptStackTrace)"
                return $false
            }
        } else {
            $executableFile = Join-Path -Path $this.LinksFolder -ChildPath $this.Name
            if ((Test-Path -Path $executableFile)){
                Write-Verbose "$executableFile found"
                return $false
            }
            return $true
        }
    }
    
    [void] Set () {
        if ($this.Ensure -eq [Ensure]::Present) { 
            try {
                if (-not (Test-Path -Path $this.Source)){
                    throw "$($this.Source) not found, cannot install when target application does not exist"
                }
                
                if (-not (Test-Path -Path $this.LinksFolder)) {
                    throw "$($this.LinksFolder) not found, cannot install if destination folder does not exist"
                }
            
                New-Item -ItemType SymbolicLink -Path $this.LinksFolder -Name $this.Name -Value $this.Source -Force
            
            } catch {
                Write-Error "Set failed Error:  $_ $($_.ScriptStackTrace)"
            }
        } 
        else {
            $executableFile = Join-Path -Path $this.LinksFolder -ChildPath $this.Name
            try { 
                Remove-Item -Path $executableFile -Recurse -Force -ErrorAction Stop
            } catch {
                Write-Error "Cannot remove $executableFile"
            }
        }
    }
}