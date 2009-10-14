package rope1401;

import java.awt.*;
import java.awt.event.*;
import java.io.IOException;

import javax.swing.*;
import javax.swing.border.*;
import javax.swing.UIManager;

/**
 * <p>Title: </p>
 * <p>Description: </p>
 * <p>Copyright: Copyright (c) 2005</p>
 * <p>Company: NASA Ames Research Center</p>
 * @author Ronald Mak
 * @version 2.0
 */

public class Rope
{
    public Rope()
    {
        RopeFrame ropeFrame = new RopeFrame(true);
    }

    public static void main(String[] args)
    {
        try {
            RopeConfig rc = RopeConfig.getConfig ( args[0] );
        } catch ( IOException e ) {
            // TODO Auto-generated catch block
            e.printStackTrace();
        }
        new Rope();
    }
}
