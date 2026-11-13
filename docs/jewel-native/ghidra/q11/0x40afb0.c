
void FUN_0040afb0(void)

{
  int iVar1;
  int iVar2;

  EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  iVar1 = FUN_0040a2e0();
  iVar2 = FUN_0040a2e0();
  FUN_0040a380(iVar2 + iVar1);
  LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  return;
}
