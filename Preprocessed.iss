; Script generated by the Inno Setup Script Wizard.
; SEE THE DOCUMENTATION FOR DETAILS ON CREATING INNO SETUP SCRIPT FILES!
; -- CodeDependencies.iss --
;
; This script shows how to download and install any dependency such as .NET,
; Visual C++ or SQL Server during your application's installation process.
;
; contribute: https://github.com/DomGries/InnoDependencyInstaller
; -----------
; SHARED CODE
; -----------
[Code]
type
  TDependency_Entry = record
    Filename: String;
    Parameters: String;
    Title: String;
    URL: String;
    Checksum: String;
    ForceSuccess: Boolean;
    RestartAfter: Boolean;
  end;
var
  Dependency_Memo: String;
  Dependency_List: array of TDependency_Entry;
  Dependency_NeedRestart, Dependency_ForceX86: Boolean;
  Dependency_DownloadPage: TDownloadWizardPage;
procedure Dependency_Add(const Filename, Parameters, Title, URL, Checksum: String; const ForceSuccess, RestartAfter: Boolean);
var
  Dependency: TDependency_Entry;
  DependencyCount: Integer;
begin
  Dependency_Memo := Dependency_Memo + #13#10 + '%1' + Title;
  Dependency.Filename := Filename;
  Dependency.Parameters := Parameters;
  Dependency.Title := Title;
  if FileExists(ExpandConstant('{tmp}{\}') + Filename) then begin
    Dependency.URL := '';
  end else begin
    Dependency.URL := URL;
  end;
  Dependency.Checksum := Checksum;
  Dependency.ForceSuccess := ForceSuccess;
  Dependency.RestartAfter := RestartAfter;
  DependencyCount := GetArrayLength(Dependency_List);
  SetArrayLength(Dependency_List, DependencyCount + 1);
  Dependency_List[DependencyCount] := Dependency;
end;
<event('InitializeWizard')>
procedure Dependency_Internal1;
begin
  Dependency_DownloadPage := CreateDownloadPage(SetupMessage(msgWizardPreparing), SetupMessage(msgPreparingDesc), nil);
end;
<event('PrepareToInstall')>
function Dependency_Internal2(var NeedsRestart: Boolean): String;
var
  DependencyCount, DependencyIndex, ResultCode: Integer;
  Retry: Boolean;
  TempValue: String;
begin
  DependencyCount := GetArrayLength(Dependency_List);
  if DependencyCount > 0 then begin
    Dependency_DownloadPage.Show;
    for DependencyIndex := 0 to DependencyCount - 1 do begin
      if Dependency_List[DependencyIndex].URL <> '' then begin
        Dependency_DownloadPage.Clear;
        Dependency_DownloadPage.Add(Dependency_List[DependencyIndex].URL, Dependency_List[DependencyIndex].Filename, Dependency_List[DependencyIndex].Checksum);
        Retry := True;
        while Retry do begin
          Retry := False;
          try
            Dependency_DownloadPage.Download;
          except
            if Dependency_DownloadPage.AbortedByUser then begin
              Result := Dependency_List[DependencyIndex].Title;
              DependencyIndex := DependencyCount;
            end else begin
              case SuppressibleMsgBox(AddPeriod(GetExceptionMessage), mbError, MB_ABORTRETRYIGNORE, IDIGNORE) of
                IDABORT: begin
                  Result := Dependency_List[DependencyIndex].Title;
                  DependencyIndex := DependencyCount;
                end;
                IDRETRY: begin
                  Retry := True;
                end;
              end;
            end;
          end;
        end;
      end;
    end;
    if Result = '' then begin
      for DependencyIndex := 0 to DependencyCount - 1 do begin
        Dependency_DownloadPage.SetText(Dependency_List[DependencyIndex].Title, '');
        Dependency_DownloadPage.SetProgress(DependencyIndex + 1, DependencyCount + 1);
        while True do begin
          ResultCode := 0;
          if ShellExec('', ExpandConstant('{tmp}{\}') + Dependency_List[DependencyIndex].Filename, Dependency_List[DependencyIndex].Parameters, '', SW_SHOWNORMAL, ewWaitUntilTerminated, ResultCode) then begin
            if Dependency_List[DependencyIndex].RestartAfter then begin
              if DependencyIndex = DependencyCount - 1 then begin
                Dependency_NeedRestart := True;
              end else begin
                NeedsRestart := True;
                Result := Dependency_List[DependencyIndex].Title;
              end;
              break;
            end else if (ResultCode = 0) or Dependency_List[DependencyIndex].ForceSuccess then begin // ERROR_SUCCESS (0)
              break;
            end else if ResultCode = 1641 then begin // ERROR_SUCCESS_REBOOT_INITIATED (1641)
              NeedsRestart := True;
              Result := Dependency_List[DependencyIndex].Title;
              break;
            end else if ResultCode = 3010 then begin // ERROR_SUCCESS_REBOOT_REQUIRED (3010)
              Dependency_NeedRestart := True;
              break;
            end;
          end;
          case SuppressibleMsgBox(FmtMessage(SetupMessage(msgErrorFunctionFailed), [Dependency_List[DependencyIndex].Title, IntToStr(ResultCode)]), mbError, MB_ABORTRETRYIGNORE, IDIGNORE) of
            IDABORT: begin
              Result := Dependency_List[DependencyIndex].Title;
              break;
            end;
            IDIGNORE: begin
              break;
            end;
          end;
        end;
        if Result <> '' then begin
          break;
        end;
      end;
      if NeedsRestart then begin
        TempValue := '"' + ExpandConstant('{srcexe}') + '" /restart=1 /LANG="' + ExpandConstant('{language}') + '" /DIR="' + WizardDirValue + '" /GROUP="' + WizardGroupValue + '" /TYPE="' + WizardSetupType(False) + '" /COMPONENTS="' + WizardSelectedComponents(False) + '" /TASKS="' + WizardSelectedTasks(False) + '"';
        if WizardNoIcons then begin
          TempValue := TempValue + ' /NOICONS';
        end;
        RegWriteStringValue(HKA, 'SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce', '', TempValue);
      end;
    end;
    Dependency_DownloadPage.Hide;
  end;
