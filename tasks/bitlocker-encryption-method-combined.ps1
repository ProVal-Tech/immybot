param(
    [Parameter(Position = 0, Mandatory = $False, HelpMessage = 'The encryption method to enforce.')]
    [ValidateSet('Aes128', 'Aes256', 'XtsAes128', 'XtsAes256')]
    [string]$EncryptionMethod = 'XtsAes256',
    [Parameter(Position = 1, Mandatory = $False, HelpMessage = 'The number of seconds to wait for the decryption process to complete.')]
    [int]$DecryptionWaitSeconds = 600
)

switch ($method) {
    'Get' {
        Invoke-ImmyCommand -ScriptBlock {
            $volumes = Get-BitLockerVolume
            foreach ($volume in $volumes) {
                $volume.EncryptionMethod
            }
        }
    }
    'Set' {
        Invoke-ImmyCommand -ScriptBlock {
            $decryptionWaitLoopDuration = 10
            $decryptionWaitLoopCount = [System.Math]::Ceiling($using:DecryptionWaitSeconds / $decryptionWaitLoopDuration)
            $volumes = Get-BitLockerVolume
            foreach ($volume in $volumes) {
                if ($volume.EncryptionStatus -ne 'FullyEncrypted') {
                    continue
                }
                if ($volume.EncryptionMethod -ne $using:EncryptionMethod) {
                    Disable-BitLocker -MountPoint $volume.MountPoint
                    for ($i = 0; $i -lt $decryptionWaitLoopCount; $i++) {
                        if ($volume.EncryptionStatus -eq 'FullyDecrypted') {
                            break
                        }
                        Start-Sleep -Seconds $decryptionWaitSeconds
                    }
                    Enable-BitLocker -MountPoint $volume.MountPoint -EncryptionMethod $using:EncryptionMethod
                }
            }
        }
    }
    'Test' {
        Invoke-ImmyCommand -ScriptBlock {
            $volumes = Get-BitLockerVolume
            $testResult = $true
            foreach ($volume in $volumes) {
                if ($volume.EncryptionMethod -ne $using:EncryptionMethod) {
                    $testResult = $false
                    break
                }
            }
            return $testResult
        }
    }
}