(**
---------------------------------------------------------------------------------------------------------------------------------------------------------------
Copyright 2000, 2001, 2002, 2003, 2004, 2005 Dataprev - Empresa de Tecnologia e Informa��es da Previd�ncia Social, Brasil

Este arquivo � parte do programa CACIC - Configurador Autom�tico e Coletor de Informa��es Computacionais

O CACIC � um software livre; voc� pode redistribui-lo e/ou modifica-lo dentro dos termos da Licen�a P�blica Geral GNU como
publicada pela Funda��o do Software Livre (FSF); na vers�o 2 da Licen�a, ou (na sua opini�o) qualquer vers�o.

Este programa � distribuido na esperan�a que possa ser  util, mas SEM NENHUMA GARANTIA; sem uma garantia implicita de ADEQUA��O a qualquer
MERCADO ou APLICA��O EM PARTICULAR. Veja a Licen�a P�blica Geral GNU para maiores detalhes.

Voc� deve ter recebido uma c�pia da Licen�a P�blica Geral GNU, sob o t�tulo "LICENCA.txt", junto com este programa, se n�o, escreva para a Funda��o do Software
Livre(FSF) Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
---------------------------------------------------------------------------------------------------------------------------------------------------------------
*)

program chksis;
{$R *.res}

uses
  Windows,
  SysUtils,
  Classes,
  CACIC_Library in '..\CACIC_Library.pas',
  CACIC_Comm in '..\CACIC_Comm.pas',
  CACIC_VerifyAndGetModules in '..\CACIC_VerifyAndGetModules.pas',
  CACIC_WMI in '..\CACIC_WMI.pas';

var   objCacic                                : TCACIC;
      strChkSisInfFileName,
      strFieldsAndValuesToRequest,
      strGerColsInfFileName,
      strCommResponse                         : String;

function FindWindowByTitle(WindowTitle: string): Hwnd;
var
  NextHandle: Hwnd;
  ConHandle : Thandle;
  NextTitle: array[0..260] of char;
begin
  // Get the first window

  NextHandle := GetWindow(ConHandle, GW_HWNDFIRST);
  while NextHandle > 0 do
  begin
    // retrieve its text
    GetWindowText(NextHandle, NextTitle, 255);

    if (trim(StrPas(NextTitle))<> '') and (Pos(strlower(pchar(WindowTitle)), strlower(PChar(StrPas(NextTitle)))) <> 0) then
    begin
      Result := NextHandle;
      Exit;
    end
    else
      // Get the next window
      NextHandle := GetWindow(NextHandle, GW_HWNDNEXT);
  end;
  Result := 0;
end;