end;
<event('UpdateReadyMemo')>
function Dependency_Internal3(const Space, NewLine, MemoUserInfoInfo, MemoDirInfo, MemoTypeInfo, MemoComponentsInfo, MemoGroupInfo, MemoTasksInfo: String): String;
begin
  Result := '';
  if MemoUserInfoInfo <> '' then begin
    Result := Result + MemoUserInfoInfo + Newline + NewLine;
  end;
  if MemoDirInfo <> '' then begin
    Result := Result + MemoDirInfo + Newline + NewLine;
  end;
  if MemoTypeInfo <> '' then begin
    Result := Result + MemoTypeInfo + Newline + NewLine;
  end;
  if MemoComponentsInfo <> '' then begin
    Result := Result + MemoComponentsInfo + Newline + NewLine;
  end;
  if MemoGroupInfo <> '' then begin
    Result := Result + MemoGroupInfo + Newline + NewLine;
  end;
  if MemoTasksInfo <> '' then begin
    Result := Result + MemoTasksInfo;
  end;
  if Dependency_Memo <> '' then begin
    if MemoTasksInfo = '' then begin
      Result := Result + SetupMessage(msgReadyMemoTasks);
    end;
    Result := Result + FmtMessage(Dependency_Memo, [Space]);
  end;
end;
<event('NeedRestart')>
function Dependency_Internal4: Boolean;
begin
  Result := Dependency_NeedRestart;
end;
function Dependency_IsX64: Boolean;
begin
  Result := not Dependency_ForceX86 and Is64BitInstallMode;
end;
function Dependency_String(const x86, x64: String): String;
begin
  if Dependency_IsX64 then begin
    Result := x64;
  end else begin
    Result := x86;
  end;
end;
function Dependency_ArchSuffix: String;
begin
  Result := Dependency_String('', '_x64');
end;
function Dependency_ArchTitle: String;
begin
  Result := Dependency_String(' (x86)', ' (x64)');
end;
function Dependency_IsNetCoreInstalled(const Version: String): Boolean;
var
  ResultCode: Integer;
begin
  if not FileExists(ExpandConstant('{tmp}{\}') + 'netcorecheck' + Dependency_ArchSuffix + '.exe') then begin
    ExtractTemporaryFile('netcorecheck' + Dependency_ArchSuffix + '.exe');
  end;
  StringChangeEx(Version, ' ', ' -v ', True)
  Result := ShellExec('', ExpandConstant('{tmp}{\}') + 'netcorecheck' + Dependency_ArchSuffix + '.exe', ' -n ' + Version, '', SW_HIDE, ewWaitUntilTerminated, ResultCode) and (ResultCode = 0);
end;
procedure Dependency_AddDotNet35;
begin
  if not IsDotNetInstalled(net35, 1) then begin
    Dependency_Add('dotnetfx35.exe',
      '/lang:enu /passive /norestart',
      '.NET Framework 3.5 Service Pack 1',
      'https://download.microsoft.com/download/2/0/E/20E90413-712F-438C-988E-FDAA79A8AC3D/dotnetfx35.exe',
      '', False, False);
  end;
end;
procedure Dependency_AddDotNet40;
begin
  if not IsDotNetInstalled(net4full, 0) then begin
    Dependency_Add('dotNetFx40_Full_setup.exe',
      '/lcid ' + IntToStr(GetUILanguage) + ' /passive /norestart',
      '.NET Framework 4.0',
      'https://download.microsoft.com/download/1/B/E/1BE39E79-7E39-46A3-96FF-047F95396215/dotNetFx40_Full_setup.exe',
      '', False, False);
  end;
