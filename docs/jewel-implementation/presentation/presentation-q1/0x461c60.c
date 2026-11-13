
void __fastcall FUN_00461c60(int param_1)

{
  int iVar1;

  if (*(int *)(param_1 + 0x1c) != 0) {
    iVar1 = FUN_00401610();
    *(int *)(param_1 + 0x24) = iVar1;
    if (iVar1 != -1) {
      *(undefined1 *)(param_1 + 0x20) = 1;
      *(undefined1 *)(param_1 + 0x34) = 0;
      *(undefined4 *)(param_1 + 0x2c) = 0;
      *(undefined4 *)(param_1 + 0x28) = 0;
      return;
    }
    *(undefined1 *)(param_1 + 0x20) = 0;
    *(undefined1 *)(param_1 + 0x34) = 1;
  }
  return;
}
