
void __fastcall FUN_004ae1a0(int param_1)

{
  char cVar1;
  int iVar2;
  undefined4 uVar3;
  int iVar4;
  uint uVar5;
  
  if ((*(int *)(DAT_005b3484 + 0x20b94) != 0) && (*(int *)(param_1 + 0x3fa0) == -1)) {
    cVar1 = FUN_004065a0();
    if (cVar1 != '\0') {
      *(undefined1 *)(*(int *)(param_1 + 8) + 0x20bb4 + DAT_005b3484) = 0;
    }
    EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    iVar2 = FUN_0040a2e0();
    LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    cVar1 = FUN_00406610(iVar2 < 0);
    if (cVar1 == '\0') {
      *(undefined1 *)(*(int *)(param_1 + 8) + 0x20ba4 + DAT_005b3484) = 1;
    }
    else {
      *(undefined1 *)(*(int *)(param_1 + 8) + 0x20ba4 + DAT_005b3484) = 0;
    }
    EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    uVar3 = FUN_0040a2e0();
    LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    *(undefined4 *)(DAT_005b3484 + (*(int *)(param_1 + 8) + 0x1a35) * 0x14) = uVar3;
    EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    uVar3 = FUN_0040a2e0();
    LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    *(undefined4 *)(DAT_005b3484 + 0x20c28 + *(int *)(param_1 + 8) * 0x14) = uVar3;
    EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    uVar3 = FUN_0040a2e0();
    LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    iVar2 = DAT_005b3484;
    *(undefined4 *)(DAT_005b3484 + 0x20c2c + *(int *)(param_1 + 8) * 0x14) = uVar3;
    *(undefined4 *)(iVar2 + 0x20c34 + *(int *)(param_1 + 8) * 0x14) = 0;
    iVar4 = ((*(uint *)(param_1 + 8) >> 2) * *(int *)(iVar2 + 0x20b98) +
            (*(uint *)(param_1 + 8) & 3) * 2) * 0x40 + *(int *)(iVar2 + 0x20b94);
    if (iVar4 != 0) {
      FUN_00455b60(iVar4,*(int *)(iVar2 + 0x20b98));
      if (*(int *)(iVar2 + 0x20b9c) != 0) {
        uVar5 = FUN_00455b60(((*(uint *)(param_1 + 8) >> 2) * *(int *)(iVar2 + 0x20ba0) +
                             (*(uint *)(param_1 + 8) & 3) * 2) * 0x40 + *(int *)(iVar2 + 0x20b9c),
                             *(int *)(iVar2 + 0x20ba0));
        *(uint *)(iVar2 + 0x20c30 + *(int *)(param_1 + 8) * 0x14) = uVar5 & 0xff;
      }
    }
  }
  return;
}