end;
procedure Dependency_AddDotNet45;
begin
  if not IsDotNetInstalled(net452, 0) then begin
    Dependency_Add('dotnetfx45.exe',
      '/lcid ' + IntToStr(GetUILanguage) + ' /passive /norestart',
      '.NET Framework 4.5.2',
      'https://go.microsoft.com/fwlink/?LinkId=397707',
      '', False, False);
  end;
end;
procedure Dependency_AddDotNet46;
begin
  if not IsDotNetInstalled(net462, 0) then begin
    Dependency_Add('dotnetfx46.exe',
      '/lcid ' + IntToStr(GetUILanguage) + ' /passive /norestart',
      '.NET Framework 4.6.2',
      'https://go.microsoft.com/fwlink/?linkid=780596',
      '', False, False);
  end;
end;
procedure Dependency_AddDotNet47;
begin
  if not IsDotNetInstalled(net472, 0) then begin
    Dependency_Add('dotnetfx47.exe',
      '/lcid ' + IntToStr(GetUILanguage) + ' /passive /norestart',
      '.NET Framework 4.7.2',
      'https://go.microsoft.com/fwlink/?LinkId=863262',
      '', False, False);
  end;
end;
procedure Dependency_AddDotNet48;
begin
  if not IsDotNetInstalled(net48, 0) then begin
    Dependency_Add('dotnetfx48.exe',
      '/lcid ' + IntToStr(GetUILanguage) + ' /passive /norestart',
      '.NET Framework 4.8',
      'https://go.microsoft.com/fwlink/?LinkId=2085155',
      '', False, False);
  end;
end;
procedure Dependency_AddNetCore31;
begin
  if not Dependency_IsNetCoreInstalled('Microsoft.NETCore.App 3.1.22') then begin
    Dependency_Add('netcore31' + Dependency_ArchSuffix + '.exe',
      '/lcid ' + IntToStr(GetUILanguage) + ' /passive /norestart',
      '.NET Core Runtime 3.1.22' + Dependency_ArchTitle,
      Dependency_String('https://download.visualstudio.microsoft.com/download/pr/c2437aed-8cc4-41d0-a239-d6c7cf7bddae/062c37e8b06df740301c0bca1b0b7b9a/dotnet-runtime-3.1.22-win-x86.exe', 'https://download.visualstudio.microsoft.com/download/pr/4e95705e-1bb6-4764-b899-1b97eb70ea1d/dd311e073bd3e25b2efe2dcf02727e81/dotnet-runtime-3.1.22-win-x64.exe'),
      '', False, False);
  end;
end;
procedure Dependency_AddNetCore31Asp;
begin
  if not Dependency_IsNetCoreInstalled('Microsoft.AspNetCore.App 3.1.22') then begin
    Dependency_Add('netcore31asp' + Dependency_ArchSuffix + '.exe',
      '/lcid ' + IntToStr(GetUILanguage) + ' /passive /norestart',
      'ASP.NET Core Runtime 3.1.22' + Dependency_ArchTitle,
      Dependency_String('https://download.visualstudio.microsoft.com/download/pr/0a1a2ee5-b8ed-4f0d-a4af-a7bce9a9ac2b/d452039b49d79e8897f272c3ab34b875/aspnetcore-runtime-3.1.22-win-x86.exe', 'https://download.visualstudio.microsoft.com/download/pr/80e52143-31e8-450e-aa94-b3f8484aaba9/4b69e5c77d50e7b367960a0079c90a99/aspnetcore-runtime-3.1.22-win-x64.exe'),
      '', False, False);
  end;
end;
procedure Dependency_AddNetCore31Desktop;
begin
  if not Dependency_IsNetCoreInstalled('Microsoft.WindowsDesktop.App 3.1.22') then begin
    Dependency_Add('netcore31desktop' + Dependency_ArchSuffix + '.exe',
      '/lcid ' + IntToStr(GetUILanguage) + ' /passive /norestart',
      '.NET Desktop Runtime 3.1.22' + Dependency_ArchTitle,
      Dependency_String('https://download.visualstudio.microsoft.com/download/pr/e4fcd574-4487-4b4b-8ca8-c23177c6f59f/c6d67a04956169dc21895cdcb42bf344/windowsdesktop-runtime-3.1.22-win-x86.exe', 'https://download.visualstudio.microsoft.com/download/pr/1c14e24b-7f31-42dc-ba3c-83295a2d6f7e/41b93591162dfe556cc160ae44fbe75e/windowsdesktop-runtime-3.1.22-win-x64.exe'),
      '', False, False);
  end;
