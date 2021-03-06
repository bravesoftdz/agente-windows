//  Copyright (C) 1999 AT&T Laboratories Cambridge. All Rights Reserved.
//
//  This file is part of the VNC system.
//
//  The VNC system is free software; you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation; either version 2 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307,
//  USA.
//
// If the source code for the VNC system is not available from the place 
// whence you received this file, check http://www.uk.research.att.com/vnc or contact
// the authors on vnc@uk.research.att.com for information on obtaining it.


// vncAcceptDialog.cpp: implementation of the vncAcceptDialog class, used
// to query whether or not to accept incoming connections.

#include "stdhdrs.h"
#include "vncAcceptDialog.h"
#include "WinVNC.h"
#include "vncService.h"

#include "resource.h"

#include "localization.h" // Act : add localization on messages

//	[v1.0.2-jp1 fix] Load resouce from dll
extern HINSTANCE	hInstResDLL;

DWORD WINAPI makeWndBlink(LPVOID lParam);
HANDLE isWindowActivated = 0;

// Constructor

vncAcceptDialog::vncAcceptDialog(UINT timeoutSecs,BOOL acceptOnTimeout, const char *ipAddress)
{
	m_timeoutSecs = timeoutSecs;
	m_ipAddress = _strdup(ipAddress);
	m_foreground_hack=FALSE;
	m_acceptOnTimeout = acceptOnTimeout;
}

// Destructor

vncAcceptDialog::~vncAcceptDialog()
{
	if (m_ipAddress)
		free(m_ipAddress);
}

// Routine called to activate the dialog and, once it's done, delete it

BOOL vncAcceptDialog::DoDialog()
{	
	

	//	[v1.0.2-jp1 fix]
	//int retVal = DialogBoxParam(hAppInstance, MAKEINTRESOURCE(IDD_ACCEPT_CONN), 

		int retVal = DialogBoxParam(hInstResDLL, MAKEINTRESOURCE(IDD_ACCEPT_CONN), 
			NULL, (DLGPROC) vncAcceptDlgProc, (LONG) this);
		delete this;
		switch (retVal) 
		{
			case IDREJECT:
				return 0;
			case IDACCEPT://modificar aqui!
				return 1;
		}
		return (m_acceptOnTimeout) ? 1 : 0;
}

// Callback function - handles messages sent to the dialog box