procedure executeChkSIS;
begin
  objCacic.writeDebugLog('executeChkSIS: getLocalFolderName => "'+objCacic.getLocalFolderName+'"');

  objCacic.writeDebugLog('executeChkSIS: Verificando exist�ncia da pasta "' + objCacic.getLocalFolderName+'"');
  // Verifico a exist�ncia do diret�rio configurado para o Cacic, normalmente CACIC
  if not DirectoryExists(objCacic.getLocalFolderName) then
      begin
        objCacic.writeDebugLog('executeChkSIS: Criando diret�rio ' + objCacic.getLocalFolderName);
        ForceDirectories(objCacic.getLocalFolderName);
      end;

  objCacic.writeDebugLog('executeChkSIS: Verificando exist�ncia da pasta "' + objCacic.getLocalFolderName + 'Modules"');
  // Para eliminar vers�o 20014 e anteriores que provavelmente n�o fazem corretamente o AutoUpdate
  if not DirectoryExists(objCacic.getLocalFolderName + 'Modules') then
      begin
        objCacic.writeDebugLog('executeChkSIS: Excluindo '+ objCacic.getLocalFolderName + objCacic.getMainProgramName);
        objCacic.deleteFileOrFolder(objCacic.getLocalFolderName + objCacic.getMainProgramName);
        objCacic.writeDebugLog('executeChkSIS: Criando diret�rio ' + objCacic.getLocalFolderName + 'Modules');
        ForceDirectories(objCacic.getLocalFolderName + 'Modules');
      end;

  objCacic.writeDebugLog('executeChkSIS: Verificando exist�ncia da pasta "' + objCacic.getLocalFolderName + 'Temp"');
  // Crio o SubDiret�rio TEMP, caso n�o exista
  if not DirectoryExists(objCacic.getLocalFolderName + 'Temp') then
      begin
        objCacic.writeDebugLog('executeChkSIS: Criando diret�rio ' + objCacic.getLocalFolderName + 'Temp');
        ForceDirectories(objCacic.getLocalFolderName + 'Temp');
      end;

  Try
     // Busco as configura��es para acesso ao ambiente FTP - Updates
     strFieldsAndValuesToRequest :=                               'in_instalacao=OK,';
     strFieldsAndValuesToRequest := strFieldsAndValuesToRequest + 'te_fila_ftp=1'; // Indicativo para entrada no grupo FTP

     objCacic.writeDebugLog('executeChkSIS: Efetuando chamada ao Gerente WEB com valores: "' + objCacic.getWebManagerAddress + objCacic.getWebServicesFolderName + 'get/config' + '", "' + objCacic.getLocalFolderName + '" e lista interna');
		 strCommResponse := Comm(objCacic.getWebManagerAddress + objCacic.getWebServicesFolderName + 'get/config', strFieldsAndValuesToRequest, objCacic.getLocalFolderName);

     if (strCommResponse <> '0') then
      Begin
        objCacic.setBoolCipher(not objCacic.isInDebugMode);
        objCacic.setMainProgramName(      objCacic.deCrypt(objCacic.getValueFromTags('MainProgramName'                     , strCommResponse, '<>')));
        objCacic.setMainProgramHash(      objCacic.deCrypt(objCacic.getValueFromTags(objCacic.getMainProgramName + '_HASH' , strCommResponse, '<>'),true,true));
        objCacic.setWebManagerAddress(    objCacic.deCrypt(objCacic.getValueFromTags('WebManagerAddress'                   , strCommResponse, '<>')));
        objCacic.setWebServicesFolderName(objCacic.deCrypt(objCacic.getValueFromTags('WebServicesFolderName'               , strCommResponse, '<>')));
        objCacic.setLocalFolderName(      objCacic.deCrypt(objCacic.getValueFromTags('LocalFolderName'                     , strCommResponse, '<>')));

        objCacic.writeDebugLog('executeChkSIS: Resposta: ' + strCommResponse);

        objCacic.setValueToFile('Configs'   ,'NmUsuarioLoginServUpdates', objCacic.getValueFromTags('nm_usuario_login_serv_updates'      , strCommResponse, '<>'), strChkSisInfFileName);
        objCacic.setValueToFile('Configs'   ,'NuPortaServUpdates'       , objCacic.getValueFromTags('nu_porta_serv_updates'              , strCommResponse, '<>'), strChkSisInfFileName);
        objCacic.setValueToFile('Configs'   ,'TePathServUpdates'        , objCacic.getValueFromTags('te_path_serv_updates'               , strCommResponse, '<>'), strChkSisInfFileName);
        objCacic.setValueToFile('Configs'   ,'TeSenhaLoginServUpdates'  , objCacic.getValueFromTags('te_senha_login_serv_updates'        , strCommResponse, '<>'), strChkSisInfFileName);
        objCacic.setValueToFile('Configs'   ,'TeServUpdates'            , objCacic.getValueFromTags('te_serv_updates'                    , strCommResponse, '<>'), strChkSisInfFileName);
        objCacic.setValueToFile('Configs'   ,'WebManagerAddress'        , objCacic.getValueFromTags('WebManagerAddress'                  , strCommResponse, '<>'), strChkSisInfFileName);
        objCacic.setValueToFile('Configs'   ,'WebServicesFolderName'    , objCacic.getValueFromTags('WebServicesFolderName'              , strCommResponse, '<>'), strChkSisInfFileName);
        objCacic.setValueToFile('Configs'   ,'apikey'                   , objCacic.getValueFromTags('apikey'                             , strCommResponse, '<>'), strChkSisInfFileName);
        objCacic.setValueToFile('Hash-Codes','CACICSERVICE.EXE'         , objCacic.getValueFromTags('CACICSERVICE.EXE_HASH'              , strCommResponse, '<>'), strChkSisInfFileName);
        objCacic.setValueToFile('Hash-Codes','CHKSIS.EXE'               , objCacic.getValueFromTags('CHKSIS.EXE_HASH'                    , strCommResponse, '<>'), strChkSisInfFileName);
        objCacic.setValueToFile('Hash-Codes','GERCOLS.EXE'              , objCacic.getValueFromTags('GERCOLS.EXE_HASH'                   , strCommResponse, '<>'), strChkSisInfFileName);
        objCacic.setValueToFile('Hash-Codes','MAPACACIC.EXE'            , objCacic.getValueFromTags('MAPACACIC.EXE_HASH'                 , strCommResponse, '<>'), strChkSisInfFileName);
        objCacic.setValueToFile('Hash-Codes',objCacic.getMainProgramName, objCacic.getValueFromTags(objCacic.getMainProgramName + '_HASH', strCommResponse, '<>'), strChkSisInfFileName);

        // Crio/Recrio/Atualizo o arquivo de configura��es do Agente Principal
        objCacic.writeDebugLog('executeChkSIS: Criando/Recriando ' + objCacic.getLocalFolderName + ChangeFileExt(LowerCase(objCacic.getMainProgramName) ,'.inf'));

        objCacic.writeDebugLog('executeChkSIS: :::::::::::::::: VALORES OBTIDOS NO Gerente WEB :::::::::::::::');
        objCacic.writeDebugLog('executeChkSIS: Endere�o no Servidor de aplica��o........: ' + objCacic.deCrypt(objCacic.getValueFromTags('WebManagerAddress'               , strCommResponse, '<>')));
        objCacic.writeDebugLog('executeChkSIS: Nome de Pasta para Interface com Agentes.: ' + objCacic.deCrypt(objCacic.getValueFromTags('WebServicesFolderName'           , strCommResponse, '<>')));
        objCacic.writeDebugLog('executeChkSIS: Servidor de updates......................: ' + objCacic.deCrypt(objCacic.getValueFromTags('te_serv_updates'                 , strCommResponse, '<>')));
        objCacic.writeDebugLog('executeChkSIS: Porta do servidor de updates.............: ' + objCacic.deCrypt(objCacic.getValueFromTags('nu_porta_serv_updates'           , strCommResponse, '<>')));
        objCacic.writeDebugLog('executeChkSIS: Usu�rio para login no servidor de updates: ' + objCacic.deCrypt(objCacic.getValueFromTags('nm_usuario_login_serv_updates'   , strCommResponse, '<>')));
        objCacic.writeDebugLog('executeChkSIS: Pasta no servidor de updates.............: ' + objCacic.deCrypt(objCacic.getValueFromTags('te_path_serv_updates'            , strCommResponse, '<>')));
        objCacic.writeDebugLog('executeChkSIS:  ');
        objCacic.writeDebugLog('executeChkSIS: Vers�es dos Agentes Principais:');
        objCacic.writeDebugLog('executeChkSIS: ------------------------------');
        objCacic.writeDebugLog('executeChkSIS: ' + objCacic.getMainProgramName+ ' - Agente Principal........: ' + objCacic.deCrypt(objCacic.getValueFromTags(objCacic.getMainProgramName + '_VER', strCommResponse, '<>')));
        objCacic.writeDebugLog('executeChkSIS: CACICservice - Servi�o de Sustenta��o: '                    + objCacic.deCrypt(objCacic.getValueFromTags('CACICSERVICE.EXE_VER'              , strCommResponse, '<>')));
        objCacic.writeDebugLog('executeChkSIS: GerCols - Gerente de Coletas.........: '                    + objCacic.deCrypt(objCacic.getValueFromTags('GERCOLS.EXE_VER'                   , strCommResponse, '<>')));
        objCacic.writeDebugLog('executeChkSIS: ChkSis   - Verificador de Integridade: '                    + objCacic.deCrypt(objCacic.getValueFromTags('CHKSIS.EXE_VER'                    , strCommResponse, '<>')));
        objCacic.writeDebugLog('executeChkSIS: ------------------------------');
        objCacic.writeDebugLog('executeChkSIS: Verificando exist�ncia do agente "' + objCacic.getLocalFolderName + LowerCase(objCacic.getMainProgramName)+'"');

        objCacic.deleteFileOrFolder(objCacic.getLocalFolderName + 'aguarde_CACIC.txt');

        // Auto verifica��o de vers�o
        verifyAndGetModules('chksis.exe',
                            objCacic.deCrypt(objCacic.getValueFromTags('CHKSIS.EXE_HASH', strCommResponse, '<>'),true,true),
                            objCacic.getWinDir,
                            objCacic.getLocalFolderName,
                            objCacic,
                            strChkSisInfFileName);

        // Verifica��o de vers�o do Agente Principal
        verifyAndGetModules(LowerCase(objCacic.getMainProgramName),
                                      objCacic.getMainProgramHash,
                                      objCacic.getLocalFolderName,
                                      objCacic.getLocalFolderName,
                                      objCacic,
                                      strChkSisInfFileName);

        // Verifica��o de vers�o do Agente Gerente de Coletas
        verifyAndGetModules('gercols.exe',
                            objCacic.deCrypt(objCacic.getValueFromTags('GERCOLS.EXE_HASH', strCommResponse, '<>'),true,true),
                            objCacic.getLocalFolderName + 'Modules',
                            objCacic.getLocalFolderName,
                            objCacic,
                            strChkSisInfFileName);

        // Verifica��o de vers�o do Servi�o de Sustenta��o do Agente CACIC
        verifyAndGetModules('cacicservice.exe',
                            objCacic.deCrypt(objCacic.getValueFromTags('CACICSERVICE.EXE_HASH', strCommResponse, '<>'),true,true),
                            objCacic.getWinDir,
                            objCacic.getLocalFolderName,
                            objCacic,
                            strChkSisInfFileName);

        // Verifica��o de vers�o do Mapa Cacic
        verifyAndGetModules('mapacacic.exe',
                            objCacic.deCrypt(objCacic.getValueFromTags('MAPACACIC.EXE_HASH', strCommResponse, '<>'),true,true),
                            objCacic.getLocalFolderName + 'Modules',
                            objCacic.getLocalFolderName,
                            objCacic,
                            strChkSisInfFileName);

        verifyAndGetModules('Cacic.msi',
                              '0',
                              objCacic.getLocalFolderName + 'Modules',
                              objCacic.getLocalFolderName,
                              objCacic,
                              strChkSisInfFileName);                            


        // 5 segundos para espera de poss�vel FTP em andamento...
        Sleep(5000);
      End
      else
      begin
        strCommResponse := Comm(objCacic.getWebManagerAddress + objCacic.getWebServicesFolderName + 'get/update', strFieldsAndValuesToRequest, objCacic.getLocalFolderName);
        if (strCommResponse <> '0') then
        begin
          objCacic.writeDailyLog('executeChkSIS: Iniciando segunda tentativa de comunica��o sem a obrigatoriedade do MAC');
          objCacic.setBoolCipher(not objCacic.isInDebugMode);
          objCacic.setMainProgramName(      objCacic.deCrypt(objCacic.getValueFromTags('MainProgramName'                     , strCommResponse, '<>')));
          objCacic.setMainProgramHash(      objCacic.deCrypt(objCacic.getValueFromTags(objCacic.getMainProgramName + '_HASH' , strCommResponse, '<>'),true,true));
          objCacic.setWebManagerAddress(    objCacic.deCrypt(objCacic.getValueFromTags('WebManagerAddress'                   , strCommResponse, '<>')));
          objCacic.setWebServicesFolderName(objCacic.deCrypt(objCacic.getValueFromTags('WebServicesFolderName'               , strCommResponse, '<>')));
          objCacic.setLocalFolderName(      objCacic.deCrypt(objCacic.getValueFromTags('LocalFolderName'                     , strCommResponse, '<>')));

          objCacic.writeDebugLog('executeChkSIS: Resposta: ' + strCommResponse);

          objCacic.setValueToFile('Configs'   ,'NmUsuarioLoginServUpdates', objCacic.getValueFromTags('nm_usuario_login_serv_updates'      , strCommResponse, '<>'), strChkSisInfFileName);
          objCacic.setValueToFile('Configs'   ,'NuPortaServUpdates'       , objCacic.getValueFromTags('nu_porta_serv_updates'              , strCommResponse, '<>'), strChkSisInfFileName);
          objCacic.setValueToFile('Configs'   ,'TePathServUpdates'        , objCacic.getValueFromTags('te_path_serv_updates'               , strCommResponse, '<>'), strChkSisInfFileName);
          objCacic.setValueToFile('Configs'   ,'TeSenhaLoginServUpdates'  , objCacic.getValueFromTags('te_senha_login_serv_updates'        , strCommResponse, '<>'), strChkSisInfFileName);
          objCacic.setValueToFile('Configs'   ,'TeServUpdates'            , objCacic.getValueFromTags('te_serv_updates'                    , strCommResponse, '<>'), strChkSisInfFileName);
          objCacic.setValueToFile('Configs'   ,'WebManagerAddress'        , objCacic.getValueFromTags('WebManagerAddress'                  , strCommResponse, '<>'), strChkSisInfFileName);
          objCacic.setValueToFile('Configs'   ,'WebServicesFolderName'    , objCacic.getValueFromTags('WebServicesFolderName'              , strCommResponse, '<>'), strChkSisInfFileName);
          objCacic.setValueToFile('Configs'   ,'apikey'                   , objCacic.getValueFromTags('apikey'                             , strCommResponse, '<>'), strChkSisInfFileName);
          objCacic.setValueToFile('Hash-Codes','CACICSERVICE.EXE'         , objCacic.getValueFromTags('CACICSERVICE.EXE_HASH'              , strCommResponse, '<>'), strChkSisInfFileName);
          objCacic.setValueToFile('Hash-Codes','CHKSIS.EXE'               , objCacic.getValueFromTags('CHKSIS.EXE_HASH'                    , strCommResponse, '<>'), strChkSisInfFileName);
          objCacic.setValueToFile('Hash-Codes','GERCOLS.EXE'              , objCacic.getValueFromTags('GERCOLS.EXE_HASH'                   , strCommResponse, '<>'), strChkSisInfFileName);
          objCacic.setValueToFile('Hash-Codes','MAPACACIC.EXE'            , objCacic.getValueFromTags('MAPACACIC.EXE_HASH'                 , strCommResponse, '<>'), strChkSisInfFileName);
          objCacic.setValueToFile('Hash-Codes',objCacic.getMainProgramName, objCacic.getValueFromTags(objCacic.getMainProgramName + '_HASH', strCommResponse, '<>'), strChkSisInfFileName);
          objCacic.deleteFileOrFolder(objCacic.getLocalFolderName + 'aguarde_CACIC.txt');

          // Auto verifica��o de vers�o
          verifyAndGetModules('chksis.exe',
                              objCacic.deCrypt(objCacic.getValueFromTags('CHKSIS.EXE_HASH', strCommResponse, '<>'),true,true),
                              objCacic.getWinDir,
                              objCacic.getLocalFolderName,
                              objCacic,
                              strChkSisInfFileName);

          // Verifica��o de vers�o do Agente Principal
          verifyAndGetModules(LowerCase(objCacic.getMainProgramName),
                                        objCacic.getMainProgramHash,
                                        objCacic.getLocalFolderName,
                                        objCacic.getLocalFolderName,
                                        objCacic,
                                        strChkSisInfFileName);

          // Verifica��o de vers�o do Agente Gerente de Coletas
          verifyAndGetModules('gercols.exe',
                              objCacic.deCrypt(objCacic.getValueFromTags('GERCOLS.EXE_HASH', strCommResponse, '<>'),true,true),
                              objCacic.getLocalFolderName + 'Modules',
                              objCacic.getLocalFolderName,
                              objCacic,
                              strChkSisInfFileName);

          // Verifica��o de vers�o do Servi�o de Sustenta��o do Agente CACIC
          verifyAndGetModules('cacicservice.exe',
                              objCacic.deCrypt(objCacic.getValueFromTags('CACICSERVICE.EXE_HASH', strCommResponse, '<>'),true,true),
                              objCacic.getWinDir,
                              objCacic.getLocalFolderName,
                              objCacic,
                              strChkSisInfFileName);

          // Verifica��o de vers�o do Mapa Cacic
          verifyAndGetModules('mapacacic.exe',
                              objCacic.deCrypt(objCacic.getValueFromTags('MAPACACIC.EXE_HASH', strCommResponse, '<>'),true,true),
                              objCacic.getLocalFolderName + 'Modules',
                              objCacic.getLocalFolderName,
                              objCacic,
                              strChkSisInfFileName);

          verifyAndGetModules('Cacic.msi',
                              '0',
                              objCacic.getLocalFolderName,
                              objCacic.getLocalFolderName,
                              objCacic,
                              strChkSisInfFileName);

          // 5 segundos para espera de poss�vel FTP em andamento...
          Sleep(5000);
        end;
      end;
           
  Except
    on E : Exception do
      Begin
        objCacic.writeExceptionLog(E.Message,E.ClassName,'Falha no contato com ' + objCacic.getWebManagerAddress + objCacic.getWebServicesFolderName + 'get/config');
        objCacic.writeDebugLog('executeChkSIS: Falha no contato com ' + objCacic.getWebManagerAddress  + objCacic.getWebServicesFolderName + 'get/config');
      End;
  End;

  //inicia instala��o do cacic se existir.
  if FileExists(objCacic.getLocalFolderName + 'Cacic.msi') and objCacic.getValueFromFile('Configs', 'apikey', strChkSisInfFileName) <> '' then
  begin