end;
procedure Dependency_AddDotNet50;
begin
  if not Dependency_IsNetCoreInstalled('Microsoft.NETCore.App 5.0.13') then begin
    Dependency_Add('dotnet50' + Dependency_ArchSuffix + '.exe',
      '/lcid ' + IntToStr(GetUILanguage) + ' /passive /norestart',
      '.NET Runtime 5.0.13' + Dependency_ArchTitle,
      Dependency_String('https://download.visualstudio.microsoft.com/download/pr/4a79fcd5-d61b-4606-8496-68071c8099c6/2bf770ca40521e8c4563072592eadd06/dotnet-runtime-5.0.13-win-x86.exe', 'https://download.visualstudio.microsoft.com/download/pr/fccf43d2-3e62-4ede-b5a5-592a7ccded7b/6339f1fdfe3317df5b09adf65f0261ab/dotnet-runtime-5.0.13-win-x64.exe'),
      '', False, False);
  end;
end;
procedure Dependency_AddDotNet50Asp;
begin
  if not Dependency_IsNetCoreInstalled('Microsoft.AspNetCore.App 5.0.13') then begin
    Dependency_Add('dotnet50asp' + Dependency_ArchSuffix + '.exe',
      '/lcid ' + IntToStr(GetUILanguage) + ' /passive /norestart',
      'ASP.NET Core Runtime 5.0.13' + Dependency_ArchTitle,
      Dependency_String('https://download.visualstudio.microsoft.com/download/pr/340f9482-fc43-4ef7-b434-e2ed57f55cb3/c641b805cef3823769409a6dbac5746b/aspnetcore-runtime-5.0.13-win-x86.exe', 'https://download.visualstudio.microsoft.com/download/pr/aac560f3-eac8-437e-aebd-9830119deb10/6a3880161cf527e4ec71f67efe4d91ad/aspnetcore-runtime-5.0.13-win-x64.exe'),
      '', False, False);
  end;
end;
procedure Dependency_AddDotNet50Desktop;
begin
  if not Dependency_IsNetCoreInstalled('Microsoft.WindowsDesktop.App 5.0.13') then begin
    Dependency_Add('dotnet50desktop' + Dependency_ArchSuffix + '.exe',
      '/lcid ' + IntToStr(GetUILanguage) + ' /passive /norestart',
      '.NET Desktop Runtime 5.0.13' + Dependency_ArchTitle,
      Dependency_String('https://download.visualstudio.microsoft.com/download/pr/c8125c6b-d399-4be3-b201-8f1394fc3b25/724758f754fc7b67daba74db8d6d91d9/windowsdesktop-runtime-5.0.13-win-x86.exe', 'https://download.visualstudio.microsoft.com/download/pr/2bfb80f2-b8f2-44b0-90c1-d3c8c1c8eac8/409dd3d3367feeeda048f4ff34b32e82/windowsdesktop-runtime-5.0.13-win-x64.exe'),
      '', False, False);
  end;
end;
procedure Dependency_AddDotNet60;
begin
  if not Dependency_IsNetCoreInstalled('Microsoft.NETCore.App 6.0.11') then begin
    Dependency_Add('dotnet60' + Dependency_ArchSuffix + '.exe',
      '/lcid ' + IntToStr(GetUILanguage) + ' /passive /norestart',
      '.NET Runtime 6.0.11' + Dependency_ArchTitle,
      Dependency_String('https://download.visualstudio.microsoft.com/download/pr/719bfd7c-bce2-4e73-937c-cbd7a7ace3cb/d4f570d461711d22e277f1e3487ea9c2/dotnet-runtime-6.0.11-win-x86.exe', 'https://download.visualstudio.microsoft.com/download/pr/8cf88855-ed09-4002-95db-8bb0f0eff051/f9006645511830bd3b840be132423768/dotnet-runtime-6.0.11-win-x64.exe'),
      '', False, False);
  end;
end;
procedure Dependency_AddDotNet60Asp;
begin
  if not Dependency_IsNetCoreInstalled('Microsoft.AspNetCore.App 6.0.11') then begin
    Dependency_Add('dotnet60asp' + Dependency_ArchSuffix + '.exe',
      '/lcid ' + IntToStr(GetUILanguage) + ' /passive /norestart',
      'ASP.NET Core Runtime 6.0.11' + Dependency_ArchTitle,
      Dependency_String('https://download.visualstudio.microsoft.com/download/pr/94504599-143a-4d53-b518-74aee0ebecca/dac4a7b1f7bdc7b4e8441d6befa4941a/aspnetcore-runtime-6.0.11-win-x86.exe', 'https://download.visualstudio.microsoft.com/download/pr/e874914f-d43d-4b61-8479-f6a5536e44b1/7043adfe896aa9f980ce23e884aae37d/aspnetcore-runtime-6.0.11-win-x64.exe'),
      '', False, False);
  end;
