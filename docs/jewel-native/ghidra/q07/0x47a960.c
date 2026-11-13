
void __fastcall FUN_0047a960(int param_1)

{
  int iVar1;
  undefined4 uVar2;
  uint uVar3;
  int iVar4;

  iVar4 = *(int *)(DAT_005b3484 + 0x23270);
  uVar3 = *(uint *)(param_1 + 8);
  iVar1 = *(int *)(DAT_005b3484 + 0x23274);
  *(undefined1 *)(uVar3 + 0x23278 + DAT_005b3484) = 1;
  EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  uVar2 = FUN_0040a2e0();
  LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  *(undefined4 *)((*(int *)(param_1 + 8) + 9000) * 0x10 + DAT_005b3484) = uVar2;
  EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  uVar2 = FUN_0040a2e0();
  LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  *(undefined4 *)(*(int *)(param_1 + 8) * 0x10 + 0x23284 + DAT_005b3484) = uVar2;
  EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  uVar2 = FUN_0040a2e0();
  LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  *(undefined4 *)(*(int *)(param_1 + 8) * 0x10 + 0x23288 + DAT_005b3484) = uVar2;
  uVar3 = uVar3 & 0x80000003;
  if ((int)uVar3 < 0) {
    uVar3 = (uVar3 - 1 | 0xfffffffc) + 1;
  }
  iVar4 = ((*(uint *)(param_1 + 8) >> 2) * iVar1 + uVar3 * 2) * 0x40 + iVar4;
  EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  FUN_0040a2e0();
  LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  FUN_004784a0(iVar4,iVar1);
  EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  FUN_0040a2e0();
  LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  FUN_004784a0(iVar1 * 0x80 + iVar4,iVar1);
  return;
}
