
char FUN_004065a0(void)

{
  byte bVar1;
  byte bVar2;
  byte *in_EAX;

  EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  bVar1 = *in_EAX;
  bVar2 = in_EAX[1];
  if ((byte)((bVar1 + bVar2) - 0x34) == in_EAX[2]) {
    LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
    return '\x01' - ((bVar2 >> (bVar1 & 7) & 1) != 1);
  }
  DAT_00793514 = 1;
  LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  return '\0';
}
