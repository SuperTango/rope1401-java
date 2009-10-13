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
    
    public static RopeConfig getConfig() {
        if ( s_config == null ) {
            s_config = new RopeConfig();
        }
        return s_config;
    }
    
    public static RopeConfig getConfig ( String ropeConfigPath ) throws IOException {
        s_config = new RopeConfig();
        s_config.load ( ropeConfigPath );
        return s_config;
    }
    
    RopeConfig() {
    }
    
    void load ( String path ) throws IOException {
        System.out.println ( "Loading file: " + path );
        Properties defaultProperties = new Properties();
        defaultProperties.setProperty ( "autocoder.path", "./autocoder" );
        defaultProperties.setProperty ( "simulator.path", "./i1401r" );
        m_properties = new Properties ( defaultProperties );
        m_properties.load ( new FileInputStream ( path ) );
        m_properties.storeToXML ( System.out, "foo" );
        m_properties.store ( System.out, "comment" );
    }
    
    public String getConfigValue ( String key ) {
        return m_properties.getProperty ( key );
    }
    
    public String toString() {
        return m_properties.toString ();
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
    