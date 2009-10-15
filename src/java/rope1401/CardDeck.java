package rope1401;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.io.PrintWriter;

public class CardDeck {
    public static String[] generateCardDeckFile ( File cardDeckFile ) {
        String[] ret = new String[2];
        if (cardDeckFile == null) {
            if (DataOptions.readerPath.trim().length() > 0) {
                cardDeckFile = new File(DataOptions.readerPath);
            }
            else {
                ret[0] = AssemblerOptions.objectPath;
                return ret;
            }
        }

        File objectFile = new File(AssemblerOptions.objectPath);
        String objectName = objectFile.getName();
        String cardDeckName = cardDeckFile.getName();
        String name1 = new String(objectName);
        String name2 = new String(cardDeckName);

        int index = name1.lastIndexOf(".");
        if (index != -1) {
            name1 = name1.substring(0, index);
        }

        index = name2.lastIndexOf(".");
        if (index != -1) {
            name2 = name2.substring(0, index);
        }

        String inputName = name1 + "_" + name2 + ".cd";
        File inputFile = new File(DataOptions.directoryPath, inputName);
        String inputPath = inputFile.getPath();
        ret[0] = inputPath;

        try {
            BufferedReader objectReader =
                new BufferedReader(new FileReader(objectFile));
            BufferedReader cardDeckReader =
                new BufferedReader(new FileReader(cardDeckFile));
            PrintWriter inputWriter =
                new PrintWriter(new FileWriter(inputFile));
            String line;

            while ((line = objectReader.readLine()) != null) {
                inputWriter.println(line);
            }
            while ((line = cardDeckReader.readLine()) != null) {
                inputWriter.println(line);
            }

            objectReader.close();
            cardDeckReader.close();
            inputWriter.close();
        }
        catch (Exception ex) {
            ret[1] = "*** " + ex.getMessage();
        }

        return ret;
    }
}