end;
procedure Dependency_AddDotNet60Desktop;
begin
  if not Dependency_IsNetCoreInstalled('Microsoft.WindowsDesktop.App 6.0.11') then begin
    Dependency_Add('dotnet60desktop' + Dependency_ArchSuffix + '.exe',
      '/lcid ' + IntToStr(GetUILanguage) + ' /passive /norestart',
      '.NET Desktop Runtime 6.0.11' + Dependency_ArchTitle,
      Dependency_String('https://download.visualstudio.microsoft.com/download/pr/2a392287-fd51-4ee8-9c15-a672ab9bc55d/03d4784b3a543a0fb9ce5677ed13a9a3/windowsdesktop-runtime-6.0.11-win-x86.exe', 'https://download.visualstudio.microsoft.com/download/pr/0192a249-3ec8-4374-a827-e186dd58d55d/cec046575f3eb2247a10ba3d50f5cf6c/windowsdesktop-runtime-6.0.11-win-x64.exe'),
      '', False, False);
  end;
end;
procedure Dependency_AddDotNet70;
begin
  if not Dependency_IsNetCoreInstalled('Microsoft.NETCore.App 7.0.3') then begin
    Dependency_Add('dotnet70' + Dependency_ArchSuffix + '.exe',
      '/lcid ' + IntToStr(GetUILanguage) + ' /passive /norestart',
      '.NET Runtime 7.0.3' + Dependency_ArchTitle,
      Dependency_String('https://download.visualstudio.microsoft.com/download/pr/9dd2da29-ca47-40fb-81a0-96fe26ea8ea2/e8f7e09a6d4848b8c4a13282d964b9e1/dotnet-runtime-7.0.3-win-x86.exe', 'https://download.visualstudio.microsoft.com/download/pr/c69813b7-2ece-4c2e-8c45-e33006985e18/61cc8fe4693a662b2da55ad932a46446/dotnet-runtime-7.0.3-win-x64.exe'),
      '', False, False);
  end;
end;
procedure Dependency_AddDotNet70Asp;
begin
  if not Dependency_IsNetCoreInstalled('Microsoft.AspNetCore.App 7.0.3') then begin
    Dependency_Add('dotnet70asp' + Dependency_ArchSuffix + '.exe',
      '/lcid ' + IntToStr(GetUILanguage) + ' /passive /norestart',
      'ASP.NET Core Runtime 7.0.3' + Dependency_ArchTitle,
      Dependency_String('https://download.visualstudio.microsoft.com/download/pr/4bf0f350-f947-408b-9ee4-539313b85634/b17087052d6192b5d59735ae6f208c19/aspnetcore-runtime-7.0.3-win-x86.exe', 'https://download.visualstudio.microsoft.com/download/pr/d37efccc-2ba1-4fc9-a1ef-a8e1e77fb681/b9a20fc29ff05f18d81620ec88ade699/aspnetcore-runtime-7.0.3-win-x64.exe'),
      '', False, False);
  end;
end;
procedure Dependency_AddDotNet70Desktop;
begin
  if not Dependency_IsNetCoreInstalled('Microsoft.WindowsDesktop.App 7.0.3') then begin
    Dependency_Add('dotnet70desktop' + Dependency_ArchSuffix + '.exe',
      '/lcid ' + IntToStr(GetUILanguage) + ' /passive /norestart',
      '.NET Desktop Runtime 7.0.3' + Dependency_ArchTitle,
      Dependency_String('https://download.visualstudio.microsoft.com/download/pr/fb8bf100-9e1c-472c-8bc8-aa16fff44f53/8d36f5a56edff8620f9c63c1e73ba88c/windowsdesktop-runtime-7.0.3-win-x86.exe', 'https://download.visualstudio.microsoft.com/download/pr/3ebf014d-fcb9-4200-b3fe-76ba2000b027/840f2f95833ce400a9949e35f1581d28/windowsdesktop-runtime-7.0.3-win-x64.exe'),
      '', False, False);
  end;
end;
procedure Dependency_AddVC2005;
begin
  if not IsMsiProductInstalled(Dependency_String('{86C9D5AA-F00C-4921-B3F2-C60AF92E2844}', '{A8D19029-8E5C-4E22-8011-48070F9E796E}'), PackVersionComponents(8, 0, 61000, 0)) then begin
    Dependency_Add('vcredist2005' + Dependency_ArchSuffix + '.exe',
      '/q',
      'Visual C++ 2005 Service Pack 1 Redistributable' + Dependency_ArchTitle,
      Dependency_String('https://download.microsoft.com/download/8/B/4/8B42259F-5D70-43F4-AC2E-4B208FD8D66A/vcredist_x86.EXE', 'https://download.microsoft.com/download/8/B/4/8B42259F-5D70-43F4-AC2E-4B208FD8D66A/vcredist_x64.EXE'),
      '', False, False);
  end;
