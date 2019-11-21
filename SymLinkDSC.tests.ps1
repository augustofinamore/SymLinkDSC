using module ..\SymLinkDSC\SymLinkDSC.psd1

Import-Module $PSScriptRoot\StubModules\NativeCommands.Stub.psm1 -force

# Module with functions not available on buildserver

InModuleScope SymLinkDSC {
    $module = Get-Module -Name SymLinkDSC
    $resources = $module.ExportedDscResources

    switch ($resources) {
        SymLinkDSC {
            $SymLinkDSC = [SymLinkDSC]@{
                Name = 'TargetApp.exe'
                Source = 'testdrive:\SourceApps\Application.exe'
                LinksFolder = 'Testdrive:\SymLinks\'
                Ensure = [Ensure]::Present
            }
          
            Describe "Testing methods in $_" {
            
                    New-Item -ItemType Directory -Path 'Testdrive:\SymLinks\' -Force
                    New-Item -ItemType Directory -Path 'Testdrive:\SourceApps\' -Force
                    New-Item -ItemType File -Path 'Testdrive:\SourceApps\Application.exe' -Force
                    New-Item -ItemType File -Path 'Testdrive:\SymLinks\TargetApp.exe' -Force
                
                Mock -CommandName Remove-Item
                
                Mock -CommandName New-Item
                
                
                Context 'SymLink exists and should be present' {
                    Mock -CommandName Test-Path -MockWith {
                        $true
                    }

                    It 'Get should return ensure Present if the SymLink exists.' {
                        $SymLinkDSC.Get().ensure | Should -Be 'Present'
                    }                                        

                    It 'Get should return status Created if the SymLink exists.' {
                        $SymLinkDSC.Get().status | Should -Be 'Created'
                    }                    

                    It 'Test should return true if no changes are required' {
                        $SymLinkDSC.Test() | Should -BeTrue
                    }
                }
                
                Context 'SymLink exists and should be absent' {
                    $SymLinkDSC.Ensure = [Ensure]::Absent
                    Mock -CommandName Test-Path -MockWith {
                        $true
                    }

                    It 'Get should return ensure Absent if the SymLink should be removed.' {
                        $SymLinkDSC.Get().ensure | Should -Be 'Absent'
                    }
                    
                    It 'Test should return false if the SymLink is installed but should be absent' {
                        $SymLinkDSC.Test() | Should -BeFalse
                    }
                    
                    It 'Set should remove the SymLink correctly' {
                        $SymLinkDSC.Set()
                        Assert-MockCalled -CommandName Remove-Item -Exactly -Times 1 -Scope it
                    }
                }
                
                Context 'Missing SymLink which should be installed' {
                    $SymLinkDSC.Ensure = [Ensure]::Present
                    Mock -CommandName Test-Path -MockWith {
                        $false
                    }
                    
                    It 'Get should return status NotFound if SymLink is missing.' {
                        $SymLinkDSC.Get().Status | Should -Be 'NotFound'
                    }
                    
                    It 'Test should return false if changes are required' {
                        $SymLinkDSC.Test() | Should -BeFalse
                    }
                    Mock -CommandName Test-Path -MockWith {
                        $true
                    }
                    It 'Set should create the SymLink correctly' {
                        $SymLinkDSC.Set()
                        Assert-MockCalled -CommandName New-Item -Exactly -Times 1 -Scope it
                    }
                }
                
                Context 'Absent SymLink which should be absent' {
                    $SymLinkDSC.Ensure = [Ensure]::Absent
                    
                    Mock -CommandName Test-Path -MockWith {
                        $false
                    }
                    
                    It 'Get should return ensure absent if the SymLink is missing.' {
                        $SymLinkDSC.Get().Ensure | Should -Be 'Absent'
                    }
                    
                    It 'Get should return status NotFound if the SymLink is missing.' {
                        $SymLinkDSC.Get().Status | Should -Be 'NotFound'
                    }
                    
                    It 'Test should return true if changes no are required' {
                        $SymLinkDSC.Test() | Should -BeTrue
                    }
                }
            }
        }
        Default {
            throw "Resource $_ not supported. Please add tests for $_"
        }
    }
}