//  msiexec /i Cacic.msi /quiet /qn /norestart HOST=teste.cacic.cc USER=cacic PASS=cacic123
      objCacic.createOneProcess('msiexec /i ' + objCacic.getLocalFolderName + 'Cacic.msi' +
                                  ' /quiet /qn /norestart HOST=' + objCacic.getWebManagerAddress +
                                  ' USER=cacic' +
                                  ' PASS=' + objCacic.getValueFromFile('Configs', 'apikey', strChkSisInfFileName),
                                false);
  end;

  objCacic.deleteFileOrFolder(objCacic.getLocalFolderName + 'aguarde_CACIC.txt');
  // Caso o Cacic tenha sido baixado executo-o com par�metro de configura��o de servidor
  if Not FileExists(objCacic.getLocalFolderName + 'aguarde_CACIC.txt') then
    Begin
      if (objCacic.GetValueFromFile('Configs','NuExecApos', ChangeFileExt(objCacic.getMainProgramName,'.inf')) = '') then // Verifico se � uma primeira execu��o depois da instala��o
        strChkSisInfFileName := ''
      else
        strChkSisInfFileName := ' /execute';

      objCacic.writeDebugLog('executeChkSIS: Executando '+objCacic.getLocalFolderName + objCacic.getMainProgramName + ' /WebManagerAddress=' + objCacic.getWebManagerAddress + ' /WebServicesFolderName=' + objCacic.getWebServicesFolderName + strChkSisInfFileName);
      objCacic.createOneProcess(objCacic.getLocalFolderName + objCacic.getMainProgramName + ' /WebManagerAddress=' + objCacic.getWebManagerAddress + ' /WebServicesFolderName=' + objCacic.getWebServicesFolderName + strChkSisInfFileName, false)
    End;