end;
procedure Dependency_AddVC2008;
begin
  if not IsMsiProductInstalled(Dependency_String('{DE2C306F-A067-38EF-B86C-03DE4B0312F9}', '{FDA45DDF-8E17-336F-A3ED-356B7B7C688A}'), PackVersionComponents(9, 0, 30729, 6161)) then begin
    Dependency_Add('vcredist2008' + Dependency_ArchSuffix + '.exe',
      '/q',
      'Visual C++ 2008 Service Pack 1 Redistributable' + Dependency_ArchTitle,
      Dependency_String('https://download.microsoft.com/download/5/D/8/5D8C65CB-C849-4025-8E95-C3966CAFD8AE/vcredist_x86.exe', 'https://download.microsoft.com/download/5/D/8/5D8C65CB-C849-4025-8E95-C3966CAFD8AE/vcredist_x64.exe'),
      '', False, False);
  end;
end;
procedure Dependency_AddVC2010;
begin
  if not IsMsiProductInstalled(Dependency_String('{1F4F1D2A-D9DA-32CF-9909-48485DA06DD5}', '{5B75F761-BAC8-33BC-A381-464DDDD813A3}'), PackVersionComponents(10, 0, 40219, 0)) then begin
    Dependency_Add('vcredist2010' + Dependency_ArchSuffix + '.exe',
      '/passive /norestart',
      'Visual C++ 2010 Service Pack 1 Redistributable' + Dependency_ArchTitle,
      Dependency_String('https://download.microsoft.com/download/1/6/5/165255E7-1014-4D0A-B094-B6A430A6BFFC/vcredist_x86.exe', 'https://download.microsoft.com/download/1/6/5/165255E7-1014-4D0A-B094-B6A430A6BFFC/vcredist_x64.exe'),
      '', False, False);
  end;
end;
procedure Dependency_AddVC2012;
begin
  if not IsMsiProductInstalled(Dependency_String('{4121ED58-4BD9-3E7B-A8B5-9F8BAAE045B7}', '{EFA6AFA1-738E-3E00-8101-FD03B86B29D1}'), PackVersionComponents(11, 0, 61030, 0)) then begin
    Dependency_Add('vcredist2012' + Dependency_ArchSuffix + '.exe',
      '/passive /norestart',
      'Visual C++ 2012 Update 4 Redistributable' + Dependency_ArchTitle,
      Dependency_String('https://download.microsoft.com/download/1/6/B/16B06F60-3B20-4FF2-B699-5E9B7962F9AE/VSU_4/vcredist_x86.exe', 'https://download.microsoft.com/download/1/6/B/16B06F60-3B20-4FF2-B699-5E9B7962F9AE/VSU_4/vcredist_x64.exe'),
      '', False, False);
  end;
end;
procedure Dependency_AddVC2013;
begin
  if not IsMsiProductInstalled(Dependency_String('{B59F5BF1-67C8-3802-8E59-2CE551A39FC5}', '{20400CF0-DE7C-327E-9AE4-F0F38D9085F8}'), PackVersionComponents(12, 0, 40664, 0)) then begin
    Dependency_Add('vcredist2013' + Dependency_ArchSuffix + '.exe',
      '/passive /norestart',
      'Visual C++ 2013 Update 5 Redistributable' + Dependency_ArchTitle,
      Dependency_String('https://download.visualstudio.microsoft.com/download/pr/10912113/5da66ddebb0ad32ebd4b922fd82e8e25/vcredist_x86.exe', 'https://download.visualstudio.microsoft.com/download/pr/10912041/cee5d6bca2ddbcd039da727bf4acb48a/vcredist_x64.exe'),
      '', False, False);
  end;
end;
procedure Dependency_AddVC2015To2022;
begin
  if not IsMsiProductInstalled(Dependency_String('{65E5BD06-6392-3027-8C26-853107D3CF1A}', '{36F68A90-239C-34DF-B58C-64B30153CE35}'), PackVersionComponents(14, 30, 30704, 0)) then begin
    Dependency_Add('vcredist2022' + Dependency_ArchSuffix + '.exe',
      '/passive /norestart',
      'Visual C++ 2015-2022 Redistributable' + Dependency_ArchTitle,
      Dependency_String('https://aka.ms/vs/17/release/vc_redist.x86.exe', 'https://aka.ms/vs/17/release/vc_redist.x64.exe'),
      '', False, False);
  end;
end;
procedure Dependency_AddDirectX;
begin
  Dependency_Add('dxwebsetup.exe',
    '/q',
    'DirectX Runtime',
    'https://download.microsoft.com/download/1/7/1/1718CCC4-6315-4D8E-9543-8E28A4E18C4C/dxwebsetup.exe',
    '', True, False);
