import List "mo:base/List";
import Array "mo:base/Array";
import Time "mo:base/Time";
import Text "mo:base/Text";
import Result "mo:base/Result";
import Buffer "mo:base/Buffer";
import Blob "mo:base/Blob";
import Nat64 "mo:base/Nat64";
import Int "mo:base/Int";

import Types "./types";

import ICPTypes "./ICPTypes";

import CRC32 "./CRC32";
import SHA224 "./SHA224";
import Account "./account";
import Hex "./hex";
import Utils "./utils";


shared (install) actor class Inbox(name : Text) = this {

  type Message = Types.Message;
  type Currency = Types.Currency;

  let ICPLedger : ICPTypes.Ledger = actor ("ryjl3-tyaaa-aaaaa-aaaba-cai");
  let ICP_FEE : Nat64 = 10_000;

  private stable var _name = name;
  private stable var _version = "0.0.1";

  private stable var _nextId : Nat = 1;

  private stable var _stableNewMessages : [Message] = [];
  private stable var _stableMessages : [Message] = [];
  private var messages : List.List<Message> = List.fromArray(_stableMessages);
  private var newMessages : List.List<Message> = List.fromArray(_stableNewMessages);

  private var _owner : Principal = install.caller;

  //block senders
  private stable var _blacklist : [Text] = []; //allow proxys/clients
  private stable var _whitelist : [Principal] = [];

  //=======================================================
  //  WALLET (ICP/BTC/ETH...)
  //=======================================================

  public shared ({ caller }) func transfer(currency : Currency, amount : Nat64, to : Principal) : async Result.Result<Nat64, Text> {
    if (caller == _owner) {
      switch (currency) {
        case (#ICP) {
         await transferICP(amount, to);
        };
        case (#BTC) {
         await transferBTC(amount, to);
        };
        case (#ETH) {
        await  transferETH(amount, to);
        };
      };
    } else {
      #err("no permission");
    };

  };

  private func transferICP(amount : Nat64, to : Principal) : async Result.Result<Nat64, Text> {
    let toAccount = Account.accountIdentifier(to, Account.defaultSubaccount());
    let res = await ICPLedger.transfer({
      memo = 1;
      from_subaccount = null;
      to = Blob.fromArray(Hex.decode(Utils.accountIdToHex(toAccount)));
      amount = { e8s = amount };
      fee = { e8s = ICP_FEE };
      created_at_time = ?{
        timestamp_nanos = Nat64.fromNat(Int.abs(Time.now()));
      };
    });
    switch (res) {
      case (#Ok(blockIndex)) {
        #ok(blockIndex);
      };
      case (#Err(#InsufficientFunds { balance })) {
        #err("No enough fund! The balance is only " # debug_show balance # " e8s");
      };
      case (#Err(other)) {
        #err("Unexpected error: " # debug_show other);
      };
    };

  };
  private func transferETH(amount : Nat64, to : Principal) :async Result.Result<Nat64, Text> {
    #err("not support");
  };
  private func transferBTC(amount : Nat64, to : Principal) :async Result.Result<Nat64, Text> {
    #err("not support");
  };
  //=======================================================
  //  MESSAGE
  //=======================================================
  /**
    drop message to this inbox
  **/
  public shared ({ caller }) func drop(subject : Text, content : Text, sender : Text) : async Result.Result<Int, Text> {
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
            client = caller;

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

  //change new message to read
  public shared ({ caller }) func read(id : Nat) : async Result.Result<Int, Text> {
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

  //get all new messages
  public query ({ caller }) func fetch() : async [Message] {
    if (caller == _owner) {
      List.toArray(newMessages);
    } else { [] };
  };

  // search messages from read
  public query ({ caller }) func search(start : Int, end : Int, q : ?Text) : async [Message] {
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

  //change the inbox's owner
  public shared ({ caller }) func changeOwner(newOwner : Principal) : async Result.Result<Int, Text> {
    if (caller == _owner) {
      _owner := newOwner;
      #ok(1);
    } else {
      #err("no permission");
    };
  };

  //allow one to drop message
  public shared ({ caller }) func allow(client : Principal) : async Result.Result<Int, Text> {
    if (caller == _owner) {
      let pb = Buffer.fromArray<Principal>(_whitelist);
      pb.add(client);
      _whitelist := Buffer.toArray(pb);

      #ok(1);
    } else {
      #err("no permission");
    };
  };

  //block specific sender
  public shared ({ caller }) func block(sender : Text) : async Result.Result<Int, Text> {
    if (caller == _owner) {
      let pb = Buffer.fromArray<Text>(_blacklist);
      pb.add(sender);
      _blacklist := Buffer.toArray(pb);
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
