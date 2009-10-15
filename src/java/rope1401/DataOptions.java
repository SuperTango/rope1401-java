package rope1401;

import java.util.*;

class DataOptions
{
    static String directoryPath = System.getProperty("user.dir");
    static ArrayList unitCommands;

    static String inputPath;
    static String outputPath;

    static String readerPath;
    static String punchPath;
    static String tape1Path;
    static String tape2Path;
    static String tape3Path;
    static String tape4Path;
    static String tape5Path;
    static String tape6Path;
        
    static void addUnitCommand ( String command ) {
        if ( unitCommands == null ) {
            unitCommands = new ArrayList();
        }
        unitCommands.add ( command );
    }
    
    static void resetUnitCommands() {
        unitCommands = new ArrayList();
    }

    static Iterator getUnitCommandsIterator () {
        if ( unitCommands == null ) { 
            unitCommands = new ArrayList();
        }
        return unitCommands.iterator();
    }
}
