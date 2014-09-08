(*
---------------------------------------------------------------------------------------------------------------------------------------------------------------
Copyright 2000, 2001, 2002, 2003, 2004, 2005 Dataprev - Empresa de Tecnologia e Informa��es da Previd�ncia Social, Brasil

Este arquivo � parte do programa CACIC - Configurador Autom�tico e Coletor de Informa��es Computacionais

O CACIC � um software livre; voc� pode redistribui-lo e/ou modifica-lo dentro dos termos da Licen�a P�blica Geral GNU como
publicada pela Funda��o do Software Livre (FSF); na vers�o 2 da Licen�a, ou (na sua opini�o) qualquer vers�o.

Este programa � distribuido na esperan�a que possa ser  util, mas SEM NENHUMA GARANTIA; sem uma garantia implicita de ADEQUA��O a qualquer
MERCADO ou APLICA��O EM PARTICULAR. Veja a Licen�a P�blica Geral GNU para maiores detalhes.

Voc� deve ter recebido uma c�pia da Licen�a P�blica Geral GNU, sob o t�tulo "LICENCA.txt", junto com este programa, se n�o, escreva para a Funda��o do Software
Livre(FSF) Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

NOTA: O componente MiTeC System Information Component (MSIC) � baseado na classe TComponent e cont�m alguns subcomponentes baseados na classe TPersistent
      Este componente � apenas freeware e n�o open-source, e foi baixado de http://www.mitec.cz/Downloads/MSIC.zip
---------------------------------------------------------------------------------------------------------------------------------------------------------------
*)

program gercols;
{$R *.res}

uses
  Windows,
  SysUtils,
  Classes,
  StrUtils,
  Math,
  ActiveX,
  Registry,
  TLHELP32,
  JclRegistry,
  JclFileUtils,
  JclSysInfo,
  CACIC_Library in '..\CACIC_Library.pas',
  CACIC_Comm in '..\CACIC_Comm.pas',
  CACIC_VerifyAndGetModules in '..\CACIC_VerifyAndGetModules.pas',
  CACIC_WMI in '..\CACIC_WMI.pas';

{
type
  TServerBrowseDialogA0 = function(hwnd: HWND; pchBuffer: Pointer;
    cchBufSize: DWORD): bool;
  stdcall;
  ATStrings = array of string;
}

//***** VERIFICAR INATIVIDADE DE GERCOLS.EXE E ERROS GERADOS PELO CHKSIS NO EVENTVWR....

{$APPTYPE CONSOLE}
var strAcaoGerCols,
    strAux,
    strChkSisInfFileName,
    strFieldsAndValuesToRequest,
    strGerColsInfFileName,
    strMainProgramInfFileName,
    strResultSearch               : string;
    intAuxGerCols                 : integer;
    objCacic                      : TCACIC;

const APP_NAME            = 'gercols.exe';

function programaRodando(NomePrograma: String): Boolean;
var
  IsRunning, ContinueTest: Boolean;
  FSnapshotHandle: THandle;
  FProcessEntry32: TProcessEntry32;
begin
  IsRunning := False;
  FSnapshotHandle := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  FProcessEntry32.dwSize := Sizeof(FProcessEntry32);
  ContinueTest := Process32First(FSnapshotHandle, FProcessEntry32);
  while ContinueTest do
  begin
    IsRunning :=  UpperCase(ExtractFileName(FProcessEntry32.szExeFile)) = UpperCase(NomePrograma);
    if IsRunning then  ContinueTest := False
    else ContinueTest := Process32Next(FSnapshotHandle, FProcessEntry32);
  end;
  CloseHandle(FSnapshotHandle);
  Result := IsRunning;
end;

// Gerador de Palavras-Chave
function geraPalavraChave: String;
var intLimite,
    intContaLetras : integer;
    strPalavra,
    strCaracter    : String;
begin
  objCacic.writeDebugLog('geraPalavraChave: Regerando palavra-chave...');
  Randomize;
  strPalavra  := '';
  intLimite  := RandomRange(10,30); // Gerarei uma palavra com tamanho m�nimo 10 e m�ximo 30
  for intContaLetras := 1 to intLimite do
    Begin
      strCaracter := '.';
      while not (strCaracter[1] in ['0'..'9','A'..'Z','a'..'z']) do
        Begin
          if (strCaracter = '.') then strCaracter := '';
          Randomize;
          strCaracter := chr(RandomRange(1,250));
        End;

      strPalavra := strPalavra + strCaracter;
    End;
  Result := strPalavra;
  objCacic.writeDebugLog('geraPalavraChave: Nova Palavra-Chave gerada "'+Result+'"');
end;

function stringtoHex(Data: string): string;
var
  i, i2: Integer;
  s: string;
begin
  i2 := 1;
  for i := 1 to Length(Data) do
  begin
    Inc(i2);
    if i2 = 2 then
    begin
      s  := s + ' ';
      i2 := 1;
    end;
    s := s + IntToHex(Ord(Data[i]), 2);
  end;
  Result := s;
end;

procedure apagaTemps;
begin
  objCacic.deleteFileOrFolder(objCacic.getLocalFolderName + 'Temp\*.txt');
end;

procedure Sair;
Begin
  objCacic.Free;
  Halt(0);
End;

procedure finalizar(p_pausa:boolean);
Begin
  if not objCacic.isInDebugMode then
    apagaTemps;
  if p_pausa then sleep(2000); // Pausa de 2 segundos para conclus�o de opera��es de arquivos.
End;

function lastPos(SubStr, S: string): Integer;
var
  Found, Len, Pos: integer;
begin
  Pos := Length(S);
  Len := Length(SubStr);
  Found := 0;
  while (Pos > 0) and (Found = 0) do
  begin
    if Copy(S, Pos, Len) = SubStr then
      Found := Pos;
    Dec(Pos);
  end;
  LastPos := Found;
end;

procedure checkModules;
Begin
  objCacic.writeDebugLog('checkModules: Verificando chksis.exe');
  verifyAndGetModules('chksis.exe',
                      objCacic.deCrypt(objCacic.getValueFromFile('Hash-Codes','CHKSIS.EXE',strChkSisInfFileName),false,true),
                      objCacic.getWinDir,
                      objCacic.getLocalFolderName,
                      objCacic,
                      strChkSisInfFileName);

  objCacic.writeDebugLog('checkModules: Verificando cacicservice.exe');
  verifyAndGetModules('cacicservice.exe',
                      objCacic.deCrypt(objCacic.getValueFromFile('Hash-Codes','CACICSERVICE.EXE',strChkSisInfFileName),false,true),
                      objCacic.getWinDir,
                      objCacic.getLocalFolderName,
                      objCacic,
                      strChkSisInfFileName);

  objCacic.writeDebugLog('checkModules: Verificando ' + objCacic.getMainProgramName);
  verifyAndGetModules(objCacic.getMainProgramName,
                      objCacic.getMainProgramHash,
                      objCacic.getLocalFolderName,
                      objCacic.getLocalFolderName,
                      objCacic,
                      strChkSisInfFileName);

  objCacic.writeDebugLog('checkModules: Verificando gercols.exe');
  verifyAndGetModules('gercols.exe',
                      objCacic.deCrypt( objCacic.getValueFromFile('Hash-Codes','GERCOLS.EXE',strChkSisInfFileName),false,true),
                      objCacic.getLocalFolderName + 'Modules',
                      objCacic.getLocalFolderName,
                      objCacic,
                      strChkSisInfFileName);

  objCacic.writeDebugLog('checkModules: Verificando mapacacic.exe');
  verifyAndGetModules('mapacacic.exe',
                      objCacic.deCrypt( objCacic.getValueFromFile('Hash-Codes','MAPACACIC.EXE',strChkSisInfFileName),false,true),
                      objCacic.getLocalFolderName + 'Modules',
                      objCacic.getLocalFolderName,
                      objCacic,
                      strChkSisInfFileName);

  // O m�dulo de Suporte Remoto � opcional...
  if (objCacic.getValueFromTags('srcacic',objCacic.getValueFromFile('Configs','CollectsDefinitions',strGerColsInfFileName)) = 'OK') then
    Begin
      objCacic.writeDailyLog('Verificando nova vers�o para m�dulo Suporte Remoto Seguro.');
      objCacic.writeDebugLog('checkModules: Verificando srcacicsrv.exe');
      // Caso encontre nova vers�o de srCACICsrv esta ser� gravada em Modules.
      verifyAndGetModules('srcacicsrv.exe',
                          objCacic.deCrypt( objCacic.getValueFromFile('Hash-Codes','SRCACICSRV.EXE',strChkSisInfFileName),false,true),
                          objCacic.getLocalFolderName + 'Modules',
                          objCacic.getLocalFolderName,
                          objCacic,
                          strChkSisInfFileName);
    End;
  objCacic.writeDebugLog('checkModules: Final');
  objCacic.writeDebugLog('checkModules: ' + DupeString(':',100));
End;

procedure getConfigs(p_mensagem_log : boolean);
var strRetorno,
    v_mensagem_log,
    strKeyWord,
    strForcaColeta                  : string;
    textfileKeyWord             : TextFile;
Begin
  Try
    // Verifico comunica��o com o M�dulo Gerente WEB.
    // Tratamentos de valores para tr�fego POST:
    objCacic.setValueToFile('Configs','ConexaoOK','N', strGerColsInfFileName);

    strAcaoGerCols := 'Preparando teste de comunica��o com M�dulo Gerente WEB ('+objCacic.getWebManagerAddress+').';

    objCacic.writeDebugLog('getConfigs: Teste de Comunica��o.');

    Try
        Try
          strRetorno := Comm(objCacic.getWebManagerAddress + objCacic.getWebServicesFolderName + 'get/test', strFieldsAndValuesToRequest, objCacic.getLocalFolderName, 'Testando comunica��o com o M�dulo Gerente WEB ('+objCacic.getWebManagerAddress+').');

          if (strRetorno <> '0') Then
            Begin
              objCacic.setBoolCipher(not objCacic.isInDebugMode);
              objCacic.setValueToFile('Configs','ConexaoOK','S', strGerColsInfFileName);

              if (objCacic.getValueFromTags('WebManagerAddress', strRetorno,'<>') <> '') then
                Begin
                  strForcaColeta := objCacic.getValueFromTags('ForcaColeta', strRetorno, '<>');
