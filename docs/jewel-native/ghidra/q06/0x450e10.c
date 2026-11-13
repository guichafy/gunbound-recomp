
undefined4 FUN_00450e10(int param_1)

{
  char cVar1;
  int iVar2;
  int unaff_EBX;

  if ((((unaff_EBX < 0) || (*(int *)(&DAT_006a7720 + DAT_005b3484) <= unaff_EBX)) || (param_1 < 0))
     || (*(int *)(&DAT_006a7724 + DAT_005b3484) <= param_1)) {
    return 0;
  }
  iVar2 = FUN_004f2f90();
  if (iVar2 != 0) {
    iVar2 = *(int *)(iVar2 + 0x10);
    cVar1 = *(char *)(iVar2 + 0x15);
    while (cVar1 == '\0') {
      cVar1 = FUN_0045d640(unaff_EBX,param_1);
      if (cVar1 != '\0') {
        return 1;
      }
      iVar2 = *(int *)(iVar2 + 0x10);
      cVar1 = *(char *)(iVar2 + 0x15);
    }
  }
  iVar2 = FUN_004f2f90();
  if (iVar2 != 0) {
    iVar2 = *(int *)(iVar2 + 0x10);
    cVar1 = *(char *)(iVar2 + 0x15);
    while (cVar1 == '\0') {
      cVar1 = FUN_00478a80(iVar2,unaff_EBX,param_1);
      if (cVar1 != '\0') {
        return 1;
      }
      iVar2 = *(int *)(iVar2 + 0x10);
      cVar1 = *(char *)(iVar2 + 0x15);
    }
  }
  return 0;
}