end;
procedure Dependency_AddSql2008Express;
var
  Version: String;
  PackedVersion: Int64;
begin
  if not RegQueryStringValue(HKLM, 'SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL10_50.MSSQLSERVER\MSSQLServer\CurrentVersion', 'CurrentVersion', Version) or not StrToVersion(Version, PackedVersion) or (ComparePackedVersion(PackedVersion, PackVersionComponents(10, 50, 4000, 0)) < 0) then begin
    Dependency_Add('sql2008express' + Dependency_ArchSuffix + '.exe',
      '/QS /IACCEPTSQLSERVERLICENSETERMS /ACTION=INSTALL /FEATURES=SQL /INSTANCENAME=MSSQLSERVER',
      'SQL Server 2008 R2 Service Pack 2 Express',
      Dependency_String('https://download.microsoft.com/download/0/4/B/04BE03CD-EAF3-4797-9D8D-2E08E316C998/SQLEXPR32_x86_ENU.exe', 'https://download.microsoft.com/download/0/4/B/04BE03CD-EAF3-4797-9D8D-2E08E316C998/SQLEXPR_x64_ENU.exe'),
      '', False, False);
  end;
end;
procedure Dependency_AddSql2012Express;
var
  Version: String;
  PackedVersion: Int64;
begin
  if not RegQueryStringValue(HKLM, 'SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQLServer\CurrentVersion', 'CurrentVersion', Version) or not StrToVersion(Version, PackedVersion) or (ComparePackedVersion(PackedVersion, PackVersionComponents(11, 0, 7001, 0)) < 0) then begin
    Dependency_Add('sql2012express' + Dependency_ArchSuffix + '.exe',
      '/QS /IACCEPTSQLSERVERLICENSETERMS /ACTION=INSTALL /FEATURES=SQL /INSTANCENAME=MSSQLSERVER',
      'SQL Server 2012 Service Pack 4 Express',
      Dependency_String('https://download.microsoft.com/download/B/D/E/BDE8FAD6-33E5-44F6-B714-348F73E602B6/SQLEXPR32_x86_ENU.exe', 'https://download.microsoft.com/download/B/D/E/BDE8FAD6-33E5-44F6-B714-348F73E602B6/SQLEXPR_x64_ENU.exe'),
      '', False, False);
  end;
end;
procedure Dependency_AddSql2014Express;
var
  Version: String;
  PackedVersion: Int64;
begin
  if not RegQueryStringValue(HKLM, 'SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQLServer\CurrentVersion', 'CurrentVersion', Version) or not StrToVersion(Version, PackedVersion) or (ComparePackedVersion(PackedVersion, PackVersionComponents(12, 0, 6024, 0)) < 0) then begin
    Dependency_Add('sql2014express' + Dependency_ArchSuffix + '.exe',
      '/QS /IACCEPTSQLSERVERLICENSETERMS /ACTION=INSTALL /FEATURES=SQL /INSTANCENAME=MSSQLSERVER',
      'SQL Server 2014 Service Pack 3 Express',
      Dependency_String('https://download.microsoft.com/download/3/9/F/39F968FA-DEBB-4960-8F9E-0E7BB3035959/SQLEXPR32_x86_ENU.exe', 'https://download.microsoft.com/download/3/9/F/39F968FA-DEBB-4960-8F9E-0E7BB3035959/SQLEXPR_x64_ENU.exe'),
      '', False, False);
  end;
end;
procedure Dependency_AddSql2016Express;
var
  Version: String;
  PackedVersion: Int64;
begin
  if not RegQueryStringValue(HKLM, 'SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQLServer\CurrentVersion', 'CurrentVersion', Version) or not StrToVersion(Version, PackedVersion) or (ComparePackedVersion(PackedVersion, PackVersionComponents(13, 0, 5026, 0)) < 0) then begin
    Dependency_Add('sql2016express' + Dependency_ArchSuffix + '.exe',
      '/QS /IACCEPTSQLSERVERLICENSETERMS /ACTION=INSTALL /FEATURES=SQL /INSTANCENAME=MSSQLSERVER',
      'SQL Server 2016 Service Pack 2 Express',
      'https://download.microsoft.com/download/3/7/6/3767D272-76A1-4F31-8849-260BD37924E4/SQLServer2016-SSEI-Expr.exe',
      '', False, False);
  end;
end;
procedure Dependency_AddSql2017Express;
var
  Version: String;
  PackedVersion: Int64;
