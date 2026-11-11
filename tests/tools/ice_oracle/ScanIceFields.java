// @category Gunbound.Port
import ghidra.app.script.GhidraScript;
import ghidra.program.model.listing.*;
import ghidra.program.model.scalar.Scalar;
import java.nio.file.*;
import java.util.*;

/** Enumerate explicit offsets; indirect stride loops still require manual review. */
public class ScanIceFields extends GhidraScript {
    public void run() throws Exception {
        Set<Long> offsets = Set.of(0xb728L, 0xb94cL, 0xbb70L, 0xbd94L, 0xe55ab8L);
        List<String> lines = new ArrayList<>();
        lines.add("instruction\tfunction\tasm");
        for (Instruction ins : currentProgram.getListing().getInstructions(true)) {
            boolean found = false;
            for (int op = 0; op < ins.getNumOperands(); op++) {
                for (Object obj : ins.getOpObjects(op)) {
                    if (obj instanceof Scalar && offsets.contains(((Scalar)obj).getUnsignedValue())) found = true;
                }
            }
            if (found) {
                Function fn = getFunctionContaining(ins.getAddress());
                lines.add(ins.getAddress() + "\t" + (fn == null ? "?" : fn.getEntryPoint()) + "\t" + ins);
            }
        }
        Files.write(Path.of(getScriptArgs()[0]), lines);
        println("ICE_FIELD_SCAN " + (lines.size() - 1));
    }
}
