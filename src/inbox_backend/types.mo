module Types {

    public type Currency = {
        #ICP;
        #BTC;
        #ETH;
        
    };

    public type Message = {
        id: Nat;
        subject: Text;
        content: Text;
        timestamp: Int;
        sender: Text;
        client: Principal;
       
    };
}