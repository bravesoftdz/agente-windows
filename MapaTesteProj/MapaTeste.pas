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

unit MapaTeste;

interface

uses
  Windows,
  SysUtils,    // Deve ser colocado ap�s o Windows acima, nunca antes
  StrUtils,
  StdCtrls,
  Controls,
  Classes,
  Forms,
  ExtCtrls,
  Graphics,
  Dialogs,
  CACIC_Library,
  CACIC_Comm,
  ComCtrls,
  Commctrl,
  ShellAPI,
  Types,
  IdIPWatch,
  Registry,
  Math,
  IdBaseComponent,
  IdComponent,
  Mask,
  ComObj,
  ldapsend;

function IsUserAnAdmin() : boolean; external shell32;

var strCollectsPatrimonioLast,
    strConfigsPatrimonioCombos,
    strFieldsAndValuesToRequest,
    strIdUON1,
    strFrmAtual,
    strShowOrHide               : string;
    textFileAguarde             : TextFile;
    boolFinalizando             : boolean;
    objCacic                    : TCACIC;
    Fechar                      : boolean;
    Dummy                       : integer;
    OldValue                    : LongBool;

type
  TfrmMapaCacic = class(TForm)
    edWebManagerAddress: TLabel;
    lbWebManagerAddress: TLabel;
    pnVersao: TPanel;
    timerMessageBoxShowOrHide: TTimer;
    timerMessageShowTime: TTimer;
    timerProcessos: TTimer;
    IdIPWatch1: TIdIPWatch;
    pnMessageBox: TPanel;
    lbMensagens: TLabel;
    gbLeiaComAtencao: TGroupBox;
    lbLeiaComAtencao: TLabel;
    gbInformacoesSobreComputador: TGroupBox;
    lbEtiqueta5: TLabel;
    lbEtiqueta6: TLabel;
    lbEtiquetaUserLogado: TLabel;
    lbEtiquetaNomeComputador: TLabel;
    lbEtiquetaIpComputador: TLabel;
    lbEtiquetaPatrimonioPc: TLabel;
    lbEtiquetaNome: TLabel;
    edTeInfoPatrimonio5: TEdit;
    edTeInfoPatrimonio6: TEdit;
    btCombosUpdate: TButton;
    edTeInfoUserLogado: TEdit;
    edTeInfoNomeComputador: TEdit;
    edTeInfoIpComputador: TEdit;
    edTePatrimonioPc: TEdit;
    edTeInfoNome: TEdit;
    bgTermoResponsabilidade: TGroupBox;
    rdConcordaTermos: TRadioButton;
    btGravarInformacoes: TButton;
    
    procedure FormCreate(Sender: TObject);
    procedure AtualizaPatrimonio(Sender: TObject);
    procedure mapa;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormActivate(Sender: TObject);
    procedure btCombosUpdateClick(Sender: TObject);
    procedure timerProcessosTimer(Sender: TObject);
    procedure rdConcordaTermosClick(Sender: TObject);
    procedure EstadoBarraTarefa(EstadoBarra: Boolean);

    function getLastValue(S : String; separador : string): string; 
    function LDAPName: string;
    function NomeComputador : String;
    function getUserLogon : String;
    function getConfigs : String;
    function SetCpfUser : String;
    function SetPatrimonioPC : String;
    function FormatarCpf(strCpfUser : String) : String;


  private
    strTeInfoPatrimonio1,
    strTeInfoPatrimonio2,
    strTeInfoPatrimonio3,
    strTeInfoPatrimonio4,
    strTeInfoPatrimonio5,
    strTeInfoPatrimonio6,
    strTeInfoPatrimonio7    : String;

    procedure FormSetFocus(VerificaFoco: Boolean);
    procedure MontaInterface;
    procedure RecuperaValoresAnteriores;
    procedure Sair;

  public
    boolAcessoOK                : boolean;
    strId_usuario,
    strChkSisInfFileName,
    strGerColsInfFileName       : String;

    procedure Finalizar(p_pausa:boolean);

  end;

var frmMapaCacic: TfrmMapaCacic;

implementation

{$R *.dfm}


procedure TfrmMapaCacic.Sair;
Begin
    EstadoBarraTarefa(TRUE);
    Application.Terminate;
End;

procedure TfrmMapaCacic.Finalizar(p_pausa:boolean);
Begin
  Visible                               := false;

  Application.ProcessMessages;

  Sair;
End;

procedure TfrmMapaCacic.rdConcordaTermosClick(Sender: TObject);
begin
  btGravarInformacoes.Enabled:= true;