BOOL CALLBACK vncAcceptDialog::vncAcceptDlgProc(HWND hwnd,
											UINT uMsg,
											WPARAM wParam,
											LPARAM lParam) {
	// This is a static method, so we don't know which instantiation we're 
	// dealing with. But we can get a pseudo-this from the parameter to 
	// WM_INITDIALOG, which we therafter store with the window and retrieve
	// as follows:
#ifndef _X64
	vncAcceptDialog *_this = (vncAcceptDialog *) GetWindowLong(hwnd, GWL_USERDATA);
#else
	vncAcceptDialog *_this = (vncAcceptDialog *) GetWindowLongPtr(hwnd, GWLP_USERDATA);
#endif
	switch (uMsg) {

		// Dialog has just been created
	case WM_INITDIALOG:
		{
			// Save the lParam into our user data so that subsequent calls have
			// access to the parent C++ object
#ifndef _X64
            SetWindowLong(hwnd, GWL_USERDATA, lParam);
#else
			SetWindowLongPtr(hwnd, GWLP_USERDATA, lParam);
#endif
            vncAcceptDialog *_this = (vncAcceptDialog *) lParam;

			// Seta o nome do �ltimo usu�rio visitante
			SetDlgItemText(hwnd, IDC_UVIS_NAME, CACIC_Auth::getInstance()->m_novoCliente.nm_usuario_completo.data());
			// Seta o nome do �ltimo usu�rio visitante
			SetDlgItemText(hwnd, IDC_MOTIVO_SUPORTE, CACIC_Auth::getInstance()->m_novoCliente.te_motivo_conexao.data());
			// Set the IP-address string
			SetDlgItemText(hwnd, IDC_ACCEPT_IP, _this->m_ipAddress);
			// Seta o doc. refer�ncia do �ltimo usu�rio visitante
			SetDlgItemText(hwnd, IDC_DOC_REF, CACIC_Auth::getInstance()->m_novoCliente.te_documento_referencial.data());
			if (SetTimer(hwnd, 1, 1000, NULL) == 0)
			{
				if (_this->m_acceptOnTimeout)
					EndDialog(hwnd, IDACCEPT);
				else
				EndDialog(hwnd, IDREJECT);
			}
			_this->m_timeoutCount = _this->m_timeoutSecs;

			char temp[256];
			if (_this->m_acceptOnTimeout)
				sprintf(temp, "Aceitar:%u", (_this->m_timeoutCount));
			else
				sprintf(temp, "Rejeitar:%u", (_this->m_timeoutCount));
			SetDlgItemText(hwnd, IDC_ACCEPT_TIMEOUT, temp);


			// Attempt to mimic Win98/2000 dialog behaviour
			if ((vncService::IsWinNT() && (vncService::VersionMajor() <= 4)) ||
				(vncService::IsWin95() && (vncService::VersionMinor() == 0)))
			{
				// Perform special hack to display the dialog safely
				if (GetWindowThreadProcessId(GetForegroundWindow(), NULL) != GetCurrentProcessId())
				{
					// We can't set our dialog as foreground if the foreground window
					// doesn't belong to us - it's unsafe!
					SetActiveWindow(hwnd);
					_this->m_foreground_hack = TRUE;
					_this->m_flash_state = FALSE;
				}
			}
			if (!_this->m_foreground_hack) {
				SetForegroundWindow(hwnd);
			}

			// Beep
			MessageBeep(MB_ICONEXCLAMATION);

			// Faz a janela piscar na barra de tarefas
			PFLASHWINFO fhwInfo = new FLASHWINFO();
			fhwInfo->cbSize = sizeof (FLASHWINFO);
			fhwInfo->dwFlags = FLASHW_ALL | FLASHW_TIMERNOFG;
			fhwInfo->dwTimeout = 1000;
			fhwInfo->hwnd = hwnd;
			fhwInfo->uCount = 60;
			FlashWindowEx(fhwInfo);

			DWORD threadID;
			CreateThread(NULL, 0, makeWndBlink, (LPVOID) hwnd, 0, &threadID);
            
            // Return success!
			return TRUE;
		}

		// Timer event
	case WM_TIMER:
		if ((_this->m_timeoutCount) == 0)
			{
				if ( _this->m_acceptOnTimeout ) 
					{
						EndDialog(hwnd, IDACCEPT);
					}
				else 
					{
						EndDialog(hwnd, IDREJECT);
					}
			}
		_this->m_timeoutCount--;

		// Flash if necessary
		if (_this->m_foreground_hack) {
			if (GetWindowThreadProcessId(GetForegroundWindow(), NULL) != GetCurrentProcessId())
			{
				_this->m_flash_state = !_this->m_flash_state;
				FlashWindow(hwnd, _this->m_flash_state);
			} else {
				_this->m_foreground_hack = FALSE;
			}
		}

		// Update the displayed count
		char temp[256];
		if ( _this->m_acceptOnTimeout )
			sprintf(temp, "Aceitar: %u", (_this->m_timeoutCount));
		else
			sprintf(temp, "Rejeitar: %u", (_this->m_timeoutCount));
		SetDlgItemText(hwnd, IDC_ACCEPT_TIMEOUT, temp);
		break;

		// Dialog has just received a command
	case WM_COMMAND:
		switch (LOWORD(wParam)) {

			// User clicked Accept or pressed return
		case IDACCEPT:
		case IDOK:
			EndDialog(hwnd, IDACCEPT);
			return TRUE;

		case IDREJECT:
		case IDCANCEL:
			EndDialog(hwnd, IDREJECT);
			return TRUE;
		};

		break;

	case WM_ACTIVATE:
	case WM_MOUSEACTIVATE:
		SetEvent(isWindowActivated);
		break;
		// Window is being destroyed!  (Should never happen)
	case WM_DESTROY:
		EndDialog(hwnd, IDREJECT);
		return TRUE;
	}
	return 0;
}

DWORD WINAPI makeWndBlink(LPVOID lParam) {
	HWND hwnd = (HWND) lParam;
	int percentage = 100;
	int flip = -1;
	isWindowActivated = CreateEvent(0, FALSE, FALSE, 0);

	while (WaitForSingleObject(isWindowActivated, 10)) {
		if (percentage == 25) {
			flip = 1;
		} else if (percentage == 100) {
			flip = -1;
			Sleep(1000);
		}
		percentage += (1 * flip);

		LONG ExtendedStyle = GetWindowLong(hwnd, GWL_EXSTYLE);
		SetWindowLong(hwnd, GWL_EXSTYLE, ExtendedStyle | WS_EX_LAYERED);
		double TransparencyPercentage = (double) percentage;
		double fAlpha = TransparencyPercentage * (255.0 /100);
		BYTE byAlpha = static_cast<BYTE>(fAlpha);
		SetLayeredWindowAttributes(hwnd, 0, byAlpha, LWA_ALPHA);
	}
	SetLayeredWindowAttributes(hwnd, 0, static_cast<BYTE>(100 * (255.0 /100)), LWA_ALPHA);

	return 0;
}
