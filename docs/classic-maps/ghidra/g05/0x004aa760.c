
void __fastcall FUN_004aa760(int param_1)

{
  int iVar1;
  uint uVar2;

  iVar1 = *(int *)(DAT_00ea0e1c + 0x1c);
  uVar2 = *(uint *)(iVar1 + 4);
  while( true ) {
    if (60000 < uVar2) goto LAB_004aa7a9;
    if (uVar2 == 60000) break;
    iVar1 = *(int *)(iVar1 + 0x1c);
    uVar2 = *(uint *)(iVar1 + 4);
  }
  iVar1 = *(int *)(iVar1 + 0x10);
  uVar2 = *(uint *)(iVar1 + 8);
  while ((uVar2 < 2 && (uVar2 != 1))) {
    iVar1 = *(int *)(iVar1 + 0x10);
    uVar2 = *(uint *)(iVar1 + 8);
  }
LAB_004aa7a9:
  FUN_004eb8e0(*(int *)(param_1 + 8) + 60000);
  return;
}
