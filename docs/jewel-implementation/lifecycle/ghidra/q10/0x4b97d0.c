
/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void __thiscall FUN_004b97d0(int *param_1,uint param_2,int param_3,uint param_4)

{
  short *psVar1;
  undefined2 *puVar2;
  undefined1 *puVar3;
  char cVar4;
  undefined1 uVar5;
  short sVar6;
  undefined2 uVar7;
  undefined2 uVar8;
  uint uVar9;
  int iVar10;
  int iVar11;
  int iVar12;
  uint uVar13;
  int iVar14;
  int iVar15;
  undefined *puVar16;
  undefined4 extraout_EDX;
  uint uVar17;
  uint uVar18;
  bool bVar19;
  undefined4 uVar20;
  undefined4 uVar21;
  char *pcVar22;
  undefined4 uVar23;
  char local_80 [128];

  iVar12 = DAT_005b3484;
  if (0x202 < param_2) {
    if (param_2 == 0x204) {
      *(undefined1 *)((int)param_1 + 0x91) = 1;
      if (DAT_00e53c3c != '\0') {
        DAT_00e53c3c = '\0';
      }
      (&DAT_006a7758)[DAT_005b3484] = 0;
      FUN_00461c60(&DAT_00553f90);
      return;
    }
    if (param_2 == 0x205) {
      uVar5 = 0;
      *(undefined1 *)((int)param_1 + 0x91) = 0;
      if (DAT_00e53c3c != '\x01') {
        DAT_00e53c3c = '\x01';
      }
      if ((*(char *)((int)param_1 + 0x92) == '\0') && (*(char *)((int)param_1 + 0x93) == '\0')) {
        uVar5 = 1;
      }
      (&DAT_006a7758)[DAT_005b3484] = uVar5;
      FUN_00461c60(s_normal_00552230);
      return;
    }
    if (param_2 != 0x206) {
      return;
    }
    iVar10 = FUN_0040a4d0(*(int *)(DAT_005b3484 + 0x621e0) + 0xb30);
    iVar11 = FUN_0040a4d0(*(int *)(DAT_005b3484 + 0x621e0) + 0x90c);
    iVar12 = DAT_005b3484;
    cVar4 = FUN_004065a0();
    if ((cVar4 == '\0') && ((&DAT_006a7758)[iVar12] != '\0')) {
      iVar14 = 400;
      if (399 < iVar11) {
        iVar14 = iVar11;
      }
      if (*(int *)(&DAT_006a7720 + iVar12) + -400 < iVar14) {
        iVar11 = *(int *)(&DAT_006a7720 + iVar12) + -400;
      }
      else if (iVar11 < 400) {
        iVar11 = 400;
      }
      iVar14 = -0x14;
      if (-0x15 < iVar10) {
        iVar14 = iVar10;
      }
      iVar15 = *(int *)(&DAT_006a7724 + iVar12) + -0x104;
      if ((iVar14 <= *(int *)(&DAT_006a7724 + iVar12) + -0x104) && (iVar15 = -0x14, -0x15 < iVar10))
      {
        iVar15 = iVar10;
      }
      *(int *)(&DAT_006a7718 + iVar12) = iVar11;
      *(int *)(&DAT_006a771c + iVar12) = iVar15;
    }
    *(undefined1 *)((int)param_1 + 0x91) = 1;
    if (DAT_00e53c3c != '\0') {
      DAT_00e53c3c = '\0';
    }
    (&DAT_006a7758)[DAT_005b3484] = 0;
    return;
  }
  if (param_2 != 0x202) {
    if (0x112 < param_2) {
      if (param_2 != 0x201) {
        return;
      }
      uVar17 = param_4 & 0xffff;
      uVar9 = param_4 >> 0x10;
      if ((char)param_1[0x46b] != '\0') {
        if ((0x72 < uVar9) && (uVar9 < 0x7f)) {
          if ((0x1d < uVar17) && (uVar17 < 0x5e)) {
            (&DAT_005f2f40)[DAT_005b3484] = 2;
          }
          if ((0x71 < uVar17) && (uVar17 < 0xb2)) {
            (&DAT_005f2f40)[iVar12] = 0;
          }
          if ((0xc6 < uVar17) && (uVar17 < 0x106)) {
            (&DAT_005f2f40)[iVar12] = 1;
          }
          FUN_0040a470(0xffffffff);
          FUN_0040a470(0xffffffff);
        }
        iVar12 = DAT_005b3484;
        if ((0xa8 < uVar9) && (uVar9 < 0xb4)) {
          if ((0x27 < uVar17) && (uVar17 < 0x41)) {
            *(undefined4 *)(&DAT_005f2f44 + DAT_005b3484) = 0x14;
          }
          if ((0x41 < uVar17) && (uVar17 < 0x69)) {
            *(undefined4 *)(&DAT_005f2f44 + iVar12) = 0x1e;
          }
          if ((0x69 < uVar17) && (uVar17 < 0x91)) {
            *(undefined4 *)(&DAT_005f2f44 + iVar12) = 0x28;
          }
          if ((0x91 < uVar17) && (uVar17 < 0xb9)) {
            *(undefined4 *)(&DAT_005f2f44 + iVar12) = 0x32;
          }
          if ((0xb9 < uVar17) && (uVar17 < 0xe1)) {
            *(undefined4 *)(&DAT_005f2f44 + iVar12) = 0x3c;
          }
          if ((0xe1 < uVar17) && (uVar17 < 0x109)) {
            *(undefined4 *)(&DAT_005f2f44 + iVar12) = 0x46;
          }
        }
        if ((0xda < uVar9) && (uVar9 < 0xe6)) {
          if ((0x23 < uVar17) && (uVar17 < 0x50)) {
            (&DAT_005f2f48)[iVar12] = 0;
          }
          if ((0xd6 < uVar17) && (uVar17 < 0x101)) {
            (&DAT_005f2f48)[iVar12] = 1;
          }
        }
        if ((0xf8 < uVar9) && (uVar9 < 0x104)) {
          if ((0x59 < uVar17) && (uVar17 < 0x6e)) {
            bVar19 = DAT_00793549 != '\0';
            *(undefined4 *)(&DAT_005f2f4c + iVar12) = 0;
            DAT_0079354a = '\0';
            if (bVar19) {
              (**(code **)(*(int *)*DAT_00793554 + 0xc))();
              DAT_00793568 = 0;
              iVar12 = DAT_005b3484;
            }
          }
          if ((0x6e < uVar17) && (uVar17 < 0x8c)) {
            if (DAT_0079354a == '\0') {
              DAT_0079354a = DAT_00793549 != '\0';
              _sprintf(local_80,s_stage_d_mp3_005569c0,(uint)*(byte *)(iVar12 + 0x475c4));
              cVar4 = FUN_004eea30(1);
              if (cVar4 == '\0') {
                iVar12 = _rand();
                _sprintf(local_80,s_stage_d_mp3_005569c0,iVar12 % 6 + 1);
                FUN_004eea30(1);
              }
              iVar12 = DAT_005b3484;
            }
            *(undefined4 *)(&DAT_005f2f4c + iVar12) = 0x50;
            FUN_004eeb10();
            iVar12 = DAT_005b3484;
          }
          if ((0x8c < uVar17) && (uVar17 < 0xaa)) {
            if (DAT_0079354a == '\0') {
              DAT_0079354a = DAT_00793549 != '\0';
              _sprintf(local_80,s_stage_d_mp3_005569c0,(uint)*(byte *)(iVar12 + 0x475c4));
              cVar4 = FUN_004eea30(1);
              if (cVar4 == '\0') {
                iVar12 = _rand();
                _sprintf(local_80,s_stage_d_mp3_005569c0,iVar12 % 6 + 1);
                FUN_004eea30(1);
              }
              iVar12 = DAT_005b3484;
            }
            *(undefined4 *)(&DAT_005f2f4c + iVar12) = 0x5a;
            FUN_004eeb10();
            iVar12 = DAT_005b3484;
          }
          if ((0xaa < uVar17) && (uVar17 < 200)) {
            if (DAT_0079354a == '\0') {
              DAT_0079354a = DAT_00793549 != '\0';
              _sprintf(local_80,s_stage_d_mp3_005569c0,(uint)*(byte *)(iVar12 + 0x475c4));
              cVar4 = FUN_004eea30(1);
              if (cVar4 == '\0') {
                iVar12 = _rand();
                _sprintf(local_80,s_stage_d_mp3_005569c0,iVar12 % 6 + 1);
                FUN_004eea30(1);
              }
              iVar12 = DAT_005b3484;
            }
            *(undefined4 *)(&DAT_005f2f4c + iVar12) = 0x5f;
            FUN_004eeb10();
            iVar12 = DAT_005b3484;
          }
          if ((200 < uVar17) && (uVar17 < 0xe6)) {
            if (DAT_0079354a == '\0') {
              DAT_0079354a = DAT_00793549 != '\0';
              _sprintf(local_80,s_stage_d_mp3_005569c0,(uint)*(byte *)(iVar12 + 0x475c4));
              cVar4 = FUN_004eea30(1);
              if (cVar4 == '\0') {
                iVar12 = _rand();
                _sprintf(local_80,s_stage_d_mp3_005569c0,iVar12 % 6 + 1);
                FUN_004eea30(1);
              }
              iVar12 = DAT_005b3484;
            }
            *(undefined4 *)(&DAT_005f2f4c + iVar12) = 0x62;
            FUN_004eeb10();
            iVar12 = DAT_005b3484;
          }
          if ((0xe6 < uVar17) && (uVar17 < 0xfb)) {
            if (DAT_0079354a == '\0') {
              DAT_0079354a = DAT_00793549 != '\0';
              _sprintf(local_80,s_stage_d_mp3_005569c0,(uint)*(byte *)(iVar12 + 0x475c4));
              cVar4 = FUN_004eea30(1);
              if (cVar4 == '\0') {
                iVar12 = _rand();
                _sprintf(local_80,s_stage_d_mp3_005569c0,iVar12 % 6 + 1);
                FUN_004eea30(1);
              }
              iVar12 = DAT_005b3484;
            }
            *(undefined4 *)(&DAT_005f2f4c + iVar12) = 100;
            FUN_004eeb10();
            iVar12 = DAT_005b3484;
          }
        }
        uVar13 = DAT_00793560;
        if ((0x112 < uVar9) && (uVar9 < 0x11e)) {
          if ((0x59 < uVar17) && (uVar17 < 0x6e)) {
            uVar18 = 1;
            *(undefined4 *)(&DAT_005f2f50 + iVar12) = 0;
            DAT_0079354b = 0;
            if (1 < uVar13) {
              do {
                if (DAT_00793549 != '\0') {
                  if (uVar18 != 0xffffffff) {
                    (**(code **)(*(int *)DAT_00793554[uVar18] + 0xc))();
                    iVar12 = DAT_005b3484;
                  }
                  if (uVar18 == 0) {
                    DAT_00793568 = 0;
                  }
                }
                uVar18 = uVar18 + 1;
              } while (uVar18 < DAT_00793560);
            }
          }
          if ((0x6e < uVar17) && (uVar17 < 0x8c)) {
            DAT_0079354b = DAT_00793549 != '\0';
            *(undefined4 *)(&DAT_005f2f50 + iVar12) = 0x50;
            FUN_004eeb30();
            iVar12 = DAT_005b3484;
          }
          if ((0x8c < uVar17) && (uVar17 < 0xaa)) {
            DAT_0079354b = DAT_00793549 != '\0';
            *(undefined4 *)(&DAT_005f2f50 + iVar12) = 0x5a;
            FUN_004eeb30();
            iVar12 = DAT_005b3484;
          }
          if ((0xaa < uVar17) && (uVar17 < 200)) {
            DAT_0079354b = DAT_00793549 != '\0';
            *(undefined4 *)(&DAT_005f2f50 + iVar12) = 0x5f;
            FUN_004eeb30();
            iVar12 = DAT_005b3484;
          }
          if ((200 < uVar17) && (uVar17 < 0xe6)) {
            DAT_0079354b = DAT_00793549 != '\0';
            *(undefined4 *)(&DAT_005f2f50 + iVar12) = 0x62;
            FUN_004eeb30();
            iVar12 = DAT_005b3484;
          }
          if ((0xe6 < uVar17) && (uVar17 < 0xfb)) {
            DAT_0079354b = DAT_00793549 != '\0';
            *(undefined4 *)(&DAT_005f2f50 + iVar12) = 100;
            FUN_004eeb30();
            iVar12 = DAT_005b3484;
          }
        }
        if ((0x143 < uVar9) && (uVar9 < 0x151)) {
          if ((0x1d < uVar17) && (uVar17 < 0x5d)) {
            (&DAT_005f2f54)[iVar12] = 3;
          }
          if ((0x71 < uVar17) && (uVar17 < 0xb2)) {
            (&DAT_005f2f54)[iVar12] = 2;
          }
          if ((0xc6 < uVar17) && (uVar17 < 0x107)) {
            (&DAT_005f2f54)[iVar12] = 1;
          }
        }
        if (uVar9 < 0x177) {
          return;
        }
        if (0x182 < uVar9) {
          return;
        }
        if ((0x23 < uVar17) && (uVar17 < 0x4a)) {
          (&DAT_005f2f55)[iVar12] = 1;
        }
        if (uVar17 < 0xdc) {
          return;
        }
        if (uVar17 < 0x102) {
          (&DAT_005f2f55)[iVar12] = 0;
          return;
        }
        return;
      }
      if ((((0x226 < uVar9) && (uVar9 < 599)) && (0xf4 < uVar17)) && (uVar17 < 0x284)) {
        *(uint *)(DAT_005b3484 + 0xebee8) = uVar17;
        *(undefined1 *)(param_1 + 4) = 1;
      }
      if ((3 < uVar9) && (uVar9 < 0x22)) {
        cVar4 = FUN_004065a0();
        if (((cVar4 == '\0') &&
            ((cVar4 = FUN_004065a0(), cVar4 == '\x01' && ((char)param_1[0x42f] == '\x01')))) &&
           (cVar4 = FUN_0040b2a0(DAT_005b3484 + 0xebcbc,6), cVar4 != '\0')) {
          iVar12 = 0;
          iVar11 = 0x218;
          do {
            cVar4 = FUN_0040b2a0(iVar12 + 0x39f30 + DAT_005b3484,0);
            if (((cVar4 != '\0') && (iVar11 + -0x23 < (int)uVar17)) && ((int)uVar17 < iVar11)) {
              cVar4 = FUN_004065a0();
              if (cVar4 == '\0') {
                iVar11 = FUN_00420600(DAT_005b3484);
                iVar12 = DAT_005b3484;
                if (*(int *)(DAT_005b3484 + 0xf0374) == iVar11) {
                  *(undefined4 *)(DAT_005b3484 + 0xf0374) = 0xffffffff;
                }
                else {
                  *(int *)(DAT_005b3484 + 0xf0374) = iVar11;
                }
                goto LAB_004ba6f8;
              }
              uVar20 = FUN_00420600(DAT_005b3484);
              FUN_004cbda0(param_1,uVar20);
              break;
            }
            iVar11 = iVar11 + 0x24;
            iVar12 = iVar12 + 0x224;
          } while (iVar11 < 0x2f0);
        }
        iVar12 = DAT_005b3484;
      }
LAB_004ba6f8:
      if (uVar9 < 0x27) {
        return;
      }
      if (499 < uVar9) {
        return;
      }
      if (*(char *)((int)param_1 + 0x92) != '\0') {
        FUN_004e6c90(0x8404);
        sVar6 = FUN_0040a4d0(DAT_005b3484 + 0xeba98);
        *(short *)(&DAT_00e9aacc + DAT_00e9accc) = sVar6 + 4;
        puVar16 = &DAT_006a64c4 + DAT_005b3484;
        psVar1 = (short *)(&DAT_00e9aace + DAT_00e9accc);
        DAT_00e9accc = DAT_00e9accc + 2;
        *psVar1 = *(short *)(&DAT_006a7710 + DAT_005b3484) + (short)param_4 + -400;
        DAT_00e9accc = DAT_00e9accc + 2;
        iVar12 = FUN_0040a4d0(puVar16);
        if (iVar12 == 1) {
          iVar12 = _rand();
          (&DAT_00e9aacc)[DAT_00e9accc] = (char)(iVar12 % 6) + '\x02';
        }
        else {
          uVar5 = FUN_0040a4d0(&DAT_006a64c4 + DAT_005b3484);
          (&DAT_00e9aacc)[DAT_00e9accc] = uVar5;
        }
        DAT_00e9accc = DAT_00e9accc + 1;
        uVar5 = FUN_0040a4d0(DAT_005b3484 + 0x3b49c);
        (&DAT_00e9aacc)[DAT_00e9accc] = uVar5;
        DAT_00e9accc = DAT_00e9accc + 1;
        FUN_004e6fc0();
        *(undefined1 *)((int)param_1 + 0x92) = 0;
        FUN_004e1f70();
        FUN_00405fb0();
        iVar12 = DAT_005b3484;
        (&DAT_006a7758)[DAT_005b3484] = 1;
        *(undefined4 *)(&DAT_006a73c8 + iVar12) = 1;
      }
      if (*(char *)((int)param_1 + 0x93) != '\0') {
        FUN_004e6c90(0x8408);
        cVar4 = FUN_0040b270(DAT_005b3484 + 0x45354,3);
        if (cVar4 == '\0') {
          sVar6 = FUN_0040a4d0(DAT_005b3484 + 0xeba98);
          *(short *)(&DAT_00e9aacc + DAT_00e9accc) = sVar6 + 4;
        }
        else {
          sVar6 = FUN_0040a4d0(DAT_005b3484 + 0xeba98);
          *(short *)(&DAT_00e9aacc + DAT_00e9accc) = sVar6 + 2;
        }
        iVar12 = DAT_00e9accc;
        DAT_00e9accc = DAT_00e9accc + 2;
        iVar11 = DAT_005b3484 + 0x3b49c;
        *(short *)(&DAT_00e9aace + iVar12) =
             *(short *)(&DAT_006a7710 + DAT_005b3484) + (short)param_4 + -400;
        DAT_00e9accc = DAT_00e9accc + 2;
        iVar12 = FUN_0040a4d0(iVar11);
        uVar13 = FUN_0040a4d0(iVar12 * 0x224 + 0xebef4 + DAT_005b3484);
        if (uVar13 < 10) {
          *(undefined4 *)(&DAT_00e9aacc + DAT_00e9accc) = 10;
        }
        else {
          iVar12 = FUN_0045d360(0);
          *(int *)(&DAT_00e9aacc + DAT_00e9accc) = iVar12 / 2;
        }
        DAT_00e9accc = DAT_00e9accc + 4;
        FUN_004e6fc0();
        iVar12 = DAT_005b3484;
        *(undefined1 *)((int)param_1 + 0x93) = 0;
        (&DAT_006a7758)[iVar12] = 1;
      }
      iVar11 = FUN_0043c550(*(int *)(&DAT_006a7710 + iVar12) + -400 + uVar17,
                            *(int *)(&DAT_006a7714 + iVar12) + -0x12a + uVar9);
      iVar12 = DAT_005b3484;
      if (iVar11 != -1) {
        _DAT_00e9b4e8 = *(undefined2 *)(DAT_005b3484 + 0x4591c + iVar11 * 2);
        pcVar22 = (char *)(iVar11 * 0xd + 0x457f1 + DAT_005b3484);
        iVar10 = (int)&DAT_00e9b4fd - (int)pcVar22;
        do {
          cVar4 = *pcVar22;
          pcVar22[iVar10] = cVar4;
          pcVar22 = pcVar22 + 1;
        } while (cVar4 != '\0');
        pcVar22 = (char *)(iVar11 * 9 + 0x457a9 + iVar12);
        iVar10 = (int)&DAT_00e9b4ea - (int)pcVar22;
        do {
          cVar4 = *pcVar22;
          pcVar22[iVar10] = cVar4;
          pcVar22 = pcVar22 + 1;
        } while (cVar4 != '\0');
        uVar20 = *(undefined4 *)(iVar12 + 0x4593c + iVar11 * 4);
        pcVar22 = (char *)FUN_0043dc70(&DAT_00796eec,3000);
        _sprintf(&DAT_00e9b50a,pcVar22,uVar20);
        uVar9 = *(uint *)(DAT_005b3484 + 0x4597c + iVar11 * 4);
        if (999 < uVar9) {
          uVar9 = 999;
        }
        uVar20 = *(undefined4 *)(DAT_005b3484 + 0x4599c + iVar11 * 4);
        pcVar22 = (char *)FUN_0043dc70(&DAT_00796eec,0xbb9);
        _sprintf(&DAT_00e9b58a,pcVar22,uVar9,uVar20);
        iVar12 = *(int *)(DAT_005b3484 + 0x472fc + iVar11 * 4);
        uVar9 = *(int *)(DAT_005b3484 + 0x4731c + iVar11 * 4) + iVar12;
        if (uVar9 == 0) {
          uVar9 = 1;
        }
        uVar9 = (uint)(iVar12 * 100) / uVar9;
        pcVar22 = (char *)FUN_0043dc70(&DAT_00796eec,0xbba);
        _sprintf(&DAT_00e9b60a,pcVar22,uVar9);
        uVar9 = *(uint *)(DAT_005b3484 + 0x4735c + iVar11 * 4);
        if (uVar9 == 0) {
          uVar9 = 1;
        }
        uVar9 = *(uint *)(DAT_005b3484 + 0x4733c + iVar11 * 4) / uVar9;
        pcVar22 = (char *)FUN_0043dc70(&DAT_00796eec,0xbbb);
        _sprintf(&DAT_00e9b68a,pcVar22,uVar9);
        iVar14 = FUN_0040a4d0(iVar11 * 0x448 + 0x477ec + DAT_005b3484);
        iVar15 = FUN_00420650(DAT_005b3484,iVar11,iVar14);
        iVar12 = iVar11 * 0x14 + iVar14;
        iVar10 = *(int *)(DAT_005b3484 + 0x459bc + iVar12 * 4);
        uVar9 = *(int *)(DAT_005b3484 + 0x45c3c + iVar12 * 4) + iVar10;
        if (uVar9 == 0) {
          uVar9 = 1;
        }
        uVar9 = (uint)(iVar10 * 100) / uVar9;
        uVar20 = FUN_0043dc70(&DAT_00796eec,iVar14 + 1000);
        pcVar22 = (char *)FUN_0043dc70(&DAT_00796eec,0xbbc);
        _sprintf(&DAT_00e9b70a,pcVar22,uVar20,uVar9);
        iVar12 = iVar11 * 0x14 + iVar15;
        iVar11 = *(int *)(DAT_005b3484 + 0x459bc + iVar12 * 4);
        uVar9 = *(int *)(DAT_005b3484 + 0x45c3c + iVar12 * 4) + iVar11;
        if (uVar9 == 0) {
          uVar9 = 1;
        }
        uVar9 = (uint)(iVar11 * 100) / uVar9;
        uVar20 = FUN_0043dc70(&DAT_00796eec,iVar15 + 1000);
        pcVar22 = (char *)FUN_0043dc70(&DAT_00796eec,0xbbd);
        _sprintf(&DAT_00e9b78a,pcVar22,uVar20,uVar9);
        _DAT_00e9b810 = 800;
        _DAT_00e9b80c = 0xfffffff6;
        DAT_00e9b80a = 1;
        (&DAT_006a7758)[DAT_005b3484] = 0;
        return;
      }
      cVar4 = FUN_00406710();
      if (cVar4 == '\0') {
        return;
      }
      cVar4 = FUN_004065a0();
      if (cVar4 == '\0') {
        return;
      }
      cVar4 = FUN_004065a0();
      if (cVar4 == '\0') {
        return;
      }
      if (*(int *)(*(int *)(DAT_005b3484 + 0x621e0) + 0x24) == 0xd) {
        return;
      }
      if ((char)param_1[0x468] != '\0') {
        return;
      }
      if ((&DAT_005f2f40)[DAT_005b3484] != '\x02') {
        return;
      }
      if (*(int *)(&DAT_005f3768 + DAT_005b3484) == 1) {
        return;
      }
      if (*(int *)(&DAT_005f3768 + DAT_005b3484) == 2) {
        return;
      }
      *(undefined1 *)(param_1 + 0x468) = 1;
      param_1[0x469] = 0;
      param_1[0x46a] = 0;
      if (DAT_00e53c3c != '\0') {
        DAT_00e53c3c = '\0';
      }
      FUN_00461c60(&DAT_00556980);
      FUN_00406300(0);
      FUN_004e6c90(0x8006);
      uVar7 = FUN_0040a4d0(*(int *)(DAT_005b3484 + 0x621e0) + 0x90c);
      iVar12 = DAT_005b3484;
      *(undefined2 *)(&DAT_00e9aacc + DAT_00e9accc) = uVar7;
      DAT_00e9accc = DAT_00e9accc + 2;
      uVar7 = FUN_0040a4d0(*(int *)(iVar12 + 0x621e0) + 0xb30);
      *(undefined2 *)(&DAT_00e9aacc + DAT_00e9accc) = uVar7;
      DAT_00e9accc = DAT_00e9accc + 2;
      cVar4 = FUN_004065a0();
      if (cVar4 == '\0') {
        cVar4 = FUN_004065a0();
        uVar5 = cVar4 != '\0';
      }
      else {
        uVar5 = 2;
      }
      iVar12 = DAT_005b3484;
      (&DAT_00e9aacc)[DAT_00e9accc] = uVar5;
      DAT_00e9accc = DAT_00e9accc + 1;
      uVar5 = FUN_0040b270(*(int *)(iVar12 + 0x621e0) + 0x1c54,1);
      (&DAT_00e9aacc)[DAT_00e9accc] = uVar5;
LAB_004b9bb0:
      DAT_00e9accc = DAT_00e9accc + 1;
      FUN_004e6fc0();
      return;
    }
    if (param_2 == 0x112) {
      if (param_3 != 0xf060) {
        return;
      }
      if ((param_1[1] < 0xe11) && (cVar4 = FUN_004065a0(), cVar4 != '\0')) {
        return;
      }
      DAT_005b33ec = 0xf;
      DAT_007934d4 = 1;
      FUN_004122f0();
      return;
    }
    if (param_2 != 0x100) {
      if (param_2 != 0x101) {
        return;
      }
      if (param_3 != 9) {
        if (param_3 != 0x78) {
          return;
        }
        if (*(char *)(DAT_005b3484 + 0xebee5) == '\x01') {
          FUN_00405fb0();
          FUN_00406020(&DAT_00e9be90,0,4,0x3ec,s_b_play_all_0055412c,0xa8,0x219,0x1d,0x10,1,0);
          *(undefined1 *)(DAT_005b3484 + 0xebee5) = 0;
          return;
        }
        FUN_00405fb0();
        FUN_00406020(&DAT_00e9be90,0,5,0x3ed,s_b_play_team_00554114,0xa8,0x219,0x1d,0x10,1,0);
        *(undefined1 *)(DAT_005b3484 + 0xebee5) = 1;
        return;
      }
      cVar4 = FUN_004065a0();
      if (cVar4 == '\0') {
        return;
      }
      cVar4 = FUN_004065a0();
      if (cVar4 == '\x01') {
        *(undefined4 *)(DAT_005b3484 + 0xebef0) = 0xfffffffd;
        FUN_00406500(0);
        FUN_00406500(0);
        FUN_00405fb0();
        FUN_00406020(&DAT_00e9be90,0,2,0x3ea,s_b_play_weapon2_00554154,0x2f,0x232,0x23,0x22,1,0);
        uVar9 = FUN_0040b2d0(*(int *)(DAT_005b3484 + 0x621e0) + 0xc080,4);
        if (((char)uVar9 == '\0') ||
           (uVar9 = *(uint *)(DAT_005b3484 + 0x621e0), *(short *)(uVar9 + 0xbfbc) != 0)) {
          uVar9 = uVar9 & 0xffffff00;
        }
        else {
          uVar9 = CONCAT31((int3)(uVar9 >> 8),1);
        }
        FUN_00406020(&DAT_00e9be90,0,0x12,0x3fa,s_b_play_weapon3_00554144,0x58,0x232,0x23,0x22,uVar9
                     ,0);
        return;
      }
      cVar4 = FUN_004065a0();
      if (cVar4 == '\0') {
        *(undefined4 *)(DAT_005b3484 + 0xebef0) = 0xffffffe8;
        FUN_00406500(1);
        FUN_00405fb0();
        uVar23 = 6;
        pcVar22 = s_b_play_weapon1_00554164;
        uVar21 = 0x3e9;
        uVar20 = 1;
      }
      else {
        cVar4 = FUN_0040b2d0(*(int *)(DAT_005b3484 + 0x621e0) + 0xc080,4);
        if (((cVar4 == '\0') &&
            ((cVar4 = FUN_004065a0(), cVar4 != '\x01' ||
             (*(char *)(DAT_005b3484 + 0x45127) != '\x03')))) ||
           (*(short *)(*(int *)(DAT_005b3484 + 0x621e0) + 0xbfbc) != 0)) {
          *(undefined4 *)(DAT_005b3484 + 0xebef0) = 0xfffffffd;
          FUN_00406500(0);
          FUN_00405fb0();
        }
        else {
          FUN_00406500(1);
          FUN_00405fb0();
          FUN_00406020(&DAT_00e9be90,0,1,0x3e9,s_b_play_weapon1_00554164,6,0x232,0x23,0x22,1,0);
        }
        uVar23 = 0x2f;
        pcVar22 = s_b_play_weapon2_00554154;
        uVar21 = 0x3ea;
        uVar20 = 2;
      }
      FUN_00406020(&DAT_00e9be90,0,uVar20,uVar21,pcVar22,uVar23,0x232,0x23,0x22,1,0);
      FUN_004e6c90(0x4005);
      cVar4 = FUN_004065a0();
      (&DAT_00e9aacc)[DAT_00e9accc] = cVar4 != '\0';
      DAT_00e9accc = DAT_00e9accc + 1;
      uVar5 = FUN_0040b270(*(int *)(DAT_005b3484 + 0x621e0) + 0x1c54,1);
      (&DAT_00e9aacc)[DAT_00e9accc] = uVar5;
      goto LAB_004b9bb0;
    }
    if (param_3 != 0xd) {
      if (param_3 == 0x1b) {
        if ((char)param_1[0x474] != '\0') {
          return;
        }
        if ((&DAT_006a6481)[DAT_005b3484] == '\0') {
          FUN_004f2da0(0,0,0);
          return;
        }
        FUN_00409990(&DAT_006a647c + DAT_005b3484,0);
        return;
      }
      if (param_3 != 0x24) {
        return;
      }
      iVar10 = FUN_0040a4d0(*(int *)(DAT_005b3484 + 0x621e0) + 0xb30);
      iVar11 = FUN_0040a4d0(*(int *)(DAT_005b3484 + 0x621e0) + 0x90c);
      iVar12 = DAT_005b3484;
      cVar4 = FUN_004065a0();
      if (cVar4 != '\0') {
        return;
      }
      if ((&DAT_006a7758)[iVar12] == '\0') {
        return;
      }
      iVar14 = 400;
      if (399 < iVar11) {
        iVar14 = iVar11;
      }
      if (*(int *)(&DAT_006a7720 + iVar12) + -400 < iVar14) {
        iVar11 = *(int *)(&DAT_006a7720 + iVar12) + -400;
      }
      else if (iVar11 < 400) {
        iVar11 = 400;
      }
      iVar14 = -0x14;
      if (-0x15 < iVar10) {
        iVar14 = iVar10;
      }
      iVar15 = *(int *)(&DAT_006a7724 + iVar12) + -0x104;
      if ((iVar14 <= *(int *)(&DAT_006a7724 + iVar12) + -0x104) && (iVar15 = -0x14, -0x15 < iVar10))
      {
        iVar15 = iVar10;
      }
      *(int *)(&DAT_006a7718 + iVar12) = iVar11;
      *(int *)(&DAT_006a771c + iVar12) = iVar15;
      return;
    }
    if (((char)param_1[0x474] != '\0') && (cVar4 = FUN_00406400(), cVar4 == '\x01')) {
      FUN_00406300(extraout_EDX);
      iVar12 = DAT_007934e8;
      *(undefined2 *)(DAT_007934e8 + 0x4d4) = 0x3232;
      *(undefined4 *)(iVar12 + 0x44d0) = 6;
      FUN_004d2680();
      return;
    }
    if (DAT_007933b8 != '\x01') goto LAB_004b9e53;
    cVar4 = FUN_004065a0();
    if (cVar4 == '\0') {
      FUN_0040c880();
      if ((local_80[0] != '\0') && (cVar4 = FUN_004218c0(DAT_005b3484,local_80), cVar4 == '\0')) {
        cVar4 = FUN_00415b00(local_80);
        if (cVar4 == '\x01') {
          uVar20 = 0x202;
        }
        else {
          cVar4 = FUN_00415230();
          if (cVar4 == '\0') {
            FUN_004e6c90((*(char *)(DAT_005b3484 + 0xebee5) != '\0') + 0x4002);
            pcVar22 = local_80;
            do {
              cVar4 = *pcVar22;
              pcVar22 = pcVar22 + 1;
            } while (cVar4 != '\0');
            FUN_004e6db0(local_80);
            FUN_004e6fc0();
            goto LAB_004b9e3e;
          }
          uVar20 = 0x205;
        }
        uVar23 = 6;
        uVar21 = 2;
        iVar12 = *param_1;
        uVar20 = FUN_0043dc70(&DAT_00796eec,uVar20);
        (**(code **)(iVar12 + 0x28))(uVar20,uVar21,uVar23);
      }
    }
    else {
      FUN_00426230();
    }
LAB_004b9e3e:
    SetWindowTextA(*(HWND *)(DAT_007934e4 + 4),&DAT_00551cb1);
LAB_004b9e53:
    FUN_00409990(&DAT_006a647c + DAT_005b3484,1);
    return;
  }
  uVar9 = param_4 & 0xffff;
  if ((char)param_1[4] != '\0') {
    if ((((0x233 < param_4 >> 0x10) && (param_4 >> 0x10 < 0x247)) && (0xf5 < uVar9)) &&
       (uVar9 < 0x285)) {
      *(uint *)(DAT_005b3484 + 0xebee8) = uVar9;
    }
    *(undefined1 *)(param_1 + 4) = 0;
  }
  if ((char)param_1[0x468] != '\x01') goto LAB_004bb56e;
  cVar4 = FUN_004065a0();
  if ((cVar4 != '\0') && (cVar4 = FUN_004065a0(), iVar12 = DAT_005b3484, cVar4 != '\0')) {
    if ((&DAT_005f2f40)[DAT_005b3484] != '\x02') goto LAB_004bb56e;
    *(undefined1 *)(param_1 + 0x468) = 0;
    iVar12 = FUN_0040a4d0(*(int *)(iVar12 + 0x621e0) + 0x7640);
    iVar11 = FUN_0040a4d0(*(int *)(DAT_005b3484 + 0x621e0) + 0x7864);
    if (iVar11 < iVar12 * 10) {
      iVar12 = FUN_0040a4d0(*(int *)(DAT_005b3484 + 0x621e0) + 0x7864);
    }
    else {
      iVar12 = FUN_0040a4d0(*(int *)(DAT_005b3484 + 0x621e0) + 0x7640);
      iVar12 = iVar12 * 10;
    }
    FUN_0040a470(iVar12);
    FUN_0043c860(&DAT_006a7f70 + DAT_005b3484,*(undefined4 *)(DAT_005b3484 + 0x621e0));
    cVar4 = FUN_004065a0();
    if (cVar4 == '\x01') {
      cVar4 = FUN_004065a0();
      if (cVar4 == '\0') {
        uVar20 = 0xc409;
      }
      else {
LAB_004bafd2:
        uVar20 = 0xc400;
      }
    }
    else {
      cVar4 = FUN_0041eaa0(DAT_005b3484,*(undefined2 *)(*(int *)(DAT_005b3484 + 0x621e0) + 0xbfbc));
      if (cVar4 == '\0') goto LAB_004bafd2;
      uVar20 = 0x8403;
    }
    FUN_004e6c90(uVar20);
    uVar7 = FUN_0040a4d0(*(int *)(DAT_005b3484 + 0x621e0) + 0x90c);
    iVar12 = DAT_005b3484;
    *(undefined2 *)(&DAT_00e9aacc + DAT_00e9accc) = uVar7;
    DAT_00e9accc = DAT_00e9accc + 2;
    uVar7 = FUN_0040a4d0(*(int *)(iVar12 + 0x621e0) + 0xb30);
    iVar12 = DAT_005b3484;
    *(undefined2 *)(&DAT_00e9aacc + DAT_00e9accc) = uVar7;
    DAT_00e9accc = DAT_00e9accc + 2;
    uVar5 = FUN_0040b270(*(int *)(iVar12 + 0x621e0) + 0x1c54,1);
    (&DAT_00e9aacc)[DAT_00e9accc] = uVar5;
    DAT_00e9accc = DAT_00e9accc + 1;
    uVar5 = FUN_004065a0();
    iVar12 = DAT_005b3484;
    (&DAT_00e9aacc)[DAT_00e9accc] = uVar5;
    DAT_00e9accc = DAT_00e9accc + 1;
    uVar7 = FUN_0040a4d0(*(int *)(iVar12 + 0x621e0) + 0x4d90);
    iVar12 = DAT_005b3484;
    *(undefined2 *)(&DAT_00e9aacc + DAT_00e9accc) = uVar7;
    DAT_00e9accc = DAT_00e9accc + 2;
    uVar7 = FUN_0040a4d0(*(int *)(iVar12 + 0x621e0) + 0x7864);
    *(undefined2 *)(&DAT_00e9aacc + DAT_00e9accc) = uVar7;
    DAT_00e9accc = DAT_00e9accc + 2;
    cVar4 = FUN_0045ec30();
    iVar12 = DAT_005b3484;
    (&DAT_00e9aacc)[DAT_00e9accc] = cVar4 != '\0';
    DAT_00e9accc = DAT_00e9accc + 1;
    cVar4 = FUN_0040b270(*(int *)(iVar12 + 0x621e0) + 0x1c54,0);
    if (cVar4 == '\0') {
      FUN_0040a4d0(*(int *)(DAT_005b3484 + 0x621e0) + 0x9cf0);
      FUN_0040a4d0(*(int *)(DAT_005b3484 + 0x621e0) + 0x51d8);
    }
    else {
      FUN_0040a4d0(*(int *)(DAT_005b3484 + 0x621e0) + 0x51d8);
      FUN_0040a4d0(*(int *)(DAT_005b3484 + 0x621e0) + 0x9cf0);
    }
    FUN_0040a4d0(*(int *)(DAT_005b3484 + 0x621e0) + 0x9f14);
    FUN_004ead90();
    uVar7 = FUN_0053753c();
    FUN_0040a4d0(*(int *)(DAT_005b3484 + 0x621e0) + 0x9f14);
    FUN_004ead70();
    uVar8 = FUN_0053753c();
    iVar12 = DAT_005b3484;
    *(undefined2 *)(&DAT_00e9aacc + DAT_00e9accc) = uVar7;
    puVar2 = (undefined2 *)(&DAT_00e9aace + DAT_00e9accc);
    DAT_00e9accc = DAT_00e9accc + 2;
    *puVar2 = uVar8;
    DAT_00e9accc = DAT_00e9accc + 2;
    cVar4 = FUN_0040b270(*(int *)(iVar12 + 0x621e0) + 0x1c54,0);
    if (cVar4 == '\0') {
      FUN_0040a4d0(*(int *)(DAT_005b3484 + 0x621e0) + 0xa138);
      FUN_0040a4d0(*(int *)(DAT_005b3484 + 0x621e0) + 0x51d8);
    }
    else {
      FUN_0040a4d0(*(int *)(DAT_005b3484 + 0x621e0) + 0x51d8);
      FUN_0040a4d0(*(int *)(DAT_005b3484 + 0x621e0) + 0xa138);
    }
    FUN_0040a4d0(*(int *)(DAT_005b3484 + 0x621e0) + 0xa35c);
    FUN_004ead90();
    uVar7 = FUN_0053753c();
    FUN_0040a4d0(*(int *)(DAT_005b3484 + 0x621e0) + 0xa35c);
    FUN_004ead70();
    uVar8 = FUN_0053753c();
    iVar12 = DAT_005b3484;
    *(undefined2 *)(&DAT_00e9aacc + DAT_00e9accc) = uVar7;
    puVar2 = (undefined2 *)(&DAT_00e9aace + DAT_00e9accc);
    DAT_00e9accc = DAT_00e9accc + 2;
    *puVar2 = uVar8;
    DAT_00e9accc = DAT_00e9accc + 2;
    cVar4 = FUN_0040b270(*(int *)(iVar12 + 0x621e0) + 0x1c54,0);
    if (cVar4 == '\0') {
      FUN_0040a4d0(*(int *)(DAT_005b3484 + 0x621e0) + 0xa9c8);
      FUN_0040a4d0(*(int *)(DAT_005b3484 + 0x621e0) + 0x51d8);
    }
    else {
      FUN_0040a4d0(*(int *)(DAT_005b3484 + 0x621e0) + 0x51d8);
      FUN_0040a4d0(*(int *)(DAT_005b3484 + 0x621e0) + 0xa9c8);
    }
    FUN_0040a4d0(*(int *)(DAT_005b3484 + 0x621e0) + 0xabec);
    FUN_004ead90();
    uVar7 = FUN_0053753c();
    FUN_0040a4d0(*(int *)(DAT_005b3484 + 0x621e0) + 0xabec);
    FUN_004ead70();
    uVar8 = FUN_0053753c();
    iVar12 = DAT_005b3484;
    *(undefined2 *)(&DAT_00e9aacc + DAT_00e9accc) = uVar7;
    puVar2 = (undefined2 *)(&DAT_00e9aace + DAT_00e9accc);
    DAT_00e9accc = DAT_00e9accc + 2;
    *puVar2 = uVar8;
    DAT_00e9accc = DAT_00e9accc + 2;
    uVar7 = FUN_0040a4d0(iVar12 + 0x5af88);
    iVar12 = DAT_005b3484;
    *(undefined2 *)(&DAT_00e9aacc + DAT_00e9accc) = uVar7;
    DAT_00e9accc = DAT_00e9accc + 2;
    uVar7 = FUN_0040a4d0(iVar12 + 0x5b1ac);
    *(undefined2 *)(&DAT_00e9aacc + DAT_00e9accc) = uVar7;
    puVar3 = &DAT_00e9aace + DAT_00e9accc;
    DAT_00e9accc = DAT_00e9accc + 2;
    *puVar3 = 0;
    DAT_00e9accc = DAT_00e9accc + 1;
    FUN_0043d6d0();
    FUN_004e6fc0();
    FUN_0040a4d0(*(int *)(DAT_005b3484 + 0x621e0) + 0x7864);
    FUN_004ee200();
    FUN_00406500(0);
    FUN_00406500(0);
    FUN_0040a470(0xffffffff);
    FUN_0040a470(0xffffffff);
    *(undefined1 *)(*(int *)(DAT_005b3484 + 0x621e0) + 0xbfe8) = 0;
    FUN_00461c60(s_normal_00552230);
  }
  iVar12 = DAT_005b3484;
LAB_004bb56e:
  _DAT_00e9b80c = 10;
  (&DAT_006a7758)[iVar12] = 1;
  if (DAT_00e53c3c == '\x01') {
    return;
  }
  DAT_00e53c3c = 1;
  return;
}
