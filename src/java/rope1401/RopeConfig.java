package rope1401;

import java.util.*;
import java.io.*;

public class RopeConfig {
    static RopeConfig s_config = null;

    String m_autocoderPath = "./autocoder";
    String m_simulatorPath = "./i1401r";
    
    String m_autocoderSrcPath = null;
    String m_autocoderMacroPath = null;
    Properties m_properties = null;
    Properties m_defaultProperties = null;
 
    RopeConfig() {
        m_defaultProperties = new Properties();
        m_defaultProperties.setProperty ( "autocoder.binary.path", "./autocoder" );
        m_defaultProperties.setProperty ( "simulator.binary.path", "./i1401r" );
        m_defaultProperties.setProperty ( "rope.debug", "0" );
        m_properties = new Properties ( m_defaultProperties );
    }    
    
    public static RopeConfig getConfig() {
        if ( s_config == null ) {
            s_config = new RopeConfig();
        }
        return s_config;
    }
    
    public static void initConfig ( String ropeConfigPath ) throws IOException {
        s_config = new RopeConfig();
        s_config.load ( ropeConfigPath );
    }
    
    
    void load ( String path ) throws IOException {       
        System.out.println ( "Loading config file: " + path );
        m_properties.load ( new FileInputStream ( path ) );
//        m_properties.storeToXML ( System.out, "foo" );
//        m_properties.store ( System.out, "comment" );
    }
    
    public String getConfigValue ( String key ) {
        return m_properties.getProperty ( key );
    }
    
    public String toString() {
        return m_properties.toString ();
    }
    
    public boolean isDebug() {
        return m_properties.getProperty ( "rope.debug" ).equals ( "1" );
    }
    
}
/*
 * settable things...
 * 
 * ROPE:
 *   start mode (dialog, autocoder, simulator)
 * 
 * autocoder:
 *    source file
 *    macro directories (plural)
 *    
 */
    