
void __thiscall FUN_00434fc0(undefined4 param_1,undefined4 param_2,int param_3)

{
  int *piVar1;
  char cVar2;
  char *pcVar3;
  void *pvVar4;
  undefined4 uVar5;
  int iVar6;
  int iVar7;
  int iVar8;
  byte bVar9;
  uint uVar10;
  int iVar11;
  undefined4 *unaff_FS_OFFSET;
  undefined4 local_c;
  undefined1 *puStack_8;
  undefined4 local_4;

  local_4 = 0xffffffff;
  puStack_8 = &LAB_0053ca9b;
  local_c = *unaff_FS_OFFSET;
  *unaff_FS_OFFSET = &local_c;
  cVar2 = FUN_004065a0(param_1);
  if (cVar2 == '\0') {
    if ((-1 < param_3) && (param_3 < *(int *)(&DAT_006a7720 + DAT_005b3484))) {
      pcVar3 = (char *)(*(int *)(&DAT_006a773c + DAT_005b3484) + param_3);
      iVar7 = 0;
      if (0 < *(int *)(&DAT_006a7724 + DAT_005b3484)) {
        do {
          if (*pcVar3 != '\0') goto LAB_00435034;
          pcVar3 = pcVar3 + *(int *)(&DAT_006a7720 + DAT_005b3484);
          iVar7 = iVar7 + 1;
        } while (iVar7 < *(int *)(&DAT_006a7724 + DAT_005b3484));
      }
    }
    iVar7 = 10000;
LAB_00435034:
    iVar11 = iVar7;
    FUN_00436070(&DAT_006a7f70 + DAT_005b3484,param_3,iVar7);
    FUN_0043af40(param_3,iVar7,0,0x1e,0x1e,0x1e,0xff);
    pvVar4 = operator_new(0x3fa0);
    local_4 = 0;
    if (pvVar4 == (void *)0x0) {
      iVar7 = 0;
    }
    else {
      iVar7 = FUN_004aa830();
    }
    local_4 = 0xffffffff;
    *(undefined4 *)(iVar7 + 0x18) = 0xffffffff;
    *(undefined4 *)(iVar7 + 0x3894) = 0x1f4f;
    *(undefined1 *)(iVar7 + 0x3c) = 0xff;
    *(undefined4 *)(iVar7 + 0x38) = 0xffffffff;
    EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    FUN_0040a380(param_3);
    LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    uVar5 = FUN_0040a2e0();
    FUN_0040a380(uVar5);
    LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    FUN_0040a380(iVar11);
    LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    FUN_0040a380(param_3 << 8);
    LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    FUN_0040a380(iVar11 << 8);
    LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    FUN_0040a380(0);
    LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    uVar5 = FUN_0040a2e0();
    FUN_0040a380(uVar5);
    LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    uVar5 = FUN_0040a2e0();
    FUN_0040a380(uVar5);
    LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    uVar5 = FUN_0040a2e0();
    FUN_0040a380(uVar5);
    LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    uVar5 = FUN_0040a2e0();
    FUN_0040a380(uVar5);
    LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    iVar6 = _rand();
    *(char *)(iVar7 + 0xf3f) = (char)iVar6;
    iVar6 = _rand();
    *(byte *)(iVar7 + 0xf40) = (byte)iVar6;
    bVar9 = *(byte *)(iVar7 + 0xf3f) & 7;
    bVar9 = ~('\x01' << bVar9) & (byte)iVar6 | '\0' << bVar9;
    *(byte *)(iVar7 + 0xf40) = bVar9;
    *(byte *)(iVar7 + 0xf41) = *(byte *)(iVar7 + 0xf3f) + bVar9 + -0x34;
    LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    uVar5 = FUN_0040a2e0();
    LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    FUN_0040a380(uVar5);
    LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    uVar5 = FUN_0040a2e0();
    FUN_0040a380(uVar5);
    LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    *(undefined4 *)(iVar7 + 0x3898) = s_lightningflame_00553c58._0_4_;
    *(undefined4 *)(iVar7 + 0x389c) = s_lightningflame_00553c58._4_4_;
    *(undefined4 *)(iVar7 + 0x38a0) = s_lightningflame_00553c58._8_4_;
    *(undefined2 *)(iVar7 + 0x38a4) = s_lightningflame_00553c58._12_2_;
    *(char *)(iVar7 + 0x38a6) = s_lightningflame_00553c58[0xe];
    *(undefined4 *)(iVar7 + 0x3813) = s_lightningblast_xes_00553c44._0_4_;
    *(undefined4 *)(iVar7 + 0x3817) = s_lightningblast_xes_00553c44._4_4_;
    *(undefined4 *)(iVar7 + 0x381b) = s_lightningblast_xes_00553c44._8_4_;
    *(undefined4 *)(iVar7 + 0x381f) = s_lightningblast_xes_00553c44._12_4_;
    *(undefined2 *)(iVar7 + 0x3823) = s_lightningblast_xes_00553c44._16_2_;
    *(char *)(iVar7 + 0x3825) = s_lightningblast_xes_00553c44[0x12];
    EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    FUN_0040a380(0x46);
    LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    FUN_0040a380(0x46);
    LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    FUN_0040a380(0x46);
    LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    FUN_0040a380(0x1e);
    LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    FUN_0040a380(0x1e);
    LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    FUN_0040a380(0x1e);
    LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    FUN_0040a380(0x6e);
    LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    FUN_0040a380(0x6e);
    LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    FUN_0040a380(0x6e);
    LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    uVar5 = FUN_0040a2e0();
    LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    FUN_0040a380(uVar5);
    LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    iVar6 = _rand();
    *(char *)(iVar7 + 0x33bc) = (char)iVar6;
    iVar6 = _rand();
    *(byte *)(iVar7 + 0x33bd) = (byte)iVar6;
    bVar9 = *(byte *)(iVar7 + 0x33bc) & 7;
    bVar9 = ~('\x01' << bVar9) & (byte)iVar6 | '\0' << bVar9;
    *(byte *)(iVar7 + 0x33bd) = bVar9;
    *(byte *)(iVar7 + 0x33be) = *(byte *)(iVar7 + 0x33bc) + bVar9 + -0x34;
    LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    iVar6 = _rand();
    *(char *)(iVar7 + 0x33bf) = (char)iVar6;
    iVar6 = _rand();
    *(byte *)(iVar7 + 0x33c0) = (byte)iVar6;
    bVar9 = '\x01' << (*(byte *)(iVar7 + 0x33bf) & 7);
    bVar9 = ~bVar9 & (byte)iVar6 | bVar9;
    *(byte *)(iVar7 + 0x33c0) = bVar9;
    *(byte *)(iVar7 + 0x33c1) = *(byte *)(iVar7 + 0x33bf) + bVar9 + -0x34;
    LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    iVar6 = _rand();
    *(char *)(iVar7 + 0x33c2) = (char)iVar6;
    iVar6 = _rand();
    *(byte *)(iVar7 + 0x33c3) = (byte)iVar6;
    bVar9 = *(byte *)(iVar7 + 0x33c2) & 7;
    bVar9 = ~('\x01' << bVar9) & (byte)iVar6 | '\0' << bVar9;
    *(byte *)(iVar7 + 0x33c3) = bVar9;
    *(byte *)(iVar7 + 0x33c4) = *(byte *)(iVar7 + 0x33c2) + bVar9 + -0x34;
    LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    iVar6 = _rand();
    *(char *)(iVar7 + 0x33c5) = (char)iVar6;
    iVar6 = _rand();
    *(byte *)(iVar7 + 0x33c6) = (byte)iVar6;
    bVar9 = *(byte *)(iVar7 + 0x33c5) & 7;
    bVar9 = ~('\x01' << bVar9) & (byte)iVar6 | '\0' << bVar9;
    *(byte *)(iVar7 + 0x33c6) = bVar9;
    *(byte *)(iVar7 + 0x33c7) = *(byte *)(iVar7 + 0x33c5) + bVar9 + -0x34;
    LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    FUN_0040a380(0x1e);
    LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    FUN_0040a380(0x1e);
    LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    FUN_004f2fb0();
    iVar7 = DAT_005b3484;
    piVar1 = (int *)(&DAT_006a7708 + DAT_005b3484);
    cVar2 = FUN_004065a0();
    if ((cVar2 == '\0') && ((&DAT_006a7758)[iVar7] != '\0')) {
      if (((&DAT_006a7736)[iVar7] == '\x01') &&
         ((uVar10 = iVar11 - *(int *)(&DAT_006a7714 + iVar7) >> 0x1f,
          200 < (int)((iVar11 - *(int *)(&DAT_006a7714 + iVar7) ^ uVar10) - uVar10) ||
          (uVar10 = param_3 - *(int *)(&DAT_006a7710 + iVar7) >> 0x1f,
          300 < (int)((param_3 - *(int *)(&DAT_006a7710 + iVar7) ^ uVar10) - uVar10))))) {
        (&DAT_006a7736)[iVar7] = 0;
      }
      iVar6 = 400;
      if (399 < param_3) {
        iVar6 = param_3;
      }
      if (*(int *)(&DAT_006a7720 + iVar7) + -400 < iVar6) {
        param_3 = *(int *)(&DAT_006a7720 + iVar7) + -400;
      }
      else if (param_3 < 400) {
        param_3 = 400;
      }
      iVar6 = -0x14;
      if (-0x15 < iVar11) {
        iVar6 = iVar11;
      }
      if (*(int *)(&DAT_006a7724 + iVar7) + -0x104 < iVar6) {
        iVar11 = *(int *)(&DAT_006a7724 + iVar7) + -0x104;
      }
      else if (iVar11 < -0x14) {
        iVar11 = -0x14;
      }
      iVar6 = *piVar1 - param_3;
      *(int *)(&DAT_006a771c + iVar7) = iVar11;
      if (((*(int *)(&DAT_006a770c + iVar7) - iVar11) * (*(int *)(&DAT_006a770c + iVar7) - iVar11) +
           iVar6 * iVar6 < 40000) &&
         (((&DAT_006a7734)[iVar7] == '\x01' || ((&DAT_006a7f6c)[iVar7] == '\0')))) {
        *(int *)(&DAT_006a7710 + iVar7) = param_3;
        *piVar1 = param_3;
        *(int *)(&DAT_006a7714 + iVar7) = iVar11;
        *(int *)(&DAT_006a770c + iVar7) = iVar11;
      }
      if ((((&DAT_006a7734)[iVar7] == '\0') && ((&DAT_006a7f6c)[iVar7] == '\x01')) &&
         ((&DAT_006a7736)[iVar7] == '\0')) {
        iVar6 = *(int *)(&DAT_006a7730 + iVar7);
        iVar8 = param_3;
        if (iVar6 < param_3) {
          iVar8 = iVar6;
        }
        if (iVar8 < *(int *)(&DAT_006a772c + iVar7)) {
          iVar6 = *(int *)(&DAT_006a772c + iVar7);
        }
        else if (param_3 <= iVar6) {
          iVar6 = param_3;
        }
        *(int *)(&DAT_006a7718 + iVar7) = iVar6;
      }
      if ((&DAT_006a7734)[iVar7] == '\x01') {
        *(int *)(&DAT_006a7718 + iVar7) = param_3;
        *(int *)(&DAT_006a771c + iVar7) = iVar11;
      }
    }
    EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    uVar5 = FUN_0040a2e0();
    LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    FUN_0040a380(uVar5);
    LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  }
  *unaff_FS_OFFSET = local_c;
  return;
}
