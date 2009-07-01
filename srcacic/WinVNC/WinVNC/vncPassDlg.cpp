#include "vncPassDlg.h"
#include <iostream>  
#include <sstream>  

extern HINSTANCE hInstResDLL;

vncPassDlg::vncPassDlg(vector<Dominio> &listaDominios) {
	m_listaDominios = listaDominios;
	m_authStat = vncPassDlg::ESPERANDO_AUTENTICACAO;

	memset(m_usuario, '\0', 32);
	memset(m_senha, '\0', 32);
	memset(m_dominio, '\0', 16);
}

vncPassDlg::~vncPassDlg()
{
}

BOOL vncPassDlg::DoDialog(EAuthCode authStat, string msginfo)
{
	m_authStat = authStat;
	m_msgInfo = msginfo;

	BOOL retVal;
	if (m_authStat == vncPassDlg::SEM_AUTENTICACAO)
	{
		strcpy(m_dominio, "0");
		strcpy(m_senha, "0");
		retVal = DialogBoxParam(hInstResDLL, MAKEINTRESOURCE(IDD_NO_AUTH_DLG), 
			NULL, (DLGPROC) vncNoAuthDlgProc, (LONG) this);
	}
	else
	{
		retVal = DialogBoxParam(hInstResDLL, MAKEINTRESOURCE(IDD_AUTH_DLG), 
			NULL, (DLGPROC) vncAuthDlgProc, (LONG) this);
	}

	return retVal;
}

