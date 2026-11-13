
void FUN_004ce3d0(int param_1)

{
  char cVar1;
  int iVar2;
  int *piVar3;
  undefined4 uVar4;
  undefined4 *puVar5;

  if (*(int *)(param_1 + 0x89c) != 0) {
    EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    iVar2 = FUN_0040a2e0();
    LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    if (*(int *)(param_1 + 0x8a0) <= iVar2) {
      cVar1 = FUN_0043c820();
      if (cVar1 != '\0') {
        EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
        FUN_0040a380(1);
        LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
        return;
      }
      piVar3 = (int *)FUN_004206f0(DAT_005b3484);
      if (piVar3 != (int *)0x0) {
        cVar1 = FUN_004065a0();
        if (cVar1 == '\x01') {
          (**(code **)(*piVar3 + 4))(&DAT_00553bcc);
          FUN_00406500(1);
          FUN_0040a470(0);
          piVar3[0x2ffb] = 0;
          FUN_0040a470(0);
          piVar3[0x2b84] = 0;
          uVar4 = FUN_0040a470(*(undefined4 *)(param_1 + 0xaa0));
          FUN_0040a4a0(uVar4);
          uVar4 = FUN_0040a470(0);
          FUN_0040a4a0(uVar4);
          iVar2 = FUN_004f30c0();
          if (iVar2 != 0) {
            *(undefined1 *)(iVar2 + 0x14) = 1;
          }
          FUN_0040a4d0(piVar3 + 0x68b);
          FUN_0041c360(DAT_005b3484,piVar3);
          FUN_00406500(0);
          *(undefined1 *)(piVar3 + 0x2b85) = 0;
          FUN_00406500(0);
          FUN_0040a470(0);
          FUN_0040a470(0);
          FUN_0040a470(0);
          piVar3[0x2fee] = *(int *)(param_1 + 0xea0);
        }
        iVar2 = 0;
        if (0 < *(int *)(param_1 + 0x89c) + -1) {
          puVar5 = (undefined4 *)(param_1 + 0x8a0);
          do {
            *puVar5 = puVar5[1];
            puVar5[0x80] = puVar5[0x81];
            puVar5[0x100] = puVar5[0x101];
            puVar5[0x180] = puVar5[0x181];
            iVar2 = iVar2 + 1;
            puVar5 = puVar5 + 1;
          } while (iVar2 < *(int *)(param_1 + 0x89c) + -1);
        }
      }
      *(int *)(param_1 + 0x89c) = *(int *)(param_1 + 0x89c) + -1;
      return;
    }
  }
  *(undefined1 *)(param_1 + 0x94) = 0;
  FUN_004cea70(param_1);
  return;
}
