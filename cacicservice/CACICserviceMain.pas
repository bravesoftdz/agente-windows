(**
---------------------------------------------------------------------------------------------------------------------------------------------------------------
Copyright 2000, 2001, 2002, 2003, 2004, 2005, 2006, 2007, 2008, 2009 Dataprev - Empresa de Tecnologia e Informa��es da Previd�ncia Social, Brasil

Este arquivo � parte do programa CACIC - Configurador Autom�tico e Coletor de Informa��es Computacionais

O CACIC � um software livre; voc� pode redistribui-lo e/ou modifica-lo dentro dos termos da Licen�a P�blica Geral GNU como
publicada pela Funda��o do Software Livre (FSF); na vers�o 2 da Licen�a, ou (na sua opini�o) qualquer vers�o.

Este programa � distribuido na esperan�a que possa ser  util, mas SEM NENHUMA GARANTIA; sem uma garantia implicita de ADEQUA��O a qualquer
MERCADO ou APLICA��O EM PARTICULAR. Veja a Licen�a P�blica Geral GNU para maiores detalhes.

Voc� deve ter recebido uma c�pia da Licen�a P�blica Geral GNU, sob o t�tulo "LICENCA.txt", junto com este programa, se n�o, escreva para a Funda��o do Software
Livre(FSF) Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
---------------------------------------------------------------------------------------------------------------------------------------------------------------
*)
unit CACICserviceMain;

