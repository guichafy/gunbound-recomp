
void __thiscall
FUN_004372f0(char param_1,undefined4 param_2,int param_3,int param_4,int param_5,undefined4 param_6)

{
  char cVar1;
  void *pvVar2;
  int *piVar3;
  int iVar4;
  int iVar5;

  cVar1 = FUN_004065a0();
  if (cVar1 == '\0') {
    pvVar2 = operator_new(0x54);
    if (pvVar2 == (void *)0x0) {
      piVar3 = (int *)0x0;
    }
    else {
      piVar3 = (int *)FUN_00471af0();
    }
    piVar3[0xe] = param_3;
    piVar3[0xf] = param_4;
    if (param_1 == '\0') {
      iVar5 = 0;
    }
    else {
      EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
      iVar4 = FUN_0040a2e0();
      LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
      iVar5 = _rand();
      iVar5 = iVar5 % iVar4;
    }
    *(char *)(piVar3 + 0x14) = param_1;
    piVar3[0x11] = iVar5;
    piVar3[6] = param_5;
    iVar5 = FUN_004017d0(param_6);
    piVar3[7] = iVar5;
    (**(code **)(*piVar3 + 4))(s_flame_00553d2c);
    FUN_004f2fb0();
  }
  return;
}
