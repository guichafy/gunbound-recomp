
undefined4 FUN_00423bf0(void)

{
  undefined4 uVar1;
  int iVar2;
  undefined4 local_4;
  
  iVar2 = FUN_004f1390(0);
  if (iVar2 != 0) {
    FUN_004f06c0(iVar2,&local_4);
    uVar1 = local_4;
    EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    FUN_0040a380(uVar1);
    LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    FUN_004f1460();
    iVar2 = FUN_004f1390(0);
    if (iVar2 != 0) {
      FUN_004f06c0(iVar2,&local_4);
      uVar1 = local_4;
      EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
      FUN_0040a380(uVar1);
      LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
      FUN_004f1460();
      iVar2 = FUN_004f1390(0);
      if (iVar2 != 0) {
        FUN_004f06c0(iVar2,&local_4);
        FUN_0040a470(local_4);
        FUN_004f1460();
        EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
        FUN_0040a380(0);
        LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
        iVar2 = FUN_004f1390(0);
        if (iVar2 != 0) {
          FUN_004f06c0(iVar2,&local_4);
          FUN_0040a470(local_4);
          FUN_004f1460();
          iVar2 = FUN_004f1390(0);
          if (iVar2 != 0) {
            FUN_004f06c0(iVar2,&local_4);
            FUN_0040a470(local_4);
            FUN_004f1460();
            iVar2 = FUN_004f1390(0);
            if (iVar2 != 0) {
              FUN_004f06c0(iVar2,&local_4);
              FUN_0040a470(local_4);
              FUN_004f1460();
              iVar2 = FUN_004f1390(0);
              if (iVar2 != 0) {
                FUN_004f06c0(iVar2,&local_4);
                FUN_0040a470(local_4);
                FUN_004f1460();
                return 1;
              }
            }
          }
        }
      }
    }
  }
  return 0;
}

