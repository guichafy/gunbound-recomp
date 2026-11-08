
void FUN_0044c5a0(void)

{
  int in_EAX;
  int iVar1;
  int unaff_EBX;
  int *unaff_EDI;
  
  if ((uint)unaff_EDI[1] < (uint)(in_EAX + unaff_EBX)) {
                    /* WARNING: Subroutine does not return */
    FUN_004010c0(0x80070057);
  }
  iVar1 = (unaff_EDI[1] - in_EAX) - unaff_EBX;
  if (iVar1 != 0) {
    _memmove((void *)(in_EAX * 0x9c + *unaff_EDI),(void *)((in_EAX + unaff_EBX) * 0x9c + *unaff_EDI)
             ,iVar1 * 0x9c);
  }
  unaff_EDI[1] = unaff_EDI[1] - unaff_EBX;
  return;
}