end;

//------------------------------------------------------------------------------
//------------------FUN��O PARA RETORNAR O NOME DO COMPUTADOR.------------------
//------------------------------------------------------------------------------

Function TfrmMapaCacic.NomeComputador : String;
var
  lpBuffer : PChar;
  nSize : DWord;
const Buff_Size = MAX_COMPUTERNAME_LENGTH + 1;
begin
  nSize := Buff_Size;
  lpBuffer := StrAlloc(Buff_Size);
  GetComputerName(lpBuffer,nSize);
  Result := String(lpBuffer);
  StrDispose(lpBuffer);
end;

//------------------------------------------------------------------------------
//------------------FUN��O PARA RETORNAR O NOME DO USUARIO.---------------------
//------------------------------------------------------------------------------

Function TfrmMapaCacic.getUserLogon : String;
var
  lpBuffer : PChar;
  nSize : DWord;
const Buff_Size = MAX_COMPUTERNAME_LENGTH + 1;
begin
  nSize := Buff_Size;
  lpBuffer := StrAlloc(Buff_Size);
  GetUserName(lpBuffer,nSize);
  Result := String(lpBuffer);
  StrDispose(lpBuffer);
end;

//------------------------------------------------------------------------------
//----------------------FUN��O PARA RETORNAR O PATRIMONIO-----------------------
//------------------------------------------------------------------------------

function TfrmMapaCacic.SetPatrimonioPC : String;
var
  strPatrimonioPc,
  strNomePC        : String;
begin
  Result:='';
  strNomePC:=NomeComputador;

  if (pos('-',strNomePC) > 0) then
    strPatrimonioPc:=copy(strNomePC, 0, (pos('-', strNomePC)-1));
  Result:=strPatrimonioPC;
end;

//------------------------------------------------------------------------------
//--------------------FUN��O PARA FORMATAR O CPF--------------------------------
//------------------------------------------------------------------------------

function TfrmMapaCacic.FormatarCpf(strCpfUser : String) : String;
var
  strCpfFormatado : String;
begin
  Result:='';
  strCpfFormatado:= Copy(strCpfUser, 1,3)

            + '.' + Copy(strCpfUser, 4,3)

            + '.' + Copy(strCpfUser, 7,3)

            + '-' + Copy(strCpfUser, 10,2);
  Result:=strCpfFormatado;

end;
//------------------------------------------------------------------------------
//--------------------FUN��O PARA RETORNAR O CPF DO USUARIO---------------------
//------------------------------------------------------------------------------

function TfrmMapaCacic.SetCpfUser : String;
var
  strCpfUser,
  strUser        : String;
begin
  Result:='';
  strUser:=getUserLogon;

  if (pos('-',strUser) > 0) then
    strCpfUser:=copy(strUser, 0, (pos('-', strUser)-1));

  Result:=strCpfUser;
end;

//------------------------------------------------------------------------------
//--------------------FUN��O PARA RETORNAR O ULTIMO VALOR-----------------------
//-----------------------AP�S O SEPARADOR SELECIONADO---------------------------
//------------------------------------------------------------------------------

function TfrmMapaCacic.getLastValue(S : String; separador : string): string; 
  var
  conta : integer;         // vari�veis auxiliares
  resultado : TStringList; // vari�veis auxiliares
  Saux : string;           // vari�veis auxiliares
begin
    resultado := TStringList.Create;   // inicializa variavel
    conta := pos(separador,S);         // pega posi��o do separador
    if conta <> 0 then begin           // verifica se existe o separador caso contrario trata apenas //como uma �nica linha
        while trim(S) <> '' do begin   // enquanto S n�o for nulo executa
            Saux := copy(S,1,conta-1); // Vari�vel Saux recebe primeiro valor
            delete(S,1,conta);         // deleta primeiro valor
            if conta = 0 then begin    // se n�o ouver mais separador Saux equivale ao resto da //linha
                Saux := S;
                S := '';
            end;
        resultado.Add(Saux);           // adiciona linhas na string lista
        conta := pos(separador,S);     //pega posi��o do separador
        end;
        end
    else begin
        Saux := S;
        resultado.Add(Saux);
    end;
    Result := trim(resultado[resultado.count-1]); // retorna resultado como uma lista indexada
end;

//------------------------------------------------------------------------------
//--------------------FUN��O PARA PEGAR CONFIGURA��ES NO GERENTE----------------
//------------------------------------------------------------------------------

