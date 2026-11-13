
int FUN_0040a7d0(undefined4 param_1,int param_2,int param_3)

{
  int iVar1;
  undefined4 uVar2;
  undefined4 *unaff_FS_OFFSET;
  undefined1 local_238 [28];
  int local_21c;
  undefined1 local_10;
  undefined4 local_c;
  undefined1 *puStack_8;
  uint local_4;

  local_4 = 0xffffffff;
  puStack_8 = &LAB_00538e6a;
  local_c = *unaff_FS_OFFSET;
  *unaff_FS_OFFSET = &local_c;
  EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  local_10 = 0;
  local_21c = 0;
  FUN_0040a380(0);
  local_4 = 1;
  iVar1 = FUN_0040a2e0();
  FUN_0040a380(iVar1 * param_3);
  LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  *(undefined1 *)(param_2 + 0x220) = 0;
  *(undefined4 *)(param_2 + 0x14) = 0;
  uVar2 = FUN_0040a2e0();
  FUN_0040a380(uVar2);
  local_4 = local_4 & 0xffffff00;
  if (local_21c != 0) {
    FUN_0040a240();
    FUN_0040b540(local_238);
  }
  *unaff_FS_OFFSET = local_c;
  return param_2;
}
