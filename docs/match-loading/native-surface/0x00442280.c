
int __fastcall FUN_00442280(int param_1)

{
  undefined4 *puVar1;
  byte bVar2;
  char cVar3;
  uint uVar4;
  int iVar5;
  uint uVar6;
  char *pcVar7;
  char *pcVar8;
  int iVar9;
  LRESULT LVar10;
  HIMC pHVar11;
  int iVar12;
  int iVar13;
  int iVar14;
  undefined2 *puVar15;
  int iVar16;
  int *piVar17;
  uint uVar18;
  bool bVar19;
  tagCOMPOSITIONFORM *lpCompForm;
  int local_b0;
  int local_ac;
  char local_a5;
  int local_a4;
  int local_a0;
  tagCOMPOSITIONFORM local_9c;
  char local_80 [128];
  
  local_a4 = param_1;
  if ((DAT_0079352c != 0) && (iVar5 = FUN_004f30c0(), iVar5 != 0)) {
    if (*(char *)(iVar5 + 0x18) == '\x01') {
      FUN_004ed6a0(0);
    }
    else {
      FUN_004eb9c0(0);
    }
  }
  if (DAT_00e55a34 == -1) {
    if ((DAT_0079352c != 0) && (iVar5 = FUN_004f30c0(), iVar5 != 0)) {
      if (*(char *)(iVar5 + 0x18) == '\x01') {
        FUN_004ed6a0(0x243,0x10c);
      }
      else {
        FUN_004eb9c0(0x17);
      }
    }
    FUN_00442d50(param_1);
  }
  FUN_004eadb0();
  if ((DAT_0079352c != 0) && (iVar5 = FUN_004f30c0(), iVar5 != 0)) {
    if (*(char *)(iVar5 + 0x18) == '\x01') {
      FUN_004ed6a0(0x6b,0x237);
    }
    else {
      FUN_004eb9c0(0x16);
    }
  }
  FUN_004eadb0();
  bVar2 = *(byte *)(DAT_005b3484 + 0x475c4);
  if ((DAT_0079352c != 0) && (iVar5 = FUN_004f30c0(), iVar5 != 0)) {
    if (*(char *)(iVar5 + 0x18) == '\x01') {
      FUN_004ed6a0(0x1a,0x12);
    }
    else {
      FUN_004eb9c0((uint)bVar2 * 2);
    }
  }
  local_a0 = 0;
  local_ac = 0;
  local_b0 = 499;
LAB_00442440:
  uVar18 = 0x2000 << ((byte)local_a0 & 0x1f);
  EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  uVar6 = FUN_0040a2e0();
  LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  if ((uVar6 & uVar18) == uVar18) {
    EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    FUN_0040a2e0();
    LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    iVar5 = FUN_0040a2e0();
    LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    uVar6 = iVar5 + 0x10c;
    if ((DAT_0079352c != 0) && (-1 < (int)uVar6)) {
      iVar5 = *(int *)(DAT_00ea0e1c + 0x1c);
      uVar18 = *(uint *)(iVar5 + 4);
      while (uVar18 < 0x33) {
        if (uVar18 == 0x32) {
          iVar5 = *(int *)(iVar5 + 0x10);
          uVar18 = *(uint *)(iVar5 + 8);
          if (uVar18 <= uVar6) goto LAB_00442525;
          break;
        }
        iVar5 = *(int *)(iVar5 + 0x1c);
        uVar18 = *(uint *)(iVar5 + 4);
      }
    }
  }
  else if (DAT_0079352c != 0) {
    iVar5 = *(int *)(DAT_00ea0e1c + 0x1c);
    uVar6 = *(uint *)(iVar5 + 4);
    while (uVar6 < 0x33) {
      if (uVar6 == 0x32) {
        iVar5 = *(int *)(iVar5 + 0x10);
        uVar6 = *(uint *)(iVar5 + 8);
        if (uVar6 < 0x10d) goto LAB_00442591;
        break;
      }
      iVar5 = *(int *)(iVar5 + 0x1c);
      uVar6 = *(uint *)(iVar5 + 4);
    }
  }
  goto LAB_004425da;
  while( true ) {
    iVar5 = *(int *)(iVar5 + 0x10);
    uVar18 = *(uint *)(iVar5 + 8);
    if (uVar6 < uVar18) break;
LAB_00442525:
    if (uVar18 == uVar6) {
      if (*(char *)(iVar5 + 0x18) != '\x01') goto LAB_004425cd;
      FUN_004ed6a0(local_b0,0xe);
      break;
    }
  }
  goto LAB_004425da;
  while( true ) {
    iVar5 = *(int *)(iVar5 + 0x10);
    uVar6 = *(uint *)(iVar5 + 8);
    if (0x10c < uVar6) break;
LAB_00442591:
    if (uVar6 == 0x10c) {
      if (*(char *)(iVar5 + 0x18) == '\x01') {
        FUN_004ed6a0(local_b0,0xe);
      }
      else {
        uVar6 = 0x10c;
LAB_004425cd:
        FUN_004eb9c0(uVar6);
      }
      break;
    }
  }
LAB_004425da:
  iVar5 = local_a4;
  local_b0 = local_b0 + 0x2c;
  local_a0 = local_a0 + 1;
  local_ac = local_ac + 0x224;
  if (0x326 < local_b0) goto code_r0x00442607;
  goto LAB_00442440;
code_r0x00442607:
  pcVar8 = (char *)(local_a4 + 8);
  pcVar7 = pcVar8;
  do {
    cVar3 = *pcVar7;
    pcVar7 = pcVar7 + 1;
  } while (cVar3 != '\0');
  FUN_004eb510(0x27,0);
  do {
    cVar3 = *pcVar8;
    pcVar8 = pcVar8 + 1;
  } while (cVar3 != '\0');
  FUN_004eb450(0x27,0xffff);
  iVar9 = DAT_005b3484;
  if (0xd < *(int *)(iVar5 + 4)) {
    local_b0 = 0;
    local_ac = 0;
    piVar17 = (int *)(iVar5 + 300);
LAB_00442690:
    iVar5 = local_b0;
    if (*(char *)(iVar9 + 0x45914 + local_b0) != '\0') {
      uVar6 = (uint)(*(char *)(iVar9 + 0x4590c + local_b0) == '\0') * 2 + 0x18;
      EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
      iVar9 = FUN_0040a2e0();
      local_a5 = iVar9 == iVar5;
      LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
      if (local_a5 != '\0') {
        uVar18 = *(int *)(local_a4 + 4) / 10 & 0x80000001;
        bVar19 = uVar18 == 0;
        if ((int)uVar18 < 0) {
          bVar19 = (uVar18 - 1 | 0xfffffffe) == 0xffffffff;
        }
        if (bVar19) {
          uVar6 = 0x19;
        }
      }
      if (DAT_0079352c != 0) {
        iVar5 = *(int *)(DAT_00ea0e1c + 0x1c);
        uVar18 = *(uint *)(iVar5 + 4);
        while (uVar18 < 0x2711) {
          if (uVar18 == 10000) {
            iVar5 = *(int *)(iVar5 + 0x10);
            uVar18 = *(uint *)(iVar5 + 8);
            if (uVar18 <= uVar6) goto LAB_00442760;
            break;
          }
          iVar5 = *(int *)(iVar5 + 0x1c);
          uVar18 = *(uint *)(iVar5 + 4);
        }
      }
      goto LAB_00442790;
    }
    goto LAB_00442805;
  }
LAB_00442831:
  _sprintf(local_80,&DAT_00551ed4,*(int *)(iVar9 + 0x44e60) + 1);
  pcVar8 = local_80;
  do {
    cVar3 = *pcVar8;
    pcVar8 = pcVar8 + 1;
  } while (cVar3 != '\0');
  local_ac = (int)pcVar8 - (int)(local_80 + 1);
  if (local_ac == 0) {
LAB_00442907:
    iVar9 = DAT_005b3484;
    pcVar8 = local_80;
    do {
      cVar3 = *pcVar8;
      pcVar8 = pcVar8 + 1;
    } while (cVar3 != '\0');
    FUN_004eb450(0x118,0xffff);
    if (*(char *)(iVar9 + 0x44ee4) != '\0') {
      FUN_004eb450(0x117,0xffff);
    }
    FUN_0041bce0(iVar9);
    if (DAT_007933b8 == '\x01') {
      if (*(char *)(DAT_007934e4 + 8) == '\0') {
        local_ac = 0;
        local_b0 = 0;
      }
      else {
        puVar1 = (undefined4 *)(DAT_007934e4 + 4);
        LVar10 = SendMessageA(*(HWND *)(DAT_007934e4 + 4),0xb0,(WPARAM)&local_b0,(LPARAM)&local_ac);
        if (LVar10 == -1) {
          local_ac = 0;
          local_b0 = 0;
        }
        local_9c.ptCurrentPos.x = local_b0 * 6 + 0xca;
        lpCompForm = &local_9c;
        local_9c.dwStyle = 2;
        local_9c.ptCurrentPos.y = 0x21b;
        pHVar11 = ImmGetContext((HWND)*puVar1);
        ImmSetCompositionWindow(pHVar11,lpCompForm);
      }
      if ((*(char *)(DAT_007934e4 + 8) == '\0') ||
         (iVar5 = GetWindowTextA(*(HWND *)(DAT_007934e4 + 4),local_80,0x80), iVar5 == 0)) {
        local_80[0] = '\0';
      }
      iVar5 = local_b0;
      if (local_b0 == -1) {
        pcVar8 = local_80;
        do {
          cVar3 = *pcVar8;
          pcVar8 = pcVar8 + 1;
        } while (cVar3 != '\0');
        iVar5 = (int)pcVar8 - (int)(local_80 + 1);
      }
      iVar9 = local_ac;
      if (local_ac == -1) {
        pcVar8 = local_80;
        do {
          cVar3 = *pcVar8;
          pcVar8 = pcVar8 + 1;
        } while (cVar3 != '\0');
        iVar9 = (int)pcVar8 - (int)(local_80 + 1);
      }
      iVar12 = iVar9 * 6 + iVar5 * -6 + 2;
      iVar9 = iVar5 * 6 + 0xca;
      if (((DAT_0079352c != 0) && (0x21a < DAT_0056df34)) && (DAT_00793534 < 0x21c)) {
        iVar13 = iVar12;
        iVar14 = iVar9;
        if (iVar9 < DAT_00793530) {
          iVar13 = (iVar9 - DAT_00793530) + iVar12;
          iVar14 = DAT_00793530;
        }
        if (DAT_0056df30 < iVar14 + iVar13) {
          iVar13 = (DAT_0056df30 - iVar14) + 1;
        }
        if (0 < iVar13) {
          FUN_004f26f0(DAT_0079352c + (DAT_005b3620 * 0x21b + iVar14) * 2,0xf800,iVar13);
        }
      }
      if (((DAT_0079352c != 0) && (0x225 < DAT_0056df34)) && (DAT_00793534 < 0x227)) {
        iVar13 = iVar12;
        iVar14 = iVar9;
        if (iVar9 < DAT_00793530) {
          iVar13 = (iVar9 - DAT_00793530) + iVar12;
          iVar14 = DAT_00793530;
        }
        if (DAT_0056df30 < iVar14 + iVar13) {
          iVar13 = (DAT_0056df30 - iVar14) + 1;
        }
        if (0 < iVar13) {
          FUN_004f26f0(DAT_0079352c + (DAT_005b3620 * 0x226 + iVar14) * 2,0xf800,iVar13);
        }
      }
      iVar13 = DAT_0056df34;
      iVar14 = 0xc;
      if (((DAT_0079352c != 0) && (iVar9 <= DAT_0056df30)) && (DAT_00793530 <= iVar9)) {
        iVar16 = 0x21b;
        if (0x21b < DAT_00793534) {
          iVar14 = 0x227 - DAT_00793534;
          iVar16 = DAT_00793534;
        }
        if (DAT_0056df34 < iVar16 + iVar14) {
          iVar14 = (DAT_0056df34 - iVar16) + 1;
        }
        if ((0 < iVar14) &&
           (puVar15 = (undefined2 *)(DAT_0079352c + (iVar16 * DAT_005b3620 + iVar9) * 2), 0 < iVar14
           )) {
          do {
            iVar14 = iVar14 + -1;
            *puVar15 = 0xf800;
            puVar15 = puVar15 + DAT_005b3620;
          } while (iVar14 != 0);
        }
      }
      iVar9 = 0xc;
      iVar12 = iVar5 * 6 + 0xc9 + iVar12;
      if (((DAT_0079352c != 0) && (iVar12 <= DAT_0056df30)) && (DAT_00793530 <= iVar12)) {
        iVar5 = 0x21b;
        if (0x21b < DAT_00793534) {
          iVar9 = 0x227 - DAT_00793534;
          iVar5 = DAT_00793534;
        }
        if (iVar13 < iVar5 + iVar9) {
          iVar9 = (iVar13 - iVar5) + 1;
        }
        if ((0 < iVar9) &&
           (puVar15 = (undefined2 *)(DAT_0079352c + (iVar5 * DAT_005b3620 + iVar12) * 2), 0 < iVar9)
           ) {
          do {
            iVar9 = iVar9 + -1;
            *puVar15 = 0xf800;
            puVar15 = puVar15 + DAT_005b3620;
          } while (iVar9 != 0);
        }
      }
      FUN_004eb450(0x21c,0);
      iVar12 = FUN_004eb450(0x21b,0xffe0);
      iVar5 = local_a4;
      iVar9 = DAT_005b3484;
    }
    else {
      iVar12 = FUN_004eb450(0x208,0xffff);
    }
    if (((*(short *)(&DAT_006aa660 + iVar9) != -1) &&
        (iVar12 = *(int *)(iVar5 + 4) / 0x14, *(int *)(iVar5 + 4) % 0x14 < 10)) &&
       (iVar12 = 0, DAT_0079352c != 0)) {
      iVar12 = *(int *)(DAT_00ea0e1c + 0x1c);
      uVar6 = *(uint *)(iVar12 + 4);
      if (uVar6 < 0x2713) {
        while (uVar6 != 0x2712) {
          iVar12 = *(int *)(iVar12 + 0x1c);
          uVar6 = *(uint *)(iVar12 + 4);
          if (0x2712 < uVar6) {
            return iVar12;
          }
        }
        iVar12 = *(int *)(iVar12 + 0x10);
        bVar19 = true;
        if (*(int *)(iVar12 + 8) == 0) {
          while (!bVar19) {
            iVar12 = *(int *)(iVar12 + 0x10);
            bVar19 = *(int *)(iVar12 + 8) == 0;
            if (!bVar19) {
              return iVar12;
            }
          }
          if (*(char *)(iVar12 + 0x18) == '\x01') {
            iVar5 = FUN_004ed6a0(0x1a,0x12);
            return iVar5;
          }
          iVar12 = FUN_004eb9c0(0);
        }
      }
    }
    return iVar12;
  }
  iVar9 = 0x29;
  uVar6 = 0;
LAB_00442870:
  uVar18 = (int)local_80[uVar6] + 0xd2;
  if ((DAT_0079352c != 0) && (-1 < (int)uVar18)) {
    iVar12 = *(int *)(DAT_00ea0e1c + 0x1c);
    uVar4 = *(uint *)(iVar12 + 4);
    while (uVar4 < 0x33) {
      if (uVar4 == 0x32) {
        iVar12 = *(int *)(iVar12 + 0x10);
        uVar4 = *(uint *)(iVar12 + 8);
        if (uVar4 <= uVar18) goto LAB_004428b2;
        break;
      }
      iVar12 = *(int *)(iVar12 + 0x1c);
      uVar4 = *(uint *)(iVar12 + 4);
    }
  }
  goto LAB_004428eb;
  while( true ) {
    iVar5 = *(int *)(iVar5 + 0x10);
    uVar18 = *(uint *)(iVar5 + 8);
    if (uVar6 < uVar18) break;
LAB_00442760:
    if (uVar18 == uVar6) {
      if (*(char *)(iVar5 + 0x18) == '\x01') {
        FUN_004ed6a0(piVar17[-8] + 0x1a,*piVar17 + 2);
      }
      else {
        FUN_004eb9c0(uVar6);
      }
      break;
    }
  }
LAB_00442790:
  iVar9 = DAT_005b3484;
  pcVar8 = (char *)(local_ac + 0x457f1 + DAT_005b3484);
  do {
    cVar3 = *pcVar8;
    pcVar8 = pcVar8 + 1;
  } while (cVar3 != '\0');
  FUN_004eb510(*piVar17 + 5,
               -(uint)(*(char *)(DAT_005b3484 + 0x4590c + local_b0) !=
                      *(char *)(DAT_005b3484 + 0x3b6c0)) & 0xfae8);
  FUN_004eb450(*piVar17 + 5,0xffff);
LAB_00442805:
  local_ac = local_ac + 0xd;
  local_b0 = local_b0 + 1;
  piVar17 = piVar17 + 1;
  if (0x67 < local_ac) goto code_r0x00442825;
  goto LAB_00442690;
code_r0x00442825:
  iVar5 = local_a4;
  goto LAB_00442831;
  while( true ) {
    iVar12 = *(int *)(iVar12 + 0x10);
    uVar4 = *(uint *)(iVar12 + 8);
    if (uVar18 < uVar4) break;
LAB_004428b2:
    if (uVar4 == uVar18) {
      if (*(char *)(iVar12 + 0x18) == '\x01') {
        FUN_004ed6a0(iVar9,0x117);
      }
      else {
        FUN_004eb9c0(uVar18);
      }
      break;
    }
  }
LAB_004428eb:
  pcVar8 = local_80;
  uVar6 = uVar6 + 1;
  iVar9 = iVar9 + 8;
  do {
    cVar3 = *pcVar8;
    pcVar8 = pcVar8 + 1;
  } while (cVar3 != '\0');
  if ((uint)((int)pcVar8 - (int)(local_80 + 1)) <= uVar6) goto LAB_00442907;
  goto LAB_00442870;
}