end;

const APP_NAME = 'chksis.exe';

begin
   objCacic              := TCACIC.Create();
   objCacic.setBoolCipher(true);
   strChkSisInfFileName  := objCacic.getWinDir + 'chksis.inf';
   if( not objCacic.isAppRunning(PChar(APP_NAME) ) ) then
      Begin
       if (not objCacic.isAppRunning(PChar('installcacic'))) then
          Begin
            if(FileExists(strChkSisInfFileName)) and
              (objCacic.getValueFromFile('Configs','WebManagerAddress',strChkSisInfFileName) <> '') then
              Begin
                objCacic.setWebManagerAddress(objCacic.GetValueFromFile('Configs','WebManagerAddress', strChkSisInfFileName));
                objCacic.setWebServicesFolderName(objCacic.GetValueFromFile('Configs','WebServicesFolderName', strChkSisInfFileName));
                objCacic.setLocalFolderName(objCacic.GetValueFromFile('Configs','LocalFolderName', strChkSisInfFileName));
                objCacic.writeDebugLog('chkSIS: Verificando chamada');

                strGerColsInfFileName := objCacic.getLocalFolderName + 'gercols.inf';
                executeChkSIS;
              End
           else
              objCacic.writeDebugLog('chkSIS: Problema - Execu��o paralela ou inexist�ncia de configura��es! � necess�ria a execu��o do InstallCACIC!');
          End
       else
          objCacic.writeDebugLog('chkSIS: Oops! Encontrei Execu��o de InstallCACIC!');
      End
   else
      objCacic.writeDebugLog('chkSIS: Oops! Execu��o paralela!');
   objCacic.Free();
   Halt(0);
end.

