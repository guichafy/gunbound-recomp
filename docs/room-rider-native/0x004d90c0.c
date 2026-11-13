
/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void __fastcall FUN_004d90c0(int param_1)

{
  undefined4 uVar1;
  undefined4 uVar2;
  int iVar3;
  int iVar4;
  int unaff_EBP;
  undefined4 *puVar5;
  uint uVar6;
  int iVar7;
  int iVar8;

  if (DAT_00793611 != '\x01') {
    (**(code **)(*DAT_00793604 + 0x50))(DAT_00793604,0x1b,1);
  }
  DAT_00793611 = 1;
  iVar4 = FUN_004f4650(s_AvataTexture1_0055565c);
  if (DAT_00793614 != 1) {
    DAT_00793614 = 1;
    _DAT_00792194 = 1;
    (**(code **)(*DAT_00793604 + 0x50))(DAT_00793604,0x13,5);
    (**(code **)(*DAT_00793604 + 0x50))(DAT_00793604,0x14,6);
  }
  if (iVar4 == 0) {
    iVar8 = 0;
    (**(code **)(*DAT_00793604 + 0x8c))(DAT_00793604,0,0);
  }
  else {
    uVar6 = 0;
    puVar5 = (undefined4 *)(param_1 + 0x6c0);
    iVar8 = DAT_005b3484;
    do {
      iVar7 = DAT_005b3484;
      if (*(char *)(iVar8 + 0x45914 + uVar6) != '\0') {
        uVar1 = *puVar5;
        uVar2 = puVar5[-1];
        *(undefined4 *)(iVar4 + 0x88) = 0x3f000000;
        *(float *)(iVar4 + 0x80) = (float)(uVar6 % 2) * _DAT_00557fb8;
        *(float *)(iVar4 + 0x84) = (float)(uVar6 / 2) * _DAT_00557fb8;
        FUN_004eca50(uVar2,uVar1,
                     CONCAT31((int3)(uVar6 / 2 >> 8),*(char *)(iVar7 + 0x4590c + uVar6) == '\0'),
                     0xff,0xffffff);
        iVar8 = iVar7;
      }
      uVar6 = uVar6 + 1;
      puVar5 = puVar5 + 2;
    } while ((int)uVar6 < 4);
    iVar8 = 0;
    (**(code **)(*DAT_00793604 + 0x8c))
              (DAT_00793604,0,*(undefined4 *)(*(int *)(iVar4 + 0x94) + 0x110));
  }
  if (DAT_00793658 != 0) {
    DAT_0079365c = DAT_0079365c + DAT_00793658;
    (**(code **)(*DAT_00793604 + 100))(DAT_00793604,4,0x244,&DAT_006ba190,DAT_00793658 * 3,1);
    DAT_00793658 = 0;
  }
  iVar4 = FUN_004f4650(s_AvataTexture2_00556914);
  if (iVar4 == 0) {
    iVar7 = 0;
    (**(code **)(*DAT_00793604 + 0x8c))(DAT_00793604,0,0);
  }
  else {
    uVar6 = 0;
    puVar5 = (undefined4 *)(unaff_EBP + 0x6e0);
    iVar7 = DAT_005b3484;
    do {
      iVar3 = DAT_005b3484;
      if (*(char *)(iVar7 + 0x45918 + uVar6) != '\0') {
        uVar1 = *puVar5;
        uVar2 = puVar5[-1];
        *(undefined4 *)(iVar4 + 0x88) = 0x3f000000;
        *(float *)(iVar4 + 0x80) = (float)(uVar6 % 2) * _DAT_00557fb8;
        *(float *)(iVar4 + 0x84) = (float)(uVar6 / 2) * _DAT_00557fb8;
        FUN_004eca50(uVar2,uVar1,
                     CONCAT31((int3)(uVar6 / 2 >> 8),*(char *)(iVar3 + 0x45910 + uVar6) == '\0'),
                     0xff,0xffffff);
        iVar7 = iVar3;
      }
      uVar6 = uVar6 + 1;
      puVar5 = puVar5 + 2;
    } while ((int)uVar6 < 4);
    iVar7 = 0;
    (**(code **)(*DAT_00793604 + 0x8c))
              (DAT_00793604,0,*(undefined4 *)(*(int *)(iVar4 + 0x94) + 0x110));
  }
  if (DAT_00793658 != 0) {
    DAT_0079365c = DAT_0079365c + DAT_00793658;
    (**(code **)(*DAT_00793604 + 100))(DAT_00793604,4,0x244,&DAT_006ba190,DAT_00793658 * 3,1);
    DAT_00793658 = 0;
  }
  iVar4 = FUN_004f4650(s_CharacterTexture1_005568d8);
  if (iVar4 == 0) {
    iVar8 = 0;
    (**(code **)(*DAT_00793604 + 0x8c))(DAT_00793604,0,0);
  }
  else {
    uVar6 = 0;
    puVar5 = (undefined4 *)(iVar8 + 0x6c0);
    iVar8 = DAT_005b3484;
    do {
      iVar3 = DAT_005b3484;
      if (*(char *)(iVar8 + 0x45914 + uVar6) != '\0') {
        uVar1 = *puVar5;
        uVar2 = puVar5[-1];
        *(undefined4 *)(iVar4 + 0x88) = 0x3f000000;
        *(float *)(iVar4 + 0x80) = (float)(uVar6 % 2) * _DAT_00557fb8;
        *(float *)(iVar4 + 0x84) = (float)(uVar6 / 2) * _DAT_00557fb8;
        FUN_004eca50(uVar2,uVar1,
                     CONCAT31((int3)(uVar6 / 2 >> 8),*(char *)(iVar3 + 0x4590c + uVar6) == '\0'),
                     0xff,0xffffff);
        iVar8 = iVar3;
      }
      uVar6 = uVar6 + 1;
      puVar5 = puVar5 + 2;
    } while ((int)uVar6 < 4);
    iVar8 = 0;
    (**(code **)(*DAT_00793604 + 0x8c))
              (DAT_00793604,0,*(undefined4 *)(*(int *)(iVar4 + 0x94) + 0x110));
  }
  if (DAT_00793658 != 0) {
    DAT_0079365c = DAT_0079365c + DAT_00793658;
    (**(code **)(*DAT_00793604 + 100))(DAT_00793604,4,0x244,&DAT_006ba190,DAT_00793658 * 3,1);
    DAT_00793658 = 0;
  }
  iVar4 = FUN_004f4650(s_CharacterTexture2_005568c4);
  if (iVar4 == 0) {
    iVar7 = 0;
    (**(code **)(*DAT_00793604 + 0x8c))(DAT_00793604,0,0);
  }
  else {
    uVar6 = 0;
    puVar5 = (undefined4 *)(iVar7 + 0x6e0);
    iVar7 = DAT_005b3484;
    do {
      iVar3 = DAT_005b3484;
      if (*(char *)(iVar7 + 0x45918 + uVar6) != '\0') {
        uVar1 = *puVar5;
        uVar2 = puVar5[-1];
        *(undefined4 *)(iVar4 + 0x88) = 0x3f000000;
        *(float *)(iVar4 + 0x80) = (float)(uVar6 % 2) * _DAT_00557fb8;
        *(float *)(iVar4 + 0x84) = (float)(uVar6 / 2) * _DAT_00557fb8;
        FUN_004eca50(uVar2,uVar1,
                     CONCAT31((int3)(uVar6 / 2 >> 8),*(char *)(iVar3 + 0x45910 + uVar6) == '\0'),
                     0xff,0xffffff);
        iVar7 = iVar3;
      }
      uVar6 = uVar6 + 1;
      puVar5 = puVar5 + 2;
    } while ((int)uVar6 < 4);
    iVar7 = 0;
    (**(code **)(*DAT_00793604 + 0x8c))
              (DAT_00793604,0,*(undefined4 *)(*(int *)(iVar4 + 0x94) + 0x110));
  }
  if (DAT_00793658 != 0) {
    DAT_0079365c = DAT_0079365c + DAT_00793658;
    (**(code **)(*DAT_00793604 + 100))(DAT_00793604,4,0x244,&DAT_006ba190,DAT_00793658 * 3,1);
    DAT_00793658 = 0;
  }
  iVar4 = FUN_004f4650(s_AvataEffectTexture1_00556900);
  if (DAT_00793614 != 2) {
    DAT_00793614 = 2;
    _DAT_00792194 = 2;
    (**(code **)(*DAT_00793604 + 0x50))(DAT_00793604,0x13,5);
    (**(code **)(*DAT_00793604 + 0x50))(DAT_00793604,0x14,2);
  }
  if (iVar4 == 0) {
    iVar8 = 0;
    (**(code **)(*DAT_00793604 + 0x8c))(DAT_00793604,0,0);
  }
  else {
    uVar6 = 0;
    puVar5 = (undefined4 *)(iVar8 + 0x6c0);
    iVar8 = DAT_005b3484;
    do {
      iVar3 = DAT_005b3484;
      if (*(char *)(iVar8 + 0x45914 + uVar6) != '\0') {
        uVar1 = *puVar5;
        uVar2 = puVar5[-1];
        *(undefined4 *)(iVar4 + 0x88) = 0x3f000000;
        *(float *)(iVar4 + 0x80) = (float)(uVar6 % 2) * _DAT_00557fb8;
        *(float *)(iVar4 + 0x84) = (float)(uVar6 / 2) * _DAT_00557fb8;
        FUN_004eca50(uVar2,uVar1,*(char *)(iVar3 + 0x4590c + uVar6) == '\0',0xff,0xffffff);
        iVar8 = iVar3;
      }
      uVar6 = uVar6 + 1;
      puVar5 = puVar5 + 2;
    } while ((int)uVar6 < 4);
    iVar8 = 0;
    (**(code **)(*DAT_00793604 + 0x8c))
              (DAT_00793604,0,*(undefined4 *)(*(int *)(iVar4 + 0x94) + 0x110));
  }
  if (DAT_00793658 != 0) {
    DAT_0079365c = DAT_0079365c + DAT_00793658;
    (**(code **)(*DAT_00793604 + 100))(DAT_00793604,4,0x244,&DAT_006ba190,DAT_00793658 * 3,1);
    DAT_00793658 = 0;
  }
  iVar4 = FUN_004f4650(s_AvataEffectTexture2_005568ec);
  if (iVar4 == 0) {
    iVar7 = 0;
    (**(code **)(*DAT_00793604 + 0x8c))(DAT_00793604,0,0);
  }
  else {
    uVar6 = 0;
    puVar5 = (undefined4 *)(iVar7 + 0x6e0);
    iVar7 = DAT_005b3484;
    do {
      iVar3 = DAT_005b3484;
      if (*(char *)(iVar7 + 0x45918 + uVar6) != '\0') {
        uVar1 = *puVar5;
        uVar2 = puVar5[-1];
        *(undefined4 *)(iVar4 + 0x88) = 0x3f000000;
        *(float *)(iVar4 + 0x80) = (float)(uVar6 % 2) * _DAT_00557fb8;
        *(float *)(iVar4 + 0x84) = (float)(uVar6 / 2) * _DAT_00557fb8;
        FUN_004eca50(uVar2,uVar1,
                     CONCAT31((int3)(uVar6 / 2 >> 8),*(char *)(iVar3 + 0x45910 + uVar6) == '\0'),
                     0xff,0xffffff);
        iVar7 = iVar3;
      }
      uVar6 = uVar6 + 1;
      puVar5 = puVar5 + 2;
    } while ((int)uVar6 < 4);
    iVar7 = 0;
    (**(code **)(*DAT_00793604 + 0x8c))
              (DAT_00793604,0,*(undefined4 *)(*(int *)(iVar4 + 0x94) + 0x110));
  }
  if (DAT_00793658 != 0) {
    DAT_0079365c = DAT_0079365c + DAT_00793658;
    (**(code **)(*DAT_00793604 + 100))(DAT_00793604,4,0x244,&DAT_006ba190,DAT_00793658 * 3,1);
    DAT_00793658 = 0;
  }
  iVar4 = FUN_004f4650(s_CharEffectTexture1_005568a4);
  if (iVar4 == 0) {
    (**(code **)(*DAT_00793604 + 0x8c))(DAT_00793604,0,0);
  }
  else {
    uVar6 = 0;
    puVar5 = (undefined4 *)(iVar8 + 0x6c0);
    iVar8 = DAT_005b3484;
    do {
      iVar3 = DAT_005b3484;
      if (*(char *)(uVar6 + 0x45914 + iVar8) != '\0') {
        uVar1 = *puVar5;
        uVar2 = puVar5[-1];
        *(undefined4 *)(iVar4 + 0x88) = 0x3f000000;
        *(float *)(iVar4 + 0x80) = (float)(uVar6 % 2) * _DAT_00557fb8;
        *(float *)(iVar4 + 0x84) = (float)(uVar6 / 2) * _DAT_00557fb8;
        FUN_004eca50(uVar2,uVar1,
                     CONCAT31((int3)(uVar6 / 2 >> 8),*(char *)(iVar3 + 0x4590c + uVar6) == '\0'),
                     0xff,0xffffff);
        iVar8 = iVar3;
      }
      uVar6 = uVar6 + 1;
      puVar5 = puVar5 + 2;
    } while ((int)uVar6 < 4);
    (**(code **)(*DAT_00793604 + 0x8c))
              (DAT_00793604,0,*(undefined4 *)(*(int *)(iVar4 + 0x94) + 0x110));
  }
  if (DAT_00793658 != 0) {
    DAT_0079365c = DAT_0079365c + DAT_00793658;
    (**(code **)(*DAT_00793604 + 100))(DAT_00793604,4,0x244,&DAT_006ba190,DAT_00793658 * 3,1);
    DAT_00793658 = 0;
  }
  iVar4 = FUN_004f4650(s_CharEffectTexture2_00556890);
  if (iVar4 == 0) {
    (**(code **)(*DAT_00793604 + 0x8c))(DAT_00793604,0,0);
  }
  else {
    uVar6 = 0;
    puVar5 = (undefined4 *)(iVar7 + 0x6e0);
    iVar8 = DAT_005b3484;
    do {
      iVar7 = DAT_005b3484;
      if (*(char *)(iVar8 + 0x45918 + uVar6) != '\0') {
        uVar1 = *puVar5;
        uVar2 = puVar5[-1];
        *(undefined4 *)(iVar4 + 0x88) = 0x3f000000;
        *(float *)(iVar4 + 0x80) = (float)(uVar6 % 2) * _DAT_00557fb8;
        *(float *)(iVar4 + 0x84) = (float)(uVar6 / 2) * _DAT_00557fb8;
        FUN_004eca50(uVar2,uVar1,
                     CONCAT31((int3)(uVar6 / 2 >> 8),*(char *)(iVar7 + 0x45910 + uVar6) == '\0'),
                     0xff,0xffffff);
        iVar8 = iVar7;
      }
      uVar6 = uVar6 + 1;
      puVar5 = puVar5 + 2;
    } while ((int)uVar6 < 4);
    (**(code **)(*DAT_00793604 + 0x8c))
              (DAT_00793604,0,*(undefined4 *)(*(int *)(iVar4 + 0x94) + 0x110));
  }
  if (DAT_00793658 != 0) {
    DAT_0079365c = DAT_0079365c + DAT_00793658;
    (**(code **)(*DAT_00793604 + 100))(DAT_00793604,4,0x244,&DAT_006ba190,DAT_00793658 * 3,1);
    DAT_00793658 = 0;
  }
  return;
}
