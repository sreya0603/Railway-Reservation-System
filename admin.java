
import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.*;
import java.text.SimpleDateFormat; 
import java.text.DateFormat; 

public class admin {
    public static void main(String[] args) {
		BufferedReader reader;
        try {
            Connection c1 = null;
           Class.forName("org.postgresql.Driver");
           c1 = DriverManager
              .getConnection("jdbc:postgresql://localhost:5432/postgres","postgres", "Vishnu@123");
              try {
                reader = new BufferedReader(new FileReader("trainshedule.txt"));
                String line;
                line = reader.readLine();
                while (!line.equals("#")) {
                    System.out.println(line);
                    String[] s= line.split("\\s+");
                    DateFormat df = new SimpleDateFormat("yyyy/MM/dd");
                    int trainno=Integer.parseInt(s[0]);
                    Date sql= Date.valueOf(s[1]);
                    int ac_couch=Integer.parseInt(s[2]);
                    int sl_couch=Integer.parseInt(s[3]);
                    String sql_string = "select release_train(?,?,?,?,?,?)";
                    CallableStatement css = c1.prepareCall(sql_string);
                    css.setInt(1,trainno);
                    css.setDate(2,sql);
                    css.setInt(3,ac_couch);
                    css.setInt(4,sl_couch);
                    css.setInt(5,18*ac_couch);
                    css.setInt(6,24*sl_couch);
                    css.executeQuery(); 
                    line = reader.readLine();
                }
               
                reader.close();
                c1.close();
                }
                catch (IOException e) {
                e.printStackTrace();
                }
        }
         catch (Exception e) {
           e.printStackTrace();
           System.err.println(e.getClass().getName()+": "+e.getMessage());
           System.exit(0);
        }
        
	
       
	}
}
