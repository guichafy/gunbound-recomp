
/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

undefined4 FUN_0040d8e0(HINSTANCE param_1,int param_2,undefined4 param_3,int param_4)

{
  char cVar1;
  HANDLE pvVar2;
  DWORD DVar3;
  void *pvVar4;
  LPSTR _Src;
  HWND hWnd;
  LPBYTE lpData;
  LSTATUS LVar5;
  undefined4 uVar6;
  BOOL BVar7;
  LPCSTR pCVar8;
  LPCSTR pCVar9;
  undefined4 uVar10;
  char *pcVar11;
  LPSTR pCVar12;
  int iVar13;
  undefined4 *puVar14;
  char *pcVar15;
  LPCSTR lpDirectory;
  UINT UVar16;
  undefined1 *puVar17;
  INT nShowCmd;
  HKEY local_db8;
  HDC local_db4;
  LPBYTE local_db0;
  DWORD local_dac;
  DWORD local_da8;
  WNDCLASSA local_da4;
  tagMSG tStack_d7c;
  char cStack_d49;
  char acStack_d48 [12];
  char acStack_d3c [1011];
  char cStack_949;
  CHAR aCStack_948 [12];
  char acStack_93c [1012];
  _WIN32_FIND_DATAA _Stack_548;
  char cStack_408;
  undefined4 uStack_407;

  FUN_00525f26(s_test_txt_00552c30);
  FUN_00525f26(s_c__comsik_txt_00552778);
  EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  FUN_0040a380(0x118);
  LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  FUN_0040a380(0);
  LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  FUN_0040a380(2);
  LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  FUN_0040a380(4);
  LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  FUN_0040a380(5);
  LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  FUN_0040a380(8);
  LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  FUN_0040a380(10);
  LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  FUN_0040a380(0xf);
  LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  FUN_0040a380(0x14);
  LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  FUN_0040a380(0x19);
  LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  FUN_0040a380(0x1e);
  LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  FUN_0040a380(0x32);
  LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  FUN_0040a380(0x46);
  LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  FUN_0040a380(0x50);
  LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  FUN_0040a380(0x62);
  LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  FUN_0040a380(100);
  LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  FUN_0040a380(0xa0);
  LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  FUN_0040a380(200);
  LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  FUN_0040a380(0x100);
  LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  FUN_0040a380(0x168);
  LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  pvVar2 = CreateMutexA((LPSECURITY_ATTRIBUTES)0x0,1,s_SoftnyxGunBound_gme_00552764);
  DVar3 = GetLastError();
  if (pvVar2 != (HANDLE)0x0) {
    ReleaseMutex(pvVar2);
  }
  if (DVar3 == 0xb7) {
    return 0;
  }
  WSAStartup(0x101,(LPWSADATA)&DAT_00793228);
  pvVar4 = operator_new(0x84f0);
  if (pvVar4 == (void *)0x0) {
    DAT_005b2b58 = 0;
  }
  else {
    DAT_005b2b58 = FUN_004d2170(pvVar4,0,&DAT_00795070);
  }
  DAT_007934ec = DAT_005b2b58;
  FUN_004d23f0();
  pvVar4 = operator_new(0x84f0);
  if (pvVar4 == (void *)0x0) {
    DAT_005b2b5c = 0;
  }
  else {
    DAT_005b2b5c = FUN_004d2170(pvVar4,1,&DAT_00795070);
  }
  DAT_007934e8 = DAT_005b2b5c;
  FUN_004d23f0();
  pvVar4 = operator_new(0x84f0);
  if (pvVar4 == (void *)0x0) {
    DAT_005b2b60 = 0;
  }
  else {
    DAT_005b2b60 = FUN_004d2170(pvVar4,2,&DAT_00795070);
  }
  DAT_007934f0 = DAT_005b2b60;
  FUN_004d23f0();
  FUN_0040d370();
  pvVar4 = operator_new(0x200c);
  if (pvVar4 == (void *)0x0) {
    DAT_007934f4 = (HDC)0x0;
  }
  else {
    DAT_007934f4 = (HDC)FUN_004058c0(3,&DAT_00795070);
  }
  DVar3 = timeGetTime();
  FUN_00525c42(DVar3);
  _Src = GetCommandLineA();
  pCVar12 = _Src;
  do {
    cVar1 = *pCVar12;
    pCVar12 = pCVar12 + 1;
  } while (cVar1 != '\0');
  if ((int)pCVar12 - (int)(_Src + 1) != 0x60) {
    return 0;
  }
  iVar13 = 0;
  do {
    _sscanf(_Src,&DAT_0055275c,&DAT_005b3440 + iVar13);
    iVar13 = iVar13 + 1;
    _Src = _Src + 2;
  } while (iVar13 < 0x30);
  if (param_2 == 0) {
    local_da4.style = 0xb;
    local_da4.lpfnWndProc = FUN_00410040;
    local_da4.cbClsExtra = 0;
    local_da4.cbWndExtra = 0;
    local_da4.hInstance = param_1;
    local_da4.hIcon = (HICON)0x0;
    local_da4.hCursor = LoadCursorA((HINSTANCE)0x0,(LPCSTR)0x7f00);
    local_da4.hbrBackground = (HBRUSH)0x0;
    local_da4.lpszMenuName = (LPCSTR)0x0;
    local_da4.lpszClassName = s_Softnyx_00552754;
    RegisterClassA(&local_da4);
  }
  hWnd = CreateWindowExA(8,s_Softnyx_00552754,s_GunBound_00552748,0x86000000,0,0,1,1,(HWND)0x0,
                         (HMENU)0x0,param_1,(LPVOID)0x0);
  SetForegroundWindow(hWnd);
  SetFocus(hWnd);
  _DAT_0079351c = param_1;
  DAT_00588f48 = 0;
  _DAT_00793518 = hWnd;
  if (DAT_005b33f0 == 1) {
    local_db4 = GetDC(hWnd);
    GetDeviceCaps(local_db4,0x74);
    DAT_00588f48 = FUN_0040d200();
    if (DAT_00588f48 == 0) {
      lpData = (LPBYTE)FUN_0040c620();
      FUN_0040c470(0x10);
      local_db0 = (LPBYTE)FUN_0040d200();
      if (local_db0 < lpData) {
        local_dac = 4;
        LVar5 = RegOpenKeyExA((HKEY)0x80000002,s_Software_Softnyx_GunBound_0056d3a0,0,0xf003f,
                              &local_db8);
        if ((LVar5 == 0) &&
           (LVar5 = RegQueryValueExA(local_db8,s_Template_0055273c,(LPDWORD)0x0,&local_da8,lpData,
                                     &local_dac), LVar5 != 0)) {
          RegSetValueExA(local_db8,s_Template_0055273c,0,4,(BYTE *)&local_db0,4);
          RegCloseKey(local_db8);
        }
        uVar6 = FUN_0040d200();
        FUN_0040c550(uVar6);
      }
    }
    ReleaseDC(hWnd,local_db4);
  }
  ShowWindow(hWnd,param_4);
  UpdateWindow(hWnd);
  ShowCursor(0);
  local_dac = FUN_0040eaa0(hWnd,param_1);
  if (local_dac == 0) {
    FUN_0040d260(DAT_005b3484 + 0x2331c);
    SetFocus(hWnd);
    local_db4 = DAT_007934f4;
    FUN_004e5a50(0x20a3);
    *(undefined1 *)&local_db4[0x802].unused = 1;
    DAT_007934e0 = timeGetTime();
    FUN_004122f0();
    while( true ) {
      while (BVar7 = PeekMessageA(&tStack_d7c,(HWND)0x0,0,0,0), BVar7 == 0) {
        FUN_00413130();
      }
      BVar7 = GetMessageA(&tStack_d7c,(HWND)0x0,0,0);
      if (BVar7 == 0) break;
      TranslateMessage(&tStack_d7c);
      DispatchMessageA(&tStack_d7c);
    }
  }
  else if (local_dac == 0x17) {
    LVar5 = RegOpenKeyExA((HKEY)0x80000002,s_Software_Softnyx_GunBound_0056d3a0,0,0xf003f,&local_db8
                         );
    if (LVar5 == 0) {
      local_db4 = (HDC)0x4;
      LVar5 = RegQueryValueExA(local_db8,s_Template_0055273c,(LPDWORD)0x0,&local_da8,
                               (LPBYTE)&local_db0,(LPDWORD)&local_db4);
      if (LVar5 == 0) {
        FUN_0040c550(local_db0);
        RegDeleteValueA(local_db8,s_Template_0055273c);
      }
      RegCloseKey(local_db8);
    }
    iVar13 = FUN_0040eaa0(hWnd,param_1);
    if (iVar13 == 0) {
      FUN_0040d260(DAT_005b3484 + 0x2331c);
      SetFocus(hWnd);
      DAT_007934e0 = timeGetTime();
      FUN_004122f0();
      DAT_005b33f0 = 0;
    }
  }
  if ((DAT_00588f48 == 0) &&
     (LVar5 = RegOpenKeyExA((HKEY)0x80000002,s_Software_Softnyx_GunBound_0056d3a0,0,0xf003f,
                            &local_db8), LVar5 == 0)) {
    local_db4 = (HDC)0x4;
    LVar5 = RegQueryValueExA(local_db8,s_Template_0055273c,(LPDWORD)0x0,&local_da8,
                             (LPBYTE)&local_db0,(LPDWORD)&local_db4);
    if (LVar5 == 0) {
      FUN_0040c550(local_db0);
      RegDeleteValueA(local_db8,s_Template_0055273c);
    }
    RegCloseKey(local_db8);
  }
  cStack_408 = '\0';
  puVar14 = &uStack_407;
  for (iVar13 = 0xff; iVar13 != 0; iVar13 = iVar13 + -1) {
    *puVar14 = 0;
    puVar14 = puVar14 + 1;
  }
  *(undefined2 *)puVar14 = 0;
  *(undefined1 *)((int)puVar14 + 2) = 0;
  _sprintf(&cStack_408,s__sADB_exe_00552730,&DAT_005b1ed0);
  DVar3 = local_dac;
  FUN_0040f400(local_dac == 0);
  ShowCursor(1);
  ShowWindow(hWnd,0);
  if (DAT_00793516 == '\x01') {
    if (DAT_00793640 == 1) {
      UVar16 = 0;
      pCVar8 = (LPCSTR)FUN_0043dc70(&DAT_00796eec,0x13b);
      uVar6 = 300;
    }
    else {
      if (DAT_00793640 != 2) goto LAB_0040e75c;
      UVar16 = 0;
      pCVar8 = (LPCSTR)FUN_0043dc70(&DAT_00796eec,0x13b);
      uVar6 = 0x13c;
    }
    goto LAB_0040e0f1;
  }
  if (DVar3 == 0) goto LAB_0040e75c;
  if (0x806e < (int)DVar3) {
    if (0x8099 < (int)DVar3) {
      switch(DVar3) {
      case 0x809b:
        UVar16 = 0;
        pCVar8 = (LPCSTR)FUN_0043dc70(&DAT_00796eec,30000);
        pCVar9 = (LPCSTR)FUN_0043dc70(&DAT_00796eec,0x7535);
        MessageBoxA(hWnd,pCVar9,pCVar8,UVar16);
        break;
      default:
switchD_0040e15b_caseD_e:
        pcVar11 = (char *)FUN_0043dc70(&DAT_00796eec,0x13a);
        _sprintf(acStack_d48,pcVar11,DVar3);
        UVar16 = 0;
        pCVar8 = (LPCSTR)FUN_0043dc70(&DAT_00796eec,0x13d);
        MessageBoxA((HWND)0x0,acStack_d48,pCVar8,UVar16);
        uVar6 = 0x140;
        goto LAB_0040e744;
      case 0x80aa:
        UVar16 = 0;
        pCVar8 = (LPCSTR)FUN_0043dc70(&DAT_00796eec,30000);
        pCVar9 = (LPCSTR)FUN_0043dc70(&DAT_00796eec,0x7536);
        MessageBoxA(hWnd,pCVar9,pCVar8,UVar16);
        break;
      case 0x80c8:
        UVar16 = 0;
        pCVar8 = (LPCSTR)FUN_0043dc70(&DAT_00796eec,30000);
        pCVar9 = (LPCSTR)FUN_0043dc70(&DAT_00796eec,0x7537);
        MessageBoxA(hWnd,pCVar9,pCVar8,UVar16);
        break;
      case 0x8154:
      case 0x817c:
        UVar16 = 0;
        pCVar8 = (LPCSTR)FUN_0043dc70(&DAT_00796eec,30000);
        pCVar9 = (LPCSTR)FUN_0043dc70(&DAT_00796eec,0x7539);
        MessageBoxA(hWnd,pCVar9,pCVar8,UVar16);
        break;
      case 0x815e:
        UVar16 = 0;
        pCVar8 = (LPCSTR)FUN_0043dc70(&DAT_00796eec,30000);
        pCVar9 = (LPCSTR)FUN_0043dc70(&DAT_00796eec,0x7538);
        MessageBoxA(hWnd,pCVar9,pCVar8,UVar16);
        break;
      case 0x8168:
        UVar16 = 0;
        pCVar8 = (LPCSTR)FUN_0043dc70(&DAT_00796eec,30000);
        pCVar9 = (LPCSTR)FUN_0043dc70(&DAT_00796eec,0x753a);
        MessageBoxA(hWnd,pCVar9,pCVar8,UVar16);
      }
      goto LAB_0040e75c;
    }
    if (DVar3 == 0x8099) {
switchD_0040e507_caseD_8078:
      UVar16 = 0;
      pCVar8 = (LPCSTR)FUN_0043dc70(&DAT_00796eec,30000);
      pCVar9 = (LPCSTR)FUN_0043dc70(&DAT_00796eec,0x7534);
      MessageBoxA(hWnd,pCVar9,pCVar8,UVar16);
    }
    else {
      switch(DVar3) {
      case 0x8070:
        UVar16 = 0;
        pCVar8 = (LPCSTR)FUN_0043dc70(&DAT_00796eec,30000);
        pCVar9 = (LPCSTR)FUN_0043dc70(&DAT_00796eec,0x753b);
        MessageBoxA(hWnd,pCVar9,pCVar8,UVar16);
        break;
      default:
        goto switchD_0040e15b_caseD_e;
      case 0x8072:
        UVar16 = 0;
        pCVar8 = (LPCSTR)FUN_0043dc70(&DAT_00796eec,30000);
        pCVar9 = (LPCSTR)FUN_0043dc70(&DAT_00796eec,0x7533);
        MessageBoxA(hWnd,pCVar9,pCVar8,UVar16);
        break;
      case 0x8073:
        UVar16 = 0;
        pCVar8 = (LPCSTR)FUN_0043dc70(&DAT_00796eec,30000);
        pCVar9 = (LPCSTR)FUN_0043dc70(&DAT_00796eec,0x7532);
        MessageBoxA(hWnd,pCVar9,pCVar8,UVar16);
        break;
      case 0x8078:
      case 0x807c:
      case 0x808d:
      case 0x808e:
      case 0x8096:
        goto switchD_0040e507_caseD_8078;
      }
    }
    goto LAB_0040e75c;
  }
  if (DVar3 == 0x806e) {
    UVar16 = 0;
    pCVar8 = (LPCSTR)FUN_0043dc70(&DAT_00796eec,30000);
    pCVar9 = (LPCSTR)FUN_0043dc70(&DAT_00796eec,0x7531);
    MessageBoxA(hWnd,pCVar9,pCVar8,UVar16);
    goto LAB_0040e75c;
  }
  switch(DVar3) {
  case 0xd:
    UVar16 = 0;
    pCVar8 = (LPCSTR)FUN_0043dc70(&DAT_00796eec,0x13d);
    uVar6 = 0x135;
    goto LAB_0040e0f1;
  default:
    goto switchD_0040e15b_caseD_e;
  case 0x12:
  case 0x15:
  case 0x1c:
    UVar16 = 0;
    pCVar8 = (LPCSTR)FUN_0043dc70(&DAT_00796eec,0x13d);
    pCVar9 = (LPCSTR)FUN_0043dc70(&DAT_00796eec,0x136);
    MessageBoxA((HWND)0x0,pCVar9,pCVar8,UVar16);
    uVar6 = 0x13e;
    goto LAB_0040e744;
  case 0x13:
    UVar16 = 0;
    pCVar8 = (LPCSTR)FUN_0043dc70(&DAT_00796eec,0x13d);
    uVar6 = 0x138;
    goto LAB_0040e0f1;
  case 0x1a:
    UVar16 = 0;
    pCVar8 = (LPCSTR)FUN_0043dc70(&DAT_00796eec,0x13d);
    pCVar9 = (LPCSTR)FUN_0043dc70(&DAT_00796eec,0x137);
    MessageBoxA((HWND)0x0,pCVar9,pCVar8,UVar16);
    uVar6 = 0x13f;
LAB_0040e744:
    nShowCmd = 1;
    lpDirectory = (LPCSTR)0x0;
    pCVar9 = (LPCSTR)0x0;
    pCVar8 = (LPCSTR)FUN_0043dc70(&DAT_00796eec,uVar6);
    ShellExecuteA((HWND)0x0,&DAT_00552728,pCVar8,pCVar9,lpDirectory,nShowCmd);
    break;
  case 0x1b:
    UVar16 = 0;
    pCVar8 = (LPCSTR)FUN_0043dc70(&DAT_00796eec,0x13d);
    uVar6 = 0x139;
LAB_0040e0f1:
    pCVar9 = (LPCSTR)FUN_0043dc70(&DAT_00796eec,uVar6);
    MessageBoxA((HWND)0x0,pCVar9,pCVar8,UVar16);
    break;
  case 0xcd:
    puVar17 = &DAT_005b1ed0;
    uVar6 = DAT_007934c8;
    uVar10 = FUN_0040a4d0(&DAT_00796878);
    pcVar11 = (char *)FUN_0043dc70(&DAT_00796eec,0x133);
    _sprintf(acStack_d48,pcVar11,uVar10,uVar6,puVar17);
    goto LAB_0040e1a0;
  case 0xce:
    puVar17 = &DAT_005b1ed0;
    uVar6 = DAT_007934c8;
    uVar10 = FUN_0040a4d0(&DAT_00796878);
    pcVar11 = (char *)FUN_0043dc70(&DAT_00796eec,0x134);
    _sprintf(acStack_d48,pcVar11,uVar10,uVar6,puVar17);
    goto LAB_0040e1a0;
  case 0xe1:
    uVar6 = FUN_0040a4d0(DAT_005b3484 + 0xf5b48);
    uVar10 = FUN_0040a4d0(&DAT_00e525e8);
    pcVar11 = (char *)FUN_0043dc70(&DAT_00796eec,0x12d);
    _sprintf(acStack_d48,pcVar11,uVar10,uVar6);
    goto LAB_0040e1a0;
  case 0xe2:
    puVar17 = &DAT_005b1ed0;
    pcVar11 = (char *)FUN_0043dc70(&DAT_00796eec,0x12e);
    _sprintf(acStack_d48,pcVar11,puVar17);
    goto LAB_0040e1ec;
  case 0xe3:
    uVar6 = *(undefined4 *)(DAT_005b3484 + 0x1a1e44);
    uVar10 = FUN_0040a4d0(&DAT_00e525e8);
    pcVar11 = (char *)FUN_0043dc70(&DAT_00796eec,0x12f);
    _sprintf(acStack_d48,pcVar11,uVar10,uVar6);
    UVar16 = 0;
    pCVar8 = (LPCSTR)FUN_0043dc70(&DAT_00796eec,0x13b);
    MessageBoxA((HWND)0x0,acStack_d48,pCVar8,UVar16);
    break;
  case 0xe4:
    puVar17 = &DAT_005b1ed0;
    pcVar11 = (char *)FUN_0043dc70(&DAT_00796eec,0x130);
    _sprintf(acStack_d48,pcVar11,puVar17);
    UVar16 = 0;
    pCVar8 = (LPCSTR)FUN_0043dc70(&DAT_00796eec,0x13b);
    MessageBoxA((HWND)0x0,acStack_d48,pCVar8,UVar16);
    break;
  case 0xe5:
    puVar17 = &DAT_005b1ed0;
    pcVar11 = (char *)FUN_0043dc70(&DAT_00796eec,0x132);
    _sprintf(acStack_d48,pcVar11,puVar17);
    UVar16 = 0;
    pCVar8 = (LPCSTR)FUN_0043dc70(&DAT_00796eec,0x13b);
    MessageBoxA((HWND)0x0,acStack_d48,pCVar8,UVar16);
    break;
  case 0xe6:
    uVar6 = FUN_0041e9a0(DAT_005b3484,99);
    uVar10 = FUN_0040a4d0(&DAT_00e525e8);
    pcVar11 = (char *)FUN_0043dc70(&DAT_00796eec,0x131);
    _sprintf(acStack_d48,pcVar11,uVar10,uVar6);
LAB_0040e1ec:
    UVar16 = 0;
    pCVar8 = (LPCSTR)FUN_0043dc70(&DAT_00796eec,0x13b);
    MessageBoxA((HWND)0x0,acStack_d48,pCVar8,UVar16);
    break;
  case 0xe7:
    puVar17 = &DAT_005b1ed0;
    pcVar11 = (char *)FUN_0043dc70(&DAT_00796eec,0x142);
    _sprintf(acStack_d48,pcVar11,puVar17);
LAB_0040e1a0:
    UVar16 = 0;
    pCVar8 = (LPCSTR)FUN_0043dc70(&DAT_00796eec,0x13b);
    MessageBoxA((HWND)0x0,acStack_d48,pCVar8,UVar16);
  }
LAB_0040e75c:
  iVar13 = 0;
  do {
    cVar1 = (&DAT_005b1ed0)[iVar13];
    aCStack_948[iVar13] = cVar1;
    iVar13 = iVar13 + 1;
  } while (cVar1 != '\0');
  pcVar11 = &cStack_949;
  do {
    pcVar15 = pcVar11;
    pcVar11 = pcVar15 + 1;
  } while (pcVar15[1] != '\0');
  *(undefined4 *)(pcVar15 + 1) = s_gunbound_ex__00552718._0_4_;
  *(undefined4 *)(pcVar15 + 5) = s_gunbound_ex__00552718._4_4_;
  *(undefined4 *)(pcVar15 + 9) = s_gunbound_ex__00552718._8_4_;
  pcVar15[0xd] = s_gunbound_ex__00552718[0xc];
  pvVar2 = FindFirstFileA(aCStack_948,&_Stack_548);
  if (pvVar2 != (HANDLE)0xffffffff) {
    iVar13 = 0;
    do {
      cVar1 = (&DAT_005b1ed0)[iVar13];
      acStack_d48[iVar13] = cVar1;
      iVar13 = iVar13 + 1;
    } while (cVar1 != '\0');
    pcVar11 = &cStack_d49;
    do {
      pcVar15 = pcVar11;
      pcVar11 = pcVar15 + 1;
    } while (pcVar15[1] != '\0');
    *(undefined4 *)(pcVar15 + 1) = s_gunbound_exe_00552708._0_4_;
    *(undefined4 *)(pcVar15 + 5) = s_gunbound_exe_00552708._4_4_;
    *(undefined4 *)(pcVar15 + 9) = s_gunbound_exe_00552708._8_4_;
    pcVar15[0xd] = s_gunbound_exe_00552708[0xc];
    FUN_00525f26(acStack_d48);
    MoveFileA(aCStack_948,acStack_d48);
  }
  return 0;
}
