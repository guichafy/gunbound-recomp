
void FUN_004785f0(int param_1)

{
  short sVar1;
  char cVar2;
  undefined4 uVar3;
  int iVar4;
  int iVar5;
  int iVar6;
  undefined4 *unaff_FS_OFFSET;
  int local_8b0 [2];
  undefined1 local_8a8 [8];
  int local_8a0;
  undefined1 local_89c [20];
  int local_888;
  undefined1 local_678 [20];
  int local_664;
  undefined1 local_454 [20];
  int local_440;
  undefined1 local_230 [20];
  int local_21c;
  undefined4 local_c;
  undefined1 *puStack_8;
  undefined4 local_4;

  local_c = *unaff_FS_OFFSET;
  local_4 = 0xffffffff;
  puStack_8 = &LAB_00539797;
  *unaff_FS_OFFSET = &local_c;
  cVar2 = FUN_004065a0();
  if (cVar2 == '\x01') {
    EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    FUN_0040a380(0);
    LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    goto LAB_00478a67;
  }
  EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  uVar3 = FUN_0040a2e0();
  LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  FUN_0040a6e0(param_1 + 0x480,local_89c,uVar3);
  local_4 = 0;
  EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  FUN_0040a2e0();
  LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  FUN_0040a2e0();
  LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  local_8a0 = FUN_004e4340();
  local_4 = 0xffffffff;
  if (local_888 != 0) {
    FUN_0040a240();
    FUN_0040b540(local_8b0);
  }
  EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  uVar3 = FUN_0040a2e0();
  LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  FUN_0040a6e0(param_1 + 0x480,local_678,uVar3);
  local_4 = 1;
  EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  uVar3 = FUN_0040a2e0();
  LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  FUN_0040a6e0(param_1 + 0x25c,local_89c,uVar3);
  local_4._0_1_ = 2;
  EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  FUN_0040a2e0();
  LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  FUN_0040a2e0();
  LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  iVar4 = FUN_004e4340();
  local_4 = CONCAT31(local_4._1_3_,1);
  if (local_888 != 0) {
    FUN_0040a240();
    local_8b0[0] = local_888;
    FUN_0040b540(local_8a8);
  }
  local_4 = 0xffffffff;
  if (local_664 != 0) {
    FUN_0040a240();
    local_8b0[0] = local_664;
    FUN_0040b540(local_8a8);
  }
  EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  uVar3 = FUN_0040a2e0();
  LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  FUN_0040a6e0(param_1 + 0x480,local_230,uVar3);
  local_4 = 3;
  EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  local_8b0[0] = FUN_0040a2e0();
  LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  local_8b0[0] = FUN_0040a5f0(param_1 + 0x25c,local_454,local_8b0[0]);
  local_4._0_1_ = 4;
  EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  FUN_0040a2e0();
  LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  local_8b0[0] = FUN_0040a2e0();
  LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  iVar5 = FUN_004e4340();
  local_4 = CONCAT31(local_4._1_3_,3);
  local_8b0[0] = local_440;
  if (local_440 != 0) {
    FUN_0040a240();
    FUN_0040b540(local_8a8);
  }
  local_4 = 0xffffffff;
  local_8b0[0] = local_21c;
  if (local_21c != 0) {
    FUN_0040a240();
    FUN_0040b540(local_8a8);
  }
  EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  local_8b0[0] = FUN_0040a2e0();
  LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  iVar6 = local_8b0[0] + local_8a0;
  if (iVar6 < iVar4) {
    if (iVar5 <= iVar6) {
      if (iVar5 < iVar6) {
        iVar4 = local_8a0 * 2 - iVar5;
      }
      goto LAB_004789f7;
    }
    iVar4 = local_8a0;
    iVar5 = local_8a0;
  }
  else {
LAB_004789f7:
    if ((iVar6 < iVar5) && (iVar4 < iVar6)) {
      iVar5 = local_8a0 * 2 - iVar4;
    }
  }
  iVar6 = 0x14;
  for (iVar5 = iVar5 - iVar4;
      (((iVar6 < -0x7f || (0x80 < iVar6)) || (iVar5 < -0x7f)) || (0x80 < iVar5)); iVar5 = iVar5 / 2)
  {
    iVar6 = iVar6 / 2;
  }
  sVar1 = *(short *)(&DAT_00598e7e + (iVar5 * 0x100 + iVar6) * 2);
  EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  FUN_0040a380((int)sVar1);
  LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
LAB_00478a67:
  *unaff_FS_OFFSET = local_c;
  return;
}
