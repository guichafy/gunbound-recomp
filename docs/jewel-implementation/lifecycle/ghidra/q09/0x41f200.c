
void FUN_0041f200(void)

{
  undefined2 *puVar1;
  undefined *puVar2;
  short *psVar3;
  undefined1 uVar4;
  byte bVar5;
  short sVar6;
  int in_EAX;
  int iVar7;
  int iVar8;
  int iVar9;
  int iVar10;
  uint uVar11;
  int iVar12;
  uint uVar13;
  undefined4 *puVar14;
  undefined4 *puVar15;
  bool bVar16;
  uint uStack00000004;
  int local_20;
  int local_1c;
  int local_c;
  uint local_8;

  EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  iVar7 = FUN_0040a2e0();
  LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  iVar8 = FUN_0040a2e0();
  LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  bVar16 = iVar7 % iVar8 != 0;
  EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  FUN_0040a2e0();
  LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  iVar8 = FUN_0040a2e0();
  LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  local_1c = FUN_0040a2e0();
  LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  local_20 = FUN_0040a2e0();
  LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  local_8 = FUN_0040a2e0();
  LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  local_c = FUN_0040a2e0();
  LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  iVar7 = DAT_00e9accc;
  if ((iVar8 == 3) && (!bVar16)) {
    local_20 = local_8 + local_20;
    EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    iVar9 = FUN_0040a2e0();
    LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    if (iVar9 < local_20) {
      EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
      iVar9 = FUN_0040a2e0();
      LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
      local_20 = local_20 - iVar9;
    }
    local_1c = local_c;
    if (local_20 < 0) {
      EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
      iVar9 = FUN_0040a2e0();
      LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
      local_20 = local_20 + iVar9;
    }
  }
  EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  iVar9 = FUN_0040a2e0();
  LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  iVar10 = FUN_0040a2e0();
  LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  if ((iVar9 + 1) % iVar10 == 0) {
    local_c = _rand();
    local_c = local_c % 0x1b;
    iVar9 = _rand();
    local_8 = iVar9 % 0xb4;
  }
  EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  uVar11 = FUN_0040a2e0();
  LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  if ((uVar11 & 0x10000) != 0) {
    EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    uVar11 = FUN_0040a2e0();
    LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    uVar11 = uVar11 & 0x80000007;
    if ((int)uVar11 < 0) {
      uVar11 = (uVar11 - 1 | 0xfffffff8) + 1;
    }
    local_1c = local_1c + *(int *)(&DAT_0056d440 + uVar11 * 4);
    if (local_1c < 0x1b) {
      if (local_1c < 0) {
        local_1c = 0;
      }
    }
    else {
      local_1c = 0x1a;
    }
  }
  (&DAT_00e9aacc)[DAT_00e9accc] = (char)local_1c;
  puVar1 = (undefined2 *)(&DAT_00e9aacd + DAT_00e9accc);
  DAT_00e9accc = DAT_00e9accc + 1;
  *puVar1 = (undefined2)local_20;
  puVar2 = &DAT_00e9aace + DAT_00e9accc;
  DAT_00e9accc = DAT_00e9accc + 2;
  *puVar2 = (undefined1)local_c;
  puVar2 = &DAT_00e9aacd + DAT_00e9accc;
  DAT_00e9accc = DAT_00e9accc + 1;
  *puVar2 = (undefined1)local_8;
  DAT_00e9accc = DAT_00e9accc + 1;
  EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  FUN_0040a2e0();
  LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  FUN_0040a2e0();
  LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  uVar4 = FUN_0040a2e0();
  LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  (&DAT_00e9aacc)[DAT_00e9accc] = uVar4;
  if ((iVar8 != 0) || (bVar16)) {
    puVar2 = &DAT_00e9aacd + DAT_00e9accc;
    DAT_00e9accc = DAT_00e9accc + 1;
    *puVar2 = 0xff;
    DAT_00e9accc = DAT_00e9accc + 1;
    if ((iVar8 != 1) || (bVar16)) goto LAB_0041f7e9;
    uVar11 = FUN_004217b0(0);
    EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    FUN_0040a2e0();
    LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    iVar8 = (uVar11 & 7) * 0x224;
    EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    iVar9 = FUN_0040a2e0();
    LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    FUN_0040a2e0();
    LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    iVar10 = FUN_0040a2e0();
    LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    if (iVar9 - iVar10 < 1) {
      uStack00000004 = 1;
    }
    else {
      iVar9 = FUN_0040a4d0(in_EAX + 0x475c8);
      iVar9 = FUN_0040a4d0((iVar9 * 0xb + (uint)*(byte *)(in_EAX + 0x475c4)) * 0x7d28 + iVar8 +
                           0x1a45d0 + in_EAX);
      iVar10 = FUN_0040a4d0(in_EAX + 0x475c8);
      iVar8 = FUN_0040a4d0((iVar10 * 0xb + (uint)*(byte *)(in_EAX + 0x475c4)) * 0x7d28 + iVar8 +
                           0x1a34b0 + in_EAX);
      uStack00000004 = iVar9 - iVar8;
    }
    EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    FUN_0040a2e0();
    LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    sVar6 = FUN_0040a2e0();
    LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    uVar11 = FUN_004217b0(1);
    (&DAT_00e9aacc)[DAT_00e9accc] = 0;
    DAT_00e9accc = DAT_00e9accc + 1;
    bVar5 = FUN_004217b0(2);
    (&DAT_00e9aacc)[DAT_00e9accc] = (bVar5 & 0x3f) + 0x40;
    psVar3 = (short *)(&DAT_00e9aacd + DAT_00e9accc);
    DAT_00e9accc = DAT_00e9accc + 1;
    *psVar3 = (short)(uVar11 % uStack00000004) + sVar6;
    DAT_00e9accc = DAT_00e9accc + 2;
LAB_0041fb05:
    (&DAT_00e9aacc)[DAT_00e9accc] = 0xff;
    DAT_00e9accc = DAT_00e9accc + 1;
  }
  else {
    DAT_00e9accc = DAT_00e9accc + 1;
    uVar11 = FUN_004217b0(0);
    EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    FUN_0040a2e0();
    LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    iVar9 = (uVar11 & 7) * 0x224;
    EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    iVar10 = FUN_0040a2e0();
    LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    FUN_0040a2e0();
    LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    iVar12 = FUN_0040a2e0();
    LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    if (iVar10 - iVar12 < 1) {
      local_8 = 1;
    }
    else {
      iVar10 = FUN_0040a4d0(in_EAX + 0x475c8);
      iVar10 = FUN_0040a4d0((iVar10 * 0xb + (uint)*(byte *)(in_EAX + 0x475c4)) * 0x7d28 + iVar9 +
                            0x1a6810 + in_EAX);
      iVar12 = FUN_0040a4d0(in_EAX + 0x475c8);
      iVar9 = FUN_0040a4d0((iVar12 * 0xb + (uint)*(byte *)(in_EAX + 0x475c4)) * 0x7d28 + iVar9 +
                           0x1a56f0 + in_EAX);
      local_8 = iVar10 - iVar9;
    }
    EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    FUN_0040a2e0();
    LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    sVar6 = FUN_0040a2e0();
    LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    uVar11 = FUN_004217b0(1);
    (&DAT_00e9aacc)[DAT_00e9accc] = 0;
    DAT_00e9accc = DAT_00e9accc + 1;
    bVar5 = FUN_004217b0(2);
    (&DAT_00e9aacc)[DAT_00e9accc] = (bVar5 & 0x3f) + 0x40;
    psVar3 = (short *)(&DAT_00e9aacd + DAT_00e9accc);
    DAT_00e9accc = DAT_00e9accc + 1;
    *psVar3 = (short)(uVar11 % local_8) + sVar6;
    DAT_00e9accc = DAT_00e9accc + 2;
LAB_0041f7e9:
    (&DAT_00e9aacc)[DAT_00e9accc] = 0xff;
    DAT_00e9accc = DAT_00e9accc + 1;
    if ((iVar8 != 2) || (bVar16)) goto LAB_0041fb05;
    uVar11 = FUN_004217b0(0);
    EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    FUN_0040a2e0();
    LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    iVar8 = (uVar11 & 7) * 0x224;
    EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    iVar9 = FUN_0040a2e0();
    LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    FUN_0040a2e0();
    LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    iVar10 = FUN_0040a2e0();
    LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    if (iVar9 - iVar10 < 1) {
      uStack00000004 = 1;
    }
    else {
      iVar9 = FUN_0040a4d0(in_EAX + 0x475c8);
      iVar9 = FUN_0040a4d0((iVar9 * 0xb + (uint)*(byte *)(in_EAX + 0x475c4)) * 0x7d28 + iVar8 +
                           0x1a8a50 + in_EAX);
      iVar10 = FUN_0040a4d0(in_EAX + 0x475c8);
      iVar8 = FUN_0040a4d0((iVar10 * 0xb + (uint)*(byte *)(in_EAX + 0x475c4)) * 0x7d28 + iVar8 +
                           0x1a7930 + in_EAX);
      uStack00000004 = iVar9 - iVar8;
    }
    EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    FUN_0040a2e0();
    LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    sVar6 = FUN_0040a2e0();
    LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    uVar11 = FUN_004217b0(1);
    (&DAT_00e9aacc)[DAT_00e9accc] = 0;
    DAT_00e9accc = DAT_00e9accc + 1;
    bVar5 = FUN_004217b0(2);
    (&DAT_00e9aacc)[DAT_00e9accc] = (bVar5 & 0x3f) + 0x40;
    psVar3 = (short *)(&DAT_00e9aacd + DAT_00e9accc);
    DAT_00e9accc = DAT_00e9accc + 1;
    *psVar3 = (short)(uVar11 % uStack00000004) + sVar6;
    DAT_00e9accc = DAT_00e9accc + 2;
  }
  EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  iVar8 = FUN_0040a2e0();
  LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  if (iVar8 == 3) {
    EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    iVar8 = FUN_0040a2e0();
    LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    if (iVar8 < 6) {
      (&DAT_00e9aacc)[DAT_00e9accc] = 0;
      DAT_00e9accc = DAT_00e9accc + 1;
      EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
      iVar8 = FUN_0040a2e0();
      LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
      iVar9 = _rand();
      (&DAT_00e9aacc)[DAT_00e9accc] = (char)(iVar9 % iVar8);
      DAT_00e9accc = DAT_00e9accc + 1;
      iVar8 = _rand();
      *(short *)(&DAT_00e9aacc + DAT_00e9accc) = (short)iVar8;
      DAT_00e9accc = DAT_00e9accc + 2;
      goto LAB_0041fd16;
    }
  }
  (&DAT_00e9aacc)[DAT_00e9accc] = 0xff;
  DAT_00e9accc = DAT_00e9accc + 1;
LAB_0041fd16:
  uVar13 = DAT_00e9accc - iVar7;
  puVar14 = (undefined4 *)(&DAT_00e9aacc + iVar7);
  puVar15 = (undefined4 *)(in_EAX + 0xeba78);
  for (uVar11 = uVar13 >> 2; uVar11 != 0; uVar11 = uVar11 - 1) {
    *puVar15 = *puVar14;
    puVar14 = puVar14 + 1;
    puVar15 = puVar15 + 1;
  }
  for (uVar13 = uVar13 & 3; uVar13 != 0; uVar13 = uVar13 - 1) {
    *(undefined1 *)puVar15 = *(undefined1 *)puVar14;
    puVar14 = (undefined4 *)((int)puVar14 + 1);
    puVar15 = (undefined4 *)((int)puVar15 + 1);
  }
  return;
}
