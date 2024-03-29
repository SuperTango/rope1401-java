package rope1401;

import java.io.*;
import java.util.Iterator;

class Simulator
{
    private static BufferedWriter stdin;
    private static BufferedReader stdout;
    private static BufferedReader stderr;
    private static Process process;
    private static boolean isActive;

    private static long wallStartTime;
    private static long simulatorStartTime;
    private static long simulatorElapsedTime;

    private static boolean timersReset = true;

    static BufferedReader getStderr()
    {
        return stderr;
    }

    static void start()
    {
        try {
            cleanup();
            String command = RopeConfig.getConfig().getConfigValue ( "simulator.binary.path" );
            process = Runtime.getRuntime().exec ( command );
            isActive = true;

            stdin = new BufferedWriter(new OutputStreamWriter(process.getOutputStream()));
            stdout = new BufferedReader(new InputStreamReader(process.getInputStream()));
            stderr = new BufferedReader(new InputStreamReader(process.getErrorStream()));

            setupFiles();
            resetTimers();
            simulatorStartTime = System.currentTimeMillis();
        }
        catch(Exception ex) {
            ex.printStackTrace();
        }
    }

    private static void setupFiles()
    {
        // Clear printout file.
        try {
            new BufferedWriter(new FileWriter(DataOptions.outputPath));
        }
        catch(Exception ex) {
            ex.printStackTrace();
        }

        synchronized(Simulator.class) {
            execute("at cdr " + DataOptions.inputPath);
            execute("at lpt " + DataOptions.outputPath);

            Iterator i = DataOptions.getUnitCommandsIterator();
            while ( i.hasNext() ) {
                execute ( (String)i.next() );
            }
        }
    }

    static void stop()
    {
        execute("q");
        isActive = false;
    }

    static void execute(String command)
    {
        if (isActive) {
            try {
                if (timersReset) {
                    wallStartTime = System.currentTimeMillis();
                    timersReset = false;
                }

                simulatorStartTime = System.currentTimeMillis();

                stdin.write(command + "\n");
                stdin.flush();
                Thread.yield();

                if ( RopeConfig.getConfig ().isDebug() ) {
                    System.out.println("sim> " + command);
                }
            }
            catch (Exception ex) {
                kill();
            }
        }
    }

    static boolean hasOutput()
    {
        try {
            return stdout.ready();
        }
        catch (Exception ex) {
            ex.printStackTrace();
            return false;
        }
    }

    static boolean hasOutput(int waitTime)
    {
        try {
            Thread.sleep(waitTime);
            return stdout.ready();
        }
        catch (Exception ex) {
            ex.printStackTrace();
            return false;
        }
    }

    static String output()
    {
        try {
            String output = stdout.readLine();
            simulatorElapsedTime += System.currentTimeMillis() - simulatorStartTime;
            simulatorStartTime = System.currentTimeMillis();
            return output;
        }
        catch (Exception ex) {
            ex.printStackTrace();
            return null;
        }
    }

    static void resetTimers()
    {
        wallStartTime = System.currentTimeMillis();
        simulatorStartTime = 0;
        simulatorElapsedTime = 0;

        timersReset = true;
    }

    static long elapsedWallTime()
    {
        return System.currentTimeMillis() - wallStartTime;
    }

    static long elapsedSimulatorTime()
    {
        return simulatorElapsedTime;
    }

    static void kill()
    {
        isActive = false;

        if (process != null){
            process.destroy();
        }
    }

    private static void cleanup()
    {
        try {
            if (isActive) {
                stop();
                kill();
            }

            stdin.close();
            stdout.close();
            stderr.close();
        }
        catch (Exception ignore) {}
    }

    protected void finalize()
    {
        cleanup();
    }

/*
    public static void main(String[] args)
    {
        String line;

        start("C:\\IBM1401\\programs\\Pi\\test.cd",
              "C:\\IBM1401\\programs\\Pi\\test.out");
    }
*/
}
