package rope1401;

import java.awt.*;
import java.awt.event.*;
import java.io.File;
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
        if ( args.length == 0 ) {
            System.out.println ( "no initialization file passed, continuing without it." );
        } else if ( args.length == 1 ) {
            try {
                File f = new File ( args[0] );
                if ( ! f.exists() ) {
                    System.out.println ( "The initalizationn file passed: '" + args[0] + "' does not exist. Exiting." );
                    System.exit ( 1 );
                }
                RopeConfig.initConfig ( args[0] );
            } catch ( IOException e ) {
                // TODO Auto-generated catch block
                e.printStackTrace();
            }
        } else {
            System.out.println ( "Sorry, " + args.length + " parameters were passed. only zero or one parameters are allowed.  Exiting." );
            System.exit ( 1 );
        }
        new Rope();
    }
}