interface
uses  Windows,
      Messages,
      SysUtils,
      Classes,
      SvcMgr,
      ExtCtrls,
      CACIC_Library,
      tlhelp32,
      JwaWinNT,    { As units com prefixo Jwa constam do Pacote Jedi_API22a }
      JwaWinBase,  { que pode ser obtido em  http://sourceforge.net/projects/jedi-apilib/files/JEDI%20Windows%20API/JEDI%20API%202.2a%20and%20WSCL%200.9.2a/jedi_api22a_jwscl092a.zip/download }
      JwaWtsApi32,
      JwaWinSvc,
      JwaWinType,
      JwaNtStatus,
      Registry;

var   intContaMinutos      : integer;
      g_oCacic             : TCACIC;
      strChkSisInfFileName : String;

const SE_DEBUG_NAME = 'SeDebugPrivilege';

type
  TCacicSustainService = class(TService)
    timerToCHKSIS: TTimer;
    procedure ServiceExecute(Sender: TService);
    procedure ServiceStart(Sender: TService; var Started: Boolean);
    procedure timerToCHKSISTimer(Sender: TObject);
    procedure ServiceStop(Sender: TService; var Stopped: Boolean);
    procedure ServiceShutdown(Sender: TService);
  private
    { Internal Start & Stop methods }
    Procedure WMEndSession(var Msg : TWMEndSession) ;  message WM_ENDSESSION;
    procedure ExecutaCACIC;
    function  startapp(p_TargetFolderName, p_ApplicationName : String) : integer;

  public
    { Public declarations }
    function GetServiceController: TServiceController; override;
  end;

var
  CacicSustainService: TCacicSustainService;

function  CreateEnvironmentBlock(var lpEnvironment: Pointer;
                                 hToken: THandle;
                                 bInherit: BOOL): BOOL; stdcall; external 'userenv';
function  DestroyEnvironmentBlock(pEnvironment: Pointer): BOOL; stdcall; external 'userenv';

implementation

uses ComObj;

{$R *.DFM}

// Solu��o adaptada a partir do exemplo contido em http://www.codeproject.com/KB/vista-security/VistaSessions.aspx?msg=2750630
// para execu��o a partir de token do WinLogon, possibilitando a exibi��o do �cone da aplica��o na bandeja do systray em plataforma Microsoft Windows VISTA.
function TCacicSustainService.startApp(p_TargetFolderName, p_ApplicationName : String) : integer;
var
   pi : PROCESS_INFORMATION;
   si : STARTUPINFO;
   bresult : boolean;
   dwSessionId,winlogonPid : DWORD;
   hUserToken,hUserTokenDup,hPToken,hProcess,hsnap : THANDLE;
   dwCreationFlags : DWORD;
   procEntry : TPROCESSENTRY32;
   winlogonSessId : DWORD;
   tp : TOKEN_PRIVILEGES;
   abcd, abc, dup : integer;
   lpenv : pointer;
   iResultOfCreateProcessAsUser : integer;

begin
  g_oCacic.writeDebugLog('startApp: ' + p_TargetFolderName + p_ApplicationName);
  Result := 0;
  bresult := false;

  //TOKEN_ADJUST_SESSIONID := 256;

  // Log the client on to the local computer.
  ServiceType := stWin32;
  dwSessionId := WTSGetActiveConsoleSessionId();
  hSnap := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  if (hSnap = INVALID_HANDLE_VALUE) then
    begin
      result := 1;
      g_oCacic.writeDebugLog('startApp: Error => INVALID_HANDLE_VALUE');
      exit;
    end;

  procEntry.dwSize := sizeof(TPROCESSENTRY32);

  if (not Process32First(hSnap, procEntry)) then
    begin
      result := 1;
      g_oCacic.writeDebugLog('startApp: Error => not Process32First');
      exit;
    end;

  repeat;
  if (comparetext(procEntry.szExeFile, 'winlogon.exe') = 0) then
    begin
      g_oCacic.writeDebugLog('startApp: Winlogon Founded');
      // We found a winlogon process...

      // make sure it's running in the console session

      winlogonSessId := 0;
      if (ProcessIdToSessionId(procEntry.th32ProcessID, winlogonSessId) and (winlogonSessId = dwSessionId)) then
        begin
          winlogonPid := procEntry.th32ProcessID;
          g_oCacic.writeDebugLog('startApp: ProcessIdToSessionId OK => ' + IntToStr(winlogonPid));
          break;
        end;
    end;

  until (not Process32Next(hSnap, procEntry));

  ////////////////////////////////////////////////////////////////////////

  WTSQueryUserToken(dwSessionId, hUserToken);
  dwCreationFlags := NORMAL_PRIORITY_CLASS or CREATE_NEW_CONSOLE;
  ZeroMemory(@si, sizeof(STARTUPINFO));
  si.cb := sizeof(STARTUPINFO);
  si.lpDesktop := 'winsta0\default';
  ZeroMemory(@pi, sizeof(pi));
  hProcess := OpenProcess(MAXIMUM_ALLOWED,FALSE,winlogonPid);

  if(not OpenProcessToken(hProcess,TOKEN_ADJUST_PRIVILEGES or TOKEN_QUERY
                 or TOKEN_DUPLICATE or TOKEN_ASSIGN_PRIMARY or TOKEN_ADJUST_SESSIONID
                          or TOKEN_READ or TOKEN_WRITE, hPToken)) then
    begin
      abcd := GetLastError();
      g_oCacic.writeDebugLog('startApp: Process token open Error => ' + inttostr(GetLastError()));
    end;

  if (not LookupPrivilegeValue(nil,SE_DEBUG_NAME,tp.Privileges[0].Luid)) then
      g_oCacic.writeDebugLog('startApp: Lookup Privilege value Error => ' + inttostr(GetLastError()));

  tp.PrivilegeCount := 1;
  tp.Privileges[0].Attributes := SE_PRIVILEGE_ENABLED;

  DuplicateTokenEx(hPToken,MAXIMUM_ALLOWED,Nil,SecurityIdentification,TokenPrimary,hUserTokenDup);
  dup := GetLastError();

  // Adjust Token privilege

  SetTokenInformation(hUserTokenDup,TokenSessionId,pointer(dwSessionId),sizeof(DWORD));

  if (not AdjustTokenPrivileges(hUserTokenDup,FALSE,@tp,sizeof(TOKEN_PRIVILEGES),nil,nil)) then
    begin
      abc := GetLastError();
      g_oCacic.writeDebugLog('startApp: Adjust Privilege value Error => ' + inttostr(GetLastError()));
    end;

  if (GetLastError() = ERROR_NOT_ALL_ASSIGNED) then
      g_oCacic.writeDebugLog('startApp: Token does not have the provilege');

  lpEnv := nil;

  if(CreateEnvironmentBlock(lpEnv,hUserTokenDup,TRUE)) then
      dwCreationFlags := dwCreationFlags or CREATE_UNICODE_ENVIRONMENT
  else
    lpEnv := nil;

  // Launch the process in the client's logon session.
  bResult := CreateProcessAsUser( hUserTokenDup,                        // client's access token
                                  PAnsiChar(p_TargetFolderName + p_ApplicationName), // file to execute
                                  nil,                                  // command line
                                  nil,                                  // pointer to process SECURITY_ATTRIBUTES
                                  nil,                                  // pointer to thread SECURITY_ATTRIBUTES
                                  FALSE,                                // handles are not inheritable
                                  dwCreationFlags,                      // creation flags
                                  lpEnv,                                // pointer to new environment block
                                  PAnsiChar(p_TargetFolderName),   // name of current directory
                                  si,                                   // pointer to STARTUPINFO structure
                                  pi                                    // receives information about new process
                                 );

  // End impersonation of client.
  //GetLastError Shud be 0
  iResultOfCreateProcessAsUser := GetLastError();

  //Perform All the Close Handles tasks
  CloseHandle(hProcess);
  CloseHandle(hUserToken);
  CloseHandle(hUserTokenDup);
  CloseHandle(hPToken);
end;
//
procedure TCacicSustainService.WMEndSession(var Msg : TWMEndSession) ;
begin
  if Msg.EndSession = TRUE then
    g_oCacic.writeDailyLog('WMEndSession: Windows finalizado em ' + FormatDateTime('dd/mm hh:nn:ss : ', Now)) ;
  inherited;
  Application.Free;
end;

procedure ServiceController(CtrlCode: DWord); stdcall;
begin
  CacicSustainService.Controller(CtrlCode);
end;

function TCacicSustainService.GetServiceController: TServiceController;
begin
  Result := ServiceController;
end;

procedure TCacicSustainService.ServiceExecute(Sender: TService);
begin
  Try
    Application.Initialize;

    { Loop while service is active in SCM }
    While NOT Terminated do
      Begin
        { Process Service Requests }
        ServiceThread.ProcessRequests( False );
        { Allow system some time }
        Sleep(1);
      End;
  Except
    on e: exception do
      Begin
        g_oCacic.writeDebugLog('ServiceExecute: Erro => ' + e.Message);
      End;
  End;
end;

procedure TCacicSustainService.ServiceStart(Sender: TService; var Started: Boolean);
begin
  g_oCacic := TCACIC.Create;
  g_oCacic.setBoolCipher(true);

  strChkSisInfFileName := g_oCacic.getWinDir + 'chksis.inf';
  g_oCacic.setLocalFolderName(g_oCacic.GetValueFromFile('Configs', 'LocalFolderName', strChkSisInfFileName));

  Started := False;
  try
    Started := True;
  except
    on E : Exception do
         g_oCacic.writeExceptionLog(E.Message,E.ClassName,'ServiceStart');
  end;

  // ATEN��O: A propriedade "Interactive" em FALSE para S.O. menor que VISTA inibe a exibi��o gr�fica para o servi�o e seus herdeiros,
  //          e assim o �cone da aplica��o n�o � mostrado na bandeja do sistema.
  Self.Interactive   := not g_oCacic.isWindowsGEVista;
  g_oCacic.setMainProgramName(g_oCacic.GetValueFromFile('Configs'   ,'MainProgramName'           , strChkSisInfFileName));
  g_oCacic.setMainProgramHash(g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Hash-Codes',g_oCacic.getMainProgramName , strChkSisInfFileName),false,true));


  g_oCacic.writeDebugLog('ServiceStart: O.S. Identification');
  g_oCacic.writeDebugLog('ServiceStart: ************************************************');
  g_oCacic.writeDebugLog('ServiceStart: isWindowsVista => '        + g_oCacic.getBoolToString(g_oCacic.isWindowsVista       ) );
  g_oCacic.writeDebugLog('ServiceStart: isWindowsGEVista => '      + g_oCacic.getBoolToString(g_oCacic.isWindowsGEVista     ) );
  g_oCacic.writeDebugLog('ServiceStart: isWindowsXP => '           + g_oCacic.getBoolToString(g_oCacic.isWindowsXP          ) );
  g_oCacic.writeDebugLog('ServiceStart: isWindowsGEXP => '         + g_oCacic.getBoolToString(g_oCacic.isWindowsGEXP        ) );
  g_oCacic.writeDebugLog('ServiceStart: isWindowsNTPlataform => '  + g_oCacic.getBoolToString(g_oCacic.isWindowsNTPlataform ) );
  g_oCacic.writeDebugLog('ServiceStart: isWindows2000 => '         + g_oCacic.getBoolToString(g_oCacic.isWindows2000        ) );
  g_oCacic.writeDebugLog('ServiceStart: isWindowsNT => '           + g_oCacic.getBoolToString(g_oCacic.isWindowsNT          ) );
  g_oCacic.writeDebugLog('ServiceStart: isWindows9xME => '         + g_oCacic.getBoolToString(g_oCacic.isWindows9xME        ) );
  g_oCacic.writeDebugLog('ServiceStart: ************************************************');

  g_oCacic.writeDebugLog('ServiceStart: Interactive Mode=> '       + g_oCacic.getBoolToString(Self.Interactive));
  g_oCacic.writeDebugLog('ServiceStart: LocalFolderName => '       + g_oCacic.getLocalFolderName);
  g_oCacic.writeDebugLog('ServiceStart: MainProgramName => '       + g_oCacic.getMainProgramName);
  g_oCacic.writeDebugLog('ServiceStart: MainProgramHash => '       + g_oCacic.getMainProgramHash);

  // Caso exista uma c�pia do chkSIS.exe supostamente baixada do servidor de updates, movo-a para a devida pasta
  if FileExists(g_oCacic.getLocalFolderName + 'Temp\chksis.exe') then
    Begin
      g_oCacic.writeDebugLog('ServiceStart: Encontrado "' + g_oCacic.getLocalFolderName + 'Temp\chksis.exe" com vers�o "' + g_oCacic.GetVersionInfo(g_oCacic.getLocalFolderName + 'Temp\chksis.exe') + '"');

      if (g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Hash-Codes', 'CHKSIS.EXE', strChkSisInfFileName),false,true)  = g_oCacic.getFileHash(g_oCacic.getLocalFolderName + 'Temp\chksis.exe')) then
        Begin
          g_oCacic.writeDebugLog('ServiceStart: Hash Code conferido! Movendo para ' + g_oCacic.getWinDir);

          CopyFile(PAnsiChar(g_oCacic.getLocalFolderName + 'Temp\chksis.exe'),PAnsiChar(g_oCacic.getWinDir + 'chksis.exe'),false);
          Sleep(2000);

          // A fun��o MoveFile n�o estava excluindo o arquivo da origem. (???)
          g_oCacic.deleteFileOrFolder(g_oCacic.getLocalFolderName + 'Temp\chksis.exe');
          Sleep(2000);
        End;
    End;

  // Como o servi�o est� iniciando, executo o Verificador de Integridade...
  Try
    if (g_oCacic.isWindowsGEVista) then
      Begin
        g_oCacic.writeDebugLog('ServiceStart: Ativando StartAPP('+g_oCacic.getWinDir+',chksis.exe)');
        CacicSustainService.startapp(g_oCacic.getWinDir,'chksis.exe')
      End
    else
      Begin
        g_oCacic.writeDebugLog('ServiceStart: Ativando CreateSampleProcess(' + g_oCacic.getWinDir + 'chksis.exe)');
        g_oCacic.createOneProcess(g_oCacic.getWinDir + 'chksis.exe',false,SW_HIDE);
      End;
  Except
    on E : Exception do
       g_oCacic.writeExceptionLog(E.Message,E.ClassName,'ExecutaCACIC');
  End;

  Sleep(5000); // Espera de 5 segundos para o caso de ter sido baixado o Agente Principal...

  ExecutaCACIC;

  // Intervalo de 1 minuto (60 segundos)
  // Normalmente a cada 120 minutos (2 horas) acontecer� a chamada ao chkSIS
  timerToCHKSIS.Interval := 60000;
  timerToCHKSIS.Enabled  := true;
end;

procedure TCacicSustainService.ExecutaCACIC;
Begin
  g_oCacic.writeDebugLog('ExecutaCACIC: BEGIN');

  g_oCacic.writeDebugLog('ExecutaCACIC: deleteFile => '+g_oCacic.getLocalFolderName + 'aguarde_CACIC.txt');
  DeleteFile(PAnsiChar(g_oCacic.getLocalFolderName + 'aguarde_CACIC.txt'));
  DeleteFile(PAnsiChar(g_oCacic.getLocalFolderName + 'Temp\aguarde_UPDATE.txt'));
  Sleep(2000);

  // Caso exista uma c�pia do chkSIS.exe supostamente baixada do servidor de updates, movo-a para a devida pasta
  if FileExists(g_oCacic.getLocalFolderName + 'Temp\chksis.exe') then
    Begin
      g_oCacic.writeDebugLog('ExecutaCACIC: Encontrado "' + g_oCacic.getLocalFolderName + 'Temp\chksis.exe" com vers�o "' + g_oCacic.GetVersionInfo(g_oCacic.getLocalFolderName + 'Temp\chksis.exe') + '"');

      if (g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Hash-Codes', 'CHKSIS.EXE', strChkSisInfFileName),false,true)  = g_oCacic.getFileHash(g_oCacic.getLocalFolderName + 'Temp\chksis.exe')) then
        Begin
          g_oCacic.writeDebugLog('ExecutaCACIC: Hash Code conferido! Movendo para ' + g_oCacic.getWinDir);

          CopyFile(PAnsiChar(g_oCacic.getLocalFolderName + 'Temp\chksis.exe'),PAnsiChar(g_oCacic.getWinDir + 'chksis.exe'),false);
          Sleep(2000);

          // A fun��o MoveFile n�o estava excluindo o arquivo da origem. (???)
          g_oCacic.deleteFileOrFolder(g_oCacic.getLocalFolderName + 'Temp\chksis.exe');
          Sleep(2000);
        End
      else
        Begin
          g_oCacic.writeDebugLog('ExecutaCACIC: HASH Codes diferentes: "'+ g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Hash-Codes', 'CHKSIS.EXE', strChkSisInfFileName),false,true) + '" e "'+g_oCacic.getFileHash(g_oCacic.getLocalFolderName + 'Temp\chksis.exe')+'"');
          g_oCacic.deleteFileOrFolder(g_oCacic.getLocalFolderName + 'Temp\chksis.exe');
          Sleep(2000);
          g_oCacic.writeDebugLog('ExecutaCACIC: C�pia n�o efetuada e arquivo apagado!');
        End;
    End;

  g_oCacic.writeDebugLog('ExecutaCACIC: Verificando "aguarde_CACIC.txt" e "aguarde_UPDATE.txt"');
  if (not (FileExists(g_oCacic.getLocalFolderName + 'aguarde_CACIC.txt')) and
      not (FileExists(g_oCacic.getLocalFolderName + 'Temp\aguarde_UPDATE.txt'))) or
      not FileExists(g_oCacic.getLocalFolderName + g_oCacic.getMainProgramName) or
     ((FileExists(g_oCacic.getLocalFolderName + 'aguarde_CACIC.txt')) and
      (FileExists(g_oCacic.getLocalFolderName + 'normal_CACIC.txt'))) then
    Begin
      g_oCacic.writeDebugLog('ExecutaCACIC: Verificando situa��o estranha com indicador de atividades e finaliza��o normal!');

      // Verifico se o arquivo indicador de finaliza��o normal tamb�m inexiste...
      if not FileExists(g_oCacic.getLocalFolderName + 'normal_CACIC.txt') or
         not FileExists(g_oCacic.getLocalFolderName + g_oCacic.getMainProgramName) or
            ((FileExists(g_oCacic.getLocalFolderName + 'aguarde_CACIC.txt')) and
             (FileExists(g_oCacic.getLocalFolderName + 'normal_CACIC.txt'))) then
        Begin
          g_oCacic.writeDebugLog('ExecutaCACIC: Invocando "chkSIS.exe" para verifica��o.');
          // Executo o CHKsis, verificando a estrutura do sistema
          Try
            if (g_oCacic.isWindowsGEVista) then
              Begin
                g_oCacic.writeDebugLog('ExecutaCACIC: Ativando StartAPP('+g_oCacic.getWinDir+',chksis.exe)');
                CacicSustainService.startapp(g_oCacic.getWinDir,'chksis.exe')
              End
            else
              Begin
                g_oCacic.writeDebugLog('ExecutaCACIC: Ativando CreateSampleProcess(' + g_oCacic.getWinDir + 'chksis.exe)');
                g_oCacic.createOneProcess(g_oCacic.getWinDir + 'chksis.exe',false,SW_HIDE);
              End;
          Except
            on E : Exception do
               g_oCacic.writeExceptionLog(E.Message,E.ClassName,'ExecutaCACIC');
          End;
      Sleep(5000); // Espera de 5 segundos para o caso de ter sido baixado o Agente Principal...

      if FileExists(g_oCacic.getLocalFolderName + 'Temp\' + g_oCacic.getMainProgramName) then
        Begin
          g_oCacic.writeDebugLog('ExecutaCACIC: Encontrado Agente Principal (' + g_oCacic.getLocalFolderName + 'Temp\' + g_oCacic.getMainProgramName + ') com vers�o "' + g_oCacic.GetVersionInfo(g_oCacic.getLocalFolderName + 'Temp\' + g_oCacic.getMainProgramName) + '" para atualiza��o');

          CopyFile(PAnsiChar(g_oCacic.getLocalFolderName + 'Temp\' + g_oCacic.getMainProgramName),PAnsiChar(g_oCacic.getLocalFolderName + g_oCacic.getMainProgramName),false);
          Sleep(2000);

          // A fun��o MoveFile n�o estava excluindo o arquivo da origem. (???)
          g_oCacic.deleteFileOrFolder(g_oCacic.getLocalFolderName + 'Temp\' + g_oCacic.getMainProgramName);
          Sleep(2000);

          // VERIFICO O HASH CODE DO AGENTE PRINCIPAL...
          g_oCacic.writeDebugLog('ExecutaCACIC: HASH Code do INI: "'+ g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Hash-Codes', g_oCacic.getMainProgramName , strChkSisInfFileName ),false,true)+'"');
          g_oCacic.writeDebugLog('ExecutaCACIC: HASH Code de      "'+g_oCacic.getLocalFolderName + g_oCacic.getMainProgramName+'": "'+g_oCacic.getFileHash(g_oCacic.getLocalFolderName + g_oCacic.getMainProgramName)+'"');
        End
      else
        g_oCacic.writeDebugLog('ExecutaCACIC: Arquivo "'+g_oCacic.getLocalFolderName + g_oCacic.getMainProgramName+'" N�O ENCONTRADO!');

      if (g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Hash-Codes', g_oCacic.getMainProgramName, strChkSisInfFileName),false,true) = g_oCacic.getFileHash(g_oCacic.getLocalFolderName + g_oCacic.getMainProgramName) ) then
        Begin
          g_oCacic.writeDebugLog('ExecutaCACIC: Agente Principal v�lido para execu��o!');
          // Executo o Agente Principal do CACIC
          if (g_oCacic.isWindowsGEVista) then
            CacicSustainService.startapp(g_oCacic.getLocalFolderName,g_oCacic.getMainProgramName)
          else
            g_oCacic.createOneProcess(g_oCacic.getLocalFolderName + g_oCacic.getMainProgramName,false,SW_NORMAL);
          end;
        End
      else
        g_oCacic.writeDebugLog('ExecutaCACIC: HASH Code do Agente Principal INV�LIDO ou DIFERENTE');
    End
  else
    g_oCacic.writeDebugLog('ExecutaCACIC: Cookie Bloqueado pelo Agente Principal ENCONTRADO - CACIC em Execu��o!');

  g_oCacic.writeDebugLog('ExecutaCACIC: Verificando exist�ncia de nova vers�o deste servi�o para atualiza��o.');
  // Verifico a exist�ncia de nova vers�o do servi�o e finalizo em caso positivo...
  if (FileExists(g_oCacic.getLocalFolderName + 'Temp\cacicservice.exe')) and
     (g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Hash-Codes', 'CACICSERVICE.EXE', strChkSisInfFileName),false,true) = g_oCacic.getFileHash(g_oCacic.getLocalFolderName + 'Temp\cacicservice.exe')) then
    Begin
        g_oCacic.writeDebugLog('ExecutaCACIC: CACICSERVICE.EXE_HASH => '+ g_oCacic.deCrypt( g_oCacic.GetValueFromFile('Hash-Codes', 'CACICSERVICE.EXE', strChkSisInfFileName),false,true) );
        g_oCacic.writeDebugLog('ExecutaCACIC: Terminando para execu��o de atualiza��o...');
        CacicSustainService.ServiceThread.ProcessRequests(true);
        CacicSustainService.ServiceThread.Terminate;
    End
  else
    g_oCacic.writeDebugLog('ExecutaCACIC: N�o foi encontrada nova vers�o disponibilizada deste servi�o.');

  g_oCacic.writeDebugLog('ExecutaCACIC: END');
End;

procedure TCacicSustainService.timerToCHKSISTimer(Sender: TObject);
begin
  timerToCHKSIS.Enabled := false;

  g_oCacic.writeDebugLog('Timer_CHKsisTimer: BEGIN');

  inc(intContaMinutos);

  // A cada 2 horas o Verificador de Integridade do Sistema ser� chamado
  // Caso o DEBUG esteja ativo esse intervalo se reduz a 2 minutos
  if (intContaMinutos = 120) or (g_oCacic.isInDebugMode and (intContaMinutos = 2))then
    Begin
      intContaMinutos := 0;
      g_oCacic.writeDebugLog('Timer_CHKsisTimer: Criando processo "'+g_oCacic.getWinDir + 'chksis.exe');
      Try
        if (g_oCacic.isWindowsGEVista) then
            CacicSustainService.startapp(g_oCacic.getWinDir,'chksis.exe')
        else
            g_oCacic.createOneProcess(g_oCacic.getWinDir + 'chksis.exe',false,SW_HIDE);
      Except
        on E : Exception do
            g_oCacic.writeExceptionLog(E.Message,E.ClassName,'timerToChkSIS');
      End;
    End;

  g_oCacic.writeDebugLog('Timer_CHKsisTimer: Chamando ExecutaCACIC...');

  ExecutaCACIC;

  if timerToCHKSIS.Interval <> 60000 then
    timerToCHKSIS.Interval := 60000;
    
  timerToCHKSIS.Enabled := true;
  g_oCacic.writeDebugLog('Timer_CHKsisTimer: END');
end;

procedure TCacicSustainService.ServiceStop(Sender: TService;
  var Stopped: Boolean);
begin
  g_oCacic.writeDebugLog('ServiceStop: BEGIN');
  try
    Stopped := True; // always stop service, even if we had exceptions, this is to prevent "stuck" service (must reboot then)
  except
    on E : Exception do
       g_oCacic.writeExceptionLog(E.Message,E.ClassName,'ServiceStop');
  end;
  g_oCacic.writeDebugLog('ServiceStop: END');
end;

procedure TCacicSustainService.ServiceShutdown(Sender: TService);
var Stopped : boolean;
begin
  // is called when windows shuts down
  ServiceStop(Self, Stopped);
end;

end.
