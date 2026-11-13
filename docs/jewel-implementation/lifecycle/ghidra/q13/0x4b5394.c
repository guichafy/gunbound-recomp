
/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void __thiscall FUN_004b4100(int *param_1,int param_2,ushort param_3,byte *param_4)

{
  bool bVar1;
  char cVar2;
  undefined1 uVar3;
  undefined2 uVar4;
  char *pcVar5;
  int iVar6;
  int *piVar7;
  int iVar8;
  undefined4 uVar9;
  uint uVar10;
  uint *puVar11;
  undefined *puVar12;
  byte bVar13;
  byte bVar14;
  byte *pbVar15;
  uint uVar16;
  int iVar17;
  undefined4 *unaff_FS_OFFSET;
  undefined4 uVar18;
  undefined4 uVar19;
  byte local_9b5;
  uint local_9b4;
  int local_9b0;
  int *local_9ac;
  int local_9a8;
  int local_9a4 [2];
  char local_99c [128];
  char local_91c [128];
  undefined1 local_89c [20];
  int *local_888;
  undefined1 local_67c;
  int *local_664;
  undefined1 local_458;
  undefined1 local_454 [548];
  undefined1 local_230 [548];
  undefined4 local_c;
  undefined1 *puStack_8;
  uint local_4;

  local_4 = 0xffffffff;
  puStack_8 = &LAB_0053e03c;
  local_c = *unaff_FS_OFFSET;
  *unaff_FS_OFFSET = &local_c;
  iVar6 = DAT_007934e8;
  local_9ac = param_1;
  if (param_3 < 0x4000) {
    if (param_3 == 0x3fff) {
      *(undefined4 *)(DAT_007934e8 + 0x44d0) = 6;
      *(undefined2 *)(iVar6 + 0x4d4) = 0x2000;
      *(undefined2 *)(iVar6 + 0x4d6) = 0xffff;
      *(int *)(iVar6 + 0x44d0) = *(int *)(iVar6 + 0x44d0) + 2;
      FUN_004d2680();
      *(undefined4 *)(DAT_005b3484 + 0x44e60) = 0xffffffff;
      goto LAB_004b541a;
    }
    if (0x3233 < param_3) {
      if (param_3 == 0x3400) {
        cVar2 = FUN_0040b390(DAT_005b3484 + 0x3b49c,DAT_005b3484 + 0x3b6c4);
        if ((cVar2 != '\0') && ((char)param_1[0x474] != '\0')) {
          FUN_00413bf0();
        }
        if (1 < param_2) {
          FUN_00425a30(DAT_005b3484);
        }
        local_9b0 = 0;
        do {
          iVar6 = local_9b0;
          cVar2 = FUN_004065a0();
          if (cVar2 == '\x01') {
            cVar2 = FUN_0040b390(DAT_005b3484 + 0x3b6c4,DAT_005b3484 + 0x3b49c);
            if (cVar2 == '\0') {
              FUN_004e6c90(0xc302);
              iVar8 = DAT_005b3484;
              (&DAT_00e9aacc)[DAT_00e9accc] = (char)iVar6;
              DAT_00e9accc = DAT_00e9accc + 1;
              uVar9 = FUN_0040a4d0(iVar8 + 0xeba98);
              *(undefined4 *)(&DAT_00e9aacc + DAT_00e9accc) = uVar9;
              DAT_00e9accc = DAT_00e9accc + 4;
              if (iVar6 == 0xe) {
                uVar9 = FUN_0045d360(0);
                *(undefined4 *)(&DAT_00e9aacc + DAT_00e9accc) = uVar9;
                DAT_00e9accc = DAT_00e9accc + 4;
              }
              uVar9 = FUN_0040a4d0(DAT_005b3484 + 0x3b6c4);
              iVar8 = DAT_005b3484;
              *(undefined4 *)(&DAT_006a7704 + DAT_005b3484) = uVar9;
              uVar9 = FUN_0040a4d0(iVar8 + 0x3b6c4);
              FUN_004e7140(uVar9);
            }
            else {
              iVar8 = iVar6 * 8 + DAT_005b3484;
              *(undefined4 *)(&DAT_006a7670 + iVar8) = 0;
              *(undefined4 *)((int)(&DAT_006a7670 + iVar8) + 4) = 0;
              FUN_004d2130(iVar6);
              FUN_004261d0();
              local_9a8 = 0xc302;
              FUN_004e8a70();
              if (local_9b4 != DAT_00e9af14) {
                FUN_004e87b0(&DAT_00e9af10,&local_9ac,local_9b4);
              }
              iVar6 = local_9b0;
            }
          }
          local_9b0 = iVar6 + 1;
        } while (local_9b0 < 0x10);
      }
      goto LAB_004b541a;
    }
    if (param_3 == 0x3233) {
      if (*(short *)param_4 == 0) {
        DAT_005b33ec = 9;
        DAT_007934d4 = 0;
        DAT_0056d108 = 0;
        _DAT_007934d8 = 1;
        FUN_004e6c90(0x8103);
        FUN_004e6fc0();
        iVar6 = DAT_005b3484;
        if (*(int *)(&DAT_006a64b4 + DAT_005b3484) != -1) {
          FUN_004eeae0();
          iVar6 = DAT_005b3484;
          *(undefined4 *)(&DAT_006a64b4 + DAT_005b3484) = 0xffffffff;
        }
        if (*(FILE **)(&DAT_006a9b68 + iVar6) != (FILE *)0x0) {
          local_9b5 = 2;
          _fwrite(&local_9b5,1,1,*(FILE **)(&DAT_006a9b68 + iVar6));
          _fclose(*(FILE **)(&DAT_006a9b68 + DAT_005b3484));
          *(undefined4 *)(&DAT_006a9b68 + DAT_005b3484) = 0;
        }
      }
      else {
        *(undefined4 *)(DAT_007934e8 + 0x44d0) = 6;
        *(undefined2 *)(iVar6 + 0x4d4) = 0x2000;
        *(undefined2 *)(iVar6 + 0x4d6) = 0xffff;
        *(int *)(iVar6 + 0x44d0) = *(int *)(iVar6 + 0x44d0) + 2;
        FUN_004d2680();
        *(undefined4 *)(DAT_005b3484 + 0x44e60) = 0xffffffff;
      }
      goto LAB_004b541a;
    }
    if (param_3 == 0x2001) {
      if (*(short *)param_4 == 0) {
        DAT_005b33ec = 3;
        DAT_007934d4 = 0;
        DAT_0056d108 = 0;
        _DAT_007934d8 = 1;
        if (DAT_007934f4 == 0) {
          FUN_00404410(&DAT_00e53e88);
        }
        else {
          FUN_00405ba0();
        }
      }
      goto LAB_004b541a;
    }
    if (param_3 != 0x3020) goto LAB_004b541a;
    iVar6 = (uint)*param_4 * 0xd + 0x457f1 + DAT_005b3484;
    pcVar5 = (char *)FUN_0043dc70(&DAT_00796eec,0x25f);
    _sprintf(local_91c,pcVar5,iVar6);
    (**(code **)(*param_1 + 0x28))(local_91c,2,6);
    cVar2 = FUN_004065a0();
    if (cVar2 == '\x01') {
      FUN_0040a470(0xffffffff);
      FUN_004cf050(param_1);
      FUN_00406500(0);
      FUN_00406500(1);
      goto LAB_004b541a;
    }
    local_9b5 = *param_4;
    uVar16 = (uint)local_9b5;
    local_9b4 = uVar16;
    local_9a8 = FUN_004206f0(DAT_005b3484);
    cVar2 = FUN_0040b390(DAT_005b3484 + 0x3b6c4,DAT_005b3484 + 0x3b49c);
    if (((cVar2 != '\0') && (uVar16 == param_1[0x428])) && (param_4[2] != 0)) {
      FUN_004e6c90(0x307);
      (&DAT_00e9aacc)[DAT_00e9accc] = 0xff;
      DAT_00e9accc = DAT_00e9accc + 1;
      FUN_004e6fc0();
      FUN_004cb280(param_1);
    }
    cVar2 = FUN_0040b270(DAT_005b3484 + 0x45354,1);
    if ((cVar2 != '\0') || (cVar2 = FUN_0040b270(DAT_005b3484 + 0x45354,3), cVar2 != '\0')) {
      iVar6 = 0;
      if (0 < param_1[0x227]) {
        puVar11 = (uint *)(param_1 + 0x328);
LAB_004b42d0:
        if (*puVar11 != uVar16) goto code_r0x004b42d4;
        if (iVar6 < param_1[0x227] + -1) {
          piVar7 = param_1 + iVar6 + 0x228;
          do {
            *piVar7 = piVar7[1];
            piVar7[0x80] = piVar7[0x81];
            piVar7[0x100] = piVar7[0x101];
            iVar6 = iVar6 + 1;
            piVar7 = piVar7 + 1;
          } while (iVar6 < param_1[0x227] + -1);
        }
        param_1[0x227] = param_1[0x227] + -1;
      }
    }
LAB_004b4324:
    local_9b0 = uVar16 * 0x224;
    iVar6 = FUN_0040a4d0(local_9b0 + 0xebef4 + DAT_005b3484);
    if (iVar6 == -1) {
      cVar2 = FUN_0040b270(DAT_005b3484 + 0x45354,1);
      if ((cVar2 == '\0') || ((char)param_1[0x474] != '\0')) goto LAB_004b458f;
      iVar6 = FUN_0040a4d0(DAT_005b3484 + 0x473a0);
      iVar8 = FUN_0040a4d0(&DAT_00796aa0);
      FUN_0040aaf0((iVar6 / 2) * iVar8);
      uVar16 = 0;
      iVar8 = 0;
      iVar17 = 0;
      iVar6 = DAT_005b3484;
      do {
        if (((*(char *)(iVar6 + 0x5010d + uVar16) != '\0') &&
            (*(char *)(iVar6 + 0x50126 + uVar16) == *(char *)(local_9b4 + 0x50126 + iVar6))) &&
           (uVar16 != local_9b4)) {
          uVar9 = FUN_0040a4d0(&DAT_00796aa0);
          FUN_0040aab0(uVar9);
          uVar9 = FUN_0040a4d0(&DAT_00796aa0);
          iVar6 = iVar8 + 0x50196 + DAT_005b3484;
          pcVar5 = (char *)FUN_0043dc70(&DAT_00796eec,0x281);
          _sprintf(local_99c,pcVar5,iVar6,uVar9);
          (**(code **)(*param_1 + 0x28))(local_99c,4,3);
          iVar6 = DAT_005b3484;
        }
        iVar17 = iVar17 + 0x224;
        uVar16 = uVar16 + 1;
        iVar8 = iVar8 + 0xd;
      } while (iVar17 < 0x1120);
      uVar16 = local_9b4;
    }
    else {
      FUN_004cf050(param_1);
      iVar6 = FUN_0040a4d0(DAT_005b3484 + 0x473a0);
      iVar8 = FUN_0040a4d0(&DAT_00796aa0);
      FUN_0040aaf0((iVar6 / 2 + -1) * iVar8);
      if ((char)param_1[0x474] == '\0') {
        uVar16 = 0;
        iVar8 = 0;
        iVar17 = 0;
        iVar6 = DAT_005b3484;
        do {
          if (((*(char *)(iVar6 + 0x5010d + uVar16) != '\0') &&
              (*(char *)(iVar6 + 0x50126 + uVar16) == *(char *)(local_9b4 + 0x50126 + iVar6))) &&
             (uVar16 != local_9b4)) {
            uVar9 = FUN_0040a4d0(&DAT_00796aa0);
            FUN_0040aab0(uVar9);
            uVar9 = FUN_0040a4d0(&DAT_00796aa0);
            iVar6 = iVar8 + 0x50196 + DAT_005b3484;
            pcVar5 = (char *)FUN_0043dc70(&DAT_00796eec,0x281);
            _sprintf(local_91c,pcVar5,iVar6,uVar9);
            (**(code **)(*param_1 + 0x28))(local_91c,4,3);
            iVar6 = DAT_005b3484;
          }
          iVar17 = iVar17 + 0x224;
          uVar16 = uVar16 + 1;
          iVar8 = iVar8 + 0xd;
        } while (iVar17 < 0x1120);
        uVar16 = local_9b4;
      }
      else {
LAB_004b458f:
      }
    }
    EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    FUN_0040a380(0xffffffff);
    LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    if ((uVar16 == param_1[0x428]) || (uVar10 = FUN_004d0dd0(), uVar16 == uVar10)) {
      cVar2 = FUN_0040b390(DAT_005b3484 + 0x3b6c4,DAT_005b3484 + 0x3b49c);
      if (cVar2 != '\0') {
        FUN_004e6c90(0x8500);
        iVar6 = local_9a8;
        (&DAT_00e9aacc)[DAT_00e9accc] = local_9b5;
        DAT_00e9accc = DAT_00e9accc + 1;
        uVar4 = FUN_0040a4d0(local_9a8 + 0x90c);
        *(undefined2 *)(&DAT_00e9aacc + DAT_00e9accc) = uVar4;
        DAT_00e9accc = DAT_00e9accc + 2;
        uVar4 = FUN_0040a4d0(iVar6 + 0xb30);
        *(undefined2 *)(&DAT_00e9aacc + DAT_00e9accc) = uVar4;
        DAT_00e9accc = DAT_00e9accc + 2;
        uVar3 = FUN_0040b270(iVar6 + 0x1c54,1);
        (&DAT_00e9aacc)[DAT_00e9accc] = uVar3;
        DAT_00e9accc = DAT_00e9accc + 1;
        FUN_004e6fc0();
      }
      iVar6 = DAT_005b3484;
      pbVar15 = &DAT_006a9b72 + DAT_005b3484;
      EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
      iVar8 = _rand();
      *pbVar15 = (byte)iVar8;
      iVar8 = _rand();
      bVar14 = *pbVar15;
      (&DAT_006a9b73)[iVar6] = (byte)iVar8;
      bVar13 = bVar14 & 7;
      bVar13 = ~('\x01' << bVar13) & (byte)iVar8 | '\0' << bVar13;
      (&DAT_006a9b73)[iVar6] = bVar13;
      (&DAT_006a9b74)[iVar6] = bVar14 + bVar13 + -0x34;
      LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
      iVar6 = DAT_005b3484;
      pbVar15 = &DAT_006a9b6f + DAT_005b3484;
      EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
      iVar8 = _rand();
      *pbVar15 = (byte)iVar8;
      iVar8 = _rand();
      bVar14 = *pbVar15;
      (&DAT_006a9b70)[iVar6] = (byte)iVar8;
      bVar13 = '\x01' << (bVar14 & 7);
      bVar13 = ~bVar13 & (byte)iVar8 | bVar13;
      (&DAT_006a9b70)[iVar6] = bVar13;
      (&DAT_006a9b71)[iVar6] = bVar14 + bVar13 + -0x34;
      LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    }
    cVar2 = FUN_004065a0();
    if ((((cVar2 == '\x01') &&
         (cVar2 = FUN_0040b390(DAT_005b3484 + 0x3b49c,DAT_005b3484 + 0x3b6c4), cVar2 != '\0')) &&
        (cVar2 = FUN_004065a0(), cVar2 == '\0')) &&
       ((DAT_007934d0 != 0xb || (cVar2 = FUN_004065a0(), cVar2 != '\x01')))) {
      FUN_00413bf0();
    }
    goto LAB_004b541a;
  }
  if (param_3 == 0x4102) {
    local_9b5 = *param_4;
    piVar7 = *(int **)(param_4 + 1);
    uVar16 = (uint)local_9b5;
    local_9ac = piVar7;
    iVar6 = FUN_004206f0(DAT_005b3484);
    if (iVar6 != 0) {
      uVar10 = FUN_0040a4d0(DAT_005b3484 + 0x3b49c);
      if ((uVar16 == uVar10) && (cVar2 = FUN_004065a0(), iVar8 = DAT_007934e8, cVar2 != '\0')) {
        *(undefined4 *)(DAT_007934e8 + 0x44d0) = 6;
        *(undefined2 *)(iVar8 + 0x4d4) = 0x2000;
        *(undefined2 *)(iVar8 + 0x4d6) = 0xffff;
        *(int *)(iVar8 + 0x44d0) = *(int *)(iVar8 + 0x44d0) + 2;
        FUN_004d2680();
        FUN_00422f10(*(undefined4 *)(DAT_005b3484 + 0x44e60));
        iVar8 = DAT_005b3484;
        *(undefined4 *)(DAT_005b3484 + 0x44e60) = 0xffffffff;
        piVar7 = local_9ac;
      }
      else {
        iVar8 = DAT_005b3484;
      }
      if (((uint)piVar7 & 0xf000) == 0xf000) {
        cVar2 = FUN_0040b390(iVar8 + 0x3b6c4,iVar8 + 0x3b49c);
        if (cVar2 != '\0') {
          FUN_004e6c90(0x8500);
          (&DAT_00e9aacc)[DAT_00e9accc] = local_9b5;
          DAT_00e9accc = DAT_00e9accc + 1;
          uVar4 = FUN_0040a4d0(iVar6 + 0x90c);
          *(undefined2 *)(&DAT_00e9aacc + DAT_00e9accc) = uVar4;
          DAT_00e9accc = DAT_00e9accc + 2;
          uVar4 = FUN_0040a4d0(iVar6 + 0xb30);
          *(undefined2 *)(&DAT_00e9aacc + DAT_00e9accc) = uVar4;
          DAT_00e9accc = DAT_00e9accc + 2;
          uVar3 = FUN_0040b270(iVar6 + 0x1c54,1);
          (&DAT_00e9aacc)[DAT_00e9accc] = uVar3;
          DAT_00e9accc = DAT_00e9accc + 1;
          FUN_004e6fc0();
        }
        cVar2 = FUN_0040b270(DAT_005b3484 + 0x45354,1);
        if ((cVar2 != '\0') && (cVar2 = FUN_004065a0(), cVar2 == '\0')) {
          if (0 < param_1[0x42c]) {
            iVar6 = param_1[0x42c];
            bVar1 = false;
            do {
              if (local_9b5 == *(byte *)(param_1 + 0x42a)) {
                bVar1 = true;
              }
              iVar6 = iVar6 + -1;
            } while (iVar6 != 0);
            if (bVar1) goto LAB_004b541a;
          }
          cVar2 = *(char *)(uVar16 + 0x50126 + DAT_005b3484);
          if (cVar2 == '\0') {
            iVar6 = *param_1;
            uVar19 = 8;
            uVar18 = 3;
            uVar9 = FUN_0043dc70(&DAT_00796eec,0x25c);
            (**(code **)(iVar6 + 0x28))(uVar9,uVar18,uVar19);
            FUN_0040b060();
            cVar2 = FUN_0040b330(&DAT_0067e3d0 + DAT_005b3484,0);
          }
          else {
            if (cVar2 != '\x01') goto LAB_004b541a;
            iVar6 = *param_1;
            uVar19 = 8;
            uVar18 = 3;
            uVar9 = FUN_0043dc70(&DAT_00796eec,0x25d);
            (**(code **)(iVar6 + 0x28))(uVar9,uVar18,uVar19);
            FUN_0040b060();
            cVar2 = FUN_0040b330(&DAT_0067e5f4 + DAT_005b3484,0);
          }
          if (cVar2 != '\0') {
            FUN_0040a470(0);
          }
        }
      }
    }
    goto LAB_004b541a;
  }
  if (param_3 != 0x4410) {
    if (param_3 == 0x4413) {
      FUN_00405fb0();
      FUN_00405fb0();
      FUN_00405fb0();
      FUN_00405fb0();
      FUN_00405fb0();
      FUN_00405fb0();
      FUN_00405fb0();
      FUN_00405fb0();
      *(undefined1 *)(param_1 + 0x474) = 1;
      param_1[0x475] = 0;
      FUN_00406020(&DAT_00e9be90,0,0x10,0x3f8,s_b_result_confirm_00554074,0x29f,0x1b9,0x67,0x2d,1,0)
      ;
      iVar6 = DAT_005b3484;
      pbVar15 = (byte *)(DAT_005b3484 + 0x62152);
      EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
      iVar8 = _rand();
      *pbVar15 = (byte)iVar8;
      iVar8 = _rand();
      bVar14 = *pbVar15;
      *(byte *)(iVar6 + 0x62153) = (byte)iVar8;
      bVar13 = '\x01' << (bVar14 & 7);
      bVar13 = ~bVar13 & (byte)iVar8 | bVar13;
      *(byte *)(iVar6 + 0x62153) = bVar13;
      *(byte *)(iVar6 + 0x62154) = bVar14 + bVar13 + -0x34;
      LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    }
    goto LAB_004b541a;
  }
  cVar2 = FUN_004065a0();
  if (cVar2 != '\0') goto LAB_004b541a;
  FUN_00406500(1);
  local_67c = 0;
  local_888 = (int *)0x0;
  FUN_0040a380(0);
  local_4 = 0;
  local_458 = 0;
  local_664 = (int *)0x0;
  FUN_0040a380(0);
  local_4 = CONCAT31(local_4._1_3_,1);
  FUN_0040a440();
  FUN_0040a440();
  cVar2 = FUN_0040b270(DAT_005b3484 + 0x45354,3);
  if (cVar2 == '\0') {
LAB_004b4d38:
    uVar9 = FUN_0040a4d0(DAT_005b3484 + 0x473a0);
    switch(uVar9) {
    case 1:
    case 2:
      FUN_0040a440();
      break;
    case 3:
    case 4:
      FUN_0040a440();
      break;
    case 5:
    case 6:
      FUN_0040a440();
      break;
    case 7:
    case 8:
      FUN_0040a440();
      break;
    default:
      FUN_0040a440();
    }
    FUN_0040a440();
  }
  else {
    if (*(char *)(DAT_005b3484 + 0x62155) == '\0') {
      uVar9 = FUN_0040a4d0(&DAT_00796aa0);
      puVar12 = &DAT_0067e3d0 + DAT_005b3484;
    }
    else {
      uVar9 = FUN_0040a4d0(&DAT_00796aa0);
      puVar12 = &DAT_0067e5f4 + DAT_005b3484;
    }
    cVar2 = FUN_0040b300(puVar12,uVar9);
    if (cVar2 != '\0') goto LAB_004b4d38;
  }
  local_9b4 = 0;
  do {
    iVar6 = FUN_004206f0(DAT_005b3484);
    if (iVar6 != 0) {
      EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
      iVar8 = _rand();
      *(char *)(iVar6 + 0x8ba8) = (char)iVar8;
      iVar8 = _rand();
      local_9b5 = *(byte *)(iVar6 + 0x8ba8);
      *(byte *)(iVar6 + 0x8ba9) = (byte)iVar8;
      bVar14 = ~('\x01' << (local_9b5 & 7)) & (byte)iVar8 | '\0' << (local_9b5 & 7);
      *(byte *)(iVar6 + 0x8ba9) = bVar14;
      *(byte *)(iVar6 + 0x8baa) = local_9b5 + bVar14 + -0x34;
      LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
      EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
      iVar8 = _rand();
      *(char *)(iVar6 + 0x8bb1) = (char)iVar8;
      iVar8 = _rand();
      local_9b5 = *(byte *)(iVar6 + 0x8bb1);
      *(byte *)(iVar6 + 0x8bb2) = (byte)iVar8;
      bVar14 = ~('\x01' << (local_9b5 & 7)) & (byte)iVar8 | '\0' << (local_9b5 & 7);
      *(byte *)(iVar6 + 0x8bb2) = bVar14;
      *(byte *)(iVar6 + 0x8bb3) = local_9b5 + bVar14 + -0x34;
      LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    }
    local_9b4 = local_9b4 + 1;
  } while ((int)local_9b4 < 8);
  local_9b4 = 0;
  local_9b0 = 0;
  iVar6 = DAT_005b3484;
  do {
    if ((*(char *)(iVar6 + 0x5010d + local_9b4) != '\0') &&
       (*(char *)(iVar6 + 0x50126 + local_9b4) == *(char *)(iVar6 + 0x62155))) {
      iVar6 = FUN_004206f0(iVar6);
      if (iVar6 != 0) {
        EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
        uVar9 = FUN_0040a2e0();
        LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
        EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
        local_9a8 = FUN_0040a2e0();
        LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
        EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
        local_9a4[0] = FUN_0040a2e0();
        LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
        FUN_004368f0(local_9a4[0],local_9a8,uVar9);
        EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
        iVar8 = FUN_0040a2e0();
        LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
        local_9a4[0] = local_9b0 + 0x5113c + DAT_005b3484;
        EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
        local_9a4[0] = FUN_0040a2e0();
        LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
        uVar9 = FUN_0040a7d0(local_89c,local_230,local_9a4[0] + iVar8);
        local_4._0_1_ = 2;
        EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
        local_9a4[0] = FUN_0040a2e0();
        LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
        FUN_0040a8c0(uVar9,local_454,local_9a4[0]);
        local_4._0_1_ = 3;
        EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
        uVar9 = FUN_0040a2e0();
        LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
        iVar6 = iVar6 + 0xae15;
        pcVar5 = (char *)FUN_0043dc70(&DAT_00796eec,0x25e);
        _sprintf(local_99c,pcVar5,iVar6,uVar9);
        local_4._0_1_ = 2;
        FUN_0040a2a0();
        local_4 = CONCAT31(local_4._1_3_,1);
        FUN_0040a2a0();
        (**(code **)(*local_9ac + 0x28))(local_99c,4,3);
      }
      iVar6 = DAT_005b3484;
    }
    piVar7 = local_664;
    local_9b0 = local_9b0 + 0x1120;
    local_9b4 = local_9b4 + 1;
  } while (local_9b0 < 0x8900);
  local_4 = local_4 & 0xffffff00;
  if (local_664 != (int *)0x0) {
    FUN_0040a240();
    local_9ac = piVar7;
    FUN_0040b540(local_9a4);
  }
  piVar7 = local_888;
  local_4 = 0xffffffff;
  if (local_888 != (int *)0x0) {
    FUN_0040a240();
    local_9ac = piVar7;
    FUN_0040b540(local_9a4);
  }
LAB_004b541a:
  *unaff_FS_OFFSET = local_c;
  return;
code_r0x004b42d4:
  iVar6 = iVar6 + 1;
  puVar11 = puVar11 + 1;
  if (param_1[0x227] <= iVar6) goto LAB_004b4324;
  goto LAB_004b42d0;
}
