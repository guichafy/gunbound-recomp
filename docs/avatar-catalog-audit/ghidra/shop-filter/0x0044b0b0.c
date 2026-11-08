
void FUN_0044b0b0(int param_1)

{
  uint uVar1;
  int iVar2;
  
  iVar2 = 0;
  while( true ) {
    uVar1 = *(int *)(param_1 + 0x454) + iVar2;
    if (*(uint *)(DAT_005b3484 + 0x44e24) <= uVar1) {
      return;
    }
    if (*(uint *)(DAT_005b3484 + 0x44e24) <= uVar1) break;
    EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    uVar1 = FUN_0040a2e0();
    LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    FUN_004240c0(DAT_005b3484,(uVar1 & 0x8000) == 0x8000,uVar1 >> 0x10,uVar1 & 0x7fff);
    iVar2 = iVar2 + 1;
    if (0x14 < iVar2) {
      return;
    }
  }
                    /* WARNING: Subroutine does not return */
  FUN_004010c0(0x80070057);
}

