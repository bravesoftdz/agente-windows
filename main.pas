﻿(**
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

unit main;

interface

uses
  Windows,
  Messages,
  Forms,
  Menus,
  Classes,
  SysUtils,
  Controls,
  StdCtrls,
  ExtCtrls,
  ShellAPI,
  registry,
  dialogs,
  ComCtrls,
  IdBaseComponent,
  IdComponent,
  Buttons,
  CACIC_Library,
  CACIC_WMI,
  ImgList,
  Graphics,
  USBdetectClass,
  WinSVC,
  SHChangeNotify, TrayIcon, AppEvnts;

  //IdTCPServer;
  //IdFTPServer;

const
  KBYTE          = Sizeof(Byte) shl 10;
  MBYTE          = KBYTE shl 10;
  GBYTE          = MBYTE shl 10;
  NORMAL         = 0; // Normal
  COLETANDO      = 1; // Raio - Coletando
  DESCONFIGURADO = 2; // Interroga��o - Identificando Host
  EM_SUPORTE     = 3; // Telefone - Em Suporte Remoto
  LEFT_MENU_ITEM = 13; // Coordenada X para escrita das op��es do menu de contexto



// Declara��o das vari�veis globais.
var strConfigsPatrimonio,
    strMenuCaptionLAT,
    strMenuCaptionCON,
    strMenuCaptionEXE,
    strMenuCaptionINF,
    strMenuCaptionSUP,
    strMenuCaptionFIN : string;
    g_intTaskBarAtual,
    g_intTaskBarAnterior,
    g_intDesktopWindow,
    g_intStatus,
    g_intStatusAnterior,
    g_intIconIndex       : integer;
    bl_primeira_execucao : bool = false;
    objCACIC: TCACIC;

type
  TFormularioGeral = class(TForm)
    Pn_InfosGerais: TPanel;
    Pn_SisMoni: TPanel;
    Lb_SisMoni: TLabel;
    Pn_TCPIP: TPanel;
    Lb_TCPIP: TLabel;
    GB_InfosTCPIP: TGroupBox;
    ST_VL_MacAddress: TStaticText;
    ST_LB_MacAddress: TStaticText;
    ST_LB_NomeHost: TStaticText;
    ST_VL_NomeHost: TStaticText;
    ST_LB_IpEstacao: TStaticText;
    ST_LB_IpRede: TStaticText;
    ST_LB_DominioDNS: TStaticText;
    ST_LB_DnsPrimario: TStaticText;
    ST_LB_DnsSecundario: TStaticText;
    ST_LB_Gateway: TStaticText;
    ST_LB_Mascara: TStaticText;
    ST_LB_ServidorDHCP: TStaticText;
    ST_LB_WinsPrimario: TStaticText;
    ST_LB_WinsSecundario: TStaticText;
    ST_VL_IpEstacao: TStaticText;
    ST_VL_DNSPrimario: TStaticText;
    ST_VL_DNSSecundario: TStaticText;
    ST_VL_Gateway: TStaticText;
    ST_VL_Mascara: TStaticText;
    ST_VL_ServidorDHCP: TStaticText;
    ST_VL_WinsPrimario: TStaticText;
    ST_VL_WinsSecundario: TStaticText;
    ST_VL_DominioDNS: TStaticText;
    ST_VL_IpRede: TStaticText;
    Pn_Linha1_TCPIP: TPanel;
    Pn_Linha2_TCPIP: TPanel;
    Pn_Linha3_TCPIP: TPanel;
    Pn_Linha4_TCPIP: TPanel;
    Pn_Linha6_TCPIP: TPanel;
    Pn_Linha5_TCPIP: TPanel;
    timerNuExecApos: TTimer;
    Popup_Menu_Contexto: TPopupMenu;
    Mnu_LogAtividades: TMenuItem;
    Mnu_Configuracoes: TMenuItem;
    Mnu_ExecutarAgora: TMenuItem;
    Mnu_InformacoesGerais: TMenuItem;
    Mnu_FinalizarCacic: TMenuItem;
    listSistemasMonitorados: TListView;
    pnColetasRealizadasNestaData: TPanel;
    lbColetasRealizadasNestaData: TLabel;
    listaColetas: TListView;
    teDataColeta: TLabel;
    pnInformacoesPatrimoniais: TPanel;
    lbInformacoesPatrimoniais: TLabel;
    gpInfosPatrimoniais: TGroupBox;
    st_lb_Etiqueta5: TStaticText;
    st_lb_Etiqueta1: TStaticText;
    st_vl_Etiqueta1: TStaticText;
    st_lb_Etiqueta1a: TStaticText;
    st_lb_Etiqueta2: TStaticText;
    st_lb_Etiqueta7: TStaticText;
    st_lb_Etiqueta6: TStaticText;
    st_lb_Etiqueta8: TStaticText;
    st_vl_Etiqueta1a: TStaticText;
    st_vl_Etiqueta2: TStaticText;
    Panel6: TPanel;
    Panel7: TPanel;
    Panel8: TPanel;
    Panel9: TPanel;
    Panel11: TPanel;
    st_lb_Etiqueta4: TStaticText;
    st_lb_Etiqueta3: TStaticText;
    st_vl_Etiqueta3: TStaticText;
    st_lb_Etiqueta9: TStaticText;
    st_vl_etiqueta4: TStaticText;
    st_vl_etiqueta5: TStaticText;
    st_vl_etiqueta6: TStaticText;
    st_vl_etiqueta7: TStaticText;
    st_vl_etiqueta8: TStaticText;
    st_vl_etiqueta9: TStaticText;
    Mnu_SuporteRemoto: TMenuItem;
    lbSemInformacoesPatrimoniais: TLabel;
    pnServidores: TPanel;
    lbServidores: TLabel;
    GroupBox1: TGroupBox;
    staticVlServidorUpdates: TStaticText;
    staticNmServidorUpdates: TStaticText;
    staticNmServidorAplicacao: TStaticText;
    staticVlServidorAplicacao: TStaticText;
    Panel4: TPanel;
    Panel3: TPanel;
    pnVersao: TPanel;
    bt_Fechar_Infos_Gerais: TBitBtn;
    ST_LB_DominioWindows: TStaticText;
    ST_VL_DominioWindows: TStaticText;
    cn: TSHChangeNotify;
    imgIconList: TImageList;
    timerCheckNoMinuto: TTimer;
    timerNuIntervalo: TTimer;
    TrayIcon1: TTrayIcon;
    ApplicationEvents1: TApplicationEvents;
    Panel1: TPanel;
    ExecutarMapa1: TMenuItem;
    CheckForcaColeta: TTimer;
    procedure RemoveIconesMortos;
    procedure ChecaCONFIGS;
    procedure CriaFormSenha(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Sair(Sender: TObject);
    procedure MinimizaParaTrayArea(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure ExecutaCACIC(Sender: TObject);
    procedure SetaVariaveisGlobais;
    procedure ExibirLogAtividades(Sender: TObject);
    procedure ExibirConfiguracoes(Sender: TObject);
    procedure HabilitaInformacoesGerais;
    procedure HabilitaSuporteRemoto;
    procedure Mnu_InformacoesGeraisClick(Sender: TObject);
    procedure Bt_Fechar_InfosGeraisClick(Sender: TObject);

    function  ChecaGERCOLS : boolean;
    function  ChecaMAPACACIC : boolean;
    function  FindWindowByTitle(WindowTitle: string): Hwnd;
    function  ActualActivity  : integer;
    function  Posso_Rodar     : boolean;
{
    procedure IdHTTPServerCACICCommandGet(AThread: TIdPeerThread;
      ARequestInfo: TIdHTTPRequestInfo;
      AResponseInfo: TIdHTTPResponseInfo);

    procedure IdFTPServer1UserLogin(ASender: TIdFTPServerThread;
      const AUsername, APassword: String; var AAuthenticated: Boolean);
}
    procedure Mnu_SuporteRemotoClick(Sender: TObject);
    procedure Popup_Menu_ContextoPopup(Sender: TObject);

    procedure CNAssocChanged(Sender: TObject; Flags: Cardinal; Path1,
      Path2: String);
    procedure CNAttributes(Sender: TObject; Flags: Cardinal;
      Path1: String);
    procedure CNCreate(Sender: TObject; Flags: Cardinal; Path1: String);
    procedure CNDelete(Sender: TObject; Flags: Cardinal; Path1: String);
    procedure CNDriveAdd(Sender: TObject; Flags: Cardinal; Path1: String);
    procedure CNDriveAddGUI(Sender: TObject; Flags: Cardinal;
      Path1: String);
    procedure CNDriveRemoved(Sender: TObject; Flags: Cardinal;
      Path1: String);
    procedure CNEndSessionQuery(Sender: TObject;
      var CanEndSession: Boolean);
    procedure CNMediaInserted(Sender: TObject; Flags: Cardinal;
      Path1: String);
    procedure CNMediaRemoved(Sender: TObject; Flags: Cardinal;
      Path1: String);
    procedure CNMkDir(Sender: TObject; Flags: Cardinal; Path1: String);
    procedure CNNetShare(Sender: TObject; Flags: Cardinal; Path1: String);
    procedure CNNetUnshare(Sender: TObject; Flags: Cardinal;
      Path1: String);
    procedure CNRenameFolder(Sender: TObject; Flags: Cardinal; Path1,
      Path2: String);
    procedure CNRenameItem(Sender: TObject; Flags: Cardinal; Path1,
      Path2: String);
    procedure CNRmDir(Sender: TObject; Flags: Cardinal; Path1: String);
    procedure CNServerDisconnect(Sender: TObject; Flags: Cardinal;
      Path1: String);
    procedure CNUpdateDir(Sender: TObject; Flags: Cardinal; Path1: String);
    procedure CNUpdateImage(Sender: TObject; Flags: Cardinal;
      Path1: String);
    procedure CNUpdateItem(Sender: TObject; Flags: Cardinal;
      Path1: String);
    procedure timerCheckNoMinutoTimer(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Mnu_LogAtividadesDrawItem(Sender: TObject; ACanvas: TCanvas;
      ARect: TRect; Selected: Boolean);
    procedure Mnu_ConfiguracoesDrawItem(Sender: TObject; ACanvas: TCanvas;
      ARect: TRect; Selected: Boolean);
    procedure Mnu_ExecutarAgoraDrawItem(Sender: TObject; ACanvas: TCanvas;
      ARect: TRect; Selected: Boolean);
    procedure Mnu_InformacoesGeraisDrawItem(Sender: TObject;
      ACanvas: TCanvas; ARect: TRect; Selected: Boolean);
    procedure Mnu_SuporteRemotoDrawItem(Sender: TObject; ACanvas: TCanvas;
      ARect: TRect; Selected: Boolean);
    procedure Mnu_FinalizarCacicDrawItem(Sender: TObject; ACanvas: TCanvas;
      ARect: TRect; Selected: Boolean);
    procedure timerNuExecAposTimer(Sender: TObject);
    procedure timerNuIntervaloTimer(Sender: TObject);
    procedure ApplicationEvents1Message(var Msg: tagMSG;
      var Handled: Boolean);
    procedure InvocaMapa1Click(Sender: TObject);
    procedure ExecutarMapa1DrawItem(Sender: TObject; ACanvas: TCanvas;
      ARect: TRect; Selected: Boolean);
    procedure CheckForcaColetaTimer(Sender: TObject);
  private
    FUsb : TUsbClass;
    ShutdownEmExecucao : Boolean;
    tstrListRCActions : TStringList;
    IsMenuOpen : Boolean;
    procedure CheckRCActions(pStrRCAction : String = '');
    procedure UsbIN(ASender : TObject; const ADevType,AVendorID,ADeviceID : string);
    procedure UsbOUT(ASender : TObject; const ADevType,AVendorID,ADeviceID : string);
    procedure InicializaTray;
    procedure Finaliza(boolNormal : boolean = true);
//    procedure MontaVetoresPatrimonio(p_strConfigs : String);
    procedure Invoca_GerCols(p_acao:string; boolShowInfo : Boolean = true; boolCheckExecution : Boolean = false);
    procedure Invoca_MapaCacic;
    procedure CheckIfDownloadedVersion;
    procedure WMSysCommand(var Msg: TWMSysCommand); message WM_SYSCOMMAND;
    // A procedure WMQueryEndSession � usada para detectar o
    // Shutdown do Windows e "derrubar" o Cacic.
    procedure WMQueryEndSession(var Msg : TWMQueryEndSession); Message WM_QUERYENDSESSION;
    procedure WMMENUSELECT(var msg: TWMMENUSELECT); message WM_MENUSELECT;
    function  getDesktopWindowHandle : integer;
    function  RetornaValorVetorUON1(id1 : string) : String;
    function  RetornaValorVetorUON1a(id1a : string) : String;
    function  RetornaValorVetorUON2(id2, idLocal: string) : String;
    function  ServiceStart(sMachine,sService : string ) : boolean;
  protected
  public
    strMainProgramInfFileName,
    strChkSisInfFileName,
    strGerColsInfFileName : String;
    function  URLDecode(const S: string): string;
    procedure DrawBar(ACanvas: TCanvas); // TrayIcon - Peterles
  end;

var FormularioGeral                      : TFormularioGeral;
    boolServerON                         : Boolean;
    strWin32_ComputerSystem,
    strWin32_NetworkAdapterConfiguration : String;
    rmTaskbarCreated                     : DWord;

implementation


{$R *.dfm}

Uses  StrUtils,
      Inifiles,
      frmConfiguracoes,
      frmSenha,
      frmLog,
      Math;

// Estruturas de dados para armazenar os itens da uon1, uon1a e uon2
type
  TRegistroUON1 = record
    id1 : String;
    nm1 : String;
  end;
  TVetorUON1 = array of TRegistroUON1;

  TRegistroUON1a = record
    id1     : String;
    id1a    : String;
    nm1a    : String;
    id_local: String;
  end;

  TVetorUON1a = array of TRegistroUON1a;

  TRegistroUON2 = record
    id1a    : String;
    id2     : String;
    nm2     : String;
    id_local: String;
  end;
  TVetorUON2 = array of TRegistroUON2;

var VetorUON1  : TVetorUON1;
    VetorUON1a : TVetorUON1a;
    VetorUON2  : TVetorUON2;

Function TFormularioGeral.RetornaValorVetorUON1(id1 : string) : String;
var I : Integer;
begin
   For I := 0 to (Length(VetorUON1)-1)  Do
       If (VetorUON1[I].id1 = id1) Then Result := VetorUON1[I].nm1;
end;

Function TFormularioGeral.RetornaValorVetorUON1a(id1a : string) : String;
var I : Integer;
begin
   For I := 0 to (Length(VetorUON1a)-1)  Do
       If (VetorUON1a[I].id1a     = id1a) Then Result := VetorUON1a[I].nm1a;
end;

Function TFormularioGeral.RetornaValorVetorUON2(id2, idLocal: string) : String;
var I : Integer;
begin
   For I := 0 to (Length(VetorUON2)-1)  Do
       If (VetorUON2[I].id2      = id2) and
          (VetorUON2[I].id_local = idLocal) Then Result := VetorUON2[I].nm2;
end;

procedure TFormularioGeral.DrawBar(ACanvas: TCanvas);
var
  lf : TLogFont;
  tf : TFont;
begin
  with ACanvas do begin
    Brush.Color := clGrayText;
    FillRect(Rect(0,    //ALeft
                  0,    //ATop
                  12,   //ARight
                  122));//ABottom

    Font.Name  := 'Arial';
    Font.Size  := 7;
    Font.Style := [fsBold];
    Font.Color := clWhite;
    tf := TFont.Create;
    try
      tf.Assign(Font);
      GetObject(tf.Handle, sizeof(lf), @lf);
      lf.lfEscapement := 900;
      lf.lfHeight := Font.Height ;
      tf.Handle := CreateFontIndirect(lf);
      Font.Assign(tf);
    finally
      tf.Free;
    end;
    TextOut( -1, // X
            102, pnVersao.Caption);
  end;
end;

function TFormularioGeral.ServiceStart(sMachine,sService : string ) : boolean;
var
  schm, // Service Control Manager Handle
  schs   : SC_Handle;  // Service Handle
  ss     : TServiceStatus;  // Service Status
  psTemp : PChar;   // Temp Char Pointer
  dwChkP : DWord;   // Check Point
begin
//  ss.dwCurrentState := -1;
  objCACIC.writeDebugLog('ServiceStart: ' + sService + ' - Iniciando!');
  ss.dwCurrentState := 0;

  // connect to the Service Control Manager
  schm := OpenSCManager(PChar(sMachine),Nil,SC_MANAGER_CONNECT);

  // if successful...
  if(schm > 0)then
  begin
    // open a handle to the specified service
    schs := OpenService(schm,PChar(sService),SERVICE_START or SERVICE_QUERY_STATUS);  // we want to start the service and query service status

    // if successful...
    if(schs > 0)then
    begin
      psTemp := Nil;
      if(StartService(
           schs,
           0,
           psTemp))then
      begin
        // check status
        if(QueryServiceStatus(
             schs,
             ss))then
        begin
          while(SERVICE_RUNNING
            <> ss.dwCurrentState)do
          begin
            //
            // dwCheckPoint contains a value that the service
            // increments periodically to report its progress
            // during a lengthy operation.
            //
            // save current value
            //
            dwChkP := ss.dwCheckPoint;

            //
            // wait a bit before checking status again
            //
            // dwWaitHint is the estimated amount of time
            // the calling program should wait before calling
            // QueryServiceStatus() again
            //
            // idle events should be handled here...
            //
            Sleep(ss.dwWaitHint);

            if(not QueryServiceStatus(
                 schs,
                 ss))then
            begin
              // couldn't check status break from the loop
              break;
            end;

            if(ss.dwCheckPoint <
              dwChkP)then
            begin
              // QueryServiceStatus didn't increment dwCheckPoint as it
              // should have.
              // avoid an infinite loop by breaking
              break;
            end;
          end;
        end;
      end;

      // close service handle
      CloseServiceHandle(schs);
    end;

    // close service control manager handle
    CloseServiceHandle(schm);
  end;

  // return TRUE if the service status is running
  Result := SERVICE_RUNNING = ss.dwCurrentState;
  if Result then
    objCACIC.writeDebugLog('ServiceStart: ' + sService + ' - OK!')
  else
    objCACIC.writeDebugLog('ServiceStart: ' + sService + ' - N�o Foi Poss�vel Iniciar!');
end;

// In�cio de Procedimentos para monitoramento de dispositivos USB - Anderson Peterle - 02/2010
procedure TFormularioGeral.UsbIN(ASender : TObject; const ADevType,AVendorID,ADeviceID : string);
begin
  // Envio de valores ao Gerente WEB
  // Formato: USBinfo=I_ddmmyyyyhhnnss_ADeviceID
  // Os valores ser�o armazenados localmente (cacic280.inf) se for imposs�vel o envio.
  objCACIC.writeDebugLog('UsbIN: << USB INSERIDO .:. Vendor ID => ' + AVendorID + ' .:. Device ID = ' + ADeviceID);
  Invoca_GerCols('USBinfo=I_'+FormatDateTime('yyyymmddhhnnss', now) + '_' + AVendorID + '_' + ADeviceID, false, false);
end;


procedure TFormularioGeral.UsbOUT(ASender : TObject; const ADevType,AVendorID,ADeviceID : string);
begin
  // Envio de valores ao Gerente WEB
  // Formato: USBinfo=O_ddmmyyyyhhnnss_ADeviceID
  // Os valores ser�o armazenados localmente (cacic280.inf) se for imposs�vel o envio.
  objCACIC.writeDebugLog('UsbOUT: >> USB REMOVIDO .:. Vendor ID => ' + AVendorID + ' .:. Device ID = ' + ADeviceID);
  Invoca_GerCols('USBinfo=O_'+FormatDateTime('yyyymmddhhnnss', now) + '_' + AVendorID + '_' + ADeviceID, false, false);
end;

// Fim de Procedimentos para monitoramento de dispositivos USB - Anderson Peterle - 02/2010
{
procedure TFormularioGeral.MontaVetoresPatrimonio(p_strConfigs : String);
var Parser   : TXmlParser;
    i        : integer;
    strAux,
    strAux1,
    strTagName,
    strItemName  : string;
begin

  Parser := TXmlParser.Create;
  Parser.Normalize := True;
  Parser.LoadFromBuffer(PAnsiChar(p_strConfigs));
  objCACIC.writeDebugLog('MontaVetoresPatrimonio: p_strConfigs: '+p_strConfigs);

  // C�digo para montar o vetor UON1
  Parser.StartScan;
  i := -1;
  strItemName := '';
  strTagName  := '';
  While Parser.Scan DO
    Begin
     strItemName := UpperCase(Parser.CurName);
     if (Parser.CurPartType = ptStartTag) and (strItemName = 'IT1') Then
       Begin
          i := i + 1;
          SetLength(VetorUON1, i + 1); // Aumento o tamanho da matriz dinamicamente de acordo com o n�mero de itens recebidos.
          strTagName := 'IT1';
       end
     else if (Parser.CurPartType = ptEndTag) and (strItemName = 'IT1') then
       strTagName := ''
     else if (Parser.CurPartType in [ptContent, ptCData]) and (strTagName='IT1')Then
       Begin
         strAux1 := objCACIC.deCrypt(Parser.CurContent);
         if      (strItemName = 'ID1') then
           Begin
             VetorUON1[i].id1 := strAux1;
             objCACIC.writeDebugLog('MontaVetoresPatrimonio: Gravei VetorUON1.id1: "'+strAux1+'"');
           End
         else if (strItemName = 'NM1') then
           Begin
             VetorUON1[i].nm1 := strAux1;
             objCACIC.writeDebugLog('MontaVetoresPatrimonio: Gravei VetorUON1.nm1: "'+strAux1+'"');
           End;
       End;
    End;

  // C�digo para montar o vetor UON1a
  Parser.StartScan;
  strTagName := '';
  strAux1    := '';
  i := -1;
  While Parser.Scan DO
    Begin
     strItemName := UpperCase(Parser.CurName);
     if (Parser.CurPartType = ptStartTag) and (strItemName = 'IT1A') Then
       Begin
          i := i + 1;
          SetLength(VetorUON1a, i + 1); // Aumento o tamanho da matriz dinamicamente de acordo com o n�mero de itens recebidos.
          strTagName := 'IT1A';
       end
     else if (Parser.CurPartType = ptEndTag) and (strItemName = 'IT1A') then
       strTagName := ''
     else if (Parser.CurPartType in [ptContent, ptCData]) and (strTagName='IT1A')Then
        Begin
          strAux1 := objCACIC.deCrypt(Parser.CurContent);
          if      (strItemName = 'ID1') then
            Begin
              VetorUON1a[i].id1 := strAux1;
              objCACIC.writeDebugLog('Gravei VetorUON1a.id1: "'+strAux1+'"');
            End
          else if (strItemName = 'SG_LOC') then
            Begin
              strAux := ' ('+strAux1 + ')';
            End
          else if (strItemName = 'ID1A') then
            Begin
              VetorUON1a[i].id1a := strAux1;
              objCACIC.writeDebugLog('Gravei VetorUON1a.id1a: "'+strAux1+'"');
            End
          else if (strItemName = 'NM1A') then
            Begin
              VetorUON1a[i].nm1a := strAux1+strAux;
              objCACIC.writeDebugLog('Gravei VetorUON1a.nm1a: "'+strAux1+strAux+'"');
            End
          else if (strItemName = 'ID_LOCAL') then
            Begin
              VetorUON1a[i].id_local := strAux1;
              objCACIC.writeDebugLog('Gravei VetorUON1a.id_local: "'+strAux1+'"');
            End;

        End;
    end;

  // C�digo para montar o vetor UON2
  Parser.StartScan;
  strTagName := '';
  i := -1;
  While Parser.Scan DO
    Begin
     strItemName := UpperCase(Parser.CurName);
     if (Parser.CurPartType = ptStartTag) and (strItemName = 'IT2') Then
       Begin
          i := i + 1;
          SetLength(VetorUON2, i + 1); // Aumento o tamanho da matriz dinamicamente de acordo com o n�mero de itens recebidos.
          strTagName := 'IT2';
       end
     else if (Parser.CurPartType = ptEndTag) and (strItemName = 'IT2') then
       strTagName := ''
     else if (Parser.CurPartType in [ptContent, ptCData]) and (strTagName='IT2')Then
        Begin
          strAux1  := objCACIC.deCrypt(Parser.CurContent);
          if      (strItemName = 'ID1A') then
            Begin
              VetorUON2[i].id1a := strAux1;
              objCACIC.writeDebugLog('Gravei VetorUON2.id1a: "'+strAux1+'"');
            End
          else if (strItemName = 'ID2') then
            Begin
              VetorUON2[i].id2 := strAux1;
              objCACIC.writeDebugLog('Gravei VetorUON2.id2: "'+strAux1+'"');
            End
          else if (strItemName = 'NM2') then
            Begin
              VetorUON2[i].nm2 := strAux1;
              objCACIC.writeDebugLog('Gravei VetorUON2.nm2: "'+strAux1+'"');
            End
          else if (strItemName = 'ID_LOCAL') then
            Begin
              VetorUON2[i].id_local := strAux1;
              objCACIC.writeDebugLog('Gravei VetorUON2.id_local: "'+strAux1+'"');
            End;

        End;
    end;
  Parser.Free;
end;
}
function TFormularioGeral.ActualActivity : integer;
Begin
  // Se eu conseguir matar os arquivos abaixo � porque srCACICsrv, GerCols e mapaCACIC j� finalizaram suas atividades...
  objCACIC.writeDebugLog('ActualActivity: BEGIN');

  objCACIC.deleteFileOrFolder(objCACIC.getLocalFolderName + 'Temp\aguarde_GER.txt');
  objCACIC.deleteFileOrFolder(objCACIC.getLocalFolderName + 'Temp\aguarde_SRCACIC.txt');
  objCACIC.deleteFileOrFolder(objCACIC.getLocalFolderName + 'Temp\aguarde_MAPACACIC.txt');

  if not FileExists(objCACIC.getLocalFolderName + 'Temp\aguarde_GER.txt')       and
     not FileExists(objCACIC.getLocalFolderName + 'Temp\aguarde_SRCACIC.txt')   and
     not FileExists(objCACIC.getLocalFolderName + 'Temp\aguarde_MAPACACIC.txt') then
      Result := 0 // NORMAL
  else if FileExists(objCACIC.getLocalFolderName + 'Temp\aguarde_GER.txt')      then
      Result := 1 // COLETANDO
  else if FileExists(objCACIC.getLocalFolderName + 'Temp\aguarde_SRCACIC.txt')  then
      Result := 3 // EM SUPORTE REMOTO
  else if FileExists(objCacic.getLocalFolderName + 'Temp\aguarde_MAPACACIC.txt') then
      Result := 4;

  objCACIC.writeDebugLog('ActualActivity: Retornando '+IntToStr(Result));
  objCACIC.writeDebugLog('ActualActivity: END');
End;

function Pode_Coletar : boolean;
var v_JANELAS_EXCECAO,
    v_plural1,
    v_plural2   : string;
    tstrJANELAS : TStrings;
    h : hwnd;
    v_contador, intContaJANELAS, intAux : integer;
Begin
    intContaJANELAS := 0;
    h := 0;

    if (FormularioGeral.ActualActivity = 0) then
        Begin
          // Verifica��o das janelas abertas para que n�o aconte�a coletas caso haja aplica��es pesadas rodando (configurado no M�dulo Gerente)
          v_JANELAS_EXCECAO := objCACIC.GetValueFromFile('Configs','TeJanelasExcecao', FormularioGeral.strMainProgramInfFileName);

          objCACIC.writeDebugLog('Pode_Coletar: Verificando Janelas para Exce��o...');
          tstrJANELAS := TStrings.Create;
          if (v_JANELAS_EXCECAO <> '') then
            Begin
              tstrJANELAS := objCACIC.explode(trim(v_JANELAS_EXCECAO),',');
              if (tstrJANELAS.Count > 0) then
                  for intAux := 0 to tstrJANELAS.Count-1 Do
                    Begin

                      h := FormularioGeral.FindWindowByTitle(tstrJANELAS[intAux]);
                      if h <> 0 then intContaJANELAS := 1;
                      break;
                    End;
            End;

          // Caso alguma janela tenha algum nome de aplica��o cadastrada como "cr�tica" ou "pesada"...
          if (intContaJANELAS > 0) then
            Begin
              objCACIC.writeDailyLog('EXECU��O DE ATIVIDADES ADIADA!');
              v_contador := 0;
              v_plural1 := '';
              v_plural2 := '�O';
              for intAux := 0 to tstrJANELAS.Count-1 Do
                Begin
                  h := FormularioGeral.FindWindowByTitle(tstrJANELAS[intAux]);
                  if h <> 0 then
                    Begin
                      v_contador := v_contador + 1;
                      objCACIC.writeDailyLog('Aplica��o/Janela ' + inttostr(v_contador) + ': ' + tstrJANELAS[intAux]);
                    End;
                End;
              if (v_contador > 1) then
                Begin
                  v_plural1  := 'S';
                  v_plural2 := '�ES';
                End;
              objCACIC.writeDailyLog('-> PARA PROCEDER, FINALIZE A' + v_plural1 + ' APLICA�' + v_plural2 + ' LISTADA' + v_plural1 + ' ACIMA.');
            End;
        End;

     if (intContaJANELAS = 0) and (h = 0) and (FormularioGeral.ActualActivity = 0) then
       Result := true
     else
        Begin
          objCACIC.writeDebugLog('Pode_Coletar: A A��o foi NEGADA!');
          if (intContaJANELAS=0) then
            Begin
             if (FileExists(objCACIC.getLocalFolderName + 'Temp\aguarde_GER.txt')) then
               objCACIC.writeDebugLog('Pode_Coletar: Gerente de Coletas em atividade.');

             if (FileExists(objCACIC.getLocalFolderName + 'Temp\aguarde_SRCACIC.txt')) then
                objCACIC.writeDebugLog('Pode_Coletar: Suporte Remoto em atividade.');

             if (FileExists(objCACIC.getLocalFolderName + 'Temp\aguarde_MAPACACIC.txt')) then
                objCACIC.writeDebugLog('Pode_Coletar: M�dulo Avulso para Coleta de Patrim�nio em atividade.');
            End;
          //else
          //  objCACIC.cipherClose(objCACIC.getLocalFolderName + objCACIC.getDatFileName,v_tstrCipherOpened);
          Result := false;
        End;

End;

Procedure TFormularioGeral.RemoveIconesMortos;
var
  TrayWindow : HWnd;
  WindowRect : TRect;
  SmallIconWidth : Integer;
  SmallIconHeight : Integer;
  CursorPos : TPoint;
  Row : Integer;
  Col : Integer;
begin
  { Get tray window handle and bounding rectangle }
  TrayWindow := FindWindowEx(FindWindow('Shell_TrayWnd',NIL),0,'TrayNotifyWnd',NIL);
  if not GetWindowRect(TrayWindow,WindowRect) then
    Exit;
  { Get small icon metrics }
  SmallIconWidth := GetSystemMetrics(SM_CXSMICON);
  SmallIconHeight := GetSystemMetrics(SM_CYSMICON);
  { Save current mouse position }
  GetCursorPos(CursorPos);
  { Sweep the mouse cursor over each icon in the tray in both dimensions }
  with WindowRect do
  begin
    for Row := 0 to (Bottom - Top) DIV SmallIconHeight do
    begin
      for Col := 0 to (Right - Left) DIV SmallIconWidth do
      begin
        SetCursorPos(Left + Col * SmallIconWidth, Top + Row * SmallIconHeight);
        Sleep(0);
      end;
    end;
  end;
  { Restore mouse position }
  SetCursorPos(CursorPos.X,CursorPos.Y);
  { Redraw tray window (to fix bug in multi-line tray area) }
  RedrawWindow(TrayWindow,NIL,0,RDW_INVALIDATE OR RDW_ERASE OR RDW_UPDATENOW);
End;

procedure TFormularioGeral.WMMENUSELECT(var msg: TWMMENUSELECT);
begin
  inherited;
  IsMenuOpen := not ((msg.MenuFlag and $FFFF > 0) and (msg.Menu = 0));
end;

// Verifico a exist�ncia do Gerente de Coletas, caso n�o exista, o chksis.exe far� download!
function TFormularioGeral.ChecaMAPACACIC : boolean;
var strFileSize : String;
Begin
  Result := true;

  objCACIC.writeDebugLog('ChecaMAPA: Verificando exist�ncia e tamanho do Gerente de Coletas...');

  strFileSize := objCACIC.getFileSize(objCACIC.getLocalFolderName + 'Modules\mapacacic.exe',true);

  if ((objCACIC.getFileHash(objCACIC.getLocalFolderName + 'Modules\mapacacic.exe') <>
      objCACIC.getValueFromFile('Hash-Codes', 'MAPACACIC.EXE', strChksisInfFileName)) or
      (strFileSize <= '0')) then
  begin
    Result := false;
    objCACIC.deleteFileOrFolder(objCACIC.getLocalFolderName + 'Modules\mapacacic.exe');

    InicializaTray;

    objCACIC.writeDailyLog('Acionando Recuperador de Mapa Cacic.');
    objCACIC.writeDebugLog('ChecaMAPACACIC: Acionando Recuperador de M�dulo Gerente de Coletas: '+objCACIC.getWinDir + 'chksis.exe');
    objCACIC.createOneProcess(objCACIC.getWinDir + 'chksis.exe',true,SW_HIDE);

    objCacic.setBoolCipher(not objCacic.isInDebugMode);
    strFileSize := objCACIC.getFileSize(objCACIC.getLocalFolderName + '\Modules\mapacacic.exe',true);
    if not(strFileSize = '0') and not(strFileSize = '-1') then
    Begin
       objCACIC.writeDailyLog('M�dulo Mapa Cacic RECUPERADO COM SUCESSO!');
       objCACIC.writeDebugLog('ChecaMAPACACIC: M�dulo Gerente de Coletas RECUPERADO COM SUCESSO!');
       InicializaTray;
       Result := True;
    End
    else
    Begin
        objCACIC.writeDailyLog('M�dulo Mapa Cacic N�O RECUPERADO!');
        objCACIC.writeDebugLog('ChecaMAPACACIC: M�dulo Gerente de Coletas N�O RECUPERADO!');
    End;
    objCACIC.writeDebugLog('ChecaMAPACACIC: ' + DupeString('=',100));
  end;
End;

// Verifico a exist�ncia do Gerente de Coletas, caso n�o exista, o chksis.exe far� download!
function TFormularioGeral.ChecaGERCOLS : boolean;
var strFileSize : String;
Begin
  Result := true;

  objCACIC.writeDebugLog('ChecaGERCOLS: Verificando exist�ncia e tamanho do Gerente de Coletas...');

  strFileSize := objCACIC.getFileSize(objCACIC.getLocalFolderName + 'Modules\gercols.exe',true);

  if (strFileSize = '0') or (strFileSize = '-1') then
    Begin
      Result := false;

      objCACIC.deleteFileOrFolder(objCACIC.getLocalFolderName + 'Modules\gercols.exe');

      InicializaTray;

      objCACIC.writeDailyLog('Acionando Recuperador de M�dulo Gerente de Coletas.');
      objCACIC.writeDebugLog('ChecaGERCOLS: Acionando Recuperador de M�dulo Gerente de Coletas: '+objCACIC.getWinDir + 'chksis.exe');
      objCACIC.createOneProcess(objCACIC.getWinDir + 'chksis.exe',false,SW_HIDE);

      sleep(30000); // 30 segundos de espera para download do gercols.exe
      objCacic.setBoolCipher(not objCacic.isInDebugMode);
      strFileSize := objCACIC.getFileSize(objCACIC.getLocalFolderName + '\Modules\gercols.exe',true);
      if not(strFileSize = '0') and not(strFileSize = '-1') then
        Begin
          objCACIC.writeDailyLog('M�dulo Gerente de Coletas RECUPERADO COM SUCESSO!');
          objCACIC.writeDebugLog('ChecaGERCOLS: M�dulo Gerente de Coletas RECUPERADO COM SUCESSO!');
          InicializaTray;
          Result := True;
        End
      else
        Begin
          objCACIC.writeDailyLog('M�dulo Gerente de Coletas N�O RECUPERADO!');
          objCACIC.writeDebugLog('ChecaGERCOLS: M�dulo Gerente de Coletas N�O RECUPERADO!');
        End;
    End;
  objCACIC.writeDebugLog('ChecaGERCOLS: ' + DupeString('=',100));
End;


procedure ExibirConfiguracoes(Sender: TObject);
begin
  // SJI = Senha J� Informada...
  // Esse valor � inicializado com "N"
  if (objCACIC.deCrypt( objCACIC.GetValueFromFile('Configs','SJI',FormularioGeral.strMainProgramInfFileName)) = '') and
     (objCACIC.GetValueFromFile('Configs','WebManagerAddress',FormularioGeral.strChkSisInfFileName) <> '') then
    begin
      FormularioGeral.CriaFormSenha(nil);
      formSenha.ShowModal;
    end;

  if (objCACIC.deCrypt( objCACIC.GetValueFromFile('Configs','SJI',FormularioGeral.strMainProgramInfFileName)) <> '') or
     (objCACIC.GetValueFromFile('Configs','WebManagerAddress',FormularioGeral.strChkSisInfFileName) = '') then
    begin
      Application.CreateForm(TFormConfiguracoes, FormConfiguracoes);
      FormConfiguracoes.ShowModal;
    end;
end;

procedure TFormularioGeral.CriaFormSenha(Sender: TObject);
begin
    // Caso ainda n�o exista senha para administra��o do CACIC, define ADMINCACIC como inicial.
    if (objCACIC.deCrypt( objCACIC.GetValueFromFile('Configs','TeSenhaAdmAgente',FormularioGeral.strMainProgramInfFileName),false,true) = '') Then
      objCACIC.setValueToFile('Configs','TeSenhaAdmAgente', objCACIC.enCrypt('ADMINCACIC'), FormularioGeral.strMainProgramInfFileName);

    Application.CreateForm(TFormSenha, FormSenha);
end;

procedure TFormularioGeral.ChecaCONFIGS;
var strAux        : string;
Begin

  // Verifico se o endere�o do servidor do cacic foi configurado.
  if (objCACIC.GetValueFromFile('Configs','WebManagerAddress',strChkSisInfFileName) = '') then
    Begin
      strAux := objCACIC.fixWebAddress(objCACIC.GetValueFromFile('Configs','WebManagerAddress', strChkSisInfFileName));

      if (strAux = '') then
        begin
          strAux := 'ATEN��O: Endere�o do servidor do CACIC ainda n�o foi configurado.';
          objCACIC.writeDailyLog(strAux);
          objCACIC.writeDailyLog('Ativando m�dulo de configura��o de endere�o de servidor.');
          MessageDlg(strAux + chr(13) + 'Por favor, informe o endere�o do servidor do CACIC na tela que ser� exibida a seguir.', mtWarning, [mbOk], 0);
          ExibirConfiguracoes(Nil);
        end;
    End;
end;

procedure TFormularioGeral.HabilitaInformacoesGerais;
Begin
  // Desabilita/Habilita a op��o de Informa��es Gerais
  Mnu_InformacoesGerais.Enabled := (objCACIC.getValueFromTags('Caption'             ,strWin32_ComputerSystem)              +
                                    objCACIC.getValueFromTags('IPAddress'           ,strWin32_NetworkAdapterConfiguration) +
                                    objCACIC.getValueFromTags('DNSDomain'           ,strWin32_NetworkAdapterConfiguration) +
                                    objCACIC.getValueFromTags('DNSHostName'         ,strWin32_NetworkAdapterConfiguration) +
                                    objCACIC.getValueFromTags('DNSServerSearchOrder',strWin32_NetworkAdapterConfiguration) +
                                    objCACIC.getValueFromTags('DefaultIPGateway'    ,strWin32_NetworkAdapterConfiguration) +
                                    objCACIC.getValueFromTags('IPSubnet'            ,strWin32_NetworkAdapterConfiguration) +
                                    objCACIC.getValueFromTags('DHCPServer'          ,strWin32_NetworkAdapterConfiguration) +
                                    objCACIC.getValueFromTags('WINSPrimaryServer'   ,strWin32_NetworkAdapterConfiguration) +
                                    objCACIC.getValueFromTags('WINSSecondaryServer' ,strWin32_NetworkAdapterConfiguration) <> '');
End;

procedure TFormularioGeral.HabilitaSuporteRemoto;
Begin
  // Desabilita/Habilita a op��o de Suporte Remoto
  Mnu_SuporteRemoto.Enabled := (objCACIC.GetValueFromFile('Configs','CsSuporteRemoto',strMainProgramInfFileName) = 'S') and (FileExists(objCACIC.getLocalFolderName + 'Modules\srcacicsrv.exe'));
End;

function TFormularioGeral.Posso_Rodar : boolean;
Begin
  result := false;

  objCACIC.writeDebugLog('Posso_Rodar: Verificando concomit�ncia de sess�es');
  // Se eu conseguir matar o arquivo abaixo � porque n�o h� outra sess�o deste agente aberta... (POG? N���o!  :) )
  objCACIC.deleteFileOrFolder(objCACIC.getLocalFolderName + 'aguarde_CACIC.txt');

  Result := not (FileExists(objCACIC.getLocalFolderName + 'aguarde_CACIC.txt'));
End;



procedure TFormularioGeral.FormCreate(Sender: TObject);
var textFileAguarde : TextFile;
    serviceType, wordServiceStatus     : Cardinal;
    service_start    : bool;
begin
  objCACIC := TCACIC.Create;
  objCACIC.setLocalFolderName(ExtractFilePath(ParamStr(0)));
  objCACIC.setMainProgramName(ExtractFileName(ParamStr(0)));
  objCACIC.setBoolCipher(not objCACIC.isInDebugMode);
  strMainProgramInfFileName := objCACIC.getLocalFolderName + ChangeFileExt(objCACIC.getMainProgramName,'.inf');
  strGerColsInfFileName     := objCACIC.getLocalFolderName + 'gercols.inf';
  strChkSisInfFileName      := objCACIC.getWinDir          + 'chksis.inf';

  bl_primeira_execucao := true;

  // A verifica��o dupla � uma solu��o de contorno para o caso de o boolCipher ter sido setado ap�s criptografia/deCriptografia do dado gravado
  if (objCACIC.deCrypt( objCACIC.getValueFromFile('Hash-Codes',objCACIC.getMainProgramName,strChkSisInfFileName),false,true)  = objCACIC.getFileHash(ParamStr(0))) then
    Begin
      objCACIC.setMainProgramHash(objCACIC.getFileHash(ParamStr(0)));
      objCACIC.setWebManagerAddress(objCACIC.getValueFromFile('Configs','WebManagerAddress',strChkSisInfFileName));
      objCACIC.setWebServicesFolderName(objCACIC.getValueFromFile('Configs','WebServicesFolderName',strChkSisInfFileName));

      rmTaskbarCreated    := RegisterWindowMessage('TaskbarCreated');
      pnVersao.Caption    := 'CACIC  v:' + objCACIC.getVersionInfo(ParamStr(0));
      g_intIconIndex      := 0;

      Popup_Menu_Contexto.OwnerDraw := True;

      strWin32_NetworkAdapterConfiguration := fetchWMIvalues('Win32_NetworkAdapterConfiguration', objCACIC.getLocalFolderName);
      strWin32_ComputerSystem := fetchWMIvalues('Win32_ComputerSystem', objCACIC.getLocalFolderName);

      //Corre��o do bug do script net logon da pgfn;
      //O script estava instalando o cacic sem intera��o com desktop,
      //bugando o mapa e o trayicon.

      {*** 1 = SERVICE_STOPPED ***}
      {*** 2 = SERVICE_START_PENDING ***}
      {*** 3 = SERVICE_STOP_PENDING ***}
      {*** 4 = SERVICE_RUNNING ***}
      {*** 5 = SERVICE_CONTINUE_PENDING ***}
      {*** 6 = SERVICE_PAUSE_PENDING ***}
      {*** 7 = SERVICE_PAUSED ***}

      // Verifico se o servi�o est� instalado/rodando,etc.
      wordServiceStatus := objCacic.ServiceGetStatus(nil,'CacicSustainService');

      //Verifico o servi�o para corre��o de bug
      // Verifico se o servi�o est� instalado/rodando,etc.

      if wordServiceStatus <> 0 then
      begin
      //verifica o status, se n�o estiver correto altera
        serviceType := objCacic.serviceGetType('', 'CacicSustainService');
      end;

      if (wordServiceStatus = 0) then
      Begin
      // Instalo e Habilito o servi�o
        objCacic.createOneProcess(objCacic.getWinDir + 'cacicservice.exe /install /silent',true);
      End
      else if (wordServiceStatus < 4)  then
      Begin
        objCacic.createOneProcess(objCacic.getWinDir + 'cacicservice.exe -start', true);
      End
      else if (wordServiceStatus > 4)  then
      Begin
        objCacic.createOneProcess(objCacic.getWinDir + 'cacicservice.exe -continue', true);
      End;

      TrayIcon1           := TTrayIcon.Create(self);
      TrayIcon1.Hint      := pnVersao.Caption;
      if not (objCACIC.getValueFromTags('IPAddress',strWin32_NetworkAdapterConfiguration) = '') then
        TrayIcon1.Hint := pnVersao.Caption + chr(13) + 'IP: ' + objCACIC.getValueFromTags('IPAddress',strWin32_NetworkAdapterConfiguration);

      TrayIcon1.PopupMenu := Popup_Menu_Contexto;
      imgIconList.GetIcon(0,TrayIcon1.Icon);
      TrayIcon1.Show;

      // Cria��o do objeto para monitoramento de dispositivos USB
      FUsb                := TUsbClass.Create;
      FUsb.OnUsbInsertion := UsbIN;
      FUsb.OnUsbRemoval   := UsbOUT;

      // Essas vari�veis ajudar�o a controlar o redesenho do �cone no systray,
      // evitando o "roubo" do foco.
      g_intTaskBarAtual    := 0;
      g_intTaskBarAnterior := 0;
      g_intDesktopWindow   := 0;

      // N�o mostrar o formul�rio...
      Application.ShowMainForm := false;
      g_intStatusAnterior      := -1;

      // Aplicar tradu��es GetText,etc...

      strMenuCaptionLAT := Mnu_LogAtividades.Caption;
      strMenuCaptionCON := Mnu_Configuracoes.Caption;
      strMenuCaptionEXE := Mnu_ExecutarAgora.Caption;
      strMenuCaptionINF := Mnu_InformacoesGerais.Caption;
      strMenuCaptionSUP := Mnu_SuporteRemoto.Caption;
      strMenuCaptionFIN := Mnu_FinalizarCacic.Caption;


      Try

         // Apago o indicador de finaliza��o normal
         objCACIC.deleteFileOrFolder(objCACIC.getLocalFolderName + 'normal_CACIC.txt');

         if not DirectoryExists(objCACIC.getLocalFolderName + 'Temp') then
           begin
             ForceDirectories(objCACIC.getLocalFolderName + 'Temp');
             FileSetAttr (objCACIC.getLocalFolderName + 'Temp',0); // Retira os atributos para evitar o erro I/O 32
             objCACIC.writeDailyLog('Criando pasta '+objCACIC.getLocalFolderName + 'Temp');
           end;

         if not DirectoryExists(objCACIC.getLocalFolderName + 'Modules') then
           begin
             ForceDirectories(objCACIC.getLocalFolderName + 'Modules');
             FileSetAttr (objCACIC.getLocalFolderName + 'Modules',0); // Retira os atributos para evitar o erro I/O 32
             objCACIC.writeDailyLog('Criando pasta '+objCACIC.getLocalFolderName + 'Modules');
           end;

         objCACIC.writeDebugLog('FormCreate: Pasta Local do Sistema: "' + objCACIC.getLocalFolderName + '"');

         if Posso_Rodar then
            Begin
              // Uma forma f�cil de evitar que outra sess�o deste agente seja iniciada! (POG? N����ooo!) :))))
              AssignFile(textFileAguarde,objCACIC.getLocalFolderName + 'aguarde_CACIC.txt'); {Associa o arquivo a uma vari�vel do tipo TextFile}
              {$IOChecks off}
              Reset(textFileAguarde); {Abre o arquivo texto}
              {$IOChecks on}
              if (IOResult <> 0) then // Arquivo n�o existe, ser� recriado.
                Rewrite (textFileAguarde);

              Append(textFileAguarde);
              Writeln(textFileAguarde,'Apenas um pseudo-cookie para evitar sessões concomitantes...');
              Append(textFileAguarde);
              Writeln(textFileAguarde,'Futuramente penso em colocar aqui o pID, para possibilitar finalização via software externo...');
              Append(textFileAguarde);

              // Inicializo bloqueando o m�dulo de suporte remoto seguro na FireWall nativa.
              if FileExists(objCACIC.getLocalFolderName + 'Modules\srcacicsrv.exe') then
                objCACIC.addApplicationToFirewall('srCACIC - Suporte Remoto Seguro do Sistema CACIC',objCACIC.getLocalFolderName + 'Modules\srcacicsrv.exe', false);

              CheckIfDownloadedVersion;


              If  FindCmdLineSwitch('execute', True) or
                  FindCmdLineSwitch('atualizacao', True) Then
                begin
                  if FindCmdLineSwitch('atualizacao', True) then
                    begin
                      objCACIC.writeDebugLog('FormCreate: Opção /atualizacao recebida...');
                      objCACIC.writeDailyLog('Reinicializando com versão '+ objCACIC.GetVersionInfo(ParamStr(0)));
                    end
                  else
                    begin
                      objCACIC.writeDebugLog('FormCreate: Opção /execute recebida...');
                      objCACIC.writeDailyLog('Opção para execução imediata encontrada...');
                    end;
                  ExecutaCACIC(nil);
                end;
              Invoca_GerCols('getMapa');
              // Os timers iniciam-se desabilitados... Mais � frente receber�o par�metros de tempo para execu��o.
              timerNuExecApos.Enabled   := False;
              timerNuIntervalo.Enabled  := False;

              // Derruba o cacic durante o shutdown do windows.
              ShutdownEmExecucao := False;

              // N�o mostrar o formul�rio...
              //Application.ShowMainForm:=false;

              Try
                // A chamada abaixo define os valores usados pelo agente principal.
                SetaVariaveisGlobais;
              Except
                on E : Exception do
                objCACIC.writeExceptionLog(E.Message,E.ClassName,'SETANDO VARIÁVEIS GLOBAIS!');
              End;

              timerNuExecApos.Enabled  := True;

              CheckForcaColeta.Enabled := True;

              InicializaTray;

              // String list e objeto para captura de a��es durante suporte remoto
              tstrListRCActions := TStringList.Create;
            End
         else
            Begin
              objCACIC.writeDebugLog('FormCreate: Agente finalizado devido a concomitância de sessões...');
              Finaliza;
            End;
      Except
        on E:Exception do
          Begin
            objCACIC.writeExceptionLog(E.Message,e.ClassName,'PROBLEMAS NA INICIALIZAÇÃO (2)');
            Finaliza(false);
          End;
      End
    End
  else
    Begin
      objCACIC.writeDailyLog('Execução Impedida por Falta de Integridade do Agente Principal!');
      Finaliza(false);
    End;
end;

procedure TFormularioGeral.SetaVariaveisGlobais;
var v_aux : string;
Begin
  Try
    // Inicializa��o do indicador de SENHA J� INFORMADA
    objCACIC.setValueToFile('Configs','SJI',objCACIC.enCrypt(''),strMainProgramInfFileName);

    if  (Trim(objCACIC.GetValueFromFile('Configs','InExibeBandeja' ,strMainProgramInfFileName)) = ''  ) or
        (Trim(objCACIC.GetValueFromFile('Configs','InExibeBandeja' ,strMainProgramInfFileName)) <> 'S') then
        objCACIC.setValueToFile('Configs','InExibeBandeja' , 'S'  ,strMainProgramInfFileName);

    if (objCACIC.GetValueFromFile('Configs','NuExecApos'      ,strMainProgramInfFileName) = '') then
      objCACIC.setValueToFile('Configs','NuExecApos'     , '12345',strMainProgramInfFileName);

    if (Trim(objCACIC.GetValueFromFile('Configs','NuIntervaloExec',strMainProgramInfFileName)) = '') then
      objCACIC.setValueToFile('Configs','NuIntervaloExec', '4'   ,strMainProgramInfFileName);

    if (Trim(objCACIC.GetValueFromFile('Configs','timerForcaColeta',strMainProgramInfFileName)) = '') then
      objCACIC.setValueToFile('Configs', 'timerForcaColeta', '60', strMainProgramInfFileName);
    
    // IN_EXIBE_BANDEJA     O valor padr�o � mostrar o �cone na bandeja.
    // NU_EXEC_APOS         Assumir� o padr�o de 0 minutos para execu��o imediata em caso de primeira execu��o (instala��o).
    // NU_INTERVALO_EXEC    Assumir� o padr�o de 4 horas para o intervalo, no caso de problemas.

    CheckForcaColeta.Interval := strtoint(objCACIC.getValueFromFile('Configs', 'timerForcaColeta', strMainProgramInfFileName)) * 60000;

    // N�mero de horas do intervalo (3.600.000 milisegundos correspondem a 1 hora).
    timerNuIntervalo.Interval := strtoint(objCACIC.GetValueFromFile('Configs','NuIntervaloExec',strMainProgramInfFileName)) * 3600000;

    // N�mero de minutos para iniciar a execu��o (60.000 milisegundos correspondem a 1 minuto). Acrescento 1, pois se for zero ele n�o executa.
    timerNuExecApos.Interval := (strtoint(objCACIC.GetValueFromFile('Configs','NuExecApos',strMainProgramInfFileName)) * 60000) + 1000;

    // Se for a primeir�ssima execu��o do agente naquela m�quina (ap�s sua instala��o) j� faz todas as coletas configuradas, sem esperar os minutos definidos pelo administrador.
    // Tamb�m armazena os Hash-Codes dos m�dulos principais, evitando novo download...
    If (objCACIC.GetValueFromFile('Configs','NuExecApos',strMainProgramInfFileName) = '12345') then // Flag usada na inicializa��o. S� entra nesse if se for a primeira execu��o do cacic ap�s carregado.
      begin
        timerNuExecApos.Interval := 1000; // 1 minuto para chamar GerCols /coletas
        objCACIC.setValueToFile('Configs','NuExecApos', '1',strMainProgramInfFileName);
      end
    else if (FileExists(objCACIC.getLocalFolderName + 'Temp\atualiza_CACIC.txt')) then
      Begin
        objCACIC.deleteFileOrFolder(objCACIC.getLocalFolderName + 'Temp\atualiza_CACIC.txt');
        timerNuExecApos.Interval := 1000; // 1 minuto para chamar GerCols /coletas
        objCACIC.writeDailyLog('Reinicializando com versão '+ objCACIC.GetVersionInfo(ParamStr(0)));
      End
    else
      Begin
        objCACIC.writeDailyLog('Inicio automático de coletas programado para ' + objCACIC.GetValueFromFile('Configs','NuExecApos',strMainProgramInfFileName) + ' minutos.');
        objCACIC.writeDailyLog('Executar as ações de coletas automaticamente a cada ' + objCACIC.GetValueFromFile('Configs','NuIntervaloExec',strMainProgramInfFileName) + ' horas.');
        objCACIC.writeDailyLog(DupeString('=',100));
      End;

    v_aux := Trim(objCACIC.GetValueFromFile('Configs','DtHrUltimaColeta',strGerColsInfFileName));
    if (v_aux <> '') and (Copy(v_aux, 1, 8) <> FormatDateTime('YYYYmmdd', Now)) then timerNuExecApos.Enabled  := True;

    // Desabilita/Habilita a op��o de Informa��es Gerais
    HabilitaInformacoesGerais;

    // Desabilita/Habilita a op��o de Suporte Remoto
    HabilitaSuporteRemoto;

    InicializaTray;
  Except
    on E : Exception do
      Begin
        objCACIC.writeExceptionLog(E.Message,E.ClassName,'PROBLEMAS NA INICIALIZAÇÃO (1)');
        Finaliza;
      End;
  End;
end;

procedure TFormularioGeral.Finaliza(boolNormal : boolean = true);
var txtFileNormal : TextFile;
Begin
  Try
    cn.Stop;
    FreeAndNil(cn);
    FreeAndNil(FUsb);
    RemoveIconesMortos;

    if (boolNormal) then
      Begin
        // Criando um indicador de finaliza��o normal da aplica��o,
        // evitando que o chkSIS.exe baixe outra c�pia do Agente Principal ao "achar" que o agente encontra-se com problema.
        AssignFile(txtFileNormal,objCACIC.getLocalFolderName + 'normal_CACIC.txt'); {Associa o arquivo a uma vari�vel do tipo TextFile}
        {$IOChecks off}
        Reset(txtFileNormal); {Abre o arquivo texto}
        {$IOChecks on}
        if (IOResult <> 0) then // Arquivo n�o existe, ser� recriado.
          Rewrite (txtFileNormal);

        Append(txtFileNormal);

        Writeln(txtFileNormal,'O Agente Principal do CACIC foi finalizado normalmente.');

        Append(txtFileNormal);

        CloseFile(txtFileNormal);
      End;
  Except
    on E : Exception do
      objCACIC.writeExceptionLog(E.Message,E.ClassName,'PROBLEMAS NA FINALIZAÇÃO');
  End;
  objCACIC.Free;
  Halt(0);
End;

procedure TFormularioGeral.Sair(Sender: TObject);
begin
  CriaFormSenha(nil);
  formSenha.ShowModal;
  If (objCACIC.deCrypt( objCACIC.GetValueFromFile('Configs','SJI',strMainProgramInfFileName)) =  'S') Then Finaliza(true);
end;

procedure TFormularioGeral.Invoca_GerCols(p_acao:string; boolShowInfo : Boolean = true; boolCheckExecution : Boolean = false);
begin
  if not boolCheckExecution or
     (boolCheckExecution    and
     (ActualActivity = 0) ) then
     Begin
        // Caso exista o Gerente de Coletas ser� verificada a vers�o e exclu�da caso antiga(Uma forma de a��o pr�-ativa)
        if ChecaGERCOLS then
          Begin
            ChecaCONFIGS;

            objCACIC.writeDebugLog('Invoca_GerCols: Invocando Gerente de Coletas com ação: "'+p_acao+'"');

            if boolShowInfo and not (p_acao = 'getTest') then
              objCACIC.writeDebugLog('Invocando Gerente de Coletas com ação: "'+p_acao+'"');

            timerNuExecApos.Enabled  := False;
            objCACIC.writeDebugLog('Invoca_GerCols: Criando Processo GerCols => "'+objCACIC.getLocalFolderName + 'Modules\gercols.exe /'+p_acao+' /WebServicesFolderName='+objCACIC.getWebServicesFolderName +' /LocalFolderName='+objCACIC.getLocalFolderName + ' /WebManagerAddress=' + objCACIC.getWebManagerAddress + '"');

            if (p_acao = 'getTest') or (p_acao = 'getConfig') or (p_acao = 'getMapa') then
              objCACIC.createOneProcess(objCACIC.getLocalFolderName + 'Modules\gercols.exe /'+p_acao+' /WebServicesFolderName='+objCACIC.getWebServicesFolderName +' /LocalFolderName='+objCACIC.getLocalFolderName + ' /WebManagerAddress=' + objCACIC.getWebManagerAddress + ' /MainProgramName=' + objCACIC.getMainProgramName + ' /MainProgramHash=' + objCACIC.getMainProgramHash,true,SW_HIDE)            
            else
              objCACIC.createOneProcess(objCACIC.getLocalFolderName + 'Modules\gercols.exe /'+p_acao+' /WebServicesFolderName='+objCACIC.getWebServicesFolderName +' /LocalFolderName='+objCACIC.getLocalFolderName + ' /WebManagerAddress=' + objCACIC.getWebManagerAddress + ' /MainProgramName=' + objCACIC.getMainProgramName + ' /MainProgramHash=' + objCACIC.getMainProgramHash,false,SW_HIDE);

            g_intStatus :=             1;
            objCacic.setBoolCipher(not objCacic.isInDebugMode);
          End
        else
          objCACIC.writeDailyLog('N�o foi poss�vel invocar o Gerente de Coletas!');
     End;
end;

procedure TFormularioGeral.InvocaMapa1Click(Sender: TObject);
begin
  FormularioGeral.Invoca_GerCols('getMapa');
  if (ActualActivity=0) and (objCACIC.getValueFromFile('Configs', 'modulo_patr', strGerColsInfFileName) = 'S') then
    Invoca_MapaCacic
  else if(ActualActivity <> 0) then
  begin
    if ActualActivity = 1 then
      MessageDlg(#13#13+'Coleta em execução!',mtInformation, [mbOK], 0);
    if ActualActivity = 3 then
      MessageDlg(#13#13+'Cacic sendo executado em suporte remoto!',mtInformation, [mbOK], 0);
    if ActualActivity = 4 then
      MessageDlg(#13#13+'Mapa já está em execução!',mtInformation, [mbOK], 0);
  end
  else
    MessageDlg(#13#13+'M�dulo desabilitado!',mtInformation, [mbOK], 0);
end;

////////////////////////////////////////////////////////////////////////////////
//                 CRIADO PARA A CHAMADA DO MAPA CACIC                        //
////////////////////////////////////////////////////////////////////////////////

procedure TFormularioGeral.Invoca_MapaCacic;
begin
  if ActualActivity = 0 then
     Begin
     if ChecaMAPACACIC then
     begin
        // Caso exista o Mapa Cacic ser� verificada a vers�o e exclu�da caso antiga(Uma forma de a��o pr�-ativa)
        if FileExists(objCACIC.getLocalFolderName + 'Modules\mapacacic.exe') then
        Begin
          objCacic.writeDailyLog('Invoca_MapaCacic: Criando processo mapa.');
          objCACIC.writeDebugLog('Invoca_MapaCacic: Criando Processo Mapa => "'+objCACIC.getLocalFolderName + 'Modules\MapaCACIC.exe');
          if (objCACIC.createOneProcess(objCACIC.getLocalFolderName + 'Modules\mapacacic.exe',false,SW_SHOW)) then
            objCacic.writeDailyLog('Invoca_MapaCacic: Processo criado.')
          else
            objCacic.writeDailyLog('Invoca_MapaCacic: Falha ao criar processo.');
        End
        else
          objCACIC.writeDailyLog('Não foi possível invocar o Mapa Cacic!');
     End;
  End;
end;

function TFormularioGeral.FindWindowByTitle(WindowTitle: string): Hwnd;
var
  NextHandle: Hwnd;
  NextTitle: array[0..260] of char;
begin
  // Get the first window
  NextHandle := GetWindow(Application.Handle, GW_HWNDFIRST);
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

procedure TFormularioGeral.ExecutaCACIC(Sender: TObject);
var v_mensagem,
    v_tipo_mensagem,
    primeira_execucao,
    v_TE_FILA_FTP   : string;
    v_MsgDlgType    : TMsgDlgType;
    intTentativas   : integer;
begin
   try

     if FindCmdLineSwitch('execute', True)     or
        FindCmdLineSwitch('atualizacao', True) or
        Pode_Coletar                           or
        (trim(objCACIC.getValueFromFile('Configs','DtHrUltimaColeta', strGerColsInfFileName))='') or
        (trim(objCACIC.getValueFromFile('Configs','forca_coleta', strGerColsInfFileName))='S') Then
        Begin
          timerCheckNoMinuto.Enabled := false;
          objCACIC.writeDebugLog('ExecutaCACIC: Preparando chamada ao Gerente de Coletas...');

          // Se foi gerado o arquivo ger_erro.txt o Log conter� a mensagem al� gravada como valor de chave
          // O Gerente de Coletas dever� ser eliminado para que seja baixado novamente por ChecaGERCOLS
          if (FileExists(objCACIC.getLocalFolderName + 'gererro.txt')) then
            Begin
              objCACIC.writeDailyLog('Gerente de Coletas eliminado devido a falha:');
              objCACIC.writeDailyLog(objCACIC.GetValueFromFile('Mensagens','TeMensagem',strGerColsInfFileName));
              SetaVariaveisGlobais;
              objCACIC.deleteFileOrFolder(objCACIC.getLocalFolderName + 'gererro.txt');
              objCACIC.deleteFileOrFolder(objCACIC.getLocalFolderName + 'Modules\gercols.exe');
            End;

          if (FileExists(objCACIC.getLocalFolderName + 'Temp\reset.txt')) then
            Begin
              objCACIC.deleteFileOrFolder(objCACIC.getLocalFolderName + 'Temp\reset.txt');
              objCACIC.writeDailyLog('Reinicializando...');
              SetaVariaveisGlobais;
            End;

          objCACIC.writeDailyLog('Iniciando execu��o de atividades.');

          objCACIC.writeDebugLog('ExecutaCACIC: Primeira chamada ao Gerente de Coletas...');
          Invoca_GerCols('getConfigs');

          sleep(3000); // Pausa para in�cio do   Gerente de Coletas e cria��o do arquivo temp\aguarde_GER.txt

          Application.ProcessMessages;
          InicializaTray;

          ////////////////////////////////////////////////////////////////////////////////
          //               CRIADO PARA TESTAR A CHAMADA DO MAPA CACIC                   //
          ////////////////////////////////////////////////////////////////////////////////
          if not FindCmdLineSwitch('atualizacao', True)
            and not (FileExists(objCacic.getLocalFolderName + 'Temp\aguarde_MAPACACIC.txt'))
            and (objCACIC.getValueFromFile('Configs', 'Patrimonio', strGerColsInfFileName) = 'true') then
          begin
                objCACIC.writeDebugLog('ExecutaCACIC: Executa chamada ao Mapa Cacic...');
                Invoca_MapaCacic;
          end;

          // Pausas de 15 segundos para o caso de ser(em) baixada(s) nova(s) vers�o(�es) de GerCols e/ou Cacic280.
          // Ser�o 4 tentativas por minuto
          // Ser�o 30 minutos no m�ximo de tentativas, totalizando 120
          intTentativas := 0;
          while (not Pode_Coletar and (intTentativas < 121)) do
            Begin
              objCACIC.writeDebugLog('ExecutaCACIC: Aguardando 15 segundos...');
              Application.ProcessMessages;
              sleep(15000);
              inc(intTentativas);
            End;

          // Neste caso o Gerente de Coletas dever� fazer novo contato devido � permiss�o de criptografia ter sido colocada em espera pelo pr�ximo contato.
          if (intTentativas > 120) or
             (objCACIC.GetValueFromFile('Configs','CsCipher', strGerColsInfFileName) = '2') then
            Begin
              if not (intTentativas > 120) then
                Begin
                  objCACIC.writeDebugLog('ExecutaCACIC: Reiniciando processo -> CsCipher=2');
                  ExecutaCACIC(nil);
                End;
            End
          else
            Begin
              // Caso tenha sido baixada nova c�pia do Gerente de Coletas, esta dever� ser movida para cima da atual
              if (FileExists(objCACIC.getLocalFolderName + 'Temp\gercols.exe')) then
                Begin
                  objCACIC.writeDailyLog('Atualizando vers�o do Gerente de Coletas para '+objCACIC.getVersionInfo(objCACIC.getLocalFolderName + 'Temp\gercols.exe'));
                  // O MoveFileEx n�o se deu bem no Win98!  :|
                  // MoveFileEx(PChar(objCACIC.getLocalFolderName + 'Temp\gercols.exe'),PChar(objCACIC.getLocalFolderName + 'Modulos\gercols.exe'),MOVEFILE_REPLACE_EXISTING);

                  CopyFile(PChar(objCACIC.getLocalFolderName + 'Temp\gercols.exe'),PChar(objCACIC.getLocalFolderName + 'Modules\gercols.exe'),false);
                  sleep(2000); // 2 segundos de espera pela c�pia!  :) (Rwindows!)

                  objCACIC.deleteFileOrFolder(objCACIC.getLocalFolderName + 'Temp\gercols.exe');
                  sleep(2000); // 2 segundos de espera pela dele��o!

                  ExecutaCACIC(nil); // For�ar� uma reexecu��o de GerCols...
                End;

              // Verifico se foi gravada alguma mensagem pelo Gerente de Coletas e mostro caso a configura��o permita
              v_mensagem := objCACIC.GetValueFromFile('Mensagens','TeMensagem', strGerColsInfFileName);
              if (v_mensagem <> '') and
                 (objCACIC.GetValueFromFile('Configs','InExibeErrosCriticos', strMainProgramInfFileName) = 'S') then
                Begin
                  v_tipo_mensagem := objCACIC.GetValueFromFile('Mensagens','CsTipo', strGerColsInfFileName);
                  if      (v_tipo_mensagem='mtError')       then v_MsgDlgType := mtError
                  else if (v_tipo_mensagem='mtInformation') then v_MsgDlgType := mtInformation
                  else if (v_tipo_mensagem='mtWarning')     then v_MsgDlgType := mtWarning;

                  MessageDlg(v_mensagem,v_MsgDlgType, [mbOk], 0);
                  objCACIC.setValueToFile('Mensagens','TeMensagem', '', strGerColsInfFileName);
                  objCACIC.setValueToFile('Mensagens','CsTipo'    , '', strGerColsInfFileName);
                  // Para evitar uma reexecu��o de GerCols sem necessidade...
                  intTentativas := 121; // Apenas para ajudar na condi��o seguinte
                End;

              // Verifico se TE_FILA_FTP foi setado (por GerCols) e obede�o ao intervalo para nova tentativa de coletas
              // Caso TE_FILA_FTP inicie com # � porque j� passou nessa condi��o e deve iniciar nova tentativa de FTP...
              v_TE_FILA_FTP := objCACIC.GetValueFromFile('Configs','TeFilaFTP', strGerColsInfFileName);
              if (intTentativas <> 121) and
                 (Copy(v_TE_FILA_FTP,1,1) <> '#') and
                 (v_TE_FILA_FTP <> '0') and
                 (v_TE_FILA_FTP <> '') then
                Begin
                  // Busquei o n�mero de milisegundos setados em TeFilaFTP e o obede�o...
                  // 60.000 milisegundos correspondem a 60 segundos (1 minuto).
                  // Acrescento 1, pois se for zero ele n�o executa.
                  timerNuExecApos.Enabled  := False;
                  timerNuExecApos.Interval := strtoint(v_TE_FILA_FTP) * 60000;
                  timerNuExecApos.Enabled  := True;
                  objCACIC.writeDailyLog('FTP de coletores adiado pelo M�dulo Gerente.');
                  objCACIC.writeDailyLog('Nova tentativa em aproximadamente ' + v_TE_FILA_FTP+ ' minuto(s).');
                  objCACIC.setValueToFile('Configs','TeFilaFTP','#' + v_TE_FILA_FTP, strGerColsInfFileName);
                End;

              // Desabilita/Habilita a op��o de Informa��es Gerais
              HabilitaInformacoesGerais;

              // Desabilita/Habilita a op��o de Suporte Remoto
              HabilitaSuporteRemoto;

              // O loop 1 foi dedicado a atualiza��es de vers�es e afins...
              // O loop 2 dever� invocar as coletas propriamente ditas...
              if (intTentativas <> 121) then
                Begin
                  objCACIC.writeDebugLog('ExecutaCACIC: Iniciando Chamada para Coletas...');
                  Invoca_GerCols('collect');
                End;
            End;
          timerCheckNoMinuto.Enabled := true;            
        End;

      InicializaTray;
    except
      on E : Exception do
        objCACIC.writeExceptionLog(E.Message,E.ClassName,'PROBLEMAS AO TENTAR ATIVAR COLETAS.');
    end;
   objCACIC.writeDebugLog('ExecutaCACIC: ' + DupeString('=',100));

   bl_primeira_execucao := false;
end;

procedure TFormularioGeral.ExecutarMapa1DrawItem(Sender: TObject;
  ACanvas: TCanvas; ARect: TRect; Selected: Boolean);
begin
 if Selected then
   ACanvas.Brush.Color := clHighlight
 else
   ACanvas.Brush.Color := clMenu;

 ARect.Left := LEFT_MENU_ITEM;
 ACanvas.FillRect(ARect);

 DrawText(ACanvas.Handle, PChar('Executar Mapa'), -1, ARect, DT_LEFT or DT_VCENTER or DT_SINGLELINE{ or DT_NOCLIP});
end;

procedure TFormularioGeral.ExibirLogAtividades(Sender: TObject);
begin
     Application.CreateForm(tformLog,formLog);
     formLog.ShowModal;
end;

procedure TFormularioGeral.ExibirConfiguracoes(Sender: TObject);
begin
  // SJI = Senha J� Informada...
  // Esse valor � inicializado com "N"
  if (objCACIC.deCrypt( objCACIC.GetValueFromFile('Configs','SJI',strMainProgramInfFileName))='') and
     (objCACIC.GetValueFromFile('Configs','WebManagerAddress',strChkSisInfFileName)<>'') then
    begin
      FormularioGeral.CriaFormSenha(nil);
      formSenha.ShowModal;
    end;

  if (objCACIC.deCrypt( objCACIC.GetValueFromFile('Configs','SJI',strMainProgramInfFileName))<>'') or
     (objCACIC.GetValueFromFile('Configs','WebManagerAddress',strChkSisInfFileName)='') then
    begin
      Application.CreateForm(TFormConfiguracoes, FormConfiguracoes);
      FormConfiguracoes.ShowModal;
    end;

end;

//=======================================================================
// Todo o c�digo deste ponto em diante est� relacionado �s rotinas de
// de inclus�o do �cone do programa na bandeja do sistema
//=======================================================================
procedure TFormularioGeral.InicializaTray;
var v_strHint : String;
begin
    // g_intStatus receber� 0 -> NORMAL  ou  1 -> COLETAS  ou  3 -> srCACIC
    g_intStatus := ActualActivity;

    // Monto a frase a ser colocada no Hint
    v_strHint := pnVersao.Caption;

    if not (objCACIC.getValueFromTags('IPAddress',strWin32_NetworkAdapterConfiguration) = '') then
      v_strHint := v_strHint + chr(13) + chr(10) + 'IP: ' + objCACIC.getValueFromTags('IPAddress',strWin32_NetworkAdapterConfiguration);

    // Mostro a vers�o no painel de Informa��es Gerais


    if (g_intStatus = NORMAL) then
      Begin
        if not (UpperCase(objCACIC.GetValueFromFile('Configs','ConexaoOK', strGerColsInfFileName)) = 'S') then
          Begin
            v_strHint := v_strHint + '  IDENTIFICA��O LOCAL...';
            g_intStatus := DESCONFIGURADO;
          End
        else
      End
    else
      Begin
        objCACIC.writeDebugLog('InicializaTray: InActivity');
        objCACIC.writeDebugLog('InicializaTray: v_strHint Antes = "'+v_strHint+'"');
        if g_intStatus = EM_SUPORTE then
          v_strHint := v_strHint + chr(13) + chr(10) + ' Em Suporte Remoto...'
        else if g_intStatus = COLETANDO then
          v_strHint := v_strHint + chr(13) + chr(10) + ' Coletas em Execu��o...';
        objCACIC.writeDebugLog('InicializaTray: v_strHint Depois = "'+v_strHint+'"');
      End;

   g_intIconIndex := g_intStatus;
   objCACIC.writeDebugLog('InicializaTray: g_intStatus   =' + IntToStr(g_intStatus));
   objCACIC.writeDebugLog('InicializaTray: g_intStatusAnterior=' + IntToStr(g_intStatusAnterior));
   objCACIC.writeDebugLog('InicializaTray: g_intIconIndex=' + IntToStr(g_intIconIndex));

   if (g_intStatus <> g_intStatusAnterior) then
      Begin
          imgIconList.GetIcon(g_intIconIndex,TrayIcon1.Icon);
          g_intStatusAnterior := g_intStatus;
          timerCheckNoMinuto.Enabled    := false;
          timerCheckNoMinuto.Interval   := 5000; // Durante as coletas altero o timer verificador de a��es para 5 segundos

          objCACIC.writeDebugLog('InicializaTray: Status alterado para ' + intToStr(g_intStatus));
          if      (g_intStatus = COLETANDO)      then
            Begin
              Mnu_InformacoesGerais.Enabled := False;
              Mnu_ExecutarAgora.Enabled     := False;
              Mnu_InformacoesGerais.Caption := 'Aguarde, coletas em a��o!';
              Mnu_ExecutarAgora.Caption     := Mnu_InformacoesGerais.Caption;
            End
          else if (g_intStatus = DESCONFIGURADO) then
            Begin
              objCACIC.writeDebugLog('InicializaTray: Setando �cones para "Interroga" (intStatus=' + IntToStr(g_intStatus) + ')...');
            End
          else if (g_intStatus = EM_SUPORTE)     then
            Begin
              Mnu_InformacoesGerais.Enabled := False;
              Mnu_ExecutarAgora.Enabled     := False;
              Mnu_InformacoesGerais.Caption := 'Aguarde, em Suporte Remoto!';
              Mnu_ExecutarAgora.Caption     := Mnu_InformacoesGerais.Caption;
            End
          else
            Begin
              timerCheckNoMinuto.Interval   := 60000; // Restauro o timer verificador de a��es para 1 minuto

              Mnu_InformacoesGerais.Caption := strMenuCaptionINF;
              Mnu_ExecutarAgora.Caption     := strMenuCaptionEXE;
              Mnu_InformacoesGerais.Enabled := true;
              Mnu_ExecutarAgora.Enabled     := true;

              objCACIC.writeDebugLog('InicializaTray: Setando �cones para "Normal" (intStatus=' + IntToStr(g_intStatus) + ')...');
            End;

          objCACIC.writeDebugLog('InicializaTray: Setando o HINT do Systray para: "'+v_strHint+'"');
          TrayIcon1.Hint := v_strHint;

        timerCheckNoMinuto.Enabled := true;

        if (objCACIC.GetValueFromFile('Configs','InExibeBandeja', strMainProgramInfFileName) <> 'N') Then
           Begin
             objCACIC.writeDebugLog('InicializaTray: Exibe/Renova �cone do Systray...');
             imgIconList.GetIcon(g_intStatus,TrayIcon1.Icon);
             TrayIcon1.Show;
           End
        else
           Begin
             objCACIC.writeDebugLog('InicializaTray: Inibe �cone do Systray...');
             TrayIcon1.Hide;
           End;
      End
   else
      objCACIC.writeDebugLog('InicializaTray: No mesmo status (' + intToStr(g_intStatus) + ')');

   Application.ProcessMessages;
   objCACIC.writeDebugLog('InicializaTray: ' + DupeString('=',100));
end;

procedure TFormularioGeral.WMSysCommand;
begin  // Captura o minimizar da janela
  if (Msg.CmdType = SC_MINIMIZE) or (Msg.CmdType = SC_MAXIMIZE) then
  Begin
       MinimizaParaTrayArea(Nil);
       Exit;
  end;
  DefaultHandler(Msg);
end;

procedure TFormularioGeral.MinimizaParaTrayArea(Sender: TObject);
begin
    FormularioGeral.Visible:=false;
    if (objCACIC.GetValueFromFile('Configs','InExibeBandeja', strMainProgramInfFileName) = 'N') Then
      Begin
        objCACIC.writeDebugLog('MinimizaParaTrayArea: Escondendo o �cone');
        TrayIcon1.Hide
      End
    else
      Begin
        objCACIC.writeDebugLog('MinimizaParaTrayArea: Mostrando o �cone');
        TrayIcon1.Show;
      End;
end;
// -------------------------------------
// Fim dos c�digos da bandeja do sistema
// -------------------------------------

procedure TFormularioGeral.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
   // Esse evento � colocado em Nil durante o shutdown do windows.
   // Ver o evento WMQueryEndSession.
   CanClose := False;
   MinimizaParaTrayArea(Nil);
end;

procedure TFormularioGeral.WMQueryEndSession(var Msg: TWMQueryEndSession);
begin
   objCACIC.writeDailyLog('Windows em processo de finaliza��o!');
   // Quando h� um shutdown do windows em execu��o, libera o close.
   OnCloseQuery := Nil;
   Msg.Result   := 1;
   Finaliza(true);
   inherited // Continue ShutDown request
end;

procedure TFormularioGeral.Mnu_InformacoesGeraisClick(Sender: TObject);
var v_tripa_perfis, v_tripa_infos_coletadas,strAux : string;
    v_array_perfis, v_array_tripa_infos_coletadas, v_array_infos_coletadas : tstrings;
    v_conta_perfis, v_conta_infos_coletadas, intAux : integer;
begin
    FormularioGeral.Enabled       := true;
    FormularioGeral.Visible       := true;

    ST_VL_NomeHost.Caption        := objCACIC.getValueFromTags('Caption'              ,strWin32_NetworkAdapterConfiguration);
    ST_VL_IPEstacao.Caption       := objCACIC.getValueFromTags('IPAddress'            ,strWin32_NetworkAdapterConfiguration);
    ST_VL_MacAddress.Caption      := objCACIC.getValueFromTags('MACAddress'           ,strWin32_NetworkAdapterConfiguration);
    ST_VL_IPRede.Caption          := '';
    ST_VL_DominioDNS.Caption      := objCACIC.getValueFromTags('DNSDomain'            ,strWin32_NetworkAdapterConfiguration);
    ST_VL_DominioWindows.Caption  := objCACIC.getValueFromTags('Domain'               ,strWin32_ComputerSystem);
    ST_VL_DNSPrimario.Caption     := objCACIC.getValueFromTags('DNSServerSearchOrder' ,strWin32_NetworkAdapterConfiguration);
    ST_VL_DNSSecundario.Caption   := objCACIC.getValueFromTags('DNSServerSearchOrder' ,strWin32_NetworkAdapterConfiguration);
    ST_VL_Gateway.Caption         := objCACIC.getValueFromTags('DefaultIPGateway'     ,strWin32_NetworkAdapterConfiguration);
    ST_VL_Mascara.Caption         := objCACIC.getValueFromTags('IPSubnet'             ,strWin32_NetworkAdapterConfiguration);
    ST_VL_ServidorDHCP.Caption    := objCACIC.getValueFromTags('DHCPServer'           ,strWin32_NetworkAdapterConfiguration);
    ST_VL_WinsPrimario.Caption    := objCACIC.getValueFromTags('WINSPrimaryServer'    ,strWin32_NetworkAdapterConfiguration);
    ST_VL_WinsSecundario.Caption  := objCACIC.getValueFromTags('WINSSecondaryServer'  ,strWin32_NetworkAdapterConfiguration);

    // Exibi��o das informa��es de Sistemas Monitorados...
    v_conta_perfis := 1;
    v_conta_infos_coletadas := 0;
    v_tripa_perfis := '*';

    while v_tripa_perfis <> '' do
      begin

        v_tripa_perfis := objCACIC.deCrypt( objCACIC.GetValueFromFile('Collects','ColMoni_' + trim(inttostr(v_conta_perfis)), strGerColsInfFileName));
        objCACIC.writeDebugLog('Mnu_InformacoesGeraisClick: Perfil => Collects.ColMoni_' + trim(inttostr(v_conta_perfis))+' => '+v_tripa_perfis);
        v_conta_perfis := v_conta_perfis + 1;

        if (trim(v_tripa_perfis) <> '') then
          Begin
            v_array_perfis := objCACIC.explode(v_tripa_perfis,',');

            // ATEN��O!!! Antes da implementa��o de INFORMA��ES GERAIS o Count ia at� 11, ok?!
            if (v_array_perfis.Count > 11) and (v_array_perfis[11]='S') then
              Begin
                v_tripa_infos_coletadas := objCACIC.deCrypt( objCACIC.GetValueFromFile('Collects','ColMoni_Atual', strGerColsInfFileName));
                objCACIC.writeDebugLog('Mnu_InformacoesGeraisClick: Coletas de S.M. Efetuadas => ' + v_tripa_infos_coletadas);
                if (trim(v_tripa_infos_coletadas) <> '') then
                  Begin
                    v_array_tripa_infos_coletadas := objCACIC.explode(v_tripa_infos_coletadas,'#');
                    for intAux := 0 to v_array_tripa_infos_coletadas.Count-1 Do
                      Begin
                        v_array_infos_coletadas := objCACIC.explode(v_array_tripa_infos_coletadas[intAux],',');

                        objCACIC.writeDebugLog('Mnu_InformacoesGeraisClick: Verificando perfil[0]:' + v_array_perfis[0]);
                        if (v_array_infos_coletadas[0]=v_array_perfis[0]) then
                          Begin
                            objCACIC.writeDebugLog('Mnu_InformacoesGeraisClick: Verificando valores condicionais [1]:"'+trim(v_array_infos_coletadas[1])+'" e [3]:"'+trim(v_array_infos_coletadas[3])+'"');
                            if  ((trim(v_array_infos_coletadas[1])<>'') and (trim(v_array_infos_coletadas[1])<>'?')) or
                                ((trim(v_array_infos_coletadas[3])<>'') and (trim(v_array_infos_coletadas[3])<>'?')) then
                              Begin
                                listSistemasMonitorados.Items.Add;
                                listSistemasMonitorados.Items[v_conta_infos_coletadas].Caption := Format('%2d', [v_conta_infos_coletadas+1])+') '+v_array_perfis[12];
                                listSistemasMonitorados.Items[v_conta_infos_coletadas].SubItems.Add(v_array_infos_coletadas[1]);
                                listSistemasMonitorados.Items[v_conta_infos_coletadas].SubItems.Add(v_array_infos_coletadas[3]);
                                v_conta_infos_coletadas := v_conta_infos_coletadas + 1;
                              End;
                          End;
                        Application.ProcessMessages;
                      End;
                  End;
              End;
          End;
      end;

    teDataColeta.Caption := '('+FormatDateTime('dd/mm/yyyy', now)+')';
    staticVlServidorAplicacao.Caption := '"'+ objCACIC.GetValueFromFile('Configs','WebManagerAddress', strChkSisInfFileName)+'"';
    staticVlServidorUpdates.Caption   := '"'+ objCACIC.GetValueFromFile('Configs','TeServUpdates'    , strChkSisInfFileName)+'"';

    strAux := objCACIC.GetValueFromFile('Collects','Coletas_Atual_Inicio', strGerColsInfFileName);
    if (strAux <> '') then
      Begin
        if (copy(strAux,0,8) = FormatDateTime('yyyymmdd', Date)) then
          Begin
            // Vamos reaproveitar algumas vari�veis!...

            v_array_perfis := objCACIC.explode(strAux,'#');
            for intAux := 1 to v_array_perfis.Count-1 Do
              Begin
                v_array_infos_coletadas := objCACIC.explode(v_array_perfis[intAux],',');
                listaColetas.Items.Add;
                listaColetas.Items[intAux-1].Caption := v_array_infos_coletadas[0];
                listaColetas.Items[intAux-1].SubItems.Add(v_array_infos_coletadas[1]);

                // Verifico se houve problema na coleta...
                if (v_array_infos_coletadas[2]<>'99999999') then
                  listaColetas.Items[intAux-1].SubItems.Add(v_array_infos_coletadas[2])
                else
                  Begin
                    listaColetas.Items[intAux-1].SubItems.Add('--------');
                    v_array_infos_coletadas[3] := v_array_infos_coletadas[2];
                  End;

                // C�digos Poss�veis: -1 : Problema no Envio da Coleta
                //                     1 : Coleta Enviada
                //                     0 : Sem Coleta para Envio
                strAux := IfThen(v_array_infos_coletadas[3]='1','Coleta Enviada ao Gerente WEB!',
                          IfThen(v_array_infos_coletadas[3]='-1','Problema Enviando Coleta ao Gerente WEB!',
                          IfThen(v_array_infos_coletadas[3]='0','Sem Coleta para Envio ao Gerente WEB!',
                          IfThen(v_array_infos_coletadas[3]='99999999','Problema no Processo de Coleta!','Status Desconhecido!'))));
                listaColetas.Items[intAux-1].SubItems.Add(strAux);

                Application.ProcessMessages;
              End;
          End
      End
    else
      Begin
        listSistemasMonitorados.Items.Add;
        listSistemasMonitorados.Items[0].Caption := 'N�o H� Coletas Registradas Nesta Data';
      End;

   strConfigsPatrimonio      := objCACIC.GetValueFromFile('Patrimonio','Configs', strMainProgramInfFileName);

//   MontaVetoresPatrimonio(strConfigsPatrimonio);

   if (strConfigsPatrimonio = '') then
    lbSemInformacoesPatrimoniais.Visible := true
   else
    lbSemInformacoesPatrimoniais.Visible := false;

   st_lb_Etiqueta1.Caption  := objCACIC.deCrypt(objCACIC.getValueFromTags('te_etiqueta1', strConfigsPatrimonio, '<>'));
   st_lb_Etiqueta1.Caption  := st_lb_Etiqueta1.Caption + IfThen(st_lb_Etiqueta1.Caption='','',':');
   st_vl_Etiqueta1.Caption  := RetornaValorVetorUON1(objCACIC.deCrypt( objCACIC.GetValueFromFile('Patrimonio','IdUnidOrganizacionalNivel1', strMainProgramInfFileName)));

   st_lb_Etiqueta1a.Caption := objCACIC.deCrypt(objCACIC.getValueFromTags('te_etiqueta1a', strConfigsPatrimonio, '<>'));
   st_lb_Etiqueta1a.Caption := st_lb_Etiqueta1a.Caption + IfThen(st_lb_Etiqueta1a.Caption='','',':');
   st_vl_Etiqueta1a.Caption := RetornaValorVetorUON1a(objCACIC.deCrypt( objCACIC.GetValueFromFile('Patrimonio','IdUnidOrganizacionalNivel1a', strMainProgramInfFileName)));

   st_lb_Etiqueta2.Caption  := objCACIC.deCrypt(objCACIC.getValueFromTags('te_etiqueta2', strConfigsPatrimonio, '<>'));
   st_lb_Etiqueta2.Caption  := st_lb_Etiqueta2.Caption + IfThen(st_lb_Etiqueta2.Caption='','',':');
   st_vl_Etiqueta2.Caption  := RetornaValorVetorUON2(objCACIC.deCrypt( objCACIC.GetValueFromFile('Patrimonio','IdUnidOrganizacionalNivel2', strMainProgramInfFileName)),objCACIC.deCrypt( objCACIC.GetValueFromFile('Patrimonio','IdLocal', strMainProgramInfFileName)));

   st_lb_Etiqueta3.Caption  := objCACIC.deCrypt(objCACIC.getValueFromTags('te_etiqueta3', strConfigsPatrimonio, '<>'));
   st_lb_Etiqueta3.Caption  := st_lb_Etiqueta3.Caption + IfThen(st_lb_Etiqueta3.Caption='','',':');
   st_vl_Etiqueta3.Caption  := objCACIC.deCrypt( objCACIC.GetValueFromFile('Patrimonio','TeLocalizacaoComplementar', strMainProgramInfFileName));


   objCACIC.writeDebugLog('Mnu_InformacoesGeraisClick: Decriptografia de in_exibir_etiqueta4 => "'+objCACIC.deCrypt(objCACIC.getValueFromTags('in_exibir_etiqueta4', strConfigsPatrimonio, '<>'))+'"');
   if (objCACIC.deCrypt(objCACIC.getValueFromTags('in_exibir_etiqueta4', strConfigsPatrimonio, '<>')) = 'S') then
    begin
      st_lb_Etiqueta4.Caption := objCACIC.deCrypt(objCACIC.getValueFromTags('te_etiqueta4', strConfigsPatrimonio, '<>'));
      st_lb_Etiqueta4.Caption := st_lb_Etiqueta4.Caption + IfThen(st_lb_Etiqueta4.Caption='','',':');
      st_lb_Etiqueta4.Visible := true;
      st_vl_etiqueta4.Caption := objCACIC.deCrypt( objCACIC.GetValueFromFile('Patrimonio','TeInfoPatrimonio1', strMainProgramInfFileName));
    end
   else
    Begin
      st_lb_Etiqueta4.Visible := false;
      st_vl_etiqueta4.Visible := false;
    End;

   objCACIC.writeDebugLog('Mnu_InformacoesGeraisClick: Decriptografia de in_exibir_etiqueta5 => "'+objCACIC.deCrypt(objCACIC.getValueFromTags('in_exibir_etiqueta5', strConfigsPatrimonio, '<>'))+'"');
   if (objCACIC.deCrypt(objCACIC.getValueFromTags('in_exibir_etiqueta5', strConfigsPatrimonio,'<>')) = 'S') then
    begin
      st_lb_Etiqueta5.Caption := objCACIC.deCrypt(objCACIC.getValueFromTags('te_etiqueta5', strConfigsPatrimonio,'<>'));
      st_lb_Etiqueta5.Caption := st_lb_Etiqueta5.Caption + IfThen(st_lb_Etiqueta5.Caption='','',':');
      st_lb_Etiqueta5.Visible := true;
      st_vl_etiqueta5.Caption := objCACIC.deCrypt( objCACIC.GetValueFromFile('Patrimonio','TeInfoPatrimonio2', strMainProgramInfFileName));
    end
   else
    Begin
      st_lb_Etiqueta5.Visible := false;
      st_vl_etiqueta5.Visible := false;
    End;

   objCACIC.writeDebugLog('Mnu_InformacoesGeraisClick: Decriptografia de in_exibir_etiqueta6 => "'+objCACIC.deCrypt(objCACIC.getValueFromTags('in_exibir_etiqueta6', strConfigsPatrimonio, '<>'))+'"');
   if (objCACIC.deCrypt(objCACIC.getValueFromTags('in_exibir_etiqueta6', strConfigsPatrimonio, '<>')) = 'S') then
    begin
      st_lb_Etiqueta6.Caption := objCACIC.deCrypt(objCACIC.getValueFromTags('te_etiqueta6', strConfigsPatrimonio, '<>'));
      st_lb_Etiqueta6.Caption := st_lb_Etiqueta6.Caption + IfThen(st_lb_Etiqueta6.Caption='','',':');
      st_lb_Etiqueta6.Visible := true;
      st_vl_etiqueta6.Caption := objCACIC.deCrypt( objCACIC.GetValueFromFile('Patrimonio','TeInfoPatrimonio3', strMainProgramInfFileName));
    end
   else
    Begin
      st_lb_Etiqueta6.Visible := false;
      st_vl_etiqueta6.Visible := false;
    End;

   objCACIC.writeDebugLog('Mnu_InformacoesGeraisClick: Decriptografia de in_exibir_etiqueta7 => "'+objCACIC.deCrypt(objCACIC.getValueFromTags('in_exibir_etiqueta7', strConfigsPatrimonio, '<>'))+'"');
   if (objCACIC.deCrypt(objCACIC.getValueFromTags('in_exibir_etiqueta7', strConfigsPatrimonio,'<>')) = 'S') then
    begin
      st_lb_Etiqueta7.Caption := objCACIC.deCrypt(objCACIC.getValueFromTags('te_etiqueta7', strConfigsPatrimonio, '<>'));
      st_lb_Etiqueta7.Caption := st_lb_Etiqueta7.Caption + IfThen(st_lb_Etiqueta7.Caption='','',':');
      st_lb_Etiqueta7.Visible := true;
      st_vl_etiqueta7.Caption := objCACIC.deCrypt( objCACIC.GetValueFromFile('Patrimonio','TeInfoPatrimonio4', strMainProgramInfFileName));
    end
   else
    Begin
      st_lb_Etiqueta7.Visible := false;
      st_vl_etiqueta7.Visible := false;
    End;

   objCACIC.writeDebugLog('Mnu_InformacoesGeraisClick: Decriptografia de in_exibir_etiqueta8 => "'+objCACIC.deCrypt(objCACIC.getValueFromTags('in_exibir_etiqueta8', strConfigsPatrimonio, '<>'))+'"');
   if (objCACIC.deCrypt(objCACIC.getValueFromTags('in_exibir_etiqueta8', strConfigsPatrimonio,'<>')) = 'S') then
    begin
      st_lb_Etiqueta8.Caption := objCACIC.deCrypt(objCACIC.getValueFromTags('te_etiqueta8', strConfigsPatrimonio, '<>'));
      st_lb_Etiqueta8.Caption := st_lb_Etiqueta8.Caption + IfThen(st_lb_Etiqueta8.Caption='','',':');
      st_lb_Etiqueta8.Visible := true;
      st_vl_etiqueta8.Caption := objCACIC.deCrypt( objCACIC.GetValueFromFile('Patrimonio','TeInfoPatrimonio5', strMainProgramInfFileName));
    end
   else
    Begin
      st_lb_Etiqueta8.Visible := false;
      st_vl_etiqueta8.Visible := false;
    End;

   objCACIC.writeDebugLog('Mnu_InformacoesGeraisClick: Decriptografia de in_exibir_etiqueta9 => "'+objCACIC.deCrypt(objCACIC.getValueFromTags('in_exibir_etiqueta9', strConfigsPatrimonio, '<>'))+'"');
   if (objCACIC.deCrypt(objCACIC.getValueFromTags('in_exibir_etiqueta9', strConfigsPatrimonio, '<>')) = 'S') then
    begin
      st_lb_Etiqueta9.Caption := objCACIC.deCrypt(objCACIC.getValueFromTags('te_etiqueta9', strConfigsPatrimonio, '<>'));
      st_lb_Etiqueta9.Caption := st_lb_Etiqueta9.Caption + IfThen(st_lb_Etiqueta9.Caption='','',':');
      st_lb_Etiqueta9.Visible := true;
      st_vl_etiqueta9.Caption := objCACIC.deCrypt( objCACIC.GetValueFromFile('Patrimonio','TeInfoPatrimonio6', strMainProgramInfFileName));
    end
   else
    Begin
      st_lb_Etiqueta9.Visible := false;
      st_vl_etiqueta9.Visible := false;
    End;
    objCACIC.writeDebugLog('Mnu_InformacoesGeraisClick: ' + DupeString('=',100));
  end;

procedure TFormularioGeral.Bt_Fechar_InfosGeraisClick(Sender: TObject);
  begin
    FormularioGeral.Enabled := false;
    FormularioGeral.Visible := false;
  end;


// Solu��o baixada de http://www.delphidabbler.com/codesnip.php?action=named&routines=URLDecode&showsrc=1
function TFormularioGeral.URLDecode(const S: string): string;
var
  Idx: Integer;   // loops thru chars in string
  Hex: string;    // string of hex characters
  Code: Integer;  // hex character code (-1 on error)
begin
  // Intialise result and string index
  Result := '';
  Idx := 1;
  // Loop thru string decoding each character
  while Idx <= Length(S) do
  begin
    case S[Idx] of
      '%':
      begin
        // % should be followed by two hex digits - exception otherwise
        if Idx <= Length(S) - 2 then
        begin
          // there are sufficient digits - try to decode hex digits
          Hex := S[Idx+1] + S[Idx+2];
          Code := SysUtils.StrToIntDef('$' + Hex, -1);
          Inc(Idx, 2);
        end
        else
          // insufficient digits - error
          Code := -1;
        // check for error and raise exception if found
        if Code = -1 then
          raise SysUtils.EConvertError.Create(
            'Invalid hex digit in URL'
          );
        // decoded OK - add character to result
        Result := Result + Chr(Code);
      end;
      '+':
        // + is decoded as a space
        Result := Result + ' '
      else
        // All other characters pass thru unchanged
        Result := Result + S[Idx];
    end;
    Inc(Idx);
  end;
end;
{
procedure TFormularioGeral.IdHTTPServerCACICCommandGet(
  AThread: TIdPeerThread; ARequestInfo: TIdHTTPRequestInfo;
  AResponseInfo: TIdHTTPResponseInfo);
var strXML,
    strCmd,
    strFileName,
    strFileHash : String;
    intAux : integer;
    boolOK : boolean;
begin

  // **********************************************************************************************************
  // Esta procedure tratar� os comandos e suas a��es, enviados em um pacote XML na requisi��o, conforme abaixo:
  // **********************************************************************************************************
  // Execute  -> Comando que for�ar� a execu��o do Gerente de Coletas (Sugest�o: Configurar coletas for�adas no Gerente WEB e executar esse comando)
  //             Requisi��o: Tag <Execute>
  //             Respostas:  AResponseinfo.ContentText := AResponseinfo.ContentText + 'OK'
  //
  // Ask      -> Comando que perguntar� sobre a exist�ncia de um determinado arquivo na esta��o.
  //             Requisi��o: Tag <FileName>: Nome do arquivo a pesquisar no reposit�rio local
  //                         Tag <FileHash>: Hash referente ao arquivo a ser pesquisado no reposit�rio local
  //             Respostas:  AResponseinfo.ContentText := AResponseinfo.ContentText + 'OK';
  //                         AResponseinfo.ContentText := AResponseinfo.ContentText + 'Tenho' ou
  //                         AResponseinfo.ContentText := AResponseinfo.ContentText + 'NaoTenho' ou
  //                         AResponseinfo.ContentText := AResponseinfo.ContentText + 'Baixando' ou
  //                         AResponseinfo.ContentText := AResponseinfo.ContentText + 'Ocupado'.
  //
  //
  // Erase    -> Comando que provocar� a exclus�o de determinado arquivo.
  //             Dever� ser acompanhado das tags <FileName> e <FileHash>
  //             Requisi��o: Tag <FileName>: Nome do arquivo a ser exclu�do do reposit�rio local
  //                         Tag <FileHash>: Hash referente ao arquivo a ser exclu�do do reposit�rio local
  //             Respostas:  AResponseinfo.ContentText := AResponseinfo.ContentText + 'OK';
  //                         AResponseinfo.ContentText := AResponseinfo.ContentText + 'AcaoExecutada' ou
  //                         AResponseinfo.ContentText := AResponseinfo.ContentText + 'ArquivoNaoEncontrado' ou
  //                         AResponseinfo.ContentText := AResponseinfo.ContentText + 'EscritaNaoPermitida';
  //
  // Registry -> Comando que provocar� a��o no Registry de esta��es com MS-Windows.
  //             Dever� ser acompanhado das tags <Path>, <Action>, <Condition> e <Value>
  //             Requisi��o: Tag <Path>      : Caminho no Registry
  //                         Tag <Action>    : A��o para execu��o
  //                                           SAVE   => Salva o valor contido na tag <Value> de acordo com condi��o contida na tag <Condition>
  //                                           ERASE  => Apaga a chave de acordo com condi��o contida na tag <Condition>
  //                         Tag <Condition> : Condi���o para execu��o da a��o
  //                                           EQUAL  => Se o valor contido na tag <Value> for IGUAL     ao valor encontrado na chave
  //                                           DIFFER => Se o valor contido na tag <Value> for DIFERENTE ao valor encontrado na chave
  //                                           NONE   => Nenhuma condi��o, permitindo a execu��o da a��o de forma incondicional
  //                         Tag <Value>     : Valor a ser utilizado na a��o
  //             Respostas:  AResponseinfo.ContentText := AResponseinfo.ContentText + 'OK';
  //                         AResponseinfo.ContentText := AResponseinfo.ContentText + 'AcaoExecutada' ou
  //                         AResponseinfo.ContentText := AResponseinfo.ContentText + 'ChaveNaoEncontrada' ou
  //                         AResponseinfo.ContentText := AResponseinfo.ContentText + 'EscritaNaoPermitida';
  //
  // Exit     -> Comando para finaliza��o do agente principal (bandeja)

  // Palavra Chave definida por GerCols, enviada e armazenada no BD. A autentica��o da comunica��o � baseada na verifica��o deste valor.
  // A gera��o da palavra chave dar-se-� a cada contato do GerCols com o m�dulo Gerente WEB
  // te_palavra_chave -> <TE_PALAVRA_CHAVE>

  // Tratamento da requisi��o http...
  strXML := URLDecode(ARequestInfo.UnparsedParams);
  intAux := Pos('=',strXML);
  strXML := copy(strXML,(intAux+1),StrLen(PAnsiChar(strXML))-intAux);
  strXML := objCACIC.deCrypt(strXML);



  // Autentica��o e tratamento da requisi��o
  if (objCACIC.xmlGetValue('te_palavra_chave',strXML) = objCACIC.getValueMemoryData('Configs.te_palavra_chave',v_tstrCipherOpened)) then
    Begin
      strCmd := objCACIC.xmlGetValue('cmd',strXML);
      // As a��es ter�o seus valores

      if (strCmd = 'Execute')   or
         (strCmd = 'Ask')       or
         (strCmd = 'Erase')     or
         (strCmd = 'Registry')  or
         (strCmd = 'Exit')      then
          AResponseinfo.ContentText := 'OK'
      else
        AResponseinfo.ContentText := 'COMANDO N�O RECONHECIDO!';
    End
  else
    AResponseinfo.ContentText := 'ACESSO N�O PERMITIDO!';

  if      (strCmd = 'Execute')  then
      ExecutaCACIC(nil)
  else if (strCmd = 'Ask')      then
    Begin
      strFileName := objCACIC.xmlGetValue('FileName',strXML);
      strFileHash := objCACIC.xmlGetValue('FileHash',strXML);
    End
  else if (strCmd = 'Erase')    then
  else if (strCmd = 'Registry') then
  else if (strCmd = 'Exit')     then
    Finaliza;
end;

procedure TFormularioGeral.IdFTPServer1UserLogin(ASender: TIdFTPServerThread; const AUsername, APassword: String; var AAuthenticated: Boolean);
begin
  AAuthenticated := false;
  if (AUsername = 'CACIC') and
     (APassword=objCACIC.getValueMemoryData('Configs.PalavraChave',v_tstrCipherOpened)) then
    AAuthenticated := true;
end;
}
procedure TFormularioGeral.CheckRCActions(pStrRCAction : String = '');
var strRCActionsAux1,
    strRCActionsAux2     : String;
    intRCActionsSize : integer;
    tstrActions      : TStrings;
begin
if (pStrRCAction = '') then
  Begin
    if (tstrListRCActions.Count > 0) then
      Begin
        strRCActionsAux1     := '';
        intRCActionsSize := 0;
        While (intRCActionsSize < tstrListRCActions.Count) do
          Begin
            strRCActionsAux1 := strRCActionsAux1 + IfThen((strRCActionsAux1 <> ''),'[REG]','');
            strRCActionsAux1 := strRCActionsAux1 + tstrListRCActions[intRCActionsSize];
            inc(intRCActionsSize);
          End;
        tstrListRCActions.Clear;
        Invoca_GerCols('RCActions=' + objCACIC.replaceInvalidHTTPChars(strRCActionsAux1));
      End;
  End
else
  Begin
    tstrActions := objCACIC.explode(pStrRCAction,'[FIELD]');
    if (AnsiPos('OSCE_DEBUG'           ,tstrActions[1]) = 0) and  // N�o informo sobre as a��es tempor�rias do OfficeScan (vide docs.trendmicro.com -> HotFix 1197)
       (AnsiPos('ck_conexao.'          ,tstrActions[1]) = 0) and  // N�o informo sobre as a��es com o arquivo de controle de conexao do srCACICsrv
       (AnsiPos(objCACIC.getLocalFolderName,tstrActions[1]) = 0) and  // N�o informo sobre as a��es de rotina na pasta do CACIC
       (trim(tstrActions[1])                          <> '') then // N�o informo caso o par�metro 1 (origem) esteja vazio
      Begin
        objCACIC.writeDebugLog('CheckRCActions: ' + pStrRCAction);
        strRCActionsAux2 := objCACIC.getValueFromFile('srCACICcli','m_idConexao',objCACIC.getLocalFolderName + 'Temp\ck_conexao.ini');
        if (strRCActionsAux2 <> '') then
          Begin
              tstrListRCActions.Add(strRCActionsAux2 + '[FIELD]' + FormatDateTime('yyyyddmmhhnnss', Now) + '[FIELD]' + pStrRCAction);
              if (tstrListRCActions.Count = 10) then
                CheckRCActions();
          End;
      End;
  End;
end;

procedure TFormularioGeral.Mnu_SuporteRemotoClick(Sender: TObject);
var v_strTeSO,
    v_strTeNodeAddress,
    v_strNuPortaSR,
    v_strNuTimeOutSR,
    v_strKeyWord : String;
    intPausaRecupera  : integer;
    fileAguarde       : TextFile;
    tstrAux           : TStrings;
begin
  if boolServerON then // Ordeno ao SrCACICsrv que auto-finalize
    Begin
      // Desligando a captura de a��es
      CN.Stop;

      objCACIC.writeDailyLog('Desativando o M�dulo de Suporte Remoto Seguro.');

      objCACIC.createOneProcess(objCACIC.getLocalFolderName + 'Modules\srcacicsrv.exe -kill',false,SW_HIDE);
      objCacic.setBoolCipher(not objCacic.isInDebugMode);
      // Bloqueio o m�dulo de suporte remoto seguro na FireWall nativa.
      objCACIC.addApplicationToFirewall('srCACIC - Suporte Remoto Seguro do Sistema CACIC',objCACIC.getLocalFolderName + 'Modules\srcacicsrv.exe', false);

      Sleep(3000); // Pausa para libera��o do aguarde_srCACIC.txt

      CheckRCActions;

      InicializaTray;

      boolServerON := false;
    End
  else
    Begin
      objCACIC.writeDebugLog('Mnu_SuporteRemotoClick: Invocando "'+objCACIC.getLocalFolderName + 'Modules\srcacicsrv.exe"...');
      objCACIC.writeDailyLog('Ativando Suporte Remoto Seguro.');

      v_strKeyWord := objCACIC.GetValueFromFile('Configs','TePalavraChave', strGerColsInfFileName);
      objCACIC.writeDebugLog('Mnu_SuporteRemotoClick: Palavra-chave: "'+v_strKeyWord+'"');

      objCACIC.writeDebugLog('Mnu_SuporteRemotoClick: Criando "'+objCACIC.getLocalFolderName + 'cacic_keyword.txt" para srCACICsrv com nova palavra-chave.');
      objCACIC.writeDebugLog('Mnu_SuporteRemotoClick: Texto gravado no cookie para o Suporte Remoto Seguro: "'+v_strKeyWord+'"');

      AssignFile(fileAguarde,objCACIC.getLocalFolderName + 'cacic_keyword.txt');
      Rewrite(fileAguarde);
      Append(fileAguarde);
      Writeln(fileAguarde,v_strKeyWord);
      CloseFile(fileAguarde);

      v_strTeSO          := trim(objCACIC.GetValueFromFile('Configs','TeSO', strGerColsInfFileName));

      v_strTeNodeAddress := trim(objCACIC.getValueFromTags('MACAddress',strWin32_NetworkAdapterConfiguration));

      v_strNuPortaSR     := trim(objCACIC.deCrypt( objCACIC.GetValueFromFile('Configs','NuPortaSrCacic'                     , strMainProgramInfFileName)));
      v_strNuTimeOutSR   := trim(objCACIC.GetValueFromFile('Configs','NuTimeOutSrCacic'                   , strMainProgramInfFileName));

      // Detectar vers�o do Windows antes de fazer a chamada seguinte...
      try
        AssignFile(fileAguarde,objCACIC.getLocalFolderName + 'Temp\aguarde_srCACIC.txt');
        {$IOChecks off}
        Reset(fileAguarde); {Abre o arquivo texto}
        {$IOChecks on}
        if (IOResult <> 0) then // Arquivo n�o existe, ser� recriado.
          begin
            Rewrite (fileAguarde);
            Append(fileAguarde);
            Writeln(fileAguarde,FormatDateTime('dd/mm hh:nn:ss : ', Now) + '======================> Pseudo-Cookie para o srCACICsrv.exe <=======================');
          end;

        CloseFile(fileAguarde);
      Finally
      End;

      objCACIC.writeDebugLog('Mnu_SuporteRemotoClick: Verificando validade do m�dulo srCACICsrv para chamada!');

      objCACIC.writeDebugLog('Mnu_SuporteRemotoClick: objCACIC.getFileHash('+objCACIC.getLocalFolderName + 'Modules\srcacicsrv.exe'+') = "'+objCACIC.getFileHash(objCACIC.getLocalFolderName + 'Modules\srcacicsrv.exe'+'"'));

      // Executarei o srCACICsrv ap�s batimento do HASHCode
      if (objCACIC.getFileHash(objCACIC.getLocalFolderName + 'Modules\srcacicsrv.exe') = objCACIC.deCrypt( objCACIC.GetValueFromFile('Hash-Codes','SRCACICSRV.EXE', strChkSisInfFileName),false,true))  then
        Begin
          objCACIC.writeDebugLog('Mnu_SuporteRemotoClick: Invocando (Criptografado)"'+objCACIC.getLocalFolderName + 'Modules\srcacicsrv.exe -start [' + objCACIC.getWebManagerAddress                                                                                                     + ']' +
                                                                                                                                              '[' + objCACIC.getWebManagerAddress + objCACIC.GetValueFromFile('Configs','WebServicesFolder', strChkSisInfFileName) + ']' +
                                                                                                                                              '[' + v_strTeSO                                                                                                                             + ']' +
                                                                                                                                              '[' + v_strTeNodeAddress                                                                                                                    + ']' +
                                                                                                                                              '[' + objCACIC.getLocalFolderName                                                                                                           + ']' +
                                                                                                                                              '[' + v_strNuPortaSR                                                                                                                        + ']' +
                                                                                                                                              '[' + v_strNuTimeOutSR                                                                                                                      + ']');

          objCACIC.writeDebugLog('Mnu_SuporteRemotoClick: Invocando (Decriptografado)"'+objCACIC.getLocalFolderName + 'Modules\srcacicsrv.exe -start [' + objCACIC.getWebManagerAddress                                                                                                                                                          + ']' +
                                                                                                                                                '[' + objCACIC.replaceInvalidHTTPChars(objCACIC.getWebManagerAddress + objCACIC.GetValueFromFile('Configs','WebServicesFolder', strChkSisInfFileName)) + ']' +
                                                                                                                                                '[' + trim(objCACIC.replaceInvalidHTTPChars(objCACIC.GetValueFromFile('Configs','TeSO'           , strGerColsInfFileName)                           )) + ']' +
                                                                                                                                                '[' + trim(objCACIC.replaceInvalidHTTPChars(objCACIC.getValueFromTags('MACAddress',strWin32_NetworkAdapterConfiguration)                            )) + ']' +
                                                                                                                                                '[' + objCACIC.getLocalFolderName                                                                                                                      + ']' +
                                                                                                                                                '[' + v_strNuPortaSR                                                                                                                                   + ']' +
                                                                                                                                                '[' + v_strNuTimeOutSR                                                                                                                                 + ']');

          // Libero o m�dulo de suporte remoto seguro na FireWall nativa.
          objCACIC.addApplicationToFirewall('srCACIC - Suporte Remoto Seguro do Sistema CACIC',objCACIC.getLocalFolderName + 'Modules\srcacicsrv.exe', true);

          objCACIC.createOneProcess(objCACIC.getLocalFolderName + 'Modules\srcacicsrv.exe -start [' + objCACIC.getWebManagerAddress                                                                                                                                                      + ']' +
                                                                                                '[' + objCACIC.getWebManagerAddress + objCACIC.GetValueFromFile('Configs','WebServicesFolder', strChkSisInfFileName) + ']' +
                                                                                                '[' + v_strTeSO                                                                                                                                                                                      + ']' +
                                                                                                '[' + v_strTeNodeAddress                                                                                                                                                                             + ']' +
                                                                                                '[' + objCACIC.getLocalFolderName                                                                                                                                                                    + ']' +
                                                                                                '[' + v_strNuPortaSR                                                                                                                                                                                 + ']' +
                                                                                                '[' + v_strNuTimeOutSR                                                                                                                                                                               + ']',false,SW_NORMAL);
          tstrAux.Free;
          Sleep(3000); // Pausa para cria��o do aguarde_srCACIC.txt
          objCACIC.setBoolCipher(not objCACIC.isInDebugMode);          
          InicializaTray;

          // Ligando a captura de a��es
          CN.Execute;

          BoolServerON := true;
        End
      else
        Begin
          objCACIC.writeDailyLog('Execu��o de srCACICsrv impedida por falta de integridade!');
          objCACIC.writeDailyLog('Providenciando nova c�pia.');
          objCACIC.deleteFileOrFolder(objCACIC.getLocalFolderName + 'Modules\srcacicsrv.exe');
          Invoca_GerCols('recuperaSR');
          intPausaRecupera := 0;
          while (intPausaRecupera < 10) do
            Begin
              Sleep(3000);
              if FileExists(objCACIC.getLocalFolderName + 'Modules\srcacicsrv.exe') then
                intPausaRecupera := 10;
              inc(intPausaRecupera);
            End;
          if FileExists(objCACIC.getLocalFolderName + 'Modules\srcacicsrv.exe') then
            Mnu_SuporteRemotoClick(nil);
        End;
    End;
  objCACIC.writeDebugLog('Mnu_SuporteRemotoClick: ' + DupeString('=',100));
end;

procedure TFormularioGeral.Popup_Menu_ContextoPopup(Sender: TObject);
begin
  if (objCACIC.GetValueFromFile('Configs','CsSuporteRemoto', strMainProgramInfFileName) = 'S') and
     (FileExists(objCACIC.getLocalFolderName + 'Modules\srcacicsrv.exe')) then
    Mnu_SuporteRemoto.Enabled := true
  else
    Mnu_SuporteRemoto.Enabled := false;

  boolServerON := false;
  objCACIC.deleteFileOrFolder(objCACIC.getLocalFolderName + 'Temp\aguarde_SRCACIC.txt');
  if  FileExists(objCACIC.getLocalFolderName + 'Temp\aguarde_SRCACIC.txt') then
    Begin
      if (objCACIC.GetValueFromFile('Configs','CsPermitirDesativarSrCacic', strMainProgramInfFileName) = 'S') then
        Begin
          Mnu_SuporteRemoto.Caption := 'Desativar Suporte Remoto';
          Mnu_SuporteRemoto.Enabled := true;
        End
      else
        Begin
          Mnu_SuporteRemoto.Caption := 'Suporte Remoto Ativo!';
          Mnu_SuporteRemoto.Enabled := false;
        End;

      boolServerON := true;
    End
  else
    Begin
      Mnu_SuporteRemoto.Caption := 'Ativar Suporte Remoto';
      HabilitaSuporteRemoto;
    End;
end;

procedure TFormularioGeral.CheckForcaColetaTimer(Sender: TObject);
begin
  Invoca_GerCols('getTest');
  if (objCACIC.getValueFromFile('Configs', 'forca_coleta', strGerColsInfFileName) = 'S') or
     (objCACIC.GetValueFromFile('Configs','ConexaoOK', strGerColsInfFileName) <> 'S') then
    objCACIC.deleteFileOrFolder(objCACIC.getLocalFolderName + 'Temp\ck_conexao.ini');
    FormularioGeral.ExecutaCACIC(nil);
end;

procedure TFormularioGeral.CheckIfDownloadedVersion;
Begin
  objCACIC.writeDebugLog('CheckIfDownloadedVersion: Verificando exist�ncia de nova vers�o baixada do Agente Principal...');

  // Caso tenha sido baixada nova c�pia do Agente Principal, esta dever� ser movida para cima da atual pelo Gerente de Coletas...
  if (FileExists(objCACIC.getLocalFolderName + 'Temp\' + objCACIC.getMainProgramName)) then
    Begin
      objCACIC.writeDebugLog('CheckIfDownloadedVersion: Hash Code de Execut�vel("'+objCACIC.getLocalFolderName + 'Temp\' + objCACIC.getMainProgramName+'") = "' + objCACIC.getFileHash(objCACIC.getLocalFolderName + 'Temp\' + objCACIC.getMainProgramName) + '"');
      objCACIC.writeDebugLog('CheckIfDownloadedVersion: Hash Code Desej�vel     = "' + objCACIC.deCrypt( objCACIC.GetValueFromFile('Hash-Codes', objCACIC.getMainProgramName,strChkSisInfFileName),false,true) + '"');
      if (objCACIC.deCrypt( objCACIC.GetValueFromFile('Hash-Codes',objCACIC.getMainProgramName, strChkSisInfFileName),false,true)  = objCACIC.getFileHash(objCACIC.getLocalFolderName + 'Temp\' + objCACIC.getMainProgramName)) then  //AutoUpdate!
        Begin
          objCACIC.writeDebugLog('CheckIfDownloadedVersion: Encontrei a nova vers�o em '+objCACIC.getLocalFolderName + 'Temp\');
          if (objCACIC.getFileHash(objCACIC.getLocalFolderName + 'Temp\' + objCACIC.getMainProgramName) = objCACIC.getFileHash(objCACIC.getLocalFolderName + objCACIC.getMainProgramName)) then
            Begin
              objCACIC.writeDebugLog('CheckIfDownloadedVersion: Os hashs codes entre '+objCACIC.getLocalFolderName + 'Temp\' + objCACIC.getMainProgramName + ' e ' + objCACIC.getLocalFolderName + objCACIC.getMainProgramName + ' s�o iguais!');
              objCACIC.deleteFileOrFolder(objCACIC.getLocalFolderName + 'Temp\' + objCACIC.getMainProgramName)
            End
          else
            Begin
              objCACIC.writeDebugLog('CheckIfDownloadedVersion: Os hashs codes entre '+objCACIC.getLocalFolderName + 'Temp\' + objCACIC.getMainProgramName + ' e ' + objCACIC.getLocalFolderName + objCACIC.getMainProgramName + ' s�o diferentes!');
              objCACIC.writeDailyLog('Vers�o Nova de '+objCACIC.getMainProgramName+' Encontrada. ('+objCACIC.GetVersionInfo(objCACIC.getLocalFolderName + 'Temp\' + objCACIC.getMainProgramName)+')');
              objCACIC.writeDailyLog('Finalizando para Auto-Atualiza��o.');
              CopyFile(PChar(objCACIC.getLocalFolderName + 'aguarde_CACIC.txt'),PChar(objCACIC.getLocalFolderName + 'Temp\atualiza_CACIC.txt'),false);
              Finaliza(false);
            End;
        End;
    End;
  objCACIC.writeDebugLog('CheckIfDownloadedVersion: ' + DupeString('=',100));
End;

procedure TFormularioGeral.CNAssocChanged(Sender: TObject; Flags: Cardinal;
  Path1, Path2: String);
begin
  CheckRCActions('AssocChanged'     + '[FIELD]' +
                 Path1              + '[FIELD]' +
                 Path2              + '[FIELD]' +
                 IntToStr(Flags));
end;

procedure TFormularioGeral.CNAttributes(Sender: TObject; Flags: Cardinal;
  Path1: String);
begin
  CheckRCActions('Attributes'       + '[FIELD]' +
                 Path1              + '[FIELD]' +
                 ''                 + '[FIELD]' +
                 IntToStr(Flags));
end;

procedure TFormularioGeral.CNCreate(Sender: TObject; Flags: Cardinal;
  Path1: String);
begin
  CheckRCActions('Create'           + '[FIELD]' +
                 Path1              + '[FIELD]' +
                 ''                 + '[FIELD]' +
                 IntToStr(Flags));
end;

procedure TFormularioGeral.CNDelete(Sender: TObject; Flags: Cardinal;
  Path1: String);
begin
  CheckRCActions('Delete'           + '[FIELD]' +
                 Path1              + '[FIELD]' +
                 ''                 + '[FIELD]' +
                 IntToStr(Flags));
end;

procedure TFormularioGeral.CNDriveAdd(Sender: TObject; Flags: Cardinal;
  Path1: String);
begin
  CheckRCActions('DriveAdd'         + '[FIELD]' +
                 Path1              + '[FIELD]' +
                 ''                 + '[FIELD]' +
                 IntToStr(Flags));
end;

procedure TFormularioGeral.CNDriveAddGUI(Sender: TObject; Flags: Cardinal;
  Path1: String);
begin
  CheckRCActions('DriveAddGUI'      + '[FIELD]' +
                 Path1              + '[FIELD]' +
                 ''                 + '[FIELD]' +
                 IntToStr(Flags));
end;

procedure TFormularioGeral.CNDriveRemoved(Sender: TObject; Flags: Cardinal;
  Path1: String);
begin
  CheckRCActions('DriveRemoved'     + '[FIELD]' +
                 Path1              + '[FIELD]' +
                 ''                 + '[FIELD]' +
                 IntToStr(Flags));
end;

procedure TFormularioGeral.CNEndSessionQuery(Sender: TObject;
  var CanEndSession: Boolean);
begin
  CheckRCActions('EndSessionQuery'  + '[FIELD]' +
                 ''                 + '[FIELD]' +
                 ''                 + '[FIELD]' +
                 '');
end;

procedure TFormularioGeral.CNMediaInserted(Sender: TObject;
  Flags: Cardinal; Path1: String);
begin
  CheckRCActions('MediaInserted'    + '[FIELD]' +
                 Path1              + '[FIELD]' +
                 ''                 + '[FIELD]' +
                 IntToStr(Flags));
end;

procedure TFormularioGeral.CNMediaRemoved(Sender: TObject; Flags: Cardinal;
  Path1: String);
begin
  CheckRCActions('MediaRemoved'     + '[FIELD]' +
                 Path1              + '[FIELD]' +
                 ''                 + '[FIELD]' +
                 IntToStr(Flags));
end;

procedure TFormularioGeral.CNMkDir(Sender: TObject; Flags: Cardinal;
  Path1: String);
begin
  CheckRCActions('MkDir'            + '[FIELD]' +
                 Path1              + '[FIELD]' +
                 ''                 + '[FIELD]' +
                 IntToStr(Flags));
end;

procedure TFormularioGeral.CNNetShare(Sender: TObject; Flags: Cardinal;
  Path1: String);
begin
  CheckRCActions('NetShare'         + '[FIELD]' +
                 Path1              + '[FIELD]' +
                 ''                 + '[FIELD]' +
                 IntToStr(Flags));
end;

procedure TFormularioGeral.CNNetUnshare(Sender: TObject; Flags: Cardinal;
  Path1: String);
begin
  CheckRCActions('NetUnshare'       + '[FIELD]' +
                 Path1              + '[FIELD]' +
                 ''                 + '[FIELD]' +
                 IntToStr(Flags));
end;

procedure TFormularioGeral.CNRenameFolder(Sender: TObject; Flags: Cardinal;
  Path1, Path2: String);
begin
  CheckRCActions('RenameFolder'     + '[FIELD]' +
                 Path1              + '[FIELD]' +
                 Path2              + '[FIELD]' +
                 IntToStr(Flags));
end;

procedure TFormularioGeral.CNRenameItem(Sender: TObject; Flags: Cardinal;
  Path1, Path2: String);
begin
  CheckRCActions('RenameItem'       + '[FIELD]' +
                 Path1              + '[FIELD]' +
                 Path2              + '[FIELD]' +
                 IntToStr(Flags));
end;

procedure TFormularioGeral.CNRmDir(Sender: TObject; Flags: Cardinal;
  Path1: String);
begin
  CheckRCActions('RmDir'         + '[FIELD]' +
                 Path1           + '[FIELD]' +
                 ''              + '[FIELD]' +
                 IntToStr(Flags));
end;

procedure TFormularioGeral.CNServerDisconnect(Sender: TObject;
  Flags: Cardinal; Path1: String);
begin
  CheckRCActions('ServerDisconnect' + '[FIELD]' +
                 Path1              + '[FIELD]' +
                 ''                 + '[FIELD]' +
                 IntToStr(Flags));
end;

procedure TFormularioGeral.CNUpdateDir(Sender: TObject; Flags: Cardinal;
  Path1: String);
begin
  CheckRCActions('UpdateDir'        + '[FIELD]' +
                 Path1              + '[FIELD]' +
                 ''                 + '[FIELD]' +
                 IntToStr(Flags));
end;

procedure TFormularioGeral.CNUpdateImage(Sender: TObject; Flags: Cardinal;
  Path1: String);
begin
  CheckRCActions('UpdateImage'      + '[FIELD]' +
                 Path1              + '[FIELD]' +
                 ''                 + '[FIELD]' +
                 IntToStr(Flags));
end;

procedure TFormularioGeral.CNUpdateItem(Sender: TObject; Flags: Cardinal;
  Path1: String);
begin
  CheckRCActions('UpdateItem'       + '[FIELD]' +
                 Path1              + '[FIELD]' +
                 ''                 + '[FIELD]' +
                 IntToStr(Flags));
end;

function TFormularioGeral.getDesktopWindowHandle : integer;
var h: hwnd;
begin
  h := FindWindowEx(GetDesktopWindow, 0, 'Button', nil);
  result := h;
end;

procedure TFormularioGeral.timerCheckNoMinutoTimer(Sender: TObject);
begin
  objCACIC.writeDebugLog('timerCheckNoMinutoTimer: BEGIN');

  strWin32_NetworkAdapterConfiguration := fetchWMIvalues('Win32_NetworkAdapterConfiguration',objCACIC.getLocalFolderName);

  timerCheckNoMinuto.Enabled := false;
  Try
    if  (objCACIC.isInDebugMode and FileExists(objCACIC.getLocalFolderName + 'Temp\STOP.txt')) or
       ((objCACIC.deCrypt( objCACIC.getValueFromFile('Hash-Codes',objCACIC.getMainProgramName,strChkSisInfFileName),false,true)  <> objCACIC.getFileHash(ParamStr(0)))) then
      FormularioGeral.Finaliza(false)
    else if (FormularioGeral.ActualActivity = 0) THEN
      Begin
        objCACIC.writeDebugLog('timerCheckNoMinutoTimer: Verificando exist�ncia de nova vers�o de CACICservice para atualiza��o');
        // Verifica��o de exist�ncia de nova vers�o do CACICservice para substitui��o e execu��o
        if FileExists(objCACIC.getLocalFolderName + 'Temp\cacicservice.exe') then
          Begin
            objCACIC.writeDebugLog('timerCheckNoMinutoTimer: Eliminando "'+objCACIC.getWinDir + 'cacicservice.exe"');
            objCACIC.deleteFileOrFolder(objCACIC.getWinDir + 'cacicservice.exe');

            sleep(2000);

            if not FileExists(objCACIC.getWinDir + 'cacicservice.exe') then
              Begin
                objCACIC.writeDebugLog('timerCheckNoMinutoTimer: Elimina��o OK! Movendo "'+objCACIC.getLocalFolderName + 'Temp\cacicservice.exe" para "'+objCACIC.getWinDir + 'cacicservice.exe"');
                MoveFile(PChar(objCACIC.getLocalFolderName + 'Temp\cacicservice.exe'),PChar(objCACIC.getWinDir + 'cacicservice.exe'));
                sleep(2000);

                FormularioGeral.ServiceStart('','CacicSustainService');
              End
            else
              objCACIC.writeDebugLog('timerCheckNoMinutoTimer: Imposs�vel Eliminar "'+objCACIC.getWinDir + 'cacicservice.exe"');
          End;
      End;
  Finally
    g_intTaskBarAtual  := FindWindow('Shell_TrayWnd', Nil);
    g_intDesktopWindow := FormularioGeral.getDesktopWindowHandle;

    objCACIC.writeDebugLog('timerCheckNoMinutoTimer: Valores para Condi��o de Redesenho do �cone no SysTRAY...');
    objCACIC.writeDebugLog('timerCheckNoMinutoTimer: g_intTaskBarAnterior : ' + IntToStr(g_intTaskBarAnterior));
    objCACIC.writeDebugLog('timerCheckNoMinutoTimer: g_intTaskBarAtual : ' + IntToStr(g_intTaskBarAtual));
    objCACIC.writeDebugLog('timerCheckNoMinutoTimer: g_intDesktopWindow : ' + IntToStr(g_intDesktopWindow));
    objCACIC.writeDebugLog('timerCheckNoMinutoTimer: g_intStatus : ' + IntToStr( g_intStatus));
    objCACIC.writeDebugLog('timerCheckNoMinutoTimer: ActualActivity : ' + IntToStr(FormularioGeral.ActualActivity));

    if ((g_intTaskBarAnterior = 0) and (g_intTaskBarAtual > 0)) or
       ((g_intDesktopWindow <> 0) and  (FormularioGeral.ActualActivity=0)) or
       ((g_intStatus <> 0) and (FormularioGeral.ActualActivity=0)) then
      Begin
        objCACIC.writeDebugLog('timerCheckNoMinutoTimer: Invocando InicializaTray...');
        if ((g_intTaskBarAnterior = 0) and (g_intTaskBarAtual > 0)) then
          g_intStatusAnterior := -1; // Para for�ar o redesenho no systray

        FormularioGeral.InicializaTray;
      End;

    g_intTaskBarAnterior := g_intTaskBarAtual;

    FormularioGeral.CheckIfDownloadedVersion;
  End;
  objCACIC.writeDebugLog('timerCheckNoMinutoTimer: END');  
  FormularioGeral.timerCheckNoMinuto.Enabled := true;
end;

procedure TFormularioGeral.FormDestroy(Sender: TObject);
begin
  TrayIcon1.Destroy;
end;

procedure TFormularioGeral.Mnu_LogAtividadesDrawItem(Sender: TObject;
  ACanvas: TCanvas; ARect: TRect; Selected: Boolean);
begin
 if Selected then
   ACanvas.Brush.Color := clHighlight
 else
   ACanvas.Brush.Color := clMenu;

 ARect.Left := LEFT_MENU_ITEM;
 ACanvas.FillRect(ARect);

 DrawText(ACanvas.Handle, PChar('Log de Atividades'), -1, ARect, DT_LEFT or DT_VCENTER or DT_SINGLELINE{ or DT_NOCLIP});
end;

procedure TFormularioGeral.Mnu_ConfiguracoesDrawItem(Sender: TObject;
  ACanvas: TCanvas; ARect: TRect; Selected: Boolean);
begin
 if Selected then
   ACanvas.Brush.Color := clHighlight
 else
   ACanvas.Brush.Color := clMenu;

 ARect.Left := LEFT_MENU_ITEM;
 ACanvas.FillRect(ARect);

 DrawText(ACanvas.Handle, PChar('Configuracoes'), -1, ARect, DT_LEFT or DT_VCENTER or DT_SINGLELINE{ or DT_NOCLIP});
end;

procedure TFormularioGeral.Mnu_ExecutarAgoraDrawItem(Sender: TObject;
  ACanvas: TCanvas; ARect: TRect; Selected: Boolean);
begin
 if Selected then
   ACanvas.Brush.Color := clHighlight
 else
   ACanvas.Brush.Color := clMenu;

 ARect.Left := LEFT_MENU_ITEM;
 ACanvas.FillRect(ARect);

 DrawText(ACanvas.Handle, PChar('Executar Agora'), -1, ARect, DT_LEFT or DT_VCENTER or DT_SINGLELINE{ or DT_NOCLIP});
end;

procedure TFormularioGeral.Mnu_InformacoesGeraisDrawItem(Sender: TObject;
  ACanvas: TCanvas; ARect: TRect; Selected: Boolean);
begin
 if Selected then
   ACanvas.Brush.Color := clHighlight
 else
   ACanvas.Brush.Color := clMenu;

 ARect.Left := LEFT_MENU_ITEM;
 ACanvas.FillRect(ARect);

 DrawText(ACanvas.Handle, PChar('Informacoes Gerais'), -1, ARect, DT_LEFT or DT_VCENTER or DT_SINGLELINE{ or DT_NOCLIP});
end;

procedure TFormularioGeral.Mnu_SuporteRemotoDrawItem(Sender: TObject;
  ACanvas: TCanvas; ARect: TRect; Selected: Boolean);
begin
 if Selected then
   ACanvas.Brush.Color := clHighlight
 else
   ACanvas.Brush.Color := clMenu;

 ARect.Left := LEFT_MENU_ITEM;
 ACanvas.FillRect(ARect);

 DrawText(ACanvas.Handle, PChar('Ativar Suporte Remoto'), -1, ARect, DT_LEFT or DT_VCENTER or DT_SINGLELINE{ or DT_NOCLIP});
end;

procedure TFormularioGeral.Mnu_FinalizarCacicDrawItem(Sender: TObject;
  ACanvas: TCanvas; ARect: TRect; Selected: Boolean);
begin
 if Selected then
   ACanvas.Brush.Color := clHighlight
 else
   ACanvas.Brush.Color := clMenu;

 ARect.Left := LEFT_MENU_ITEM;
 ACanvas.FillRect(ARect);

 DrawText(ACanvas.Handle, PChar('Finalizar o CACIC'), -1, ARect, DT_LEFT or DT_VCENTER or DT_SINGLELINE{ or DT_NOCLIP});
 DrawBar(ACanvas);
end;

procedure TFormularioGeral.TimerNuExecAposTimer(Sender: TObject);
begin
  timerNuExecApos.Enabled := false;
  objCACIC.writeDebugLog('TimerNuExecAposTimer: BEGIN');
  ExecutaCACIC(nil);
  objCACIC.writeDebugLog('TimerNuExecAposTimer: END');  
end;

procedure TFormularioGeral.timerNuIntervaloTimer(Sender: TObject);
begin
  objCACIC.writeDebugLog('timerNuIntervaloTimer: BEGIN');
  ExecutaCACIC(nil);
  objCACIC.writeDebugLog('timerNuIntervaloTimer: END');
end;

procedure TFormularioGeral.ApplicationEvents1Message(var Msg: tagMSG;
  var Handled: Boolean);
begin
  if Msg.message = rmTaskbarCreated then
    begin
      objCACIC.writeDebugLog('ApplicationEvents1Message: Mensagem rmTaskbarCreated RECEBIDA!!!!!');
      try
        TrayIcon1.Free;
      except
        // it will fail because it no longer exists when the explorer restarts.
        on E:Exception do
          Begin
            objCACIC.writeExceptionLog(E.Message,e.ClassName,'ApplicationEvents1Message - Liberando Systray Icon para recria��o');
          End;
      end;
      TrayIcon1           := TTrayIcon.Create(self);
      TrayIcon1.Hint      := pnVersao.Caption;
      TrayIcon1.PopupMenu := Popup_Menu_Contexto;
      imgIconList.GetIcon(g_intStatus,TrayIcon1.Icon);
      TrayIcon1.Show;
    End
  else
    inherited;
end;

end.

