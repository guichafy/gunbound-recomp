
void FUN_0043b7a0(undefined4 param_1,int param_2,int param_3,int param_4,int param_5,int param_6,
                 byte param_7)

{
  int *piVar1;
  int *piVar2;
  char cVar3;
  int iVar4;
  int iVar5;
  int iVar6;
  uint uVar7;
  byte bVar8;
  undefined4 *unaff_FS_OFFSET;
  undefined1 local_680 [8];
  undefined1 local_678 [20];
  int local_664;
  undefined1 local_454 [548];
  undefined1 local_230 [20];
  int local_21c;
  undefined4 local_c;
  undefined1 *puStack_8;
  undefined4 local_4;

  iVar5 = DAT_005b3484;
  local_c = *unaff_FS_OFFSET;
  local_4 = 0xffffffff;
  puStack_8 = &LAB_0053ae5c;
  *unaff_FS_OFFSET = &local_c;
  if (param_2 <= *(int *)(&DAT_006a7724 + iVar5)) {
    if (param_3 != 0) {
      EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
      FUN_0040a2e0();
      LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
      iVar5 = DAT_005b3484;
    }
    piVar1 = *(int **)(*(int *)(&DAT_006a7f8c + iVar5) + 0x1c);
    uVar7 = piVar1[1];
    while (uVar7 < 0x186a2) {
      if (uVar7 == 0x186a1) {
        piVar2 = (int *)piVar1[4];
        goto joined_r0x0043b854;
      }
      piVar1 = (int *)piVar1[7];
      uVar7 = piVar1[1];
    }
LAB_0043ba8e:
    piVar1 = *(int **)(*(int *)(&DAT_006a7f8c + iVar5) + 0x1c);
    uVar7 = piVar1[1];
    while (uVar7 < 0x186a7) {
      if (uVar7 == 0x186a6) {
        for (piVar2 = (int *)piVar1[4]; piVar1 != piVar2; piVar2 = (int *)piVar2[4]) {
          if ((char)piVar2[5] == '\0') {
            FUN_0040a6e0(piVar2 + 0x97,local_678,param_1);
            local_4 = 2;
            EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
            iVar5 = FUN_0040a2e0();
            LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
            local_4 = 0xffffffff;
            if (local_664 != 0) {
              FUN_0040a240();
              FUN_0040b540(local_680);
            }
            FUN_0040a6e0(piVar2 + 0x120,local_230,param_2);
            local_4 = 3;
            EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
            iVar6 = FUN_0040a2e0();
            LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
            local_4 = 0xffffffff;
            if (local_21c != 0) {
              FUN_0040a240();
              FUN_0040b540(local_680);
            }
            if (iVar6 * iVar6 + iVar5 * iVar5 < param_4 * param_4) {
              EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
              iVar5 = _rand();
              *(char *)(piVar2 + 0x3ce) = (char)iVar5;
              iVar5 = _rand();
              *(byte *)((int)piVar2 + 0xf39) = (byte)iVar5;
              bVar8 = '\x01' << (*(byte *)(piVar2 + 0x3ce) & 7);
              bVar8 = ~bVar8 & (byte)iVar5 | bVar8;
              *(byte *)((int)piVar2 + 0xf39) = bVar8;
              *(byte *)((int)piVar2 + 0xf3a) = bVar8 + *(byte *)(piVar2 + 0x3ce) + -0x34;
              LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
              EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
              FUN_0040a380(param_5);
              LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
              EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
              FUN_0040a380(param_6);
              LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
              EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
              FUN_0040a380(param_4);
              LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
              EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
              iVar5 = _rand();
              *(char *)((int)piVar2 + 0xf3b) = (char)iVar5;
              iVar5 = _rand();
              *(byte *)(piVar2 + 0x3cf) = (byte)iVar5;
              bVar8 = *(byte *)((int)piVar2 + 0xf3b) & 7;
              bVar8 = ~('\x01' << bVar8) & (byte)iVar5 | '\0' << bVar8;
              *(byte *)(piVar2 + 0x3cf) = bVar8;
              *(byte *)((int)piVar2 + 0xf3d) = bVar8 + *(char *)((int)piVar2 + 0xf3b) + -0x34;
              LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
              (**(code **)(*piVar2 + 4))(s_shock_00553b80);
            }
          }
        }
        break;
      }
      piVar1 = (int *)piVar1[7];
      uVar7 = piVar1[1];
    }
  }
  *unaff_FS_OFFSET = local_c;
  return;
joined_r0x0043b854:
  if (piVar1 == piVar2) goto LAB_0043ba8e;
  cVar3 = FUN_004065a0();
  if (((cVar3 == '\0') || (cVar3 = FUN_004065a0(), cVar3 == '\x01')) || (piVar2[9] == 0xe)) {
    iVar5 = DAT_005b3484;
  }
  else {
    cVar3 = FUN_004065a0();
    iVar5 = param_4;
    if (cVar3 != '\0') {
      iVar5 = param_4 / 5 + param_4;
    }
    cVar3 = FUN_00406860();
    if (cVar3 != '\0') {
      FUN_0040a6e0(piVar2 + 0x243,local_454,param_1);
      local_4 = 0;
      EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
      iVar6 = FUN_0040a2e0();
      LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
      local_4 = 0xffffffff;
      FUN_0040a2a0();
      FUN_0040a6e0(piVar2 + 0x2cc,local_678,param_2);
      local_4 = 1;
      EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
      iVar4 = FUN_0040a2e0();
      LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
      local_4 = 0xffffffff;
      FUN_0040a2a0();
      if (iVar4 * iVar4 + iVar6 * iVar6 < iVar5 * iVar5) {
        FUN_00406500(1);
        FUN_0040a470(param_5);
        FUN_0040a470(param_6);
        FUN_0040a470(param_4);
        FUN_00406500(0);
        iVar5 = piVar2[9];
        if (((iVar5 != 0xe) && (iVar5 != 5)) && ((iVar5 != 6 && ((iVar5 != 8 && (iVar5 != 10)))))) {
          (**(code **)(*piVar2 + 4))(s_shock_00553b80);
        }
        iVar5 = DAT_005b3484;
        if (param_7 < 8) {
          uVar7 = (uint)param_7;
          if (*(char *)((piVar2[2] & 7U) + 0x4590c + DAT_005b3484) ==
              *(char *)(uVar7 + 0x4590c + DAT_005b3484)) {
            *(int *)(DAT_005b3484 + 0x5b83c + uVar7 * 4) =
                 *(int *)(DAT_005b3484 + 0x5b83c + uVar7 * 4) + param_5 + param_6;
            *(undefined1 *)(piVar2 + 0x2c2d) = 1;
          }
          else {
            *(int *)(DAT_005b3484 + 0x5b81c + uVar7 * 4) =
                 *(int *)(DAT_005b3484 + 0x5b81c + uVar7 * 4) + param_5 + param_6;
          }
          goto LAB_0043ba83;
        }
      }
    }
    iVar5 = DAT_005b3484;
  }
LAB_0043ba83:
  piVar2 = (int *)piVar2[4];
  goto joined_r0x0043b854;
}
