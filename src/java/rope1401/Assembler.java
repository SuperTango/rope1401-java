package rope1401;

import java.io.*;

/**
 * <p>Title: </p>
 * <p>Description: </p>
 * <p>Copyright: Copyright (c) 2005</p>
 * <p>Company: NASA Ames Research Center</p>
 * @author Ronald Mak
 * @version 2.0
 */

class Assembler
{
//    private static String sourceName;
//    private static String sourcePath;
    private static BufferedReader stdout;

    static void setPaths(String sourceName, String sourcePath)
    {
//        Assembler.sourceName = sourceName;
//        Assembler.sourcePath = sourcePath;
    }

    static void version()
    {
        String command = "./autocoder -V";

        try {
            Process process = Runtime.getRuntime().exec(command);
            stdout = new BufferedReader(new InputStreamReader(process.getInputStream()));
        }
        catch(Exception ex) {
            ex.printStackTrace();
        }
    }

    static void assemble()
    {
        try {
            Process process = Runtime.getRuntime().exec(AssemblerOptions.command);
            stdout = new BufferedReader(new InputStreamReader(process.getInputStream()));
        }
        catch(Exception ex) {
            ex.printStackTrace();
        }
    }

    static String output()
    {
        try {
            String line = stdout.readLine();

            if (line == null) {
                stdout.close();
            }

            return line;
        }
        catch (Exception ex) {
            ex.printStackTrace();
            return null;
        }
    }
}
