
void FUN_004e3d60(int param_1,char *param_2)

{
  char cVar1;
  uint uVar2;
  uint uVar3;
  undefined4 *puVar4;
  char *in_EAX;
  char *pcVar5;
  int iVar6;
  void *pvVar7;
  undefined4 *puVar8;
  int iVar9;
  undefined4 *puVar10;
  char *pcVar11;
  int iVar12;
  bool bVar13;
  char local_100 [4];
  char local_fc [123];
  undefined4 uStack_81;
  char local_7c [124];

  iVar12 = -(int)in_EAX;
  do {
    cVar1 = *in_EAX;
    in_EAX[(int)(local_100 + iVar12)] = cVar1;
    in_EAX = in_EAX + 1;
  } while (cVar1 != '\0');
  pcVar5 = local_100 + -1;
  do {
    pcVar11 = pcVar5;
    pcVar5 = pcVar11 + 1;
  } while (pcVar11[1] != '\0');
  *(undefined4 *)(pcVar11 + 1) = DAT_005554f8;
  pcVar11[5] = DAT_005554fc;
  pcVar5 = param_2;
  do {
    cVar1 = *pcVar5;
    pcVar5[(int)(local_7c + (-4 - (int)param_2))] = cVar1;
    pcVar5 = pcVar5 + 1;
  } while (cVar1 != '\0');
  puVar10 = &uStack_81;
  do {
    puVar8 = puVar10;
    puVar10 = (undefined4 *)((int)puVar8 + 1);
  } while (*(char *)((int)puVar8 + 1) != '\0');
  *(undefined4 *)((int)puVar8 + 1) = DAT_005554f8;
  *(char *)((int)puVar8 + 5) = DAT_005554fc;
  puVar10 = *(undefined4 **)(DAT_00ea0e1c + 0x1c);
  uVar2 = puVar10[1];
  if (uVar2 < 0xea61) {
LAB_004e3de1:
    if (uVar2 != 60000) goto code_r0x004e3de3;
    puVar8 = (undefined4 *)puVar10[4];
    if (puVar8 != puVar10) {
      do {
        puVar4 = (undefined4 *)*puVar8;
        puVar8 = (undefined4 *)puVar8[4];
        (*(code *)*puVar4)(1);
      } while (puVar8 != puVar10);
    }
    puVar10[3] = puVar10;
    puVar10[4] = puVar10;
  }
LAB_004e3e15:
  FUN_004f18c0(&DAT_00ea0e18,60000,0);
  if (*(char *)(DAT_005b3484 + 0x45578) == '\0') {
    FUN_004f18c0(&DAT_00ea0e18,60000,1);
  }
  iVar9 = DAT_005b3484;
  iVar12 = *(int *)(DAT_00ea0e1c + 0x1c);
  uVar2 = *(uint *)(iVar12 + 4);
  while (uVar2 < 0xea61) {
    if (uVar2 == 60000) {
      iVar12 = *(int *)(iVar12 + 0x10);
      bVar13 = true;
      if (*(int *)(iVar12 + 8) != 0) goto LAB_004e3e8f;
      goto LAB_004e3e83;
    }
    iVar12 = *(int *)(iVar12 + 0x1c);
    uVar2 = *(uint *)(iVar12 + 4);
  }
  iVar12 = 0;
  goto LAB_004e3e95;
code_r0x004e3de3:
  puVar10 = (undefined4 *)puVar10[7];
  uVar2 = puVar10[1];
  if (60000 < uVar2) goto LAB_004e3e15;
  goto LAB_004e3de1;
  while( true ) {
    iVar12 = *(int *)(iVar12 + 0x10);
    bVar13 = *(int *)(iVar12 + 8) == 0;
    if (!bVar13) break;
LAB_004e3e83:
    if (bVar13) goto LAB_004e3e95;
  }
LAB_004e3e8f:
  iVar12 = 0;
LAB_004e3e95:
  iVar6 = *(int *)(iVar12 + 0x20);
  *(int *)(param_1 + 0x18) = iVar6;
  *(undefined4 *)(param_1 + 0x1c) = *(undefined4 *)(iVar12 + 0x24);
  iVar6 = iVar6 / 2;
  *(int *)(param_1 + 8) = iVar6;
  *(int *)(param_1 + 0x10) = iVar6;
  iVar6 = *(int *)(param_1 + 0x1c) / 2;
  *(int *)(param_1 + 0xc) = iVar6;
  *(int *)(param_1 + 0x14) = iVar6;
  if (*(byte *)(iVar9 + 0x45578) != 0) {
    _sprintf(local_100,s_event_d1800_img_00557248,(uint)*(byte *)(iVar9 + 0x45578));
    FUN_004f18c0(&DAT_00ea0e18,60000,1);
  }
  pvVar7 = operator_new(*(int *)(iVar12 + 0x3c) << 1);
  iVar12 = DAT_005b3484;
  *(void **)(param_1 + 0x3c) = pvVar7;
  puVar10 = (undefined4 *)(param_1 + 0x51);
  for (iVar9 = 0x200; iVar9 != 0; iVar9 = iVar9 + -1) {
    *puVar10 = 0;
    puVar10 = puVar10 + 1;
  }
  cVar1 = *(char *)(iVar12 + 0x45578);
  iVar12 = 1;
  while( true ) {
    if (cVar1 != '\0') {
      return;
    }
    puVar10 = *(undefined4 **)(DAT_00ea0e1c + 0x1c);
    uVar3 = puVar10[1];
    uVar2 = iVar12 + 60000;
    if (uVar3 <= uVar2) break;
LAB_004e3f75:
    _sprintf((char *)((int)&uStack_81 + 1),s__s_d_img_0055723c,param_2,iVar12);
    iVar9 = FUN_004f1790(&DAT_00ea0e18,uVar2);
    if (iVar9 == 0) {
      return;
    }
    _sprintf(local_100,&DAT_00557234,param_2,iVar12);
    FUN_00401740(&DAT_0067ec70 + DAT_005b3484);
    FUN_004e4f50(param_1,iVar12,local_100);
    cVar1 = *(char *)(DAT_005b3484 + 0x45578);
    iVar12 = iVar12 + 1;
  }
LAB_004e3f4a:
  if (uVar3 != uVar2) goto code_r0x004e3f4c;
  puVar8 = (undefined4 *)puVar10[4];
  while (puVar8 != puVar10) {
    puVar4 = (undefined4 *)*puVar8;
    puVar8 = (undefined4 *)puVar8[4];
    (*(code *)*puVar4)(1);
  }
  puVar10[3] = puVar10;
  puVar10[4] = puVar10;
  goto LAB_004e3f75;
code_r0x004e3f4c:
  puVar10 = (undefined4 *)puVar10[7];
  uVar3 = puVar10[1];
  if (uVar2 < uVar3) goto LAB_004e3f75;
  goto LAB_004e3f4a;
}
