import List "mo:base/List";
import Array "mo:base/Array";
import Time "mo:base/Time";
import Text "mo:base/Text";
import Result "mo:base/Result";

import Types "./types";

shared (install) actor class Inbox(name : Text) = this {

  type Message = Types.Message;

  private stable var _name = name;
  private stable var _version = "0.01";

  private stable var _nextId : Nat = 1;

  private stable var _stableNewMessages : [Message] = [];
  private stable var _stableMessages : [Message] = [];
  private var messages : List.List<Message> = List.fromArray(_stableMessages);
  private var newMessages : List.List<Message> = List.fromArray(_stableNewMessages);

  private var _owner : Principal = install.caller;

  //block senders
  private stable var _blacklist : [Text] = []; //allow proxys
  private stable var _whitelist : [Principal] = [];

  public shared ({ caller }) func send(subject : Text, content : Text, sender : Text) : async Result.Result<Int, Text> {
    if (_isAllowed(caller)) {
      if (_isBlocked(sender)) {
        #err("this sender is blocked by inbox!");
      } else {
        newMessages := List.push(
          {
            id = _nextId;
            subject = subject;
            content = content;
            timestamp = Time.now();
            sender = sender;

          },
          newMessages,
        );
        _nextId := _nextId +1;
        #ok(1);
      };
    } else {
      #err("not allow to send message to this inbox");
    };
  };

  public shared ({ caller }) func readMessage(id : Nat) : async Result.Result<Int, Text> {
    if (caller == _owner) {
      let fm = List.find(
        newMessages,
        func(m : Message) : Bool {
          m.id == id;
        },
      );
      switch (fm) {
        case (?fm) {
          messages := List.push(fm, messages);
          #ok(1);
        };
        case (_) {
          #err("no message found");
        };
      };
    } else {
      #err("no permission");
    };

  };

  public query ({ caller }) func fetchNewMessages() : async [Message] {
    if (caller == _owner) {
      List.toArray(newMessages);
    } else { [] };
  };

  public query ({ caller }) func searchMessages(start : Int, end : Int, q : ?Text) : async [Message] {
    if (caller == _owner) {
      switch (q) {
        case (?q) {
          let fl = List.filter(
            messages,
            func(m : Message) : Bool {
              m.timestamp >= start and m.timestamp <= end and (Text.contains(m.subject, #text(q)) or Text.contains(m.content, #text(q)))
            },
          );
          List.toArray(fl);
        };
        case (_) {
          let fl = List.filter(
            messages,
            func(m : Message) : Bool {
              m.timestamp >= start and m.timestamp <= end
            },
          );
          List.toArray(fl);
        };
      };

    } else { [] };
  };

  public shared ({ caller }) func changeOwner(newOwner : Principal) : async Result.Result<Int, Text> {
    if (caller == _owner) {
      _owner := newOwner;
      #ok(1);
    } else {
      #err("no permission");
    };
  };

  private func _isBlocked(sender : Text) : Bool {
    let fb = Array.find<Text>(
      _blacklist,
      func(b : Text) : Bool {
        sender == b;
      },
    );
    switch (fb) {
      case (?fb) { true };
      case (_) { false };
    };
  };
  private func _isAllowed(proxy : Principal) : Bool {
    let fb = Array.find<Principal>(
      _whitelist,
      func(w : Principal) : Bool {
        proxy == w;
      },
    );
    switch (fb) {
      case (?fb) { true };
      case (_) { false };
    };
  };

  system func preupgrade() {
    _stableMessages := List.toArray(messages);
    _stableNewMessages := List.toArray(newMessages);
  };
  system func postupgrade() {
    _stableMessages := [];
    _stableNewMessages := [];
  };

};