begin
  if not RegQueryStringValue(HKLM, 'SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQLServer\CurrentVersion', 'CurrentVersion', Version) or not StrToVersion(Version, PackedVersion) or (ComparePackedVersion(PackedVersion, PackVersionComponents(14, 0, 0, 0)) < 0) then begin
    Dependency_Add('sql2017express' + Dependency_ArchSuffix + '.exe',
      '/QS /IACCEPTSQLSERVERLICENSETERMS /ACTION=INSTALL /FEATURES=SQL /INSTANCENAME=MSSQLSERVER',
      'SQL Server 2017 Express',
      'https://download.microsoft.com/download/5/E/9/5E9B18CC-8FD5-467E-B5BF-BADE39C51F73/SQLServer2017-SSEI-Expr.exe',
      '', False, False);
  end;
end;
procedure Dependency_AddSql2019Express;
var
  Version: String;
  PackedVersion: Int64;
begin
  if not RegQueryStringValue(HKLM, 'SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQLServer\CurrentVersion', 'CurrentVersion', Version) or not StrToVersion(Version, PackedVersion) or (ComparePackedVersion(PackedVersion, PackVersionComponents(15, 0, 0, 0)) < 0) then begin
    Dependency_Add('sql2019express' + Dependency_ArchSuffix + '.exe',
      '/QS /IACCEPTSQLSERVERLICENSETERMS /ACTION=INSTALL /FEATURES=SQL /INSTANCENAME=MSSQLSERVER',
      'SQL Server 2019 Express',
      'https://download.microsoft.com/download/7/f/8/7f8a9c43-8c8a-4f7c-9f92-83c18d96b681/SQL2019-SSEI-Expr.exe',
      '', False, False);
  end;
end;
procedure Dependency_AddWebView2;
begin
  if not RegValueExists(HKLM, Dependency_String('SOFTWARE', 'SOFTWARE\WOW6432Node') + '\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}', 'pv') then begin
    Dependency_Add('MicrosoftEdgeWebview2Setup.exe',
      '/silent /install',
      'WebView2 Runtime',
      'https://go.microsoft.com/fwlink/p/?LinkId=2124703',
      '', False, False);
  end;
end;
[Setup]
; -------------
; EXAMPLE SETUP
; -------------
[Setup]
; NOTE: The value of AppId uniquely identifies this application. Do not use the same AppId value in installers for other applications.
; (To generate a new GUID, click Tools | Generate GUID inside the IDE.)
AppId={{7774CEEE-6785-48B9-BA35-6B842F947A21}
AppName=Twitchy
AppVersion=0.5
DefaultDirName={autopf}\Twitchy
DisableProgramGroupPage=yes
LicenseFile=.\TwitchDesktopNotifications\Lisence.rtf
; Uncomment the following line to run in non administrative install mode (install for current user only.)
;PrivilegesRequired=lowest
OutputDir=.\SetupFiles
OutputBaseFilename=TwitchySetup
SetupIconFile=.\TwitchDesktopNotifications\Assets\icon.ico
UninstallDisplayIcon=.\TwitchDesktopNotifications\Assets\icon.ico
WizardSmallImageFile=.\TwitchDesktopNotifications\Assets\twitch.bmp
Compression=lzma
SolidCompression=yes
WizardStyle=modern
ArchitecturesInstallIn64BitMode=x64
SignedUninstaller=yes
SignTool=signtool
SourceDir=.\
[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked
Name: "autostarticon"; Description: "{cm:AutoStartProgram,Twitchy}"; GroupDescription: "{cm:AdditionalIcons}";
[Files]
Source: "TwitchDesktopNotifications\bin\Release\net6.0-windows10.0.17763.0\Twitchy.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "TwitchDesktopNotifications\bin\Release\net6.0-windows10.0.17763.0\Microsoft.Toolkit.Uwp.Notifications.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "TwitchDesktopNotifications\bin\Release\net6.0-windows10.0.17763.0\Microsoft.Windows.SDK.NET.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "TwitchDesktopNotifications\bin\Release\net6.0-windows10.0.17763.0\Twitchy.deps.json"; DestDir: "{app}"; Flags: ignoreversion
Source: "TwitchDesktopNotifications\bin\Release\net6.0-windows10.0.17763.0\Twitchy.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "TwitchDesktopNotifications\bin\Release\net6.0-windows10.0.17763.0\Twitchy.runtimeconfig.json"; DestDir: "{app}"; Flags: ignoreversion
Source: "TwitchDesktopNotifications\bin\Release\net6.0-windows10.0.17763.0\WinRT.Runtime.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "TwitchDesktopNotifications\bin\Release\net6.0-windows10.0.17763.0\Assets\icon.ico"; DestDir: "{app}\Assets"; Flags: ignoreversion
Source: "TwitchDesktopNotifications\bin\Release\net6.0-windows10.0.17763.0\Assets\twitch.png"; DestDir: "{app}\Assets"; Flags: ignoreversion
; NOTE: Don't use "Flags: ignoreversion" on any shared system files
Source: "netcorecheck.exe"; Flags: dontcopy noencryption
Source: "netcorecheck_x64.exe"; Flags: dontcopy noencryption
