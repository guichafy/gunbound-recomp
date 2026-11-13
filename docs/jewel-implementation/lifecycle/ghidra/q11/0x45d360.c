
int FUN_0045d360(char param_1)

{
  char cVar1;
  int in_EAX;
  int iVar2;
  int iVar3;
  int iVar4;
  int iVar5;

  EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  iVar2 = FUN_0040a2e0();
  LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  iVar3 = FUN_0040a2e0();
  LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  iVar4 = FUN_0040a2e0();
  LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  iVar5 = FUN_0040a2e0();
  LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  iVar5 = ((400 - iVar3) / iVar4) * iVar5;
  cVar1 = FUN_00406860();
  if (cVar1 != '\0') {
    cVar1 = FUN_004065a0();
    if (cVar1 == '\0') {
      cVar1 = FUN_004065a0();
      if (cVar1 == '\0') {
        iVar3 = in_EAX + 0x9230;
      }
      else {
        iVar3 = in_EAX + 0x9454;
      }
      iVar3 = FUN_0040a4d0(iVar3);
    }
    else {
      EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
      iVar3 = FUN_0040a2e0();
      LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    }
    iVar5 = iVar5 + iVar3;
  }
  cVar1 = FUN_004065a0();
  if (cVar1 == '\x01') {
    EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    iVar3 = FUN_0040a2e0();
    LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    iVar5 = iVar5 + iVar3;
    if (param_1 != '\0') {
      iVar3 = FUN_0041e9a0(DAT_005b3484,*(undefined2 *)(in_EAX + 0xbfbc));
      iVar5 = iVar5 + iVar3;
      goto LAB_0045d4b9;
    }
    EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    iVar3 = FUN_0040a2e0();
    LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    iVar4 = FUN_0041e9a0(DAT_005b3484,*(undefined2 *)(in_EAX + 0xbfbc));
    if (iVar4 + iVar3 * -3 < 0) {
      iVar3 = 0;
    }
    else {
      iVar4 = FUN_0040a4d0((*(uint *)(in_EAX + 8) & 7) * 0x1120 + 0x50cf4 + DAT_005b3484);
      iVar3 = FUN_0041e9a0(DAT_005b3484,*(undefined2 *)(in_EAX + 0xbfbc));
      iVar3 = iVar3 + iVar4 * -3;
    }
  }
  else {
LAB_0045d4b9:
    if (param_1 == '\0') goto LAB_0045d527;
    EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    iVar3 = FUN_0040a2e0();
    LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    iVar4 = FUN_0040a2e0();
    LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    iVar3 = iVar3 + iVar4 * -3;
  }
  iVar5 = iVar5 + iVar3;
LAB_0045d527:
  *(undefined1 *)(in_EAX + 0xae68) = 1;
  cVar1 = FUN_004065a0();
  if (cVar1 != '\0') {
    EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    FUN_0040a380(iVar5 + iVar2);
    LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  }
  EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  iVar3 = FUN_0040a2e0();
  LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  return iVar3 * (iVar5 + iVar2);
}
