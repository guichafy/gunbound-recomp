
int __fastcall FUN_00479ba0(int *param_1)

{
  int *piVar1;
  bool bVar2;
  char cVar3;
  undefined4 uVar4;
  int iVar5;
  int iVar6;
  uint uVar7;
  int iVar8;
  int iVar9;
  int iVar10;
  undefined4 uVar11;
  undefined4 *puVar12;
  char *pcVar13;
  int *unaff_FS_OFFSET;
  undefined4 uVar14;
  int local_924 [2];
  char acStack_91c [128];
  undefined1 local_89c [20];
  int local_888;
  undefined1 uStack_67c;
  undefined1 auStack_678 [20];
  undefined4 uStack_664;
  undefined1 uStack_458;
  undefined1 auStack_454 [548];
  undefined1 auStack_230 [548];
  int local_c;
  undefined1 *puStack_8;
  undefined4 local_4;

  local_4 = 0xffffffff;
  puStack_8 = &LAB_0053c294;
  iVar5 = *unaff_FS_OFFSET;
  *unaff_FS_OFFSET = (int)&local_c;
  local_c = iVar5;
  if ((char)param_1[5] == '\x01') goto LAB_0047a932;
  EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  uVar4 = FUN_0040a2e0();
  LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  FUN_0040a6e0(param_1 + 0x120,local_89c,uVar4);
  local_4 = 0;
  EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  FUN_0040a2e0();
  LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  FUN_0040a2e0();
  LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  iVar5 = FUN_004e4340();
  local_4 = 0xffffffff;
  if (local_888 != 0) {
    FUN_0040a240();
    FUN_0040b540(local_924);
  }
  FUN_0040aba0(param_1 + 0x120,local_89c,param_1 + 0x67d);
  local_4 = 1;
  EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  iVar6 = FUN_0040a2e0();
  LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  if (iVar6 < iVar5) {
LAB_00479d44:
    bVar2 = false;
  }
  else {
    EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    iVar6 = FUN_0040a2e0();
    LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    if (iVar6 < 0) goto LAB_00479d44;
    cVar3 = FUN_0040b330(param_1 + 0x97,*(undefined4 *)(&DAT_006a7720 + DAT_005b3484));
    bVar2 = true;
    if (cVar3 == '\0') goto LAB_00479d44;
  }
  local_4 = 0xffffffff;
  if (local_888 != 0) {
    FUN_0040a240();
    FUN_0040b540(local_924);
  }
  if (bVar2) {
    EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    iVar6 = FUN_0040a2e0();
    LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    if (iVar6 < 5) {
      FUN_0040a470(iVar5);
      if (param_1[9] == 1) {
        (**(code **)(*param_1 + 4))(s_normal_00552230);
      }
      EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
      FUN_0040a380(0);
      LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
      EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
      FUN_0040a380(0);
      LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
      cVar3 = FUN_004065a0();
      if (cVar3 == '\x01') {
        uVar7 = FUN_00415c60();
        if ((uVar7 & 1) != 0) {
          uVar7 = FUN_00415c60();
          FUN_0043dc70(&DAT_00796eec,uVar7 % 10 + 0x80d);
          FUN_004382d0();
        }
LAB_00479e75:
        uVar4 = FUN_0040a4d0(&DAT_00e55ab8);
        FUN_0040a470(uVar4);
        FUN_0040b030();
        FUN_00406500(0);
      }
    }
    else {
      iVar6 = FUN_0040a4d0(param_1 + 0x67d);
      FUN_0040a470(iVar5 - iVar6);
      EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
      FUN_0040a380(1);
      LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
      EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
      FUN_0040a380(0);
      LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
      cVar3 = FUN_004065a0();
      if ((cVar3 == '\x01') && (iVar5 < *(int *)(&DAT_006a7724 + DAT_005b3484))) goto LAB_00479e75;
    }
  }
  else {
    if (param_1[9] == 0) {
      (**(code **)(*param_1 + 4))(&DAT_00553bcc);
      FUN_0040a4a0(DAT_005b3484 + 0x62630);
    }
    EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    iVar5 = FUN_0040a2e0();
    FUN_0040a380(iVar5 + 1);
    LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    FUN_0040afb0(param_1 + 0x67d);
    cVar3 = FUN_004065a0();
    if (cVar3 != '\0') {
      FUN_0040a4d0(DAT_005b3484 + 0x5b1ac);
      FUN_0040a4d0(DAT_005b3484 + 0x5af88);
      iVar5 = FUN_0053753c();
      FUN_0040aab0(iVar5 * 3);
      EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
      uVar4 = FUN_0040a2e0();
      LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
      uVar4 = FUN_0040a8c0(param_1 + 0x5f4,local_89c,uVar4);
      local_4 = 2;
      FUN_0040afb0(uVar4);
      local_4 = 0xffffffff;
      FUN_0040a2a0();
      EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
      uVar4 = FUN_0040a2e0();
      LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
      FUN_0040ab60(uVar4);
    }
  }
  iVar5 = FUN_004065a0();
  if ((char)iVar5 != '\0') goto LAB_0047a932;
  cVar3 = FUN_004065a0();
  if (cVar3 == '\x01') {
    iVar6 = FUN_0040a4d0(param_1 + 0x120);
    iVar8 = FUN_0040a4d0(param_1 + 0x97);
    iVar5 = DAT_005b3484;
    piVar1 = (int *)(&DAT_006a7708 + DAT_005b3484);
    cVar3 = FUN_004065a0();
    if ((cVar3 == '\0') && ((&DAT_006a7758)[iVar5] != '\0')) {
      if (((&DAT_006a7736)[iVar5] == '\x01') &&
         ((uVar7 = iVar6 - *(int *)(&DAT_006a7714 + iVar5) >> 0x1f,
          200 < (int)((iVar6 - *(int *)(&DAT_006a7714 + iVar5) ^ uVar7) - uVar7) ||
          (uVar7 = iVar8 - *(int *)(&DAT_006a7710 + iVar5) >> 0x1f,
          300 < (int)((iVar8 - *(int *)(&DAT_006a7710 + iVar5) ^ uVar7) - uVar7))))) {
        (&DAT_006a7736)[iVar5] = 0;
      }
      iVar10 = 400;
      if (399 < iVar8) {
        iVar10 = iVar8;
      }
      if (*(int *)(&DAT_006a7720 + iVar5) + -400 < iVar10) {
        iVar10 = *(int *)(&DAT_006a7720 + iVar5) + -400;
      }
      else {
        iVar10 = 400;
        if (399 < iVar8) {
          iVar10 = iVar8;
        }
      }
      iVar8 = iVar6;
      if (iVar6 < -0x14) {
        iVar8 = -0x14;
      }
      iVar9 = *(int *)(&DAT_006a7724 + iVar5) + -0x104;
      if ((iVar8 <= *(int *)(&DAT_006a7724 + iVar5) + -0x104) && (iVar9 = iVar6, iVar6 < -0x14)) {
        iVar9 = -0x14;
      }
      local_924[0] = *piVar1;
      *(int *)(&DAT_006a771c + iVar5) = iVar9;
      local_924[0] = local_924[0] - iVar10;
      if (((*(int *)(&DAT_006a770c + iVar5) - iVar9) * (*(int *)(&DAT_006a770c + iVar5) - iVar9) +
           local_924[0] * local_924[0] < 40000) &&
         (((&DAT_006a7734)[iVar5] == '\x01' || ((&DAT_006a7f6c)[iVar5] == '\0')))) {
        *(int *)(&DAT_006a7710 + iVar5) = iVar10;
        *piVar1 = iVar10;
        *(int *)(&DAT_006a7714 + iVar5) = iVar9;
        *(int *)(&DAT_006a770c + iVar5) = iVar9;
      }
      if ((((&DAT_006a7734)[iVar5] == '\0') && ((&DAT_006a7f6c)[iVar5] == '\x01')) &&
         ((&DAT_006a7736)[iVar5] == '\0')) {
        iVar6 = *(int *)(&DAT_006a7730 + iVar5);
        iVar8 = iVar10;
        if (iVar6 < iVar10) {
          iVar8 = iVar6;
        }
        if (iVar8 < *(int *)(&DAT_006a772c + iVar5)) {
          iVar6 = *(int *)(&DAT_006a772c + iVar5);
        }
        else if (iVar10 <= iVar6) {
          iVar6 = iVar10;
        }
        *(int *)(&DAT_006a7718 + iVar5) = iVar6;
      }
      if ((&DAT_006a7734)[iVar5] == '\x01') {
        *(int *)(&DAT_006a7718 + iVar5) = iVar10;
        *(int *)(&DAT_006a771c + iVar5) = iVar9;
      }
    }
  }
  FUN_004785f0(param_1);
  FUN_00450730();
  if ((char)param_1[0xd] != '\0') {
    (**(code **)(*param_1 + 4))(s_normal_00552230);
  }
  iVar5 = *(int *)(&DAT_006a7724 + DAT_005b3484);
  EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  iVar6 = FUN_0040a2e0();
  LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  if ((iVar5 < iVar6) || (cVar3 = FUN_0040b450(param_1 + 0x232,param_1 + 0x1a9), cVar3 != '\0')) {
    cVar3 = FUN_004065a0();
    if (cVar3 == '\x01') {
      uVar4 = FUN_0040a4d0(&DAT_00e55ab8);
      FUN_0040a470(uVar4);
    }
    else if (*(char *)((int)DAT_005b3424 + 0x2382) == '\0') {
      uStack_67c = 0;
      local_888 = 0;
      FUN_0040a380(0);
      local_4 = 3;
      uStack_458 = 0;
      uStack_664 = 0;
      FUN_0040a380(0);
      piVar1 = param_1 + 0xe;
      local_4 = CONCAT31(local_4._1_3_,4);
      uVar4 = FUN_0040a4d0(piVar1);
      switch(uVar4) {
      case 0:
        FUN_0040a440();
        break;
      case 1:
        FUN_0040a440();
        break;
      case 2:
        FUN_0040a440();
        break;
      case 3:
        FUN_0040a440();
        break;
      default:
        FUN_0040a440();
      }
      FUN_0040a440();
      iVar5 = FUN_0040a4d0(param_1 + 0x345);
      iVar6 = FUN_004206f0(DAT_005b3484);
      if (iVar6 != 0) {
        iVar8 = FUN_0040a4d0(iVar5 * 0x1120 + 0x5113c + DAT_005b3484);
        iVar10 = FUN_0040a4d0(&DAT_00796aa0);
        uVar4 = FUN_0040a7d0(local_89c,auStack_230,iVar8 + iVar10);
        local_4._0_1_ = 5;
        uVar11 = FUN_0040a4d0(&DAT_00796aa0);
        uVar4 = FUN_0040a8c0(uVar4,auStack_454,uVar11);
        local_4._0_1_ = 6;
        uVar4 = FUN_0040a4d0(uVar4);
        local_4._0_1_ = 5;
        FUN_0040a2a0();
        local_4 = CONCAT31(local_4._1_3_,4);
        FUN_0040a2a0();
        FUN_0040aab0(uVar4);
        uVar11 = FUN_0040a4d0(auStack_678);
        iVar8 = iVar6 + 0xae15;
        iVar10 = FUN_0040a4d0(piVar1);
        pcVar13 = (char *)FUN_0043dc70(&DAT_00796eec,iVar10 + 600);
        _sprintf(acStack_91c,pcVar13,iVar8,uVar11,uVar4);
        cVar3 = FUN_0040b270(piVar1,3);
        if (cVar3 == '\0') {
          uVar11 = 3;
          uVar4 = 4;
        }
        else {
          uVar11 = 2;
          uVar4 = 3;
        }
        (**(code **)(*DAT_005b3424 + 0x28))(acStack_91c,uVar4,uVar11);
        iVar8 = FUN_0040a4d0(piVar1);
        if (iVar8 == 0) {
          uVar14 = 2;
          uVar4 = FUN_0040a4d0(iVar6 + 0xb30);
          uVar11 = FUN_0040a4d0(iVar6 + 0x90c);
          FUN_004368f0(uVar11,uVar4,uVar14);
          uVar4 = 2;
        }
        else {
          if (iVar8 != 1) goto LAB_0047a564;
          uVar14 = 1;
          uVar4 = FUN_0040a4d0(iVar6 + 0xb30);
          uVar11 = FUN_0040a4d0(iVar6 + 0x90c);
          FUN_004368f0(uVar11,uVar4,uVar14);
          uVar4 = 1;
        }
        FUN_0040aab0(uVar4);
      }
LAB_0047a564:
      cVar3 = *(char *)(DAT_005b3484 + 0x50126 + iVar5);
      if (cVar3 == '\0') {
        FUN_0040afb0(auStack_678);
        cVar3 = FUN_0040b330(&DAT_0067e3d0 + DAT_005b3484,0);
joined_r0x0047a5db:
        if (cVar3 != '\0') {
          FUN_0040a470(0);
        }
      }
      else if (cVar3 == '\x01') {
        FUN_0040afb0(auStack_678);
        cVar3 = FUN_0040b330(&DAT_0067e5f4 + DAT_005b3484,0);
        goto joined_r0x0047a5db;
      }
      uVar4 = FUN_0040a4d0(&DAT_00796aa0);
      cVar3 = FUN_0040b300(&DAT_0067e5f4 + DAT_005b3484,uVar4);
      if (cVar3 == '\0') {
        uVar4 = FUN_0040a4d0(&DAT_00796aa0);
        cVar3 = FUN_0040b300(&DAT_0067e3d0 + DAT_005b3484,uVar4);
        if (cVar3 != '\0') goto LAB_0047a634;
      }
      else {
LAB_0047a634:
        cVar3 = FUN_0040b390(DAT_005b3484 + 0x3b6c4,DAT_005b3484 + 0x3b49c);
        iVar5 = DAT_007934e8;
        if ((cVar3 != '\0') && (*(char *)((int)DAT_005b3424 + 0x2382) == '\0')) {
          *(undefined2 *)(DAT_007934e8 + 0x4d4) = 0x4200;
          *(undefined4 *)(iVar5 + 0x44d0) = 6;
          cVar3 = FUN_0040b410(&DAT_0067e5f4 + DAT_005b3484,&DAT_0067e3d0 + DAT_005b3484);
          iVar5 = DAT_007934e8;
          if (cVar3 == '\0') {
            *(undefined1 *)(DAT_007934e8 + 0x4d0 + *(int *)(DAT_007934e8 + 0x44d0)) = 0;
          }
          else {
            *(undefined1 *)(DAT_007934e8 + 0x4d0 + *(int *)(DAT_007934e8 + 0x44d0)) = 1;
          }
          *(int *)(iVar5 + 0x44d0) = *(int *)(iVar5 + 0x44d0) + 1;
          FUN_004d25e0();
          FUN_004d2680();
          *(undefined1 *)((int)DAT_005b3424 + 0x2382) = 1;
          local_4 = CONCAT31(local_4._1_3_,3);
          FUN_0040a2a0();
          local_4 = 0xffffffff;
          iVar5 = FUN_0040a2a0();
          goto LAB_0047a932;
        }
      }
      FUN_004ee9b0(0);
      FUN_0040b060();
      local_4 = CONCAT31(local_4._1_3_,3);
      FUN_0040a2a0();
      local_4 = 0xffffffff;
      FUN_0040a2a0();
    }
    cVar3 = FUN_0040b450(param_1 + 0x232,param_1 + 0x1a9);
    if (cVar3 != '\0') {
      iVar5 = FUN_0040a4d0(param_1 + 0xe);
      _sprintf(acStack_91c,s_jflame_d_00555ff0,iVar5 + 1);
      uVar7 = param_1[2];
      if ((uVar7 & 3) < 3) {
        iVar5 = 7;
      }
      else {
        iVar5 = FUN_0040a4d0(&DAT_00794bf0);
      }
      pcVar13 = acStack_91c;
      iVar6 = FUN_0040a4d0(param_1 + 0xe);
      iVar6 = iVar6 + 0xc80;
      uVar4 = FUN_0040a4d0(param_1 + 0x120);
      uVar11 = FUN_0040a4d0(param_1 + 0x97);
      FUN_004372f0(iVar5 - (uVar7 & 3),uVar11,uVar4,iVar6,pcVar13);
      uVar7 = FUN_00415c60();
      FUN_0043dc70(&DAT_00796eec,uVar7 % 10 + 0x7f9);
      FUN_004382d0();
    }
    *(undefined1 *)(param_1 + 5) = 1;
  }
  iVar6 = _rand();
  iVar5 = iVar6 / 1000;
  if (((iVar6 % 1000 == 0) && (iVar5 = FUN_0040b270(param_1 + 0x67d,0), (char)iVar5 != '\0')) &&
     (iVar5 = FUN_0040b390(DAT_005b3484 + 0x3b6c4,DAT_005b3484 + 0x3b49c), (char)iVar5 != '\0')) {
    FUN_004e6c90(0x4004);
    (&DAT_00e9aacc)[DAT_00e9accc] = (char)param_1[2];
    DAT_00e9accc = DAT_00e9accc + 1;
    iVar5 = param_1[0x791];
    iVar6 = _rand();
    if (iVar5 == 0) {
      iVar5 = iVar6 % 10 + 0x7d1;
      pcVar13 = (char *)FUN_0043dc70(&DAT_00796eec,iVar5);
      do {
        cVar3 = *pcVar13;
        pcVar13 = pcVar13 + 1;
      } while (cVar3 != '\0');
      uVar4 = FUN_0043dc70(&DAT_00796eec,iVar5);
    }
    else {
      puVar12 = (undefined4 *)FUN_00415450();
      pcVar13 = (char *)*puVar12;
      do {
        cVar3 = *pcVar13;
        pcVar13 = pcVar13 + 1;
      } while (cVar3 != '\0');
      puVar12 = (undefined4 *)FUN_00415450();
      uVar4 = *puVar12;
    }
    FUN_004e6db0(uVar4);
    iVar5 = FUN_004e6fc0();
  }
LAB_0047a932:
  *unaff_FS_OFFSET = local_c;
  return iVar5;
}