BOOL CALLBACK vncPassDlg::vncAuthDlgProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
	// This is a static method, so we don't know which instantiation we're 
	// dealing with. We use Allen Hadden's (ahadden@taratec.com) suggestion 
	// from a newsgroup to get the pseudo-this.
	#ifndef _X64
		vncPassDlg *_this = (vncPassDlg*)GetWindowLong(hwnd, GWL_USERDATA);
	#else
		vncPassDlg *_this = (vncPassDlg*)GetWindowLongPtr(hwnd, GWLP_USERDATA);
	#endif

	static HBRUSH msgBkColor;
	static HBRUSH vrsBkColor;

	switch (uMsg)
	{
		case WM_INITDIALOG:
		{
			// Save the lParam into our user data so that subsequent calls have
			// access to the parent C++ object
			#ifndef _X64
				SetWindowLong(hwnd, GWL_USERDATA, lParam);
			#else
				SetWindowLongPtr(hwnd, GWLP_USERDATA, lParam);
			#endif
			
			vncPassDlg *_this = (vncPassDlg *) lParam;

			vrsBkColor = CreateSolidBrush(RGB(238, 215, 184));

			changeFont(hwnd, IDC_ATT_MSG);

			SendMessage (hwnd, EM_SETMARGINS, EC_LEFTMARGIN | EC_RIGHTMARGIN, MAKELONG (8, 8));

			// Limitando o tamanho dos campos para 32 caracteres.
			SendMessage(GetDlgItem(hwnd, IDC_USER_EDIT), EM_LIMITTEXT, WPARAM(32), 0);
			SendMessage(GetDlgItem(hwnd, IDC_PASS_EDIT), EM_LIMITTEXT, WPARAM(32), 0);

			string nm_dominio;
			HWND hDominios = GetDlgItem(hwnd, IDC_DOMAIN_CB);
			SendMessage(hDominios, CB_ADDSTRING, 0, (LPARAM) _this->m_listaDominios.at(0).nome.c_str());
			SendMessage(hDominios, CB_SETCURSEL, 0, 0);
			int found;
			for (int i = 1; i < _this->m_listaDominios.size(); i++)
			{
				nm_dominio = _this->m_listaDominios.at(i).nome;
				SendMessage(hDominios, CB_ADDSTRING, 0, (LPARAM) nm_dominio.c_str());
				found = nm_dominio.find("*"); // seleciona o dom�nio marcado com o *
				if (found != string::npos)
					SendMessage(hDominios, CB_SELECTSTRING, 0, (LPARAM) nm_dominio.c_str());
			}
			
			//HWND num_con_cb = GetDlgItem(hwnd, IDC_NUMCON_CB);
			//SendMessage(num_con_cb, CB_ADDSTRING, 0, (LPARAM)"1");
			//SendMessage(num_con_cb, CB_ADDSTRING, 0, (LPARAM)"2");
			//SendMessage(num_con_cb, CB_ADDSTRING, 0, (LPARAM)"3");
			//SendMessage(num_con_cb, CB_SETCURSEL, 0, 0);

			if (_this->m_authStat == vncPassDlg::FALHA_AUTENTICACAO)
			{
				msgBkColor = CreateSolidBrush(RGB(242, 0, 28));

				SendMessage(hDominios, CB_SELECTSTRING, 0, (LPARAM) _this->m_listaDominios.at(_this->m_indiceDominio).nome.c_str());
				SetDlgItemText(hwnd, IDC_USER_EDIT, _this->m_usuario);
				SetDlgItemText(hwnd, IDC_PASS_EDIT, _this->m_senha);
				SetDlgItemText(hwnd, IDC_MSG, (LPSTR) "Falha na autentica��o!");
			}
			else if (_this->m_authStat == vncPassDlg::AUTENTICADO)
			{
				msgBkColor = CreateSolidBrush(RGB(102, 255, 0));

				SendMessage(hDominios, CB_SELECTSTRING, 0, (LPARAM) _this->m_listaDominios.at(_this->m_indiceDominio).nome.c_str());
				SetDlgItemText(hwnd, IDC_USER_EDIT, _this->m_usuario);
				SetDlgItemText(hwnd, IDC_PASS_EDIT, _this->m_senha);

				HWND hDominios = GetDlgItem(hwnd, IDC_DOMAIN_CB);
				EnableWindow( hDominios, FALSE );
				HWND hUsuario = GetDlgItem(hwnd, IDC_USER_EDIT);
				EnableWindow( hUsuario, FALSE );
				HWND hSenha = GetDlgItem(hwnd, IDC_PASS_EDIT);
				EnableWindow( hSenha, FALSE );

				//HWND h_num_con_lbl = GetDlgItem(hwnd, IDC_STATIC_N_CON);
				//ShowWindow( h_num_con_lbl, TRUE );
				//HWND h_num_con = GetDlgItem(hwnd, IDC_NUMCON_CB);
				//ShowWindow( h_num_con, TRUE );

				SetDlgItemText( hwnd, IDC_MSG, (LPSTR)_this->m_msgInfo.c_str() );
			}

			return TRUE;
		}
		break;

		case WM_COMMAND:
		{
			switch (LOWORD(wParam))
			{
				case ID_POK:
				{
					if (_this->m_authStat == vncPassDlg::AUTENTICADO)
					{
						/*HWND numcon_cb = GetDlgItem(hwnd, IDC_NUMCON_CB);
						int numcon = SendMessage(numcon_cb, CB_GETCURSEL, 0, 0);
						numcon++;
						MAX_VNC_CLIENTS = numcon;*/

						EndDialog(hwnd, IDOK);
					}

					int ulen = GetWindowTextLength(GetDlgItem(hwnd, IDC_USER_EDIT));
					int plen = GetWindowTextLength(GetDlgItem(hwnd, IDC_PASS_EDIT));

					HWND hDominios = GetDlgItem(hwnd, IDC_DOMAIN_CB);
					_this->m_indiceDominio = SendMessage(hDominios, CB_GETCURSEL, 0, 0);

					memset(_this->m_usuario, '\0', 32);
					memset(_this->m_senha, '\0', 32);
					memset(_this->m_dominio, '\0', 16);

					GetDlgItemText(hwnd, IDC_USER_EDIT, _this->m_usuario, 32);

					if (_this->m_authStat == vncPassDlg::SEM_AUTENTICACAO)
					{
						strcpy(_this->m_senha, "0");
						strcpy(_this->m_dominio, "0");
					}
					else
					{
						GetDlgItemText(hwnd, IDC_PASS_EDIT, _this->m_senha, 32);

						strcpy(_this->m_dominio, _this->m_listaDominios.at(_this->m_indiceDominio).id.c_str());

						if (_this->m_usuario[0] == '\0' || _this->m_senha[0] == '\0' || _this->m_dominio[0] == '\0')
						{
							MessageBox(hwnd, "Os campos devem ser preenchidos!", "Erro!", MB_ICONERROR | MB_OK);
							return FALSE;
						}
					}

					EndDialog(hwnd, IDOK);
				}
				break;

				case ID_PCANCELAR:
					EndDialog(hwnd, FALSE);
				break;
			}
		}
		break;

		case WM_CTLCOLORSTATIC:
		{
			HDC hdc = (HDC)wParam;
			HWND hwndStatic = (HWND)lParam;

			if (hwndStatic == GetDlgItem(hwnd, IDC_MSG))
			{
				SetBkMode(hdc, TRANSPARENT);
				return (LRESULT)msgBkColor;
			}

			if (hwndStatic == GetDlgItem(hwnd, IDC_AUTHDLG_VERSION))
			{
				SetBkMode(hdc, TRANSPARENT);
				return (LRESULT)vrsBkColor;
			}

			if (hwndStatic == GetDlgItem(hwnd, IDC_ATT_MSG))
			{
				SetTextColor(hdc, RGB(255, 0, 0));
				SetBkMode(hdc, TRANSPARENT);
				return (BOOL)GetStockObject(NULL_BRUSH);
			}
		}
		break;

	}

	return FALSE;
}

