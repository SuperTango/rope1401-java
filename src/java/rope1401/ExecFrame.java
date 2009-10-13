package rope1401;

import java.io.*;
import java.util.*;
import java.awt.*;
import java.awt.event.*;
import javax.swing.*;
import javax.swing.border.*;
import javax.swing.event.*;
import java.awt.BorderLayout;

/**
 * <p>Title: </p>
 * <p>Description: </p>
 * <p>Copyright: Copyright (c) 2005</p>
 * <p>Company: NASA Ames Research Center</p>
 * @author Ronald Mak
 * @version 2.0
 */

public class ExecFrame
    extends JInternalFrame
    implements ActionListener, ChangeListener
{
    BorderLayout borderLayout1 = new BorderLayout();
    BorderLayout borderLayout2 = new BorderLayout();
    TitledBorder titledBorder1;
    GridBagLayout gridBagLayout1 = new GridBagLayout();
    GridBagLayout gridBagLayout2 = new GridBagLayout();
    JScrollPane listingScrollPane = new JScrollPane();
    JList listing = new JList();
    JPanel controlPanel = new JPanel();
    JPanel messagePanel = new JPanel();
    JTextArea messageArea = new JTextArea();
    JPanel buttonPanel = new JPanel();
    JPanel filler1Panel = new JPanel();
    JPanel filler2Panel = new JPanel();
    JCheckBox showAllCheckBox = new JCheckBox();
    JButton simulatorButton = new JButton();
    JButton optionsButton = new JButton();
    JButton dataButton = new JButton();
    JButton startButton = new JButton();
    JButton quitButton = new JButton();
    JButton singleStepButton = new JButton();
    JButton autoStepButton = new JButton();
    JButton fasterButton = new JButton();
    JButton slowerButton = new JButton();
    JButton showMemoryButton = new JButton();
    JButton showConsoleButton = new JButton();
    JButton showTimerButton = new JButton();

    private RopeFrame parent;
    private DataDialog dialog = null;
    private Hashtable lineTable;

    private static int INIT_AUTO_STEP_WAIT_TIME = 200;

    private Thread autoStepper;
    private int autoStepWaitTime;

    private boolean simulatorRunning = false;
    private boolean programRunning = false;
    private boolean settingBreakpoint = false;
    private boolean autoStepping = false;

    private String baseName;
    private String currentMessage = null;

    public ExecFrame()
    {
        try {
            jbInit();
        }
        catch (Exception ex) {
            ex.printStackTrace();
        }

        this.setSize(890, 650);

        simulatorButton.addActionListener(this);
        optionsButton.addActionListener(this);
        dataButton.addActionListener(this);
        showAllCheckBox.addChangeListener(this);
        startButton.addActionListener(this);
        quitButton.addActionListener(this);
        singleStepButton.addActionListener(this);
        autoStepButton.addActionListener(this);
        slowerButton.addActionListener(this);
        fasterButton.addActionListener(this);
        showMemoryButton.addActionListener(this);
        showConsoleButton.addActionListener(this);
        showTimerButton.addActionListener(this);

        listing.setCellRenderer(new ListingLineRenderer());

        listing.addMouseListener(new MouseAdapter()
        {
            public void mouseClicked(MouseEvent event)
            {
                if (simulatorRunning) {
                    settingBreakpoint = true;
                    flipBreakpoint(listing.locationToIndex(event.getPoint()));
                    settingBreakpoint = false;
                }

                listing.clearSelection();
            }
        });

        listing.addMouseMotionListener(new MouseMotionAdapter()
        {
            public void mouseDragged(MouseEvent event)
            {
                listing.clearSelection();
            }
        });

    }

    ExecFrame(RopeFrame parent)
    {
        this();
        this.parent = parent;
    }

    void jbInit()
        throws Exception
    {
        titledBorder1 = new TitledBorder(BorderFactory.createLineBorder(
            new Color(153, 153, 153), 2), "Simulator messages");
        this.getContentPane().setLayout(borderLayout1);
        this.setIconifiable(true);
        this.setMaximizable(true);
        this.setResizable(true);
        this.setTitle("EXEC");
        listing.setFont(new java.awt.Font("Courier", 0, 12));
        listing.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);
        controlPanel.setLayout(gridBagLayout1);
        messagePanel.setLayout(borderLayout2);
        messagePanel.setBorder(titledBorder1);
        messagePanel.setMinimumSize(new Dimension(12, 50));
        messagePanel.setPreferredSize(new Dimension(12, 50));
        messageArea.setBackground(new Color(205, 205, 205));
        messageArea.setFont(new java.awt.Font("Dialog", 1, 12));
        messageArea.setForeground(Color.blue);
        messageArea.setText("");
        buttonPanel.setLayout(gridBagLayout2);
        buttonPanel.setBorder(BorderFactory.createLoweredBevelBorder());
        filler1Panel.setLayout(null);
        filler2Panel.setLayout(null);
        simulatorButton.setEnabled(true);
        simulatorButton.setText("Kill simulator");
        optionsButton.setEnabled(false);
        optionsButton.setText("Simulator options ...");
        dataButton.setEnabled(true);
        dataButton.setText("Runtime data ...");
        showAllCheckBox.setEnabled(true);
        showAllCheckBox.setText("Show all");
        startButton.setEnabled(false);
        startButton.setText("Start program");
        quitButton.setEnabled(false);
        quitButton.setText("Quit program");
        singleStepButton.setEnabled(false);
        singleStepButton.setText("Single step");
        autoStepButton.setEnabled(false);
        autoStepButton.setText("Auto step");
        fasterButton.setEnabled(false);
        fasterButton.setText("Faster");
        slowerButton.setEnabled(false);
        slowerButton.setText("Slower");
        showMemoryButton.setEnabled(false);
        showMemoryButton.setText("Memory ...");
        showConsoleButton.setEnabled(false);
        showConsoleButton.setText("Console ...");
        showTimerButton.setText("Timers ...");
        listingScrollPane.getViewport().add(listing, null);
        controlPanel.add(messagePanel,
                         new GridBagConstraints(0, 0, 4, 1, 1.0, 0.0,
                                                GridBagConstraints.CENTER,
                                                GridBagConstraints.HORIZONTAL,
                                                new Insets(5, 5, 0, 5), 0, 0));
        messagePanel.add(messageArea, BorderLayout.CENTER);
        controlPanel.add(buttonPanel,
                         new GridBagConstraints(0, 1, 1, 1, 1.0, 0.0,
                                                GridBagConstraints.CENTER,
                                                GridBagConstraints.HORIZONTAL,
                                                new Insets(5, 5, 5, 5), 0, 0));
        buttonPanel.add(simulatorButton,
                        new GridBagConstraints(0, 0, 1, 1, 0.0, 0.0,
                                               GridBagConstraints.CENTER,
                                               GridBagConstraints.HORIZONTAL,
                                               new Insets(5, 5, 0, 0), 0, 0));
        buttonPanel.add(optionsButton,
                        new GridBagConstraints(0, 1, 1, 1, 0.0, 0.0,
                                               GridBagConstraints.CENTER,
                                               GridBagConstraints.HORIZONTAL,
                                               new Insets(5, 5, 5, 0), 0, 0));
        buttonPanel.add(dataButton,
                        new GridBagConstraints(1, 0, 1, 1, 0.0, 0.0,
                                               GridBagConstraints.CENTER,
                                               GridBagConstraints.HORIZONTAL,
                                               new Insets(5, 20, 0, 15), 0, 0));
        buttonPanel.add(showAllCheckBox,
                        new GridBagConstraints(1, 1, 1, 1, 0.0, 0.0,
                                               GridBagConstraints.CENTER,
                                               GridBagConstraints.NONE,
                                               new Insets(5, 5, 5, 0), 0, 0));
        buttonPanel.add(startButton,
                        new GridBagConstraints(2, 0, 1, 1, 0.0, 0.0,
                                               GridBagConstraints.CENTER,
                                               GridBagConstraints.HORIZONTAL,
                                               new Insets(5, 5, 0, 0), 0, 0));
        buttonPanel.add(quitButton,
                        new GridBagConstraints(2, 1, 1, 1, 0.0, 0.0,
                                               GridBagConstraints.CENTER,
                                               GridBagConstraints.HORIZONTAL,
                                               new Insets(5, 5, 5, 0), 0, 0));
        buttonPanel.add(singleStepButton,
                        new GridBagConstraints(3, 0, 1, 1, 0.0, 0.0,
                                               GridBagConstraints.CENTER,
                                               GridBagConstraints.HORIZONTAL,
                                               new Insets(5, 5, 0, 0), 0, 0));
        buttonPanel.add(autoStepButton,
                        new GridBagConstraints(3, 1, 1, 1, 0.0, 0.0,
                                               GridBagConstraints.CENTER,
                                               GridBagConstraints.HORIZONTAL,
                                               new Insets(5, 5, 5, 0), 0, 0));
        buttonPanel.add(fasterButton,
                        new GridBagConstraints(4, 1, 1, 1, 0.0, 0.0,
                                               GridBagConstraints.CENTER,
                                               GridBagConstraints.HORIZONTAL,
                                               new Insets(5, 5, 5, 0), 0, 0));
        buttonPanel.add(slowerButton,
                        new GridBagConstraints(4, 0, 1, 1, 0.0, 0.0,
                                               GridBagConstraints.CENTER,
                                               GridBagConstraints.HORIZONTAL,
                                               new Insets(5, 5, 0, 0), 0, 0));
        buttonPanel.add(showTimerButton,
                        new GridBagConstraints(5, 1, 1, 1, 0.0, 0.0,
                                               GridBagConstraints.CENTER,
                                               GridBagConstraints.HORIZONTAL,
                                               new Insets(5, 5, 5, 5), 0, 0));
        buttonPanel.add(showMemoryButton,
                        new GridBagConstraints(6, 0, 1, 1, 0.0, 0.0,
                                               GridBagConstraints.SOUTH,
                                               GridBagConstraints.HORIZONTAL,
                                               new Insets(5, 0, 0, 5), 0, 0));
        buttonPanel.add(showConsoleButton,
                        new GridBagConstraints(6, 1, 1, 1, 0.0, 0.0,
                                               GridBagConstraints.CENTER,
                                               GridBagConstraints.HORIZONTAL,
                                               new Insets(5, 0, 5, 5), 0, 0));

        this.getContentPane().add(listingScrollPane, BorderLayout.CENTER);
        this.getContentPane().add(controlPanel, BorderLayout.SOUTH);
        buttonPanel.add(filler2Panel,
                        new GridBagConstraints(5, 0, 1, 1, 0.0, 0.0
                                               , GridBagConstraints.CENTER,
                                               GridBagConstraints.BOTH,
                                               new Insets(0, 0, 0, 0), 0, 0));
    }

    public static final Color DARK_RED = new Color(150, 0, 0);

    void initialize(String baseName, String outPath)
    {
        this.baseName = baseName;

        programRunning = false;
        startButton.setText("Start program");

        simulatorButton.setEnabled(false);
        optionsButton.setEnabled(false);
        dataButton.setEnabled(true);
        startButton.setEnabled(false);
        quitButton.setEnabled(false);
        singleStepButton.setEnabled(false);
        autoStepButton.setEnabled(false);
        slowerButton.setEnabled(false);
        fasterButton.setEnabled(false);
        showMemoryButton.setEnabled(false);
        showConsoleButton.setEnabled(false);
        showTimerButton.setEnabled(false);

        autoStepWaitTime = INIT_AUTO_STEP_WAIT_TIME;
        currentMessage = null;

        loadListing();

        if (parent.haveAssemblyErrors()) {
            writeMessage(DARK_RED,
                         "*** Correct assembly errors before continuing.");
            parent.lockCommandWindows();
        }
        else if ((AssemblerOptions.listingPath == null) ||
                 (outPath == null)) {
            writeMessage(DARK_RED,
                         "*** Missing or empty listing or object deck files.");
            parent.lockCommandWindows();
        }
        else {
            clearMessage();

            if (simulatorRunning) {
                killSimulator();
            }

            startSimulator();
        }
    }

    void reset()
    {
        if (simulatorRunning) {
            killSimulator();
        }
    }

    void writeMessage(Color color, String message)
    {
        messageArea.setForeground(color);
        messageArea.setText(message);
    }

    void clearMessage()
    {
        messageArea.setText(null);
    }

    private void loadListing()
    {
        Vector v = filterListing();

        if (v != null) {
            listing.clearSelection();
            listing.setListData(v);

            if (currentMessage == null) {
                listing.ensureIndexIsVisible(0);
            }
            else {
                selectCurrentLine(currentMessage);
            }
        }
    }

    private Vector filterListing()
    {
        boolean noErrors = !parent.haveAssemblyErrors();
        boolean filtering = !showAllCheckBox.isSelected();
        Vector v = new Vector();
        String line;
        int index = 0;
        BufferedReader listFile = null;

        lineTable = new Hashtable();

        try {
            listFile = new BufferedReader(
                           new FileReader(AssemblerOptions.listingPath));

            while ((line = listFile.readLine()) != null) {
                if (!filtering ||
                    ((line.length() > 5) && (line.startsWith("  101")))) {
                    break;
                }
            }

            if (line == null) {
                return v;
            }

            do {
                if (line.length() > 1) {
                    char firstChar = line.charAt(0);

                    if (!filtering || (firstChar == ' ')) {
                        boolean breakable = noErrors &&
                                            (line.length() >= 91) &&
                                            (line.charAt(14) != '*') &&
                                            Character.isDigit(line.charAt(2)) &&
                                            Character.isDigit(line.charAt(3)) &&
                                            Character.isDigit(line.charAt(4)) &&
                                            Character.isDigit(line.charAt(87)) &&
                                            Character.isDigit(line.charAt(88)) &&
                                            Character.isDigit(line.charAt(89)) &&
                                            Character.isDigit(line.charAt(90));

                        ListingLine listingLine = new ListingLine(line,
                                                                  breakable);
                        v.addElement(listingLine);

                        if (breakable) {
                            lineTable.put(listingLine.getAddress(),
                                          new Integer(index));
                        }

                        ++index;
                    }
                }
            } while ((line = listFile.readLine()) != null);

            return v;
        }
        catch (IOException ex) {
            ex.printStackTrace();
            return null;
        }
        finally {
            try {
                if (listFile != null) {
                    listFile.close();
                }
            }
            catch (Exception ignore) {}
        }
    }

    private void flipBreakpoint(int index)
    {
        ListingLine line = (ListingLine) listing.getModel().
                           getElementAt(index);

        if (line.isBreakable()) {
            line.flipBreakpoint();

            synchronized(Simulator.class) {
                if (line.isBreakpoint()) {
                    Simulator.execute("br " + line.getAddress().intValue());
                }
                else {
                    Simulator.execute("nobr " + line.getAddress().intValue());
                }
            }
        }
    }

    private void clearBreakpoints()
    {
        ListModel model = listing.getModel();
        int size = model.getSize();

        for (int i = 0; i < size; ++i) {
            ListingLine line = (ListingLine) model.getElementAt(i);
            line.breakpoint = false;
        }

        listing.repaint();
    }

    private class ListingLine
    {
        private String text;
        private boolean breakable = true;
        private boolean breakpoint = false;
        private Integer address = null;

        ListingLine(String text, boolean breakable)
        {
            this.breakable = breakable;
            this.text = text;

            if (breakable) {
                int i = (text.charAt(86) == ' ') ? 87 : 86;
                address = new Integer(text.substring(i, 91));
            }
        }

        String getText()
        {
            return text;
        }

        Integer getAddress()
        {
            return address;
        }

        boolean isBreakable()
        {
            return breakable;
        }

        boolean isBreakpoint()
        {
            return breakpoint;
        }

        void flipBreakpoint()
        {
            this.breakpoint = !this.breakpoint;
        }
    }

    private Font listingFont = new Font("Courier", Font.PLAIN, 12);
    private ImageIcon nobreakIcon = new ImageIcon("nobreak.gif");
    private ImageIcon breakableIcon = new ImageIcon("breakable.gif");
    private ImageIcon breakPointIcon = new ImageIcon("breakpoint.gif");

    private class ListingLineRenderer
        extends JLabel
        implements ListCellRenderer
    {
        ListingLineRenderer()
        {
            setOpaque(true);
        }

        public Component getListCellRendererComponent(JList list,
                                                      Object value,
                                                      int index,
                                                      boolean isSelected,
                                                      boolean cellHasFocus)
        {
            ListingLine line = (ListingLine) value;

            setIcon(!line.isBreakable() || !simulatorRunning ? nobreakIcon :
                    line.isBreakpoint() ? breakPointIcon : breakableIcon);

            setFont(listingFont);
            setText(line.getText());

            setForeground(line.isBreakpoint() ? Color.RED : Color.BLACK);
            setBackground(isSelected && !settingBreakpoint
                          ? Color.LIGHT_GRAY : Color.WHITE);

            return this;
        }
    }

    private String processOutput()
    {
        String message = null;
        clearMessage();

        do {
            message = Simulator.output();

            if ((message != null) && (message.length() > 0)) {
                writeMessage(Color.BLUE, message);
            }

//            System.out.println(message);
        }
        while (Simulator.hasOutput());

        if (message != null) {
            selectCurrentLine(message);
        }

        return message;
    }

    private void selectCurrentLine(String message)
    {
        int start = message.indexOf("IS: ");

        if (start != -1) {
            start += 4;

            int end = message.indexOf(' ', start);
            Integer address = new Integer(message.substring(start, end));
            Integer lineNumber = (Integer) lineTable.get(address);

            if (lineNumber != null) {
                int index = lineNumber.intValue();

                listing.setSelectedIndex(index);
                listing.ensureIndexIsVisible(index);
            }

            currentMessage = message;
        }
    }

    private void restartAction()
    {
        if (simulatorRunning) {
            killSimulator();
            dataButton.setEnabled(true);
        }
        else {
            startSimulator();
        }
    }

    private void startSimulator()
    {
        synchronized (Simulator.class) {
            Simulator.start();
            processOutput();
        }

        Thread monitor = new StandardErrorMonitor(Simulator.getStderr());
        monitor.start();

        programRunning = false;
        currentMessage = null;

        simulatorButton.setEnabled(true);
        startButton.setText("Start program");
        startButton.setEnabled(true);
        showMemoryButton.setEnabled(true);
        showConsoleButton.setEnabled(true);
        showTimerButton.setEnabled(true);

        clearBreakpoints();
        parent.unlockCommandWindows();
        parent.showPrintoutWindow(baseName);

        simulatorRunning = true;
        simulatorButton.setText("Kill simulator");
    }

    private void killSimulator()
    {
        if (autoStepping) {
            autoStepping = false;

            try {
                autoStepper.join(100);
            }
            catch(Exception ignore) {}
        }

        Simulator.kill();

        startButton.setEnabled(false);
        quitButton.setEnabled(false);
        singleStepButton.setEnabled(false);
        autoStepButton.setEnabled(false);
        showMemoryButton.setEnabled(false);
        showConsoleButton.setEnabled(false);

        clearBreakpoints();
        parent.lockCommandWindows();
        parent.disableSenseSwitches();

        simulatorRunning = false;
        programRunning = false;
        simulatorButton.setText("Restart simulator");
    }

    private void optionsAction()
    {
    }

    private void dataAction()
    {
        if (dialog == null) {
            dialog = new DataDialog(parent, "Runtime Data");

            Dimension screenSize = Toolkit.getDefaultToolkit().
                                   getScreenSize();
            Dimension dialogSize = dialog.getSize();
            dialog.setLocation((screenSize.width - dialogSize.width) / 2,
                               (screenSize.height - dialogSize.height) / 2);
        }

        dialog.initialize();
        dialog.setVisible(true);
        killSimulator();
    }

    private void startAction()
    {
        if (programRunning) {
            synchronized(Simulator.class) {
                Simulator.execute("c");
                processOutput();
            }
        }
        else {
            synchronized(Simulator.class) {
                Simulator.execute("b cdr");
                processOutput();
            }

            startButton.setText("Continue program");
            dataButton.setEnabled(false);
            quitButton.setEnabled(true);
            singleStepButton.setEnabled(true);
            autoStepButton.setEnabled(true);

            programRunning = true;
        }

        parent.updateCommandWindows();
        parent.enableSenseSwitches();
    }

    private void quitAction()
    {
        synchronized(Simulator.class) {
            Simulator.stop();
            processOutput();
        }

        startButton.setText("Start program");
        simulatorButton.setText("Restart simulator");

        optionsButton.setEnabled(false);
        dataButton.setEnabled(true);
        startButton.setEnabled(false);
        quitButton.setEnabled(false);
        singleStepButton.setEnabled(false);
        autoStepButton.setEnabled(false);
        showMemoryButton.setEnabled(false);
        showConsoleButton.setEnabled(false);

        clearBreakpoints();
        parent.lockCommandWindows();
        parent.disableSenseSwitches();

        simulatorRunning = false;
        programRunning = false;
    }

    private String singleStepAction()
    {
        String message;

        synchronized(Simulator.class) {
            Simulator.execute("s");
            message = processOutput();
        }

        parent.updateCommandWindows();
        parent.enableSenseSwitches();

        return message;
    }

    private void autoStepAction()
    {
        if (autoStepping) {
            autoStepping = false;
        }
        else {
            autoStepper = new AutoStepper();

            startButton.setEnabled(false);
            quitButton.setEnabled(false);
            singleStepButton.setEnabled(false);
            autoStepButton.setText("Stop stepping");
            slowerButton.setEnabled(true);
            fasterButton.setEnabled(autoStepWaitTime > 0);

            autoStepping = true;
            autoStepper.start();
        }
    }

    private void slowerAction()
    {
        autoStepWaitTime += 50;
        fasterButton.setEnabled(true);
    }

    private void fasterAction()
    {
        if ((autoStepWaitTime -= 50) <= 0) {
            autoStepWaitTime = 0;
        }

        fasterButton.setEnabled(autoStepWaitTime > 0);
    }

    private void showMemoryAction()
    {
        parent.createMemoryFrame();
    }

    private void showConsoleAction()
    {
        parent.createConsoleFrame();
    }

    private void showTimerAction()
    {
        parent.createTimerFrame();
    }

    private class AutoStepper
        extends Thread
    {
        public void run()
        {
            String message = null;

            do {
                message = singleStepAction();

                try {
                    Thread.sleep(autoStepWaitTime);
                }
                catch (Exception ignore) {}

            }
            while (autoStepping &&
                   (message != null) && message.startsWith("Step"));

            autoStepping = false;
            startButton.setEnabled(true);
            quitButton.setEnabled(true);
            singleStepButton.setEnabled(true);
            autoStepButton.setText("Auto step");
            slowerButton.setEnabled(false);
            fasterButton.setEnabled(false);
        }
    }

    private class StandardErrorMonitor
        extends Thread
    {
        private BufferedReader stderr;

        StandardErrorMonitor(BufferedReader stderr)
        {
            this.stderr = stderr;
        }

        public void run()
        {
            int ch;

            try {
                if (stderr != null) {
                    while ((ch = stderr.read()) != -1) {
                        System.out.print((char) ch);
                    }
                }
            }
            catch(Exception ex) {
                ex.printStackTrace();
            }
        }
    }

    public void actionPerformed(ActionEvent event)
    {
        Object button = event.getSource();

        if (button == simulatorButton) {
            restartAction();
        }
        else if (button == optionsButton) {
            optionsAction();
        }
        else if (button == dataButton) {
            dataAction();
        }
        else if (button == startButton) {
            startAction();
        }
        else if (button == quitButton) {
            quitAction();
        }
        else if (button == singleStepButton) {
            singleStepAction();
        }
        else if (button == autoStepButton) {
            autoStepAction();
        }
        else if (button == slowerButton) {
            slowerAction();
        }
        else if (button == fasterButton) {
            fasterAction();
        }
        else if (button == showMemoryButton) {
            showMemoryAction();
        }
        else if (button == showConsoleButton) {
            showConsoleAction();
        }
        else if (button == showTimerButton) {
            showTimerAction();
        }
    }

    public void stateChanged(ChangeEvent event)
    {
        Object source = event.getSource();

        if (source == showAllCheckBox) {
            clearBreakpoints();
            loadListing();
        }
    }
}
