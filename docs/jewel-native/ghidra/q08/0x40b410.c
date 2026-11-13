
bool FUN_0040b410(void)

{
  int iVar1;
  int iVar2;

  EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  iVar1 = FUN_0040a2e0();
  iVar2 = FUN_0040a2e0();
  LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  return iVar2 < iVar1;
}