BOOL CALLBACK vncPassDlg::vncNoAuthDlgProc(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
	// This is a static method, so we don't know which instantiation we're 
	// dealing with. We use Allen Hadden's (ahadden@taratec.com) suggestion 
	// from a newsgroup to get the pseudo-this.
	#ifndef _X64
		vncPassDlg *_this = (vncPassDlg*)GetWindowLong(hwnd, GWL_USERDATA);
	#else
		vncPassDlg *_this = (vncPassDlg*)GetWindowLongPtr(hwnd, GWLP_USERDATA);
	#endif

	static HBRUSH msgBkColor;
	static HBRUSH vrsBkColor;

	switch (uMsg)
	{
		case WM_INITDIALOG:
		{
			// Save the lParam into our user data so that subsequent calls have
			// access to the parent C++ object
			#ifndef _X64
				SetWindowLong(hwnd, GWL_USERDATA, lParam);
			#else
				SetWindowLongPtr(hwnd, GWLP_USERDATA, lParam);
			#endif
			
			vncPassDlg *_this = (vncPassDlg *) lParam;

			vrsBkColor = CreateSolidBrush(RGB(238, 215, 184));

			changeFont(hwnd, IDC_ATT_MSG);

			SendMessage (hwnd, EM_SETMARGINS, EC_LEFTMARGIN | EC_RIGHTMARGIN, MAKELONG (8, 8));

			SetDlgItemText( hwnd, IDC_MSG, (LPSTR)_this->m_msgInfo.c_str() );

			return TRUE;
		}
		break;

		case WM_COMMAND:
		{
			switch (LOWORD(wParam))
			{
				case ID_POK:
				{
					int ulen = GetWindowTextLength(GetDlgItem(hwnd, IDC_USER_EDIT));

					memset(_this->m_usuario, '\0', 32);

					GetDlgItemText(hwnd, IDC_USER_EDIT, _this->m_usuario, 32);

					if (_this->m_usuario[0] == '\0')
					{
						MessageBox(hwnd, "O campo deve ser preenchido.", "Erro!", MB_ICONERROR | MB_OK);
						return FALSE;
					}

					EndDialog(hwnd, IDOK);
				}
				break;

				case ID_PCANCELAR:
					EndDialog(hwnd, FALSE);
				break;
			}
		}
		break;

		case WM_CTLCOLORSTATIC:
		{
			HDC hdc = (HDC)wParam;
			HWND hwndStatic = (HWND)lParam;

			if (hwndStatic == GetDlgItem(hwnd, IDC_MSG))
			{
				SetBkMode(hdc, TRANSPARENT);
				return (LRESULT)msgBkColor;
			}

			if (hwndStatic == GetDlgItem(hwnd, IDC_AUTHDLG_VERSION))
			{
				SetBkMode(hdc, TRANSPARENT);
				return (LRESULT)vrsBkColor;
			}

			if (hwndStatic == GetDlgItem(hwnd, IDC_ATT_MSG))
			{
				SetTextColor(hdc, RGB(255, 0, 0));
				SetBkMode(hdc, TRANSPARENT);
				return (BOOL)GetStockObject(NULL_BRUSH);
			}
		}
		break;

	}

	return FALSE;
}

void vncPassDlg::changeFont(HWND hwndDlg, int dlgItem)
{
	HFONT hFont ;
	LOGFONT lfFont;

	memset(&lfFont, 0x00, sizeof(lfFont));
	memcpy(lfFont.lfFaceName, TEXT("Microsoft Sans Serif"), 24);

	lfFont.lfHeight   = 13;
	lfFont.lfWeight   = FW_BOLD;
	lfFont.lfCharSet  = ANSI_CHARSET;
	lfFont.lfOutPrecision = OUT_DEFAULT_PRECIS;
	lfFont.lfClipPrecision = CLIP_DEFAULT_PRECIS;
	lfFont.lfQuality  = DEFAULT_QUALITY;

	// Create the font from the LOGFONT structure passed.
	hFont = CreateFontIndirect (&lfFont);

	SendMessage( GetDlgItem(hwndDlg, dlgItem), WM_SETFONT, (int)hFont, MAKELONG( TRUE, 0 ) );
}
