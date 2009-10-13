package rope1401;

import java.util.*;
import java.awt.*;
import java.awt.event.*;
import javax.swing.*;

/**
 * <p>Title: </p>
 * <p>Description: </p>
 * <p>Copyright: Copyright (c) 2005</p>
 * <p>Company: NASA Ames Research Center</p>
 * @author Ronald Mak
 * @version 2.0
 */

public class RopeFrame extends JFrame
{
    private static final String TITLE =
        "ROPE/1401 by Ronald Mak (Version 0.8 Beta)";

    private JDesktopPane desktop = new JDesktopPane();
    private EditFrame editFrame;
    private ExecFrame execFrame;
    private PrintoutFrame printoutFrame;
    private ConsoleFrame consoleFrame;
    private TimerFrame timerFrame;

    private Vector commandWindows = new Vector();

    private boolean packFrame = false;

    public RopeFrame(boolean dummy)
    {
        // Validate frames that have preset sizes
        // Pack frames that have useful preferred size info, e.g. from their layout
        if (packFrame) {
            this.pack();
        }
        else {
            this.validate();
        }


        try {
            UIManager.setLookAndFeel(UIManager.getSystemLookAndFeelClassName());
        }
        catch (Exception ex) {
            ex.printStackTrace();
        }


        Dimension screenSize = Toolkit.getDefaultToolkit().getScreenSize();
        Dimension frameSize = new Dimension(screenSize.width - 25,
                                            screenSize.height - 50);
        this.setSize(frameSize);
        this.setLocation((screenSize.width - frameSize.width) / 2, 10);

        this.setTitle(TITLE);
        this.setVisible(true);

        JPanel contentPanel = (JPanel) this.getContentPane();
        contentPanel.add(desktop);
        desktop.setBackground(new Color(215, 215, 255));

        editFrame = new EditFrame(this);
        editFrame.setLocation(0, 0);
        desktop.add(editFrame);
        editFrame.setVisible(true);

        execFrame = new ExecFrame(this);
        Dimension ropeSize = this.getContentPane().getSize();
        Dimension execSize = execFrame.getSize();

        execFrame.setLocation((int) (ropeSize.getWidth() - execSize.getWidth()),
                              0);
        desktop.add(execFrame);
        execFrame.setVisible(false);

        printoutFrame = new PrintoutFrame(this);
        Dimension printoutSize = printoutFrame.getSize();

        printoutFrame.setLocation(0, (int) (ropeSize.getHeight() -
                                            printoutSize.getHeight()));
        desktop.add(printoutFrame);
        printoutFrame.setVisible(false);
//        execFrame.setVisible ( true );
    }

    void showExecWindow(String baseName)
    {
        desktop.getDesktopManager().deiconifyFrame(execFrame);
        execFrame.setTitle("EXEC: " + baseName);
        execFrame.setVisible(true);
        execFrame.initialize(baseName, DataOptions.outputPath);

        if (haveAssemblyErrors()) {
            try {
                editFrame.setSelected(true);
            }
            catch(Exception ignore) {}
        }
    }

    void resetExecWindow()
    {
        execFrame.reset();
    }

    void showPrintoutWindow(String baseName)
    {
        desktop.getDesktopManager().deiconifyFrame(printoutFrame);
        printoutFrame.setTitle("PRINTOUT: " + baseName);
        printoutFrame.setVisible(true);
        printoutFrame.initialize();
        printoutFrame.toBack();

        commandWindows.addElement(printoutFrame);

        try {
            execFrame.setSelected(true);
        }
        catch(Exception ignore) {}
    }

    void createMemoryFrame()
    {
        MemoryFrame memoryFrame = new MemoryFrame(this);
        Dimension ropeSize = this.getContentPane().getSize();
        Dimension memorySize = memoryFrame.getSize();

        memoryFrame.setLocation(((int) (ropeSize.getWidth()
                                        - memorySize.getWidth())) / 2,
                                ((int) (ropeSize.getHeight()
                                        - memorySize.getHeight())) / 2);
        desktop.add(memoryFrame);
        memoryFrame.setVisible(true);

        commandWindows.addElement(memoryFrame);
    }

    void createConsoleFrame()
    {
        if (consoleFrame == null) {
            consoleFrame = new ConsoleFrame(this);
            Dimension ropeSize = this.getContentPane().getSize();
            Dimension consoleSize = consoleFrame.getSize();

            consoleFrame.setLocation(((int) (ropeSize.getWidth()
                                             - consoleSize.getWidth())),
                                     ((int) (ropeSize.getHeight()
                                             - consoleSize.getHeight())));
            desktop.add(consoleFrame);
            consoleFrame.setVisible(true);

            commandWindows.addElement(consoleFrame);
        }
        else {
            desktop.getDesktopManager().deiconifyFrame(consoleFrame);
            desktop.getDesktopManager().activateFrame(consoleFrame);
        }
    }

    void consoleFrameClosed()
    {
        consoleFrame = null;
    }

    void createTimerFrame()
    {
        if (timerFrame == null) {
            timerFrame = new TimerFrame(this);
            Dimension ropeSize = this.getContentPane().getSize();
            Dimension frameSize = timerFrame.getSize();

            timerFrame.setLocation(((int) (ropeSize.getWidth()
                                             - frameSize.getWidth() - 100)),
                                     ((int) (ropeSize.getHeight()
                                             - frameSize.getHeight())) - 100);

            desktop.add(timerFrame);
            timerFrame.setVisible(true);

            commandWindows.addElement(timerFrame);
        }
        else {
            desktop.getDesktopManager().deiconifyFrame(timerFrame);
            desktop.getDesktopManager().activateFrame(timerFrame);
        }
    }

    void timerFrameClosed()
    {
        timerFrame = null;
    }

    void resetTimers()
    {
        Simulator.resetTimers();
    }

    void removeCommandWindow(CommandWindow window)
    {
        commandWindows.remove(window);
    }

    void updateCommandWindows()
    {
        Enumeration elements = commandWindows.elements();
        while (elements.hasMoreElements()) {
            CommandWindow window = (CommandWindow) elements.nextElement();
            window.execute();
        }
    }

    void lockCommandWindows()
    {
        Enumeration elements = commandWindows.elements();
        while (elements.hasMoreElements()) {
            CommandWindow window = (CommandWindow) elements.nextElement();
            window.lock();
        }
    }

    void unlockCommandWindows()
    {
        Enumeration elements = commandWindows.elements();
        while (elements.hasMoreElements()) {
            CommandWindow window = (CommandWindow) elements.nextElement();
            window.unlock();
        }
    }

    void writeMessage(Color color, String message)
    {
//        execFrame.writeMessage(color, message);
    }

    private boolean senseSwitchesEnabled = false;

    void enableSenseSwitches()
    {
        if (consoleFrame != null) {
            consoleFrame.enableSenseSwitches();
        }

        senseSwitchesEnabled = true;
    }

    void disableSenseSwitches()
    {
        if (consoleFrame != null) {
            consoleFrame.disableSenseSwitches();
        }

        senseSwitchesEnabled = false;
    }

    boolean senseSwitchesEnabled()
    {
        return senseSwitchesEnabled;
    }

    boolean haveAssemblyErrors()
    {
        return editFrame.haveAssemblyErrors();
    }

    protected void processWindowEvent(WindowEvent event)
    {
        super.processWindowEvent(event);

        if (event.getID() == WindowEvent.WINDOW_CLOSING) {
            Simulator.kill();
            System.exit(0);
        }
    }
}
