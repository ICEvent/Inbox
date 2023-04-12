module Types {

    public type Subject = Text;
    public type Content = Text;
    public type Sender = Text;
    public type Inbox = Text;

    public type Currency = {
        #ICP;
        #BTC;
        #ETH;
        
    };

    public type Message = {
        id: Nat;
        subject: Subject;
        content: Content;
        timestamp: Int;
        sender: Sender;
        carrier: Principal;
       
    };
}