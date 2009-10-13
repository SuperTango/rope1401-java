package rope1401;

import java.io.*;
import java.awt.*;
import java.awt.event.*;
import javax.swing.*;
import javax.swing.event.*;

public class PrintoutFrame
    extends JInternalFrame
    implements ActionListener, ChangeListener, CommandWindow
{
    BorderLayout borderLayout1 = new BorderLayout();
    GridBagLayout gridBagLayout1 = new GridBagLayout();
    JPanel controlPanel = new JPanel();
    JButton updateButton = new JButton();
    JCheckBox autoCheckBox = new JCheckBox();
    JCheckBox stripesCheckBox = new JCheckBox();
    JCheckBox barsCheckBox = new JCheckBox();
    JScrollPane scrollPane = new JScrollPane();
    JTextArea printoutArea = new JTextArea();

    private RopeFrame parent;
    private BufferedReader printout;
    private Color barColor = new Color(100, 0, 100);
    private Color stripeColor = new Color(25, 0, 25);

    public PrintoutFrame()
    {
        printoutArea = new JTextArea() {
            public void paint(Graphics g)
            {
                super.paint(g);

                boolean doBars = barsCheckBox.isSelected();
                boolean doStripes = stripesCheckBox.isSelected();

                if (doBars || doStripes) {
                    Dimension size = this.getSize();
                    FontMetrics fm = g.getFontMetrics();
                    int charWidth = fm.charWidth('w');
                    int lineHeight = fm.getHeight();
                    int barWidth = 10*charWidth;
                    int barHeight = 3*lineHeight;
                    int skipHeight = 2*barHeight;

                    g.setXORMode(Color.BLACK);

                    if (doBars) {
                        g.setColor(barColor);
                        for (int x = barWidth; x < size.width; x += barWidth) {
                            g.drawLine(x, 0, x, size.height);
                        }
                    }

                    if (doStripes) {
                        g.setColor(stripeColor);
                        for (int y = barHeight; y < size.height; y += skipHeight) {
                            g.fillRect(0, y, size.width, barHeight);
                        }
                    }

                    g.setPaintMode();
                }
            }
        };

        try {
            jbInit();
        }
        catch (Exception ex) {
            ex.printStackTrace();
        }
    }

    PrintoutFrame(RopeFrame parent)
    {
        this();
        this.parent = parent;

        this.setSize(960, 350);
        updateButton.addActionListener(this);
        stripesCheckBox.addChangeListener(this);
        barsCheckBox.addChangeListener(this);
    }

    protected void finalize()
    {
        if (printout != null) {
            try {
                printout.close();
            }
            catch(Exception ignore) {}
        }
    }

    void jbInit()
        throws Exception
    {
        this.setIconifiable(true);
        this.setMaximizable(true);
        this.setResizable(true);
        this.setTitle("PRINTOUT");
        this.getContentPane().setLayout(borderLayout1);
        this.getContentPane().add(controlPanel, BorderLayout.NORTH);
        this.getContentPane().add(scrollPane, BorderLayout.CENTER);
        controlPanel.setLayout(gridBagLayout1);
        updateButton.setText("Update");
        autoCheckBox.setText("Auto update");
        autoCheckBox.setSelected(true);
        stripesCheckBox.setText("Stripes");
        stripesCheckBox.setSelected(true);
        barsCheckBox.setText("Bars");
        barsCheckBox.setSelected(false);
        scrollPane.getViewport().add(printoutArea, null);
        printoutArea.setFont(new java.awt.Font("Courier", 0, 12));
        printoutArea.setDoubleBuffered(true);
        printoutArea.setEditable(false);
        controlPanel.add(updateButton,
                         new GridBagConstraints(0, 0, 1, 1, 0.0, 0.0,
                                                GridBagConstraints.WEST,
                                                GridBagConstraints.NONE,
                                                new Insets(5, 5, 5, 0), 0, 0));
        controlPanel.add(autoCheckBox,
                         new GridBagConstraints(1, 0, 1, 1, 0.0, 0.0,
                                                GridBagConstraints.CENTER,
                                                GridBagConstraints.NONE,
                                                new Insets(5, 5, 5, 0), 0, 0));
        controlPanel.add(stripesCheckBox,
                         new GridBagConstraints(3, 0, 1, 1, 1.0, 0.0,
                                                GridBagConstraints.EAST,
                                                GridBagConstraints.NONE,
                                                new Insets(5, 0, 5, 0), 0, 0));
        controlPanel.add(barsCheckBox,
                         new GridBagConstraints(4, 0, 1, 1, 0.0, 0.0,
                                                GridBagConstraints.CENTER,
                                                GridBagConstraints.NONE,
                                                new Insets(0, 0, 0, 0), 0, 0));
    }

    void initialize()
    {
        try {
            if (printout != null) {
                printout.close();
            }

            printout = new BufferedReader(new FileReader(DataOptions.outputPath));
            printoutArea.setText(null);
        }
        catch(Exception ex) {
            printout = null;
            ex.printStackTrace();
        }
    }

    public void execute()
    {
        if (autoCheckBox.isSelected()) {
            update();
        }
        else {
            printoutArea.setEnabled(false);
        }
    }

    public void lock()
    {
        updateButton.setEnabled(false);
    }

    public void unlock()
    {
        updateButton.setEnabled(true);
    }

    public void stateChanged(ChangeEvent event)
    {
        Object source = event.getSource();

        if ((source == stripesCheckBox) || (source == barsCheckBox)) {
            printoutArea.repaint();
        }
    }

    public void actionPerformed(ActionEvent event)
    {
        update();
        printoutArea.repaint();
    }

    private void update()
    {
        if (printout != null) {
            String line;

            try {
                while ((line = printout.readLine()) != null) {
                    printoutArea.append(line + "\n");
                }
            }
            catch (Exception ex) {
                ex.printStackTrace();
            }

            printoutArea.setEnabled(true);
            printoutArea.setCaretPosition(printoutArea.getText().length());
        }
    }
}