//                  if strForcaColeta <> 'S' then
//                     objCacic.setValueToFile('Configs','col_patr_exe',
//                                          'n',
//                                          strGerColsInfFileName);
                  objCacic.setValueToFile('Configs','forca_coleta',
                                          strForcaColeta,
                                          strGerColsInfFileName);
                  objCacic.setValueToFile('Configs','WebManagerAddress'    ,objCacic.getValueFromTags('WebManagerAddress'    , strRetorno,'<>'), strChkSisInfFileName);
                  objCacic.setValueToFile('Configs','WebServicesFolderName',objCacic.getValueFromTags('WebServicesFolderName', strRetorno,'<>'), strChkSisInfFileName);
                  objCacic.setWebManagerAddress(objCacic.getValueFromTags('WebManagerAddress', strRetorno,'<>'));
                  objCacic.setWebServicesFolderName(objCacic.getValueFromTags('WebServicesFolderName', strRetorno,'<>'));
                End;

              strAcaoGerCols := 'IP validado pelo M�dulo Gerente WEB ('+objCacic.getWebManagerAddress+').';
              objCacic.writeDebugLog('getConfigs: ' + strAcaoGerCols);
            End;
        except
          on E : Exception do
            Begin
              objCacic.writeDebugLog('getConfigs: Lan�ando Exce��o #2');
              objCacic.writeExceptionLog(E.Message,E.ClassName,'Exce��o #2 - Insucesso na comunica��o com o M�dulo Gerente WEB ('+objCacic.getWebManagerAddress+').');
              objCacic.writeDailyLog('Insucesso na comunica��o com o M�dulo Gerente WEB ('+objCacic.getWebManagerAddress+').');
            End;
        End;
    Except
    End;

    strAcaoGerCols := 'Setando TeFilaFTP=0';
    // Setando controle de FTP para 0 (0=tempo de espera para FTP   de algum componente do sistema)
    objCacic.setValueToFile('Configs','TeFilaFTP','0', strGerColsInfFileName);

    // Verifico e contabilizo as necessidades de FTP dos agentes (instala��o ou atualiza��o)
    // Para poss�vel requisi��o de acesso ao grupo FTP... (Essa medida visa balancear o acesso aos servidores de atualiza��o de vers�es, principalmente quando � um �nico S.A.V.)
    strAcaoGerCols := 'Verificando vers�es de agentes...';

    checkModules;

    // Caso tenha sido baixada uma vers�o deste agente, executo a finaliza��o
    if (FileExists(objCacic.getLocalFolderName + 'Temp\gercols.exe')) then
      Begin
        objCacic.writeDebugLog('getConfigs: Finalizando para atualiza��o de vers�o');
        Finalizar(true);
        Sair;
      End;

    v_mensagem_log  := 'Obtendo configura��es a partir do Gerente WEB ('+objCacic.getWebManagerAddress+').';

    if (not p_mensagem_log) then v_mensagem_log := '';

    objCacic.writeDebugLog('getConfigs: objCacic.getWebManagerAddress: "' + objCacic.getWebManagerAddress + '"');
    if (Trim(objCacic.getWebManagerAddress) <> '') then
        begin
             objCacic.writeDebugLog('getConfigs: Obtendo nova palavra chave');
             // Gero e armazeno uma palavra-chave e a envio ao Gerente WEB para atualiza��o no BD.
             // Essa palavra-chave ser� usada para o acesso ao Agente Principal
             strAux := GeraPalavraChave;
             objCacic.writeDebugLog('getConfigs: Guardando nova palavra chave: "' + strAux + '"');
             strAux := objCacic.enCrypt(strAux);
             objCacic.setValueToFile('Configs','TePalavraChave', strAux, strGerColsInfFileName);

             // Renova a palavra chave para o Servidor de Suporte Remoto Seguro
             strKeyWord := objCacic.deCrypt(strAux);
             strKeyWord := objCacic.replaceInvalidHTTPChars(objCacic.enCrypt(strKeyWord));
             strKeyWord := objCacic.replaceInvalidHTTPChars(strKeyWord);

             objCacic.writeDebugLog('getConfigs: Criando cookie para srCACICsrv com nova palavra-chave "'+ strAux + '" => "'+strKeyWord+'"');

             AssignFile(textfileKeyWord,objCacic.getLocalFolderName + 'cacic_keyword.txt');
             Rewrite(textfileKeyWord);
             Append(textfileKeyWord);
             Writeln(textfileKeyWord,strKeyWord);
             CloseFile(textfileKeyWord);
             //
             strFieldsAndValuesToRequest := 'te_palavra_chave=' + objCacic.replaceInvalidHTTPChars(objCacic.enCrypt(strAux));
             strRetorno := Comm(objCacic.getWebManagerAddress + objCacic.getWebServicesFolderName + 'get/config', strFieldsAndValuesToRequest, objCacic.getLocalFolderName,v_mensagem_log);
             objCacic.setBoolCipher(not objCacic.isInDebugMode);

             if (strRetorno <> '0') and
                (objCacic.getValueFromTags('WebManagerAddress',strRetorno,'<>') <> objCacic.getValueFromFile('Configs','WebManagerAddress', strChkSisInfFileName)) then
                Begin
                  v_mensagem_log := 'Endere�o de Gerente WEB: ' + (objCacic.getValueFromTags('WebManagerAddress',strRetorno,'<>'));
                  objCacic.setWebManagerAddress((objCacic.getValueFromTags('WebManagerAddress',strRetorno,'<>')));
                  objCacic.setValueToFile('Configs','WebManagerAddress',objCacic.getValueFromTags('WebManagerAddress',strRetorno,'<>'), strChkSisInfFileName);
                  objCacic.writeDebugLog('getConfigs: Refazendo comunica��o');
                  strRetorno := Comm(objCacic.getWebManagerAddress + objCacic.getWebServicesFolderName + 'get/config', strFieldsAndValuesToRequest, objCacic.getLocalFolderName,v_mensagem_log);
                End;

             if (strRetorno <> '0') Then
              Begin
                strAcaoGercols := 'Armazenando em "' + strGerColsInfFileName + '" os valores obtidos.';
                objCacic.writeDebugLog('getConfigs: ' + strAcaoGerCols);

                //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                //Grava��o no DatFileName dos valores de REDE, COMPUTADOR e EXECU��O obtidos, para consulta pelos outros m�dulos...
                //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                objCacic.setValueToFile('Configs'   ,'modulo_patr'                    ,objCacic.getValueFromTags('modPatrimonio'                    , strRetorno, '<>'), strGerColsInfFileName);
                objCacic.setValueToFile('Configs'   ,'CollectsDefinitions'            ,objCacic.getValueFromTags('CollectsDefinitions'              , strRetorno, '<>'), strGerColsInfFileName);
                objCacic.setValueToFile('Configs'   ,'TeServUpdates'                  ,objCacic.getValueFromTags('te_serv_updates'                  , strRetorno, '<>'), strChkSisInfFileName);
                objCacic.setValueToFile('Configs'   ,'NuPortaServUpdates'             ,objCacic.getValueFromTags('nu_porta_serv_updates'            , strRetorno, '<>'), strChkSisInfFileName);
                objCacic.setValueToFile('Configs'   ,'TePathServUpdates'              ,objCacic.getValueFromTags('te_path_serv_updates'             , strRetorno, '<>'), strChkSisInfFileName);
                objCacic.setValueToFile('Configs'   ,'NmUsuarioLoginServUpdates'      ,objCacic.getValueFromTags('nm_usuario_login_serv_updates'    , strRetorno, '<>'), strChkSisInfFileName);
                objCacic.setValueToFile('Configs'   ,'TeSenhaLoginServUpdates'        ,objCacic.getValueFromTags('te_senha_login_serv_updates'      , strRetorno, '<>'), strChkSisInfFileName);
                objCacic.setValueToFile('Hash-Codes',objCacic.getMainProgramName      ,objCacic.getValueFromTags(objCacic.getMainProgramName+'_HASH', strRetorno, '<>'), strChkSisInfFileName);
                objCacic.setValueToFile('Hash-Codes','CHKSIS.EXE'                     ,objCacic.getValueFromTags('CHKSIS.EXE_HASH'                  , strRetorno, '<>'), strChkSisInfFileName);
                objCacic.setValueToFile('Hash-Codes','GERCOLS.EXE'                    ,objCacic.getValueFromTags('GERCOLS.EXE_HASH'                 , strRetorno, '<>'), strChkSisInfFileName);
                objCacic.setValueToFile('Hash-Codes','SRCACICSRV.EXE'                 ,objCacic.getValueFromTags('SRCACICSRV.EXE_HASH'              , strRetorno, '<>'), strChkSisInfFileName);
                objCacic.setValueToFile('Hash-Codes','CACICSERVICE.EXE'               ,objCacic.getValueFromTags('CACICSERVICE.EXE_HASH'            , strRetorno, '<>'), strChkSisInfFileName);
                objCacic.setValueToFile('Hash-Codes','MAPACACIC.EXE'                  ,objCacic.getValueFromTags('MAPACACIC.EXE_HASH'               , strRetorno, '<>'), strChkSisInfFileName);
                objCacic.setValueToFile('Configs'   ,'InExibeErrosCriticos'           ,objCacic.getValueFromTags('in_exibe_erros_criticos'          , strRetorno, '<>'), strMainProgramInfFileName);
                objCacic.setValueToFile('Configs'   ,'TeSenhaAdmAgente'               ,objCacic.getValueFromTags('te_senha_adm_agente'              , strRetorno, '<>'), strMainProgramInfFileName);
                objCacic.setValueToFile('Configs'   ,'NuIntervaloExec'                ,objCacic.getValueFromTags('nu_intervalo_exec'                , strRetorno, '<>'), strMainProgramInfFileName);
                objCacic.setValueToFile('Configs'   ,'NuExecApos'                     ,objCacic.getValueFromTags('nu_exec_apos'                     , strRetorno, '<>'), strMainProgramInfFileName);
                objCacic.setValueToFile('Configs'   ,'InExibeBandeja'                 ,objCacic.getValueFromTags('in_exibe_bandeja'                 , strRetorno, '<>'), strMainProgramInfFileName);
                objCacic.setValueToFile('Configs'   ,'TeJanelasExecucao'              ,objCacic.getValueFromTags('te_janelas_excecao'               , strRetorno, '<>'), strMainProgramInfFileName);
                objCacic.setValueToFile('Configs'   ,'NuPortaSrCacic'                 ,objCacic.getValueFromTags('nu_porta_srcacic'                 , strRetorno, '<>'), strMainProgramInfFileName);
                objCacic.setValueToFile('Configs'   ,'IdLocal'                        ,objCacic.getValueFromTags('id_local'                         , strRetorno, '<>'), strMainProgramInfFileName);
                objCacic.setValueToFile('Configs'   ,'NuTimeOutSrCacic'               ,objCacic.getValueFromTags('nu_timeout_srcacic'               , strRetorno, '<>'), strMainProgramInfFileName);
                objCacic.setValueToFile('Configs'   ,'CsPermitirDesativarSrCacic'     ,objCacic.getValueFromTags('cs_permitir_desativar_srcacic'    , strRetorno, '<>'), strMainProgramInfFileName);
                objCacic.setValueToFile('Configs'   ,'TeEnderecosMacInvalidos'        ,objCacic.getValueFromTags('te_enderecos_mac_invalidos'       , strRetorno, '<>'), strMainProgramInfFileName);
              end;
        end;
  Except
   on E : Exception do
     Begin
       objCacic.writeDebugLog('getConfigs: Lan�ando Exce��o #5');
       objCacic.writeExceptionLog(E.Message,E.ClassName,'getConfigs: Exce��o #5');
     End;
  End;
end;

procedure getTest();
var strRetorno: string;
Begin
  Try
    // Verifico comunica��o com o M�dulo Gerente WEB.
    // Tratamentos de valores para tr�fego POST:
    objCacic.setValueToFile('Configs','ConexaoOK','N', strGerColsInfFileName);

    strAcaoGerCols := 'Preparando teste de comunica��o com M�dulo Gerente WEB ('+objCacic.getWebManagerAddress+').';

    objCacic.writeDebugLog('getTest: Teste de Comunica��o.');

    Try
        strRetorno := Comm(objCacic.getWebManagerAddress + objCacic.getWebServicesFolderName + 'get/test', strFieldsAndValuesToRequest, objCacic.getLocalFolderName, 'Testando comunica��o com o M�dulo Gerente WEB ('+objCacic.getWebManagerAddress+').');

        if (strRetorno <> '0') Then
        Begin
          objCacic.setBoolCipher(not objCacic.isInDebugMode);
          objCacic.setValueToFile('Configs','ConexaoOK','S', strGerColsInfFileName);
          if (objCacic.getValueFromTags('WebManagerAddress', strRetorno,'<>') <> '') then
          Begin
			      objCacic.setValueToFile('Configs','forca_coleta',
                                    objCacic.getValueFromTags('ForcaColeta', strRetorno, '<>'),
                                    strGerColsInfFileName);
            objCacic.setValueToFile('Configs','WebManagerAddress'    ,objCacic.getValueFromTags('WebManagerAddress'    , strRetorno,'<>'), strChkSisInfFileName);
            objCacic.setValueToFile('Configs','WebServicesFolderName',objCacic.getValueFromTags('WebServicesFolderName', strRetorno,'<>'), strChkSisInfFileName);
            objCacic.setWebManagerAddress(objCacic.getValueFromTags('WebManagerAddress', strRetorno,'<>'));
            objCacic.setWebServicesFolderName(objCacic.getValueFromTags('WebServicesFolderName', strRetorno,'<>'));
          End;

          strAcaoGerCols := 'IP validado pelo M�dulo Gerente WEB ('+objCacic.getWebManagerAddress+').';
          objCacic.writeDebugLog('getTest: ' + strAcaoGerCols);
        End;
    except
        on E : Exception do
        Begin
          objCacic.writeDebugLog('getTest: Lan�ando Exce��o #2');
          objCacic.writeExceptionLog(E.Message,E.ClassName,'Exce��o #2 - Insucesso na comunica��o com o M�dulo Gerente WEB ('+objCacic.getWebManagerAddress+').');
          objCacic.writeDailyLog('Insucesso na comunica��o com o M�dulo Gerente WEB ('+objCacic.getWebManagerAddress+').');
        End;
    End;
  Except
   on E : Exception do
     Begin
       objCacic.writeDebugLog('getTest: Lan�ando Exce��o #5');
       objCacic.writeExceptionLog(E.Message,E.ClassName,'getTest: Exce��o #5');
     End;
  End;
end;

