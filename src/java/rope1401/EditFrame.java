package rope1401;

import java.io.*;
import java.util.*;
import java.awt.*;
import java.awt.event.*;
import javax.swing.*;
import javax.swing.border.*;
import javax.swing.event.*;
import javax.swing.filechooser.FileFilter;

public class EditFrame
    extends JInternalFrame
    implements ActionListener, CaretListener
{
    TitledBorder titledBorder1;
    BorderLayout borderLayout1 = new BorderLayout();
    GridBagLayout gridBagLayout1 = new GridBagLayout();
    GridBagLayout gridBagLayout2 = new GridBagLayout();
    JSplitPane splitPane = new JSplitPane();
    JScrollPane textScrollPane = new JScrollPane();
    JTextArea sourceArea = new JTextArea();
    JPanel controlPanel = new JPanel();
    JLabel fileLabel = new JLabel();
    JTextField fileText = new JTextField();
    JButton browseButton = new JButton();
    JButton optionsButton = new JButton();
    JButton assembleButton = new JButton();
    JButton saveButton = new JButton();
    JPanel positionPanel = new JPanel();
    JLabel lineLabel = new JLabel();
    JTextField lineText = new JTextField();
    JLabel columnLabel = new JLabel();
    JTextField columnText = new JTextField();
    JScrollPane messageScrollPane = new JScrollPane();
    JList messageList = new JList();

    private RopeFrame parent;
    private AssemblerDialog dialog = null;
    private String baseName;
//    private String outPath;

    private boolean haveAssemblyErrors;
    private Vector messages;

    public EditFrame()
    {
        try {
            jbInit();
        }
        catch (Exception ex) {
            ex.printStackTrace();
        }
    }

    EditFrame(RopeFrame parent)
    {
        this();
        this.parent = parent;

        this.setSize(600, 600);

        sourceArea.addCaretListener(this);
        browseButton.addActionListener(this);
        optionsButton.addActionListener(this);
        assembleButton.addActionListener(this);
        saveButton.addActionListener(this);

        messageList.addMouseListener(new MouseAdapter()
        {
            public void mouseClicked(MouseEvent event)
            {
                highlightError(messageList.locationToIndex(event.getPoint()));
            }
        });
    }

    void jbInit()
        throws Exception
    {
        titledBorder1 = new TitledBorder(BorderFactory.createLineBorder(
            new Color(153, 153, 153), 2), "Assembly messages");
        this.getContentPane().setLayout(borderLayout1);
        this.setIconifiable(true);
        this.setMaximizable(true);
        this.setResizable(true);
        this.setTitle("EDIT");
        splitPane.setOrientation(JSplitPane.VERTICAL_SPLIT);
        splitPane.setDividerLocation(350);
        sourceArea.setFont(new java.awt.Font("Courier", 0, 12));
        controlPanel.setLayout(gridBagLayout1);
        controlPanel.setBorder(BorderFactory.createLoweredBevelBorder());
        positionPanel.setLayout(gridBagLayout2);
        fileLabel.setText("Source file:");
        fileText.setEditable(false);
        browseButton.setSelected(false);
        browseButton.setText("Browse ...");
        assembleButton.setEnabled(false);
        assembleButton.setText("Assemble file");
        saveButton.setEnabled(false);
        saveButton.setText("Save file");
        lineLabel.setText("Line:");
        lineText.setMinimumSize(new Dimension(35, 20));
        lineText.setPreferredSize(new Dimension(35, 20));
        lineText.setEditable(false);
        columnLabel.setText("Column:");
        columnText.setMinimumSize(new Dimension(20, 20));
        columnText.setPreferredSize(new Dimension(20, 20));
        columnText.setEditable(false);
        columnText.setText("");
        messageScrollPane.setBorder(titledBorder1);
        messageScrollPane.setMinimumSize(new Dimension(33, 90));
        messageScrollPane.setPreferredSize(new Dimension(60, 90));
        optionsButton.setEnabled(false);
        optionsButton.setText("Assembler options ...");
        messageScrollPane.getViewport().add(messageList, null);
        messageList.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);
        this.getContentPane().add(splitPane, BorderLayout.CENTER);
        splitPane.add(textScrollPane, JSplitPane.TOP);
        splitPane.add(controlPanel, JSplitPane.BOTTOM);
        textScrollPane.getViewport().add(sourceArea, null);
        controlPanel.add(fileLabel,
                         new GridBagConstraints(0, 0, 1, 1, 0.0, 0.0,
                                                GridBagConstraints.WEST,
                                                GridBagConstraints.NONE,
                                                new Insets(5, 5, 0, 0), 0, 0));
        controlPanel.add(fileText,
                         new GridBagConstraints(1, 0, 3, 1, 1.0, 0.0,
                                                GridBagConstraints.CENTER,
                                                GridBagConstraints.HORIZONTAL,
                                                new Insets(5, 5, 0, 0), 0, 0));
        controlPanel.add(browseButton,
                         new GridBagConstraints(4, 0, 1, 1, 0.0, 0.0,
                                                GridBagConstraints.CENTER,
                                                GridBagConstraints.HORIZONTAL,
                                                new Insets(5, 5, 0, 5), 0, 0));
        positionPanel.add(lineLabel,
                          new GridBagConstraints(0, 0, 1, 1, 0.0, 0.0,
                                                 GridBagConstraints.EAST,
                                                 GridBagConstraints.NONE,
                                                 new Insets(0, 0, 0, 0), 0, 0));
        controlPanel.add(optionsButton,
                         new GridBagConstraints(2, 1, 1, 1, 1.0, 0.0,
                                                GridBagConstraints.EAST,
                                                GridBagConstraints.NONE,
                                                new Insets(5, 5, 0, 0), 0, 0));
        controlPanel.add(assembleButton,
                         new GridBagConstraints(3, 1, 1, 1, 0.0, 0.0,
                                                GridBagConstraints.EAST,
                                                GridBagConstraints.NONE,
                                                new Insets(5, 5, 0, 0), 0, 0));
        controlPanel.add(saveButton,
                         new GridBagConstraints(4, 1, 1, 1, 0.0, 0.0,
                                                GridBagConstraints.CENTER,
                                                GridBagConstraints.HORIZONTAL,
                                                new Insets(5, 5, 0, 5), 0, 0));
        controlPanel.add(positionPanel,
                         new GridBagConstraints(0, 1, 2, 1, 0.0, 0.0,
                                                GridBagConstraints.CENTER,
                                                GridBagConstraints.NONE,
                                                new Insets(5, 5, 0, 0), 0, 0));
        positionPanel.add(lineText,
                          new GridBagConstraints(1, 0, 1, 1, 0.0, 0.0,
                                                 GridBagConstraints.EAST,
                                                 GridBagConstraints.NONE,
                                                 new Insets(0, 5, 0, 0), 0, 0));
        positionPanel.add(columnLabel,
                          new GridBagConstraints(2, 0, 1, 1, 0.0, 0.0,
                                                 GridBagConstraints.EAST,
                                                 GridBagConstraints.NONE,
                                                 new Insets(0, 15, 0, 0), 0, 0));
        positionPanel.add(columnText,
                          new GridBagConstraints(3, 0, 1, 1, 0.0, 0.0,
                                                 GridBagConstraints.EAST,
                                                 GridBagConstraints.NONE,
                                                 new Insets(0, 5, 0, 0), 0, 0));
        controlPanel.add(messageScrollPane,
                         new GridBagConstraints(0, 2, 5, 1, 1.0, 1.0,
                                                GridBagConstraints.CENTER,
                                                GridBagConstraints.BOTH,
                                                new Insets(5, 5, 5, 5), 0, 0));
    }

    boolean haveAssemblyErrors()
    {
        return haveAssemblyErrors;
    }

    private class AssemblyFileFilter extends FileFilter
    {
        private String extensions[];
        private String description;

        public AssemblyFileFilter(String extensions[], String description)
        {
            this.extensions = new String[extensions.length];
            this.description = description;

            for (int i = 0; i < extensions.length; ++i) {
                this.extensions[i] = extensions[i].toLowerCase();
            }
        }

        public boolean accept(File file)
        {
            if (file.isDirectory()) {
                return true;
            }

            String name = file.getName().toLowerCase();
            for (int i = 0; i < extensions.length; ++i) {
                if (name.endsWith(extensions[i])) {
                    return true;
                }
            }

            return false;
        }

        public String getDescription()
        {
            return description;
        }
    }

    public void actionPerformed(ActionEvent event)
    {
        Object button = event.getSource();

        if (button == browseButton) {
            browseAction();
        }
        else if (button == saveButton) {
            saveAction();
        }
        else if (button == optionsButton) {
            optionsAction();
        }
        else if (button == assembleButton) {
            assembleAction();
        }
    }

    private void browseAction()
    {
        RopeFileChooser chooser =
            new RopeFileChooser(DataOptions.directoryPath, null,
                                new RopeFileFilter(
                                    new String[] {".a", ".asm", ".aut", ".s"},
                                    "Assembly files (*.a, *.asm, *.aut, *.s)"));
        File file = chooser.choose(fileText, this);

        setSourceFile ( file );
    }

    public void setSourceFile ( File file ) {
        if (file != null) {
            BufferedReader sourceFile = null;

            String directoryPath = file.getParent();
            String sourceName = file.getName();

            int i = sourceName.lastIndexOf(".");
            baseName =
                i == -1 ? sourceName.substring(0) : sourceName.substring(0, i);
            String basePath = directoryPath + File.separator + baseName;

            DataOptions.directoryPath = directoryPath;
//            outPath = directoryPath + File.separator + baseName + ".out";

            AssemblerOptions.sourcePath = file.getPath();
            AssemblerOptions.listingPath = basePath + ".lst";
            AssemblerOptions.objectPath = basePath + ".cd";

            DataOptions.inputPath = AssemblerOptions.objectPath;
            DataOptions.outputPath = basePath + ".out";

            DataOptions.readerPath = null;
            DataOptions.punchPath = basePath + ".pch";
            DataOptions.tape1Path = basePath + ".mt1";
            DataOptions.tape2Path = basePath + ".mt2";
            DataOptions.tape3Path = basePath + ".mt3";
            DataOptions.tape4Path = basePath + ".mt4";
            DataOptions.tape5Path = basePath + ".mt5";
            DataOptions.tape6Path = basePath + ".mt6";

            this.setTitle("EDIT: " + sourceName);
            fileText.setText(AssemblerOptions.sourcePath);

            if (dialog == null) {
                dialog = new AssemblerDialog(parent, "Assembler options");

                Dimension screenSize = Toolkit.getDefaultToolkit().
                                       getScreenSize();
                Dimension dialogSize = dialog.getSize();
                dialog.setLocation((screenSize.width - dialogSize.width) / 2,
                                   (screenSize.height - dialogSize.height) / 2);
            }

            dialog.initialize();
            AssemblerOptions.command = dialog.buildCommand();

            sourceArea.setText(null);

            try {
                sourceFile = new BufferedReader(new FileReader(file));
                String line;

                while ((line = sourceFile.readLine()) != null) {
                    sourceArea.append(line + "\n");
                }

                sourceArea.setCaretPosition(0);
                optionsButton.setEnabled(true);
                assembleButton.setEnabled(true);
                saveButton.setEnabled(true);
            }
            catch (Exception ex) {
                ex.printStackTrace();
            }
            finally {
                try {
                    sourceFile.close();
                }
                catch (Exception ignore) {}
            }
        }
    }

    private void saveAction()
    {
        BufferedWriter sourceFile = null;

        try {
            sourceFile = new BufferedWriter(
                             new FileWriter(AssemblerOptions.sourcePath, false));
            sourceFile.write(sourceArea.getText());
        }
        catch (IOException ex) {
            ex.printStackTrace();
        }
        finally {
            if (sourceFile != null) {
                try {
                    sourceFile.close();
                }
                catch (Exception ignore) {}
            }
        }
    }

    private void optionsAction()
    {
        dialog.initialize();
        dialog.buildCommand();
        dialog.setVisible(true);
    }

    void assembleAction()
    {
        String line;
        messages = new Vector();

        parent.resetExecWindow();

        saveAction();
        haveAssemblyErrors = false;

        Assembler.version();
        while ((line = Assembler.output()) != null) {
            messages.addElement(line);
        }

        Assembler.setPaths(baseName, AssemblerOptions.sourcePath);
        Assembler.assemble();
        while ((line = Assembler.output()) != null) {
            messages.addElement(line);
            haveAssemblyErrors = true;
        }

        messageList.setListData(messages);
        messageList.ensureIndexIsVisible(0);

        parent.showExecWindow(baseName);
    }

    private void highlightError(int index)
    {
        String message = (String) messages.elementAt(index);
        int i = message.indexOf(":");

        if ((i != -1) && (i < 10)) {
            int lineNumber = Integer.parseInt(message.substring(0, i).trim()) - 1;

            try {
                int start = sourceArea.getLineStartOffset(lineNumber);
                int end = sourceArea.getLineEndOffset(lineNumber);

                sourceArea.requestFocus();
                sourceArea.setSelectionStart(start);
                sourceArea.setSelectionEnd(end - 1);
            }
            catch (Exception ex) {
                ex.printStackTrace();
            }
        }
    }

    public void caretUpdate(CaretEvent event)
    {
        int dot = event.getDot();

        try {
            int line = sourceArea.getLineOfOffset(dot);
            lineText.setText(Integer.toString(line + 1));
            int column = dot - sourceArea.getLineStartOffset(line);
            columnText.setText(Integer.toString(column + 1));
        }
        catch(Exception ex) {
            ex.printStackTrace();
        }
    }
}
