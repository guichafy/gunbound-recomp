// Research database only: undo an exploratory interior-function seed.
import ghidra.app.script.GhidraScript;
import ghidra.program.model.listing.Function;
public class RepairJewelEntry extends GhidraScript {
 public void run() throws Exception {
  for (String s : new String[]{"004bc02d", "004bb730"}) {
   Function f = getFunctionAt(toAddr(s));
   if (f != null) removeFunction(f);
  }
  disassemble(toAddr("004bb730"));
  createFunction(toAddr("004bb730"), "JewelBattleSetupResearch");
  analyzeChanges(currentProgram);
  println("JEWEL_REPAIR entry=" + getFunctionContaining(toAddr("004bc02d")).getEntryPoint());
 }
}