procedure criaCookie(strFileName : String);
var textFileAguarde : TextFile;
Begin
  Try
      // A exist�ncia e bloqueio do arquivo abaixo evitar� que o Agente Principal chame o GerCols quando este estiver em funcionamento
      AssignFile(textFileAguarde,objCacic.getLocalFolderName + 'Temp\' + strFileName); {Associa o arquivo a uma vari�vel do tipo TextFile}

      {$IOChecks off}
      Reset(textFileAguarde); {Abre o arquivo texto}
      {$IOChecks on}

      if (IOResult <> 0) then // Arquivo n�o existe, ser� recriado.
       Rewrite (textFileAguarde);

      Append(textFileAguarde);
      Writeln(textFileAguarde,'Apenas uma marca para o Agente Principal esperar o t�rmino de GerCols');

      Append(textFileAguarde);
      Writeln(textFileAguarde,'Obs.: Solu��o tempor�ria, at� a implementa��o de troca de mensagens (TMessages)');

      Append(textFileAguarde);
  Except
   on E : Exception do
     Begin
       objCacic.writeDebugLog('criaCookie: Lan�ando Exce��o #1');
       objCacic.writeExceptionLog(E.Message,E.ClassName,'criaCookie: Exce��o #1');
     End;
  End;
End;

// Dica baixada de http://www.marcosdellantonio.net/2007/06/14/operador-if-ternario-em-delphi-e-c/
// Fiz isso para n�o ter que acrescentar o componente Math ao USES!
function iif(condicao : boolean; resTrue, resFalse : Variant) : Variant;
  Begin
    if condicao then
      Result := resTrue
    else
      Result := resFalse;
  End;
// Baixada de http://www.infoeng.hpg.ig.com.br/borland_delphi_dicas_2.htm
function LetrasDrives: string;
var
Drives: DWord;
I, Tipo: byte;
v_Unidade : string;
begin
Result := '';
Drives := GetLogicalDrives;
if Drives <> 0 then
for I := 65 to 90 do
  if ((Drives shl (31 - (I - 65))) shr 31) = 1 then
    Begin
      v_Unidade := Char(I) + ':\';
      Tipo := GetDriveType(PChar(v_Unidade));
      case Tipo of
        DRIVE_FIXED: Result := Result + Char(I);
      end;
    End;
end;

procedure GetSubDirs(Folder:string; sList:TStringList);
 var
  sr:TSearchRec;
begin
  if FindFirst(Folder+'*.*',faDirectory,sr)=0 then
   try
    repeat
      if(sr.Attr and faDirectory)=faDirectory then
       sList.Add(sr.Name);
    until FindNext(sr)<>0;
   finally
    FindClose(sr);
   end;
end;

// By Muad Dib 2003
// at http://www.planet-source-code.com.
// Excelente!!!
function SearchFile(p_Drive,p_File:string) : boolean;
var sr:TSearchRec;
    sDirList:TStringList;
    i:integer;
begin
   Result := false;
   strResultSearch := '';
   if FindFirst(p_Drive+p_File,faAnyFile,sr) = 0 then
    Begin
      strResultSearch := p_Drive+p_File;
      Result := true;
    End
   else
    Begin
     repeat
     until FindNext(sr)<>0;
        FindClose(sr);
        sDirList:= TStringList.Create;
        try
         GetSubDirs(p_Drive,sDirList);
         for i:=0 to sDirList.Count-1 do
            if (sDirList[i]<>'.') and (sDirList[i]<>'..') then
             begin
              //Application.ProcessMessages;
              if (SearchFile(IncludeTrailingPathDelimiter(p_Drive+sDirList[i]),p_File)) then
                Begin
                  Result := true;
                  Break;
                End;
             end;
         finally
         sDirList.Free;
    End;
   end;
end;
// Importado de Jedi Project
function RegNativeReadStringDef(const RootKey: DelphiHKEY; const Key, Name: string; Def: string): string;
var
  LastAccess: TJclRegWOW64Access;
begin
  LastAccess := RegGetWOW64AccessMode;
  try
    RegSetWOW64AccessMode(raNative);
    Result := RegReadStringDef(RootKey, Key, Name, Def);
  finally
    RegSetWOW64AccessMode(LastAccess);
  end;
end;

function GetAcrobatReaderVersion: String;
var Reg_GVAR : TRegistry;
    Lista_GVAR: TStringList;
    strChave : String;
Begin
      Reg_GVAR := TRegistry.Create;
      Reg_GVAR.LazyWrite := False;
      Lista_GVAR := TStringList.Create;
      Reg_GVAR.Rootkey := HKEY_LOCAL_MACHINE;
      strChave := '\Software\Adobe\Acrobat Reader';
      Reg_GVAR.OpenKeyReadOnly(strChave);
      Reg_GVAR.GetKeyNames(Lista_GVAR);
      Reg_GVAR.CloseKey;
      If Lista_GVAR.Count > 0 Then
      Begin
        Lista_GVAR.Sort;
        Result := Lista_GVAR.Strings[Lista_GVAR.Count - 1];
      end;
      Lista_GVAR.Free;
      Reg_GVAR.Free;
end;

function GetJREVersion: String;
var strVersao: string;
begin
    strVersao := '';
    strVersao := Trim(objCacic.getValueRegistryKey('HKEY_LOCAL_MACHINE\Software\JavaSoft\Java Runtime Environment\CurrentVersion'));
    Result := strVersao;
end;

function GetMozillaVersion: String;
var strVersao: string;
begin
    strVersao := '';
    strVersao := Trim(objCacic.getValueRegistryKey('HKEY_LOCAL_MACHINE\Software\mozilla.org\Mozilla\CurrentVersion'));
    Result := strVersao;
end;
function GetADOVersion: string;
begin
  Result := RegNativeReadStringDef(HKLM, '\SOFTWARE\Microsoft\DataAccess', 'Version', '');
end;
function GetBDELocation: string;
begin
  Result := ExcludeTrailingPathDelimiter(RegReadStringDef(HKLM,
    '\SOFTWARE\Borland\Database Engine', 'DLLPATH', ''));
end;

function GetBDEVersion: string;
begin
  Result := IncludeTrailingPathDelimiter(GetBDELocation) + 'idapi32.dll';
  if not VersionResourceAvailable(Result) then
    Result := IncludeTrailingPathDelimiter(GetBDELocation) + 'bdeadmin.exe';

  if VersionResourceAvailable(Result) then
  begin
    with TJclFileVersionInfo.Create(Result) do
    try
      Result := FileVersion;
    finally
      Free;
    end;
  end
  else
    Result := '';
end;

function GetDirectXVersion: string;
begin
  Result := RegNativeReadStringDef(HKLM, '\SOFTWARE\Microsoft\DirectX', 'Version', '');
end;

function GetIEVersion: string;
begin
  Result := RegNativeReadStringDef(HKLM, '\SOFTWARE\Microsoft\Internet Explorer', 'Version', '');
end;

function GetODBCVersion: string;
begin
  Result := objCacic.GetVersionInfo(objCacic.getWinDir + 'System32\odbc32.dll');
end;

function GetOpenGLVersion: string;
var
  AVendor: AnsiString;
  ASResult: AnsiString;
begin
  if not JclSysInfo.GetOpenGLVersion(GetActiveWindow, ASResult, AVendor) then
    Result := ''
  else
    Result := string(ASResult);
end;

function GetDAOVersion: String;
var sPath: string;
    iError, iResult: integer;
    rDirInfo: TSearchRec;
begin
  iResult := 0;
  sPath := objCacic.getHomeDrive +'\Program Files\Common Files\' +'Microsoft Shared\DAO\dao*.dll';

  // Loop thru to find the MAX DLL version on disk
  iError := FindFirst(sPath, faAnyFile, rDirInfo);

  while iError = 0 do
    begin
      iResult := Max(iResult, StrToIntDef(copy(rDirInfo.Name, 4, 3), 0));
      iError := FindNext(rDirInfo);
      if iError <> 0 then
      FindClose(rDirInfo);
    end;
  Result := FormatFloat('##0.00', (iResult / 100.0));
end;

// Funcao que le os valores de software instalados no Registro do Windows
Function DisplayKeys(const Key: string; const Depth: Integer): String;
var
  i: Integer;
  SubKeys: TStringList;
  Registry: TRegistry;
  SubRegistry: TRegistry;
  saida: String;
begin
  Registry := TRegistry.Create(KEY_WOW64_64KEY);
  SubRegistry := TRegistry.Create(KEY_WOW64_64KEY);
  Registry.RootKey := HKEY_LOCAL_MACHINE;
  if Registry.OpenKeyReadOnly(Key) then begin
    Try
      SubKeys := TStringList.Create;
      Try
        Registry.GetKeyNames(SubKeys);
        // Abre a tag com o nome da chave
        //saida := '[SoftwareList]';
        saida := '';

        // Adiciona o pai
        SubRegistry.RootKey := HKEY_LOCAL_MACHINE;

        for i := 0 to SubKeys.Count-1 do begin
          //Writeln(StringOfChar(' ', Depth*2) + SubKeys[i]);
          //DisplayKeys(Key + '\' + SubKeys[i], Depth+1);
          // Essa linha coloca o valor da tag do registro
          saida := saida + '[Software][IDSoftware]' + SubKeys[i] + '[/IDSoftware]';

          // Abre a tag do registro
          //Names := TStringList.Create;
          SubRegistry.OpenKeyReadOnly(Key + '\' + SubKeys[i]);

          // Agora coloca o valor do registro dentro da tag
          saida := saida + '[DisplayName]' + SubRegistry.ReadString('DisplayName') + '[/DisplayName]';
          saida := saida + '[DisplayVersion]' + SubRegistry.ReadString('DisplayVersion') + '[/DisplayVersion]';
          saida := saida + '[URLInfoAbout]' + SubRegistry.ReadString('URLInfoAbout') + '[/URLInfoAbout]';
          saida := saida + '[Publisher]' + SubRegistry.ReadString('Publisher') + '[/Publisher]';

          // Fecho o registro e a tag
          SubRegistry.CloseKey;
          //SubRegistry.Free;

          // Fecha a tag do registro
          saida := saida + '[/Software]';

          // Chamada recursiva para tags que possuem valores internos
          DisplayKeys(Key + '\' + SubKeys[i], Depth+1);
        end;

        // Fecha a tag do software
        //saida := saida + '[/SoftwareList]';
      Finally
        SubKeys.Free;
      End;
    Finally
      Registry.CloseKey;
      Registry.Free;
    End;
    Result := saida;
  end;
end;

// Procedimento que chama a lista de softwares do Sistema Operacional
Function SoftwareList: String;
var
  strChave: String;
  strChave6432: String;
  outString: String;
  outString6432: String;
begin
    // Esse registro � onde vamos buscar a chave do SO
    strChave     := '\Software\Microsoft\Windows\CurrentVersion\Uninstall';
    strChave6432 := '\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall';
    // Passo aqui o registro e a profundidade dos campos que quero ver
    outString6432 := DisplayKeys(strChave6432, 3);
    outString := DisplayKeys(strChave, 3);
//    objCacic.setValueToFile('collects', 'colsoft_puro', outString, 'c:\Cacic\colsoft.inf');
    // Retorno uma string com todas as tags coletadas do registro
    if ((outString <> outString6432) and (outString6432 <> '')) then
      Result := outString + outString6432
    else
      result := outString;
end;

// Procedimento que executa a coleta de hardware
Function ColetaHardware: String;
var
  outString: String;
begin
  // Coletas de todos os atributos de hardware
  outString := fetchWmiValues('Win32_Keyboard', 'Availability,Caption,Description,InstallDate,Manufacturer,Name', objCacic.getLocalFolderName);
  outString := outString + fetchWmiValues('Win32_PointingDevice', 'Availability,Caption,Description,InstallDate,Manufacturer,Name', objCacic.getLocalFolderName);
  outString := outString + fetchWmiValues('Win32_PhysicalMedia ', 'Caption,Description,InstallDate,Name,Manufacturer,Model,SKU,SerialNumber,Tag,Version,PartNumber,OtherIdentifyingInfo,Capacity,MediaType,MediaDescription', objCacic.getLocalFolderName);
  outString := outString + fetchWmiValues('Win32_BaseBoard', 'Caption,ConfigOptions,Depth,Description,Height,HostingBoard,InstallDate,Manufacturer,Model,Name,OtherIdentifyingInfo,PartNumber,Product,RequirementsDescription,SerialNumber,SKU,SlotLayout,SpecialRequirements,Tag,Version,Weight,Width', objCacic.getLocalFolderName);
  // Tenho que dividir a string em dois peda�os porque o Delphi n�o aceita strings individuais com mais de 255 caracteres
  outString := outString + fetchWmiValues('Win32_BIOS', 'BiosCharacteristics,BIOSVersion,BuildNumber,Caption,CodeSet,Description,IdentificationCode,InstallDate,Manufacturer,Name,OtherTargetOS,PrimaryBIOS,ReleaseDate,SerialNumber,SMBIOSBIOSVersion,SMBIOSMajorVersion,SMBIOSMinorVersion,' + 'BIOSPresent,SoftwareElementID,TargetOperatingSystem,Version', objCacic.getLocalFolderName);
  outString := outString + fetchWmiValues('Win32_MemoryDevice', 'Access,Availability,BlockSize,Caption,Description,DeviceID,EndingAddress,InstallDate,Name,NumberOfBlocks,PNPDeviceID,Purpose,SystemLevelAddress,SystemName', objCacic.getLocalFolderName);
  outString := outString + fetchWmiValues('Win32_PhysicalMemory', 'BankLabel,Capacity,Caption,DataWidth,Description,DeviceLocator,FormFactor,InstallDate,InterleaveDataDepth,InterleavePosition,Manufacturer,MemoryType,Model,Name,OtherIdentifyingInfo,PartNumber,PositionInRow,' + 'SerialNumber,SKU,Speed,Tag,TotalWidth,TypeDetail,Version', objCacic.getLocalFolderName);
  outString := outString + fetchWmiValues('Win32_Processor', 'AddressWidth,Architecture,Availability,Caption,CreationClassName,DataWidth,Description,DeviceID,ExtClock,Family,InstallDate,L2CacheSize,L2CacheSpeed,L3CacheSize,L3CacheSpeed,Level,LoadPercentage,Manufacturer,'+ 'MaxClockSpeed,Name,NumberOfCores,NumberOfLogicalProcessors,OtherFamilyDescription,PNPDeviceID,ProcessorId,ProcessorType,Revision,Role,SocketDesignation,SystemName,UniqueId,UpgradeMethod,Version,VoltageCaps', objCacic.getLocalFolderName);
  outString := outString + fetchWmiValues('Win32_Printer', 'Attributes,Availability,Caption,CharSetsSupported,Comment,CurrentCharSet,Default,Description,DeviceID,Direct,DriverName,HorizontalResolution,InstallDate,JobCountSinceLastReset,KeepPrintedJobs,LanguagesSupported,' + 'Local,Location,MarkingTechnology,MaxCopies,MaxNumberUp,MaxSizeSupported,MimeTypesSupported,Name,Network,PaperSizesSupported,PaperTypesAvailable,Parameters,PNPDeviceID,PortName,PrintProcessor,' + 'ServerName,Shared,ShareName,SpoolEnabled,SystemName,VerticalResolution,WorkOffline', objCacic.getLocalFolderName);

  // Retorna uma string com todas as coletas
  Result := outString;

end;


procedure executeGerCols;
var boolFound : boolean;
var strActionDefinition,
    strAux,
    strAux1,
    strAux3,
    strAux4,
    strChaveRegistro,
    strClassesAndProperties,
    strColetaAnterior,
    strColetaAtual,
    strCollectsDefinitions,
    strDate,
    strDirTrend,
    strDrive,
    strDtHrInstalacao,
    strFileName,
    strInAtivo,
    strLetrasDrives,
    strNomeExecutavel,
    strNuVersaoEngine,
    strNuVersaoPattern,
    strRetorno,
    strTeServidor,
    strTripa,
    tstrColetaSoftware,
    tstrColetaHardware,
    tstrColetaComputador,
    strValorChavePerfis   : String;

    intAux4,
    intLoopActions,
    intLoopClasses,
    intLoopExecutaGerCols,
    intTotalExecutedCollects,
    intTotalSendedCollects    : integer;

    tstringlistLista1RCO{,
    tstringlistListaRCC}   : TStringList;

    tstringsActions,
    tstringsClasses,
    tstringsLista2RCO,
    tstringsTripa2,
    tstringsTripa3        : TStrings;
    searchRecResult       : TSearchRec;  // Necess�rio apenas para Win9x
Begin
  Try

    // Par�metros poss�veis (aceitos)
    //   /collect        =>  Chamada para ativa��o das coletas
    //   /recuperaSR     =>  Chamada para tentativa de recupera��o do m�dulo srCACIC
    // USBinfo           =>  Informa��o sobre dispositivo USB inserido/removido
    // RCActions         =>  Informa��o sobre a��es durante conex�o de suporte remoto
    // UpdatePrincipal   =>  Atualiza��o do Agente Principal

    // Chamada com informa��o de a��es realizadas na sess�o de suporte remoto
    if (objCacic.getParam('RCActions') <> '') then
      begin
        objCacic.writeDebugLog('executeGerCols: Informa��es de A��es Recebidas: "' + objCacic.getParam('RCActions') + '"');
        strAcaoGercols := 'Informando ao Gerente WEB ('+objCacic.getWebManagerAddress+') sobre a��es durante suporte remoto.';

        strFieldsAndValuesToRequest := 'te_rcactions=' + objCacic.replaceInvalidHTTPChars(objCacic.enCrypt(objCacic.getParam('RCActions')));
        objCacic.writeDebugLog('executeGerCols: Preparando para empacotar "'+strFieldsAndValuesToRequest+'"');
        strRetorno := Comm(objCacic.getWebManagerAddress + objCacic.getWebServicesFolderName + 'gercols/set/srcacic/action', strFieldsAndValuesToRequest, objCacic.getLocalFolderName, 'Enviando informa��es sobre a��es durante suporte remoto ao Gerente WEB ('+objCacic.getWebManagerAddress+')!');

        Finalizar(true);
      end;

    // Primeira chamada efetuada pelo Agente Principal para posterior a��o de coletas
    If FindCmdLineSwitch('getConfigs', True) Then
    Begin
         getConfigs(true);
         Finalizar(false);
    End
    //Chamada realizada para verificar se h� coleta a ser for�ada.
    else if FindCmdLineSwitch ('getTest', True) then
    begin
        getTest();
        Finalizar(false);
    end;

    // Chamada efetuada pelo Agente Principal quando da exist�ncia de temp\<AgentePrincipal>.exe para AutoUpdate
    If FindCmdLineSwitch('UpdatePrincipal', True) Then
      Begin
         CriaCookie(objCacic.getLocalFolderName + 'Temp\aguarde_UPDATE.txt');
         objCacic.writeDebugLog('executeGerCols: Op��o /UpdatePrincipal recebida...');
         // 15 segundos de tempo total at� a execu��o do novo Agente Principal
         sleep(7000);
         strAcaoGercols := 'Atualiza��o do Agente Principal - Excluindo '+objCacic.getLocalFolderName + objCacic.getMainProgramName;
         objCacic.deleteFileOrFolder(objCacic.getLocalFolderName + objCacic.getMainProgramName);
         sleep(2000);

         strAcaoGercols := 'Atualiza��o do Agente Principal - Copiando '+objCacic.getLocalFolderName + 'Temp\'+objCacic.getMainProgramName+' para '+objCacic.getLocalFolderName + objCacic.getMainProgramName;
         objCacic.writeDebugLog('executeGerCols: Movendo '+objCacic.getLocalFolderName + 'Temp\'+objCacic.getMainProgramName+' para '+objCacic.getLocalFolderName + objCacic.getMainProgramName);
         MoveFile(pChar(objCacic.getLocalFolderName + 'Temp\'+ objCacic.getMainProgramName),pChar(objCacic.getLocalFolderName + objCacic.getMainProgramName));
         sleep(2000);

         objCacic.setValueToFile('Configs','NuExecApos','12345', strMainProgramInfFileName); // Para que o Agente Principal comande a coleta logo ap�s 1 minuto...
         sleep(2000);

         objCacic.writeDebugLog('executeGerCols: Invocando atualiza��o do Agente Principal...');

         strAcaoGercols := 'Atualiza��o do Agente Principal - Invocando '+objCacic.getLocalFolderName + objCacic.getMainProgramName + ' /atualizacao';
         Finalizar(false);

         objCacic.createOneProcess(objCacic.getLocalFolderName + objCacic.getMainProgramName + ' /atualizacao', false);

         Sair;
      End;

    // Chamada efetuada pelo Agente Principal quando o usu�rio clica no menu "Ativar Suporte Remoto" e o m�dulo srCACICsrv.exe n�o
    // tem seu HashCode validado
    If FindCmdLineSwitch('recuperaSR', True) Then
      Begin
        objCacic.writeDebugLog('executeGerCols: Op��o /recuperaSR recebida...');
        strAcaoGercols := 'Verificando/Recuperando srCACIC.';
        objCacic.writeDebugLog('executeGerCols: Chamando Verificador/Atualizador...');

        verifyAndGetModules('srcacicsrv.exe',
                            objCacic.deCrypt(objCacic.getValueFromFile('Hash-Codes','SRCACICSRV.EXE',strChkSisInfFileName),false,true),
                            objCacic.getLocalFolderName + 'Modules',
                            objCacic.getLocalFolderName,
                            objCacic,
                            strChkSisInfFileName);
        Finalizar(false);
        objCacic.CriaTXT(objCacic.getLocalFolderName+'Temp','recuperaSR','Tentativa de Recupera��o do m�dulo srCACIC.');
        Sair;
      End;

    // Chamada com informa��o de dispositivo USB inserido/removido
    // Envio da informa��o sobre o dispositivo USB ao Gerente WEB
    if (objCacic.getParam('USBInfo') <> '') then
      begin
        objCacic.writeDebugLog('executeGerCols: Par�metro USBinfo recebido: "' + objCacic.getParam('USBInfo') + '"');
        strAcaoGercols := 'Informando ao Gerente WEB ('+objCacic.getWebManagerAddress+') sobre dispositivo USB inserido/removido.';

        strFieldsAndValuesToRequest := 'te_usb_info=' + objCacic.replaceInvalidHTTPChars(objCacic.enCrypt(objCacic.getParam('USBInfo')));
        objCacic.writeDebugLog('executeGerCols: Preparando para empacotar "'+strFieldsAndValuesToRequest+'"');
        strRetorno := Comm(objCacic.getWebManagerAddress + objCacic.getWebServicesFolderName + 'gercols/set/usbdetect', strFieldsAndValuesToRequest, objCacic.getLocalFolderName, 'Enviando informa��es sobre ' + IfThen(Copy(objCacic.getParam('USBInfo'),1,1)='I','Inser��o','Remo��o')+ ' de dispositivo USB ao Gerente WEB ('+objCacic.getWebManagerAddress+')!');
        objCacic.setBoolCipher(not objCacic.isInDebugMode);
        if (objCacic.getValueFromTags('nm_device', strRetorno, '<>') <> '') then
          objCacic.writeDailyLog('Dispositivo USB ' + IfThen(Copy(objCacic.getParam('USBInfo'),1,1)='I','Inserido','Removido')+': "' + objCacic.getValueFromTags('nm_device', strRetorno, '<>')+'"');

        Finalizar(true);
      end;

    // Chamada temporizada efetuada pelo Agente Principal
    If FindCmdLineSwitch('collect', True) Then
      Begin
        objCacic.writeDebugLog('executeGerCols: Par�metro(op��o) /collect recebido...');
        strAcaoGercols            := 'GerCols invocado para coletas...';
        intTotalExecutedCollects  := 0;
        intTotalSendedCollects    := 0;

        getConfigs(true);

        // Abaixo eu testo se existe um endere�o configurado para n�o disparar os procedimentos de coleta em v�o.
        if (objCacic.getWebManagerAddress <> '') then
            begin
                checkModules;

                if (FileExists(objCacic.getLocalFolderName + 'Temp\gercols.exe')) or
                   (FileExists(objCacic.getLocalFolderName + 'Temp\' + objCacic.getMainProgramName))  then
                    Begin
                      objCacic.setValueToFile('Hash-Codes',objCacic.getMainProgramName,objCacic.enCrypt( objCacic.getFileHash(objCacic.getLocalFolderName + 'Temp\' + objCacic.getMainProgramName),false,true), strChkSisInfFileName);
                      objCacic.writeDailyLog('Finalizando... (Update em � 1 minuto).');
                      Finalizar(false);
                      Sair;
                    End;

                objCacic.writeDailyLog('Verificando configura��o de coletas.');

                strCollectsDefinitions := objCacic.deCrypt(objCacic.getValueFromFile('Configs','CollectsDefinitions', strGerColsInfFileName));

                if  not FileExists(objCacic.getLocalFolderName + 'Temp\gercols.exe')  then
                    begin
                      tstringsActions := objCacic.explode(objCacic.getValueFromTags('Actions',strCollectsDefinitions),',');
                      for intLoopActions := 0 to tstringsActions.Count - 1 do
                        Begin
                           strColetaAtual              := '';
                           strFieldsAndValuesToRequest := 'CollectType=' + objCacic.replaceInvalidHTTPChars(objCacic.enCrypt(tstringsActions[intLoopActions])) ;
                           objCacic.writeDebugLog('executeGerCols: CollectType atual => "' + tstringsActions[intLoopActions] + '"');

                           objCacic.setValueToFile('Collects',tstringsActions[intLoopActions] + '_Begin'      , ''  , strGerColsInfFileName);
                           objCacic.setValueToFile('Collects',tstringsActions[intLoopActions] + '_End'        , ''  , strGerColsInfFileName);
                           objCacic.setValueToFile('Collects',tstringsActions[intLoopActions] + '_Send_Status', '0' , strGerColsInfFileName);

                           strActionDefinition := objCacic.getValueFromTags(tstringsActions[intLoopActions],strCollectsDefinitions);
                           objCacic.writeDebugLog('executeGerCols: strActionDefinition => "' + strActionDefinition + '"');
                           if (strActionDefinition <> '') then
                              begin
                                objCacic.writeDebugLog('executeGerCols: Data/Hora Coleta For�ada ' + UpperCase(tstringsActions[intLoopActions]) + ': '+objCacic.getValueFromTags('DT_HR_COLETA_FORCADA',strActionDefinition));
                                objCacic.setValueToFile('Collects',tstringsActions[intLoopActions] + '_Begin',FormatDateTime('yyyymmddhhnnss', Now), strGerColsInfFileName);

                                if (intLoopActions = 0) then objCacic.writeDailyLog('In�cio de Coletas do Intervalo');

                                objCacic.writeDailyLog('Efetuando coleta de informa��es sobre ' + objCacic.getValueFromTags('te_descricao_breve',strActionDefinition) + '.');

                                if (tstringsActions[intLoopActions] = 'col_anvi') then
                                  Begin
                                    Try
                                       Inc(intTotalExecutedCollects);
                                       strNuVersaoEngine   := '';
                                       strNuVersaoPattern  := '';

                                       If objCacic.isWindows9xME() Then { Windows 9x/ME }
                                        Begin
                                           strChaveRegistro := 'HKEY_LOCAL_MACHINE\Software\TrendMicro\OfficeScanCorp\CurrentVersion';
                                           strNomeExecutavel := 'pccwin97.exe';
                                           strDtHrInstalacao  := objCacic.getValueRegistryKey(strChaveRegistro + '\Install Date') + objCacic.getValueRegistryKey(strChaveRegistro + '\Install Time');
                                           objCacic.writeDebugLog('executeGerCols: Data/Hora de Instala��o: '+strDtHrInstalacao);
                                           strDirTrend := objCacic.getValueRegistryKey(strChaveRegistro + '\Application Path');
                                           If FileExists(strDirTrend + '\filter32.vxd') Then
                                            Begin
                                             // Em m�quinas Windows 9X a vers�o do engine e do pattern n�o s�o gravadas no registro. Tenho que pegar direto dos arquivos.
                                             tstringsLista2RCO := objCacic.explode(objCacic.getVersionInfo(strDirTrend + 'filter32.vxd'), '.'); // Pego s� os dois primeiros d�gitos. Por exemplo: 6.640.0.1001  vira  6.640.
                                             strNuVersaoEngine := tstringsLista2RCO[0] + '.' + tstringsLista2RCO[1];
                                             tstringsLista2RCO.Free;
                                            end
                                           Else
                                              strNuVersaoEngine := '0';

                                           // A gambiarra para coletar a vers�o do pattern � obter a maior extens�o do arquivo lpt$vpn
                                           if FindFirst(strDirTrend + '\lpt$vpn.*', faAnyFile, searchRecResult) = 0 then
                                            Begin
                                             tstringlistLista1RCO := TStringList.Create;
                                             repeat tstringlistLista1RCO.Add(ExtractFileExt(searchRecResult.Name));
                                             until FindNext(searchRecResult) <> 0;
                                             Sysutils.FindClose(searchRecResult);
                                             tstringlistLista1RCO.Sort; // Ordeno, para, em seguida, obter o �ltimo.
                                             strAux := tstringlistLista1RCO[tstringlistLista1RCO.Count - 1];
                                             tstringlistLista1RCO.Free;
                                             strNuVersaoPattern := Copy(strAux, 2, Length(strAux)); // Removo o '.' da extens�o.
                                            End;
                                        End
                                       Else
                                        Begin  // NT a XP
                                           strChaveRegistro   := 'HKEY_LOCAL_MACHINE\Software\TrendMicro\PC-cillinNTCorp\CurrentVersion';
                                           strNomeExecutavel  := 'ntrtscan.exe';
                                           strDtHrInstalacao  := objCacic.getValueRegistryKey(strChaveRegistro + '\InstDate') + objCacic.getValueRegistryKey(strChaveRegistro + '\InstTime');
                                           strNuVersaoEngine  := objCacic.getValueRegistryKey(strChaveRegistro + '\Misc.\EngineZipVer');
                                           strNuVersaoPattern := objCacic.getValueRegistryKey(strChaveRegistro + '\Misc.\PatternVer');
                                           strNuVersaoPattern := Copy(strNuVersaoPattern, 2, Length(strNuVersaoPattern)-3);
                                        end;

                                       objCacic.writeDebugLog('executeGerCols: Vers�o de Engine obtida.: '+strNuVersaoEngine);
                                       objCacic.writeDebugLog('executeGerCols: Vers�o de Pattern obtida: '+strNuVersaoPattern);

                                       strTeServidor       := objCacic.getValueRegistryKey(strChaveRegistro + '\Server');
                                       If (ProgramaRodando(strNomeExecutavel)) Then strInAtivo := '1' Else strInativo := '0';

                                       objCacic.writeDebugLog('executeGerCols: Valor para Estado Ativo.: ' + strInAtivo);

                                       // Monto a string que ser� comparada com o valor armazenado no registro.
                                       strColetaAtual := StringReplace('[EngineVersion]'    + Trim(strNuVersaoEngine)  + '[/EngineVersion]'    +
                                                                       '[PatternVersion]'   + Trim(strNuVersaoPattern) + '[/PatternVersion]'   +
                                                                       '[ServerId]'         + Trim(strTeServidor)      + '[/ServerId]'         +
                                                                       '[InstallDateTime]'  + Trim(strDtHrInstalacao)  + '[/InstallDateTime]'  +
                                                                       '[ActivityStatus]'   + Trim(strInAtivo)         + '[/ActivityStatus]',',','[[COMMA]]',[rfReplaceAll]);

                                       strFieldsAndValuesToRequest := strFieldsAndValuesToRequest + ',AntiVirus='  + objCacic.replaceInvalidHTTPChars(objCacic.enCrypt(strColetaAtual));

                                    Except
                                     on E : Exception do
                                       Begin
                                         objCacic.writeDebugLog('executeGerCols: Lan�ando Exce��o #7');
                                         objCacic.writeExceptionLog(E.Message,E.ClassName,'Exce��o #7 - ' + objCacic.getValueFromTags('te_descricao_breve',strActionDefinition));
                                         objCacic.setValueToFile('Collects',tstringsActions[intLoopActions] + '_End'   , '99999999', strGerColsInfFileName);
                                      End;
                                    End;
                                  End
                                else If (tstringsActions[intLoopActions] = 'col_hard') then
                                  Begin
                                    Try
                                      Inc(intTotalExecutedCollects);

                                      // Insere aqui a a��o da coleta
                                      objCacic.writeDebugLog('executeGerCols: Executando coleta de Hardware -> ');
                                      //tstrColetaHardware := ColetaHardware;

                                      // Coletas de todos os atributos de hardware
                                      tstrColetaHardware := fetchWmiValues('Win32_Keyboard', objCacic.getLocalFolderName, 'Availability,Caption,Description,InstallDate,Name');
                                      strFieldsAndValuesToRequest := strFieldsAndValuesToRequest + ',Win32_Keyboard=' + objCacic.replaceInvalidHTTPChars(objCacic.enCrypt(objCacic.replaceInvalidHTTPChars(tstrColetaHardware)));
//                                      strFieldsAndValuesToRequest := strFieldsAndValuesToRequest + ',Teclado=' + objCacic.replaceInvalidHTTPChars(objCacic.enCrypt(objCacic.replaceInvalidHTTPChars(tstrColetaHardware)));

                                      tstrColetaHardware := fetchWmiValues('Win32_PointingDevice', objCacic.getLocalFolderName, 'Availability,Caption,Description,InstallDate,Manufacturer,Name');
                                      strFieldsAndValuesToRequest := strFieldsAndValuesToRequest + ',Win32_PointingDevice=' + objCacic.replaceInvalidHTTPChars(objCacic.enCrypt(objCacic.replaceInvalidHTTPChars(tstrColetaHardware)));
//                                      strFieldsAndValuesToRequest := strFieldsAndValuesToRequest + ',Mouse=' + objCacic.replaceInvalidHTTPChars(objCacic.enCrypt(objCacic.replaceInvalidHTTPChars(tstrColetaHardware)));

                                      tstrColetaHardware := fetchWmiValues('Win32_PhysicalMedia ', objCacic.getLocalFolderName, 'Caption,Description,InstallDate,Name,Manufacturer,Model,SKU,SerialNumber,Tag,Version,PartNumber,OtherIdentifyingInfo,Capacity,MediaType,MediaDescription');
                                      strFieldsAndValuesToRequest := strFieldsAndValuesToRequest + ',Win32_PhysicalMedia=' + objCacic.replaceInvalidHTTPChars(objCacic.enCrypt(objCacic.replaceInvalidHTTPChars(tstrColetaHardware)));
//                                      strFieldsAndValuesToRequest := strFieldsAndValuesToRequest + ',M�dia F�sica=' + objCacic.replaceInvalidHTTPChars(objCacic.enCrypt(objCacic.replaceInvalidHTTPChars(tstrColetaHardware)));

                                      tstrColetaHardware := fetchWmiValues('Win32_BaseBoard', objCacic.getLocalFolderName, 'Caption,ConfigOptions,Depth,Description,Height,HostingBoard,InstallDate,Manufacturer,Model,Name,OtherIdentifyingInfo,PartNumber,Product,RequirementsDescription,SerialNumber,SKU,SlotLayout,SpecialRequirements,Tag,Version,Weight,Width');
                                      strFieldsAndValuesToRequest := strFieldsAndValuesToRequest + ',Win32_BaseBoard=' + objCacic.replaceInvalidHTTPChars(objCacic.enCrypt(objCacic.replaceInvalidHTTPChars(tstrColetaHardware)));
//                                      strFieldsAndValuesToRequest := strFieldsAndValuesToRequest + ',Placa M�e=' + objCacic.replaceInvalidHTTPChars(objCacic.enCrypt(objCacic.replaceInvalidHTTPChars(tstrColetaHardware)));

                                      // Tenho que dividir a string em dois peda�os porque o Delphi n�o aceita strings individuais com mais de 255 caracteres
                                      tstrColetaHardware := fetchWmiValues('Win32_BIOS', objCacic.getLocalFolderName, 'BiosCharacteristics,BIOSVersion,BuildNumber,Caption,CodeSet,Description,IdentificationCode,InstallDate,Manufacturer,Name,OtherTargetOS,PrimaryBIOS,ReleaseDate,SerialNumber,SMBIOSBIOSVersion,SMBIOSMajorVersion,SMBIOSMinorVersion,' + 'SoftwareElementID,TargetOperatingSystem,Version');
                                      strFieldsAndValuesToRequest := strFieldsAndValuesToRequest + ',Win32_BIOS=' + objCacic.replaceInvalidHTTPChars(objCacic.enCrypt(objCacic.replaceInvalidHTTPChars(tstrColetaHardware)));
//                                      strFieldsAndValuesToRequest := strFieldsAndValuesToRequest + ',BIOS=' + objCacic.replaceInvalidHTTPChars(objCacic.enCrypt(objCacic.replaceInvalidHTTPChars(tstrColetaHardware)));

                                      tstrColetaHardware := fetchWmiValues('Win32_MemoryDevice', objCacic.getLocalFolderName, 'Access,Availability,BlockSize,Caption,Description,DeviceID,EndingAddress,InstallDate,Name,NumberOfBlocks,PNPDeviceID,Purpose,SystemLevelAddress,SystemName');
                                      strFieldsAndValuesToRequest := strFieldsAndValuesToRequest + ',Win32_MemoryDevice=' + objCacic.replaceInvalidHTTPChars(objCacic.enCrypt(objCacic.replaceInvalidHTTPChars(tstrColetaHardware)));
//                                      strFieldsAndValuesToRequest := strFieldsAndValuesToRequest + ',Dispositivos de Mem�ria=' + objCacic.replaceInvalidHTTPChars(objCacic.enCrypt(objCacic.replaceInvalidHTTPChars(tstrColetaHardware)));

                                      tstrColetaHardware := fetchWmiValues('Win32_PhysicalMemory', objCacic.getLocalFolderName, 'BankLabel,Capacity,Caption,DataWidth,Description,DeviceLocator,FormFactor,InstallDate,InterleaveDataDepth,InterleavePosition,Manufacturer,MemoryType,Model,Name,OtherIdentifyingInfo,PartNumber,PositionInRow,' + 'SerialNumber,SKU,Speed,Tag,TotalWidth,TypeDetail,Version');
                                      strFieldsAndValuesToRequest := strFieldsAndValuesToRequest + ',Win32_PhysicalMemory=' + objCacic.replaceInvalidHTTPChars(objCacic.enCrypt(objCacic.replaceInvalidHTTPChars(tstrColetaHardware)));
//                                      strFieldsAndValuesToRequest := strFieldsAndValuesToRequest + ',Mem�ria F�sica=' + objCacic.replaceInvalidHTTPChars(objCacic.enCrypt(objCacic.replaceInvalidHTTPChars(tstrColetaHardware)));

                                      tstrColetaHardware := fetchWmiValues('Win32_Processor', objCacic.getLocalFolderName, 'AddressWidth,Architecture,Availability,Caption,DataWidth,Description,DeviceID,ExtClock,Family,InstallDate,L2CacheSize,L2CacheSpeed,Level,Manufacturer,MaxClockSpeed,Name,NumberOfCores,NumberOfLogicalProcessors,OtherFamilyDescription,PNPDeviceID,' + 'ProcessorId,ProcessorType,Revision,Role,SocketDesignation,SystemName,UniqueId,UpgradeMethod,Version');
                                      strFieldsAndValuesToRequest := strFieldsAndValuesToRequest + ',Win32_Processor=' + objCacic.replaceInvalidHTTPChars(objCacic.enCrypt(objCacic.replaceInvalidHTTPChars(tstrColetaHardware)));
//                                      strFieldsAndValuesToRequest := strFieldsAndValuesToRequest + ',Processador=' + objCacic.replaceInvalidHTTPChars(objCacic.enCrypt(objCacic.replaceInvalidHTTPChars(tstrColetaHardware)));

                                      tstrColetaHardware := fetchWmiValues('Win32_Printer', objCacic.getLocalFolderName, 'Attributes,Availability,Caption,CharSetsSupported,Comment,CurrentCharSet,Default,Description,DeviceID,Direct,DriverName,HorizontalResolution,InstallDate,JobCountSinceLastReset,KeepPrintedJobs,LanguagesSupported,' + 'Local,Location,MarkingTechnology,MaxCopies,MaxNumberUp,MaxSizeSupported,MimeTypesSupported,Name,Network,PaperSizesSupported,PaperTypesAvailable,Parameters,PNPDeviceID,PortName,PrintProcessor,' + 'ServerName,Shared,ShareName,SpoolEnabled,SystemName,VerticalResolution,WorkOffline');
                                      strFieldsAndValuesToRequest := strFieldsAndValuesToRequest + ',Win32_Printer=' + objCacic.replaceInvalidHTTPChars(objCacic.enCrypt(objCacic.replaceInvalidHTTPChars(tstrColetaHardware)));
//                                      strFieldsAndValuesToRequest := strFieldsAndValuesToRequest + ',Impressora=' + objCacic.replaceInvalidHTTPChars(objCacic.enCrypt(objCacic.replaceInvalidHTTPChars(tstrColetaHardware)));

                                      // Adiciona vari�veis da coleta de hardware na requisi��o
                                      //strFieldsAndValuesToRequest := strFieldsAndValuesToRequest + ',Hardware=' + objCacic.replaceInvalidHTTPChars(objCacic.enCrypt(objCacic.replaceInvalidHTTPChars(tstrColetaHardware)));

                                      strColetaAtual := strFieldsAndValuesToRequest;
                                  Except
                                     on E : Exception do
                                       Begin
                                         objCacic.writeDebugLog('executeGerCols: Lan�ando Exce��o #12');
                                         objCacic.writeExceptionLog(E.Message,E.ClassName,'Exce��o #12 - ' + objCacic.getValueFromTags('te_descricao_breve',strActionDefinition));
                                         objCacic.setValueToFile('Collects',tstringsActions[intLoopActions] + '_End'   , '99999999', strGerColsInfFileName);
                                      End;
                                    End;
                                  End
                                else If (tstringsActions[intLoopActions] = 'col_soft') then
                                  Begin
                                    Try
                                      Inc(intTotalExecutedCollects);

                                      // Insere aqui a a��o da coleta
                                      objCacic.writeDebugLog('executeGerCols: Executando coleta de Software -> ');
                                      tstrColetaSoftware := SoftwareList;
                                      
                                      // Adiciona vari�veis da coleta de software na requisi��o
                                      strFieldsAndValuesToRequest := strFieldsAndValuesToRequest + ',SoftwareList=' + objCacic.replaceInvalidHTTPChars(objCacic.enCrypt(objCacic.replaceInvalidHTTPChars(tstrColetaSoftware)));

                                      strColetaAtual := strFieldsAndValuesToRequest;
                                    Except
                                     on E : Exception do
                                       Begin
                                         objCacic.writeDebugLog('executeGerCols: Lan�ando Exce��o #13');
                                         objCacic.writeExceptionLog(E.Message,E.ClassName,'Exce��o #13 - ' + objCacic.getValueFromTags('te_descricao_breve',strActionDefinition));
                                         objCacic.setValueToFile('Collects',tstringsActions[intLoopActions] + '_End'   , '99999999', strGerColsInfFileName);
                                      End;
                                    End;

                                  End
                                else If (tstringsActions[intLoopActions] = 'col_moni') then
                                  Begin
                                    Try
                                     Inc(intTotalExecutedCollects);

                                     // Verifica se dever� ser realizada a coleta de informa��es de sistemas monitorados neste
                                     // computador, perguntando ao Gerente de Coletas.

                                     ShortDateFormat      := 'dd/mm/yyyy';
                                     intAux4              := 1;
                                     strAux3              := '';
                                     strValorChavePerfis  := '*';
                                     strLetrasDrives      := LetrasDrives;

                                     while strValorChavePerfis <> '' do
                                        begin
                                           strAux3 := 'col_moni_perfil_' + trim(inttostr(intAux4));
                                           strTripa := ''; // Conter� as informa��es a serem enviadas ao Gerente.
                                           // Obtenho do registro o valor que foi previamente armazenado
                                           strValorChavePerfis := Trim(objCacic.deCrypt( objCacic.GetValueFromFile('Collects',strAux3,strGerColsInfFileName)));

                                           if (strValorChavePerfis <> '') then
                                             Begin
                                                 //Aten��o, OS ELEMENTOS DEVEM ESTAR DE ACORDO COM A ORDEM QUE S�O TRATADOS NO M�DULO GERENTE.
                                                 tstringsTripa2  := objCacic.explode(strValorChavePerfis,',');
                                                 if (strColetaAtual <> '') then strColetaAtual := strColetaAtual + '#';
                                                 strColetaAtual := strColetaAtual + trim(tstringsTripa2[0]) + ',';


                                                 ///////////////////////////////////////////
                                                 ///// Coleta de Informa��o de Licen�a /////
                                                 ///////////////////////////////////////////
                                                 // Devo gerar algo como [Licence][/Licence]
                                                 //Vazio
                                                 if (trim(tstringsTripa2[2])='0') then
                                                   Begin
                                                      strColetaAtual := strColetaAtual + ',';
                                                   End;

                                                 //Caminho\Chave\Valor em Registry
                                                 if (trim(tstringsTripa2[2])='1') then
                                                   Begin
                                                      strAux4 := '';
                                                      objCacic.writeDebugLog('executeGerCols: Buscando informa��o de LICEN�A em '+tstringsTripa2[3]);
                                                      Try
                                                        strAux4 := Trim(objCacic.getValueRegistryKey(trim(tstringsTripa2[3])));
                                                      Except
                                                      End;
                                                      if (strAux4 = '') then strAux4 := '?';
                                                      strColetaAtual  := strColetaAtual + strAux4 + ',';
                                                   End;

                                                 //Nome/Se��o/Chave de Arquivo INI
                                                 if (trim(tstringsTripa2[2])='2') then
                                                   Begin
                                                      objCacic.writeDebugLog('executeGerCols: Buscando informa��o de LICEN�A em '+tstringsTripa2[3]);
                                                      Try
                                                        if (LastPos('/',trim(tstringsTripa2[3]))>0) then
                                                          Begin
                                                            tstringsTripa3  := objCacic.explode(trim(tstringsTripa2[3]),'/');
                                                            //
                                                            for intLoopExecutaGerCols := 1 to length(strLetrasDrives) do
                                                              Begin
                                                                strFileName := trim(tstringsTripa3[0]);
                                                                if (LastPos(':\',strFileName)>0) then
                                                                  Begin
                                                                    strDrive    := Copy(strFileName,1,3);
                                                                    strFileName := Copy(strFileName,4,Length(strFileName));
                                                                  End
                                                                else
                                                                  Begin
                                                                    strDrive := strLetrasDrives[intLoopExecutaGerCols] + ':';
                                                                    if (Copy(strFileName,1,1)<>'\') then strDrive := strDrive + '\';
                                                                    strFileName  := Copy(strFileName,1,Length(strFileName));
                                                                  End;

                                                                strAux1 := ExtractShortPathName(strDrive + strFileName);
                                                                if (strAux1 = '') then
                                                                  begin
                                                                    if (SearchFile(strDrive,strFileName)) then
                                                                      Begin
                                                                        strAux1 := strResultSearch;
                                                                        break;
                                                                      End;
                                                                  end
                                                                else break;
                                                              End;

                                                            strAux4 := Trim(objCacic.GetValueFromFile(tstringsTripa3[1],tstringsTripa3[2],strAux1));
                                                            if (strAux4 = '') then strAux4 := '?';
                                                            strColetaAtual := strColetaAtual + strAux4 + ',';
                                                          End;

                                                        if (LastPos('/',trim(tstringsTripa2[3]))=0) then
                                                          Begin
                                                            strColetaAtual := strColetaAtual + 'Par�m.Lic.Incorreto,';
                                                          End
                                                      Except
                                                        on E : Exception do
                                                        Begin
                                                          objCacic.writeDebugLog('executeGerCols: Lan�ando Exce��o #10');
                                                          objCacic.writeExceptionLog(E.Message,E.ClassName,'Exce��o #10 - ' + strColetaAtual + 'Par�m.Lic.Incorreto');
                                                          strColetaAtual := strColetaAtual + 'Par�m.Lic.Incorreto,';
                                                        End;
                                                      End;
                                                   End;

                                                 //////////////////////////////////////////////
                                                 ///// Coleta de Informa��o de Instala��o /////
                                                 //////////////////////////////////////////////
                                                 // Devo gerar algo como [InstallDateTime][/InstallDateTime]
                                                 //Vazio
                                                 if (trim(tstringsTripa2[5])='0') then
                                                   Begin
                                                      strColetaAtual := strColetaAtual + ',';
                                                   End;

                                                 //Nome de Execut�vel OU Nome de Arquivo de Configura��o (CADPF!!!)
                                                 if (trim(tstringsTripa2[5])='1') or (trim(tstringsTripa2[5]) = '2') then
                                                   Begin
                                                    strAux1 := '';
                                                    for intLoopExecutaGerCols := 1 to length(strLetrasDrives) do
                                                      Begin
                                                      strFileName := trim(tstringsTripa2[6]);
                                                      objCacic.writeDebugLog('executeGerCols: Buscando informa��o de INSTALA��O em '+tstringsTripa2[6]);
                                                      if (LastPos(':\',strFileName)>0) then
                                                        Begin
                                                          strDrive    := Copy(strFileName,1,3);
                                                          strFileName := Copy(strFileName,4,Length(strFileName));
                                                        End
                                                      else
                                                        Begin
                                                          strDrive := strLetrasDrives[intLoopExecutaGerCols] + ':';
                                                          if (Copy(strFileName,1,1)<>'\') then strDrive := strDrive + '\';
                                                          strFileName  := Copy(strFileName,1,Length(strFileName));
                                                        End;

                                                        strAux1 := ExtractShortPathName(strDrive + strFileName);
                                                        if (strAux1 = '') then
                                                          begin
                                                            if (SearchFile(strDrive,strFileName)) then
                                                              Begin
                                                                strAux1 := strResultSearch;
                                                                break;
                                                              End;
                                                          end
                                                        else break;

                                                      End;

                                                    if (strAux1 <> '') then strColetaAtual := strColetaAtual + 'S,';
                                                    if (strAux1 = '')  then strColetaAtual := strColetaAtual + 'N,';
                                                    strAux1 := '';
                                                   End;

                                                 //Caminho\Chave\Valor em Registry
                                                 if (trim(tstringsTripa2[5])='3') then
                                                   Begin
                                                    strAux1 := '';
                                                    Try
                                                      objCacic.writeDebugLog('executeGerCols: Buscando informa��o de INSTALA��O em '+tstringsTripa2[6]);
                                                      // Anderson PETERLE - 31JAN2013
                                                      // Recurso para buscar indicativo de instala��o na sess�o HKEY_CLASSES_ROOT
                                                      if (Pos('{',tstringsTripa2[6]) > 0) then
                                                        strAux1 := objCacic.getVersionFromHCR(tstringsTripa2[6])
                                                      else
                                                        strAux1 := Trim(objCacic.getValueRegistryKey(trim(tstringsTripa2[6])));
                                                      //

                                                    Except
                                                    End;
                                                    if (strAux1 <> '') then strColetaAtual  := strColetaAtual + 'S,';
                                                    if (strAux1 = '')  then strColetaAtual := strColetaAtual + 'N,';
                                                    strAux1 := '';
                                                   End;



                                                 //////////////////////////////////////////
                                                 ///// Coleta de Informa��o de Vers�o /////
                                                 //////////////////////////////////////////
                                                 // Devo gerar algo como [Version][/Version]
                                                 //Vazio
                                                 if (trim(tstringsTripa2[7])='0') then
                                                   strColetaAtual := strColetaAtual + ',';

                                                 //Data de Arquivo
                                                 if (trim(tstringsTripa2[7])='1') then
                                                   Begin
                                                    strAux1 := '';
                                                    objCacic.writeDebugLog('executeGerCols: Buscando informa��o de VERS�O em '+tstringsTripa2[8]);
                                                    for intLoopExecutaGerCols:=1 to length(strLetrasDrives) do
                                                      Begin
                                                      strFileName := trim(tstringsTripa2[8]);
                                                      if (LastPos(':\',strFileName)>0) then
                                                        Begin
                                                          strDrive    := Copy(strFileName,1,3);
                                                          strFileName := Copy(strFileName,4,Length(strFileName));
                                                        End
                                                      else
                                                        Begin
                                                          strDrive := strLetrasDrives[intLoopExecutaGerCols] + ':';
                                                          if (Copy(strFileName,1,1)<>'\') then strDrive := strDrive + '\';
                                                          strFileName  := Copy(strFileName,1,Length(strFileName));
                                                        End;

                                                        strAux1 := ExtractShortPathName(strDrive + strFileName);
                                                        if (strAux1 = '') then
                                                          begin
                                                            if (SearchFile(strDrive,strFileName)) then
                                                              Begin
                                                                strAux1 := strResultSearch;
                                                                break;
                                                              End;
                                                          end
                                                        else break;
                                                      End;

                                                    if (strAux1 <> '') then
                                                      Begin
                                                        strAux3 := StringReplace(DateToStr(FileDateToDateTime(FileAge(strAux1))),'.','/',[rfReplaceAll]);
                                                        strAux3 := StringReplace(strAux3,'-','/',[rfReplaceAll]);
                                                        strColetaAtual  := strColetaAtual + strAux3 + ',';
                                                        strDate := '';
                                                      End;

                                                    if (strAux1 = '') then strColetaAtual := strColetaAtual + '?,';
                                                    strAux1 := '';
                                                   End;

                                                 //Caminho\Chave\Valor em Registry
                                                 if (trim(tstringsTripa2[7])='2') then
                                                   Begin
                                                    strAux1 := '';
                                                    objCacic.writeDebugLog('executeGerCols: Buscando informa��o de VERS�O em '+tstringsTripa2[8]);
                                                    Try
                                                      // Anderson PETERLE - 31JAN2013
                                                      // Recurso para buscar vers�o na sess�o HKEY_CLASSES_ROOT
                                                      if (Pos('{',tstringsTripa2[8]) > 0) then
                                                        strAux1 := objCacic.getVersionFromHCR(tstringsTripa2[8])
                                                      else
                                                        strAux1 := Trim(objCacic.getValueRegistryKey(trim(tstringsTripa2[8])));
                                                      //
                                                    Except
                                                    End;
                                                    if (strAux1 <> '') then strColetaAtual := strColetaAtual + strAux1 + ',';
                                                    if (strAux1 = '')  then strColetaAtual := strColetaAtual + '?,';
                                                    strAux1 := '';
                                                   End;


                                                 //Nome/Se��o/Chave de Arquivo INI
                                                 if (trim(tstringsTripa2[7])='3') then
                                                   Begin
                                                      Try
                                                        objCacic.writeDebugLog('executeGerCols: Buscando informa��o de VERS�O em '+tstringsTripa2[8]);
                                                        if (LastPos('/',trim(tstringsTripa2[8]))>0) then
                                                          Begin
                                                            tstringsTripa3  := objCacic.explode(trim(tstringsTripa2[8]),'/');
                                                            //
                                                            for intLoopExecutaGerCols:=1 to length(strLetrasDrives) do
                                                              Begin
                                                                strFileName := trim(tstringsTripa3[0]);
                                                                if (LastPos(':\',strFileName)>0) then
                                                                  Begin
                                                                    strDrive    := Copy(strFileName,1,3);
                                                                    strFileName := Copy(strFileName,4,Length(strFileName));
                                                                  End
                                                                else
                                                                  Begin
                                                                    strDrive := strLetrasDrives[intLoopExecutaGerCols] + ':';
                                                                    if (Copy(strFileName,1,1)<>'\') then strDrive := strDrive + '\';
                                                                    strFileName  := Copy(strFileName,1,Length(strFileName));
                                                                  End;

                                                                strAux1 := ExtractShortPathName(strDrive + strFileName);
                                                                if (strAux1 = '') then
                                                                  begin
                                                                    if (SearchFile(strDrive,strFileName)) then
                                                                      Begin
                                                                        strAux1 := strResultSearch;
                                                                        break;
                                                                      End;
                                                                  end
                                                                else break;
                                                              End;

                                                            //
                                                            strAux4 := Trim(objCacic.GetValueFromFile(tstringsTripa3[1],tstringsTripa3[2],strAux1));
                                                            if (strAux4 = '') then strAux4 := '?';
                                                            strColetaAtual := strColetaAtual + strAux4 + ',';
                                                          End
                                                        else
                                                          Begin
                                                            strColetaAtual := strColetaAtual + 'Par�m.Versao Incorreto,';
                                                          End;
                                                      Except
                                                      End;
                                                   End;


                                               //Vers�o de Execut�vel
                                               if (trim(tstringsTripa2[7])='4') then
                                                 Begin
                                                   objCacic.writeDebugLog('executeGerCols: Buscando informa��o de VERS�O em '+tstringsTripa2[8]);
                                                   Try
                                                    boolFound := false;
                                                    for intLoopExecutaGerCols:= 1 to length(strLetrasDrives) do
                                                      Begin
                                                        if not boolFound then
                                                          Begin
                                                            strFileName := trim(tstringsTripa2[8]);
                                                            if (LastPos(':\',strFileName)>0) then
                                                              Begin
                                                                strDrive := Copy(strFileName,1,3);
                                                                strFileName  := Copy(strFileName,4,Length(strFileName));
                                                              End
                                                            else
                                                              Begin
                                                                strDrive := strLetrasDrives[intLoopExecutaGerCols] + ':';
                                                                if (Copy(strFileName,1,1)<>'\') then strDrive := strDrive + '\';
                                                                strFileName  := Copy(strFileName,1,Length(strFileName));
                                                              End;

                                                            strAux1 := ExtractShortPathName(strDrive + strFileName);
                                                            if (strAux1 = '') then
                                                              begin
                                                              if (SearchFile(strDrive,strFileName)) then
                                                                Begin
                                                                  strAux1 := strResultSearch;
                                                                  boolFound := true;
                                                                End;
                                                              end
                                                            else boolFound := true;
                                                          End;
                                                      End;
                                                   Except
                                                   End;

                                                   if (strAux1 <> '') then
                                                      Begin
                                                        strColetaAtual := strColetaAtual + objCacic.GetVersionInfo(strAux1);
                                                      End
                                                  else strColetaAtual := strColetaAtual + '?';

                                                  strColetaAtual := strColetaAtual + ',';

                                                 End;


                                                 //////////////////////////////////////////
                                                 ///// Coleta de Informa��o de Engine /////
                                                 //////////////////////////////////////////
                                                 // Devo gerar algo como [Engine][/Engine]
                                                 //Vazio
                                                 if (trim(tstringsTripa2[9])='.') then
                                                   Begin
                                                      strColetaAtual := strColetaAtual + ',';
                                                   End;

                                                 //Arquivo para Vers�o de Engine
                                                 //O ponto � proposital para quando o �ltimo par�metro vem vazio do Gerente!!!  :)
                                                 if (trim(tstringsTripa2[9])<>'.') then
                                                   Begin
                                                    objCacic.writeDebugLog('executeGerCols: Buscando informa��o de ENGINE em '+tstringsTripa2[9]);
                                                    for intLoopExecutaGerCols := 1 to length(strLetrasDrives) do
                                                      Begin
                                                        strFileName := trim(tstringsTripa2[9]);
                                                        if (LastPos(':\',strFileName)>0) then
                                                          Begin
                                                            strDrive    := Copy(strFileName,1,3);
                                                            strFileName := Copy(strFileName,4,Length(strFileName));
                                                          End
                                                        else
                                                          Begin
                                                            strDrive := strLetrasDrives[intLoopExecutaGerCols] + ':';
                                                            if (Copy(strFileName,1,1)<>'\') then strDrive := strDrive + '\';
                                                            strFileName  := Copy(strFileName,1,Length(strFileName));
                                                          End;

                                                        strAux1 := ExtractShortPathName(strDrive + strFileName);
                                                        if (strAux1 = '') then
                                                          begin
                                                            if (SearchFile(strDrive,strFileName)) then
                                                              Begin
                                                                strAux1 := strResultSearch;
                                                                break;
                                                              End;
                                                          end
                                                        else break;
                                                      End;
                                                    if (strAux1 <> '') then
                                                      Begin
                                                        tstringsTripa3 := objCacic.explode(objCacic.GetVersionInfo(strAux1), '.'); // Pego s� os dois primeiros d�gitos. Por exemplo: 6.640.0.1001  vira  6.640.
                                                        strColetaAtual := strColetaAtual + tstringsTripa3[0] + '.' + tstringsTripa3[1];
                                                      End;
                                                   End;


                                                 ///////////////////////////////////////////
                                                 ///// Coleta de Informa��o de Pattern /////
                                                 ///////////////////////////////////////////
                                                 // Devo gerar algo como [Pattern][/Pattern]
                                                 //Arquivo para Vers�o de Pattern
                                                 //O ponto � proposital para quando o �ltimo par�metro vem vazio do Gerente!!!  :)
                                                 strAux1 := '';
                                                 if (trim(tstringsTripa2[10])<>'.') then
                                                   Begin
                                                    objCacic.writeDebugLog('executeGerCols: Buscando informa��o de PATTERN em '+tstringsTripa2[9]);
                                                      for intLoopExecutaGerCols := 1 to length(strLetrasDrives) do
                                                        Begin
                                                        strFileName := trim(tstringsTripa2[10]);
                                                        if (LastPos(':\',strFileName)>0) then
                                                          Begin
                                                            strDrive := Copy(strFileName,1,3);
                                                            strFileName  := Copy(strFileName,4,Length(strFileName));
                                                          End
                                                        else
                                                          Begin
                                                            strDrive := strLetrasDrives[intLoopExecutaGerCols] + ':';
                                                            if (Copy(strFileName,1,1)<>'\') then strDrive := strDrive + '\';
                                                            strFileName  := Copy(strFileName,1,Length(strFileName));
                                                          End;

                                                          strAux1 := ExtractShortPathName(strDrive + strFileName);
                                                          if (strAux1 = '') then
                                                            begin
                                                            if (SearchFile(strDrive, strFileName)) then
                                                              Begin
                                                                strAux1 := strResultSearch;
                                                                break;
                                                              End;
                                                          end
                                                        else break;

                                                        End;
                                                   End;
                                                   if (strAux1 <> '') then
                                                      Begin
                                                        tstringsTripa3 := objCacic.explode(objCacic.GetVersionInfo(strAux1), '.'); // Pego s� os dois primeiros d�gitos. Por exemplo: 6.640.0.1001  vira  6.640.
                                                        strColetaAtual := strColetaAtual + tstringsTripa3[0] + '.' + tstringsTripa3[1];
                                                      End;
                                                   if (strAux1 = '') then strColetaAtual := strColetaAtual + ',';
                                                   strAux1 := '';
                                             End;
                                             intAux4 := intAux4 + 1;
                                        End;

                                      strColetaAtual := StringReplace(strColetaAtual,',','[[COMMA]]',[rfReplaceAll]);

                                      strFieldsAndValuesToRequest := strFieldsAndValuesToRequest + ',MonitoredProfiles=' + objCacic.replaceInvalidHTTPChars(objCacic.enCrypt(strColetaAtual));

                                    Except
                                      Begin
                                        objCacic.setValueToFile('Collects',tstringsActions[intLoopActions] + '_End'   ,'99999999', strGerColsInfFileName);
                                      End;
                                    End;
                                  End
                                else If (tstringsActions[intLoopActions] = 'col_soft_not_optional') then
                                  Begin
                                    Try
                                      Inc(intTotalExecutedCollects);
                                      // Monto a string que ser� comparada com o valor armazenado no registro local.
                                      strColetaAtual := StringReplace('[ODBCVersion]'           + GetODBCVersion          + '[/ODBCVersion]'           +
                                                                      '[BDEVersion]'            + GetBDEVersion           + '[/BDEVersion]'            +
                                                                      '[DAOVersion]'            + GetDAOVersion           + '[/DAOVersion]'            +
                                                                      '[ADOVersion]'            + GetADOVersion           + '[/ADOVersion]'            +
                                                                      '[DirectXVersion]'        + GetDirectXVersion       + '[/DirectXVersion]'        +
                                                                      '[MozillaVersion]'        + GetMozillaVersion       + '[/MozillaVersion]'        +
                                                                      '[IEVersion]'             + GetIEVersion            + '[/IEVersion]'             +
                                                                      '[AcrobatReaderVersion]'  + GetAcrobatReaderVersion + '[/AcrobatReaderVersion]'  +
                                                                      '[JREVersion]'            + GetJREVersion           + '[/JREVersion]',','   ,'[[COMMA]]',[rfReplaceAll]);

                                      strFieldsAndValuesToRequest := strFieldsAndValuesToRequest + ',NotOptionalBasicSoftwares='   + objCacic.replaceInvalidHTTPChars(objCacic.enCrypt(strColetaAtual));
                                    Except
                                    End;
                                  End
                                Else
                                  Begin
                                    Try
                                      Inc(intTotalExecutedCollects);
                                      strClassesAndProperties := objCacic.getValueFromTags('ClassesAndProperties',strActionDefinition);

                                      objCacic.writeDebugLog('executeGerCols: strClassesAndProperties -> "' + strClassesAndProperties + '"');
                                      tstringsClasses    := objCacic.explode(objCacic.getValueFromTags('Classes',strClassesAndProperties),',');

                                      for intLoopClasses := 0 to tstringsClasses.Count - 1 do
                                        Begin
                                          objCacic.writeDebugLog('executeGerCols: Coletando dados de Win32_' + tstringsClasses[intLoopClasses]);
                                          strFieldsAndValuesToRequest := strFieldsAndValuesToRequest + ',' + tstringsClasses[intLoopClasses] + '=' + objCacic.replaceInvalidHTTPChars(objCacic.enCrypt(objCacic.replaceInvalidHTTPChars(fetchWmiValues('Win32_' + tstringsClasses[intLoopClasses],objCacic.getLocalFolderName, objCacic.getValueFromTags(tstringsClasses[intLoopClasses] + '.Properties',strClassesAndProperties),objCacic.getValueFromTags(tstringsClasses[intLoopClasses] + '.WhereClause',strClassesAndProperties)))));
                                        End;

                                      strColetaAtual := strFieldsAndValuesToRequest;
                                    Except
                                     on E : Exception do
                                       Begin
                                         objCacic.writeDebugLog('executeGerCols: Lan�ando Exce��o #8');
                                         objCacic.writeExceptionLog(E.Message,E.ClassName,'Exce��o #8 - ' + objCacic.getValueFromTags('te_descricao_breve',strActionDefinition));
                                         objCacic.setValueToFile('Collects',tstringsActions[intLoopActions] + '_End'   , '99999999', strGerColsInfFileName);
                                       End;
                                    End;
                                  End;

                                if (strColetaAtual <> '') then
                                  Begin
                                     objCacic.writeDebugLog('executeGerCols: ColetaAtual: "' + strColetaAtual + '"');
                                     objCacic.writeDebugLog('executeGerCols: Fields And Values To Request: "' + strFieldsAndValuesToRequest + '"');

                                     objCacic.setValueToFile('Collects',tstringsActions[intLoopActions]+'_End',FormatDateTime('yyyymmddhhnnss', Now), strGerColsInfFileName);

                                     // Obtenho do registro o valor que foi previamente armazenado
                                     strColetaAnterior := objCacic.GetValueFromFile('Collects',tstringsActions[intLoopActions],strGerColsInfFileName);

                                     objCacic.writeDebugLog('executeGerCols: Registro Anterior: ' + strColetaAnterior);
                                     objCacic.writeDebugLog('executeGerCols: Registro Atual...: ' + strColetaAtual);

                                     objCacic.writeDebugLog('executeGerCols: Coleta For�ada? -> ' + objCacic.getValueFromTags('DT_HR_COLETA_FORCADA',strActionDefinition));
                                     // Se essas informa��es forem diferentes significa que houve alguma altera��o na configura��o. Nesse caso, gravo as informa��es no BD Central e,
                                     // se n�o houver problemas durante esse procedimento, atualizo o registro local.
                                     // Se for uma coleta for�ada, tamb�m grava as informa��es.
                                     If (objCacic.enCrypt(strColetaAtual) <> strColetaAnterior) or
                                        (strColetaAnterior = '') or
                                        (objCacic.getValueFromFile('Configs', 'forca_coleta', strGerColsInfFileName) = 'S') Then
                                        Begin
                                          strAcaoGercols := 'Enviando coleta de informa��es sobre ' + objCacic.getValueFromTags('te_descricao_breve',strActionDefinition) +  ' para o Gerente WEB ('+objCacic.getWebManagerAddress+').';
                                          objCacic.writeDailyLog(strAcaoGercols);

                                          // Prepara��o para envio...
                                          if (Comm(objCacic.getWebManagerAddress + objCacic.getWebServicesFolderName + 'gercols/set/collects', strFieldsAndValuesToRequest, objCacic.getLocalFolderName, strAcaoGerCols) <> '0') Then
                                            Begin
                                              objCacic.writeDailyLog('Ok! Coleta de informa��es sobre ' + objCacic.getValueFromTags('te_descricao_breve',strActionDefinition) + ' enviada com sucesso!');
                                              objCacic.setBoolCipher(not objCacic.isInDebugMode);
                                              objCacic.setValueToFile('Collects',tstringsActions[intLoopActions],objCacic.enCrypt(strColetaAtual), strGerColsInfFileName);
                                              objCacic.setValueToFile('Collects',tstringsActions[intLoopActions] + '_Send_Status','1', strGerColsInfFileName);
                                              inc(intTotalSendedCollects);
                                            End
                                          else
                                            Begin
                                              objCacic.writeDebugLog('executeGerCols: Problema no envio de ' + objCacic.getValueFromTags('te_descricao_breve',strActionDefinition) + '!');
                                              objCacic.setValueToFile('Collects','ColAnvi_Status','0', strGerColsInfFileName);
                                            End;
                                        End;
                                  End;
                              End;
                        End;
                      objCacic.writeDailyLog('Fim de Coletas do Intervalo');
                    end;

                 if (intTotalExecutedCollects = 0) then
                   objCacic.writeDailyLog('Nenhuma coleta configurada para essa subrede / esta��o / S.O.');
            End;

        // Reinicializo o indicador de Fila de Espera para FTP
        objCacic.setValueToFile('Configs','TeFilaFTP','0', strGerColsInfFileName);

        if (intTotalSendedCollects > 0) then
          objCacic.writeDailyLog('Os dados coletados - e n�o redundantes - foram enviados ao Gerente WEB ('+objCacic.getWebManagerAddress+').')
        else if (intTotalSendedCollects = 0) then
          objCacic.writeDailyLog('Problemas no envio ou sem informa��es novas para envio.');
      End;
    Except
      Begin
        objCacic.writeDailyLog('PROBLEMAS EM EXECUTA_GERCOLS! A��o: "' + strAcaoGercols+'".');
        objCacic.CriaTXT(objCacic.getLocalFolderName,'gererro',strAcaoGerCols);
        objCacic.setValueToFile('Mensagens','CsTipo'    , 'mtError'     , strGerColsInfFileName);
        objCacic.setValueToFile('Mensagens','TeMensagem', strAcaoGercols, strGerColsInfFileName);
        Finalizar(false);
        Sair;
      End;
  End;
End;

begin
   objCacic := TCACIC.Create();
   objCacic.setBoolCipher(true);

   // Setando os par�metros obrigat�rios
   objCacic.setLocalFolderName(objCacic.GetParam('LocalFolderName'));
   objCacic.setWebServicesFolderName(objCacic.GetParam('WebServicesFolderName'));
   objCacic.setWebManagerAddress(objCacic.GetParam('WebManagerAddress'));
   objCacic.setMainProgramName(LowerCase(objCacic.GetParam('MainProgramName')));
   objCacic.setMainProgramHash(objCacic.GetParam('MainProgramHash'));


   // TESTES DOM�STICOS (VPN)
   {
   objCacic.setLocalFolderName('Cacic');
   objCacic.setWebServicesFolderName('ws/');
   objCacic.setWebManagerAddress('http://10.71.0.205/cacic3/');
   objCacic.setMainProgramName('cacic280.exe');

   tstrModulosOpcoes := objCacic.getTagsFromValues('[Um]Numero UM[/Um][Dois]Numero DOIS[/Dois]');
   strAux            := objCacic.getValueFromTags('Dois','[Um]Numero UM[/Um][Dois]Numero DOIS[/Dois][Tres]Numero TRES[/Tres]');
   strAux            := objCacic.getValueFromTags('Um','[Um]Numero UM[/Um][Dois]Numero DOIS[/Dois][Tres]Numero TRES[/Tres]');
   strAux            := objCacic.getValueFromTags('Tres','[Um]Numero UM[/Um][Dois]Numero DOIS[/Dois][Tres]Numero TRES[/Tres]');
   strAux            := objCacic.getValueFromTags('Quatro','[Um]Numero UM[/Um][Dois]Numero DOIS[/Dois][Tres]Numero TRES[/Tres]');

   strAux := '[Um]Numero UM[/Um][Dois]Numero DOIS[/Dois][Tres]Numero TRES[/Tres]';
   objCacic.setValueToTags('Tres','Number Three',strAux);
   objCacic.setValueToTags('Dois','Duo',strAux);
   objCacic.setValueToTags('Cinco','Five',strAux);
   }      


   if (objCacic.getWebManagerAddress() <> '') then
      Begin
        strGerColsInfFileName     := objCacic.getLocalFolderName + 'GerCols.inf';
        strChkSisInfFileName      := objCacic.getWinDir          + 'ChkSis.inf';
        strMainProgramInfFileName := objCacic.getLocalFolderName + ChangeFileExt(objCacic.getMainProgramName,'.inf');
        Try
          if not DirectoryExists(objCacic.getLocalFolderName + 'Temp') then
            ForceDirectories(objCacic.getLocalFolderName + 'Temp');

          // N�o tirar desta posi��o
          objCacic.setValueToFile('Configs','TeSO'      , objCacic.getWindowsStrId(), strGerColsInfFileName);
          objCacic.setValueToFile('Configs','CsCipher'  , '1'                       ,strGerColsInfFileName);
          objCacic.setValueToFile('Configs','CsCompress', '0'                       ,strGerColsInfFileName);
          objCacic.writeDebugLog('GerCols: Te_So obtido: "' + objCacic.getWindowsStrId() +'"');

          strAcaoGercols := 'Iniciando teste de comunica��o com o M�dulo Gerente WEB ('+objCacic.getWebManagerAddress+')';
          
          CriaCookie('aguarde_GER.txt');

          // Esse teste tamb�m colocar� a esta��o de trabalho em DEBUG, caso seja determinado no Gerente WEB
          if FindCmdLineSwitch ('getTest', True) then
          begin
            getTest();
            Finalizar(true);
			      halt(0);
          end
          else
            Comm(objCacic.getWebManagerAddress + objCacic.getWebServicesFolderName + 'get/test', strFieldsAndValuesToRequest, objCacic.getLocalFolderName, strAcaoGerCols);

          objCacic.setBoolCipher(not objCacic.isInDebugMode);

          objCacic.writeDebugLog('GerCols: ' + DupeString('*',100));
          objCacic.writeDebugLog('GerCols: In�cio de Execu��o');
          objCacic.writeDebugLog('GerCols: ' + DupeString('*',100));
          objCacic.writeDebugLog('GerCols: ' + DupeString('=',100));
          objCacic.writeDebugLog('GerCols: Par�metros recebidos: ' + IntToStr(ParamCount));
          objCacic.writeDebugLog('GerCols: ' + DupeString('=',100));

          intAuxGerCols      := 1;
          while (intAuxGerCols <= ParamCount) do
            Begin
              objCacic.writeDebugLog('GerCols: ' + ParamStr(intAuxGerCols));
              inc(intAuxGerCols);
            End;
          objCacic.writeDebugLog('GerCols: ' + DupeString('=',100));
          executeGerCols;
          Finalizar(true);
        Except
          Begin
            objCacic.writeDailyLog('PROBLEMAS EM EXECUTA_GERCOLS! A��o : ' + strAcaoGercols+'.');
            objCacic.CriaTXT(objCacic.getLocalFolderName,'gererro', strAcaoGerCols);
            objCacic.setValueToFile('Mensagens','CsTipo'    , 'mtError', strGerColsInfFileName);
            objCacic.setValueToFile('Mensagens','TeMensagem', strAcaoGercols, strGerColsInfFileName);
            Finalizar(false);
          End;
        End;
      End
    else
      objCacic.writeDailyLog('GERCOLS executado de forma incorreta! Par�metros obrigat�rios ausentes!');

    Halt(0);
end.