function TfrmMapaCacic.getConfigs : String;

Begin
  btCombosUpdate.Enabled := false;

  Result := Comm(objCacic.getWebManagerAddress + objCacic.getWebServicesFolderName + 'get/config', strFieldsAndValuesToRequest, objCacic.getLocalFolderName);

  objCacic.setBoolCipher(not objCacic.isInDebugMode);

  objCacic.writeDebugLog('FormActivate: Retorno de getConfigs: "'+Result+'"');

  if (Result <> '0') then
    Begin
      objCacic.setValueToFile('Configs' ,'Patrimonio_dados_ldap', objCacic.getValueFromTags('dados_ldap'                  , Result), strGerColsInfFileName);
      objCacic.setValueToFile('Configs' ,'Patrimonio_Combos'    , objCacic.getValueFromTags('Configs_Patrimonio_Combos'   , Result), strGerColsInfFileName);
      objCacic.setValueToFile('Configs' ,'Patrimonio_Interface' , objCacic.getValueFromTags('Configs_Patrimonio_Interface', Result), strGerColsInfFileName);
//      objCacic.setValueToFile('Collects','col_patr_last'        , objCacic.getValueFromTags('Collects_Patrimonio_Last'    , Result), strGerColsInfFileName);
    End
  else
    begin
      MessageDlg(#13#13+'N�o foi poss�vel realizar a conex�o!',mtError, [mbOK], 0);
    end;
  btCombosUpdate.Enabled := true;
End;

//------------------------------------------------------------------------------
//--------------------PROCEDIMENTO UTILIZADO PARA PEGAR AS ULTIMAS--------------
//----------------------INFORMA��ES ENVIADAS PELO MAPACACIC---------------------

procedure TfrmMapaCacic.RecuperaValoresAnteriores;
var strCollectsPatrimonioLast : String;
begin
  btCombosUpdate.Enabled := false;

  strCollectsPatrimonioLast := objCacic.deCrypt( objCacic.GetValueFromFile
                                                ('Collects','col_patr_last',
                                                 strGerColsInfFileName));

  if (strCollectsPatrimonioLast <> '') then
    Begin

      if (strTeInfoPatrimonio1='') then
        strTeInfoPatrimonio1 := objCacic.getValueFromTags('IDPatrimonio', objCacic.getValueFromTags('Patrimonio',
                                                          strCollectsPatrimonioLast));
      if (strTeInfoPatrimonio2='') then
        strTeInfoPatrimonio2 := objCacic.getValueFromTags('UserLogado',
                                                          strCollectsPatrimonioLast);
      if (strTeInfoPatrimonio3='') then
        strTeInfoPatrimonio3 := objCacic.getValueFromTags('UserNameLDAP',
                                                          strCollectsPatrimonioLast);
      if (strTeInfoPatrimonio4='') then
        strTeInfoPatrimonio4 := objCacic.getValueFromTags('IPComputer',
                                                          strCollectsPatrimonioLast);
      if (strTeInfoPatrimonio5='') then
        strTeInfoPatrimonio5 := objCacic.getValueFromTags('ComputerName',
                                                          strCollectsPatrimonioLast);
      if (strTeInfoPatrimonio6='') then
        strTeInfoPatrimonio6 := objCacic.getValueFromTags('PatrimonioMonitor1',
                                                          strCollectsPatrimonioLast);
      if (strTeInfoPatrimonio7='') then
        strTeInfoPatrimonio7 := objCacic.getValueFromTags('PatrimonioMonitor2',
                                                          strCollectsPatrimonioLast);
    End;
  btCombosUpdate.Enabled := true;
  Application.ProcessMessages;
end;

procedure TfrmMapaCacic.AtualizaPatrimonio(Sender: TObject);
var strColetaAtual,
    strRetorno: String;
begin
if edTeInfoNome.text <> '' then
  begin
    btGravarInformacoes.Enabled := false;
    btGravarInformacoes.Caption := 'Enviando informa��es...';
    strFieldsAndValuesToRequest := 'CollectType=' + objCacic.replaceInvalidHTTPChars(objCacic.enCrypt('col_patr')) ;

    strColetaAtual := StringReplace('[Patrimonio]'                                                                  +
                                    '[IDPatrimonio]'         + edTePatrimonioPc.Text      + '[/IDPatrimonio]'       +
                                    '[UserLogado]'           + edTeInfoUserLogado.Text    + '[/UserLogado]'         +
                                    '[UserNameLDAP]'         + edTeInfoNome.Text          + '[/UserNameLDAP]'       +
                                    '[IPComputer]'           + edTeInfoIpComputador.Text  + '[/IPComputer]'         +
                                    '[ComputerName]'         + edTeInfoNomeComputador.Text+ '[/ComputerName]'       +
                                    '[PatrimonioMonitor1]'   + edTeInfoPatrimonio5.Text   + '[/PatrimonioMonitor1]' +
                                    '[PatrimonioMonitor2]'   + edTeInfoPatrimonio6.Text   + '[/PatrimonioMonitor2]' +
                                    '[/Patrimonio]', ',','[[COMMA]]',[rfReplaceAll]);

    strFieldsAndValuesToRequest := strFieldsAndValuesToRequest + ',col_patr='  +
                                   objCacic.replaceInvalidHTTPChars(objCacic.enCrypt(strColetaAtual));

    strRetorno := Comm(objCacic.getWebManagerAddress + objCacic.getWebServicesFolderName +
                        'gercols/set/collects', strFieldsAndValuesToRequest, objCacic.getLocalFolderName);

    objCacic.setBoolCipher(not objCacic.isInDebugMode);

    if (strRetorno = '0') then
    begin
       btGravarInformacoes.caption := 'Problema ao enviar informa��es...';
       MessageDLG(#13#10+'Aten��o!'+ #13#10 + 'Problema ao enviar as informa��es!'
               + #13#10 + 'Se o problema persistir contate o adminsitrador.',mtError,[mbOK],0);
    end
    else
    Begin
        btGravarInformacoes.Caption := 'Informa��es enviadas com sucesso...';
        objCacic.setValueToFile('Collects','col_patr_last' ,
                                objCacic.enCrypt(strColetaAtual), strGerColsInfFileName);
        objCacic.setValueToFile('Collects','col_patr_exe', 's', strGerColsInfFileName);

    End;
    objCacic.writeDebugLog(#13#10 + 'AtualizaPatrimonio: Dados Enviados ao Servidor!');
    Application.ProcessMessages;

    Finalizar(true);
  end
  else
    MessageDLG(#13#10+'Aten��o!'+ #13#10 + '� necess�rio digitar seu nome.'
               + #13#10,mtError,[mbOK],0);
end;


procedure TfrmMapaCacic.MontaInterface;
var strConfigsPatrimonioInterface, strNomeLDAP : String;
Begin
   btCombosUpdate.Enabled := false;

//-------------------------------NOME USUARIO-----------------------------------
   strNomeLDAP                         := LDAPName;

   if (strNomeLDAP <> '') and (strNomeLDAP <> 'Results: 0') then
   begin
      edTeInfoNome.Text                      := strNomeLDAP;
      edTeInfoNome.Visible                   := true;
      lbEtiquetaNome.Visible                 := true;
   end
   else
   begin
      edTeInfoNome.Visible                   := true;
      edTeInfoNome.Enabled                   := true;
      lbEtiquetaNome.Visible                 := true;
   end;

//-----------------------NOME DO COMPUTADOR PARA O EDTEXT-----------------------
   edTeInfoNomeComputador.Text               := NomeComputador;
   if edTeInfoNomeComputador.Text <> '' then
   begin
      lbEtiquetaNomeComputador.Visible       := true;
      edTeInfoNomeComputador.Visible         := true;
   end;
   lbEtiquetaNomeComputador.Visible          := true;
   edTeInfonomeComputador.Visible            := true;

//-----------------------------USUARIO LOGADO-----------------------------------

   edTeInfoUserLogado.Text                   := getUserLogon;
   if edTeInfoUserLogado.Text <> '' then
   begin
      lbEtiquetaUserLogado.Visible           := true;
      edTeInfoUserLogado.Visible             := true;
   end;

//-------------------------------CPF USUARIO------------------------------------

{   edTeInfoCpfUser.Text                      := FormatarCpf(SetCpfUser);
   if edTeInfoCpfUser.Text <> '' then
   begin
      lbEtiquetaCpfUser.Visible              := true;
      edTeInfoCpfUser.Visible                := true;
   end;}

//-----------------------PUXA O IP DA M�QUINA PARA O EDTEXT-------------------------------------
   edTeInfoIpComputador.Text                 := idipwatch1.LocalIP;
   if edTeInfoIpComputador.Text <> '' then
   begin
      lbEtiquetaIpComputador.Visible         := true;
      edTeInfoIpComputador.Visible           := true;
   end;

//-------------------------PATRIMONIO DA MAQUINA--------------------------------
{   edTePatrimonioPc.Text                     := SetPatrimonioPc;
   if edTePatrimonioPc.Text <> '' then
   Begin
      lbEtiquetaPatrimonioPc.Visible         := true;
      edTePatrimonioPc.Visible               := true;
   end;}
   edTePatrimonioPc.Text                     := strTeInfoPatrimonio1;
   edTePatrimonioPc.Visible                  := true;
   lbEtiquetaPatrimonioPc.Visible            := true;


   //----------VALOR DE strGerColsInfFileName ALTERADO PARA ARQUIVO TESTE-----------------------------
   strConfigsPatrimonioInterface := objCacic.deCrypt(objCacic.getValueFromFile('Configs','Patrimonio_Interface',strGerColsInfFileName));

  { objCacic.writeDebugLog('MontaInterface: in_exibir_etiqueobjCacic.enCta1 -> "'     +
                          objCacic.getValueFromTags('in_exibir_etiqueta1',
                                                    strConfigsPatrimonioInterface)+'"');

   if (trim(objCacic.getValueFromTags('in_exibir_etiqueta1', strConfigsPatrimonioInterface)) = 'S') then
   begin
      lbEtiqueta1.Caption         := objCacic.getValueFromTags('te_etiqueta1', strConfigsPatrimonioInterface);
      lbEtiqueta1.Visible         := true;
      edTeInfoPatrimonio1.Hint    := objCacic.getValueFromTags('te_help_etiqueta1', strConfigsPatrimonioInterface);
      edTeInfoPatrimonio1.Text    := strTeInfoPatrimonio1;
      edTeInfoPatrimonio1.visible := True;
   end;

   objCacic.writeDebugLog('MontaInterface: in_exibir_etiqueta2 -> "'     +
                          objCacic.getValueFromTags('in_exibir_etiqueta2',
                                                   strConfigsPatrimonioInterface)+'"');

   if (trim(objCacic.getValueFromTags('in_exibir_etiqueta2', strConfigsPatrimonioInterface)) = 'S') then
   begin
      lbEtiqueta2.Caption         := objCacic.getValueFromTags('te_etiqueta2', strConfigsPatrimonioInterface);
      lbEtiqueta2.Visible         := true;
      edTeInfoPatrimonio2.Hint    := objCacic.getValueFromTags('te_help_etiqueta2', strConfigsPatrimonioInterface);
      edTeInfoPatrimonio2.Text    := strTeInfoPatrimonio2;
      edTeInfoPatrimonio2.visible := True;
   end;

   objCacic.writeDebugLog('MontaInterface: in_exibir_etiqueta3 -> "'     +
                          objCacic.getValueFromTags('in_exibir_etiqueta3',
                                                     strConfigsPatrimonioInterface)+'"');

   if (trim(objCacic.getValueFromTags('in_exibir_etiqueta3', strConfigsPatrimonioInterface)) = 'S') then
   begin
      lbEtiqueta3.Caption         := objCacic.getValueFromTags('te_etiqueta3', strConfigsPatrimonioInterface);
      lbEtiqueta3.Visible         := true;
      edTeInfoPatrimonio3.Hint    := objCacic.getValueFromTags('te_help_etiqueta3', strConfigsPatrimonioInterface);
      edTeInfoPatrimonio3.Text    := strTeInfoPatrimonio3;
      edTeInfoPatrimonio3.visible := True;
   end;

   objCacic.writeDebugLog('MontaInterface: in_exibir_etiqueta4 -> "'     +
                          objCacic.getValueFromTags('in_exibir_etiqueta4',
                                                    strConfigsPatrimonioInterface)+'"');

   if (trim(objCacic.getValueFromTags('in_exibir_etiqueta4', strConfigsPatrimonioInterface)) = 'S') then
   begin
      lbEtiqueta4.Caption         := objCacic.getValueFromTags('te_etiqueta4', strConfigsPatrimonioInterface);
      lbEtiqueta4.Visible         := true;
      edTeInfoPatrimonio4.Hint    := objCacic.getValueFromTags('te_help_etiqueta4', strConfigsPatrimonioInterface);
      edTeInfoPatrimonio4.Text    := strTeInfoPatrimonio4;
      edTeInfoPatrimonio4.visible := True;
   end;  }

//   objCacic.writeDebugLog('MontaInterface: in_exibir_etiqueta5 -> "'     +
//                          objCacic.getValueFromTags('in_exibir_etiqueta5',
//                                                   strConfigsPatrimonioInterface)+'"');

//   if (trim(objCacic.getValueFromTags('in_exibir_etiqueta5', strConfigsPatrimonioInterface)) = 'S') then
//   begin
      //lbEtiqueta5.Caption         := objCacic.getValueFromTags('te_etiqueta5', strConfigsPatrimonioInterface);
      lbEtiqueta5.Visible         := true;
      edTeInfoPatrimonio5.Hint    := objCacic.getValueFromTags('te_help_etiqueta5', strConfigsPatrimonioInterface);
      edTeInfoPatrimonio5.Text    := strTeInfoPatrimonio6;
      edTeInfoPatrimonio5.visible := True;
//   end;

//   objCacic.writeDebugLog('MontaInterface: in_exibir_etiqueta6 -> "'     +
//                          objCacic.getValueFromTags('in_exibir_etiqueta6',
//                                                    strConfigsPatrimonioInterface)+'"');

//   if (trim(objCacic.getValueFromTags('in_exibir_etiqueta6', strConfigsPatrimonioInterface)) = 'S') then
//   begin
      //lbEtiqueta6.Caption         := objCacic.getValueFromTags('te_etiqueta6', strConfigsPatrimonioInterface);
      lbEtiqueta6.Visible         := true;
      edTeInfoPatrimonio6.Hint    := objCacic.getValueFromTags('te_help_etiqueta6', strConfigsPatrimonioInterface);
      edTeInfoPatrimonio6.Text    := strTeInfoPatrimonio7;
      edTeInfoPatrimonio6.visible := True;
//   end;


   btGravarInformacoes.Visible := true;
   btCombosUpdate.Enabled      := true;

   Application.ProcessMessages;
end;

procedure TfrmMapaCacic.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  If Not fechar Then //se a variavel de fechamento fecha estiver falsa
    Action := caNone // nao realizar�  nenhuma opera��o
  Else
  begin
    Action := caFree;
    objCacic.writeDebugLog('FormClose: ' + Sender.ClassName);
    Finalizar(true);
  end;
end;


procedure TfrmMapaCacic.mapa;
begin
  Try
    MontaInterface;
    RecuperaValoresAnteriores;
  Except
    on E:Exception do
       Begin
         objCacic.writeExceptionLog(E.Message,e.ClassName);
       End;
  End;
End;

procedure TfrmMapaCacic.FormCreate(Sender: TObject);
var
  foco: boolean;

begin


  frmMapaCacic.boolAcessoOK := true;
//Definido TRUE, se n�o, mesmo que o foco seja falso, a aplica��o n�o � fechada quando quiser.
  Fechar:=TRUE;
  foco:=true; //DEFINIDO COMO TRUE PARA QUE A JANELA N�O SEJA FECHADA
  Try
    strFrmAtual  := 'Principal';
    objCacic     := TCACIC.Create();

    objCacic.setBoolCipher(true);
    objCacic.setLocalFolderName('Cacic');
    objCacic.setWebServicesFolderName('/ws');

    if IsUserAnAdmin then
    begin
      strChkSisInfFileName := objCacic.getWinDir + 'chksis.inf';

      if not (objCacic.GetValueFromFile('Configs','LocalFolderName',
                                         strChkSisInfFileName) = '') then

      Begin

        objCacic.setLocalFolderName(objCacic.GetValueFromFile
                                    ('Configs', 'LocalFolderName',
                                     strChkSisInfFileName));

        objCacic.setWebServicesFolderName(objCacic.GetValueFromFile
                                          ('Configs','WebServicesFolderName',
                                            strChkSisInfFileName));

        objCacic.setWebManagerAddress(objCacic.GetValueFromFile
                                      ('Configs','WebManagerAddress',
                                        strChkSisInfFileName));


        strGerColsInfFileName := objCacic.getLocalFolderName + 'GerCols.inf';

        // A exist�ncia e bloqueio do arquivo abaixo evitar� que o Agente Principal entre em a��o

        AssignFile(textFileAguarde,objCacic.getLocalFolderName +
                   '\temp\aguarde_MAPACACIC.txt'); //Associa o arquivo a uma vari�vel do tipo TextFile

        {$IOChecks off}

        reset(textFileAguarde);

        {$IOChecks on}
        if (IOResult <> 0) then // Arquivo n�o existe, ser� recriado.
            rewrite (textFileAguarde); //Abre o arquivo texto

        Append(textFileAguarde);
        Writeln(textFileAguarde,'Apenas um pseudo-cookie para o Agente Principal esperar o t�rmino de MapaCACIC');
        Append(textFileAguarde);

        frmMapaCacic.edWebManagerAddress.Caption := objCacic.GetValueFromFile('Configs','WebManagerAddress', strChkSisInfFileName);

        frmMapaCacic.lbMensagens.Caption  := 'Entrada de Dados para Autentica��o no M�dulo Gerente WEB Cacic';
        objCacic.writeDebugLog('FormActivate: Vers�o do MapaCacic...: '    +
                                pnVersao.Caption);
        ObjCacic.writeDebugLog('FormActivate: Hash-Code do MapaCacic: '    +
                                objCacic.getFileHash(ParamStr(0)));


        pnMessageBox.Visible := true;
  
        // Povoamento com dados de configura��es da interface patrimonial
        // Solicita ao servidor as configura��es para a Coleta de Informa��es de Patrim�nio
        pnMessageBox.Visible := false;
        objCacic.writeDebugLog('FormActivate: Requisitando informa��es de patrim�nio da esta��o...');

        if (getConfigs <> '0') then
        begin
           FormSetFocus(foco);
           mapa
        end
        else
           Sair;
        end
        else
        Begin
           frmMapaCacic.boolAcessoOK := false;
           MessageDLG(#13#10+'Aten��o! � necess�rio reinstalar o CACIC nesta esta��o.' + #13#10     + #13#10 +
                            'A escctrutura encontra-se corrompida.'   + #13#10,mtError,[mbOK],0);
           Application.ProcessMessages;
           frmMapaCacic.Finalizar(false);
        End;
    end
    else
    Begin // Se NT/2000/XP/...
      MessageDLG(#13#10+'ATEN��O! Essa aplica��o requer execu��o com n�vel administrativo.',mtError,[mbOK],0);
      objCacic.writeDailyLog('SEM PRIVIL�GIOS: Necess�rio ser administrador "local" ou de Dom�nio!');
      Sair
    End;
  Finally
  End;
end;

procedure TfrmMapaCacic.FormActivate(Sender: TObject);
begin
  pnVersao.Caption := 'Vers�o: ' + objCacic.getVersionInfo(ParamStr(0));
  strFrmAtual := 'Principal';
end;

procedure TfrmMapaCacic.btCombosUpdateClick(Sender: TObject);
begin

  getConfigs;
  RecuperaValoresAnteriores;
  MontaInterface;

end;

//------------------------------------------------------------------------------
//PROCEDURE CRIADO PARA DEIXAR O FORM FULLSCREEN E FOCADO, SEM QUE SEJA POSS�VEL
//FECHAR OU ALTERNAR ENTRE OUTRAS JANELAS AT� QUE ATUALIZE O PATRIMONIO.
procedure TfrmMapaCacic.FormSetFocus(VerificaFoco: Boolean);
var
  r : TRect;
begin
  if VerificaFoco then
  begin
    Fechar                    := False;
    BorderIcons               := BorderIcons - [biSystemMenu] - [biMinimize] - [biMaximize];
    BorderStyle               := bsNone;
    FormStyle                 := fsStayOnTop;
    timerProcessos.Enabled    := True;
    SystemParametersInfo(SPI_GETWORKAREA, 0, @r,0);
    SetBounds(r.Left, r.Top, r.Right-r.Left, r.Bottom-r.Top);
    Top := 0;
    Left := 0;
    Width := Screen.Width;
    Height := Screen.Height;
    EstadoBarraTarefa(FALSE);
  end;

end;

//------------------------------------------------------------------------------
//----------------ESCONDE BARRA DE TAREFAS--------------------------------------
//------------------------------------------------------------------------------

procedure TfrmMapaCacic.EstadoBarraTarefa(EstadoBarra: Boolean);

var wndHandle : THandle;
    wndClass  : array[0..50] of Char;

begin

  StrPCopy(@wndClass[0],'Shell_TrayWnd');
  wndHandle := FindWindow(@wndClass[0], nil);

  If EstadoBarra=True Then
    ShowWindow(wndHandle, SW_RESTORE) {Mostra a barra de tarefas}

  Else
    ShowWindow(wndHandle, SW_HIDE); {Esconde a barra de tarefas}

end;

//------------------------------------------------------------------------------
//-----------------BEGIN-----RETIRA PROCESSO DO GERENCIADOR---------------------
//------------------------------------------------------------------------------

procedure TfrmMapaCacic.timerProcessosTimer(Sender: TObject);
var
  dwSize,dwNumBytes,PID,hProc: Cardinal;
  PLocalShared,PSysShared: PlvItem;
  h: THandle;
  iCount,i: integer;
  szTemp: string;
begin
  //Pega o Handle da ListView
  h:=FindWindow('#32770',nil);
  h:=FindWindowEx(h,0,'#32770',nil);
  h:=FindWindowEx(h,0,'SysListView32',nil);

  //Pega o n�mero de itens da ListView
  iCount:=SendMessage(h, LVM_GETITEMCOUNT,0,0);
  for i:=0 to iCount-1 do
    begin
    //Define o tamanho de cada item da ListView
    dwSize:=sizeof(LV_ITEM) + sizeof(CHAR) * MAX_PATH;

    //Abre um espa�o na mem�ria do NOSSO programa para o PLocalShared
    PLocalShared:=VirtualAlloc(nil, dwSize, MEM_RESERVE + MEM_COMMIT, PAGE_READWRITE);

    //Pega o PID do processo taskmgr
    GetWindowThreadProcessId(h,@PID);

    //Abre o processo taskmgr
    hProc:=OpenProcess(PROCESS_ALL_ACCESS,false,PID);

    //Abre um espa�o na mem�ria do taskmgr para o PSysShared
    PSysShared:=VirtualAllocEx(hProc, nil, dwSize, MEM_RESERVE OR MEM_COMMIT, PAGE_READWRITE);

    //Define as propriedades do PLocalShared
    PLocalShared.mask:=LVIF_TEXT;
    PLocalShared.iItem:=0;
    PLocalShared.iSubItem:=0;
    PLocalShared.pszText:=LPTSTR(dword(PSysShared) + sizeof(LV_ITEM));
    PLocalShared.cchTextMax:=20;

    //Escreve PLocalShared no espa�o de mem�ria que abriu no taskmgr
    WriteProcessMemory(hProc,PSysShared,PLocalShared,1024,dwNumBytes);

    //Pega o texto to item i e passa pro PSysShared
    SendMessage(h,LVM_GETITEMTEXT,i,LPARAM(PSysShared));

    //Passa o PSysShared para o PLocalShared
    ReadProcessMemory(hProc,PSysShared,PLocalShared,1024,dwNumBytes);

    //Passa o texto do Item para szTemp
    szTemp:=pchar(dword(PLocalShared)+sizeof(LV_ITEM));

    //Se esse texto contiver a string proc deleta o item
    if LowerCase(szTemp) = 'mapacacic.exe' then
      ListView_DeleteItem(h,i);

    //Libera os espa�os de mem�ria utilizados
    VirtualFree(pLocalShared, 0, MEM_RELEASE);
    VirtualFreeEx(hProc, pSysShared, 0, MEM_RELEASE);

    //Fecha o handle do processo
    CloseHandle(hProc);
  end;
end;



function TfrmMapaCacic.LDAPName: string;
var
  ldap: TLDAPsend;
  l: TStringList;
  host, username, psswd, base, strDadosLDAP, identificador : string;
begin
  result       := '';
  ldap         := TLDAPsend.Create;
  l            := TStringList.Create;
//  PEGANDO OS DADOS DO POR MEIO DO GET/CONFIGS, ONDE SER� GRAVADO NO GERCOLS.INF
  strDadosLDAP := objCacic.deCrypt(objCacic.getValueFromFile('Configs','Patrimonio_dados_ldap',strGerColsInfFileName));
  host         := objCacic.getValueFromTags('ip', strDadosLDAP);
  username     := objCacic.getValueFromTags('usuario', strDadosLDAP);
  psswd        := objCacic.getValueFromTags('senha', strDadosLDAP);
  base         := objCacic.getValueFromTags('base', strDadosLDAP);
  identificador:= objCacic.getValueFromTags('identificador', strDadosLDAP);
  try
    ldap.TargetHost := host;
    ldap.UserName   := username;
    ldap.Password   := psswd;
    ldap.Login;    //Loga no LDAP.
    ldap.BindSasl; //Autentica no LDAP com Usu�rio e senha repassado. (BindSasl � mais seguro que Bind)
    l.Add(identificador);   //Estamos pesquisando apenas o nome, ent�o apenas 'cn' ser� enviado.
    ldap.Search(base, False, 'uid=' + getUserLogon, l); //Faz a pesquisa, com o CPF repassado.
    result := getLastValue(LDAPResultdump(ldap.SearchResult), #$D#$A);
    ldap.Logout;
  finally
    ldap.Free;
    l.Free;
  end;
end;




end.
