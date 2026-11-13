
void __fastcall FUN_0045cb50(int *param_1)

{
  int *piVar1;
  bool bVar2;
  char cVar3;
  int iVar4;
  int iVar5;
  undefined4 uVar6;
  int iVar7;
  int iVar8;
  uint uVar9;
  int iVar10;
  undefined4 *unaff_FS_OFFSET;
  undefined1 auStack_454 [548];
  undefined1 auStack_230 [548];
  undefined4 local_c;
  undefined1 *puStack_8;
  undefined4 uStack_4;

  uStack_4 = 0xffffffff;
  puStack_8 = &LAB_0053c46d;
  local_c = *unaff_FS_OFFSET;
  *unaff_FS_OFFSET = &local_c;
  iVar5 = *(int *)(&DAT_006a7724 + DAT_005b3484);
  EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  iVar4 = FUN_0040a2e0();
  LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  if ((iVar5 + 500 < iVar4) || (cVar3 = FUN_004065a0(), cVar3 == '\x01')) {
    EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    FUN_0040a380(0);
    LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    goto LAB_0045d128;
  }
  iVar5 = (**(code **)(*param_1 + 0x14))();
  piVar1 = param_1 + 0x2261;
  FUN_0040aba0(param_1 + 0x2cc,auStack_454,piVar1);
  uStack_4 = 0;
  EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  iVar4 = FUN_0040a2e0();
  LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  if ((iVar4 < iVar5) || (cVar3 = FUN_0040b300(param_1 + 0x243,0), cVar3 == '\0')) {
LAB_0045cc63:
    bVar2 = false;
  }
  else {
    cVar3 = FUN_0040b330(param_1 + 0x243,*(undefined4 *)(&DAT_006a7720 + DAT_005b3484));
    bVar2 = true;
    if (cVar3 == '\0') goto LAB_0045cc63;
  }
  uStack_4 = 0xffffffff;
  FUN_0040a2a0();
  if (bVar2) {
    cVar3 = FUN_0040b330(piVar1,5);
    if (cVar3 == '\0') {
      iVar4 = FUN_0040a4d0(piVar1);
      FUN_0040a470(iVar5 - iVar4);
      FUN_0040a470(1);
      param_1[0x2ffb] = 0;
      cVar3 = FUN_004065a0();
      if ((cVar3 == '\x01') &&
         (((cVar3 = FUN_0040b270(DAT_005b3484 + 0x45354,1), cVar3 != '\0' ||
           (cVar3 = FUN_0040b270(DAT_005b3484 + 0x45354,3), cVar3 != '\0')) &&
          (iVar5 < *(int *)(&DAT_006a7724 + DAT_005b3484))))) goto LAB_0045cdb1;
    }
    else {
      FUN_0040a470(iVar5);
      if (param_1[9] == 0xd) {
        uVar6 = FUN_0040a8c0(param_1 + 0x19d1,auStack_230,3);
        uStack_4 = 1;
        cVar3 = FUN_0040b490(param_1 + 0x1a5a,uVar6);
        uStack_4 = 0xffffffff;
        FUN_0040a2a0();
        if (cVar3 == '\0') {
          (**(code **)(*param_1 + 4))(s_normal_00552230);
        }
        else {
          (**(code **)(*param_1 + 4))(s_wnormal_00553618);
        }
      }
      FUN_0040a470(0);
      param_1[0x2ffb] = 0;
      cVar3 = FUN_004065a0();
      if (cVar3 == '\x01') {
LAB_0045cdb1:
        uVar6 = FUN_0040a4d0(&DAT_00e55ab8);
        FUN_0040a470(uVar6);
        iVar4 = FUN_0040a4d0(DAT_005b3484 + 0x3b49c);
        iVar5 = DAT_007934e8;
        if (param_1[2] == iVar4) {
          *(undefined2 *)(DAT_007934e8 + 0x4d4) = 0x4104;
          *(undefined4 *)(iVar5 + 0x44d0) = 6;
          *(char *)(iVar5 + 0x4d6) = (char)param_1[2];
          *(int *)(iVar5 + 0x44d0) = *(int *)(iVar5 + 0x44d0) + 1;
          FUN_004d25e0();
          FUN_004d2680();
        }
        FUN_00406500(0);
        FUN_00406500(1);
        FUN_0040a4a0(param_1 + 0x243);
        iVar5 = FUN_004257b0();
        FUN_0040a470(iVar5 + param_1[0x2fee]);
        FUN_00406500(0);
      }
    }
  }
  else {
    FUN_0040b030();
    FUN_0040afb0(piVar1);
    cVar3 = FUN_004065a0();
    if ((cVar3 == '\x01') &&
       ((cVar3 = FUN_0040b270(DAT_005b3484 + 0x45354,1), cVar3 != '\0' ||
        (cVar3 = FUN_0040b270(DAT_005b3484 + 0x45354,3), cVar3 != '\0')))) {
      FUN_0040a4d0(DAT_005b3484 + 0x5b1ac);
      FUN_004ead90();
      FUN_0040a4d0(DAT_005b3484 + 0x5af88);
      iVar5 = FUN_0053753c();
      param_1[0x2ffb] = param_1[0x2ffb] + iVar5 * 3;
      iVar5 = FUN_0040a4d0(&DAT_00796aa0);
      FUN_0040aab0(param_1[0x2ffb] / iVar5);
      iVar5 = FUN_0040a4d0(&DAT_00796aa0);
      FUN_0040aab0(param_1[0x2ffb] / iVar5);
      iVar5 = FUN_0040a4d0(&DAT_00796aa0);
      param_1[0x2ffb] = param_1[0x2ffb] % iVar5;
    }
  }
  cVar3 = FUN_004065a0();
  if ((cVar3 == '\x01') &&
     ((cVar3 = FUN_0040b270(DAT_005b3484 + 0x45354,1), cVar3 != '\0' ||
      (cVar3 = FUN_0040b270(DAT_005b3484 + 0x45354,3), cVar3 != '\0')))) {
    iVar7 = FUN_0040a4d0(param_1 + 0x2cc);
    iVar4 = FUN_0040a4d0(param_1 + 0x243);
    iVar5 = DAT_005b3484;
    piVar1 = (int *)(&DAT_006a7708 + DAT_005b3484);
    cVar3 = FUN_004065a0();
    if ((cVar3 == '\0') && ((&DAT_006a7758)[iVar5] != '\0')) {
      if (((&DAT_006a7736)[iVar5] == '\x01') &&
         ((uVar9 = iVar7 - *(int *)(&DAT_006a7714 + iVar5) >> 0x1f,
          200 < (int)((iVar7 - *(int *)(&DAT_006a7714 + iVar5) ^ uVar9) - uVar9) ||
          (uVar9 = iVar4 - *(int *)(&DAT_006a7710 + iVar5) >> 0x1f,
          300 < (int)((iVar4 - *(int *)(&DAT_006a7710 + iVar5) ^ uVar9) - uVar9))))) {
        (&DAT_006a7736)[iVar5] = 0;
      }
      iVar8 = 400;
      if (399 < iVar4) {
        iVar8 = iVar4;
      }
      if (*(int *)(&DAT_006a7720 + iVar5) + -400 < iVar8) {
        iVar4 = *(int *)(&DAT_006a7720 + iVar5) + -400;
      }
      else if (iVar4 < 400) {
        iVar4 = 400;
      }
      iVar8 = -0x14;
      if (-0x15 < iVar7) {
        iVar8 = iVar7;
      }
      if (*(int *)(&DAT_006a7724 + iVar5) + -0x104 < iVar8) {
        iVar8 = *(int *)(&DAT_006a7724 + iVar5) + -0x104;
      }
      else {
        iVar8 = -0x14;
        if (-0x15 < iVar7) {
          iVar8 = iVar7;
        }
      }
      iVar7 = *piVar1 - iVar4;
      *(int *)(&DAT_006a771c + iVar5) = iVar8;
      if (((*(int *)(&DAT_006a770c + iVar5) - iVar8) * (*(int *)(&DAT_006a770c + iVar5) - iVar8) +
           iVar7 * iVar7 < 40000) &&
         (((&DAT_006a7734)[iVar5] == '\x01' || ((&DAT_006a7f6c)[iVar5] == '\0')))) {
        *(int *)(&DAT_006a7710 + iVar5) = iVar4;
        *piVar1 = iVar4;
        *(int *)(&DAT_006a7714 + iVar5) = iVar8;
        *(int *)(&DAT_006a770c + iVar5) = iVar8;
      }
      if ((((&DAT_006a7734)[iVar5] == '\0') && ((&DAT_006a7f6c)[iVar5] == '\x01')) &&
         ((&DAT_006a7736)[iVar5] == '\0')) {
        iVar7 = *(int *)(&DAT_006a7730 + iVar5);
        iVar10 = iVar7;
        if (iVar4 <= iVar7) {
          iVar10 = iVar4;
        }
        if (iVar10 < *(int *)(&DAT_006a772c + iVar5)) {
          iVar7 = *(int *)(&DAT_006a772c + iVar5);
        }
        else if (iVar4 <= iVar7) {
          iVar7 = iVar4;
        }
        *(int *)(&DAT_006a7718 + iVar5) = iVar7;
      }
      if ((&DAT_006a7734)[iVar5] == '\x01') {
        *(int *)(&DAT_006a7718 + iVar5) = iVar4;
        *(int *)(&DAT_006a771c + iVar5) = iVar8;
      }
    }
  }
LAB_0045d128:
  *unaff_FS_OFFSET = local_c;
  return;
}
