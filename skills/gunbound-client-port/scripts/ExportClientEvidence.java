// Export static analysis only. Explicit seeding modifies the analysis DB, never the PE.
// @category Gunbound.Port
import ghidra.app.script.GhidraScript;
import ghidra.app.decompiler.*;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.*;
import ghidra.program.model.symbol.*;
import com.google.gson.*;
import java.nio.file.*;
import java.nio.charset.StandardCharsets;
import java.util.*;

public class ExportClientEvidence extends GhidraScript {
    private Path output;
    private final Set<String> seeded = new HashSet<>();
    private String hex(byte[] bytes) {
        StringBuilder text = new StringBuilder();
        for (byte value : bytes) text.append(String.format("%02x", value & 255));
        return text.toString();
    }
    private void write(String name, String text) throws Exception {
        Files.writeString(output.resolve(name), text, StandardCharsets.UTF_8);
    }
    private String refsTo(Address address) {
        StringBuilder text = new StringBuilder("from\tto\ttype\n");
        for (Reference ref : getReferencesTo(address))
            text.append(ref.getFromAddress()).append("\t").append(ref.getToAddress()).append("\t").append(ref.getReferenceType()).append("\n");
        return text.toString();
    }
    public void run() throws Exception {
        String[] args = getScriptArgs();
        output = Paths.get(args[0]);
        Files.createDirectories(output);
        String[] functions = args[2].equals("-") ? new String[0] : args[2].split(",");
        if (args[1].equals("seed")) {
            for (String selector : functions) {
                Address address = toAddr(selector);
                if (getFunctionContaining(address) == null && currentProgram.getMemory().contains(address)) {
                    disassemble(address);
                    if (createFunction(address, null) != null) seeded.add(selector);
                }
            }
            analyzeChanges(currentProgram);
        }
        JsonObject manifest = new JsonObject();
        manifest.addProperty("source_sha256", currentProgram.getExecutableSHA256());
        manifest.addProperty("program", currentProgram.getName());
        manifest.addProperty("language", currentProgram.getLanguageID().toString());
        manifest.addProperty("compiler", currentProgram.getCompilerSpec().getCompilerSpecID().toString());
        manifest.addProperty("image_base", currentProgram.getImageBase().toString());
        manifest.addProperty("address_kind", "VA in the imported program");
        JsonArray entries = new JsonArray();
        boolean ok = true;
        DecompInterface decompiler = new DecompInterface();
        try {
            if (!decompiler.openProgram(currentProgram)) throw new Exception(decompiler.getLastMessage());
            for (String selector : functions) {
                JsonObject item = new JsonObject();
                entries.add(item);
                item.addProperty("requested_va", selector);
                item.addProperty("seeded", seeded.contains(selector));
                Address address = toAddr(selector);
                write(selector + ".requested-refs.tsv", refsTo(address));
                Function function = getFunctionContaining(address);
                if (function == null) { item.addProperty("status", "function_not_found"); ok = false; continue; }
                item.addProperty("entry_va", function.getEntryPoint().toString());
                item.addProperty("name", function.getName());
                item.addProperty("body", function.getBody().toString());
                write(selector + ".entry-refs.tsv", refsTo(function.getEntryPoint()));
                StringBuilder assembly = new StringBuilder();
                StringBuilder outgoing = new StringBuilder("from\tto\ttype\n");
                int count = 0;
                InstructionIterator instructions = currentProgram.getListing().getInstructions(function.getBody(), true);
                while (instructions.hasNext()) {
                    Instruction ins = instructions.next();
                    assembly.append(ins.getAddress()).append("  ").append(hex(ins.getBytes())).append("  ").append(ins).append("\n");
                    for (Reference ref : ins.getReferencesFrom()) outgoing.append(ref.getFromAddress()).append("\t").append(ref.getToAddress()).append("\t").append(ref.getReferenceType()).append("\n");
                    count++;
                }
                write(selector + ".asm", assembly.toString());
                write(selector + ".outgoing-refs.tsv", outgoing.toString());
                DecompileResults result = decompiler.decompileFunction(function, 45, monitor);
                boolean complete = result.decompileCompleted() && result.getDecompiledFunction() != null;
                item.addProperty("instructions", count);
                item.addProperty("status", complete ? "decompiled" : "decompile_failed");
                item.addProperty("diagnostic", result.getErrorMessage());
                write(selector + ".c", complete ? result.getDecompiledFunction().getC() : result.getErrorMessage());
                ok &= complete;
            }
        } finally { decompiler.dispose(); }
        JsonArray ranges = new JsonArray();
        if (!args[3].equals("-")) for (String selector : args[3].split(",")) {
            String[] fields = selector.split(":");
            Address address = toAddr(fields[0]);
            JsonObject item = new JsonObject(); ranges.add(item);
            item.addProperty("requested", selector);
            try {
                byte[] bytes = getBytes(address, Integer.parseInt(fields[1]));
                item.addProperty("hex", hex(bytes));
                item.addProperty("status", "read");
                write(fields[0] + "-" + fields[1] + ".data-refs.tsv", refsTo(address));
            } catch (Exception error) { item.addProperty("status", "read_failed"); item.addProperty("diagnostic", error.toString()); ok = false; }
        }
        manifest.add("functions", entries);
        manifest.add("data", ranges);
        manifest.addProperty("ok", ok);
        write("manifest.json", new GsonBuilder().setPrettyPrinting().create().toJson(manifest) + "\n");
        println("CLIENT_EVIDENCE ok=" + ok + " output=" + output);
    }
}
