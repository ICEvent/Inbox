module Types {

    public type Message = {
        id: Nat;
        subject: Text;
        content: Text;
        timestamp: Int;
        sender: Text;
        client: Principal;
       
    };
}