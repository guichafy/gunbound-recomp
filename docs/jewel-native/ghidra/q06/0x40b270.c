
bool FUN_0040b270(undefined4 param_1,int param_2)

{
  int iVar1;

  EnterCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  iVar1 = FUN_0040a2e0();
  LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_005a9068);
  return iVar1 == param_2;
}
