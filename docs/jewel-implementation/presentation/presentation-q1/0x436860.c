
void __fastcall FUN_00436860(int param_1,int param_2,undefined4 param_3,undefined4 param_4)

{
  char cVar1;
  int iVar2;
  void *pvVar3;

  cVar1 = FUN_004065a0();
  if (cVar1 == '\0') {
    if (param_1 != -1) {
      iVar2 = FUN_004f30c0();
      if (iVar2 != 0) {
        *(undefined4 *)(iVar2 + 0x40) = 0;
        *(int *)(iVar2 + 0x48) = *(int *)(iVar2 + 0x48) + param_2;
        return;
      }
    }
    pvVar3 = operator_new(0x50);
    if (pvVar3 == (void *)0x0) {
      iVar2 = 0;
    }
    else {
      iVar2 = FUN_00468620();
    }
    *(undefined4 *)(iVar2 + 0x3c) = param_4;
    *(int *)(iVar2 + 0x48) = param_2;
    *(undefined4 *)(iVar2 + 0x38) = param_3;
    FUN_004f2fb0();
  }
  return;
}
