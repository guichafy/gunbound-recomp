
void FUN_004e3c50(int param_1)

{
  char cVar1;
  uint uVar2;
  int iVar3;
  int iVar4;
  char *pcVar5;
  char *in_EAX;
  void *pvVar6;
  int iVar7;
  char *pcVar8;
  bool bVar9;
  char local_80 [4];
  char local_7c [124];

  iVar7 = *(int *)(DAT_00ea0e1c + 0x1c);
  uVar2 = *(uint *)(iVar7 + 4);
  while (uVar2 < 0xea61) {
    if (uVar2 == 60000) {
      iVar7 = *(int *)(iVar7 + 0x10);
      bVar9 = true;
      if (*(int *)(iVar7 + 8) == 0) goto LAB_004e3c93;
      goto LAB_004e3c9f;
    }
    iVar7 = *(int *)(iVar7 + 0x1c);
    uVar2 = *(uint *)(iVar7 + 4);
  }
  iVar7 = 0;
  goto LAB_004e3ca5;
  while( true ) {
    iVar7 = *(int *)(iVar7 + 0x10);
    bVar9 = *(int *)(iVar7 + 8) == 0;
    if (!bVar9) break;
LAB_004e3c93:
    if (bVar9) goto LAB_004e3ca5;
  }
LAB_004e3c9f:
  iVar7 = 0;
LAB_004e3ca5:
  iVar3 = -(int)in_EAX;
  do {
    cVar1 = *in_EAX;
    in_EAX[(int)(local_80 + iVar3)] = cVar1;
    in_EAX = in_EAX + 1;
  } while (cVar1 != '\0');
  pcVar5 = local_80 + -1;
  do {
    pcVar8 = pcVar5;
    pcVar5 = pcVar8 + 1;
  } while (pcVar8[1] != '\0');
  iVar3 = *(int *)(iVar7 + 0x24);
  iVar4 = *(int *)(iVar7 + 0x20);
  *(undefined4 *)(pcVar8 + 1) = DAT_00557258;
  pcVar8[5] = DAT_0055725c;
  pvVar6 = operator_new(iVar3 * iVar4);
  *(void **)(param_1 + 0x34) = pvVar6;
  pvVar6 = operator_new(*(int *)(iVar7 + 0x24) * *(int *)(iVar7 + 0x20));
  *(void **)(param_1 + 0x38) = pvVar6;
  iVar7 = FUN_004f1390(0);
  if (iVar7 != 0) {
    FUN_004f06c0(iVar7,param_1 + 0x18);
    FUN_004f06c0(iVar7,param_1 + 0x1c);
    FUN_004f06c0(iVar7,*(undefined4 *)(param_1 + 0x34));
    FUN_004f1460();
  }
  return;
}
