import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.io.PrintWriter;
import java.io.IOException;
import java.net.ServerSocket;
import java.net.Socket;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.sql.Connection;
import java.sql.*;
 
class QueryRunner implements Runnable
{
    static Connection c = null; 
    protected Socket socketConnection;
    //  Declare socket for client access
     public QueryRunner(Socket clientSocket)
     {
         this.socketConnection =  clientSocket;
     }
    public void run()
    {
    
      try
        {
            try{
                
                Class.forName("org.postgresql.Driver");
                c = DriverManager.getConnection("jdbc:postgresql://localhost:5432/postgres","postgres", "iitropar");
                c.setAutoCommit(false);
            }
            catch (Exception e) {
                    e.printStackTrace();
             }
         
            //  Reading data from client
            InputStreamReader inputStream = new InputStreamReader(socketConnection
                                                                  .getInputStream()) ;
            BufferedReader bufferedInput = new BufferedReader(inputStream) ;
            OutputStreamWriter outputStream = new OutputStreamWriter(socketConnection
                                                                     .getOutputStream()) ;
            BufferedWriter bufferedOutput = new BufferedWriter(outputStream) ;
            PrintWriter printWriter = new PrintWriter(bufferedOutput, true) ;
            String clientCommand = "" ;
            // Read client query from the socket endpoint
            clientCommand = bufferedInput.readLine(); 
            while( ! clientCommand.equals("#"))
            {  
                System.out.println("Recieved data <" + clientCommand + "> from client : " + socketConnection.getRemoteSocketAddress().toString());
                String[] splitArray = clientCommand .split("\\s+|\\,\\s+");
                int numberofseats=Integer.parseInt(splitArray[0]);
                Integer[] ages=new Integer[numberofseats]; 
                String[] passengerNames=new String[numberofseats];
                String[] genders=new String[numberofseats]; 
                for(int i=0;i<numberofseats;i++){
                      passengerNames[i]=splitArray[i+1];
                      ages[i]=20;
                      genders[i]="F";

                }
               
                /*******************************************
                         Your DB code goes here
                ********************************************/
               
                    
                try {
                    c.setAutoCommit(false);
                    String sql_string = "select check_availability(?,?,?,?)";
       
                    // Preparing a CallableStateement
                    CallableStatement cs = c.prepareCall(sql_string);
                    java.sql.Date sqlDate = java.sql.Date.valueOf(splitArray[numberofseats+2]);
                   
                   
                    cs.setInt(1,numberofseats);
                    cs.setInt(2,Integer.parseInt(splitArray[numberofseats+1]));
                    cs.setDate(3,sqlDate);
                    cs.setString(4,splitArray[numberofseats+3]);

                    ResultSet rs=cs.executeQuery(); 
                    int is_avail = 5; 

                    while(rs.next()) {
                        is_avail = rs.getInt(1);
                    }
                    // printWriter.println(sqlDate);
                     printWriter.println(is_avail);
                   if( is_avail == 1)
                   { 
                    String sql_string1 = "select update_pass(?,?,?,?,?,?,?)";
                    CallableStatement cs1 = c.prepareCall(sql_string1);
                    Array passengerName=c.createArrayOf("varchar",passengerNames);
                    Array age=c.createArrayOf("int4",ages);
                    Array gender=c.createArrayOf("varchar",genders);
                    cs1.setInt(1,Integer.parseInt(splitArray[numberofseats+1]));
                    cs1.setString(2,splitArray[numberofseats+3]);
                    cs1.setDate(3,sqlDate);
                    cs1.setInt(4,numberofseats);
                    cs1.setArray(5,passengerName);
                    cs1.setArray(6,age);
                    cs1.setArray(7, gender);
                    ResultSet rs1=cs1.executeQuery(); 
                    printWriter.println("seats available check your ticket");
                    java.util.UUID uuid=java.util.UUID.randomUUID();
                    while(rs1.next()){
                        uuid = (java.util.UUID) rs1.getObject(1);
                    }
                        rs1.close();
                        String sql_string2 = "select group_ticket(?)";
                        CallableStatement cs2 = c.prepareCall(sql_string2);
                        cs2.setObject(1, uuid);
                        ResultSet rs2=cs2.executeQuery();
                        while(rs2.next()){
                            printWriter.println(rs2.getString(1));
                        }
                        rs2.close();
                        
                   }
                   else
                   {
                      printWriter.println("NO AVAILABLE SEATS");
                   }
                //STEP 5: Extract data from result set
                  
                rs.close();
                c.commit();
                } 
                catch(SQLException e){
                   //Handle errors for JDBC
                   e.printStackTrace();
                  if(c!=null){
                    try{
                        
                        c.rollback();
                        
                    }
                    catch(Exception ex){
                        ex.printStackTrace();
                    }
                  }
                 
                
                }
                catch (Exception e) {
                    e.printStackTrace();
                    System.err.println(e.getClass().getName()+": "+e.getMessage());
                    

                }
                   //finally block used to close resources
                   //end finally try
                
                // Read next client query
        
            clientCommand = bufferedInput.readLine(); 
        }
            inputStream.close();
            bufferedInput.close();
            outputStream.close();
            bufferedOutput.close();
            printWriter.close();
            socketConnection.close();
           
        
    }
        catch(IOException e)
        {
            return;
        }
    }
}

/**
 * Main Class to controll the program flow
 */
public class ServiceModule 
{
    
    // Server listens to port
    static int serverPort = 7008;
    // Max no of parallel requests the server can process
    static int numServerCores = 50;  
         
    //------------ Main----------------------
    public static void main(String[] args) throws IOException 
    {    
        // Creating a thread pool
        ExecutorService executorService = Executors.newFixedThreadPool(numServerCores);
        
        try (//Creating a server socket to listen for clients
        ServerSocket serverSocket = new ServerSocket(serverPort)) {
            Socket socketConnection = null;
           
            // Always-ON server
            while(true)
            {
                System.out.println("Listening port : " + serverPort 
                                    + "\nWaiting for clients...");
                socketConnection = serverSocket.accept();   // Accept a connection from a client
                System.out.println("Accepted client :" 
                                    + socketConnection.getRemoteSocketAddress().toString() 
                                    + "\n");
                //  Create a runnable task
                Runnable runnableTask = new QueryRunner(socketConnection);
                //  Submit task for execution   
                executorService.submit(runnableTask);   
            }
            
        }
    }
}


